defmodule Spider.Request do
  @moduledoc """
  `Request` properties:
    * `:url` - Target url as binary string or char list.
    * `:query` - GraphQL query or mutation in map or binary.
    * `:extras` - A mpa containing extras fields to be sent in request body.
    * `:headers` - HTTP headers as an orddict (e.g., `[{"Accept", "application/json"}]`)
    * `:options` - HTTPoison.Request options Keyword list of options
    * `:params` - Query parameters as a map, keyword, or orddict

  `:query`:
    * a map (e.g. `%{query: "mutation (...)", _timestamp: 1586615460000 }`)
    * binary, char list or an iolist


  """
  @enforce_keys [:url, :query]
  defstruct url: nil, query: nil, extras: %{}, headers: [], params: %{}, options: []

  @type url :: binary
  @type query :: map
  @type extras :: map
  # | any
  @type headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @type params :: map | keyword | [{binary, binary}]
  @type options :: keyword

  @type t :: %__MODULE__{
          url: url,
          query: query,
          extras: extras,
          headers: headers,
          params: params,
          options: options
        }
end

defmodule Spider do
  require HTTPoison
  require Logger

  @callback request(Spider.Request.t()) :: {:ok | :error | :with_error, any}

  def request(%Spider.Request{} = proto_request) do
    request = %HTTPoison.Request{
      url: proto_request.url,
      body: Poison.encode!(merge_query(proto_request).query),
      method: :post,
      headers: process_headers(proto_request.headers),
      params: proto_request.params,
      options: proto_request.options
    }

    Logger.debug(inspect(request))

    case HTTPoison.request(request) do
      {:error, e} ->
        {:error, e}

      {:ok, %{body: body}} ->
        case Poison.decode(body) do
          {:error, :invalid, _} ->
            {:error, body, %{code: :invalid}}

          {:ok, resp} ->
            prepare_response(resp)
        end
    end
  end

  def request(url, query, extras \\ %{}, headers \\ [], params \\ %{}, options \\ []) do
    %Spider.Request{
      url: url,
      query: query,
      extras: extras,
      headers: headers,
      params: params,
      options: options
    }
    |> request()
  end

  defp prepare_response(resp) do
    case {Map.fetch(resp, "data"), Map.fetch(resp, "errors")} do
      {:error, :error} ->
        {:error, %{raw: resp}}

      {:error, {:ok, e}} ->
        {:error, e}

      {{:ok, d}, :error} ->
        {:ok, d}

      {{:ok, d}, {:ok, e}} ->
        cond do
          Enum.count(e) === 0 -> {:ok, d}
          true -> {:with_error, d, e}
        end
    end
  end

  defp process_headers(headers) when is_map(headers) do
    case {Map.has_key?(headers, :"content-type"), Map.has_key?(headers, "content-type")} do
      {false, false} -> Map.merge(Enum.into(default_content_type(), %{}), headers)
      {_, _} -> headers
    end
  end

  defp process_headers(headers) when is_list(headers) do
    Keyword.merge(default_content_type(), headers)
  end

  defp default_content_type, do: ["content-type": "application/json"]

  @spec merge_query(request :: Request.t()) :: Request.t()
  defp merge_query(request) do
    query =
      cond do
        is_map(request.query) -> Map.merge(request.query, request.extras)
        is_binary(request.query) -> Map.merge(%{query: request.query}, request.extras)
        true -> raise ArgumentError
      end

    %{request | query: query, extras: %{}}
  end
end
