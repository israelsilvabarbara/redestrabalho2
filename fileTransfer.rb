
require 'socket'
require 'openssl'
require 'digest/sha1'

#	Redes De Computadores 
#	Professor Mauricio PIlla 
#	Trabalho2 -- File transfer --
#	--
#	-- Transferir um arquiro com segurança e confiabilidade 
#	-- Israel Silva Barbará
#


# Verifica se o caminho do pedido é um caminho possivel 
#
def verifyDir( arqfonte) 	
	i =0
	validarq = true
	diretorio = arqfonte.split("/")  		
	while(i < diretorio.size ) do
		if(diretorio[i] == "..") then
			validarq = false
		end
		i = i +1
	end
return validarq	
end



def  fileProcess(request , chave)
puts "#########FILE PROCESS #########\n"
strfile  = ""
resposta = ""
request_part = request.split(",")
caminho = request_part[1].chomp
idpedido = request_part[0]
	if (!verifyDir( caminho )) then 			# verifica se o caminho para o arquivo é possivel
		resposta = " -- Bad File Request -- "
	else
		puts caminho
		if(File.exist?(caminho)) then				# testa a existencia do arquivo
			puts "open the file"			
			myfile  = File.open( caminho )			# Abre o arquivo
			strfile << myfile.read 				# Passa o arquivo para a string strfile
		else	
			puts "nao abriu o arquivo"			
			resposta = " 404 File Not Found "	
		end	
	
	end

## Aplica criptografia Simetrica aes (256)
puts "crypt simetrica no texto"
crypt = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
crypt.encrypt


crypt.key = key = Digest::SHA1.hexdigest(chave)					# cria uma chave a partir da chave passada pelo usuario
crypt.iv = iv = crypt.random_iv

resposta = crypt.update(strfile)						# criptografa a mensagem com a chave key
resposta << crypt.final
puts "encrypted: #{resposta}\n"
puts "agora vai decriptografar para teste\n"

#c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
#c.decrypt
#
#c.key = key
#c.iv = iv
#d = c.update(resposta)
#d << c.final
#puts "decrypted: #{d}\n\n\n"

resposta =  iv + "," + resposta					# concatena chave e iv a resposta


##
## Criptografia de chave publica /privada
puts "a resposta ate agora ta assim --\n#{resposta}\n"
resposta = cryptPPV( key,resposta,idpedido)


return resposta 
end


def cryptPPV( key,resposta , idpedido)
	
	puts "##############CRYPT PPV #############"
	# CRIPTO O ID COM A CHAVE PRIVADA TUA
	puts "\n#{$id}\n"	
	private_file = "./" + $id.chomp + "_new_private.pem"
	private_key  = OpenSSL::PKey::RSA.new(File.read(private_file)) 
	chipher_id   = private_key.private_encrypt($id)					#crypt ,chave privada na assinatura	
	

	pedidoPF    = "./" + idpedido.chomp + "_new_public.pem"				#abre public key so pedido	
	puts pedidoPF
	public_key  = OpenSSL::PKey::RSA.new(File.read(pedidoPF))
	puts "sdiauhdiuahiudhaiuhdiau"	
	cipher_text = public_key.public_encrypt( key )
	resposta = key + "," + resposta
	puts "chave criptografada com a chave publica pedido: \n"	
	puts cipher_text

	resposta = chipher_id + "," + resposta	
	puts resposta
return resposta
end


############################################################
##

$id = ""
puts "digite a identificaçao do seu PC :"
$id = gets


# .generate creates an object containing both keys
new_key = OpenSSL::PKey::RSA.generate( 1024 )
# write the new keys as PEM's
new_public = new_key.public_key.to_pem			###!!!! alterei , coloquei .to_pem para conseguir ler o arquivo
$publicfile = "./" + $id.chomp + "_new_public.pem"
output_public = File.new($publicfile, "w")
output_public.puts new_public
output_public.close
	
new_private = new_key.to_pem
$privatefile = "./" + $id.chomp + "_new_private.pem"
output_private = File.new($privatefile, "w")
output_private.puts new_private
output_private.close

## Espera por uma conexao e pedido , 
## Processa o pedido e o retorna

#serv = Thread.new{
	chave = ""
	puts " --Digite a chave que sera usada para encriptar: "
	chave = gets 
	servidor = TCPServer.open("127.0.0.1" , 8080)   				# Socket to listen on port 
	loop {                          						# Servers run forever
	request,answer = "",""
	  Thread.start(servidor.accept) do |client|		
		while line = client.gets   						# Read lines from the socket			
			if (line == "\r\n") then break end				# until the client prints an empty line  	
			request << line	
		end	
		puts request
		answer = fileProcess(request, chave)
		client.puts(answer) 							# devolve para o cliente o pedido http processado        
		puts answer
		client.close 								# Disconnect from the client
	  end
	}
#}

#serv.join
puts "sduhaiuidahidaiudha"
