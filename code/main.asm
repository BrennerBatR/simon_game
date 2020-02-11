#include <p16f887.inc>
#define		button		PORTB,RB0
list p=16f887

__CONFIG	_CONFIG1, 0x2ff4
__CONFIG	_CONFIG2, 0x3ffF

	cblock 0x20
		cnt_1
		cnt_2
		led_cnt
		_wreg
		_status
		timer_counter_50ms
		timer_counter_5s
		level	;1: hard , 0: easy
		sequency
		move
	endc
	
	cblock	0x5F
		move_pointer	;ponteiro para memoria de movimentos
	endc
	TMR0_50MS	EQU		.61
	LED_RED		EQU		B'00000001'
	LED_YELLOW	EQU		B'00000010'
	LED_GREEN	EQU		B'00000100'
	LED_BLUE	EQU 	B'00001000'

	org		0x00	; reset vector
	goto 	Start
	
	org		0x04	;interrupt vector
	movwf	_wreg
	swapf	STATUS,W
	movwf	_status
	btfsc	INTCON, T0IF	;TO1F === 1 ?
	goto	Timer0Interrupt ; yes	
	goto	ExitInterrupt	;no
	
Timer0Interrupt
	bcf		INTCON, T0IF
	incf	timer_counter_5s,F
	incf	timer_counter_50ms,F
	movlw	TMR0_50MS
	movwf	TMR0
	goto	ExitInterrupt
	
ExitInterrupt
	swapf	_status,W
	movwf	STATUS
	swapf	_wreg,F
	swapf	_wreg,W
	
	retfie
	
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
	;rlf -> rotaciona os bits para direita
	;lrf -> rotaciona para esquerda
	
	clrf	timer_counter_5s
	clrf	timer_counter_50ms
	bsf		STATUS,RP0  ; seleciona o banco 1 RP0 (pag 31 doc)(ficou 01, pois setou o segundo bit para 1)
	movlw	B'11110000' ; setando RA3-RA0 como saida e RA7-RA4 input (1 input 0 output)
	movwf	TRISA		; pega os bits anteriores e seta as portas como entrada ou saida
	
	bsf		STATUS,RP1	; seleciona o banco 3
	clrf	ANSEL		; configura todas portas e pinos como digital I/0
		clrf	ANSELH		;PORTB	pins as digital	I/O
						
	;----- TMR0 config ------
	;queremos que a fonte seja o clk interno
	;INTCON , TMR0 e OPTION_REG
	;OPTION_REG: T0CS=0 (define clk interno(INTOSC/4),
	;PSA= 0 (prescaler TMRO , se nao usar o prescaler ele demora 256uS , e queremos 0.5 segundos, para dobrar os 256 coloco o prescaler 2, ( ele divide o clk em 2), 
	;PS= 111
	
	bcf		STATUS,RP1		;banco 1
	;mascara para zerar os bits	PS
	movlw	b'00001110'
	iorwf	OPTION_REG, F	;iorwf: porta or para setar bits do PS
	movlw	b'11010111'	
	andwf	OPTION_REG, F   ;clear T0CS , PSA
	
	bcf		STATUS,RP0		; bank 0
	movlw	.61
	movwf	TMR0
	bcf		INTCON, T0IF	;limpando flg de interrupção
	bsf		INTCON, T0IE	;habilita tmrp interrupt
	bsf		INTCON, GIE		;habiilita interrupcoes
	call	RotinaInicializacao

Main:

	btfsc	button		;se o botao de start for pressionado
	goto	Main
	movf	TMR0,W
	movwf	move		;COPY TMR0 para move
	clrf 	sequency
	btfsc	PORTB,RB1	;level do jogo
	goto	LevelEasy
	goto	LevelHard
	
LevelEasy:
	bcf		level,0
	goto 	Main_Loop
	
LevelHard:
	bsf		level,0
	goto 	Main_Loop
	
Main_Loop:
	call	SorteiaNumeros
	goto	Main

SorteiaNumeros:
	movlw	0x03		;00000111
	andwf	move		;clear bits 2-7
	
	movlw	.0
	subwf	move,W
	btfss	STATUS,Z
	retlw	LED_RED		;retorna led vermelho
	
	movlw	.1
	subwf	move,W
	btfss	STATUS,Z
	retlw	LED_YELLOW
	
	movlw	.2
	subwf	move,W
	btfss	STATUS,Z
	retlw	LED_GREEN
	
	movlw	.3
	subwf	move,W
	btfss	STATUS,Z
	retlw	LED_BLUE

RotinaInicializacao: 
	bcf		STATUS,RP1	
	bcf		STATUS,RP0	; os dois comandos acima resetam os bits seletores de banco, ou seja fomos para 00(bank0)
	movlw	0x0F		; seleciona os pinos RA0-RA3 (1111)
	movwf	PORTA		; seta os pinos RA0-RA3 (acende os leds)
	call 	Delay_1s	; call chama uma função com RETORNO
	
	clrf	led_cnt	; led_cnt = 0
	
LedCountLoop:
	;		PORTA	
	;00->	00000001
	;01-> 	00000010
	;10-> 	00000100
	;11-> 	00001000
	clrf	PORTA		; seta 0 para todas saidas (apaga os leds)
	
	movlw	.0			; colocando 0 no work, decimal a gente coloca '.' e o numero	
	subwf	led_cnt, W	; subwf -> substitui w de f onde f é ledcnt e o resultado ficara no mesmo registrador de entrada (led_cnt) e w = 0
	btfsc	STATUS, Z	; se z=0 pula a proxima linha (z é se a subtração deu 0 ou nao)
	bsf		PORTA,RA0	; acendi o led 0
	
	movlw	.1
	subwf	led_cnt, W
	btfsc	STATUS, Z	
	bsf		PORTA,RA1
	
	movlw	.2
	subwf	led_cnt, W
	btfsc	STATUS, Z	
	bsf		PORTA,RA2
	
	movlw	.3
	subwf	led_cnt, W
	btfsc	STATUS, Z	
	bsf		PORTA,RA3
	
	call 	Delay_200ms
	incf	led_cnt, F	; incrementei o led_cnt (F significa q vai salvar no proprio led_cnt)
	
	;verificar se o led_cnt é 4
	movlw	.4
	subwf	led_cnt, W  ; subtrai 4 de led_cnt e salva em w
	btfss	STATUS, Z	;led_cnt == 4 ? z é 1 se a subtração foi zero
	goto	LedCountLoop;se nao for executa aqu
	clrf	PORTA		;se for 4 executa aqui (ja fez toda rotina), apaga todos leds
	return 	
				
Delay_1s:					
	call	Delay_200ms
	call	Delay_200ms
	call	Delay_200ms
	call	Delay_200ms
	call	Delay_200ms
	return
	
Delay_1ms:
	movlw	.248 
	movwf	cnt_1

Delay1:
	nop
	decfsz	cnt_1,	F	;decrementando cnt_1 e F significa q salvou no proprio registrador de entrada (cnt_1)	
	goto	Delay1
	return 
	
Delay_200ms:			;aqui eu chamo o delay de 1ms 200 vezes
	movlw	.200
	movwf	cnt_2

Delay2:
	call	Delay_1ms
	decfsz	cnt_2,F		;se chegar a zero pula a proxima linha
	goto	Delay2
	return
	
Delay_10us:				;aqui gastamos 6 nops, cada um gasta 1us , o retorno 2us e o call do rdelay gastou 2us totalizando 10 us
	nop
	nop
	nop
	nop
	nop
	nop
	return
	
	end	


	
	