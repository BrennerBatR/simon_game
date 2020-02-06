#include <p16f887.inc>
list p=16f887

cblock 0x20
led_cnt
endc

	org		0x00		; reset vector
	goto	Start
	
	org		0x04		; interrupt vector 
	restfile
	
Start:
	;-------- I/0 config --------
	;vamos configurar o ra0, ra1 ... para saida digital
	;para mudar de banco uso o registrador status
	;tris -> fala se os pinos sao saidas ou entradas
	;mvlw -> 
	;bsf altera seta o bit do registrador 1
	;bcf reseta o bit do registrador
	;f -> indica um fileeregister (alteram o conteudo de um registrador da memoria ram)
	; 1 entrada analogica e 0 para digital
	;bancos -> 00=banck0  01=banck1 etc
	;PORT: seta o nivel alto ou baixo na porta, 1 alto e 0 baixo
	

	bsf		STATUS,RP0  ; seleciona o banco 1 RP0 (pag 31 doc)(ficou 01, pois setou o segundo bit para 1)
	movlw	B'11110000' ; setando RA3-RA0 como saida e RA7-RA4 input (1 input 0 output)
	movwf	TRISA		; pega os bits anteriores e seta as portas como entrada ou saida
	
	bsf		STATUS,RP1	; seleciona o banco 3
	clrf	ANSEL		; configura todas portas e pinos como digital I/0
	
Main:
	goto 	RotinaInicializacao
	end
	
RotinaInicializacao:
	bcf		STATUS,RP1	
	bcf		STATUS,RP0	; os dois comandos acima resetam os bits seletores de banco, ou seja fomos para 00(bank0)
	movlw	0x0F		; seleciona os pinos RA0-RA3 (1111)
	movwf	PORTA		; seta os pinos RA0-RA3 (acende os leds)
	call 	Delay_1s	; call chama uma função com RETORNO
	clrf	PORTA		; seta 0 para todas saidas (apaga os leds)
	
						
	


	
	