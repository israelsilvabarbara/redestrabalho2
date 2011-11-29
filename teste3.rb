require 'socket'


ipadress = IPSocket.getaddress(Socket.gethostname())   			# gets the ip adress
puts" ipadress = #{ipadress}"
