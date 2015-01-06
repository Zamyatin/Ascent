class FlightsController < ApplicationController
  def index
    @flights = Flight.all

    if current_user
      friends_array = []
      current_user.friends.each do |friend|
        friend.flights.each do |flight|
          friends_array << flight
        end
      end
      @friends_flights = friends_array.sort_by { |flight| flight.created_at }.reverse
    end

    likes_hash = {}
    @flights.each { |flight| likes_hash[flight] = flight.likes.count }
    liked_nested_array = likes_hash.sort_by {|k,v| v}.reverse
    @most_liked = liked_nested_array.map { |nested_array| nested_array[0] }

    @latest = @flights.order(created_at: :desc).limit(10)
    @flights_near_you = Flight.all.limit(3)
    @highest_altitude = @flights.order(max_altitude: :desc).limit(10)
    @longest_duration = @flights.order(duration: :desc).limit(10)
  end

  def show
    @flight = Flight.find(params[:id])
    @data_points = @flight.data_points
    @f_comments = @flight.comments.order(created_at: :desc)
  end

  def create
    flight = new_user_flight.import_from_habhub(flight_params[:address])
    redirect_to flight_path(flight)
  end

  def import
    flight = new_user_flight.import_from_csv(params[:file])
    redirect_to new_flight_picture_path(flight), notice: "Your flight has been imported."
  end

  def feed
    @flights = current_user.all_friends.collect{|x| x.flights}.flatten.sort_by{|x| x.created_at}
  end

  private

  def new_user_flight
    @flight = Flight.create
    @launch = Launch.create(user_id: current_user.id, flight_id: @flight.id)
    @flight
  end

  def flight_params
    params.require(:new_flight).permit(:address, :user_id)
  end

end
