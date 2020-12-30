# Trabalho 2 - Jogo de naves
# Aleixo Damas Neto
# NUSP: 10310975


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Pre-set
# "Bitmap Display" limpo e conectado ao Mars:
#	Cada pixel com 4 unidades de altura e largura;
#	Tela com 64 pixels de altura e largura (ou 256x256 na janela da ferramenta);
#	Memoria dos dados da tela é a estática (a partir do 0x10010000 até 0x10011000);
# "Keybord and Display MMIO" limpo e conectado ao Mars (apenas keyboard usada).

		.data
screen_data:	.space	0x00001000		# Reserva o espaço de memoria para o bitmap


		.text
		.globl 	main


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


main:		li	$s0, 25			# Nave inicia no meio da tela
		li	$s1, 0x0000FFFF		# Redesenha uma posição a cima
		jal	ally_ship		# Desenha a nave inicialmente

		li	$s4, 0x00000000		# Inicia sem naves nem tiros inimigos
		li	$s6, 0			# Contador de loop de atualização de tela para
						#	temporização de animação dos tiros inimigos
		li	$s7, 0			# Contador de loop de atualização de tela para
						#	temporização de animação do tiro aliado

		li	$t7, 0			# Pré-seta a posição horizontal do tiro 1
		li	$t6, 0			# Pré-seta a posição horizontal do tiro 2
		li	$t5, 0			# Pré-seta a posição horizontal do tiro 3
		li	$t4, 0			# Pré-seta a posição horizontal do tiro 4

