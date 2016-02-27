class HomeController < ApplicationController
  def index
    @posters = Poster.select("sku, name, price").to_a
  end
end
