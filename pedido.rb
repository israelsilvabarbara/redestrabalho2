require 'socket'
require 'openssl'

def decrypt(answer,parte_answer)
	
	assinatura   = parte_answer[0]
	key          = parte_answer[1]
	iv	     = parte_answer[2]
	chipher_text = parte_answer[3] 
	hashtext     = parte_answer[4]

	public_file = "./" + $id_retorno.chomp + "_new_public.pem"
	public_key = OpenSSL::PKey::RSA.new(File.read(public_file))
	assinatura = public_key.public_decrypt(assinatura)

	if(assinatura != $id_retorno) then 
		puts "assinatura nao conrresponde\n"
		#break
	else	
		private_key  = OpenSSL::PKey::RSA.new(File.read($id_private_path))
		key = private_key.private_decrypt(key)
	end

	c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
	c.decrypt

	c.key = key
	c.iv = iv
	decrypted_text = c.update(chipher_text)
	decrypted_text << c.final	

	puts "-- Decrypted: #{decrypted_text}\n"

	return decrypted_text,hashtext
end



socket = TCPSocket.open("127.0.0.1", 8080)

$id = ""
puts "digite a identificaçao do seu PC :"
$id = gets

$id_retorno = ""
puts "digite com id do pc o qual deseja fazer a transferencia:"
$id_retorno = gets

$id_path = "./" + $id.chomp + "_new_public.pem"
$id_private_path = "./" + $id.chomp + "_new_private.pem"

# Testa a existencia da chave publica e privada
if (!(File.exist?($id_path) || File.exist?($id_private_path) )) then

	new_key = OpenSSL::PKey::RSA.generate( 1024 )


	# write the new keys as PEM's

	new_public = new_key.public_key.to_pem

	output_public = File.new($id_path, "w")
	output_public.puts new_public
	output_public.close

	new_private = new_key.to_pem

	output_private = File.new($id_private_path, "w")
	output_private.puts new_private
	output_private.close
end


puts "digite o caminho para o arquivo desejado: "
path = gets

pedido = $id.chomp + "," + path + "\r\n" 
hash = ""
hashtext = "..."

loop{

	socket.print(pedido)
	answer = socket.read

	parte_answer = answer.split("|||||",5)

	decrypted_text,hashtext = decrypt(answer,parte_answer)
	hash = Digest::MD5.hexdigest(decrypted_text)				# faz a hash com o texto decriptografado 
	
	hashtext.chop!
	if ( hashtext == hash ) then 
		puts "Mensagem recebida corretamente"
		exit 

	end
	puts "hash nao deu certo"
	ruu = gets
}





