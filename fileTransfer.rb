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
strfile  = ""
resposta = ""
	if (!verifyDir( request )) then 			# verifica se o caminho para o arquivo é possivel
		resposta = " -- Bad File Request -- "
	else
		if(File.exist?(filelocal)) then				# testa a existencia do arquivo
			myfile  = File.open( request )			# Abre o arquivo
			strfile << myfile.read 				# Passa o arquivo para a string strfile
		else	
			resposta = " 404 File Not Found "	
		end	
	
	end

## Aplica criptografia Simetrica aes (256)

crypt = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
crypt.encrypt


crypt.key = key = Digest::SHA1.hexdigest(chave)					# cria uma chave a partir da chave passada pelo usuario
crypt.iv = iv = crypt.random_iv

resposta = crypt.update(request)						# criptografa a mensagem com a chave key
resposta << crypt.final
#puts "encrypted: #{e}\n"
resposta = chave + "," + iv + "," + resposta					# concatena chave e iv a resposta


##
## Criptografia de chave publica /privada

resposta = cryptPPV(resposta)


return resposta 
end


def cryptPPV(resposta)



return reposta
end


$id = ""
puts "digite a identificaçao do seu PC :"
$id = gets

message = "This is some cool text."
puts "\nOriginal Message: #{message}\n"
puts "Using ruby-openssl to generate the public and private keys\n"

# .generate creates an object containing both keys
new_key = OpenSSL::PKey::RSA.generate( 1024 )
# write the new keys as PEM's
new_public = new_key.public_key.to_pem			###!!!! alterei , coloquei .to_pem para conseguir ler o arquivo
publicfile = "./" + $id + "_new_public.pem"
output_public = File.new(publicfile, "w")
output_public.puts new_public
output_public.close
	
new_private = new_key.to_pem
privatefile = "./" + $id + "_new_private.pem"
output_private = File.new(privatefile, "w")
output_private.puts new_private
output_private.close



## Espera por uma conexao e pedido , 
## Processa o pedido e o retorna

Thread.new{
	chave = ""
	puts " --Digite a chave que sera usada para encriptar: "
	chave = gets 
	servidor = TCPServer.open("127.0.0.1" , port)   				# Socket to listen on port 
	loop {                          						# Servers run forever
	request,answer = "",""
	  Thread.start(servidor.accept) do |client|		
		while line = client.gets   						# Read lines from the socket			
			if (line == "\r\n") then break end				# until the client prints an empty line  	
			request << line	
		end	

		answer = fileProcess(request, chave)
		client.puts(answer) 							# devolve para o cliente o pedido http processado        
		client.close 								# Disconnect from the client
	  end
	}
}


