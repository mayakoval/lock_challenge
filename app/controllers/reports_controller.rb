require 'csv'
class ReportsController < ApplicationController
	skip_before_action :verify_authenticity_token
	before_action :authenticate_server
	def handle
		# process the csv file sent in the request
		report = params[:sample].open
		csv_options = { col_sep: ',', headers: :first_row }
		CSV.parse(report, csv_options) do |timestamp, lock_id, kind, status_change|
			lock = Lock.find(lock_id[1])
			# check if the lock exists
			if lock
				lock.status = status_change
				lock.save
			else
				Lock.create(id: lock_id, kind: kind, status_change: status_change)
			end
			# create lock entry with all entries from csv
			Entry.create(timestamp: timestamp[1], status_change: status_change[1], lock: lock)
		end
		render json: { message: "The report for your #{Lock.count} locks has been updated with #{Entry.count} entries." }
	end

	def authenticate_server
		code_name = request.headers['X-Server-CodeName']
		server = Server.find_by(code_name: code_name)
		access_token = request.headers['X-Server-Token']
		# check if there is an existing server instance
		# and it has correct credentials
		unless server && server.access_token == access_token
			render json: { message: 'Wrong credentials' }
		end
	end
end
