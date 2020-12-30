# Trabalho 2 - Jogo de naves
# Aleixo Damas Neto
# NUSP: 10310975


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Pre-set
# "Bitmap Display" limpo e conectado ao Mars:
#	Cada pixel com 4 unidades de altura e largura;
#	Tela com 64 pixels de altura e largura (ou 256x256 na janela da ferramenta);
#	Memoria dos dados da tela � a est�tica (a partir do 0x10010000 at� 0x10011000);
# "Keybord and Display MMIO" limpo e conectado ao Mars (apenas keyboard usada).

		.data
screen_data:	.space	0x00001000		# Reserva o espa�o de memoria para o bitmap


		.text
		.globl 	main


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


main:		li	$s0, 25			# Nave inicia no meio da tela
		li	$s1, 0x0000FFFF		# Redesenha uma posi��o a cima
		jal	ally_ship		# Desenha a nave inicialmente

		li	$s4, 0x00000000		# Inicia sem naves nem tiros inimigos
		li	$s6, 0			# Contador de loop de atualiza��o de tela para
						#	temporiza��o de anima��o dos tiros inimigos
		li	$s7, 0			# Contador de loop de atualiza��o de tela para
						#	temporiza��o de anima��o do tiro aliado

		li	$t7, 0			# Pr�-seta a posi��o horizontal do tiro 1
		li	$t6, 0			# Pr�-seta a posi��o horizontal do tiro 2
		li	$t5, 0			# Pr�-seta a posi��o horizontal do tiro 3
		li	$t4, 0			# Pr�-seta a posi��o horizontal do tiro 4

