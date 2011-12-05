require 'socket'
require 'openssl'

if (ARGV[0] == nil) then
    puts "erro. digite: ruby pedido.rb 'ip_servidor'\n"
    exit
end

socket = TCPSocket.open(ARGV[0], 8080)

$id = ""
puts "digite a identificaçao do seu PC :"
$id = gets

id_retorno = ""
puts "digite com id do pc o qual deseja fazer a transferencia:"
id_retorno = gets

id_path = "./" + $id.chomp + "_new_public.pem"
id_private_path = "./" + $id.chomp + "_new_private.pem"

# Testa a existencia da chave publica e privada
if (!(File.exist?(id_path) || File.exist?(id_private_path) )) then

	new_key = OpenSSL::PKey::RSA.generate( 1024 )


	# write the new keys as PEM's

	new_public = new_key.public_key.to_pem

	output_public = File.new(id_path, "w")
	output_public.puts new_public
	output_public.close

	new_private = new_key.to_pem

	output_private = File.new(id_private_path, "w")
	output_private.puts new_private
	output_private.close
end


puts "digite o caminho para o arquivo desejado: "
path = gets

pedido = $id.chomp + "," + path + "\r\n" 
socket.print(pedido)
answer = socket.read

parte_answer = answer.split("|||||",4)
assinatura   = parte_answer[0]
key          = parte_answer[1]
iv	     = parte_answer[2]
chipher_text = parte_answer[3] 


public_file = "./" + id_retorno.chomp + "_new_public.pem"
public_key = OpenSSL::PKey::RSA.new(File.read(public_file))
puts assinatura
assinatura = public_key.public_decrypt(assinatura)

if(assinatura != id_retorno) then 
	puts "assinatura nao conrresponde\n"
	#break
else
	puts "assinatura ; #{assinatura}"	
	private_key  = OpenSSL::PKey::RSA.new(File.read(id_private_path))
	key = private_key.private_decrypt(key)
	puts "\n\n------------------ " + key
end

c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
c.decrypt

c.key = key
c.iv = iv
decrypted_text = c.update(chipher_text)
puts "-------------------------- " + decrypted_text
puts "decrypted: #{decrypted_text}\n"



