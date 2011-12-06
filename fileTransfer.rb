

require 'digest/md5'
require 'socket'
require 'openssl'
require 'digest/sha1'

#	Redes De Computadores 
#	Professor Mauricio PIlla 
#	Trabalho2 -- File transfer --
#	--
#	-- Transferir um arquiro com segurança e confiabilidade 
#       -- Israel Silva Barbará e  Paulo Eugenio Ferreira Fernandes  
#


# Verifica se o caminho do pedido é um caminho possivel 

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


def  fileProcess(request )
strfile  = ""
resposta = ""
request_part = request.split(",")
caminho = request_part[1].chomp
idpedido = request_part[0]
	if (!verifyDir( caminho )) then 			# verifica se o caminho para o arquivo é possivel
		resposta = " -- Bad File Request -- "
	else
		if(File.exist?(caminho)) then				# testa a existencia do arquivo
			puts "open the file"			
			myfile  = File.open( caminho )			# Abre o arquivo
			strfile << myfile.read 				# Passa o arquivo para a string strfile
		else	
			puts "nao abriu o arquivo"			
			resposta = " 404 File Not Found "	
		end		
	end

## Cria hash md5 para o texto
hashtext = Digest::MD5.hexdigest(strfile)

## Aplica criptografia Simetrica aes (256)

crypt = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
crypt.encrypt

crypt.key = key = Digest::SHA1.hexdigest("PASSWORD")					# cria uma chave a partir da chave passada pelo usuario
crypt.iv = iv = crypt.random_iv

resposta = crypt.update(strfile)						# criptografa a mensagem com a chave key
resposta << crypt.final

resposta = resposta + "|||||" + hashtext
resposta =  iv + "|||||" + resposta					# concatena chave e iv a resposta
##
## Criptografia de chave publica /privada

resposta = cryptPPV( key,resposta,idpedido)

return resposta 
end



def cryptPPV( key,resposta , idpedido)

	pedidoPF    = "./" + idpedido.chomp + "_new_public.pem"				#abre public key so pedido	
	public_key  = OpenSSL::PKey::RSA.new(File.read(pedidoPF))
	cipher_key = public_key.public_encrypt( key )
	resposta = cipher_key + "|||||" + resposta
	
	# CRIPTO O ID COM A CHAVE PRIVADA TUA
	private_file = "./" + $id.chomp + "_new_private.pem"
	private_key  = OpenSSL::PKey::RSA.new(File.read(private_file)) 
	chipher_id   = private_key.private_encrypt($id)					#crypt ,chave privada na assinatura	
			
	resposta = chipher_id + "|||||" + resposta	
return resposta
end


############################################################
##


puts "digite a identificaçao do seu PC :"
$id = ""
$id = gets

id_path = "./" + $id.chomp + "_new_public.pem"
id_private_path = "./" + $id.chomp + "_new_private.pem"

if (!(File.exist?(id_path) or File.exist?(id_private_path))) then
	
	new_key = OpenSSL::PKey::RSA.generate( 1024 )
	# write the new keys as PEM's
	new_public = new_key.public_key
	output_public = File.new(id_path, "w")
	output_public.puts new_public
	output_public.close


	new_private = new_key.to_pem
	output_private = File.new(id_private_path, "w")
	output_private.puts new_private
	output_private.close

end

## Espera por uma conexao e pedido , 
## Processa o pedido e o retorna

servidor = TCPServer.open("127.0.0.1" , 8080)   				# Socket to listen on port 
puts "--------Esperando  conexao --------"
loop {                          						# Servers run forever
request,answer = "",""
  Thread.start(servidor.accept) do |client|		

	while line = client.gets   						# Read lines from the socket			
		if (line == "\r\n") then break end				# until the client prints an empty line  	
		request << line	
	end	

	answer = fileProcess(request)
	client.puts(answer) 							# devolve para o cliente o pedido http processado        
	client.close 								# Disconnect from the client
  end
}

