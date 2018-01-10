# frozen_string_literal: true

class VendorsController < ApplicationController
  before_action :set_vendor, only: %i[show packages]

  def index
    @vendors = vendors.all(q: params[:q], page: params[:page])
    render jsonapi: @vendors.vendors.to_a,
           meta: { totalResults: @vendors.totalResults }
  end

  def show
    render jsonapi: @vendor, include: params[:include]
  end

  # Relationships
  def packages
    @packages = @vendor.find_packages(page: params[:page])
    render jsonapi: @packages.packagesList.to_a,
           meta: { totalResults: @packages.totalResults }
  end

  private

  def set_vendor
    @vendor = vendors.find params[:id]
  end

  def vendors
    Vendor.configure config
  end
end