main_loop:	li	$s2, 0			# Reseta registrador de input do MMIO
		jal	MMIO_read		# Verifica input pelo terminal MMIO

		jal	ally_ctrl		# Move a nave aliada se o comando foi para ela
		
		jal	ally_shot		# Inicia e executa a animação do tiro

		jal	enemy_entities

		bne	$s2, 'q', main_loop	# Verifica se foi inserido comando de quit

		li	$v0, 10
		syscall				# Encerra o programa


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que le o terminal MMIO se algo foi inserido (Se nada foi inserido, simplesmente nada 
# acontece).
#	s2 - Comando dado pelo teclado;
#	Usa reg temporário t0.

MMIO_read:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha o endereço de chamada

		lw	$t0, 0xFFFF0000		# Leio o sinal de entrada de dados pelo teclado
		andi	$t0, $t0, 0x00000001	# Apenas o ultimo bit é importante
		beqz	$t0, end_MMIO_read	# Se zero, não ouve atividade no teclado, s2 não é
						#	atualizado, subrotina é encerrada
		
		lw	$s2, 0xFFFF0004		# CC, s2 é atualizado

end_MMIO_read:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que verifica se a entrada do loop foi compatível com os comandos de subida e de descida
# da nave.
#	s2 - Comando dado pelo teclado.

ally_ctrl:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

go_up_ally:	bne	$s2, 'w', go_down_ally	# Verifica se o comando inserido foi 'w'
		li	$s2, 0x00000000		# Limpra s2 para não entrar na verificação no
						#	proximo loop
		beq	$s0, 1, go_down_ally	# Verifica se a nave já não está na linha mais alta
		li	$s1, 0x00000000
		jal	ally_ship		# Apaga
		sub	$s0, $s0, 1		# Decrementa posição
		li	$s1, 0x0000FFFF
		jal	ally_ship		# Redesenha

go_down_ally:	bne	$s2, 's', end_ally_ctrl	# Verifica se o comando inserido foi 's'
		li	$s2, 0x00000000		# Limpra s2 para não entrar na verificação no
						#	proximo loop
		beq	$s0, 52, end_ally_ctrl	# Verifica se a nave já não está na linha mais baixa
		li	$s1, 0x00000000
		jal	ally_ship		# Apaga
		add	$s0, $s0, 1
		li	$s1, 0x0000FFFF
		jal	ally_ship		# Redesenha

end_ally_ctrl:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que atualiza o desenho da nave aliada na tela dada duas posições verticais da asa de cima.
#	s0 - Posição da nave;
#	s1 - Cor do pixel (controla se "apaga" ou "acende" o pixel);
#	Usa reg temporário t0.

ally_ship:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		mul	$t0, $s0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel

		# Desenha pixel a pixel a nave no bitmap display a partir a linha dada
		addi	$t0, $t0, 20
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 256
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 252
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 252
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 252
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 244
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 244
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 248
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 252
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 256
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 256
		sw	$s1, screen_data($t0)

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que verifica se o comando para tipo foi inserido, e caso ja haja um tiro na tela, ela
# executa uma etapa da animação do tiro.
#	s0 - Posição da nave;
#	s2 - Comando dado pelo teclado;
#	s7 - Contador para definição de frequência de "frame" da animação de tiro;
#	t8 - Posição vertical do tiro (baseado em onde a nave alida estava quando atirou);
#	t9 - Posição horizontal do tiro (incrementada ao longo da animação):
#		Se t9 = 0, não há tiro, um novo pode ser executado.

ally_shot:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		beqz	$t9, new_ally_shot	# Se não existe tiro na tela, segue para
						# 	verificação de novo tiro.
						# CC, segue para a execução da animação de tiro.

		addu	$s7, $s7, 1		# Contagem de "frames" para o proximo quadro da 
						#	animação.

		bne	$s7, 0x00000100, end_ally_shot
						# Ajuste de frequencia de animação.
						#	Animação é executada a cada 100 "frames"
		jal	ally_shot_anim		

		bne	$t9, 252, end_ally_shot	# Verifica se o tiro chegou ao final da tela.
		jal	ally_shot_del		# Apaga o tiro e reseta os registradores


new_ally_shot:	bne	$s2, ' ', end_ally_shot	# Se houve comando de tiro, executa definição de
						# variáveis.
						# CC, encerra subrotina
		li	$s2, 0x00000000		# Limpra s2 para não entrar na verificação no
						#	proximo loop

		li	$s7, 0			# Reseta o contador para a animação

		move	$t8, $s0
		addi	$t8, $t8, 5		# Linha de pixels que passa pelo centro na nave
		li	$t9, 40

end_ally_shot:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função de animação do tiro aliado.
#	s7 - Contador para definição de frequência de "frame" da animação de tiro;
#	t8 - Posição vertical do tiro (baseado em onde a nave alida estava quando atirou);
#	t9 - Posição horizontal do tiro (incrementada ao longo da animação):
#	Usa regs temporários t0 e t1.

ally_shot_anim:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		li	$s7, 0

		mul	$t0, $t8, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t9		# Adiciona a posição horizontal do tiro

		li	$t1, 0x0000FF00
		sw	$t1, screen_data($t0)	# Desenha o ponto da frente do tiro

		subi	$t0, $t0, 4

		li	$t1, 0x0000FF00
		sw	$t1, screen_data($t0)	# Desenha o ponto de trás do tiro. Só faz algo no
						#	primeiro frame, mas n vale à pela verificar

		subi	$t0, $t0, 4

		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Apaga o ponto de trás do frame anterior

		addi	$t9, $t9, 4		# Incrementa para a próxima posição do tiro

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que encerra o tiro aliado quando ele chega ao fim da tela ou atinge uma nave inimiga.
#	t8 - Posição vertical do tiro (baseado em onde a nave alida estava quando atirou);
#	t9 - Posição horizontal do tiro (incrementada ao longo da animação):
#	Usa regs temporários t0 e t1.

ally_shot_del:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		mul	$t0, $t8, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t9		# Adiciona a posição horizontal do tiro
		subi	$t0, $t0, 4

		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Desenha o ponto da frente do tiro

		subi	$t0, $t0, 4

		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Desenha o ponto de trás do tiro. Só faz algo no
						#	primeiro frame, mas n vale à pela verificar
		li	$t9, 0			# Reseta t9 pra novo tiro

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que gerencia as naves e tiros inimigos
#	s3 - Posição vertical da nave inimiga a ser desenhada na tela;
#	s4 - Registrador de 8 nibbles (4 tiros e 4 naves - F se a entidade existe, 0 se não existe).

enemy_entities:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		bnez	$s4, enemy_verif	# Se não há naves nem tiros na tela, as 4 naves são
						#	desenhadas.
						# CC, sege para as verificações de naves e tiros
						#	inimigos.
		li	$s4, 0x0000FFFF		# "Anotas" as 4 naves como desenhadas

		li	$s3, 6			# Posição vertical da 1a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
		addi	$s3, $s3, 15		# Posição vertical da 2a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
		addi	$s3, $s3, 15		# Posição vertical da 3a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
		addi	$s3, $s3, 15		# Posição vertical da 4a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
enemy_verif:	jal	enemy_cllsion		# Verifica colisão do tiro aliado com as naves
						#	inimigas
		jal	enemy_shots		# Verifica o lançamento de um tiro inimigo em 
						#	direção à nave aliada

end_enemy_entts:lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que, dada uma posição vertical, desenha ou apaga uma nave inimiga no bitmap display.
#	s1 - Cor do pixel (controla se "apaga" ou "acende" o pixel);
#	s3 - Posição nave verticalmente;
#	Usa reg temporário t0.

enemy_ship:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		mul	$t0, $s3, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel

		# Desenha pixel a pixel a nave no bitmap display a partir a linha dada
		addi	$t0, $t0, 220
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 256
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 256
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 244
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 252
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 244
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 4
		sw	$s1, screen_data($t0)
		addi	$t0, $t0, 252
		sw	$s1, screen_data($t0)

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que verifica se algum tiro aliado atingiu uma nave inimiga, contabiliza a colizão no
# registrador s4 e apaga da tela tanto tiro como nave.
#	s1 - Cor do pixel (controla se "apaga" ou "acende" o pixel);
#	s3 - Posição nave verticalmente;
#	s4 - Registrador de 8 nibbles (4 tiros e 4 naves - F se a entidade existe, 0 se não existe);
#	t8 - Posição vertical do tiro;
#	t9 - Posição horizontal do tiro;
#	Usa reg temporário t0.

enemy_cllsion:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		bne	$t9, 220, end_enemy_cll	# Verifica se o tiro atingiu o nível horizontal das
						#	naves inimigas

enemy_cll_1:	andi	$t0, $s4, 0x0000000F	# Filtra o indicador da primeira nave
		bne	$t0, 0x0000000F, enemy_cll_2
						# Se a nave existe, é verificada se teve colisão
		blt	$t8, 6, enemy_cll_2	# Verifica se o tiro acertaria a nave
		bgt	$t8, 12, enemy_cll_2	# Verifica se o tiro acertaria a nave
		li	$s3, 6			# Posição vertical da 1a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFFFFF0	# Apaga a nave no indicador de entidade

enemy_cll_2:	andi	$t0, $s4, 0x000000F0	# Filtra o indicador da primeira nave
		bne	$t0, 0x000000F0, enemy_cll_3
						# Se a nave existe, é verificada se teve colisão
		blt	$t8, 21, enemy_cll_3	# Verifica se o tiro acertaria a nave
		bgt	$t8, 27, enemy_cll_3	# Verifica se o tiro acertaria a nave
		li	$s3, 21			# Posição vertical da 2a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFFFF0F	# Apaga a nave no indicador de entidade

enemy_cll_3:	andi	$t0, $s4, 0x00000F00	# Filtra o indicador da primeira nave
		bne	$t0, 0x00000F00, enemy_cll_4
						# Se a nave existe, é verificada se teve colisão
		blt	$t8, 36, enemy_cll_4	# Verifica se o tiro acertaria a nave
		bgt	$t8, 42, enemy_cll_4	# Verifica se o tiro acertaria a nave
		li	$s3, 36			# Posição vertical da 3a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFFF0FF	# Apaga a nave no indicador de entidade

enemy_cll_4:	andi	$t0, $s4, 0x0000F000	# Filtra o indicador da primeira nave
		bne	$t0, 0x0000F000, end_enemy_cll
						# Se a nave existe, é verificada se teve colisão
		blt	$t8, 51, end_enemy_cll	# Verifica se o tiro acertaria a nave
		bgt	$t8, 57, end_enemy_cll	# Verifica se o tiro acertaria a nave
		li	$s3, 51			# Posição vertical da 4a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFF0FFF	# Apaga a nave no indicador de entidade

end_enemy_cll:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Função que observa as naves inimigas existentes e a posição da nave inimiga para determinar um
# um ataque inimigo.
#	t7 - Posição horizontal do tiro 1
#	t6 - Posição horizontal do tiro 2
#	t5 - Posição horizontal do tiro 3
#	t4 - Posição horizontal do tiro 4

enemy_shots:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		addu	$s6, $s6, 1		# Contagem de "frames" para o proximo quadro da 
						#	animação.

		bne	$s6, 0x00000300, end_ally_shot
						# Ajuste de frequencia de animação.
						#	Animação é executada a cada 150 "frames"
		li	$s6, 0x00000000

enemy_shot_1:	andi	$t0, $s4, 0x000F000F	# Filtra a existencia da primera nave e primeiro 
						#	tiro
		bne	$t0, 0x0000000F, enemy_anim_1
						# Se não existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verificação

		bgt	$s0, 7, enemy_anim_1

		# Inicia tiro 1
		ori	$s4, $s4, 0x000F0000	# Adiciona o tiro no indicador de entidades
		li	$t7, 208		# Seta nível horizontal to tiro

enemy_anim_1:	andi	$t0, $s4, 0x000F0000	# Filtra a existencia do primero tiro
		bne	$t0, 0x000F0000, enemy_shot_2
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da animação.
						# CC, continua a verificação

		# Roda a animaçao
		li	$t0, 9
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t7		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de animação do tiro
		subi	$t7, $t7, 4

		# Verifica se chegou à extremidade direita da tela
		bnez	$t7, clsion_shot_1	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0xFFF0FFFF	# Retira o tiro do indicador de entidades

		li	$t0, 9
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t7		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00000000
		jal	enemy_shot_anim		# Apaga o tiro no final da tela

		li	$t7, 0
		
clsion_shot_1:	bne	$t7, 20, enemy_shot_2
		bgt	$s0, 9, enemy_shot_2

		li	$v0, 10
		syscall				# Encerra o programa

enemy_shot_2:	andi	$t0, $s4, 0x00F000F0	# Filtra a existencia da primera nave e primeiro 
						#	tiro
		bne	$t0, 0x000000F0, enemy_anim_2
						# Se não existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verificação

		bgt	$s0, 22, enemy_anim_2
		blt	$s0, 15, enemy_anim_2

		ori	$s4, $s4, 0x00F00000	# Adiciona o tiro no indicador de entidades

		# Inicia tiro 2
		ori	$s4, $s4, 0x00F00000	# Adiciona o tiro no indicador de entidades
		li	$t6, 208		# Seta nível horizontal to tiro

enemy_anim_2:	andi	$t0, $s4, 0x00F00000	# Filtra a existencia do primero tiro
		bne	$t0, 0x00F00000, enemy_shot_3
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da animação.
						# CC, continua a verificação

		# Roda a animaçao
		li	$t0, 24
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t6		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de animação do tiro
		subi	$t6, $t6, 4

		# Verifica se chegou à extremidade direita da tela
		bnez	$t6, clsion_shot_2	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0xFF0FFFFF	# Retira o tiro do indicador de entidades

		li	$t0, 24
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t6		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00000000
		jal	enemy_shot_anim		# Apaga o tiro no final da tela

		li	$t6, 0
		
clsion_shot_2:	bne	$t6, 20, enemy_shot_3
		bgt	$s0, 24, enemy_shot_3
		blt	$s0, 14, enemy_shot_3

		li	$v0, 10
		syscall				# Encerra o programa

enemy_shot_3:	andi	$t0, $s4, 0x0F000F00	# Filtra a existencia da primera nave e primeiro 
						#	tiro
		bne	$t0, 0x00000F00, enemy_anim_3
						# Se não existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verificação

		bgt	$s0, 37, enemy_anim_3
		blt	$s0, 30, enemy_anim_3

		ori	$s4, $s4, 0x0F000000	# Adiciona o tiro no indicador de entidades

		# Inicia tiro 3
		ori	$s4, $s4, 0x0F000000	# Adiciona o tiro no indicador de entidades
		li	$t5, 208		# Seta nível horizontal to tiro

enemy_anim_3:	andi	$t0, $s4, 0x0F000000	# Filtra a existencia do primero tiro
		bne	$t0, 0x0F000000, enemy_shot_4
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da animação.
						# CC, continua a verificação

		# Roda a animaçao
		li	$t0, 39
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t5		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de animação do tiro
		subi	$t5, $t5, 4

		# Verifica se chegou à extremidade direita da tela
		bnez	$t5, clsion_shot_3	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0xF0FFFFFF	# Retira o tiro do indicador de entidades

		li	$t0, 39
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t5		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00000000
		jal	enemy_shot_anim		# Apaga o tiro no final da tela

		li	$t5, 0
		
clsion_shot_3:	bne	$t5, 20, enemy_shot_4
		bgt	$s0, 39, enemy_shot_4
		blt	$s0, 29, enemy_shot_4

		li	$v0, 10
		syscall				# Encerra o programa

enemy_shot_4:	andi	$t0, $s4, 0xF000F000	# Filtra a existencia da primera nave e primeiro 
						#	tiro
		bne	$t0, 0x0000F000, enemy_anim_4
						# Se não existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verificação

		blt	$s0, 45, enemy_anim_4

		ori	$s4, $s4, 0xF0000000	# Adiciona o tiro no indicador de entidades

		# Inicia tiro 4
		ori	$s4, $s4, 0xF0000000	# Adiciona o tiro no indicador de entidades
		li	$t4, 208		# Seta nível horizontal to tiro

enemy_anim_4:	andi	$t0, $s4, 0xF0000000	# Filtra a existencia do primero tiro
		bne	$t0, 0xF0000000, end_enemy_shots
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da animação.
						# CC, continua a verificação

		# Roda a animaçao
		li	$t0, 54
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t4		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de animação do tiro
		subi	$t4, $t4, 4

		# Verifica se chegou à extremidade direita da tela
		bnez	$t4, clsion_shot_4	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0x0FFFFFFF	# Retira o tiro do indicador de entidades

		li	$t0, 54
		mul	$t0, $t0, 0x00000100	# n pixels até a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t4		# Adiciona a posição horizontal do tiro
		li	$t1, 0x00000000
		jal	enemy_shot_anim		# Apaga o tiro no final da tela

		li	$t4, 0
		
clsion_shot_4:	bne	$t4, 20, end_enemy_shots
		bgt	$s0, 54, end_enemy_shots
		blt	$s0, 44, end_enemy_shots

		li	$v0, 10
		syscall				# Encerra o programa

end_enemy_shots:lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


enemy_shot_anim:subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		sw	$t1, screen_data($t0)	# Desenha o ponto da frente do tiro

		addi	$t0, $t0, 4
		sw	$t1, screen_data($t0)	# Desenha o ponto de trás do tiro. Só faz algo no
						#	primeiro frame, mas n vale à pela verificar

		addi	$t0, $t0, 4
		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Apaga o ponto de trás do frame anterior

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endereço de chamada
		jr	$ra			# Retorna para o endereço de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
