defmodule ShinobiWeb.PageController do
  use ShinobiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
