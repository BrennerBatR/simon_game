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
	

	bsf		STATUS,RP0  ; seleciona o banco 1 RP0 (pag 31 doc)
	movlw	B'11110000' ; setando RA3-RA0 como saida e RA7-RA4 input (1 input 0 output)
	movwf	TRISA		; pega os bits anteriores e seta as portas como entrada ou saida
	
	bsf		STATUS,RP1	; seleciona o banco 3
	clrf	ANSEL		; configura todas portas e pinos como digital I/0
		
	end
	
	