main_loop:	li	$s2, 0			# Reseta registrador de input do MMIO
		jal	MMIO_read		# Verifica input pelo terminal MMIO

		jal	ally_ctrl		# Move a nave aliada se o comando foi para ela
		
		jal	ally_shot		# Inicia e executa a anima��o do tiro

		jal	enemy_entities

		bne	$s2, 'q', main_loop	# Verifica se foi inserido comando de quit

		li	$v0, 10
		syscall				# Encerra o programa


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que le o terminal MMIO se algo foi inserido (Se nada foi inserido, simplesmente nada 
# acontece).
#	s2 - Comando dado pelo teclado;
#	Usa reg tempor�rio t0.

MMIO_read:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha o endere�o de chamada

		lw	$t0, 0xFFFF0000		# Leio o sinal de entrada de dados pelo teclado
		andi	$t0, $t0, 0x00000001	# Apenas o ultimo bit � importante
		beqz	$t0, end_MMIO_read	# Se zero, n�o ouve atividade no teclado, s2 n�o �
						#	atualizado, subrotina � encerrada
		
		lw	$s2, 0xFFFF0004		# CC, s2 � atualizado

end_MMIO_read:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que verifica se a entrada do loop foi compat�vel com os comandos de subida e de descida
# da nave.
#	s2 - Comando dado pelo teclado.

ally_ctrl:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

go_up_ally:	bne	$s2, 'w', go_down_ally	# Verifica se o comando inserido foi 'w'
		li	$s2, 0x00000000		# Limpra s2 para n�o entrar na verifica��o no
						#	proximo loop
		beq	$s0, 1, go_down_ally	# Verifica se a nave j� n�o est� na linha mais alta
		li	$s1, 0x00000000
		jal	ally_ship		# Apaga
		sub	$s0, $s0, 1		# Decrementa posi��o
		li	$s1, 0x0000FFFF
		jal	ally_ship		# Redesenha

go_down_ally:	bne	$s2, 's', end_ally_ctrl	# Verifica se o comando inserido foi 's'
		li	$s2, 0x00000000		# Limpra s2 para n�o entrar na verifica��o no
						#	proximo loop
		beq	$s0, 52, end_ally_ctrl	# Verifica se a nave j� n�o est� na linha mais baixa
		li	$s1, 0x00000000
		jal	ally_ship		# Apaga
		add	$s0, $s0, 1
		li	$s1, 0x0000FFFF
		jal	ally_ship		# Redesenha

end_ally_ctrl:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que atualiza o desenho da nave aliada na tela dada duas posi��es verticais da asa de cima.
#	s0 - Posi��o da nave;
#	s1 - Cor do pixel (controla se "apaga" ou "acende" o pixel);
#	Usa reg tempor�rio t0.

ally_ship:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		mul	$t0, $s0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
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
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que verifica se o comando para tipo foi inserido, e caso ja haja um tiro na tela, ela
# executa uma etapa da anima��o do tiro.
#	s0 - Posi��o da nave;
#	s2 - Comando dado pelo teclado;
#	s7 - Contador para defini��o de frequ�ncia de "frame" da anima��o de tiro;
#	t8 - Posi��o vertical do tiro (baseado em onde a nave alida estava quando atirou);
#	t9 - Posi��o horizontal do tiro (incrementada ao longo da anima��o):
#		Se t9 = 0, n�o h� tiro, um novo pode ser executado.

ally_shot:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		beqz	$t9, new_ally_shot	# Se n�o existe tiro na tela, segue para
						# 	verifica��o de novo tiro.
						# CC, segue para a execu��o da anima��o de tiro.

		addu	$s7, $s7, 1		# Contagem de "frames" para o proximo quadro da 
						#	anima��o.

		bne	$s7, 0x00000100, end_ally_shot
						# Ajuste de frequencia de anima��o.
						#	Anima��o � executada a cada 100 "frames"
		jal	ally_shot_anim		

		bne	$t9, 252, end_ally_shot	# Verifica se o tiro chegou ao final da tela.
		jal	ally_shot_del		# Apaga o tiro e reseta os registradores


new_ally_shot:	bne	$s2, ' ', end_ally_shot	# Se houve comando de tiro, executa defini��o de
						# vari�veis.
						# CC, encerra subrotina
		li	$s2, 0x00000000		# Limpra s2 para n�o entrar na verifica��o no
						#	proximo loop

		li	$s7, 0			# Reseta o contador para a anima��o

		move	$t8, $s0
		addi	$t8, $t8, 5		# Linha de pixels que passa pelo centro na nave
		li	$t9, 40

end_ally_shot:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o de anima��o do tiro aliado.
#	s7 - Contador para defini��o de frequ�ncia de "frame" da anima��o de tiro;
#	t8 - Posi��o vertical do tiro (baseado em onde a nave alida estava quando atirou);
#	t9 - Posi��o horizontal do tiro (incrementada ao longo da anima��o):
#	Usa regs tempor�rios t0 e t1.

ally_shot_anim:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		li	$s7, 0

		mul	$t0, $t8, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t9		# Adiciona a posi��o horizontal do tiro

		li	$t1, 0x0000FF00
		sw	$t1, screen_data($t0)	# Desenha o ponto da frente do tiro

		subi	$t0, $t0, 4

		li	$t1, 0x0000FF00
		sw	$t1, screen_data($t0)	# Desenha o ponto de tr�s do tiro. S� faz algo no
						#	primeiro frame, mas n vale � pela verificar

		subi	$t0, $t0, 4

		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Apaga o ponto de tr�s do frame anterior

		addi	$t9, $t9, 4		# Incrementa para a pr�xima posi��o do tiro

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que encerra o tiro aliado quando ele chega ao fim da tela ou atinge uma nave inimiga.
#	t8 - Posi��o vertical do tiro (baseado em onde a nave alida estava quando atirou);
#	t9 - Posi��o horizontal do tiro (incrementada ao longo da anima��o):
#	Usa regs tempor�rios t0 e t1.

ally_shot_del:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		mul	$t0, $t8, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t9		# Adiciona a posi��o horizontal do tiro
		subi	$t0, $t0, 4

		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Desenha o ponto da frente do tiro

		subi	$t0, $t0, 4

		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Desenha o ponto de tr�s do tiro. S� faz algo no
						#	primeiro frame, mas n vale � pela verificar
		li	$t9, 0			# Reseta t9 pra novo tiro

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que gerencia as naves e tiros inimigos
#	s3 - Posi��o vertical da nave inimiga a ser desenhada na tela;
#	s4 - Registrador de 8 nibbles (4 tiros e 4 naves - F se a entidade existe, 0 se n�o existe).

enemy_entities:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		bnez	$s4, enemy_verif	# Se n�o h� naves nem tiros na tela, as 4 naves s�o
						#	desenhadas.
						# CC, sege para as verifica��es de naves e tiros
						#	inimigos.
		li	$s4, 0x0000FFFF		# "Anotas" as 4 naves como desenhadas

		li	$s3, 6			# Posi��o vertical da 1a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
		addi	$s3, $s3, 15		# Posi��o vertical da 2a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
		addi	$s3, $s3, 15		# Posi��o vertical da 3a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
		addi	$s3, $s3, 15		# Posi��o vertical da 4a nave
		li	$s1, 0x00FFFF00
		jal	enemy_ship		# Desenha nave
		
enemy_verif:	jal	enemy_cllsion		# Verifica colis�o do tiro aliado com as naves
						#	inimigas
		jal	enemy_shots		# Verifica o lan�amento de um tiro inimigo em 
						#	dire��o � nave aliada

end_enemy_entts:lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que, dada uma posi��o vertical, desenha ou apaga uma nave inimiga no bitmap display.
#	s1 - Cor do pixel (controla se "apaga" ou "acende" o pixel);
#	s3 - Posi��o nave verticalmente;
#	Usa reg tempor�rio t0.

enemy_ship:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		mul	$t0, $s3, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
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
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que verifica se algum tiro aliado atingiu uma nave inimiga, contabiliza a coliz�o no
# registrador s4 e apaga da tela tanto tiro como nave.
#	s1 - Cor do pixel (controla se "apaga" ou "acende" o pixel);
#	s3 - Posi��o nave verticalmente;
#	s4 - Registrador de 8 nibbles (4 tiros e 4 naves - F se a entidade existe, 0 se n�o existe);
#	t8 - Posi��o vertical do tiro;
#	t9 - Posi��o horizontal do tiro;
#	Usa reg tempor�rio t0.

enemy_cllsion:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		bne	$t9, 220, end_enemy_cll	# Verifica se o tiro atingiu o n�vel horizontal das
						#	naves inimigas

enemy_cll_1:	andi	$t0, $s4, 0x0000000F	# Filtra o indicador da primeira nave
		bne	$t0, 0x0000000F, enemy_cll_2
						# Se a nave existe, � verificada se teve colis�o
		blt	$t8, 6, enemy_cll_2	# Verifica se o tiro acertaria a nave
		bgt	$t8, 12, enemy_cll_2	# Verifica se o tiro acertaria a nave
		li	$s3, 6			# Posi��o vertical da 1a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFFFFF0	# Apaga a nave no indicador de entidade

enemy_cll_2:	andi	$t0, $s4, 0x000000F0	# Filtra o indicador da primeira nave
		bne	$t0, 0x000000F0, enemy_cll_3
						# Se a nave existe, � verificada se teve colis�o
		blt	$t8, 21, enemy_cll_3	# Verifica se o tiro acertaria a nave
		bgt	$t8, 27, enemy_cll_3	# Verifica se o tiro acertaria a nave
		li	$s3, 21			# Posi��o vertical da 2a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFFFF0F	# Apaga a nave no indicador de entidade

enemy_cll_3:	andi	$t0, $s4, 0x00000F00	# Filtra o indicador da primeira nave
		bne	$t0, 0x00000F00, enemy_cll_4
						# Se a nave existe, � verificada se teve colis�o
		blt	$t8, 36, enemy_cll_4	# Verifica se o tiro acertaria a nave
		bgt	$t8, 42, enemy_cll_4	# Verifica se o tiro acertaria a nave
		li	$s3, 36			# Posi��o vertical da 3a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFFF0FF	# Apaga a nave no indicador de entidade

enemy_cll_4:	andi	$t0, $s4, 0x0000F000	# Filtra o indicador da primeira nave
		bne	$t0, 0x0000F000, end_enemy_cll
						# Se a nave existe, � verificada se teve colis�o
		blt	$t8, 51, end_enemy_cll	# Verifica se o tiro acertaria a nave
		bgt	$t8, 57, end_enemy_cll	# Verifica se o tiro acertaria a nave
		li	$s3, 51			# Posi��o vertical da 4a nave
		li	$s1, 0x00000000
		jal	enemy_ship		# Apaga nave
		jal	ally_shot_del		# Apaga tiro
		andi	$s4, $s4, 0xFFFF0FFF	# Apaga a nave no indicador de entidade

end_enemy_cll:	lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# Fun��o que observa as naves inimigas existentes e a posi��o da nave inimiga para determinar um
# um ataque inimigo.
#	t7 - Posi��o horizontal do tiro 1
#	t6 - Posi��o horizontal do tiro 2
#	t5 - Posi��o horizontal do tiro 3
#	t4 - Posi��o horizontal do tiro 4

enemy_shots:	subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		addu	$s6, $s6, 1		# Contagem de "frames" para o proximo quadro da 
						#	anima��o.

		bne	$s6, 0x00000300, end_ally_shot
						# Ajuste de frequencia de anima��o.
						#	Anima��o � executada a cada 150 "frames"
		li	$s6, 0x00000000

enemy_shot_1:	andi	$t0, $s4, 0x000F000F	# Filtra a existencia da primera nave e primeiro 
						#	tiro
		bne	$t0, 0x0000000F, enemy_anim_1
						# Se n�o existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verifica��o

		bgt	$s0, 7, enemy_anim_1

		# Inicia tiro 1
		ori	$s4, $s4, 0x000F0000	# Adiciona o tiro no indicador de entidades
		li	$t7, 208		# Seta n�vel horizontal to tiro

enemy_anim_1:	andi	$t0, $s4, 0x000F0000	# Filtra a existencia do primero tiro
		bne	$t0, 0x000F0000, enemy_shot_2
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da anima��o.
						# CC, continua a verifica��o

		# Roda a anima�ao
		li	$t0, 9
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t7		# Adiciona a posi��o horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de anima��o do tiro
		subi	$t7, $t7, 4

		# Verifica se chegou � extremidade direita da tela
		bnez	$t7, clsion_shot_1	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0xFFF0FFFF	# Retira o tiro do indicador de entidades

		li	$t0, 9
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t7		# Adiciona a posi��o horizontal do tiro
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
						# Se n�o existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verifica��o

		bgt	$s0, 22, enemy_anim_2
		blt	$s0, 15, enemy_anim_2

		ori	$s4, $s4, 0x00F00000	# Adiciona o tiro no indicador de entidades

		# Inicia tiro 2
		ori	$s4, $s4, 0x00F00000	# Adiciona o tiro no indicador de entidades
		li	$t6, 208		# Seta n�vel horizontal to tiro

enemy_anim_2:	andi	$t0, $s4, 0x00F00000	# Filtra a existencia do primero tiro
		bne	$t0, 0x00F00000, enemy_shot_3
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da anima��o.
						# CC, continua a verifica��o

		# Roda a anima�ao
		li	$t0, 24
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t6		# Adiciona a posi��o horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de anima��o do tiro
		subi	$t6, $t6, 4

		# Verifica se chegou � extremidade direita da tela
		bnez	$t6, clsion_shot_2	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0xFF0FFFFF	# Retira o tiro do indicador de entidades

		li	$t0, 24
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t6		# Adiciona a posi��o horizontal do tiro
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
						# Se n�o existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verifica��o

		bgt	$s0, 37, enemy_anim_3
		blt	$s0, 30, enemy_anim_3

		ori	$s4, $s4, 0x0F000000	# Adiciona o tiro no indicador de entidades

		# Inicia tiro 3
		ori	$s4, $s4, 0x0F000000	# Adiciona o tiro no indicador de entidades
		li	$t5, 208		# Seta n�vel horizontal to tiro

enemy_anim_3:	andi	$t0, $s4, 0x0F000000	# Filtra a existencia do primero tiro
		bne	$t0, 0x0F000000, enemy_shot_4
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da anima��o.
						# CC, continua a verifica��o

		# Roda a anima�ao
		li	$t0, 39
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t5		# Adiciona a posi��o horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de anima��o do tiro
		subi	$t5, $t5, 4

		# Verifica se chegou � extremidade direita da tela
		bnez	$t5, clsion_shot_3	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0xF0FFFFFF	# Retira o tiro do indicador de entidades

		li	$t0, 39
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t5		# Adiciona a posi��o horizontal do tiro
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
						# Se n�o existir o tiro, mas a nave existir, 
						#	tiro deve ser criado
						# CC, continua a verifica��o

		blt	$s0, 45, enemy_anim_4

		ori	$s4, $s4, 0xF0000000	# Adiciona o tiro no indicador de entidades

		# Inicia tiro 4
		ori	$s4, $s4, 0xF0000000	# Adiciona o tiro no indicador de entidades
		li	$t4, 208		# Seta n�vel horizontal to tiro

enemy_anim_4:	andi	$t0, $s4, 0xF0000000	# Filtra a existencia do primero tiro
		bne	$t0, 0xF0000000, end_enemy_shots
						# Se existir o tiro e a nave, deve-se rodar uma
						#	etapa da anima��o.
						# CC, continua a verifica��o

		# Roda a anima�ao
		li	$t0, 54
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t4		# Adiciona a posi��o horizontal do tiro
		li	$t1, 0x00FF0000
		jal	enemy_shot_anim		# Executa um 'frame' de anima��o do tiro
		subi	$t4, $t4, 4

		# Verifica se chegou � extremidade direita da tela
		bnez	$t4, clsion_shot_4	# Se o tiro estiver no final da tela, ele deve
						#	ser apagado

		andi	$s4, $s4, 0x0FFFFFFF	# Retira o tiro do indicador de entidades

		li	$t0, 54
		mul	$t0, $t0, 0x00000100	# n pixels at� a linha = n linhas * 64 pixels por
						#	por linha * 4 bytes por pixel
		add	$t0, $t0, $t4		# Adiciona a posi��o horizontal do tiro
		li	$t1, 0x00000000
		jal	enemy_shot_anim		# Apaga o tiro no final da tela

		li	$t4, 0
		
clsion_shot_4:	bne	$t4, 20, end_enemy_shots
		bgt	$s0, 54, end_enemy_shots
		blt	$s0, 44, end_enemy_shots

		li	$v0, 10
		syscall				# Encerra o programa

end_enemy_shots:lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


enemy_shot_anim:subi	$sp, $sp, 4
		sw	$ra, ($sp)		# Salva na pilha de chamada

		sw	$t1, screen_data($t0)	# Desenha o ponto da frente do tiro

		addi	$t0, $t0, 4
		sw	$t1, screen_data($t0)	# Desenha o ponto de tr�s do tiro. S� faz algo no
						#	primeiro frame, mas n vale � pela verificar

		addi	$t0, $t0, 4
		li	$t1, 0x00000000
		sw	$t1, screen_data($t0)	# Apaga o ponto de tr�s do frame anterior

		lw	$ra, ($sp)
		addi	$sp, $sp, 4		# Recupera da pilha o endere�o de chamada
		jr	$ra			# Retorna para o endere�o de chamada


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
