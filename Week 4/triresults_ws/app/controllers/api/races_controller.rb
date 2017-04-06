module Api
  class RacesController < ApplicationController

    rescue_from ActionView::MissingTemplate do |exception|
      Rails.logger.debug exception
      render plain: "woops: we do not support that content-type[#{request.accept}]", status: :unsupported_media_type
    end

    rescue_from Mongoid::Errors::DocumentNotFound do |exception|
      if !request.accept || request.accept == "*/*"
        render plain: "woops: cannot find race[#{params[:id]}]", status: :not_found
      else
        render :status=>:not_found,
               :template=>"api/error_msg",
               :locals=>{ :msg=> "woops: cannot find race[#{params[:id]}]"}
      end
    end

    def index
      if !request.accept || request.accept == "*/*"
        render plain: "/api/races, offset=[#{params[:offset]}], limit=[#{params[:limit]}]", status: :ok
      end
    end

    def show
      if !request.accept || request.accept == "*/*"
        render plain: "/api/races/#{params[:id]}"
      else
        set_race
        render 'race', status: :ok
      end
    end

    def create
      if !request.accept || request.accept == "*/*"
        render plain: "#{params[:race][:name]}", status: :ok
      else
        race = Race.new(race_params)
        if race.save
          render plain: race.name, status: :created
        end
      end
    end

    def update
      Rails.logger.debug("method=#{request.method}")
      @race = Race.find(params[:id])
      if @race.update(race_params)
          render json: @race, status: :ok
      end
    end

    def destroy
      set_race
      if set_race.destroy
        render nothing: true, status: :no_content
      end
    end

    private

    def set_race
      @race = Race.find(params[:id])
    end

    def race_params
      params.require(:race).permit(:name, :date)
    end
  end
end