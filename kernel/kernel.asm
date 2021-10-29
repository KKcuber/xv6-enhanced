
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	aa013103          	ld	sp,-1376(sp) # 80008aa0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c2c78793          	addi	a5,a5,-980 # 80005c90 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	342080e7          	jalr	834(ra) # 8000246e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ea0080e7          	jalr	-352(ra) # 80002074 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	208080e7          	jalr	520(ra) # 80002418 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	1d2080e7          	jalr	466(ra) # 800024c4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dba080e7          	jalr	-582(ra) # 80002200 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1712+0x160>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	960080e7          	jalr	-1696(ra) # 80002200 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	748080e7          	jalr	1864(ra) # 80002074 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	752080e7          	jalr	1874(ra) # 80002626 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	df4080e7          	jalr	-524(ra) # 80005cd0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fde080e7          	jalr	-34(ra) # 80001ec2 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1712+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1712+0x160>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	6b2080e7          	jalr	1714(ra) # 800025fe <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	6d2080e7          	jalr	1746(ra) # 80002626 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d5e080e7          	jalr	-674(ra) # 80005cba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d6c080e7          	jalr	-660(ra) # 80005cd0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f4c080e7          	jalr	-180(ra) # 80002eb8 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	5dc080e7          	jalr	1500(ra) # 80003550 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	586080e7          	jalr	1414(ra) # 80004502 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e6e080e7          	jalr	-402(ra) # 80005df2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	a62a0a13          	addi	s4,s4,-1438 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17048493          	addi	s1,s1,368
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	99698993          	addi	s3,s3,-1642 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17048493          	addi	s1,s1,368
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ef07a783          	lw	a5,-272(a5) # 800088f0 <first.1675>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	c34080e7          	jalr	-972(ra) # 8000263e <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ec07ab23          	sw	zero,-298(a5) # 800088f0 <first.1675>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	aac080e7          	jalr	-1364(ra) # 800034d0 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	ea878793          	addi	a5,a5,-344 # 800088f4 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	70290913          	addi	s2,s2,1794 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	17048493          	addi	s1,s1,368
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	c5858593          	addi	a1,a1,-936 # 80008900 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	218080e7          	jalr	536(ra) # 80003efe <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050f63          	beqz	a0,80001ebe <fork+0x140>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054a63          	bltz	a0,80001e0c <fork+0x8e>
  np->trace_mask = p->trace_mask;
    80001dbc:	16892783          	lw	a5,360(s2)
    80001dc0:	16f9a423          	sw	a5,360(s3)
  np->sz = p->sz;
    80001dc4:	04893783          	ld	a5,72(s2)
    80001dc8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dcc:	05893683          	ld	a3,88(s2)
    80001dd0:	87b6                	mv	a5,a3
    80001dd2:	0589b703          	ld	a4,88(s3)
    80001dd6:	12068693          	addi	a3,a3,288
    80001dda:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dde:	6788                	ld	a0,8(a5)
    80001de0:	6b8c                	ld	a1,16(a5)
    80001de2:	6f90                	ld	a2,24(a5)
    80001de4:	01073023          	sd	a6,0(a4)
    80001de8:	e708                	sd	a0,8(a4)
    80001dea:	eb0c                	sd	a1,16(a4)
    80001dec:	ef10                	sd	a2,24(a4)
    80001dee:	02078793          	addi	a5,a5,32
    80001df2:	02070713          	addi	a4,a4,32
    80001df6:	fed792e3          	bne	a5,a3,80001dda <fork+0x5c>
  np->trapframe->a0 = 0;
    80001dfa:	0589b783          	ld	a5,88(s3)
    80001dfe:	0607b823          	sd	zero,112(a5)
    80001e02:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e06:	15000a13          	li	s4,336
    80001e0a:	a03d                	j	80001e38 <fork+0xba>
    freeproc(np);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	d54080e7          	jalr	-684(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e16:	854e                	mv	a0,s3
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
    return -1;
    80001e20:	5a7d                	li	s4,-1
    80001e22:	a069                	j	80001eac <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	770080e7          	jalr	1904(ra) # 80004594 <filedup>
    80001e2c:	009987b3          	add	a5,s3,s1
    80001e30:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e32:	04a1                	addi	s1,s1,8
    80001e34:	01448763          	beq	s1,s4,80001e42 <fork+0xc4>
    if(p->ofile[i])
    80001e38:	009907b3          	add	a5,s2,s1
    80001e3c:	6388                	ld	a0,0(a5)
    80001e3e:	f17d                	bnez	a0,80001e24 <fork+0xa6>
    80001e40:	bfcd                	j	80001e32 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e42:	15093503          	ld	a0,336(s2)
    80001e46:	00002097          	auipc	ra,0x2
    80001e4a:	8c4080e7          	jalr	-1852(ra) # 8000370a <idup>
    80001e4e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e52:	4641                	li	a2,16
    80001e54:	15890593          	addi	a1,s2,344
    80001e58:	15898513          	addi	a0,s3,344
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	fd6080e7          	jalr	-42(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e64:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e68:	854e                	mv	a0,s3
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e72:	0000f497          	auipc	s1,0xf
    80001e76:	44648493          	addi	s1,s1,1094 # 800112b8 <wait_lock>
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	d68080e7          	jalr	-664(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e84:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e92:	854e                	mv	a0,s3
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	d50080e7          	jalr	-688(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e9c:	478d                	li	a5,3
    80001e9e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	df4080e7          	jalr	-524(ra) # 80000c98 <release>
}
    80001eac:	8552                	mv	a0,s4
    80001eae:	70a2                	ld	ra,40(sp)
    80001eb0:	7402                	ld	s0,32(sp)
    80001eb2:	64e2                	ld	s1,24(sp)
    80001eb4:	6942                	ld	s2,16(sp)
    80001eb6:	69a2                	ld	s3,8(sp)
    80001eb8:	6a02                	ld	s4,0(sp)
    80001eba:	6145                	addi	sp,sp,48
    80001ebc:	8082                	ret
    return -1;
    80001ebe:	5a7d                	li	s4,-1
    80001ec0:	b7f5                	j	80001eac <fork+0x12e>

0000000080001ec2 <scheduler>:
{
    80001ec2:	7139                	addi	sp,sp,-64
    80001ec4:	fc06                	sd	ra,56(sp)
    80001ec6:	f822                	sd	s0,48(sp)
    80001ec8:	f426                	sd	s1,40(sp)
    80001eca:	f04a                	sd	s2,32(sp)
    80001ecc:	ec4e                	sd	s3,24(sp)
    80001ece:	e852                	sd	s4,16(sp)
    80001ed0:	e456                	sd	s5,8(sp)
    80001ed2:	e05a                	sd	s6,0(sp)
    80001ed4:	0080                	addi	s0,sp,64
    80001ed6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eda:	00779a93          	slli	s5,a5,0x7
    80001ede:	0000f717          	auipc	a4,0xf
    80001ee2:	3c270713          	addi	a4,a4,962 # 800112a0 <pid_lock>
    80001ee6:	9756                	add	a4,a4,s5
    80001ee8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eec:	0000f717          	auipc	a4,0xf
    80001ef0:	3ec70713          	addi	a4,a4,1004 # 800112d8 <cpus+0x8>
    80001ef4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef8:	4b11                	li	s6,4
        c->proc = p;
    80001efa:	079e                	slli	a5,a5,0x7
    80001efc:	0000fa17          	auipc	s4,0xf
    80001f00:	3a4a0a13          	addi	s4,s4,932 # 800112a0 <pid_lock>
    80001f04:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f06:	00015917          	auipc	s2,0x15
    80001f0a:	3ca90913          	addi	s2,s2,970 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f12:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f16:	10079073          	csrw	sstatus,a5
    80001f1a:	0000f497          	auipc	s1,0xf
    80001f1e:	7b648493          	addi	s1,s1,1974 # 800116d0 <proc>
    80001f22:	a03d                	j	80001f50 <scheduler+0x8e>
        p->state = RUNNING;
    80001f24:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f28:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2c:	06048593          	addi	a1,s1,96
    80001f30:	8556                	mv	a0,s5
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	662080e7          	jalr	1634(ra) # 80002594 <swtch>
        c->proc = 0;
    80001f3a:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	17048493          	addi	s1,s1,368
    80001f4c:	fd2481e3          	beq	s1,s2,80001f0e <scheduler+0x4c>
      acquire(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f5a:	4c9c                	lw	a5,24(s1)
    80001f5c:	ff3791e3          	bne	a5,s3,80001f3e <scheduler+0x7c>
    80001f60:	b7d1                	j	80001f24 <scheduler+0x62>

0000000080001f62 <sched>:
{
    80001f62:	7179                	addi	sp,sp,-48
    80001f64:	f406                	sd	ra,40(sp)
    80001f66:	f022                	sd	s0,32(sp)
    80001f68:	ec26                	sd	s1,24(sp)
    80001f6a:	e84a                	sd	s2,16(sp)
    80001f6c:	e44e                	sd	s3,8(sp)
    80001f6e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	a40080e7          	jalr	-1472(ra) # 800019b0 <myproc>
    80001f78:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	bf0080e7          	jalr	-1040(ra) # 80000b6a <holding>
    80001f82:	c93d                	beqz	a0,80001ff8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f84:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f86:	2781                	sext.w	a5,a5
    80001f88:	079e                	slli	a5,a5,0x7
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	31670713          	addi	a4,a4,790 # 800112a0 <pid_lock>
    80001f92:	97ba                	add	a5,a5,a4
    80001f94:	0a87a703          	lw	a4,168(a5)
    80001f98:	4785                	li	a5,1
    80001f9a:	06f71763          	bne	a4,a5,80002008 <sched+0xa6>
  if(p->state == RUNNING)
    80001f9e:	4c98                	lw	a4,24(s1)
    80001fa0:	4791                	li	a5,4
    80001fa2:	06f70b63          	beq	a4,a5,80002018 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001faa:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fac:	efb5                	bnez	a5,80002028 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fae:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb0:	0000f917          	auipc	s2,0xf
    80001fb4:	2f090913          	addi	s2,s2,752 # 800112a0 <pid_lock>
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	97ca                	add	a5,a5,s2
    80001fbe:	0ac7a983          	lw	s3,172(a5)
    80001fc2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc4:	2781                	sext.w	a5,a5
    80001fc6:	079e                	slli	a5,a5,0x7
    80001fc8:	0000f597          	auipc	a1,0xf
    80001fcc:	31058593          	addi	a1,a1,784 # 800112d8 <cpus+0x8>
    80001fd0:	95be                	add	a1,a1,a5
    80001fd2:	06048513          	addi	a0,s1,96
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	5be080e7          	jalr	1470(ra) # 80002594 <swtch>
    80001fde:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe0:	2781                	sext.w	a5,a5
    80001fe2:	079e                	slli	a5,a5,0x7
    80001fe4:	97ca                	add	a5,a5,s2
    80001fe6:	0b37a623          	sw	s3,172(a5)
}
    80001fea:	70a2                	ld	ra,40(sp)
    80001fec:	7402                	ld	s0,32(sp)
    80001fee:	64e2                	ld	s1,24(sp)
    80001ff0:	6942                	ld	s2,16(sp)
    80001ff2:	69a2                	ld	s3,8(sp)
    80001ff4:	6145                	addi	sp,sp,48
    80001ff6:	8082                	ret
    panic("sched p->lock");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	22050513          	addi	a0,a0,544 # 80008218 <digits+0x1d8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("sched locks");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	22050513          	addi	a0,a0,544 # 80008228 <digits+0x1e8>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>
    panic("sched running");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	22050513          	addi	a0,a0,544 # 80008238 <digits+0x1f8>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	22050513          	addi	a0,a0,544 # 80008248 <digits+0x208>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>

0000000080002038 <yield>:
{
    80002038:	1101                	addi	sp,sp,-32
    8000203a:	ec06                	sd	ra,24(sp)
    8000203c:	e822                	sd	s0,16(sp)
    8000203e:	e426                	sd	s1,8(sp)
    80002040:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	96e080e7          	jalr	-1682(ra) # 800019b0 <myproc>
    8000204a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b98080e7          	jalr	-1128(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002054:	478d                	li	a5,3
    80002056:	cc9c                	sw	a5,24(s1)
  sched();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	f0a080e7          	jalr	-246(ra) # 80001f62 <sched>
  release(&p->lock);
    80002060:	8526                	mv	a0,s1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c36080e7          	jalr	-970(ra) # 80000c98 <release>
}
    8000206a:	60e2                	ld	ra,24(sp)
    8000206c:	6442                	ld	s0,16(sp)
    8000206e:	64a2                	ld	s1,8(sp)
    80002070:	6105                	addi	sp,sp,32
    80002072:	8082                	ret

0000000080002074 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002074:	7179                	addi	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	1800                	addi	s0,sp,48
    80002082:	89aa                	mv	s3,a0
    80002084:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	92a080e7          	jalr	-1750(ra) # 800019b0 <myproc>
    8000208e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	b54080e7          	jalr	-1196(ra) # 80000be4 <acquire>
  release(lk);
    80002098:	854a                	mv	a0,s2
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020a2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a6:	4789                	li	a5,2
    800020a8:	cc9c                	sw	a5,24(s1)

  sched();
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	eb8080e7          	jalr	-328(ra) # 80001f62 <sched>

  // Tidy up.
  p->chan = 0;
    800020b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	be0080e7          	jalr	-1056(ra) # 80000c98 <release>
  acquire(lk);
    800020c0:	854a                	mv	a0,s2
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	b22080e7          	jalr	-1246(ra) # 80000be4 <acquire>
}
    800020ca:	70a2                	ld	ra,40(sp)
    800020cc:	7402                	ld	s0,32(sp)
    800020ce:	64e2                	ld	s1,24(sp)
    800020d0:	6942                	ld	s2,16(sp)
    800020d2:	69a2                	ld	s3,8(sp)
    800020d4:	6145                	addi	sp,sp,48
    800020d6:	8082                	ret

00000000800020d8 <wait>:
{
    800020d8:	715d                	addi	sp,sp,-80
    800020da:	e486                	sd	ra,72(sp)
    800020dc:	e0a2                	sd	s0,64(sp)
    800020de:	fc26                	sd	s1,56(sp)
    800020e0:	f84a                	sd	s2,48(sp)
    800020e2:	f44e                	sd	s3,40(sp)
    800020e4:	f052                	sd	s4,32(sp)
    800020e6:	ec56                	sd	s5,24(sp)
    800020e8:	e85a                	sd	s6,16(sp)
    800020ea:	e45e                	sd	s7,8(sp)
    800020ec:	e062                	sd	s8,0(sp)
    800020ee:	0880                	addi	s0,sp,80
    800020f0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	8be080e7          	jalr	-1858(ra) # 800019b0 <myproc>
    800020fa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020fc:	0000f517          	auipc	a0,0xf
    80002100:	1bc50513          	addi	a0,a0,444 # 800112b8 <wait_lock>
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	ae0080e7          	jalr	-1312(ra) # 80000be4 <acquire>
    havekids = 0;
    8000210c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000210e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002110:	00015997          	auipc	s3,0x15
    80002114:	1c098993          	addi	s3,s3,448 # 800172d0 <tickslock>
        havekids = 1;
    80002118:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000211a:	0000fc17          	auipc	s8,0xf
    8000211e:	19ec0c13          	addi	s8,s8,414 # 800112b8 <wait_lock>
    havekids = 0;
    80002122:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002124:	0000f497          	auipc	s1,0xf
    80002128:	5ac48493          	addi	s1,s1,1452 # 800116d0 <proc>
    8000212c:	a0bd                	j	8000219a <wait+0xc2>
          pid = np->pid;
    8000212e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002132:	000b0e63          	beqz	s6,8000214e <wait+0x76>
    80002136:	4691                	li	a3,4
    80002138:	02c48613          	addi	a2,s1,44
    8000213c:	85da                	mv	a1,s6
    8000213e:	05093503          	ld	a0,80(s2)
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	530080e7          	jalr	1328(ra) # 80001672 <copyout>
    8000214a:	02054563          	bltz	a0,80002174 <wait+0x9c>
          freeproc(np);
    8000214e:	8526                	mv	a0,s1
    80002150:	00000097          	auipc	ra,0x0
    80002154:	a12080e7          	jalr	-1518(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b3e080e7          	jalr	-1218(ra) # 80000c98 <release>
          release(&wait_lock);
    80002162:	0000f517          	auipc	a0,0xf
    80002166:	15650513          	addi	a0,a0,342 # 800112b8 <wait_lock>
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b2e080e7          	jalr	-1234(ra) # 80000c98 <release>
          return pid;
    80002172:	a09d                	j	800021d8 <wait+0x100>
            release(&np->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>
            release(&wait_lock);
    8000217e:	0000f517          	auipc	a0,0xf
    80002182:	13a50513          	addi	a0,a0,314 # 800112b8 <wait_lock>
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
            return -1;
    8000218e:	59fd                	li	s3,-1
    80002190:	a0a1                	j	800021d8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002192:	17048493          	addi	s1,s1,368
    80002196:	03348463          	beq	s1,s3,800021be <wait+0xe6>
      if(np->parent == p){
    8000219a:	7c9c                	ld	a5,56(s1)
    8000219c:	ff279be3          	bne	a5,s2,80002192 <wait+0xba>
        acquire(&np->lock);
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	a42080e7          	jalr	-1470(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021aa:	4c9c                	lw	a5,24(s1)
    800021ac:	f94781e3          	beq	a5,s4,8000212e <wait+0x56>
        release(&np->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
        havekids = 1;
    800021ba:	8756                	mv	a4,s5
    800021bc:	bfd9                	j	80002192 <wait+0xba>
    if(!havekids || p->killed){
    800021be:	c701                	beqz	a4,800021c6 <wait+0xee>
    800021c0:	02892783          	lw	a5,40(s2)
    800021c4:	c79d                	beqz	a5,800021f2 <wait+0x11a>
      release(&wait_lock);
    800021c6:	0000f517          	auipc	a0,0xf
    800021ca:	0f250513          	addi	a0,a0,242 # 800112b8 <wait_lock>
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	aca080e7          	jalr	-1334(ra) # 80000c98 <release>
      return -1;
    800021d6:	59fd                	li	s3,-1
}
    800021d8:	854e                	mv	a0,s3
    800021da:	60a6                	ld	ra,72(sp)
    800021dc:	6406                	ld	s0,64(sp)
    800021de:	74e2                	ld	s1,56(sp)
    800021e0:	7942                	ld	s2,48(sp)
    800021e2:	79a2                	ld	s3,40(sp)
    800021e4:	7a02                	ld	s4,32(sp)
    800021e6:	6ae2                	ld	s5,24(sp)
    800021e8:	6b42                	ld	s6,16(sp)
    800021ea:	6ba2                	ld	s7,8(sp)
    800021ec:	6c02                	ld	s8,0(sp)
    800021ee:	6161                	addi	sp,sp,80
    800021f0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021f2:	85e2                	mv	a1,s8
    800021f4:	854a                	mv	a0,s2
    800021f6:	00000097          	auipc	ra,0x0
    800021fa:	e7e080e7          	jalr	-386(ra) # 80002074 <sleep>
    havekids = 0;
    800021fe:	b715                	j	80002122 <wait+0x4a>

0000000080002200 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002200:	7139                	addi	sp,sp,-64
    80002202:	fc06                	sd	ra,56(sp)
    80002204:	f822                	sd	s0,48(sp)
    80002206:	f426                	sd	s1,40(sp)
    80002208:	f04a                	sd	s2,32(sp)
    8000220a:	ec4e                	sd	s3,24(sp)
    8000220c:	e852                	sd	s4,16(sp)
    8000220e:	e456                	sd	s5,8(sp)
    80002210:	0080                	addi	s0,sp,64
    80002212:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002214:	0000f497          	auipc	s1,0xf
    80002218:	4bc48493          	addi	s1,s1,1212 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000221c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000221e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002220:	00015917          	auipc	s2,0x15
    80002224:	0b090913          	addi	s2,s2,176 # 800172d0 <tickslock>
    80002228:	a821                	j	80002240 <wakeup+0x40>
        p->state = RUNNABLE;
    8000222a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a68080e7          	jalr	-1432(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002238:	17048493          	addi	s1,s1,368
    8000223c:	03248463          	beq	s1,s2,80002264 <wakeup+0x64>
    if(p != myproc()){
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	770080e7          	jalr	1904(ra) # 800019b0 <myproc>
    80002248:	fea488e3          	beq	s1,a0,80002238 <wakeup+0x38>
      acquire(&p->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	996080e7          	jalr	-1642(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002256:	4c9c                	lw	a5,24(s1)
    80002258:	fd379be3          	bne	a5,s3,8000222e <wakeup+0x2e>
    8000225c:	709c                	ld	a5,32(s1)
    8000225e:	fd4798e3          	bne	a5,s4,8000222e <wakeup+0x2e>
    80002262:	b7e1                	j	8000222a <wakeup+0x2a>
    }
  }
}
    80002264:	70e2                	ld	ra,56(sp)
    80002266:	7442                	ld	s0,48(sp)
    80002268:	74a2                	ld	s1,40(sp)
    8000226a:	7902                	ld	s2,32(sp)
    8000226c:	69e2                	ld	s3,24(sp)
    8000226e:	6a42                	ld	s4,16(sp)
    80002270:	6aa2                	ld	s5,8(sp)
    80002272:	6121                	addi	sp,sp,64
    80002274:	8082                	ret

0000000080002276 <reparent>:
{
    80002276:	7179                	addi	sp,sp,-48
    80002278:	f406                	sd	ra,40(sp)
    8000227a:	f022                	sd	s0,32(sp)
    8000227c:	ec26                	sd	s1,24(sp)
    8000227e:	e84a                	sd	s2,16(sp)
    80002280:	e44e                	sd	s3,8(sp)
    80002282:	e052                	sd	s4,0(sp)
    80002284:	1800                	addi	s0,sp,48
    80002286:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002288:	0000f497          	auipc	s1,0xf
    8000228c:	44848493          	addi	s1,s1,1096 # 800116d0 <proc>
      pp->parent = initproc;
    80002290:	00007a17          	auipc	s4,0x7
    80002294:	d98a0a13          	addi	s4,s4,-616 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002298:	00015997          	auipc	s3,0x15
    8000229c:	03898993          	addi	s3,s3,56 # 800172d0 <tickslock>
    800022a0:	a029                	j	800022aa <reparent+0x34>
    800022a2:	17048493          	addi	s1,s1,368
    800022a6:	01348d63          	beq	s1,s3,800022c0 <reparent+0x4a>
    if(pp->parent == p){
    800022aa:	7c9c                	ld	a5,56(s1)
    800022ac:	ff279be3          	bne	a5,s2,800022a2 <reparent+0x2c>
      pp->parent = initproc;
    800022b0:	000a3503          	ld	a0,0(s4)
    800022b4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	f4a080e7          	jalr	-182(ra) # 80002200 <wakeup>
    800022be:	b7d5                	j	800022a2 <reparent+0x2c>
}
    800022c0:	70a2                	ld	ra,40(sp)
    800022c2:	7402                	ld	s0,32(sp)
    800022c4:	64e2                	ld	s1,24(sp)
    800022c6:	6942                	ld	s2,16(sp)
    800022c8:	69a2                	ld	s3,8(sp)
    800022ca:	6a02                	ld	s4,0(sp)
    800022cc:	6145                	addi	sp,sp,48
    800022ce:	8082                	ret

00000000800022d0 <exit>:
{
    800022d0:	7179                	addi	sp,sp,-48
    800022d2:	f406                	sd	ra,40(sp)
    800022d4:	f022                	sd	s0,32(sp)
    800022d6:	ec26                	sd	s1,24(sp)
    800022d8:	e84a                	sd	s2,16(sp)
    800022da:	e44e                	sd	s3,8(sp)
    800022dc:	e052                	sd	s4,0(sp)
    800022de:	1800                	addi	s0,sp,48
    800022e0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	6ce080e7          	jalr	1742(ra) # 800019b0 <myproc>
    800022ea:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ec:	00007797          	auipc	a5,0x7
    800022f0:	d3c7b783          	ld	a5,-708(a5) # 80009028 <initproc>
    800022f4:	0d050493          	addi	s1,a0,208
    800022f8:	15050913          	addi	s2,a0,336
    800022fc:	02a79363          	bne	a5,a0,80002322 <exit+0x52>
    panic("init exiting");
    80002300:	00006517          	auipc	a0,0x6
    80002304:	f6050513          	addi	a0,a0,-160 # 80008260 <digits+0x220>
    80002308:	ffffe097          	auipc	ra,0xffffe
    8000230c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      fileclose(f);
    80002310:	00002097          	auipc	ra,0x2
    80002314:	2d6080e7          	jalr	726(ra) # 800045e6 <fileclose>
      p->ofile[fd] = 0;
    80002318:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000231c:	04a1                	addi	s1,s1,8
    8000231e:	01248563          	beq	s1,s2,80002328 <exit+0x58>
    if(p->ofile[fd]){
    80002322:	6088                	ld	a0,0(s1)
    80002324:	f575                	bnez	a0,80002310 <exit+0x40>
    80002326:	bfdd                	j	8000231c <exit+0x4c>
  begin_op();
    80002328:	00002097          	auipc	ra,0x2
    8000232c:	df2080e7          	jalr	-526(ra) # 8000411a <begin_op>
  iput(p->cwd);
    80002330:	1509b503          	ld	a0,336(s3)
    80002334:	00001097          	auipc	ra,0x1
    80002338:	5ce080e7          	jalr	1486(ra) # 80003902 <iput>
  end_op();
    8000233c:	00002097          	auipc	ra,0x2
    80002340:	e5e080e7          	jalr	-418(ra) # 8000419a <end_op>
  p->cwd = 0;
    80002344:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002348:	0000f497          	auipc	s1,0xf
    8000234c:	f7048493          	addi	s1,s1,-144 # 800112b8 <wait_lock>
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	892080e7          	jalr	-1902(ra) # 80000be4 <acquire>
  reparent(p);
    8000235a:	854e                	mv	a0,s3
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	f1a080e7          	jalr	-230(ra) # 80002276 <reparent>
  wakeup(p->parent);
    80002364:	0389b503          	ld	a0,56(s3)
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	e98080e7          	jalr	-360(ra) # 80002200 <wakeup>
  acquire(&p->lock);
    80002370:	854e                	mv	a0,s3
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	872080e7          	jalr	-1934(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000237a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000237e:	4795                	li	a5,5
    80002380:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
  sched();
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	bd4080e7          	jalr	-1068(ra) # 80001f62 <sched>
  panic("zombie exit");
    80002396:	00006517          	auipc	a0,0x6
    8000239a:	eda50513          	addi	a0,a0,-294 # 80008270 <digits+0x230>
    8000239e:	ffffe097          	auipc	ra,0xffffe
    800023a2:	1a0080e7          	jalr	416(ra) # 8000053e <panic>

00000000800023a6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023a6:	7179                	addi	sp,sp,-48
    800023a8:	f406                	sd	ra,40(sp)
    800023aa:	f022                	sd	s0,32(sp)
    800023ac:	ec26                	sd	s1,24(sp)
    800023ae:	e84a                	sd	s2,16(sp)
    800023b0:	e44e                	sd	s3,8(sp)
    800023b2:	1800                	addi	s0,sp,48
    800023b4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023b6:	0000f497          	auipc	s1,0xf
    800023ba:	31a48493          	addi	s1,s1,794 # 800116d0 <proc>
    800023be:	00015997          	auipc	s3,0x15
    800023c2:	f1298993          	addi	s3,s3,-238 # 800172d0 <tickslock>
    acquire(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800023d0:	589c                	lw	a5,48(s1)
    800023d2:	01278d63          	beq	a5,s2,800023ec <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023e0:	17048493          	addi	s1,s1,368
    800023e4:	ff3491e3          	bne	s1,s3,800023c6 <kill+0x20>
  }
  return -1;
    800023e8:	557d                	li	a0,-1
    800023ea:	a829                	j	80002404 <kill+0x5e>
      p->killed = 1;
    800023ec:	4785                	li	a5,1
    800023ee:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023f0:	4c98                	lw	a4,24(s1)
    800023f2:	4789                	li	a5,2
    800023f4:	00f70f63          	beq	a4,a5,80002412 <kill+0x6c>
      release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
      return 0;
    80002402:	4501                	li	a0,0
}
    80002404:	70a2                	ld	ra,40(sp)
    80002406:	7402                	ld	s0,32(sp)
    80002408:	64e2                	ld	s1,24(sp)
    8000240a:	6942                	ld	s2,16(sp)
    8000240c:	69a2                	ld	s3,8(sp)
    8000240e:	6145                	addi	sp,sp,48
    80002410:	8082                	ret
        p->state = RUNNABLE;
    80002412:	478d                	li	a5,3
    80002414:	cc9c                	sw	a5,24(s1)
    80002416:	b7cd                	j	800023f8 <kill+0x52>

0000000080002418 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	e052                	sd	s4,0(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	84aa                	mv	s1,a0
    8000242a:	892e                	mv	s2,a1
    8000242c:	89b2                	mv	s3,a2
    8000242e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	580080e7          	jalr	1408(ra) # 800019b0 <myproc>
  if(user_dst){
    80002438:	c08d                	beqz	s1,8000245a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000243a:	86d2                	mv	a3,s4
    8000243c:	864e                	mv	a2,s3
    8000243e:	85ca                	mv	a1,s2
    80002440:	6928                	ld	a0,80(a0)
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	230080e7          	jalr	560(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000244a:	70a2                	ld	ra,40(sp)
    8000244c:	7402                	ld	s0,32(sp)
    8000244e:	64e2                	ld	s1,24(sp)
    80002450:	6942                	ld	s2,16(sp)
    80002452:	69a2                	ld	s3,8(sp)
    80002454:	6a02                	ld	s4,0(sp)
    80002456:	6145                	addi	sp,sp,48
    80002458:	8082                	ret
    memmove((char *)dst, src, len);
    8000245a:	000a061b          	sext.w	a2,s4
    8000245e:	85ce                	mv	a1,s3
    80002460:	854a                	mv	a0,s2
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	8de080e7          	jalr	-1826(ra) # 80000d40 <memmove>
    return 0;
    8000246a:	8526                	mv	a0,s1
    8000246c:	bff9                	j	8000244a <either_copyout+0x32>

000000008000246e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000246e:	7179                	addi	sp,sp,-48
    80002470:	f406                	sd	ra,40(sp)
    80002472:	f022                	sd	s0,32(sp)
    80002474:	ec26                	sd	s1,24(sp)
    80002476:	e84a                	sd	s2,16(sp)
    80002478:	e44e                	sd	s3,8(sp)
    8000247a:	e052                	sd	s4,0(sp)
    8000247c:	1800                	addi	s0,sp,48
    8000247e:	892a                	mv	s2,a0
    80002480:	84ae                	mv	s1,a1
    80002482:	89b2                	mv	s3,a2
    80002484:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	52a080e7          	jalr	1322(ra) # 800019b0 <myproc>
  if(user_src){
    8000248e:	c08d                	beqz	s1,800024b0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002490:	86d2                	mv	a3,s4
    80002492:	864e                	mv	a2,s3
    80002494:	85ca                	mv	a1,s2
    80002496:	6928                	ld	a0,80(a0)
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	266080e7          	jalr	614(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024a0:	70a2                	ld	ra,40(sp)
    800024a2:	7402                	ld	s0,32(sp)
    800024a4:	64e2                	ld	s1,24(sp)
    800024a6:	6942                	ld	s2,16(sp)
    800024a8:	69a2                	ld	s3,8(sp)
    800024aa:	6a02                	ld	s4,0(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
    memmove(dst, (char*)src, len);
    800024b0:	000a061b          	sext.w	a2,s4
    800024b4:	85ce                	mv	a1,s3
    800024b6:	854a                	mv	a0,s2
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	888080e7          	jalr	-1912(ra) # 80000d40 <memmove>
    return 0;
    800024c0:	8526                	mv	a0,s1
    800024c2:	bff9                	j	800024a0 <either_copyin+0x32>

00000000800024c4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024c4:	715d                	addi	sp,sp,-80
    800024c6:	e486                	sd	ra,72(sp)
    800024c8:	e0a2                	sd	s0,64(sp)
    800024ca:	fc26                	sd	s1,56(sp)
    800024cc:	f84a                	sd	s2,48(sp)
    800024ce:	f44e                	sd	s3,40(sp)
    800024d0:	f052                	sd	s4,32(sp)
    800024d2:	ec56                	sd	s5,24(sp)
    800024d4:	e85a                	sd	s6,16(sp)
    800024d6:	e45e                	sd	s7,8(sp)
    800024d8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024da:	00006517          	auipc	a0,0x6
    800024de:	f4650513          	addi	a0,a0,-186 # 80008420 <states.1712+0x160>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	0a6080e7          	jalr	166(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ea:	0000f497          	auipc	s1,0xf
    800024ee:	33e48493          	addi	s1,s1,830 # 80011828 <proc+0x158>
    800024f2:	00015917          	auipc	s2,0x15
    800024f6:	f3690913          	addi	s2,s2,-202 # 80017428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024fa:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024fc:	00006997          	auipc	s3,0x6
    80002500:	d8498993          	addi	s3,s3,-636 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002504:	00006a97          	auipc	s5,0x6
    80002508:	d84a8a93          	addi	s5,s5,-636 # 80008288 <digits+0x248>
    printf("\n");
    8000250c:	00006a17          	auipc	s4,0x6
    80002510:	f14a0a13          	addi	s4,s4,-236 # 80008420 <states.1712+0x160>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002514:	00006b97          	auipc	s7,0x6
    80002518:	dacb8b93          	addi	s7,s7,-596 # 800082c0 <states.1712>
    8000251c:	a00d                	j	8000253e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000251e:	ed86a583          	lw	a1,-296(a3)
    80002522:	8556                	mv	a0,s5
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	064080e7          	jalr	100(ra) # 80000588 <printf>
    printf("\n");
    8000252c:	8552                	mv	a0,s4
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	05a080e7          	jalr	90(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002536:	17048493          	addi	s1,s1,368
    8000253a:	03248163          	beq	s1,s2,8000255c <procdump+0x98>
    if(p->state == UNUSED)
    8000253e:	86a6                	mv	a3,s1
    80002540:	ec04a783          	lw	a5,-320(s1)
    80002544:	dbed                	beqz	a5,80002536 <procdump+0x72>
      state = "???";
    80002546:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002548:	fcfb6be3          	bltu	s6,a5,8000251e <procdump+0x5a>
    8000254c:	1782                	slli	a5,a5,0x20
    8000254e:	9381                	srli	a5,a5,0x20
    80002550:	078e                	slli	a5,a5,0x3
    80002552:	97de                	add	a5,a5,s7
    80002554:	6390                	ld	a2,0(a5)
    80002556:	f661                	bnez	a2,8000251e <procdump+0x5a>
      state = "???";
    80002558:	864e                	mv	a2,s3
    8000255a:	b7d1                	j	8000251e <procdump+0x5a>
  }
}
    8000255c:	60a6                	ld	ra,72(sp)
    8000255e:	6406                	ld	s0,64(sp)
    80002560:	74e2                	ld	s1,56(sp)
    80002562:	7942                	ld	s2,48(sp)
    80002564:	79a2                	ld	s3,40(sp)
    80002566:	7a02                	ld	s4,32(sp)
    80002568:	6ae2                	ld	s5,24(sp)
    8000256a:	6b42                	ld	s6,16(sp)
    8000256c:	6ba2                	ld	s7,8(sp)
    8000256e:	6161                	addi	sp,sp,80
    80002570:	8082                	ret

0000000080002572 <trace>:

// enabling tracing for the current process
void
trace(int trace_mask)
{
    80002572:	1101                	addi	sp,sp,-32
    80002574:	ec06                	sd	ra,24(sp)
    80002576:	e822                	sd	s0,16(sp)
    80002578:	e426                	sd	s1,8(sp)
    8000257a:	1000                	addi	s0,sp,32
    8000257c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	432080e7          	jalr	1074(ra) # 800019b0 <myproc>
  p->trace_mask = trace_mask;
    80002586:	16952423          	sw	s1,360(a0)
    8000258a:	60e2                	ld	ra,24(sp)
    8000258c:	6442                	ld	s0,16(sp)
    8000258e:	64a2                	ld	s1,8(sp)
    80002590:	6105                	addi	sp,sp,32
    80002592:	8082                	ret

0000000080002594 <swtch>:
    80002594:	00153023          	sd	ra,0(a0)
    80002598:	00253423          	sd	sp,8(a0)
    8000259c:	e900                	sd	s0,16(a0)
    8000259e:	ed04                	sd	s1,24(a0)
    800025a0:	03253023          	sd	s2,32(a0)
    800025a4:	03353423          	sd	s3,40(a0)
    800025a8:	03453823          	sd	s4,48(a0)
    800025ac:	03553c23          	sd	s5,56(a0)
    800025b0:	05653023          	sd	s6,64(a0)
    800025b4:	05753423          	sd	s7,72(a0)
    800025b8:	05853823          	sd	s8,80(a0)
    800025bc:	05953c23          	sd	s9,88(a0)
    800025c0:	07a53023          	sd	s10,96(a0)
    800025c4:	07b53423          	sd	s11,104(a0)
    800025c8:	0005b083          	ld	ra,0(a1)
    800025cc:	0085b103          	ld	sp,8(a1)
    800025d0:	6980                	ld	s0,16(a1)
    800025d2:	6d84                	ld	s1,24(a1)
    800025d4:	0205b903          	ld	s2,32(a1)
    800025d8:	0285b983          	ld	s3,40(a1)
    800025dc:	0305ba03          	ld	s4,48(a1)
    800025e0:	0385ba83          	ld	s5,56(a1)
    800025e4:	0405bb03          	ld	s6,64(a1)
    800025e8:	0485bb83          	ld	s7,72(a1)
    800025ec:	0505bc03          	ld	s8,80(a1)
    800025f0:	0585bc83          	ld	s9,88(a1)
    800025f4:	0605bd03          	ld	s10,96(a1)
    800025f8:	0685bd83          	ld	s11,104(a1)
    800025fc:	8082                	ret

00000000800025fe <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025fe:	1141                	addi	sp,sp,-16
    80002600:	e406                	sd	ra,8(sp)
    80002602:	e022                	sd	s0,0(sp)
    80002604:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002606:	00006597          	auipc	a1,0x6
    8000260a:	cea58593          	addi	a1,a1,-790 # 800082f0 <states.1712+0x30>
    8000260e:	00015517          	auipc	a0,0x15
    80002612:	cc250513          	addi	a0,a0,-830 # 800172d0 <tickslock>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	53e080e7          	jalr	1342(ra) # 80000b54 <initlock>
}
    8000261e:	60a2                	ld	ra,8(sp)
    80002620:	6402                	ld	s0,0(sp)
    80002622:	0141                	addi	sp,sp,16
    80002624:	8082                	ret

0000000080002626 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002626:	1141                	addi	sp,sp,-16
    80002628:	e422                	sd	s0,8(sp)
    8000262a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000262c:	00003797          	auipc	a5,0x3
    80002630:	5d478793          	addi	a5,a5,1492 # 80005c00 <kernelvec>
    80002634:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002638:	6422                	ld	s0,8(sp)
    8000263a:	0141                	addi	sp,sp,16
    8000263c:	8082                	ret

000000008000263e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000263e:	1141                	addi	sp,sp,-16
    80002640:	e406                	sd	ra,8(sp)
    80002642:	e022                	sd	s0,0(sp)
    80002644:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	36a080e7          	jalr	874(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002652:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002654:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002658:	00005617          	auipc	a2,0x5
    8000265c:	9a860613          	addi	a2,a2,-1624 # 80007000 <_trampoline>
    80002660:	00005697          	auipc	a3,0x5
    80002664:	9a068693          	addi	a3,a3,-1632 # 80007000 <_trampoline>
    80002668:	8e91                	sub	a3,a3,a2
    8000266a:	040007b7          	lui	a5,0x4000
    8000266e:	17fd                	addi	a5,a5,-1
    80002670:	07b2                	slli	a5,a5,0xc
    80002672:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002674:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002678:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000267a:	180026f3          	csrr	a3,satp
    8000267e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002680:	6d38                	ld	a4,88(a0)
    80002682:	6134                	ld	a3,64(a0)
    80002684:	6585                	lui	a1,0x1
    80002686:	96ae                	add	a3,a3,a1
    80002688:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000268a:	6d38                	ld	a4,88(a0)
    8000268c:	00000697          	auipc	a3,0x0
    80002690:	13868693          	addi	a3,a3,312 # 800027c4 <usertrap>
    80002694:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002696:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002698:	8692                	mv	a3,tp
    8000269a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000269c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026a0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026a4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ae:	6f18                	ld	a4,24(a4)
    800026b0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026b4:	692c                	ld	a1,80(a0)
    800026b6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026b8:	00005717          	auipc	a4,0x5
    800026bc:	9d870713          	addi	a4,a4,-1576 # 80007090 <userret>
    800026c0:	8f11                	sub	a4,a4,a2
    800026c2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026c4:	577d                	li	a4,-1
    800026c6:	177e                	slli	a4,a4,0x3f
    800026c8:	8dd9                	or	a1,a1,a4
    800026ca:	02000537          	lui	a0,0x2000
    800026ce:	157d                	addi	a0,a0,-1
    800026d0:	0536                	slli	a0,a0,0xd
    800026d2:	9782                	jalr	a5
}
    800026d4:	60a2                	ld	ra,8(sp)
    800026d6:	6402                	ld	s0,0(sp)
    800026d8:	0141                	addi	sp,sp,16
    800026da:	8082                	ret

00000000800026dc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026dc:	1101                	addi	sp,sp,-32
    800026de:	ec06                	sd	ra,24(sp)
    800026e0:	e822                	sd	s0,16(sp)
    800026e2:	e426                	sd	s1,8(sp)
    800026e4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026e6:	00015497          	auipc	s1,0x15
    800026ea:	bea48493          	addi	s1,s1,-1046 # 800172d0 <tickslock>
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  ticks++;
    800026f8:	00007517          	auipc	a0,0x7
    800026fc:	93850513          	addi	a0,a0,-1736 # 80009030 <ticks>
    80002700:	411c                	lw	a5,0(a0)
    80002702:	2785                	addiw	a5,a5,1
    80002704:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002706:	00000097          	auipc	ra,0x0
    8000270a:	afa080e7          	jalr	-1286(ra) # 80002200 <wakeup>
  release(&tickslock);
    8000270e:	8526                	mv	a0,s1
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	588080e7          	jalr	1416(ra) # 80000c98 <release>
}
    80002718:	60e2                	ld	ra,24(sp)
    8000271a:	6442                	ld	s0,16(sp)
    8000271c:	64a2                	ld	s1,8(sp)
    8000271e:	6105                	addi	sp,sp,32
    80002720:	8082                	ret

0000000080002722 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002722:	1101                	addi	sp,sp,-32
    80002724:	ec06                	sd	ra,24(sp)
    80002726:	e822                	sd	s0,16(sp)
    80002728:	e426                	sd	s1,8(sp)
    8000272a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000272c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002730:	00074d63          	bltz	a4,8000274a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002734:	57fd                	li	a5,-1
    80002736:	17fe                	slli	a5,a5,0x3f
    80002738:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000273a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000273c:	06f70363          	beq	a4,a5,800027a2 <devintr+0x80>
  }
}
    80002740:	60e2                	ld	ra,24(sp)
    80002742:	6442                	ld	s0,16(sp)
    80002744:	64a2                	ld	s1,8(sp)
    80002746:	6105                	addi	sp,sp,32
    80002748:	8082                	ret
     (scause & 0xff) == 9){
    8000274a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000274e:	46a5                	li	a3,9
    80002750:	fed792e3          	bne	a5,a3,80002734 <devintr+0x12>
    int irq = plic_claim();
    80002754:	00003097          	auipc	ra,0x3
    80002758:	5b4080e7          	jalr	1460(ra) # 80005d08 <plic_claim>
    8000275c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000275e:	47a9                	li	a5,10
    80002760:	02f50763          	beq	a0,a5,8000278e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002764:	4785                	li	a5,1
    80002766:	02f50963          	beq	a0,a5,80002798 <devintr+0x76>
    return 1;
    8000276a:	4505                	li	a0,1
    } else if(irq){
    8000276c:	d8f1                	beqz	s1,80002740 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000276e:	85a6                	mv	a1,s1
    80002770:	00006517          	auipc	a0,0x6
    80002774:	b8850513          	addi	a0,a0,-1144 # 800082f8 <states.1712+0x38>
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	e10080e7          	jalr	-496(ra) # 80000588 <printf>
      plic_complete(irq);
    80002780:	8526                	mv	a0,s1
    80002782:	00003097          	auipc	ra,0x3
    80002786:	5aa080e7          	jalr	1450(ra) # 80005d2c <plic_complete>
    return 1;
    8000278a:	4505                	li	a0,1
    8000278c:	bf55                	j	80002740 <devintr+0x1e>
      uartintr();
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	21a080e7          	jalr	538(ra) # 800009a8 <uartintr>
    80002796:	b7ed                	j	80002780 <devintr+0x5e>
      virtio_disk_intr();
    80002798:	00004097          	auipc	ra,0x4
    8000279c:	a74080e7          	jalr	-1420(ra) # 8000620c <virtio_disk_intr>
    800027a0:	b7c5                	j	80002780 <devintr+0x5e>
    if(cpuid() == 0){
    800027a2:	fffff097          	auipc	ra,0xfffff
    800027a6:	1e2080e7          	jalr	482(ra) # 80001984 <cpuid>
    800027aa:	c901                	beqz	a0,800027ba <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027ac:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027b2:	14479073          	csrw	sip,a5
    return 2;
    800027b6:	4509                	li	a0,2
    800027b8:	b761                	j	80002740 <devintr+0x1e>
      clockintr();
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	f22080e7          	jalr	-222(ra) # 800026dc <clockintr>
    800027c2:	b7ed                	j	800027ac <devintr+0x8a>

00000000800027c4 <usertrap>:
{
    800027c4:	1101                	addi	sp,sp,-32
    800027c6:	ec06                	sd	ra,24(sp)
    800027c8:	e822                	sd	s0,16(sp)
    800027ca:	e426                	sd	s1,8(sp)
    800027cc:	e04a                	sd	s2,0(sp)
    800027ce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027d4:	1007f793          	andi	a5,a5,256
    800027d8:	e3ad                	bnez	a5,8000283a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027da:	00003797          	auipc	a5,0x3
    800027de:	42678793          	addi	a5,a5,1062 # 80005c00 <kernelvec>
    800027e2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027e6:	fffff097          	auipc	ra,0xfffff
    800027ea:	1ca080e7          	jalr	458(ra) # 800019b0 <myproc>
    800027ee:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027f0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027f2:	14102773          	csrr	a4,sepc
    800027f6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027fc:	47a1                	li	a5,8
    800027fe:	04f71c63          	bne	a4,a5,80002856 <usertrap+0x92>
    if(p->killed)
    80002802:	551c                	lw	a5,40(a0)
    80002804:	e3b9                	bnez	a5,8000284a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002806:	6cb8                	ld	a4,88(s1)
    80002808:	6f1c                	ld	a5,24(a4)
    8000280a:	0791                	addi	a5,a5,4
    8000280c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002812:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002816:	10079073          	csrw	sstatus,a5
    syscall();
    8000281a:	00000097          	auipc	ra,0x0
    8000281e:	2e0080e7          	jalr	736(ra) # 80002afa <syscall>
  if(p->killed)
    80002822:	549c                	lw	a5,40(s1)
    80002824:	ebc1                	bnez	a5,800028b4 <usertrap+0xf0>
  usertrapret();
    80002826:	00000097          	auipc	ra,0x0
    8000282a:	e18080e7          	jalr	-488(ra) # 8000263e <usertrapret>
}
    8000282e:	60e2                	ld	ra,24(sp)
    80002830:	6442                	ld	s0,16(sp)
    80002832:	64a2                	ld	s1,8(sp)
    80002834:	6902                	ld	s2,0(sp)
    80002836:	6105                	addi	sp,sp,32
    80002838:	8082                	ret
    panic("usertrap: not from user mode");
    8000283a:	00006517          	auipc	a0,0x6
    8000283e:	ade50513          	addi	a0,a0,-1314 # 80008318 <states.1712+0x58>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	cfc080e7          	jalr	-772(ra) # 8000053e <panic>
      exit(-1);
    8000284a:	557d                	li	a0,-1
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	a84080e7          	jalr	-1404(ra) # 800022d0 <exit>
    80002854:	bf4d                	j	80002806 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	ecc080e7          	jalr	-308(ra) # 80002722 <devintr>
    8000285e:	892a                	mv	s2,a0
    80002860:	c501                	beqz	a0,80002868 <usertrap+0xa4>
  if(p->killed)
    80002862:	549c                	lw	a5,40(s1)
    80002864:	c3a1                	beqz	a5,800028a4 <usertrap+0xe0>
    80002866:	a815                	j	8000289a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002868:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000286c:	5890                	lw	a2,48(s1)
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	aca50513          	addi	a0,a0,-1334 # 80008338 <states.1712+0x78>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	d12080e7          	jalr	-750(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000287e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002882:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002886:	00006517          	auipc	a0,0x6
    8000288a:	ae250513          	addi	a0,a0,-1310 # 80008368 <states.1712+0xa8>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	cfa080e7          	jalr	-774(ra) # 80000588 <printf>
    p->killed = 1;
    80002896:	4785                	li	a5,1
    80002898:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000289a:	557d                	li	a0,-1
    8000289c:	00000097          	auipc	ra,0x0
    800028a0:	a34080e7          	jalr	-1484(ra) # 800022d0 <exit>
  if(which_dev == 2)
    800028a4:	4789                	li	a5,2
    800028a6:	f8f910e3          	bne	s2,a5,80002826 <usertrap+0x62>
    yield();
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	78e080e7          	jalr	1934(ra) # 80002038 <yield>
    800028b2:	bf95                	j	80002826 <usertrap+0x62>
  int which_dev = 0;
    800028b4:	4901                	li	s2,0
    800028b6:	b7d5                	j	8000289a <usertrap+0xd6>

00000000800028b8 <kerneltrap>:
{
    800028b8:	7179                	addi	sp,sp,-48
    800028ba:	f406                	sd	ra,40(sp)
    800028bc:	f022                	sd	s0,32(sp)
    800028be:	ec26                	sd	s1,24(sp)
    800028c0:	e84a                	sd	s2,16(sp)
    800028c2:	e44e                	sd	s3,8(sp)
    800028c4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ce:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028d2:	1004f793          	andi	a5,s1,256
    800028d6:	cb85                	beqz	a5,80002906 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028dc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028de:	ef85                	bnez	a5,80002916 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	e42080e7          	jalr	-446(ra) # 80002722 <devintr>
    800028e8:	cd1d                	beqz	a0,80002926 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028ea:	4789                	li	a5,2
    800028ec:	06f50a63          	beq	a0,a5,80002960 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f4:	10049073          	csrw	sstatus,s1
}
    800028f8:	70a2                	ld	ra,40(sp)
    800028fa:	7402                	ld	s0,32(sp)
    800028fc:	64e2                	ld	s1,24(sp)
    800028fe:	6942                	ld	s2,16(sp)
    80002900:	69a2                	ld	s3,8(sp)
    80002902:	6145                	addi	sp,sp,48
    80002904:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	a8250513          	addi	a0,a0,-1406 # 80008388 <states.1712+0xc8>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	a9a50513          	addi	a0,a0,-1382 # 800083b0 <states.1712+0xf0>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002926:	85ce                	mv	a1,s3
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	aa850513          	addi	a0,a0,-1368 # 800083d0 <states.1712+0x110>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c58080e7          	jalr	-936(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002938:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002940:	00006517          	auipc	a0,0x6
    80002944:	aa050513          	addi	a0,a0,-1376 # 800083e0 <states.1712+0x120>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c40080e7          	jalr	-960(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002950:	00006517          	auipc	a0,0x6
    80002954:	aa850513          	addi	a0,a0,-1368 # 800083f8 <states.1712+0x138>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	be6080e7          	jalr	-1050(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	050080e7          	jalr	80(ra) # 800019b0 <myproc>
    80002968:	d541                	beqz	a0,800028f0 <kerneltrap+0x38>
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	046080e7          	jalr	70(ra) # 800019b0 <myproc>
    80002972:	4d18                	lw	a4,24(a0)
    80002974:	4791                	li	a5,4
    80002976:	f6f71de3          	bne	a4,a5,800028f0 <kerneltrap+0x38>
    yield();
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	6be080e7          	jalr	1726(ra) # 80002038 <yield>
    80002982:	b7bd                	j	800028f0 <kerneltrap+0x38>

0000000080002984 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002984:	1101                	addi	sp,sp,-32
    80002986:	ec06                	sd	ra,24(sp)
    80002988:	e822                	sd	s0,16(sp)
    8000298a:	e426                	sd	s1,8(sp)
    8000298c:	1000                	addi	s0,sp,32
    8000298e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	020080e7          	jalr	32(ra) # 800019b0 <myproc>
  switch (n) {
    80002998:	4795                	li	a5,5
    8000299a:	0497e163          	bltu	a5,s1,800029dc <argraw+0x58>
    8000299e:	048a                	slli	s1,s1,0x2
    800029a0:	00006717          	auipc	a4,0x6
    800029a4:	b6870713          	addi	a4,a4,-1176 # 80008508 <states.1712+0x248>
    800029a8:	94ba                	add	s1,s1,a4
    800029aa:	409c                	lw	a5,0(s1)
    800029ac:	97ba                	add	a5,a5,a4
    800029ae:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029b0:	6d3c                	ld	a5,88(a0)
    800029b2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029b4:	60e2                	ld	ra,24(sp)
    800029b6:	6442                	ld	s0,16(sp)
    800029b8:	64a2                	ld	s1,8(sp)
    800029ba:	6105                	addi	sp,sp,32
    800029bc:	8082                	ret
    return p->trapframe->a1;
    800029be:	6d3c                	ld	a5,88(a0)
    800029c0:	7fa8                	ld	a0,120(a5)
    800029c2:	bfcd                	j	800029b4 <argraw+0x30>
    return p->trapframe->a2;
    800029c4:	6d3c                	ld	a5,88(a0)
    800029c6:	63c8                	ld	a0,128(a5)
    800029c8:	b7f5                	j	800029b4 <argraw+0x30>
    return p->trapframe->a3;
    800029ca:	6d3c                	ld	a5,88(a0)
    800029cc:	67c8                	ld	a0,136(a5)
    800029ce:	b7dd                	j	800029b4 <argraw+0x30>
    return p->trapframe->a4;
    800029d0:	6d3c                	ld	a5,88(a0)
    800029d2:	6bc8                	ld	a0,144(a5)
    800029d4:	b7c5                	j	800029b4 <argraw+0x30>
    return p->trapframe->a5;
    800029d6:	6d3c                	ld	a5,88(a0)
    800029d8:	6fc8                	ld	a0,152(a5)
    800029da:	bfe9                	j	800029b4 <argraw+0x30>
  panic("argraw");
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	a2c50513          	addi	a0,a0,-1492 # 80008408 <states.1712+0x148>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	b5a080e7          	jalr	-1190(ra) # 8000053e <panic>

00000000800029ec <fetchaddr>:
{
    800029ec:	1101                	addi	sp,sp,-32
    800029ee:	ec06                	sd	ra,24(sp)
    800029f0:	e822                	sd	s0,16(sp)
    800029f2:	e426                	sd	s1,8(sp)
    800029f4:	e04a                	sd	s2,0(sp)
    800029f6:	1000                	addi	s0,sp,32
    800029f8:	84aa                	mv	s1,a0
    800029fa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	fb4080e7          	jalr	-76(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a04:	653c                	ld	a5,72(a0)
    80002a06:	02f4f863          	bgeu	s1,a5,80002a36 <fetchaddr+0x4a>
    80002a0a:	00848713          	addi	a4,s1,8
    80002a0e:	02e7e663          	bltu	a5,a4,80002a3a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a12:	46a1                	li	a3,8
    80002a14:	8626                	mv	a2,s1
    80002a16:	85ca                	mv	a1,s2
    80002a18:	6928                	ld	a0,80(a0)
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	ce4080e7          	jalr	-796(ra) # 800016fe <copyin>
    80002a22:	00a03533          	snez	a0,a0
    80002a26:	40a00533          	neg	a0,a0
}
    80002a2a:	60e2                	ld	ra,24(sp)
    80002a2c:	6442                	ld	s0,16(sp)
    80002a2e:	64a2                	ld	s1,8(sp)
    80002a30:	6902                	ld	s2,0(sp)
    80002a32:	6105                	addi	sp,sp,32
    80002a34:	8082                	ret
    return -1;
    80002a36:	557d                	li	a0,-1
    80002a38:	bfcd                	j	80002a2a <fetchaddr+0x3e>
    80002a3a:	557d                	li	a0,-1
    80002a3c:	b7fd                	j	80002a2a <fetchaddr+0x3e>

0000000080002a3e <fetchstr>:
{
    80002a3e:	7179                	addi	sp,sp,-48
    80002a40:	f406                	sd	ra,40(sp)
    80002a42:	f022                	sd	s0,32(sp)
    80002a44:	ec26                	sd	s1,24(sp)
    80002a46:	e84a                	sd	s2,16(sp)
    80002a48:	e44e                	sd	s3,8(sp)
    80002a4a:	1800                	addi	s0,sp,48
    80002a4c:	892a                	mv	s2,a0
    80002a4e:	84ae                	mv	s1,a1
    80002a50:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	f5e080e7          	jalr	-162(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a5a:	86ce                	mv	a3,s3
    80002a5c:	864a                	mv	a2,s2
    80002a5e:	85a6                	mv	a1,s1
    80002a60:	6928                	ld	a0,80(a0)
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	d28080e7          	jalr	-728(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a6a:	00054763          	bltz	a0,80002a78 <fetchstr+0x3a>
  return strlen(buf);
    80002a6e:	8526                	mv	a0,s1
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	3f4080e7          	jalr	1012(ra) # 80000e64 <strlen>
}
    80002a78:	70a2                	ld	ra,40(sp)
    80002a7a:	7402                	ld	s0,32(sp)
    80002a7c:	64e2                	ld	s1,24(sp)
    80002a7e:	6942                	ld	s2,16(sp)
    80002a80:	69a2                	ld	s3,8(sp)
    80002a82:	6145                	addi	sp,sp,48
    80002a84:	8082                	ret

0000000080002a86 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a86:	1101                	addi	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	1000                	addi	s0,sp,32
    80002a90:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	ef2080e7          	jalr	-270(ra) # 80002984 <argraw>
    80002a9a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a9c:	4501                	li	a0,0
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6105                	addi	sp,sp,32
    80002aa6:	8082                	ret

0000000080002aa8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002aa8:	1101                	addi	sp,sp,-32
    80002aaa:	ec06                	sd	ra,24(sp)
    80002aac:	e822                	sd	s0,16(sp)
    80002aae:	e426                	sd	s1,8(sp)
    80002ab0:	1000                	addi	s0,sp,32
    80002ab2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	ed0080e7          	jalr	-304(ra) # 80002984 <argraw>
    80002abc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002abe:	4501                	li	a0,0
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6105                	addi	sp,sp,32
    80002ac8:	8082                	ret

0000000080002aca <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aca:	1101                	addi	sp,sp,-32
    80002acc:	ec06                	sd	ra,24(sp)
    80002ace:	e822                	sd	s0,16(sp)
    80002ad0:	e426                	sd	s1,8(sp)
    80002ad2:	e04a                	sd	s2,0(sp)
    80002ad4:	1000                	addi	s0,sp,32
    80002ad6:	84ae                	mv	s1,a1
    80002ad8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	eaa080e7          	jalr	-342(ra) # 80002984 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ae2:	864a                	mv	a2,s2
    80002ae4:	85a6                	mv	a1,s1
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	f58080e7          	jalr	-168(ra) # 80002a3e <fetchstr>
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6902                	ld	s2,0(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret

0000000080002afa <syscall>:
};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002afa:	711d                	addi	sp,sp,-96
    80002afc:	ec86                	sd	ra,88(sp)
    80002afe:	e8a2                	sd	s0,80(sp)
    80002b00:	e4a6                	sd	s1,72(sp)
    80002b02:	e0ca                	sd	s2,64(sp)
    80002b04:	fc4e                	sd	s3,56(sp)
    80002b06:	f852                	sd	s4,48(sp)
    80002b08:	f456                	sd	s5,40(sp)
    80002b0a:	f05a                	sd	s6,32(sp)
    80002b0c:	ec5e                	sd	s7,24(sp)
    80002b0e:	e862                	sd	s8,16(sp)
    80002b10:	e466                	sd	s9,8(sp)
    80002b12:	e06a                	sd	s10,0(sp)
    80002b14:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	e9a080e7          	jalr	-358(ra) # 800019b0 <myproc>
    80002b1e:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002b20:	6d24                	ld	s1,88(a0)
    80002b22:	74dc                	ld	a5,168(s1)
    80002b24:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b28:	37fd                	addiw	a5,a5,-1
    80002b2a:	4755                	li	a4,21
    80002b2c:	06f76f63          	bltu	a4,a5,80002baa <syscall+0xb0>
    80002b30:	003b1713          	slli	a4,s6,0x3
    80002b34:	00006797          	auipc	a5,0x6
    80002b38:	9ec78793          	addi	a5,a5,-1556 # 80008520 <syscalls>
    80002b3c:	97ba                	add	a5,a5,a4
    80002b3e:	0007bd03          	ld	s10,0(a5)
    80002b42:	060d0463          	beqz	s10,80002baa <syscall+0xb0>
    80002b46:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002b48:	fffb0c1b          	addiw	s8,s6,-1
    80002b4c:	004c1713          	slli	a4,s8,0x4
    80002b50:	00006797          	auipc	a5,0x6
    80002b54:	de878793          	addi	a5,a5,-536 # 80008938 <syscall_arg_infos>
    80002b58:	97ba                	add	a5,a5,a4
    80002b5a:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002b5e:	00299793          	slli	a5,s3,0x2
    80002b62:	07bd                	addi	a5,a5,15
    80002b64:	9bc1                	andi	a5,a5,-16
    80002b66:	40f10133          	sub	sp,sp,a5
    80002b6a:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002b6c:	0f305363          	blez	s3,80002c52 <syscall+0x158>
    80002b70:	8ade                	mv	s5,s7
    80002b72:	895e                	mv	s2,s7
    80002b74:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002b76:	8526                	mv	a0,s1
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	e0c080e7          	jalr	-500(ra) # 80002984 <argraw>
    80002b80:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002b84:	2485                	addiw	s1,s1,1
    80002b86:	0911                	addi	s2,s2,4
    80002b88:	fe9997e3          	bne	s3,s1,80002b76 <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002b8c:	058a3483          	ld	s1,88(s4)
    80002b90:	9d02                	jalr	s10
    80002b92:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002b94:	4785                	li	a5,1
    80002b96:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002b9a:	168a2b03          	lw	s6,360(s4)
    80002b9e:	0167f7b3          	and	a5,a5,s6
    80002ba2:	2781                	sext.w	a5,a5
    80002ba4:	e7a1                	bnez	a5,80002bec <syscall+0xf2>
    80002ba6:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ba8:	a015                	j	80002bcc <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002baa:	86da                	mv	a3,s6
    80002bac:	158a0613          	addi	a2,s4,344
    80002bb0:	030a2583          	lw	a1,48(s4)
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	87450513          	addi	a0,a0,-1932 # 80008428 <states.1712+0x168>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	9cc080e7          	jalr	-1588(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bc4:	058a3783          	ld	a5,88(s4)
    80002bc8:	577d                	li	a4,-1
    80002bca:	fbb8                	sd	a4,112(a5)
  }
}
    80002bcc:	fa040113          	addi	sp,s0,-96
    80002bd0:	60e6                	ld	ra,88(sp)
    80002bd2:	6446                	ld	s0,80(sp)
    80002bd4:	64a6                	ld	s1,72(sp)
    80002bd6:	6906                	ld	s2,64(sp)
    80002bd8:	79e2                	ld	s3,56(sp)
    80002bda:	7a42                	ld	s4,48(sp)
    80002bdc:	7aa2                	ld	s5,40(sp)
    80002bde:	7b02                	ld	s6,32(sp)
    80002be0:	6be2                	ld	s7,24(sp)
    80002be2:	6c42                	ld	s8,16(sp)
    80002be4:	6ca2                	ld	s9,8(sp)
    80002be6:	6d02                	ld	s10,0(sp)
    80002be8:	6125                	addi	sp,sp,96
    80002bea:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002bec:	0c12                	slli	s8,s8,0x4
    80002bee:	00006797          	auipc	a5,0x6
    80002bf2:	d4a78793          	addi	a5,a5,-694 # 80008938 <syscall_arg_infos>
    80002bf6:	9c3e                	add	s8,s8,a5
    80002bf8:	008c3603          	ld	a2,8(s8)
    80002bfc:	030a2583          	lw	a1,48(s4)
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	84850513          	addi	a0,a0,-1976 # 80008448 <states.1712+0x188>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	980080e7          	jalr	-1664(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002c10:	fff9879b          	addiw	a5,s3,-1
    80002c14:	1782                	slli	a5,a5,0x20
    80002c16:	9381                	srli	a5,a5,0x20
    80002c18:	0785                	addi	a5,a5,1
    80002c1a:	078a                	slli	a5,a5,0x2
    80002c1c:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80002c1e:	00005497          	auipc	s1,0x5
    80002c22:	7f248493          	addi	s1,s1,2034 # 80008410 <states.1712+0x150>
    80002c26:	000aa583          	lw	a1,0(s5)
    80002c2a:	8526                	mv	a0,s1
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	95c080e7          	jalr	-1700(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002c34:	0a91                	addi	s5,s5,4
    80002c36:	ff7a98e3          	bne	s5,s7,80002c26 <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    80002c3a:	058a3783          	ld	a5,88(s4)
    80002c3e:	7bac                	ld	a1,112(a5)
    80002c40:	00005517          	auipc	a0,0x5
    80002c44:	7d850513          	addi	a0,a0,2008 # 80008418 <states.1712+0x158>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	940080e7          	jalr	-1728(ra) # 80000588 <printf>
    80002c50:	bf99                	j	80002ba6 <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002c52:	9d02                	jalr	s10
    80002c54:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002c56:	4785                	li	a5,1
    80002c58:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002c5c:	168a2703          	lw	a4,360(s4)
    80002c60:	8ff9                	and	a5,a5,a4
    80002c62:	2781                	sext.w	a5,a5
    80002c64:	d3a9                	beqz	a5,80002ba6 <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002c66:	0c12                	slli	s8,s8,0x4
    80002c68:	00006797          	auipc	a5,0x6
    80002c6c:	cd078793          	addi	a5,a5,-816 # 80008938 <syscall_arg_infos>
    80002c70:	97e2                	add	a5,a5,s8
    80002c72:	6790                	ld	a2,8(a5)
    80002c74:	030a2583          	lw	a1,48(s4)
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7d050513          	addi	a0,a0,2000 # 80008448 <states.1712+0x188>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	908080e7          	jalr	-1784(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002c88:	bf4d                	j	80002c3a <syscall+0x140>

0000000080002c8a <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c92:	fec40593          	addi	a1,s0,-20
    80002c96:	4501                	li	a0,0
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	dee080e7          	jalr	-530(ra) # 80002a86 <argint>
    return -1;
    80002ca0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca2:	00054963          	bltz	a0,80002cb4 <sys_exit+0x2a>
  exit(n);
    80002ca6:	fec42503          	lw	a0,-20(s0)
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	626080e7          	jalr	1574(ra) # 800022d0 <exit>
  return 0;  // not reached
    80002cb2:	4781                	li	a5,0
}
    80002cb4:	853e                	mv	a0,a5
    80002cb6:	60e2                	ld	ra,24(sp)
    80002cb8:	6442                	ld	s0,16(sp)
    80002cba:	6105                	addi	sp,sp,32
    80002cbc:	8082                	ret

0000000080002cbe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cbe:	1141                	addi	sp,sp,-16
    80002cc0:	e406                	sd	ra,8(sp)
    80002cc2:	e022                	sd	s0,0(sp)
    80002cc4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	cea080e7          	jalr	-790(ra) # 800019b0 <myproc>
}
    80002cce:	5908                	lw	a0,48(a0)
    80002cd0:	60a2                	ld	ra,8(sp)
    80002cd2:	6402                	ld	s0,0(sp)
    80002cd4:	0141                	addi	sp,sp,16
    80002cd6:	8082                	ret

0000000080002cd8 <sys_fork>:

uint64
sys_fork(void)
{
    80002cd8:	1141                	addi	sp,sp,-16
    80002cda:	e406                	sd	ra,8(sp)
    80002cdc:	e022                	sd	s0,0(sp)
    80002cde:	0800                	addi	s0,sp,16
  return fork();
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	09e080e7          	jalr	158(ra) # 80001d7e <fork>
}
    80002ce8:	60a2                	ld	ra,8(sp)
    80002cea:	6402                	ld	s0,0(sp)
    80002cec:	0141                	addi	sp,sp,16
    80002cee:	8082                	ret

0000000080002cf0 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf0:	1101                	addi	sp,sp,-32
    80002cf2:	ec06                	sd	ra,24(sp)
    80002cf4:	e822                	sd	s0,16(sp)
    80002cf6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cf8:	fe840593          	addi	a1,s0,-24
    80002cfc:	4501                	li	a0,0
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	daa080e7          	jalr	-598(ra) # 80002aa8 <argaddr>
    80002d06:	87aa                	mv	a5,a0
    return -1;
    80002d08:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d0a:	0007c863          	bltz	a5,80002d1a <sys_wait+0x2a>
  return wait(p);
    80002d0e:	fe843503          	ld	a0,-24(s0)
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	3c6080e7          	jalr	966(ra) # 800020d8 <wait>
}
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d22:	7179                	addi	sp,sp,-48
    80002d24:	f406                	sd	ra,40(sp)
    80002d26:	f022                	sd	s0,32(sp)
    80002d28:	ec26                	sd	s1,24(sp)
    80002d2a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d2c:	fdc40593          	addi	a1,s0,-36
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	d54080e7          	jalr	-684(ra) # 80002a86 <argint>
    80002d3a:	87aa                	mv	a5,a0
    return -1;
    80002d3c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d3e:	0207c063          	bltz	a5,80002d5e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	c6e080e7          	jalr	-914(ra) # 800019b0 <myproc>
    80002d4a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d4c:	fdc42503          	lw	a0,-36(s0)
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	fba080e7          	jalr	-70(ra) # 80001d0a <growproc>
    80002d58:	00054863          	bltz	a0,80002d68 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d5c:	8526                	mv	a0,s1
}
    80002d5e:	70a2                	ld	ra,40(sp)
    80002d60:	7402                	ld	s0,32(sp)
    80002d62:	64e2                	ld	s1,24(sp)
    80002d64:	6145                	addi	sp,sp,48
    80002d66:	8082                	ret
    return -1;
    80002d68:	557d                	li	a0,-1
    80002d6a:	bfd5                	j	80002d5e <sys_sbrk+0x3c>

0000000080002d6c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d6c:	7139                	addi	sp,sp,-64
    80002d6e:	fc06                	sd	ra,56(sp)
    80002d70:	f822                	sd	s0,48(sp)
    80002d72:	f426                	sd	s1,40(sp)
    80002d74:	f04a                	sd	s2,32(sp)
    80002d76:	ec4e                	sd	s3,24(sp)
    80002d78:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d7a:	fcc40593          	addi	a1,s0,-52
    80002d7e:	4501                	li	a0,0
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	d06080e7          	jalr	-762(ra) # 80002a86 <argint>
    return -1;
    80002d88:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d8a:	06054563          	bltz	a0,80002df4 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d8e:	00014517          	auipc	a0,0x14
    80002d92:	54250513          	addi	a0,a0,1346 # 800172d0 <tickslock>
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	e4e080e7          	jalr	-434(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d9e:	00006917          	auipc	s2,0x6
    80002da2:	29292903          	lw	s2,658(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002da6:	fcc42783          	lw	a5,-52(s0)
    80002daa:	cf85                	beqz	a5,80002de2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dac:	00014997          	auipc	s3,0x14
    80002db0:	52498993          	addi	s3,s3,1316 # 800172d0 <tickslock>
    80002db4:	00006497          	auipc	s1,0x6
    80002db8:	27c48493          	addi	s1,s1,636 # 80009030 <ticks>
    if(myproc()->killed){
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	bf4080e7          	jalr	-1036(ra) # 800019b0 <myproc>
    80002dc4:	551c                	lw	a5,40(a0)
    80002dc6:	ef9d                	bnez	a5,80002e04 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dc8:	85ce                	mv	a1,s3
    80002dca:	8526                	mv	a0,s1
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	2a8080e7          	jalr	680(ra) # 80002074 <sleep>
  while(ticks - ticks0 < n){
    80002dd4:	409c                	lw	a5,0(s1)
    80002dd6:	412787bb          	subw	a5,a5,s2
    80002dda:	fcc42703          	lw	a4,-52(s0)
    80002dde:	fce7efe3          	bltu	a5,a4,80002dbc <sys_sleep+0x50>
  }
  release(&tickslock);
    80002de2:	00014517          	auipc	a0,0x14
    80002de6:	4ee50513          	addi	a0,a0,1262 # 800172d0 <tickslock>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	eae080e7          	jalr	-338(ra) # 80000c98 <release>
  return 0;
    80002df2:	4781                	li	a5,0
}
    80002df4:	853e                	mv	a0,a5
    80002df6:	70e2                	ld	ra,56(sp)
    80002df8:	7442                	ld	s0,48(sp)
    80002dfa:	74a2                	ld	s1,40(sp)
    80002dfc:	7902                	ld	s2,32(sp)
    80002dfe:	69e2                	ld	s3,24(sp)
    80002e00:	6121                	addi	sp,sp,64
    80002e02:	8082                	ret
      release(&tickslock);
    80002e04:	00014517          	auipc	a0,0x14
    80002e08:	4cc50513          	addi	a0,a0,1228 # 800172d0 <tickslock>
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	e8c080e7          	jalr	-372(ra) # 80000c98 <release>
      return -1;
    80002e14:	57fd                	li	a5,-1
    80002e16:	bff9                	j	80002df4 <sys_sleep+0x88>

0000000080002e18 <sys_kill>:

uint64
sys_kill(void)
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e20:	fec40593          	addi	a1,s0,-20
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	c60080e7          	jalr	-928(ra) # 80002a86 <argint>
    80002e2e:	87aa                	mv	a5,a0
    return -1;
    80002e30:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e32:	0007c863          	bltz	a5,80002e42 <sys_kill+0x2a>
  return kill(pid);
    80002e36:	fec42503          	lw	a0,-20(s0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	56c080e7          	jalr	1388(ra) # 800023a6 <kill>
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	6105                	addi	sp,sp,32
    80002e48:	8082                	ret

0000000080002e4a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	e426                	sd	s1,8(sp)
    80002e52:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e54:	00014517          	auipc	a0,0x14
    80002e58:	47c50513          	addi	a0,a0,1148 # 800172d0 <tickslock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	d88080e7          	jalr	-632(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e64:	00006497          	auipc	s1,0x6
    80002e68:	1cc4a483          	lw	s1,460(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e6c:	00014517          	auipc	a0,0x14
    80002e70:	46450513          	addi	a0,a0,1124 # 800172d0 <tickslock>
    80002e74:	ffffe097          	auipc	ra,0xffffe
    80002e78:	e24080e7          	jalr	-476(ra) # 80000c98 <release>
  return xticks;
}
    80002e7c:	02049513          	slli	a0,s1,0x20
    80002e80:	9101                	srli	a0,a0,0x20
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    80002e8c:	1101                	addi	sp,sp,-32
    80002e8e:	ec06                	sd	ra,24(sp)
    80002e90:	e822                	sd	s0,16(sp)
    80002e92:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    80002e94:	fec40593          	addi	a1,s0,-20
    80002e98:	4501                	li	a0,0
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	bec080e7          	jalr	-1044(ra) # 80002a86 <argint>
  trace(n);
    80002ea2:	fec42503          	lw	a0,-20(s0)
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	6cc080e7          	jalr	1740(ra) # 80002572 <trace>
  return 0; // if the syscall is successful, return 0
}
    80002eae:	4501                	li	a0,0
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	6105                	addi	sp,sp,32
    80002eb6:	8082                	ret

0000000080002eb8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eb8:	7179                	addi	sp,sp,-48
    80002eba:	f406                	sd	ra,40(sp)
    80002ebc:	f022                	sd	s0,32(sp)
    80002ebe:	ec26                	sd	s1,24(sp)
    80002ec0:	e84a                	sd	s2,16(sp)
    80002ec2:	e44e                	sd	s3,8(sp)
    80002ec4:	e052                	sd	s4,0(sp)
    80002ec6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ec8:	00005597          	auipc	a1,0x5
    80002ecc:	71058593          	addi	a1,a1,1808 # 800085d8 <syscalls+0xb8>
    80002ed0:	00014517          	auipc	a0,0x14
    80002ed4:	41850513          	addi	a0,a0,1048 # 800172e8 <bcache>
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	c7c080e7          	jalr	-900(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ee0:	0001c797          	auipc	a5,0x1c
    80002ee4:	40878793          	addi	a5,a5,1032 # 8001f2e8 <bcache+0x8000>
    80002ee8:	0001c717          	auipc	a4,0x1c
    80002eec:	66870713          	addi	a4,a4,1640 # 8001f550 <bcache+0x8268>
    80002ef0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ef4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ef8:	00014497          	auipc	s1,0x14
    80002efc:	40848493          	addi	s1,s1,1032 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002f00:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f02:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f04:	00005a17          	auipc	s4,0x5
    80002f08:	6dca0a13          	addi	s4,s4,1756 # 800085e0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f0c:	2b893783          	ld	a5,696(s2)
    80002f10:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f12:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f16:	85d2                	mv	a1,s4
    80002f18:	01048513          	addi	a0,s1,16
    80002f1c:	00001097          	auipc	ra,0x1
    80002f20:	4bc080e7          	jalr	1212(ra) # 800043d8 <initsleeplock>
    bcache.head.next->prev = b;
    80002f24:	2b893783          	ld	a5,696(s2)
    80002f28:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f2a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f2e:	45848493          	addi	s1,s1,1112
    80002f32:	fd349de3          	bne	s1,s3,80002f0c <binit+0x54>
  }
}
    80002f36:	70a2                	ld	ra,40(sp)
    80002f38:	7402                	ld	s0,32(sp)
    80002f3a:	64e2                	ld	s1,24(sp)
    80002f3c:	6942                	ld	s2,16(sp)
    80002f3e:	69a2                	ld	s3,8(sp)
    80002f40:	6a02                	ld	s4,0(sp)
    80002f42:	6145                	addi	sp,sp,48
    80002f44:	8082                	ret

0000000080002f46 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f46:	7179                	addi	sp,sp,-48
    80002f48:	f406                	sd	ra,40(sp)
    80002f4a:	f022                	sd	s0,32(sp)
    80002f4c:	ec26                	sd	s1,24(sp)
    80002f4e:	e84a                	sd	s2,16(sp)
    80002f50:	e44e                	sd	s3,8(sp)
    80002f52:	1800                	addi	s0,sp,48
    80002f54:	89aa                	mv	s3,a0
    80002f56:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f58:	00014517          	auipc	a0,0x14
    80002f5c:	39050513          	addi	a0,a0,912 # 800172e8 <bcache>
    80002f60:	ffffe097          	auipc	ra,0xffffe
    80002f64:	c84080e7          	jalr	-892(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f68:	0001c497          	auipc	s1,0x1c
    80002f6c:	6384b483          	ld	s1,1592(s1) # 8001f5a0 <bcache+0x82b8>
    80002f70:	0001c797          	auipc	a5,0x1c
    80002f74:	5e078793          	addi	a5,a5,1504 # 8001f550 <bcache+0x8268>
    80002f78:	02f48f63          	beq	s1,a5,80002fb6 <bread+0x70>
    80002f7c:	873e                	mv	a4,a5
    80002f7e:	a021                	j	80002f86 <bread+0x40>
    80002f80:	68a4                	ld	s1,80(s1)
    80002f82:	02e48a63          	beq	s1,a4,80002fb6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f86:	449c                	lw	a5,8(s1)
    80002f88:	ff379ce3          	bne	a5,s3,80002f80 <bread+0x3a>
    80002f8c:	44dc                	lw	a5,12(s1)
    80002f8e:	ff2799e3          	bne	a5,s2,80002f80 <bread+0x3a>
      b->refcnt++;
    80002f92:	40bc                	lw	a5,64(s1)
    80002f94:	2785                	addiw	a5,a5,1
    80002f96:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f98:	00014517          	auipc	a0,0x14
    80002f9c:	35050513          	addi	a0,a0,848 # 800172e8 <bcache>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fa8:	01048513          	addi	a0,s1,16
    80002fac:	00001097          	auipc	ra,0x1
    80002fb0:	466080e7          	jalr	1126(ra) # 80004412 <acquiresleep>
      return b;
    80002fb4:	a8b9                	j	80003012 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fb6:	0001c497          	auipc	s1,0x1c
    80002fba:	5e24b483          	ld	s1,1506(s1) # 8001f598 <bcache+0x82b0>
    80002fbe:	0001c797          	auipc	a5,0x1c
    80002fc2:	59278793          	addi	a5,a5,1426 # 8001f550 <bcache+0x8268>
    80002fc6:	00f48863          	beq	s1,a5,80002fd6 <bread+0x90>
    80002fca:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fcc:	40bc                	lw	a5,64(s1)
    80002fce:	cf81                	beqz	a5,80002fe6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd0:	64a4                	ld	s1,72(s1)
    80002fd2:	fee49de3          	bne	s1,a4,80002fcc <bread+0x86>
  panic("bget: no buffers");
    80002fd6:	00005517          	auipc	a0,0x5
    80002fda:	61250513          	addi	a0,a0,1554 # 800085e8 <syscalls+0xc8>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	560080e7          	jalr	1376(ra) # 8000053e <panic>
      b->dev = dev;
    80002fe6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fea:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fee:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ff2:	4785                	li	a5,1
    80002ff4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ff6:	00014517          	auipc	a0,0x14
    80002ffa:	2f250513          	addi	a0,a0,754 # 800172e8 <bcache>
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	c9a080e7          	jalr	-870(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003006:	01048513          	addi	a0,s1,16
    8000300a:	00001097          	auipc	ra,0x1
    8000300e:	408080e7          	jalr	1032(ra) # 80004412 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003012:	409c                	lw	a5,0(s1)
    80003014:	cb89                	beqz	a5,80003026 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003016:	8526                	mv	a0,s1
    80003018:	70a2                	ld	ra,40(sp)
    8000301a:	7402                	ld	s0,32(sp)
    8000301c:	64e2                	ld	s1,24(sp)
    8000301e:	6942                	ld	s2,16(sp)
    80003020:	69a2                	ld	s3,8(sp)
    80003022:	6145                	addi	sp,sp,48
    80003024:	8082                	ret
    virtio_disk_rw(b, 0);
    80003026:	4581                	li	a1,0
    80003028:	8526                	mv	a0,s1
    8000302a:	00003097          	auipc	ra,0x3
    8000302e:	f0c080e7          	jalr	-244(ra) # 80005f36 <virtio_disk_rw>
    b->valid = 1;
    80003032:	4785                	li	a5,1
    80003034:	c09c                	sw	a5,0(s1)
  return b;
    80003036:	b7c5                	j	80003016 <bread+0xd0>

0000000080003038 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	1000                	addi	s0,sp,32
    80003042:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003044:	0541                	addi	a0,a0,16
    80003046:	00001097          	auipc	ra,0x1
    8000304a:	466080e7          	jalr	1126(ra) # 800044ac <holdingsleep>
    8000304e:	cd01                	beqz	a0,80003066 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003050:	4585                	li	a1,1
    80003052:	8526                	mv	a0,s1
    80003054:	00003097          	auipc	ra,0x3
    80003058:	ee2080e7          	jalr	-286(ra) # 80005f36 <virtio_disk_rw>
}
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret
    panic("bwrite");
    80003066:	00005517          	auipc	a0,0x5
    8000306a:	59a50513          	addi	a0,a0,1434 # 80008600 <syscalls+0xe0>
    8000306e:	ffffd097          	auipc	ra,0xffffd
    80003072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>

0000000080003076 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	e426                	sd	s1,8(sp)
    8000307e:	e04a                	sd	s2,0(sp)
    80003080:	1000                	addi	s0,sp,32
    80003082:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003084:	01050913          	addi	s2,a0,16
    80003088:	854a                	mv	a0,s2
    8000308a:	00001097          	auipc	ra,0x1
    8000308e:	422080e7          	jalr	1058(ra) # 800044ac <holdingsleep>
    80003092:	c92d                	beqz	a0,80003104 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003094:	854a                	mv	a0,s2
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	3d2080e7          	jalr	978(ra) # 80004468 <releasesleep>

  acquire(&bcache.lock);
    8000309e:	00014517          	auipc	a0,0x14
    800030a2:	24a50513          	addi	a0,a0,586 # 800172e8 <bcache>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	b3e080e7          	jalr	-1218(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030ae:	40bc                	lw	a5,64(s1)
    800030b0:	37fd                	addiw	a5,a5,-1
    800030b2:	0007871b          	sext.w	a4,a5
    800030b6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030b8:	eb05                	bnez	a4,800030e8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ba:	68bc                	ld	a5,80(s1)
    800030bc:	64b8                	ld	a4,72(s1)
    800030be:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030c0:	64bc                	ld	a5,72(s1)
    800030c2:	68b8                	ld	a4,80(s1)
    800030c4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030c6:	0001c797          	auipc	a5,0x1c
    800030ca:	22278793          	addi	a5,a5,546 # 8001f2e8 <bcache+0x8000>
    800030ce:	2b87b703          	ld	a4,696(a5)
    800030d2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030d4:	0001c717          	auipc	a4,0x1c
    800030d8:	47c70713          	addi	a4,a4,1148 # 8001f550 <bcache+0x8268>
    800030dc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030de:	2b87b703          	ld	a4,696(a5)
    800030e2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030e4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030e8:	00014517          	auipc	a0,0x14
    800030ec:	20050513          	addi	a0,a0,512 # 800172e8 <bcache>
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	ba8080e7          	jalr	-1112(ra) # 80000c98 <release>
}
    800030f8:	60e2                	ld	ra,24(sp)
    800030fa:	6442                	ld	s0,16(sp)
    800030fc:	64a2                	ld	s1,8(sp)
    800030fe:	6902                	ld	s2,0(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret
    panic("brelse");
    80003104:	00005517          	auipc	a0,0x5
    80003108:	50450513          	addi	a0,a0,1284 # 80008608 <syscalls+0xe8>
    8000310c:	ffffd097          	auipc	ra,0xffffd
    80003110:	432080e7          	jalr	1074(ra) # 8000053e <panic>

0000000080003114 <bpin>:

void
bpin(struct buf *b) {
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	1000                	addi	s0,sp,32
    8000311e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	1c850513          	addi	a0,a0,456 # 800172e8 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	abc080e7          	jalr	-1348(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003130:	40bc                	lw	a5,64(s1)
    80003132:	2785                	addiw	a5,a5,1
    80003134:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	1b250513          	addi	a0,a0,434 # 800172e8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b5a080e7          	jalr	-1190(ra) # 80000c98 <release>
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6105                	addi	sp,sp,32
    8000314e:	8082                	ret

0000000080003150 <bunpin>:

void
bunpin(struct buf *b) {
    80003150:	1101                	addi	sp,sp,-32
    80003152:	ec06                	sd	ra,24(sp)
    80003154:	e822                	sd	s0,16(sp)
    80003156:	e426                	sd	s1,8(sp)
    80003158:	1000                	addi	s0,sp,32
    8000315a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	18c50513          	addi	a0,a0,396 # 800172e8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	a80080e7          	jalr	-1408(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000316c:	40bc                	lw	a5,64(s1)
    8000316e:	37fd                	addiw	a5,a5,-1
    80003170:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	17650513          	addi	a0,a0,374 # 800172e8 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	b1e080e7          	jalr	-1250(ra) # 80000c98 <release>
}
    80003182:	60e2                	ld	ra,24(sp)
    80003184:	6442                	ld	s0,16(sp)
    80003186:	64a2                	ld	s1,8(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000318c:	1101                	addi	sp,sp,-32
    8000318e:	ec06                	sd	ra,24(sp)
    80003190:	e822                	sd	s0,16(sp)
    80003192:	e426                	sd	s1,8(sp)
    80003194:	e04a                	sd	s2,0(sp)
    80003196:	1000                	addi	s0,sp,32
    80003198:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000319a:	00d5d59b          	srliw	a1,a1,0xd
    8000319e:	0001d797          	auipc	a5,0x1d
    800031a2:	8267a783          	lw	a5,-2010(a5) # 8001f9c4 <sb+0x1c>
    800031a6:	9dbd                	addw	a1,a1,a5
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	d9e080e7          	jalr	-610(ra) # 80002f46 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031b0:	0074f713          	andi	a4,s1,7
    800031b4:	4785                	li	a5,1
    800031b6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ba:	14ce                	slli	s1,s1,0x33
    800031bc:	90d9                	srli	s1,s1,0x36
    800031be:	00950733          	add	a4,a0,s1
    800031c2:	05874703          	lbu	a4,88(a4)
    800031c6:	00e7f6b3          	and	a3,a5,a4
    800031ca:	c69d                	beqz	a3,800031f8 <bfree+0x6c>
    800031cc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031ce:	94aa                	add	s1,s1,a0
    800031d0:	fff7c793          	not	a5,a5
    800031d4:	8ff9                	and	a5,a5,a4
    800031d6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031da:	00001097          	auipc	ra,0x1
    800031de:	118080e7          	jalr	280(ra) # 800042f2 <log_write>
  brelse(bp);
    800031e2:	854a                	mv	a0,s2
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e92080e7          	jalr	-366(ra) # 80003076 <brelse>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6902                	ld	s2,0(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret
    panic("freeing free block");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	41850513          	addi	a0,a0,1048 # 80008610 <syscalls+0xf0>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	33e080e7          	jalr	830(ra) # 8000053e <panic>

0000000080003208 <balloc>:
{
    80003208:	711d                	addi	sp,sp,-96
    8000320a:	ec86                	sd	ra,88(sp)
    8000320c:	e8a2                	sd	s0,80(sp)
    8000320e:	e4a6                	sd	s1,72(sp)
    80003210:	e0ca                	sd	s2,64(sp)
    80003212:	fc4e                	sd	s3,56(sp)
    80003214:	f852                	sd	s4,48(sp)
    80003216:	f456                	sd	s5,40(sp)
    80003218:	f05a                	sd	s6,32(sp)
    8000321a:	ec5e                	sd	s7,24(sp)
    8000321c:	e862                	sd	s8,16(sp)
    8000321e:	e466                	sd	s9,8(sp)
    80003220:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003222:	0001c797          	auipc	a5,0x1c
    80003226:	78a7a783          	lw	a5,1930(a5) # 8001f9ac <sb+0x4>
    8000322a:	cbd1                	beqz	a5,800032be <balloc+0xb6>
    8000322c:	8baa                	mv	s7,a0
    8000322e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003230:	0001cb17          	auipc	s6,0x1c
    80003234:	778b0b13          	addi	s6,s6,1912 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003238:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000323a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000323c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000323e:	6c89                	lui	s9,0x2
    80003240:	a831                	j	8000325c <balloc+0x54>
    brelse(bp);
    80003242:	854a                	mv	a0,s2
    80003244:	00000097          	auipc	ra,0x0
    80003248:	e32080e7          	jalr	-462(ra) # 80003076 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000324c:	015c87bb          	addw	a5,s9,s5
    80003250:	00078a9b          	sext.w	s5,a5
    80003254:	004b2703          	lw	a4,4(s6)
    80003258:	06eaf363          	bgeu	s5,a4,800032be <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000325c:	41fad79b          	sraiw	a5,s5,0x1f
    80003260:	0137d79b          	srliw	a5,a5,0x13
    80003264:	015787bb          	addw	a5,a5,s5
    80003268:	40d7d79b          	sraiw	a5,a5,0xd
    8000326c:	01cb2583          	lw	a1,28(s6)
    80003270:	9dbd                	addw	a1,a1,a5
    80003272:	855e                	mv	a0,s7
    80003274:	00000097          	auipc	ra,0x0
    80003278:	cd2080e7          	jalr	-814(ra) # 80002f46 <bread>
    8000327c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000327e:	004b2503          	lw	a0,4(s6)
    80003282:	000a849b          	sext.w	s1,s5
    80003286:	8662                	mv	a2,s8
    80003288:	faa4fde3          	bgeu	s1,a0,80003242 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000328c:	41f6579b          	sraiw	a5,a2,0x1f
    80003290:	01d7d69b          	srliw	a3,a5,0x1d
    80003294:	00c6873b          	addw	a4,a3,a2
    80003298:	00777793          	andi	a5,a4,7
    8000329c:	9f95                	subw	a5,a5,a3
    8000329e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032a2:	4037571b          	sraiw	a4,a4,0x3
    800032a6:	00e906b3          	add	a3,s2,a4
    800032aa:	0586c683          	lbu	a3,88(a3)
    800032ae:	00d7f5b3          	and	a1,a5,a3
    800032b2:	cd91                	beqz	a1,800032ce <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b4:	2605                	addiw	a2,a2,1
    800032b6:	2485                	addiw	s1,s1,1
    800032b8:	fd4618e3          	bne	a2,s4,80003288 <balloc+0x80>
    800032bc:	b759                	j	80003242 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032be:	00005517          	auipc	a0,0x5
    800032c2:	36a50513          	addi	a0,a0,874 # 80008628 <syscalls+0x108>
    800032c6:	ffffd097          	auipc	ra,0xffffd
    800032ca:	278080e7          	jalr	632(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032ce:	974a                	add	a4,a4,s2
    800032d0:	8fd5                	or	a5,a5,a3
    800032d2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00001097          	auipc	ra,0x1
    800032dc:	01a080e7          	jalr	26(ra) # 800042f2 <log_write>
        brelse(bp);
    800032e0:	854a                	mv	a0,s2
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	d94080e7          	jalr	-620(ra) # 80003076 <brelse>
  bp = bread(dev, bno);
    800032ea:	85a6                	mv	a1,s1
    800032ec:	855e                	mv	a0,s7
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	c58080e7          	jalr	-936(ra) # 80002f46 <bread>
    800032f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032f8:	40000613          	li	a2,1024
    800032fc:	4581                	li	a1,0
    800032fe:	05850513          	addi	a0,a0,88
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	9de080e7          	jalr	-1570(ra) # 80000ce0 <memset>
  log_write(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	fe6080e7          	jalr	-26(ra) # 800042f2 <log_write>
  brelse(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	d60080e7          	jalr	-672(ra) # 80003076 <brelse>
}
    8000331e:	8526                	mv	a0,s1
    80003320:	60e6                	ld	ra,88(sp)
    80003322:	6446                	ld	s0,80(sp)
    80003324:	64a6                	ld	s1,72(sp)
    80003326:	6906                	ld	s2,64(sp)
    80003328:	79e2                	ld	s3,56(sp)
    8000332a:	7a42                	ld	s4,48(sp)
    8000332c:	7aa2                	ld	s5,40(sp)
    8000332e:	7b02                	ld	s6,32(sp)
    80003330:	6be2                	ld	s7,24(sp)
    80003332:	6c42                	ld	s8,16(sp)
    80003334:	6ca2                	ld	s9,8(sp)
    80003336:	6125                	addi	sp,sp,96
    80003338:	8082                	ret

000000008000333a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000333a:	7179                	addi	sp,sp,-48
    8000333c:	f406                	sd	ra,40(sp)
    8000333e:	f022                	sd	s0,32(sp)
    80003340:	ec26                	sd	s1,24(sp)
    80003342:	e84a                	sd	s2,16(sp)
    80003344:	e44e                	sd	s3,8(sp)
    80003346:	e052                	sd	s4,0(sp)
    80003348:	1800                	addi	s0,sp,48
    8000334a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000334c:	47ad                	li	a5,11
    8000334e:	04b7fe63          	bgeu	a5,a1,800033aa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003352:	ff45849b          	addiw	s1,a1,-12
    80003356:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000335a:	0ff00793          	li	a5,255
    8000335e:	0ae7e363          	bltu	a5,a4,80003404 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003362:	08052583          	lw	a1,128(a0)
    80003366:	c5ad                	beqz	a1,800033d0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003368:	00092503          	lw	a0,0(s2)
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	bda080e7          	jalr	-1062(ra) # 80002f46 <bread>
    80003374:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003376:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000337a:	02049593          	slli	a1,s1,0x20
    8000337e:	9181                	srli	a1,a1,0x20
    80003380:	058a                	slli	a1,a1,0x2
    80003382:	00b784b3          	add	s1,a5,a1
    80003386:	0004a983          	lw	s3,0(s1)
    8000338a:	04098d63          	beqz	s3,800033e4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000338e:	8552                	mv	a0,s4
    80003390:	00000097          	auipc	ra,0x0
    80003394:	ce6080e7          	jalr	-794(ra) # 80003076 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003398:	854e                	mv	a0,s3
    8000339a:	70a2                	ld	ra,40(sp)
    8000339c:	7402                	ld	s0,32(sp)
    8000339e:	64e2                	ld	s1,24(sp)
    800033a0:	6942                	ld	s2,16(sp)
    800033a2:	69a2                	ld	s3,8(sp)
    800033a4:	6a02                	ld	s4,0(sp)
    800033a6:	6145                	addi	sp,sp,48
    800033a8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033aa:	02059493          	slli	s1,a1,0x20
    800033ae:	9081                	srli	s1,s1,0x20
    800033b0:	048a                	slli	s1,s1,0x2
    800033b2:	94aa                	add	s1,s1,a0
    800033b4:	0504a983          	lw	s3,80(s1)
    800033b8:	fe0990e3          	bnez	s3,80003398 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033bc:	4108                	lw	a0,0(a0)
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	e4a080e7          	jalr	-438(ra) # 80003208 <balloc>
    800033c6:	0005099b          	sext.w	s3,a0
    800033ca:	0534a823          	sw	s3,80(s1)
    800033ce:	b7e9                	j	80003398 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033d0:	4108                	lw	a0,0(a0)
    800033d2:	00000097          	auipc	ra,0x0
    800033d6:	e36080e7          	jalr	-458(ra) # 80003208 <balloc>
    800033da:	0005059b          	sext.w	a1,a0
    800033de:	08b92023          	sw	a1,128(s2)
    800033e2:	b759                	j	80003368 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033e4:	00092503          	lw	a0,0(s2)
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	e20080e7          	jalr	-480(ra) # 80003208 <balloc>
    800033f0:	0005099b          	sext.w	s3,a0
    800033f4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033f8:	8552                	mv	a0,s4
    800033fa:	00001097          	auipc	ra,0x1
    800033fe:	ef8080e7          	jalr	-264(ra) # 800042f2 <log_write>
    80003402:	b771                	j	8000338e <bmap+0x54>
  panic("bmap: out of range");
    80003404:	00005517          	auipc	a0,0x5
    80003408:	23c50513          	addi	a0,a0,572 # 80008640 <syscalls+0x120>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	132080e7          	jalr	306(ra) # 8000053e <panic>

0000000080003414 <iget>:
{
    80003414:	7179                	addi	sp,sp,-48
    80003416:	f406                	sd	ra,40(sp)
    80003418:	f022                	sd	s0,32(sp)
    8000341a:	ec26                	sd	s1,24(sp)
    8000341c:	e84a                	sd	s2,16(sp)
    8000341e:	e44e                	sd	s3,8(sp)
    80003420:	e052                	sd	s4,0(sp)
    80003422:	1800                	addi	s0,sp,48
    80003424:	89aa                	mv	s3,a0
    80003426:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003428:	0001c517          	auipc	a0,0x1c
    8000342c:	5a050513          	addi	a0,a0,1440 # 8001f9c8 <itable>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
  empty = 0;
    80003438:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000343a:	0001c497          	auipc	s1,0x1c
    8000343e:	5a648493          	addi	s1,s1,1446 # 8001f9e0 <itable+0x18>
    80003442:	0001e697          	auipc	a3,0x1e
    80003446:	02e68693          	addi	a3,a3,46 # 80021470 <log>
    8000344a:	a039                	j	80003458 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344c:	02090b63          	beqz	s2,80003482 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003450:	08848493          	addi	s1,s1,136
    80003454:	02d48a63          	beq	s1,a3,80003488 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003458:	449c                	lw	a5,8(s1)
    8000345a:	fef059e3          	blez	a5,8000344c <iget+0x38>
    8000345e:	4098                	lw	a4,0(s1)
    80003460:	ff3716e3          	bne	a4,s3,8000344c <iget+0x38>
    80003464:	40d8                	lw	a4,4(s1)
    80003466:	ff4713e3          	bne	a4,s4,8000344c <iget+0x38>
      ip->ref++;
    8000346a:	2785                	addiw	a5,a5,1
    8000346c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000346e:	0001c517          	auipc	a0,0x1c
    80003472:	55a50513          	addi	a0,a0,1370 # 8001f9c8 <itable>
    80003476:	ffffe097          	auipc	ra,0xffffe
    8000347a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
      return ip;
    8000347e:	8926                	mv	s2,s1
    80003480:	a03d                	j	800034ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003482:	f7f9                	bnez	a5,80003450 <iget+0x3c>
    80003484:	8926                	mv	s2,s1
    80003486:	b7e9                	j	80003450 <iget+0x3c>
  if(empty == 0)
    80003488:	02090c63          	beqz	s2,800034c0 <iget+0xac>
  ip->dev = dev;
    8000348c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003490:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003494:	4785                	li	a5,1
    80003496:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000349a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000349e:	0001c517          	auipc	a0,0x1c
    800034a2:	52a50513          	addi	a0,a0,1322 # 8001f9c8 <itable>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	7f2080e7          	jalr	2034(ra) # 80000c98 <release>
}
    800034ae:	854a                	mv	a0,s2
    800034b0:	70a2                	ld	ra,40(sp)
    800034b2:	7402                	ld	s0,32(sp)
    800034b4:	64e2                	ld	s1,24(sp)
    800034b6:	6942                	ld	s2,16(sp)
    800034b8:	69a2                	ld	s3,8(sp)
    800034ba:	6a02                	ld	s4,0(sp)
    800034bc:	6145                	addi	sp,sp,48
    800034be:	8082                	ret
    panic("iget: no inodes");
    800034c0:	00005517          	auipc	a0,0x5
    800034c4:	19850513          	addi	a0,a0,408 # 80008658 <syscalls+0x138>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	076080e7          	jalr	118(ra) # 8000053e <panic>

00000000800034d0 <fsinit>:
fsinit(int dev) {
    800034d0:	7179                	addi	sp,sp,-48
    800034d2:	f406                	sd	ra,40(sp)
    800034d4:	f022                	sd	s0,32(sp)
    800034d6:	ec26                	sd	s1,24(sp)
    800034d8:	e84a                	sd	s2,16(sp)
    800034da:	e44e                	sd	s3,8(sp)
    800034dc:	1800                	addi	s0,sp,48
    800034de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034e0:	4585                	li	a1,1
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	a64080e7          	jalr	-1436(ra) # 80002f46 <bread>
    800034ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ec:	0001c997          	auipc	s3,0x1c
    800034f0:	4bc98993          	addi	s3,s3,1212 # 8001f9a8 <sb>
    800034f4:	02000613          	li	a2,32
    800034f8:	05850593          	addi	a1,a0,88
    800034fc:	854e                	mv	a0,s3
    800034fe:	ffffe097          	auipc	ra,0xffffe
    80003502:	842080e7          	jalr	-1982(ra) # 80000d40 <memmove>
  brelse(bp);
    80003506:	8526                	mv	a0,s1
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	b6e080e7          	jalr	-1170(ra) # 80003076 <brelse>
  if(sb.magic != FSMAGIC)
    80003510:	0009a703          	lw	a4,0(s3)
    80003514:	102037b7          	lui	a5,0x10203
    80003518:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000351c:	02f71263          	bne	a4,a5,80003540 <fsinit+0x70>
  initlog(dev, &sb);
    80003520:	0001c597          	auipc	a1,0x1c
    80003524:	48858593          	addi	a1,a1,1160 # 8001f9a8 <sb>
    80003528:	854a                	mv	a0,s2
    8000352a:	00001097          	auipc	ra,0x1
    8000352e:	b4c080e7          	jalr	-1204(ra) # 80004076 <initlog>
}
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    panic("invalid file system");
    80003540:	00005517          	auipc	a0,0x5
    80003544:	12850513          	addi	a0,a0,296 # 80008668 <syscalls+0x148>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	ff6080e7          	jalr	-10(ra) # 8000053e <panic>

0000000080003550 <iinit>:
{
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	e84a                	sd	s2,16(sp)
    8000355a:	e44e                	sd	s3,8(sp)
    8000355c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000355e:	00005597          	auipc	a1,0x5
    80003562:	12258593          	addi	a1,a1,290 # 80008680 <syscalls+0x160>
    80003566:	0001c517          	auipc	a0,0x1c
    8000356a:	46250513          	addi	a0,a0,1122 # 8001f9c8 <itable>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	5e6080e7          	jalr	1510(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003576:	0001c497          	auipc	s1,0x1c
    8000357a:	47a48493          	addi	s1,s1,1146 # 8001f9f0 <itable+0x28>
    8000357e:	0001e997          	auipc	s3,0x1e
    80003582:	f0298993          	addi	s3,s3,-254 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003586:	00005917          	auipc	s2,0x5
    8000358a:	10290913          	addi	s2,s2,258 # 80008688 <syscalls+0x168>
    8000358e:	85ca                	mv	a1,s2
    80003590:	8526                	mv	a0,s1
    80003592:	00001097          	auipc	ra,0x1
    80003596:	e46080e7          	jalr	-442(ra) # 800043d8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000359a:	08848493          	addi	s1,s1,136
    8000359e:	ff3498e3          	bne	s1,s3,8000358e <iinit+0x3e>
}
    800035a2:	70a2                	ld	ra,40(sp)
    800035a4:	7402                	ld	s0,32(sp)
    800035a6:	64e2                	ld	s1,24(sp)
    800035a8:	6942                	ld	s2,16(sp)
    800035aa:	69a2                	ld	s3,8(sp)
    800035ac:	6145                	addi	sp,sp,48
    800035ae:	8082                	ret

00000000800035b0 <ialloc>:
{
    800035b0:	715d                	addi	sp,sp,-80
    800035b2:	e486                	sd	ra,72(sp)
    800035b4:	e0a2                	sd	s0,64(sp)
    800035b6:	fc26                	sd	s1,56(sp)
    800035b8:	f84a                	sd	s2,48(sp)
    800035ba:	f44e                	sd	s3,40(sp)
    800035bc:	f052                	sd	s4,32(sp)
    800035be:	ec56                	sd	s5,24(sp)
    800035c0:	e85a                	sd	s6,16(sp)
    800035c2:	e45e                	sd	s7,8(sp)
    800035c4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035c6:	0001c717          	auipc	a4,0x1c
    800035ca:	3ee72703          	lw	a4,1006(a4) # 8001f9b4 <sb+0xc>
    800035ce:	4785                	li	a5,1
    800035d0:	04e7fa63          	bgeu	a5,a4,80003624 <ialloc+0x74>
    800035d4:	8aaa                	mv	s5,a0
    800035d6:	8bae                	mv	s7,a1
    800035d8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035da:	0001ca17          	auipc	s4,0x1c
    800035de:	3cea0a13          	addi	s4,s4,974 # 8001f9a8 <sb>
    800035e2:	00048b1b          	sext.w	s6,s1
    800035e6:	0044d593          	srli	a1,s1,0x4
    800035ea:	018a2783          	lw	a5,24(s4)
    800035ee:	9dbd                	addw	a1,a1,a5
    800035f0:	8556                	mv	a0,s5
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	954080e7          	jalr	-1708(ra) # 80002f46 <bread>
    800035fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035fc:	05850993          	addi	s3,a0,88
    80003600:	00f4f793          	andi	a5,s1,15
    80003604:	079a                	slli	a5,a5,0x6
    80003606:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003608:	00099783          	lh	a5,0(s3)
    8000360c:	c785                	beqz	a5,80003634 <ialloc+0x84>
    brelse(bp);
    8000360e:	00000097          	auipc	ra,0x0
    80003612:	a68080e7          	jalr	-1432(ra) # 80003076 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003616:	0485                	addi	s1,s1,1
    80003618:	00ca2703          	lw	a4,12(s4)
    8000361c:	0004879b          	sext.w	a5,s1
    80003620:	fce7e1e3          	bltu	a5,a4,800035e2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	06c50513          	addi	a0,a0,108 # 80008690 <syscalls+0x170>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003634:	04000613          	li	a2,64
    80003638:	4581                	li	a1,0
    8000363a:	854e                	mv	a0,s3
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	6a4080e7          	jalr	1700(ra) # 80000ce0 <memset>
      dip->type = type;
    80003644:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003648:	854a                	mv	a0,s2
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	ca8080e7          	jalr	-856(ra) # 800042f2 <log_write>
      brelse(bp);
    80003652:	854a                	mv	a0,s2
    80003654:	00000097          	auipc	ra,0x0
    80003658:	a22080e7          	jalr	-1502(ra) # 80003076 <brelse>
      return iget(dev, inum);
    8000365c:	85da                	mv	a1,s6
    8000365e:	8556                	mv	a0,s5
    80003660:	00000097          	auipc	ra,0x0
    80003664:	db4080e7          	jalr	-588(ra) # 80003414 <iget>
}
    80003668:	60a6                	ld	ra,72(sp)
    8000366a:	6406                	ld	s0,64(sp)
    8000366c:	74e2                	ld	s1,56(sp)
    8000366e:	7942                	ld	s2,48(sp)
    80003670:	79a2                	ld	s3,40(sp)
    80003672:	7a02                	ld	s4,32(sp)
    80003674:	6ae2                	ld	s5,24(sp)
    80003676:	6b42                	ld	s6,16(sp)
    80003678:	6ba2                	ld	s7,8(sp)
    8000367a:	6161                	addi	sp,sp,80
    8000367c:	8082                	ret

000000008000367e <iupdate>:
{
    8000367e:	1101                	addi	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	e04a                	sd	s2,0(sp)
    80003688:	1000                	addi	s0,sp,32
    8000368a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368c:	415c                	lw	a5,4(a0)
    8000368e:	0047d79b          	srliw	a5,a5,0x4
    80003692:	0001c597          	auipc	a1,0x1c
    80003696:	32e5a583          	lw	a1,814(a1) # 8001f9c0 <sb+0x18>
    8000369a:	9dbd                	addw	a1,a1,a5
    8000369c:	4108                	lw	a0,0(a0)
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	8a8080e7          	jalr	-1880(ra) # 80002f46 <bread>
    800036a6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a8:	05850793          	addi	a5,a0,88
    800036ac:	40c8                	lw	a0,4(s1)
    800036ae:	893d                	andi	a0,a0,15
    800036b0:	051a                	slli	a0,a0,0x6
    800036b2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036b4:	04449703          	lh	a4,68(s1)
    800036b8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036bc:	04649703          	lh	a4,70(s1)
    800036c0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036c4:	04849703          	lh	a4,72(s1)
    800036c8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036cc:	04a49703          	lh	a4,74(s1)
    800036d0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036d4:	44f8                	lw	a4,76(s1)
    800036d6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036d8:	03400613          	li	a2,52
    800036dc:	05048593          	addi	a1,s1,80
    800036e0:	0531                	addi	a0,a0,12
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	65e080e7          	jalr	1630(ra) # 80000d40 <memmove>
  log_write(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00001097          	auipc	ra,0x1
    800036f0:	c06080e7          	jalr	-1018(ra) # 800042f2 <log_write>
  brelse(bp);
    800036f4:	854a                	mv	a0,s2
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	980080e7          	jalr	-1664(ra) # 80003076 <brelse>
}
    800036fe:	60e2                	ld	ra,24(sp)
    80003700:	6442                	ld	s0,16(sp)
    80003702:	64a2                	ld	s1,8(sp)
    80003704:	6902                	ld	s2,0(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <idup>:
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	1000                	addi	s0,sp,32
    80003714:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003716:	0001c517          	auipc	a0,0x1c
    8000371a:	2b250513          	addi	a0,a0,690 # 8001f9c8 <itable>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	4c6080e7          	jalr	1222(ra) # 80000be4 <acquire>
  ip->ref++;
    80003726:	449c                	lw	a5,8(s1)
    80003728:	2785                	addiw	a5,a5,1
    8000372a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000372c:	0001c517          	auipc	a0,0x1c
    80003730:	29c50513          	addi	a0,a0,668 # 8001f9c8 <itable>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	564080e7          	jalr	1380(ra) # 80000c98 <release>
}
    8000373c:	8526                	mv	a0,s1
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	64a2                	ld	s1,8(sp)
    80003744:	6105                	addi	sp,sp,32
    80003746:	8082                	ret

0000000080003748 <ilock>:
{
    80003748:	1101                	addi	sp,sp,-32
    8000374a:	ec06                	sd	ra,24(sp)
    8000374c:	e822                	sd	s0,16(sp)
    8000374e:	e426                	sd	s1,8(sp)
    80003750:	e04a                	sd	s2,0(sp)
    80003752:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003754:	c115                	beqz	a0,80003778 <ilock+0x30>
    80003756:	84aa                	mv	s1,a0
    80003758:	451c                	lw	a5,8(a0)
    8000375a:	00f05f63          	blez	a5,80003778 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000375e:	0541                	addi	a0,a0,16
    80003760:	00001097          	auipc	ra,0x1
    80003764:	cb2080e7          	jalr	-846(ra) # 80004412 <acquiresleep>
  if(ip->valid == 0){
    80003768:	40bc                	lw	a5,64(s1)
    8000376a:	cf99                	beqz	a5,80003788 <ilock+0x40>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret
    panic("ilock");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	f3050513          	addi	a0,a0,-208 # 800086a8 <syscalls+0x188>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dbe080e7          	jalr	-578(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003788:	40dc                	lw	a5,4(s1)
    8000378a:	0047d79b          	srliw	a5,a5,0x4
    8000378e:	0001c597          	auipc	a1,0x1c
    80003792:	2325a583          	lw	a1,562(a1) # 8001f9c0 <sb+0x18>
    80003796:	9dbd                	addw	a1,a1,a5
    80003798:	4088                	lw	a0,0(s1)
    8000379a:	fffff097          	auipc	ra,0xfffff
    8000379e:	7ac080e7          	jalr	1964(ra) # 80002f46 <bread>
    800037a2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a4:	05850593          	addi	a1,a0,88
    800037a8:	40dc                	lw	a5,4(s1)
    800037aa:	8bbd                	andi	a5,a5,15
    800037ac:	079a                	slli	a5,a5,0x6
    800037ae:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037b0:	00059783          	lh	a5,0(a1)
    800037b4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037b8:	00259783          	lh	a5,2(a1)
    800037bc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037c0:	00459783          	lh	a5,4(a1)
    800037c4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037c8:	00659783          	lh	a5,6(a1)
    800037cc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037d0:	459c                	lw	a5,8(a1)
    800037d2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037d4:	03400613          	li	a2,52
    800037d8:	05b1                	addi	a1,a1,12
    800037da:	05048513          	addi	a0,s1,80
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	562080e7          	jalr	1378(ra) # 80000d40 <memmove>
    brelse(bp);
    800037e6:	854a                	mv	a0,s2
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	88e080e7          	jalr	-1906(ra) # 80003076 <brelse>
    ip->valid = 1;
    800037f0:	4785                	li	a5,1
    800037f2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037f4:	04449783          	lh	a5,68(s1)
    800037f8:	fbb5                	bnez	a5,8000376c <ilock+0x24>
      panic("ilock: no type");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	eb650513          	addi	a0,a0,-330 # 800086b0 <syscalls+0x190>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>

000000008000380a <iunlock>:
{
    8000380a:	1101                	addi	sp,sp,-32
    8000380c:	ec06                	sd	ra,24(sp)
    8000380e:	e822                	sd	s0,16(sp)
    80003810:	e426                	sd	s1,8(sp)
    80003812:	e04a                	sd	s2,0(sp)
    80003814:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003816:	c905                	beqz	a0,80003846 <iunlock+0x3c>
    80003818:	84aa                	mv	s1,a0
    8000381a:	01050913          	addi	s2,a0,16
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	c8c080e7          	jalr	-884(ra) # 800044ac <holdingsleep>
    80003828:	cd19                	beqz	a0,80003846 <iunlock+0x3c>
    8000382a:	449c                	lw	a5,8(s1)
    8000382c:	00f05d63          	blez	a5,80003846 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003830:	854a                	mv	a0,s2
    80003832:	00001097          	auipc	ra,0x1
    80003836:	c36080e7          	jalr	-970(ra) # 80004468 <releasesleep>
}
    8000383a:	60e2                	ld	ra,24(sp)
    8000383c:	6442                	ld	s0,16(sp)
    8000383e:	64a2                	ld	s1,8(sp)
    80003840:	6902                	ld	s2,0(sp)
    80003842:	6105                	addi	sp,sp,32
    80003844:	8082                	ret
    panic("iunlock");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	e7a50513          	addi	a0,a0,-390 # 800086c0 <syscalls+0x1a0>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>

0000000080003856 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003856:	7179                	addi	sp,sp,-48
    80003858:	f406                	sd	ra,40(sp)
    8000385a:	f022                	sd	s0,32(sp)
    8000385c:	ec26                	sd	s1,24(sp)
    8000385e:	e84a                	sd	s2,16(sp)
    80003860:	e44e                	sd	s3,8(sp)
    80003862:	e052                	sd	s4,0(sp)
    80003864:	1800                	addi	s0,sp,48
    80003866:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003868:	05050493          	addi	s1,a0,80
    8000386c:	08050913          	addi	s2,a0,128
    80003870:	a021                	j	80003878 <itrunc+0x22>
    80003872:	0491                	addi	s1,s1,4
    80003874:	01248d63          	beq	s1,s2,8000388e <itrunc+0x38>
    if(ip->addrs[i]){
    80003878:	408c                	lw	a1,0(s1)
    8000387a:	dde5                	beqz	a1,80003872 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000387c:	0009a503          	lw	a0,0(s3)
    80003880:	00000097          	auipc	ra,0x0
    80003884:	90c080e7          	jalr	-1780(ra) # 8000318c <bfree>
      ip->addrs[i] = 0;
    80003888:	0004a023          	sw	zero,0(s1)
    8000388c:	b7dd                	j	80003872 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000388e:	0809a583          	lw	a1,128(s3)
    80003892:	e185                	bnez	a1,800038b2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003894:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003898:	854e                	mv	a0,s3
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	de4080e7          	jalr	-540(ra) # 8000367e <iupdate>
}
    800038a2:	70a2                	ld	ra,40(sp)
    800038a4:	7402                	ld	s0,32(sp)
    800038a6:	64e2                	ld	s1,24(sp)
    800038a8:	6942                	ld	s2,16(sp)
    800038aa:	69a2                	ld	s3,8(sp)
    800038ac:	6a02                	ld	s4,0(sp)
    800038ae:	6145                	addi	sp,sp,48
    800038b0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038b2:	0009a503          	lw	a0,0(s3)
    800038b6:	fffff097          	auipc	ra,0xfffff
    800038ba:	690080e7          	jalr	1680(ra) # 80002f46 <bread>
    800038be:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038c0:	05850493          	addi	s1,a0,88
    800038c4:	45850913          	addi	s2,a0,1112
    800038c8:	a811                	j	800038dc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038ca:	0009a503          	lw	a0,0(s3)
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	8be080e7          	jalr	-1858(ra) # 8000318c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038d6:	0491                	addi	s1,s1,4
    800038d8:	01248563          	beq	s1,s2,800038e2 <itrunc+0x8c>
      if(a[j])
    800038dc:	408c                	lw	a1,0(s1)
    800038de:	dde5                	beqz	a1,800038d6 <itrunc+0x80>
    800038e0:	b7ed                	j	800038ca <itrunc+0x74>
    brelse(bp);
    800038e2:	8552                	mv	a0,s4
    800038e4:	fffff097          	auipc	ra,0xfffff
    800038e8:	792080e7          	jalr	1938(ra) # 80003076 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ec:	0809a583          	lw	a1,128(s3)
    800038f0:	0009a503          	lw	a0,0(s3)
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	898080e7          	jalr	-1896(ra) # 8000318c <bfree>
    ip->addrs[NDIRECT] = 0;
    800038fc:	0809a023          	sw	zero,128(s3)
    80003900:	bf51                	j	80003894 <itrunc+0x3e>

0000000080003902 <iput>:
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
    8000390e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003910:	0001c517          	auipc	a0,0x1c
    80003914:	0b850513          	addi	a0,a0,184 # 8001f9c8 <itable>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	2cc080e7          	jalr	716(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003920:	4498                	lw	a4,8(s1)
    80003922:	4785                	li	a5,1
    80003924:	02f70363          	beq	a4,a5,8000394a <iput+0x48>
  ip->ref--;
    80003928:	449c                	lw	a5,8(s1)
    8000392a:	37fd                	addiw	a5,a5,-1
    8000392c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000392e:	0001c517          	auipc	a0,0x1c
    80003932:	09a50513          	addi	a0,a0,154 # 8001f9c8 <itable>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	362080e7          	jalr	866(ra) # 80000c98 <release>
}
    8000393e:	60e2                	ld	ra,24(sp)
    80003940:	6442                	ld	s0,16(sp)
    80003942:	64a2                	ld	s1,8(sp)
    80003944:	6902                	ld	s2,0(sp)
    80003946:	6105                	addi	sp,sp,32
    80003948:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394a:	40bc                	lw	a5,64(s1)
    8000394c:	dff1                	beqz	a5,80003928 <iput+0x26>
    8000394e:	04a49783          	lh	a5,74(s1)
    80003952:	fbf9                	bnez	a5,80003928 <iput+0x26>
    acquiresleep(&ip->lock);
    80003954:	01048913          	addi	s2,s1,16
    80003958:	854a                	mv	a0,s2
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	ab8080e7          	jalr	-1352(ra) # 80004412 <acquiresleep>
    release(&itable.lock);
    80003962:	0001c517          	auipc	a0,0x1c
    80003966:	06650513          	addi	a0,a0,102 # 8001f9c8 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	32e080e7          	jalr	814(ra) # 80000c98 <release>
    itrunc(ip);
    80003972:	8526                	mv	a0,s1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	ee2080e7          	jalr	-286(ra) # 80003856 <itrunc>
    ip->type = 0;
    8000397c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003980:	8526                	mv	a0,s1
    80003982:	00000097          	auipc	ra,0x0
    80003986:	cfc080e7          	jalr	-772(ra) # 8000367e <iupdate>
    ip->valid = 0;
    8000398a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000398e:	854a                	mv	a0,s2
    80003990:	00001097          	auipc	ra,0x1
    80003994:	ad8080e7          	jalr	-1320(ra) # 80004468 <releasesleep>
    acquire(&itable.lock);
    80003998:	0001c517          	auipc	a0,0x1c
    8000399c:	03050513          	addi	a0,a0,48 # 8001f9c8 <itable>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	244080e7          	jalr	580(ra) # 80000be4 <acquire>
    800039a8:	b741                	j	80003928 <iput+0x26>

00000000800039aa <iunlockput>:
{
    800039aa:	1101                	addi	sp,sp,-32
    800039ac:	ec06                	sd	ra,24(sp)
    800039ae:	e822                	sd	s0,16(sp)
    800039b0:	e426                	sd	s1,8(sp)
    800039b2:	1000                	addi	s0,sp,32
    800039b4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	e54080e7          	jalr	-428(ra) # 8000380a <iunlock>
  iput(ip);
    800039be:	8526                	mv	a0,s1
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	f42080e7          	jalr	-190(ra) # 80003902 <iput>
}
    800039c8:	60e2                	ld	ra,24(sp)
    800039ca:	6442                	ld	s0,16(sp)
    800039cc:	64a2                	ld	s1,8(sp)
    800039ce:	6105                	addi	sp,sp,32
    800039d0:	8082                	ret

00000000800039d2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039d2:	1141                	addi	sp,sp,-16
    800039d4:	e422                	sd	s0,8(sp)
    800039d6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039d8:	411c                	lw	a5,0(a0)
    800039da:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039dc:	415c                	lw	a5,4(a0)
    800039de:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039e0:	04451783          	lh	a5,68(a0)
    800039e4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039e8:	04a51783          	lh	a5,74(a0)
    800039ec:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039f0:	04c56783          	lwu	a5,76(a0)
    800039f4:	e99c                	sd	a5,16(a1)
}
    800039f6:	6422                	ld	s0,8(sp)
    800039f8:	0141                	addi	sp,sp,16
    800039fa:	8082                	ret

00000000800039fc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039fc:	457c                	lw	a5,76(a0)
    800039fe:	0ed7e963          	bltu	a5,a3,80003af0 <readi+0xf4>
{
    80003a02:	7159                	addi	sp,sp,-112
    80003a04:	f486                	sd	ra,104(sp)
    80003a06:	f0a2                	sd	s0,96(sp)
    80003a08:	eca6                	sd	s1,88(sp)
    80003a0a:	e8ca                	sd	s2,80(sp)
    80003a0c:	e4ce                	sd	s3,72(sp)
    80003a0e:	e0d2                	sd	s4,64(sp)
    80003a10:	fc56                	sd	s5,56(sp)
    80003a12:	f85a                	sd	s6,48(sp)
    80003a14:	f45e                	sd	s7,40(sp)
    80003a16:	f062                	sd	s8,32(sp)
    80003a18:	ec66                	sd	s9,24(sp)
    80003a1a:	e86a                	sd	s10,16(sp)
    80003a1c:	e46e                	sd	s11,8(sp)
    80003a1e:	1880                	addi	s0,sp,112
    80003a20:	8baa                	mv	s7,a0
    80003a22:	8c2e                	mv	s8,a1
    80003a24:	8ab2                	mv	s5,a2
    80003a26:	84b6                	mv	s1,a3
    80003a28:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a2a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a2c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a2e:	0ad76063          	bltu	a4,a3,80003ace <readi+0xd2>
  if(off + n > ip->size)
    80003a32:	00e7f463          	bgeu	a5,a4,80003a3a <readi+0x3e>
    n = ip->size - off;
    80003a36:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3a:	0a0b0963          	beqz	s6,80003aec <readi+0xf0>
    80003a3e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a40:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a44:	5cfd                	li	s9,-1
    80003a46:	a82d                	j	80003a80 <readi+0x84>
    80003a48:	020a1d93          	slli	s11,s4,0x20
    80003a4c:	020ddd93          	srli	s11,s11,0x20
    80003a50:	05890613          	addi	a2,s2,88
    80003a54:	86ee                	mv	a3,s11
    80003a56:	963a                	add	a2,a2,a4
    80003a58:	85d6                	mv	a1,s5
    80003a5a:	8562                	mv	a0,s8
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	9bc080e7          	jalr	-1604(ra) # 80002418 <either_copyout>
    80003a64:	05950d63          	beq	a0,s9,80003abe <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a68:	854a                	mv	a0,s2
    80003a6a:	fffff097          	auipc	ra,0xfffff
    80003a6e:	60c080e7          	jalr	1548(ra) # 80003076 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a72:	013a09bb          	addw	s3,s4,s3
    80003a76:	009a04bb          	addw	s1,s4,s1
    80003a7a:	9aee                	add	s5,s5,s11
    80003a7c:	0569f763          	bgeu	s3,s6,80003aca <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a80:	000ba903          	lw	s2,0(s7)
    80003a84:	00a4d59b          	srliw	a1,s1,0xa
    80003a88:	855e                	mv	a0,s7
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	8b0080e7          	jalr	-1872(ra) # 8000333a <bmap>
    80003a92:	0005059b          	sext.w	a1,a0
    80003a96:	854a                	mv	a0,s2
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	4ae080e7          	jalr	1198(ra) # 80002f46 <bread>
    80003aa0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa2:	3ff4f713          	andi	a4,s1,1023
    80003aa6:	40ed07bb          	subw	a5,s10,a4
    80003aaa:	413b06bb          	subw	a3,s6,s3
    80003aae:	8a3e                	mv	s4,a5
    80003ab0:	2781                	sext.w	a5,a5
    80003ab2:	0006861b          	sext.w	a2,a3
    80003ab6:	f8f679e3          	bgeu	a2,a5,80003a48 <readi+0x4c>
    80003aba:	8a36                	mv	s4,a3
    80003abc:	b771                	j	80003a48 <readi+0x4c>
      brelse(bp);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	fffff097          	auipc	ra,0xfffff
    80003ac4:	5b6080e7          	jalr	1462(ra) # 80003076 <brelse>
      tot = -1;
    80003ac8:	59fd                	li	s3,-1
  }
  return tot;
    80003aca:	0009851b          	sext.w	a0,s3
}
    80003ace:	70a6                	ld	ra,104(sp)
    80003ad0:	7406                	ld	s0,96(sp)
    80003ad2:	64e6                	ld	s1,88(sp)
    80003ad4:	6946                	ld	s2,80(sp)
    80003ad6:	69a6                	ld	s3,72(sp)
    80003ad8:	6a06                	ld	s4,64(sp)
    80003ada:	7ae2                	ld	s5,56(sp)
    80003adc:	7b42                	ld	s6,48(sp)
    80003ade:	7ba2                	ld	s7,40(sp)
    80003ae0:	7c02                	ld	s8,32(sp)
    80003ae2:	6ce2                	ld	s9,24(sp)
    80003ae4:	6d42                	ld	s10,16(sp)
    80003ae6:	6da2                	ld	s11,8(sp)
    80003ae8:	6165                	addi	sp,sp,112
    80003aea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aec:	89da                	mv	s3,s6
    80003aee:	bff1                	j	80003aca <readi+0xce>
    return 0;
    80003af0:	4501                	li	a0,0
}
    80003af2:	8082                	ret

0000000080003af4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af4:	457c                	lw	a5,76(a0)
    80003af6:	10d7e863          	bltu	a5,a3,80003c06 <writei+0x112>
{
    80003afa:	7159                	addi	sp,sp,-112
    80003afc:	f486                	sd	ra,104(sp)
    80003afe:	f0a2                	sd	s0,96(sp)
    80003b00:	eca6                	sd	s1,88(sp)
    80003b02:	e8ca                	sd	s2,80(sp)
    80003b04:	e4ce                	sd	s3,72(sp)
    80003b06:	e0d2                	sd	s4,64(sp)
    80003b08:	fc56                	sd	s5,56(sp)
    80003b0a:	f85a                	sd	s6,48(sp)
    80003b0c:	f45e                	sd	s7,40(sp)
    80003b0e:	f062                	sd	s8,32(sp)
    80003b10:	ec66                	sd	s9,24(sp)
    80003b12:	e86a                	sd	s10,16(sp)
    80003b14:	e46e                	sd	s11,8(sp)
    80003b16:	1880                	addi	s0,sp,112
    80003b18:	8b2a                	mv	s6,a0
    80003b1a:	8c2e                	mv	s8,a1
    80003b1c:	8ab2                	mv	s5,a2
    80003b1e:	8936                	mv	s2,a3
    80003b20:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b22:	00e687bb          	addw	a5,a3,a4
    80003b26:	0ed7e263          	bltu	a5,a3,80003c0a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b2a:	00043737          	lui	a4,0x43
    80003b2e:	0ef76063          	bltu	a4,a5,80003c0e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b32:	0c0b8863          	beqz	s7,80003c02 <writei+0x10e>
    80003b36:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b38:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b3c:	5cfd                	li	s9,-1
    80003b3e:	a091                	j	80003b82 <writei+0x8e>
    80003b40:	02099d93          	slli	s11,s3,0x20
    80003b44:	020ddd93          	srli	s11,s11,0x20
    80003b48:	05848513          	addi	a0,s1,88
    80003b4c:	86ee                	mv	a3,s11
    80003b4e:	8656                	mv	a2,s5
    80003b50:	85e2                	mv	a1,s8
    80003b52:	953a                	add	a0,a0,a4
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	91a080e7          	jalr	-1766(ra) # 8000246e <either_copyin>
    80003b5c:	07950263          	beq	a0,s9,80003bc0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b60:	8526                	mv	a0,s1
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	790080e7          	jalr	1936(ra) # 800042f2 <log_write>
    brelse(bp);
    80003b6a:	8526                	mv	a0,s1
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	50a080e7          	jalr	1290(ra) # 80003076 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b74:	01498a3b          	addw	s4,s3,s4
    80003b78:	0129893b          	addw	s2,s3,s2
    80003b7c:	9aee                	add	s5,s5,s11
    80003b7e:	057a7663          	bgeu	s4,s7,80003bca <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b82:	000b2483          	lw	s1,0(s6)
    80003b86:	00a9559b          	srliw	a1,s2,0xa
    80003b8a:	855a                	mv	a0,s6
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	7ae080e7          	jalr	1966(ra) # 8000333a <bmap>
    80003b94:	0005059b          	sext.w	a1,a0
    80003b98:	8526                	mv	a0,s1
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	3ac080e7          	jalr	940(ra) # 80002f46 <bread>
    80003ba2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba4:	3ff97713          	andi	a4,s2,1023
    80003ba8:	40ed07bb          	subw	a5,s10,a4
    80003bac:	414b86bb          	subw	a3,s7,s4
    80003bb0:	89be                	mv	s3,a5
    80003bb2:	2781                	sext.w	a5,a5
    80003bb4:	0006861b          	sext.w	a2,a3
    80003bb8:	f8f674e3          	bgeu	a2,a5,80003b40 <writei+0x4c>
    80003bbc:	89b6                	mv	s3,a3
    80003bbe:	b749                	j	80003b40 <writei+0x4c>
      brelse(bp);
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	4b4080e7          	jalr	1204(ra) # 80003076 <brelse>
  }

  if(off > ip->size)
    80003bca:	04cb2783          	lw	a5,76(s6)
    80003bce:	0127f463          	bgeu	a5,s2,80003bd6 <writei+0xe2>
    ip->size = off;
    80003bd2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bd6:	855a                	mv	a0,s6
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	aa6080e7          	jalr	-1370(ra) # 8000367e <iupdate>

  return tot;
    80003be0:	000a051b          	sext.w	a0,s4
}
    80003be4:	70a6                	ld	ra,104(sp)
    80003be6:	7406                	ld	s0,96(sp)
    80003be8:	64e6                	ld	s1,88(sp)
    80003bea:	6946                	ld	s2,80(sp)
    80003bec:	69a6                	ld	s3,72(sp)
    80003bee:	6a06                	ld	s4,64(sp)
    80003bf0:	7ae2                	ld	s5,56(sp)
    80003bf2:	7b42                	ld	s6,48(sp)
    80003bf4:	7ba2                	ld	s7,40(sp)
    80003bf6:	7c02                	ld	s8,32(sp)
    80003bf8:	6ce2                	ld	s9,24(sp)
    80003bfa:	6d42                	ld	s10,16(sp)
    80003bfc:	6da2                	ld	s11,8(sp)
    80003bfe:	6165                	addi	sp,sp,112
    80003c00:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c02:	8a5e                	mv	s4,s7
    80003c04:	bfc9                	j	80003bd6 <writei+0xe2>
    return -1;
    80003c06:	557d                	li	a0,-1
}
    80003c08:	8082                	ret
    return -1;
    80003c0a:	557d                	li	a0,-1
    80003c0c:	bfe1                	j	80003be4 <writei+0xf0>
    return -1;
    80003c0e:	557d                	li	a0,-1
    80003c10:	bfd1                	j	80003be4 <writei+0xf0>

0000000080003c12 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c12:	1141                	addi	sp,sp,-16
    80003c14:	e406                	sd	ra,8(sp)
    80003c16:	e022                	sd	s0,0(sp)
    80003c18:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c1a:	4639                	li	a2,14
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	19c080e7          	jalr	412(ra) # 80000db8 <strncmp>
}
    80003c24:	60a2                	ld	ra,8(sp)
    80003c26:	6402                	ld	s0,0(sp)
    80003c28:	0141                	addi	sp,sp,16
    80003c2a:	8082                	ret

0000000080003c2c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c2c:	7139                	addi	sp,sp,-64
    80003c2e:	fc06                	sd	ra,56(sp)
    80003c30:	f822                	sd	s0,48(sp)
    80003c32:	f426                	sd	s1,40(sp)
    80003c34:	f04a                	sd	s2,32(sp)
    80003c36:	ec4e                	sd	s3,24(sp)
    80003c38:	e852                	sd	s4,16(sp)
    80003c3a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c3c:	04451703          	lh	a4,68(a0)
    80003c40:	4785                	li	a5,1
    80003c42:	00f71a63          	bne	a4,a5,80003c56 <dirlookup+0x2a>
    80003c46:	892a                	mv	s2,a0
    80003c48:	89ae                	mv	s3,a1
    80003c4a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4c:	457c                	lw	a5,76(a0)
    80003c4e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c50:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c52:	e79d                	bnez	a5,80003c80 <dirlookup+0x54>
    80003c54:	a8a5                	j	80003ccc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c56:	00005517          	auipc	a0,0x5
    80003c5a:	a7250513          	addi	a0,a0,-1422 # 800086c8 <syscalls+0x1a8>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	8e0080e7          	jalr	-1824(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c66:	00005517          	auipc	a0,0x5
    80003c6a:	a7a50513          	addi	a0,a0,-1414 # 800086e0 <syscalls+0x1c0>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	8d0080e7          	jalr	-1840(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c76:	24c1                	addiw	s1,s1,16
    80003c78:	04c92783          	lw	a5,76(s2)
    80003c7c:	04f4f763          	bgeu	s1,a5,80003cca <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c80:	4741                	li	a4,16
    80003c82:	86a6                	mv	a3,s1
    80003c84:	fc040613          	addi	a2,s0,-64
    80003c88:	4581                	li	a1,0
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	d70080e7          	jalr	-656(ra) # 800039fc <readi>
    80003c94:	47c1                	li	a5,16
    80003c96:	fcf518e3          	bne	a0,a5,80003c66 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c9a:	fc045783          	lhu	a5,-64(s0)
    80003c9e:	dfe1                	beqz	a5,80003c76 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ca0:	fc240593          	addi	a1,s0,-62
    80003ca4:	854e                	mv	a0,s3
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	f6c080e7          	jalr	-148(ra) # 80003c12 <namecmp>
    80003cae:	f561                	bnez	a0,80003c76 <dirlookup+0x4a>
      if(poff)
    80003cb0:	000a0463          	beqz	s4,80003cb8 <dirlookup+0x8c>
        *poff = off;
    80003cb4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cb8:	fc045583          	lhu	a1,-64(s0)
    80003cbc:	00092503          	lw	a0,0(s2)
    80003cc0:	fffff097          	auipc	ra,0xfffff
    80003cc4:	754080e7          	jalr	1876(ra) # 80003414 <iget>
    80003cc8:	a011                	j	80003ccc <dirlookup+0xa0>
  return 0;
    80003cca:	4501                	li	a0,0
}
    80003ccc:	70e2                	ld	ra,56(sp)
    80003cce:	7442                	ld	s0,48(sp)
    80003cd0:	74a2                	ld	s1,40(sp)
    80003cd2:	7902                	ld	s2,32(sp)
    80003cd4:	69e2                	ld	s3,24(sp)
    80003cd6:	6a42                	ld	s4,16(sp)
    80003cd8:	6121                	addi	sp,sp,64
    80003cda:	8082                	ret

0000000080003cdc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cdc:	711d                	addi	sp,sp,-96
    80003cde:	ec86                	sd	ra,88(sp)
    80003ce0:	e8a2                	sd	s0,80(sp)
    80003ce2:	e4a6                	sd	s1,72(sp)
    80003ce4:	e0ca                	sd	s2,64(sp)
    80003ce6:	fc4e                	sd	s3,56(sp)
    80003ce8:	f852                	sd	s4,48(sp)
    80003cea:	f456                	sd	s5,40(sp)
    80003cec:	f05a                	sd	s6,32(sp)
    80003cee:	ec5e                	sd	s7,24(sp)
    80003cf0:	e862                	sd	s8,16(sp)
    80003cf2:	e466                	sd	s9,8(sp)
    80003cf4:	1080                	addi	s0,sp,96
    80003cf6:	84aa                	mv	s1,a0
    80003cf8:	8b2e                	mv	s6,a1
    80003cfa:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cfc:	00054703          	lbu	a4,0(a0)
    80003d00:	02f00793          	li	a5,47
    80003d04:	02f70363          	beq	a4,a5,80003d2a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d08:	ffffe097          	auipc	ra,0xffffe
    80003d0c:	ca8080e7          	jalr	-856(ra) # 800019b0 <myproc>
    80003d10:	15053503          	ld	a0,336(a0)
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	9f6080e7          	jalr	-1546(ra) # 8000370a <idup>
    80003d1c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d1e:	02f00913          	li	s2,47
  len = path - s;
    80003d22:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d24:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d26:	4c05                	li	s8,1
    80003d28:	a865                	j	80003de0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d2a:	4585                	li	a1,1
    80003d2c:	4505                	li	a0,1
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	6e6080e7          	jalr	1766(ra) # 80003414 <iget>
    80003d36:	89aa                	mv	s3,a0
    80003d38:	b7dd                	j	80003d1e <namex+0x42>
      iunlockput(ip);
    80003d3a:	854e                	mv	a0,s3
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	c6e080e7          	jalr	-914(ra) # 800039aa <iunlockput>
      return 0;
    80003d44:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d46:	854e                	mv	a0,s3
    80003d48:	60e6                	ld	ra,88(sp)
    80003d4a:	6446                	ld	s0,80(sp)
    80003d4c:	64a6                	ld	s1,72(sp)
    80003d4e:	6906                	ld	s2,64(sp)
    80003d50:	79e2                	ld	s3,56(sp)
    80003d52:	7a42                	ld	s4,48(sp)
    80003d54:	7aa2                	ld	s5,40(sp)
    80003d56:	7b02                	ld	s6,32(sp)
    80003d58:	6be2                	ld	s7,24(sp)
    80003d5a:	6c42                	ld	s8,16(sp)
    80003d5c:	6ca2                	ld	s9,8(sp)
    80003d5e:	6125                	addi	sp,sp,96
    80003d60:	8082                	ret
      iunlock(ip);
    80003d62:	854e                	mv	a0,s3
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	aa6080e7          	jalr	-1370(ra) # 8000380a <iunlock>
      return ip;
    80003d6c:	bfe9                	j	80003d46 <namex+0x6a>
      iunlockput(ip);
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	c3a080e7          	jalr	-966(ra) # 800039aa <iunlockput>
      return 0;
    80003d78:	89d2                	mv	s3,s4
    80003d7a:	b7f1                	j	80003d46 <namex+0x6a>
  len = path - s;
    80003d7c:	40b48633          	sub	a2,s1,a1
    80003d80:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d84:	094cd463          	bge	s9,s4,80003e0c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d88:	4639                	li	a2,14
    80003d8a:	8556                	mv	a0,s5
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	fb4080e7          	jalr	-76(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d94:	0004c783          	lbu	a5,0(s1)
    80003d98:	01279763          	bne	a5,s2,80003da6 <namex+0xca>
    path++;
    80003d9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d9e:	0004c783          	lbu	a5,0(s1)
    80003da2:	ff278de3          	beq	a5,s2,80003d9c <namex+0xc0>
    ilock(ip);
    80003da6:	854e                	mv	a0,s3
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	9a0080e7          	jalr	-1632(ra) # 80003748 <ilock>
    if(ip->type != T_DIR){
    80003db0:	04499783          	lh	a5,68(s3)
    80003db4:	f98793e3          	bne	a5,s8,80003d3a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003db8:	000b0563          	beqz	s6,80003dc2 <namex+0xe6>
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	d3cd                	beqz	a5,80003d62 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc2:	865e                	mv	a2,s7
    80003dc4:	85d6                	mv	a1,s5
    80003dc6:	854e                	mv	a0,s3
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	e64080e7          	jalr	-412(ra) # 80003c2c <dirlookup>
    80003dd0:	8a2a                	mv	s4,a0
    80003dd2:	dd51                	beqz	a0,80003d6e <namex+0x92>
    iunlockput(ip);
    80003dd4:	854e                	mv	a0,s3
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	bd4080e7          	jalr	-1068(ra) # 800039aa <iunlockput>
    ip = next;
    80003dde:	89d2                	mv	s3,s4
  while(*path == '/')
    80003de0:	0004c783          	lbu	a5,0(s1)
    80003de4:	05279763          	bne	a5,s2,80003e32 <namex+0x156>
    path++;
    80003de8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dea:	0004c783          	lbu	a5,0(s1)
    80003dee:	ff278de3          	beq	a5,s2,80003de8 <namex+0x10c>
  if(*path == 0)
    80003df2:	c79d                	beqz	a5,80003e20 <namex+0x144>
    path++;
    80003df4:	85a6                	mv	a1,s1
  len = path - s;
    80003df6:	8a5e                	mv	s4,s7
    80003df8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dfa:	01278963          	beq	a5,s2,80003e0c <namex+0x130>
    80003dfe:	dfbd                	beqz	a5,80003d7c <namex+0xa0>
    path++;
    80003e00:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	ff279ce3          	bne	a5,s2,80003dfe <namex+0x122>
    80003e0a:	bf8d                	j	80003d7c <namex+0xa0>
    memmove(name, s, len);
    80003e0c:	2601                	sext.w	a2,a2
    80003e0e:	8556                	mv	a0,s5
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	f30080e7          	jalr	-208(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e18:	9a56                	add	s4,s4,s5
    80003e1a:	000a0023          	sb	zero,0(s4)
    80003e1e:	bf9d                	j	80003d94 <namex+0xb8>
  if(nameiparent){
    80003e20:	f20b03e3          	beqz	s6,80003d46 <namex+0x6a>
    iput(ip);
    80003e24:	854e                	mv	a0,s3
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	adc080e7          	jalr	-1316(ra) # 80003902 <iput>
    return 0;
    80003e2e:	4981                	li	s3,0
    80003e30:	bf19                	j	80003d46 <namex+0x6a>
  if(*path == 0)
    80003e32:	d7fd                	beqz	a5,80003e20 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e34:	0004c783          	lbu	a5,0(s1)
    80003e38:	85a6                	mv	a1,s1
    80003e3a:	b7d1                	j	80003dfe <namex+0x122>

0000000080003e3c <dirlink>:
{
    80003e3c:	7139                	addi	sp,sp,-64
    80003e3e:	fc06                	sd	ra,56(sp)
    80003e40:	f822                	sd	s0,48(sp)
    80003e42:	f426                	sd	s1,40(sp)
    80003e44:	f04a                	sd	s2,32(sp)
    80003e46:	ec4e                	sd	s3,24(sp)
    80003e48:	e852                	sd	s4,16(sp)
    80003e4a:	0080                	addi	s0,sp,64
    80003e4c:	892a                	mv	s2,a0
    80003e4e:	8a2e                	mv	s4,a1
    80003e50:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e52:	4601                	li	a2,0
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	dd8080e7          	jalr	-552(ra) # 80003c2c <dirlookup>
    80003e5c:	e93d                	bnez	a0,80003ed2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5e:	04c92483          	lw	s1,76(s2)
    80003e62:	c49d                	beqz	s1,80003e90 <dirlink+0x54>
    80003e64:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e66:	4741                	li	a4,16
    80003e68:	86a6                	mv	a3,s1
    80003e6a:	fc040613          	addi	a2,s0,-64
    80003e6e:	4581                	li	a1,0
    80003e70:	854a                	mv	a0,s2
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	b8a080e7          	jalr	-1142(ra) # 800039fc <readi>
    80003e7a:	47c1                	li	a5,16
    80003e7c:	06f51163          	bne	a0,a5,80003ede <dirlink+0xa2>
    if(de.inum == 0)
    80003e80:	fc045783          	lhu	a5,-64(s0)
    80003e84:	c791                	beqz	a5,80003e90 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e86:	24c1                	addiw	s1,s1,16
    80003e88:	04c92783          	lw	a5,76(s2)
    80003e8c:	fcf4ede3          	bltu	s1,a5,80003e66 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e90:	4639                	li	a2,14
    80003e92:	85d2                	mv	a1,s4
    80003e94:	fc240513          	addi	a0,s0,-62
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	f5c080e7          	jalr	-164(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003ea0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea4:	4741                	li	a4,16
    80003ea6:	86a6                	mv	a3,s1
    80003ea8:	fc040613          	addi	a2,s0,-64
    80003eac:	4581                	li	a1,0
    80003eae:	854a                	mv	a0,s2
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	c44080e7          	jalr	-956(ra) # 80003af4 <writei>
    80003eb8:	872a                	mv	a4,a0
    80003eba:	47c1                	li	a5,16
  return 0;
    80003ebc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebe:	02f71863          	bne	a4,a5,80003eee <dirlink+0xb2>
}
    80003ec2:	70e2                	ld	ra,56(sp)
    80003ec4:	7442                	ld	s0,48(sp)
    80003ec6:	74a2                	ld	s1,40(sp)
    80003ec8:	7902                	ld	s2,32(sp)
    80003eca:	69e2                	ld	s3,24(sp)
    80003ecc:	6a42                	ld	s4,16(sp)
    80003ece:	6121                	addi	sp,sp,64
    80003ed0:	8082                	ret
    iput(ip);
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	a30080e7          	jalr	-1488(ra) # 80003902 <iput>
    return -1;
    80003eda:	557d                	li	a0,-1
    80003edc:	b7dd                	j	80003ec2 <dirlink+0x86>
      panic("dirlink read");
    80003ede:	00005517          	auipc	a0,0x5
    80003ee2:	81250513          	addi	a0,a0,-2030 # 800086f0 <syscalls+0x1d0>
    80003ee6:	ffffc097          	auipc	ra,0xffffc
    80003eea:	658080e7          	jalr	1624(ra) # 8000053e <panic>
    panic("dirlink");
    80003eee:	00005517          	auipc	a0,0x5
    80003ef2:	90a50513          	addi	a0,a0,-1782 # 800087f8 <syscalls+0x2d8>
    80003ef6:	ffffc097          	auipc	ra,0xffffc
    80003efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>

0000000080003efe <namei>:

struct inode*
namei(char *path)
{
    80003efe:	1101                	addi	sp,sp,-32
    80003f00:	ec06                	sd	ra,24(sp)
    80003f02:	e822                	sd	s0,16(sp)
    80003f04:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f06:	fe040613          	addi	a2,s0,-32
    80003f0a:	4581                	li	a1,0
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	dd0080e7          	jalr	-560(ra) # 80003cdc <namex>
}
    80003f14:	60e2                	ld	ra,24(sp)
    80003f16:	6442                	ld	s0,16(sp)
    80003f18:	6105                	addi	sp,sp,32
    80003f1a:	8082                	ret

0000000080003f1c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f1c:	1141                	addi	sp,sp,-16
    80003f1e:	e406                	sd	ra,8(sp)
    80003f20:	e022                	sd	s0,0(sp)
    80003f22:	0800                	addi	s0,sp,16
    80003f24:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f26:	4585                	li	a1,1
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	db4080e7          	jalr	-588(ra) # 80003cdc <namex>
}
    80003f30:	60a2                	ld	ra,8(sp)
    80003f32:	6402                	ld	s0,0(sp)
    80003f34:	0141                	addi	sp,sp,16
    80003f36:	8082                	ret

0000000080003f38 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f38:	1101                	addi	sp,sp,-32
    80003f3a:	ec06                	sd	ra,24(sp)
    80003f3c:	e822                	sd	s0,16(sp)
    80003f3e:	e426                	sd	s1,8(sp)
    80003f40:	e04a                	sd	s2,0(sp)
    80003f42:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f44:	0001d917          	auipc	s2,0x1d
    80003f48:	52c90913          	addi	s2,s2,1324 # 80021470 <log>
    80003f4c:	01892583          	lw	a1,24(s2)
    80003f50:	02892503          	lw	a0,40(s2)
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	ff2080e7          	jalr	-14(ra) # 80002f46 <bread>
    80003f5c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f5e:	02c92683          	lw	a3,44(s2)
    80003f62:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f64:	02d05763          	blez	a3,80003f92 <write_head+0x5a>
    80003f68:	0001d797          	auipc	a5,0x1d
    80003f6c:	53878793          	addi	a5,a5,1336 # 800214a0 <log+0x30>
    80003f70:	05c50713          	addi	a4,a0,92
    80003f74:	36fd                	addiw	a3,a3,-1
    80003f76:	1682                	slli	a3,a3,0x20
    80003f78:	9281                	srli	a3,a3,0x20
    80003f7a:	068a                	slli	a3,a3,0x2
    80003f7c:	0001d617          	auipc	a2,0x1d
    80003f80:	52860613          	addi	a2,a2,1320 # 800214a4 <log+0x34>
    80003f84:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f86:	4390                	lw	a2,0(a5)
    80003f88:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8a:	0791                	addi	a5,a5,4
    80003f8c:	0711                	addi	a4,a4,4
    80003f8e:	fed79ce3          	bne	a5,a3,80003f86 <write_head+0x4e>
  }
  bwrite(buf);
    80003f92:	8526                	mv	a0,s1
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	0a4080e7          	jalr	164(ra) # 80003038 <bwrite>
  brelse(buf);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	0d8080e7          	jalr	216(ra) # 80003076 <brelse>
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret

0000000080003fb2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb2:	0001d797          	auipc	a5,0x1d
    80003fb6:	4ea7a783          	lw	a5,1258(a5) # 8002149c <log+0x2c>
    80003fba:	0af05d63          	blez	a5,80004074 <install_trans+0xc2>
{
    80003fbe:	7139                	addi	sp,sp,-64
    80003fc0:	fc06                	sd	ra,56(sp)
    80003fc2:	f822                	sd	s0,48(sp)
    80003fc4:	f426                	sd	s1,40(sp)
    80003fc6:	f04a                	sd	s2,32(sp)
    80003fc8:	ec4e                	sd	s3,24(sp)
    80003fca:	e852                	sd	s4,16(sp)
    80003fcc:	e456                	sd	s5,8(sp)
    80003fce:	e05a                	sd	s6,0(sp)
    80003fd0:	0080                	addi	s0,sp,64
    80003fd2:	8b2a                	mv	s6,a0
    80003fd4:	0001da97          	auipc	s5,0x1d
    80003fd8:	4cca8a93          	addi	s5,s5,1228 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fde:	0001d997          	auipc	s3,0x1d
    80003fe2:	49298993          	addi	s3,s3,1170 # 80021470 <log>
    80003fe6:	a035                	j	80004012 <install_trans+0x60>
      bunpin(dbuf);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	166080e7          	jalr	358(ra) # 80003150 <bunpin>
    brelse(lbuf);
    80003ff2:	854a                	mv	a0,s2
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	082080e7          	jalr	130(ra) # 80003076 <brelse>
    brelse(dbuf);
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	078080e7          	jalr	120(ra) # 80003076 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004006:	2a05                	addiw	s4,s4,1
    80004008:	0a91                	addi	s5,s5,4
    8000400a:	02c9a783          	lw	a5,44(s3)
    8000400e:	04fa5963          	bge	s4,a5,80004060 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004012:	0189a583          	lw	a1,24(s3)
    80004016:	014585bb          	addw	a1,a1,s4
    8000401a:	2585                	addiw	a1,a1,1
    8000401c:	0289a503          	lw	a0,40(s3)
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	f26080e7          	jalr	-218(ra) # 80002f46 <bread>
    80004028:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000402a:	000aa583          	lw	a1,0(s5)
    8000402e:	0289a503          	lw	a0,40(s3)
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	f14080e7          	jalr	-236(ra) # 80002f46 <bread>
    8000403a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000403c:	40000613          	li	a2,1024
    80004040:	05890593          	addi	a1,s2,88
    80004044:	05850513          	addi	a0,a0,88
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	cf8080e7          	jalr	-776(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004050:	8526                	mv	a0,s1
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	fe6080e7          	jalr	-26(ra) # 80003038 <bwrite>
    if(recovering == 0)
    8000405a:	f80b1ce3          	bnez	s6,80003ff2 <install_trans+0x40>
    8000405e:	b769                	j	80003fe8 <install_trans+0x36>
}
    80004060:	70e2                	ld	ra,56(sp)
    80004062:	7442                	ld	s0,48(sp)
    80004064:	74a2                	ld	s1,40(sp)
    80004066:	7902                	ld	s2,32(sp)
    80004068:	69e2                	ld	s3,24(sp)
    8000406a:	6a42                	ld	s4,16(sp)
    8000406c:	6aa2                	ld	s5,8(sp)
    8000406e:	6b02                	ld	s6,0(sp)
    80004070:	6121                	addi	sp,sp,64
    80004072:	8082                	ret
    80004074:	8082                	ret

0000000080004076 <initlog>:
{
    80004076:	7179                	addi	sp,sp,-48
    80004078:	f406                	sd	ra,40(sp)
    8000407a:	f022                	sd	s0,32(sp)
    8000407c:	ec26                	sd	s1,24(sp)
    8000407e:	e84a                	sd	s2,16(sp)
    80004080:	e44e                	sd	s3,8(sp)
    80004082:	1800                	addi	s0,sp,48
    80004084:	892a                	mv	s2,a0
    80004086:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	3e848493          	addi	s1,s1,1000 # 80021470 <log>
    80004090:	00004597          	auipc	a1,0x4
    80004094:	67058593          	addi	a1,a1,1648 # 80008700 <syscalls+0x1e0>
    80004098:	8526                	mv	a0,s1
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	aba080e7          	jalr	-1350(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800040a2:	0149a583          	lw	a1,20(s3)
    800040a6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040a8:	0109a783          	lw	a5,16(s3)
    800040ac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040b2:	854a                	mv	a0,s2
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	e92080e7          	jalr	-366(ra) # 80002f46 <bread>
  log.lh.n = lh->n;
    800040bc:	4d3c                	lw	a5,88(a0)
    800040be:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040c0:	02f05563          	blez	a5,800040ea <initlog+0x74>
    800040c4:	05c50713          	addi	a4,a0,92
    800040c8:	0001d697          	auipc	a3,0x1d
    800040cc:	3d868693          	addi	a3,a3,984 # 800214a0 <log+0x30>
    800040d0:	37fd                	addiw	a5,a5,-1
    800040d2:	1782                	slli	a5,a5,0x20
    800040d4:	9381                	srli	a5,a5,0x20
    800040d6:	078a                	slli	a5,a5,0x2
    800040d8:	06050613          	addi	a2,a0,96
    800040dc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040de:	4310                	lw	a2,0(a4)
    800040e0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040e2:	0711                	addi	a4,a4,4
    800040e4:	0691                	addi	a3,a3,4
    800040e6:	fef71ce3          	bne	a4,a5,800040de <initlog+0x68>
  brelse(buf);
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	f8c080e7          	jalr	-116(ra) # 80003076 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040f2:	4505                	li	a0,1
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	ebe080e7          	jalr	-322(ra) # 80003fb2 <install_trans>
  log.lh.n = 0;
    800040fc:	0001d797          	auipc	a5,0x1d
    80004100:	3a07a023          	sw	zero,928(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004104:	00000097          	auipc	ra,0x0
    80004108:	e34080e7          	jalr	-460(ra) # 80003f38 <write_head>
}
    8000410c:	70a2                	ld	ra,40(sp)
    8000410e:	7402                	ld	s0,32(sp)
    80004110:	64e2                	ld	s1,24(sp)
    80004112:	6942                	ld	s2,16(sp)
    80004114:	69a2                	ld	s3,8(sp)
    80004116:	6145                	addi	sp,sp,48
    80004118:	8082                	ret

000000008000411a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000411a:	1101                	addi	sp,sp,-32
    8000411c:	ec06                	sd	ra,24(sp)
    8000411e:	e822                	sd	s0,16(sp)
    80004120:	e426                	sd	s1,8(sp)
    80004122:	e04a                	sd	s2,0(sp)
    80004124:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004126:	0001d517          	auipc	a0,0x1d
    8000412a:	34a50513          	addi	a0,a0,842 # 80021470 <log>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	ab6080e7          	jalr	-1354(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004136:	0001d497          	auipc	s1,0x1d
    8000413a:	33a48493          	addi	s1,s1,826 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000413e:	4979                	li	s2,30
    80004140:	a039                	j	8000414e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004142:	85a6                	mv	a1,s1
    80004144:	8526                	mv	a0,s1
    80004146:	ffffe097          	auipc	ra,0xffffe
    8000414a:	f2e080e7          	jalr	-210(ra) # 80002074 <sleep>
    if(log.committing){
    8000414e:	50dc                	lw	a5,36(s1)
    80004150:	fbed                	bnez	a5,80004142 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004152:	509c                	lw	a5,32(s1)
    80004154:	0017871b          	addiw	a4,a5,1
    80004158:	0007069b          	sext.w	a3,a4
    8000415c:	0027179b          	slliw	a5,a4,0x2
    80004160:	9fb9                	addw	a5,a5,a4
    80004162:	0017979b          	slliw	a5,a5,0x1
    80004166:	54d8                	lw	a4,44(s1)
    80004168:	9fb9                	addw	a5,a5,a4
    8000416a:	00f95963          	bge	s2,a5,8000417c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000416e:	85a6                	mv	a1,s1
    80004170:	8526                	mv	a0,s1
    80004172:	ffffe097          	auipc	ra,0xffffe
    80004176:	f02080e7          	jalr	-254(ra) # 80002074 <sleep>
    8000417a:	bfd1                	j	8000414e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000417c:	0001d517          	auipc	a0,0x1d
    80004180:	2f450513          	addi	a0,a0,756 # 80021470 <log>
    80004184:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6902                	ld	s2,0(sp)
    80004196:	6105                	addi	sp,sp,32
    80004198:	8082                	ret

000000008000419a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000419a:	7139                	addi	sp,sp,-64
    8000419c:	fc06                	sd	ra,56(sp)
    8000419e:	f822                	sd	s0,48(sp)
    800041a0:	f426                	sd	s1,40(sp)
    800041a2:	f04a                	sd	s2,32(sp)
    800041a4:	ec4e                	sd	s3,24(sp)
    800041a6:	e852                	sd	s4,16(sp)
    800041a8:	e456                	sd	s5,8(sp)
    800041aa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ac:	0001d497          	auipc	s1,0x1d
    800041b0:	2c448493          	addi	s1,s1,708 # 80021470 <log>
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a2e080e7          	jalr	-1490(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800041be:	509c                	lw	a5,32(s1)
    800041c0:	37fd                	addiw	a5,a5,-1
    800041c2:	0007891b          	sext.w	s2,a5
    800041c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041c8:	50dc                	lw	a5,36(s1)
    800041ca:	efb9                	bnez	a5,80004228 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041cc:	06091663          	bnez	s2,80004238 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041d0:	0001d497          	auipc	s1,0x1d
    800041d4:	2a048493          	addi	s1,s1,672 # 80021470 <log>
    800041d8:	4785                	li	a5,1
    800041da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041e6:	54dc                	lw	a5,44(s1)
    800041e8:	06f04763          	bgtz	a5,80004256 <end_op+0xbc>
    acquire(&log.lock);
    800041ec:	0001d497          	auipc	s1,0x1d
    800041f0:	28448493          	addi	s1,s1,644 # 80021470 <log>
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	9ee080e7          	jalr	-1554(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004202:	8526                	mv	a0,s1
    80004204:	ffffe097          	auipc	ra,0xffffe
    80004208:	ffc080e7          	jalr	-4(ra) # 80002200 <wakeup>
    release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
}
    80004216:	70e2                	ld	ra,56(sp)
    80004218:	7442                	ld	s0,48(sp)
    8000421a:	74a2                	ld	s1,40(sp)
    8000421c:	7902                	ld	s2,32(sp)
    8000421e:	69e2                	ld	s3,24(sp)
    80004220:	6a42                	ld	s4,16(sp)
    80004222:	6aa2                	ld	s5,8(sp)
    80004224:	6121                	addi	sp,sp,64
    80004226:	8082                	ret
    panic("log.committing");
    80004228:	00004517          	auipc	a0,0x4
    8000422c:	4e050513          	addi	a0,a0,1248 # 80008708 <syscalls+0x1e8>
    80004230:	ffffc097          	auipc	ra,0xffffc
    80004234:	30e080e7          	jalr	782(ra) # 8000053e <panic>
    wakeup(&log);
    80004238:	0001d497          	auipc	s1,0x1d
    8000423c:	23848493          	addi	s1,s1,568 # 80021470 <log>
    80004240:	8526                	mv	a0,s1
    80004242:	ffffe097          	auipc	ra,0xffffe
    80004246:	fbe080e7          	jalr	-66(ra) # 80002200 <wakeup>
  release(&log.lock);
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	a4c080e7          	jalr	-1460(ra) # 80000c98 <release>
  if(do_commit){
    80004254:	b7c9                	j	80004216 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004256:	0001da97          	auipc	s5,0x1d
    8000425a:	24aa8a93          	addi	s5,s5,586 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000425e:	0001da17          	auipc	s4,0x1d
    80004262:	212a0a13          	addi	s4,s4,530 # 80021470 <log>
    80004266:	018a2583          	lw	a1,24(s4)
    8000426a:	012585bb          	addw	a1,a1,s2
    8000426e:	2585                	addiw	a1,a1,1
    80004270:	028a2503          	lw	a0,40(s4)
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	cd2080e7          	jalr	-814(ra) # 80002f46 <bread>
    8000427c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000427e:	000aa583          	lw	a1,0(s5)
    80004282:	028a2503          	lw	a0,40(s4)
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	cc0080e7          	jalr	-832(ra) # 80002f46 <bread>
    8000428e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004290:	40000613          	li	a2,1024
    80004294:	05850593          	addi	a1,a0,88
    80004298:	05848513          	addi	a0,s1,88
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	aa4080e7          	jalr	-1372(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800042a4:	8526                	mv	a0,s1
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	d92080e7          	jalr	-622(ra) # 80003038 <bwrite>
    brelse(from);
    800042ae:	854e                	mv	a0,s3
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	dc6080e7          	jalr	-570(ra) # 80003076 <brelse>
    brelse(to);
    800042b8:	8526                	mv	a0,s1
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	dbc080e7          	jalr	-580(ra) # 80003076 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	2905                	addiw	s2,s2,1
    800042c4:	0a91                	addi	s5,s5,4
    800042c6:	02ca2783          	lw	a5,44(s4)
    800042ca:	f8f94ee3          	blt	s2,a5,80004266 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	c6a080e7          	jalr	-918(ra) # 80003f38 <write_head>
    install_trans(0); // Now install writes to home locations
    800042d6:	4501                	li	a0,0
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	cda080e7          	jalr	-806(ra) # 80003fb2 <install_trans>
    log.lh.n = 0;
    800042e0:	0001d797          	auipc	a5,0x1d
    800042e4:	1a07ae23          	sw	zero,444(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	c50080e7          	jalr	-944(ra) # 80003f38 <write_head>
    800042f0:	bdf5                	j	800041ec <end_op+0x52>

00000000800042f2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042f2:	1101                	addi	sp,sp,-32
    800042f4:	ec06                	sd	ra,24(sp)
    800042f6:	e822                	sd	s0,16(sp)
    800042f8:	e426                	sd	s1,8(sp)
    800042fa:	e04a                	sd	s2,0(sp)
    800042fc:	1000                	addi	s0,sp,32
    800042fe:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004300:	0001d917          	auipc	s2,0x1d
    80004304:	17090913          	addi	s2,s2,368 # 80021470 <log>
    80004308:	854a                	mv	a0,s2
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	8da080e7          	jalr	-1830(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004312:	02c92603          	lw	a2,44(s2)
    80004316:	47f5                	li	a5,29
    80004318:	06c7c563          	blt	a5,a2,80004382 <log_write+0x90>
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	1707a783          	lw	a5,368(a5) # 8002148c <log+0x1c>
    80004324:	37fd                	addiw	a5,a5,-1
    80004326:	04f65e63          	bge	a2,a5,80004382 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000432a:	0001d797          	auipc	a5,0x1d
    8000432e:	1667a783          	lw	a5,358(a5) # 80021490 <log+0x20>
    80004332:	06f05063          	blez	a5,80004392 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004336:	4781                	li	a5,0
    80004338:	06c05563          	blez	a2,800043a2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000433c:	44cc                	lw	a1,12(s1)
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	16270713          	addi	a4,a4,354 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004346:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004348:	4314                	lw	a3,0(a4)
    8000434a:	04b68c63          	beq	a3,a1,800043a2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000434e:	2785                	addiw	a5,a5,1
    80004350:	0711                	addi	a4,a4,4
    80004352:	fef61be3          	bne	a2,a5,80004348 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004356:	0621                	addi	a2,a2,8
    80004358:	060a                	slli	a2,a2,0x2
    8000435a:	0001d797          	auipc	a5,0x1d
    8000435e:	11678793          	addi	a5,a5,278 # 80021470 <log>
    80004362:	963e                	add	a2,a2,a5
    80004364:	44dc                	lw	a5,12(s1)
    80004366:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004368:	8526                	mv	a0,s1
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	daa080e7          	jalr	-598(ra) # 80003114 <bpin>
    log.lh.n++;
    80004372:	0001d717          	auipc	a4,0x1d
    80004376:	0fe70713          	addi	a4,a4,254 # 80021470 <log>
    8000437a:	575c                	lw	a5,44(a4)
    8000437c:	2785                	addiw	a5,a5,1
    8000437e:	d75c                	sw	a5,44(a4)
    80004380:	a835                	j	800043bc <log_write+0xca>
    panic("too big a transaction");
    80004382:	00004517          	auipc	a0,0x4
    80004386:	39650513          	addi	a0,a0,918 # 80008718 <syscalls+0x1f8>
    8000438a:	ffffc097          	auipc	ra,0xffffc
    8000438e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004392:	00004517          	auipc	a0,0x4
    80004396:	39e50513          	addi	a0,a0,926 # 80008730 <syscalls+0x210>
    8000439a:	ffffc097          	auipc	ra,0xffffc
    8000439e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043a2:	00878713          	addi	a4,a5,8
    800043a6:	00271693          	slli	a3,a4,0x2
    800043aa:	0001d717          	auipc	a4,0x1d
    800043ae:	0c670713          	addi	a4,a4,198 # 80021470 <log>
    800043b2:	9736                	add	a4,a4,a3
    800043b4:	44d4                	lw	a3,12(s1)
    800043b6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043b8:	faf608e3          	beq	a2,a5,80004368 <log_write+0x76>
  }
  release(&log.lock);
    800043bc:	0001d517          	auipc	a0,0x1d
    800043c0:	0b450513          	addi	a0,a0,180 # 80021470 <log>
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
}
    800043cc:	60e2                	ld	ra,24(sp)
    800043ce:	6442                	ld	s0,16(sp)
    800043d0:	64a2                	ld	s1,8(sp)
    800043d2:	6902                	ld	s2,0(sp)
    800043d4:	6105                	addi	sp,sp,32
    800043d6:	8082                	ret

00000000800043d8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043d8:	1101                	addi	sp,sp,-32
    800043da:	ec06                	sd	ra,24(sp)
    800043dc:	e822                	sd	s0,16(sp)
    800043de:	e426                	sd	s1,8(sp)
    800043e0:	e04a                	sd	s2,0(sp)
    800043e2:	1000                	addi	s0,sp,32
    800043e4:	84aa                	mv	s1,a0
    800043e6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043e8:	00004597          	auipc	a1,0x4
    800043ec:	36858593          	addi	a1,a1,872 # 80008750 <syscalls+0x230>
    800043f0:	0521                	addi	a0,a0,8
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	762080e7          	jalr	1890(ra) # 80000b54 <initlock>
  lk->name = name;
    800043fa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043fe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004402:	0204a423          	sw	zero,40(s1)
}
    80004406:	60e2                	ld	ra,24(sp)
    80004408:	6442                	ld	s0,16(sp)
    8000440a:	64a2                	ld	s1,8(sp)
    8000440c:	6902                	ld	s2,0(sp)
    8000440e:	6105                	addi	sp,sp,32
    80004410:	8082                	ret

0000000080004412 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004412:	1101                	addi	sp,sp,-32
    80004414:	ec06                	sd	ra,24(sp)
    80004416:	e822                	sd	s0,16(sp)
    80004418:	e426                	sd	s1,8(sp)
    8000441a:	e04a                	sd	s2,0(sp)
    8000441c:	1000                	addi	s0,sp,32
    8000441e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004420:	00850913          	addi	s2,a0,8
    80004424:	854a                	mv	a0,s2
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	7be080e7          	jalr	1982(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000442e:	409c                	lw	a5,0(s1)
    80004430:	cb89                	beqz	a5,80004442 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004432:	85ca                	mv	a1,s2
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	c3e080e7          	jalr	-962(ra) # 80002074 <sleep>
  while (lk->locked) {
    8000443e:	409c                	lw	a5,0(s1)
    80004440:	fbed                	bnez	a5,80004432 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004442:	4785                	li	a5,1
    80004444:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	56a080e7          	jalr	1386(ra) # 800019b0 <myproc>
    8000444e:	591c                	lw	a5,48(a0)
    80004450:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004452:	854a                	mv	a0,s2
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004468:	1101                	addi	sp,sp,-32
    8000446a:	ec06                	sd	ra,24(sp)
    8000446c:	e822                	sd	s0,16(sp)
    8000446e:	e426                	sd	s1,8(sp)
    80004470:	e04a                	sd	s2,0(sp)
    80004472:	1000                	addi	s0,sp,32
    80004474:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	768080e7          	jalr	1896(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004484:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004488:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffe097          	auipc	ra,0xffffe
    80004492:	d72080e7          	jalr	-654(ra) # 80002200 <wakeup>
  release(&lk->lk);
    80004496:	854a                	mv	a0,s2
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
}
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6902                	ld	s2,0(sp)
    800044a8:	6105                	addi	sp,sp,32
    800044aa:	8082                	ret

00000000800044ac <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ac:	7179                	addi	sp,sp,-48
    800044ae:	f406                	sd	ra,40(sp)
    800044b0:	f022                	sd	s0,32(sp)
    800044b2:	ec26                	sd	s1,24(sp)
    800044b4:	e84a                	sd	s2,16(sp)
    800044b6:	e44e                	sd	s3,8(sp)
    800044b8:	1800                	addi	s0,sp,48
    800044ba:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044bc:	00850913          	addi	s2,a0,8
    800044c0:	854a                	mv	a0,s2
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	722080e7          	jalr	1826(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ca:	409c                	lw	a5,0(s1)
    800044cc:	ef99                	bnez	a5,800044ea <holdingsleep+0x3e>
    800044ce:	4481                	li	s1,0
  release(&lk->lk);
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
  return r;
}
    800044da:	8526                	mv	a0,s1
    800044dc:	70a2                	ld	ra,40(sp)
    800044de:	7402                	ld	s0,32(sp)
    800044e0:	64e2                	ld	s1,24(sp)
    800044e2:	6942                	ld	s2,16(sp)
    800044e4:	69a2                	ld	s3,8(sp)
    800044e6:	6145                	addi	sp,sp,48
    800044e8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ea:	0284a983          	lw	s3,40(s1)
    800044ee:	ffffd097          	auipc	ra,0xffffd
    800044f2:	4c2080e7          	jalr	1218(ra) # 800019b0 <myproc>
    800044f6:	5904                	lw	s1,48(a0)
    800044f8:	413484b3          	sub	s1,s1,s3
    800044fc:	0014b493          	seqz	s1,s1
    80004500:	bfc1                	j	800044d0 <holdingsleep+0x24>

0000000080004502 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004502:	1141                	addi	sp,sp,-16
    80004504:	e406                	sd	ra,8(sp)
    80004506:	e022                	sd	s0,0(sp)
    80004508:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000450a:	00004597          	auipc	a1,0x4
    8000450e:	25658593          	addi	a1,a1,598 # 80008760 <syscalls+0x240>
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	0a650513          	addi	a0,a0,166 # 800215b8 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	63a080e7          	jalr	1594(ra) # 80000b54 <initlock>
}
    80004522:	60a2                	ld	ra,8(sp)
    80004524:	6402                	ld	s0,0(sp)
    80004526:	0141                	addi	sp,sp,16
    80004528:	8082                	ret

000000008000452a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000452a:	1101                	addi	sp,sp,-32
    8000452c:	ec06                	sd	ra,24(sp)
    8000452e:	e822                	sd	s0,16(sp)
    80004530:	e426                	sd	s1,8(sp)
    80004532:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004534:	0001d517          	auipc	a0,0x1d
    80004538:	08450513          	addi	a0,a0,132 # 800215b8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	6a8080e7          	jalr	1704(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004544:	0001d497          	auipc	s1,0x1d
    80004548:	08c48493          	addi	s1,s1,140 # 800215d0 <ftable+0x18>
    8000454c:	0001e717          	auipc	a4,0x1e
    80004550:	02470713          	addi	a4,a4,36 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004554:	40dc                	lw	a5,4(s1)
    80004556:	cf99                	beqz	a5,80004574 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004558:	02848493          	addi	s1,s1,40
    8000455c:	fee49ce3          	bne	s1,a4,80004554 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004560:	0001d517          	auipc	a0,0x1d
    80004564:	05850513          	addi	a0,a0,88 # 800215b8 <ftable>
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	730080e7          	jalr	1840(ra) # 80000c98 <release>
  return 0;
    80004570:	4481                	li	s1,0
    80004572:	a819                	j	80004588 <filealloc+0x5e>
      f->ref = 1;
    80004574:	4785                	li	a5,1
    80004576:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004578:	0001d517          	auipc	a0,0x1d
    8000457c:	04050513          	addi	a0,a0,64 # 800215b8 <ftable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	718080e7          	jalr	1816(ra) # 80000c98 <release>
}
    80004588:	8526                	mv	a0,s1
    8000458a:	60e2                	ld	ra,24(sp)
    8000458c:	6442                	ld	s0,16(sp)
    8000458e:	64a2                	ld	s1,8(sp)
    80004590:	6105                	addi	sp,sp,32
    80004592:	8082                	ret

0000000080004594 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	1000                	addi	s0,sp,32
    8000459e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045a0:	0001d517          	auipc	a0,0x1d
    800045a4:	01850513          	addi	a0,a0,24 # 800215b8 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	63c080e7          	jalr	1596(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045b0:	40dc                	lw	a5,4(s1)
    800045b2:	02f05263          	blez	a5,800045d6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045b6:	2785                	addiw	a5,a5,1
    800045b8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ba:	0001d517          	auipc	a0,0x1d
    800045be:	ffe50513          	addi	a0,a0,-2 # 800215b8 <ftable>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
  return f;
}
    800045ca:	8526                	mv	a0,s1
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6105                	addi	sp,sp,32
    800045d4:	8082                	ret
    panic("filedup");
    800045d6:	00004517          	auipc	a0,0x4
    800045da:	19250513          	addi	a0,a0,402 # 80008768 <syscalls+0x248>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>

00000000800045e6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045e6:	7139                	addi	sp,sp,-64
    800045e8:	fc06                	sd	ra,56(sp)
    800045ea:	f822                	sd	s0,48(sp)
    800045ec:	f426                	sd	s1,40(sp)
    800045ee:	f04a                	sd	s2,32(sp)
    800045f0:	ec4e                	sd	s3,24(sp)
    800045f2:	e852                	sd	s4,16(sp)
    800045f4:	e456                	sd	s5,8(sp)
    800045f6:	0080                	addi	s0,sp,64
    800045f8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045fa:	0001d517          	auipc	a0,0x1d
    800045fe:	fbe50513          	addi	a0,a0,-66 # 800215b8 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000460a:	40dc                	lw	a5,4(s1)
    8000460c:	06f05163          	blez	a5,8000466e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004610:	37fd                	addiw	a5,a5,-1
    80004612:	0007871b          	sext.w	a4,a5
    80004616:	c0dc                	sw	a5,4(s1)
    80004618:	06e04363          	bgtz	a4,8000467e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000461c:	0004a903          	lw	s2,0(s1)
    80004620:	0094ca83          	lbu	s5,9(s1)
    80004624:	0104ba03          	ld	s4,16(s1)
    80004628:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000462c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004630:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004634:	0001d517          	auipc	a0,0x1d
    80004638:	f8450513          	addi	a0,a0,-124 # 800215b8 <ftable>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	65c080e7          	jalr	1628(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004644:	4785                	li	a5,1
    80004646:	04f90d63          	beq	s2,a5,800046a0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000464a:	3979                	addiw	s2,s2,-2
    8000464c:	4785                	li	a5,1
    8000464e:	0527e063          	bltu	a5,s2,8000468e <fileclose+0xa8>
    begin_op();
    80004652:	00000097          	auipc	ra,0x0
    80004656:	ac8080e7          	jalr	-1336(ra) # 8000411a <begin_op>
    iput(ff.ip);
    8000465a:	854e                	mv	a0,s3
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	2a6080e7          	jalr	678(ra) # 80003902 <iput>
    end_op();
    80004664:	00000097          	auipc	ra,0x0
    80004668:	b36080e7          	jalr	-1226(ra) # 8000419a <end_op>
    8000466c:	a00d                	j	8000468e <fileclose+0xa8>
    panic("fileclose");
    8000466e:	00004517          	auipc	a0,0x4
    80004672:	10250513          	addi	a0,a0,258 # 80008770 <syscalls+0x250>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	ec8080e7          	jalr	-312(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000467e:	0001d517          	auipc	a0,0x1d
    80004682:	f3a50513          	addi	a0,a0,-198 # 800215b8 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
  }
}
    8000468e:	70e2                	ld	ra,56(sp)
    80004690:	7442                	ld	s0,48(sp)
    80004692:	74a2                	ld	s1,40(sp)
    80004694:	7902                	ld	s2,32(sp)
    80004696:	69e2                	ld	s3,24(sp)
    80004698:	6a42                	ld	s4,16(sp)
    8000469a:	6aa2                	ld	s5,8(sp)
    8000469c:	6121                	addi	sp,sp,64
    8000469e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046a0:	85d6                	mv	a1,s5
    800046a2:	8552                	mv	a0,s4
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	34c080e7          	jalr	844(ra) # 800049f0 <pipeclose>
    800046ac:	b7cd                	j	8000468e <fileclose+0xa8>

00000000800046ae <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046ae:	715d                	addi	sp,sp,-80
    800046b0:	e486                	sd	ra,72(sp)
    800046b2:	e0a2                	sd	s0,64(sp)
    800046b4:	fc26                	sd	s1,56(sp)
    800046b6:	f84a                	sd	s2,48(sp)
    800046b8:	f44e                	sd	s3,40(sp)
    800046ba:	0880                	addi	s0,sp,80
    800046bc:	84aa                	mv	s1,a0
    800046be:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046c0:	ffffd097          	auipc	ra,0xffffd
    800046c4:	2f0080e7          	jalr	752(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c8:	409c                	lw	a5,0(s1)
    800046ca:	37f9                	addiw	a5,a5,-2
    800046cc:	4705                	li	a4,1
    800046ce:	04f76763          	bltu	a4,a5,8000471c <filestat+0x6e>
    800046d2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	072080e7          	jalr	114(ra) # 80003748 <ilock>
    stati(f->ip, &st);
    800046de:	fb840593          	addi	a1,s0,-72
    800046e2:	6c88                	ld	a0,24(s1)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	2ee080e7          	jalr	750(ra) # 800039d2 <stati>
    iunlock(f->ip);
    800046ec:	6c88                	ld	a0,24(s1)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	11c080e7          	jalr	284(ra) # 8000380a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046f6:	46e1                	li	a3,24
    800046f8:	fb840613          	addi	a2,s0,-72
    800046fc:	85ce                	mv	a1,s3
    800046fe:	05093503          	ld	a0,80(s2)
    80004702:	ffffd097          	auipc	ra,0xffffd
    80004706:	f70080e7          	jalr	-144(ra) # 80001672 <copyout>
    8000470a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000470e:	60a6                	ld	ra,72(sp)
    80004710:	6406                	ld	s0,64(sp)
    80004712:	74e2                	ld	s1,56(sp)
    80004714:	7942                	ld	s2,48(sp)
    80004716:	79a2                	ld	s3,40(sp)
    80004718:	6161                	addi	sp,sp,80
    8000471a:	8082                	ret
  return -1;
    8000471c:	557d                	li	a0,-1
    8000471e:	bfc5                	j	8000470e <filestat+0x60>

0000000080004720 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004720:	7179                	addi	sp,sp,-48
    80004722:	f406                	sd	ra,40(sp)
    80004724:	f022                	sd	s0,32(sp)
    80004726:	ec26                	sd	s1,24(sp)
    80004728:	e84a                	sd	s2,16(sp)
    8000472a:	e44e                	sd	s3,8(sp)
    8000472c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000472e:	00854783          	lbu	a5,8(a0)
    80004732:	c3d5                	beqz	a5,800047d6 <fileread+0xb6>
    80004734:	84aa                	mv	s1,a0
    80004736:	89ae                	mv	s3,a1
    80004738:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000473a:	411c                	lw	a5,0(a0)
    8000473c:	4705                	li	a4,1
    8000473e:	04e78963          	beq	a5,a4,80004790 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004742:	470d                	li	a4,3
    80004744:	04e78d63          	beq	a5,a4,8000479e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004748:	4709                	li	a4,2
    8000474a:	06e79e63          	bne	a5,a4,800047c6 <fileread+0xa6>
    ilock(f->ip);
    8000474e:	6d08                	ld	a0,24(a0)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	ff8080e7          	jalr	-8(ra) # 80003748 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004758:	874a                	mv	a4,s2
    8000475a:	5094                	lw	a3,32(s1)
    8000475c:	864e                	mv	a2,s3
    8000475e:	4585                	li	a1,1
    80004760:	6c88                	ld	a0,24(s1)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	29a080e7          	jalr	666(ra) # 800039fc <readi>
    8000476a:	892a                	mv	s2,a0
    8000476c:	00a05563          	blez	a0,80004776 <fileread+0x56>
      f->off += r;
    80004770:	509c                	lw	a5,32(s1)
    80004772:	9fa9                	addw	a5,a5,a0
    80004774:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004776:	6c88                	ld	a0,24(s1)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	092080e7          	jalr	146(ra) # 8000380a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004780:	854a                	mv	a0,s2
    80004782:	70a2                	ld	ra,40(sp)
    80004784:	7402                	ld	s0,32(sp)
    80004786:	64e2                	ld	s1,24(sp)
    80004788:	6942                	ld	s2,16(sp)
    8000478a:	69a2                	ld	s3,8(sp)
    8000478c:	6145                	addi	sp,sp,48
    8000478e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004790:	6908                	ld	a0,16(a0)
    80004792:	00000097          	auipc	ra,0x0
    80004796:	3c8080e7          	jalr	968(ra) # 80004b5a <piperead>
    8000479a:	892a                	mv	s2,a0
    8000479c:	b7d5                	j	80004780 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000479e:	02451783          	lh	a5,36(a0)
    800047a2:	03079693          	slli	a3,a5,0x30
    800047a6:	92c1                	srli	a3,a3,0x30
    800047a8:	4725                	li	a4,9
    800047aa:	02d76863          	bltu	a4,a3,800047da <fileread+0xba>
    800047ae:	0792                	slli	a5,a5,0x4
    800047b0:	0001d717          	auipc	a4,0x1d
    800047b4:	d6870713          	addi	a4,a4,-664 # 80021518 <devsw>
    800047b8:	97ba                	add	a5,a5,a4
    800047ba:	639c                	ld	a5,0(a5)
    800047bc:	c38d                	beqz	a5,800047de <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047be:	4505                	li	a0,1
    800047c0:	9782                	jalr	a5
    800047c2:	892a                	mv	s2,a0
    800047c4:	bf75                	j	80004780 <fileread+0x60>
    panic("fileread");
    800047c6:	00004517          	auipc	a0,0x4
    800047ca:	fba50513          	addi	a0,a0,-70 # 80008780 <syscalls+0x260>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>
    return -1;
    800047d6:	597d                	li	s2,-1
    800047d8:	b765                	j	80004780 <fileread+0x60>
      return -1;
    800047da:	597d                	li	s2,-1
    800047dc:	b755                	j	80004780 <fileread+0x60>
    800047de:	597d                	li	s2,-1
    800047e0:	b745                	j	80004780 <fileread+0x60>

00000000800047e2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047e2:	715d                	addi	sp,sp,-80
    800047e4:	e486                	sd	ra,72(sp)
    800047e6:	e0a2                	sd	s0,64(sp)
    800047e8:	fc26                	sd	s1,56(sp)
    800047ea:	f84a                	sd	s2,48(sp)
    800047ec:	f44e                	sd	s3,40(sp)
    800047ee:	f052                	sd	s4,32(sp)
    800047f0:	ec56                	sd	s5,24(sp)
    800047f2:	e85a                	sd	s6,16(sp)
    800047f4:	e45e                	sd	s7,8(sp)
    800047f6:	e062                	sd	s8,0(sp)
    800047f8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047fa:	00954783          	lbu	a5,9(a0)
    800047fe:	10078663          	beqz	a5,8000490a <filewrite+0x128>
    80004802:	892a                	mv	s2,a0
    80004804:	8aae                	mv	s5,a1
    80004806:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004808:	411c                	lw	a5,0(a0)
    8000480a:	4705                	li	a4,1
    8000480c:	02e78263          	beq	a5,a4,80004830 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004810:	470d                	li	a4,3
    80004812:	02e78663          	beq	a5,a4,8000483e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004816:	4709                	li	a4,2
    80004818:	0ee79163          	bne	a5,a4,800048fa <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000481c:	0ac05d63          	blez	a2,800048d6 <filewrite+0xf4>
    int i = 0;
    80004820:	4981                	li	s3,0
    80004822:	6b05                	lui	s6,0x1
    80004824:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004828:	6b85                	lui	s7,0x1
    8000482a:	c00b8b9b          	addiw	s7,s7,-1024
    8000482e:	a861                	j	800048c6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004830:	6908                	ld	a0,16(a0)
    80004832:	00000097          	auipc	ra,0x0
    80004836:	22e080e7          	jalr	558(ra) # 80004a60 <pipewrite>
    8000483a:	8a2a                	mv	s4,a0
    8000483c:	a045                	j	800048dc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000483e:	02451783          	lh	a5,36(a0)
    80004842:	03079693          	slli	a3,a5,0x30
    80004846:	92c1                	srli	a3,a3,0x30
    80004848:	4725                	li	a4,9
    8000484a:	0cd76263          	bltu	a4,a3,8000490e <filewrite+0x12c>
    8000484e:	0792                	slli	a5,a5,0x4
    80004850:	0001d717          	auipc	a4,0x1d
    80004854:	cc870713          	addi	a4,a4,-824 # 80021518 <devsw>
    80004858:	97ba                	add	a5,a5,a4
    8000485a:	679c                	ld	a5,8(a5)
    8000485c:	cbdd                	beqz	a5,80004912 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000485e:	4505                	li	a0,1
    80004860:	9782                	jalr	a5
    80004862:	8a2a                	mv	s4,a0
    80004864:	a8a5                	j	800048dc <filewrite+0xfa>
    80004866:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	8b0080e7          	jalr	-1872(ra) # 8000411a <begin_op>
      ilock(f->ip);
    80004872:	01893503          	ld	a0,24(s2)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	ed2080e7          	jalr	-302(ra) # 80003748 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000487e:	8762                	mv	a4,s8
    80004880:	02092683          	lw	a3,32(s2)
    80004884:	01598633          	add	a2,s3,s5
    80004888:	4585                	li	a1,1
    8000488a:	01893503          	ld	a0,24(s2)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	266080e7          	jalr	614(ra) # 80003af4 <writei>
    80004896:	84aa                	mv	s1,a0
    80004898:	00a05763          	blez	a0,800048a6 <filewrite+0xc4>
        f->off += r;
    8000489c:	02092783          	lw	a5,32(s2)
    800048a0:	9fa9                	addw	a5,a5,a0
    800048a2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048a6:	01893503          	ld	a0,24(s2)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	f60080e7          	jalr	-160(ra) # 8000380a <iunlock>
      end_op();
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	8e8080e7          	jalr	-1816(ra) # 8000419a <end_op>

      if(r != n1){
    800048ba:	009c1f63          	bne	s8,s1,800048d8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048be:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048c2:	0149db63          	bge	s3,s4,800048d8 <filewrite+0xf6>
      int n1 = n - i;
    800048c6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048ca:	84be                	mv	s1,a5
    800048cc:	2781                	sext.w	a5,a5
    800048ce:	f8fb5ce3          	bge	s6,a5,80004866 <filewrite+0x84>
    800048d2:	84de                	mv	s1,s7
    800048d4:	bf49                	j	80004866 <filewrite+0x84>
    int i = 0;
    800048d6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048d8:	013a1f63          	bne	s4,s3,800048f6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048dc:	8552                	mv	a0,s4
    800048de:	60a6                	ld	ra,72(sp)
    800048e0:	6406                	ld	s0,64(sp)
    800048e2:	74e2                	ld	s1,56(sp)
    800048e4:	7942                	ld	s2,48(sp)
    800048e6:	79a2                	ld	s3,40(sp)
    800048e8:	7a02                	ld	s4,32(sp)
    800048ea:	6ae2                	ld	s5,24(sp)
    800048ec:	6b42                	ld	s6,16(sp)
    800048ee:	6ba2                	ld	s7,8(sp)
    800048f0:	6c02                	ld	s8,0(sp)
    800048f2:	6161                	addi	sp,sp,80
    800048f4:	8082                	ret
    ret = (i == n ? n : -1);
    800048f6:	5a7d                	li	s4,-1
    800048f8:	b7d5                	j	800048dc <filewrite+0xfa>
    panic("filewrite");
    800048fa:	00004517          	auipc	a0,0x4
    800048fe:	e9650513          	addi	a0,a0,-362 # 80008790 <syscalls+0x270>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>
    return -1;
    8000490a:	5a7d                	li	s4,-1
    8000490c:	bfc1                	j	800048dc <filewrite+0xfa>
      return -1;
    8000490e:	5a7d                	li	s4,-1
    80004910:	b7f1                	j	800048dc <filewrite+0xfa>
    80004912:	5a7d                	li	s4,-1
    80004914:	b7e1                	j	800048dc <filewrite+0xfa>

0000000080004916 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004916:	7179                	addi	sp,sp,-48
    80004918:	f406                	sd	ra,40(sp)
    8000491a:	f022                	sd	s0,32(sp)
    8000491c:	ec26                	sd	s1,24(sp)
    8000491e:	e84a                	sd	s2,16(sp)
    80004920:	e44e                	sd	s3,8(sp)
    80004922:	e052                	sd	s4,0(sp)
    80004924:	1800                	addi	s0,sp,48
    80004926:	84aa                	mv	s1,a0
    80004928:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000492a:	0005b023          	sd	zero,0(a1)
    8000492e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004932:	00000097          	auipc	ra,0x0
    80004936:	bf8080e7          	jalr	-1032(ra) # 8000452a <filealloc>
    8000493a:	e088                	sd	a0,0(s1)
    8000493c:	c551                	beqz	a0,800049c8 <pipealloc+0xb2>
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	bec080e7          	jalr	-1044(ra) # 8000452a <filealloc>
    80004946:	00aa3023          	sd	a0,0(s4)
    8000494a:	c92d                	beqz	a0,800049bc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	1a8080e7          	jalr	424(ra) # 80000af4 <kalloc>
    80004954:	892a                	mv	s2,a0
    80004956:	c125                	beqz	a0,800049b6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004958:	4985                	li	s3,1
    8000495a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000495e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004962:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004966:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000496a:	00004597          	auipc	a1,0x4
    8000496e:	b0e58593          	addi	a1,a1,-1266 # 80008478 <states.1712+0x1b8>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	1e2080e7          	jalr	482(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000497a:	609c                	ld	a5,0(s1)
    8000497c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004980:	609c                	ld	a5,0(s1)
    80004982:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004986:	609c                	ld	a5,0(s1)
    80004988:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000498c:	609c                	ld	a5,0(s1)
    8000498e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004992:	000a3783          	ld	a5,0(s4)
    80004996:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000499a:	000a3783          	ld	a5,0(s4)
    8000499e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049a2:	000a3783          	ld	a5,0(s4)
    800049a6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049aa:	000a3783          	ld	a5,0(s4)
    800049ae:	0127b823          	sd	s2,16(a5)
  return 0;
    800049b2:	4501                	li	a0,0
    800049b4:	a025                	j	800049dc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049b6:	6088                	ld	a0,0(s1)
    800049b8:	e501                	bnez	a0,800049c0 <pipealloc+0xaa>
    800049ba:	a039                	j	800049c8 <pipealloc+0xb2>
    800049bc:	6088                	ld	a0,0(s1)
    800049be:	c51d                	beqz	a0,800049ec <pipealloc+0xd6>
    fileclose(*f0);
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	c26080e7          	jalr	-986(ra) # 800045e6 <fileclose>
  if(*f1)
    800049c8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049cc:	557d                	li	a0,-1
  if(*f1)
    800049ce:	c799                	beqz	a5,800049dc <pipealloc+0xc6>
    fileclose(*f1);
    800049d0:	853e                	mv	a0,a5
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	c14080e7          	jalr	-1004(ra) # 800045e6 <fileclose>
  return -1;
    800049da:	557d                	li	a0,-1
}
    800049dc:	70a2                	ld	ra,40(sp)
    800049de:	7402                	ld	s0,32(sp)
    800049e0:	64e2                	ld	s1,24(sp)
    800049e2:	6942                	ld	s2,16(sp)
    800049e4:	69a2                	ld	s3,8(sp)
    800049e6:	6a02                	ld	s4,0(sp)
    800049e8:	6145                	addi	sp,sp,48
    800049ea:	8082                	ret
  return -1;
    800049ec:	557d                	li	a0,-1
    800049ee:	b7fd                	j	800049dc <pipealloc+0xc6>

00000000800049f0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049f0:	1101                	addi	sp,sp,-32
    800049f2:	ec06                	sd	ra,24(sp)
    800049f4:	e822                	sd	s0,16(sp)
    800049f6:	e426                	sd	s1,8(sp)
    800049f8:	e04a                	sd	s2,0(sp)
    800049fa:	1000                	addi	s0,sp,32
    800049fc:	84aa                	mv	s1,a0
    800049fe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	1e4080e7          	jalr	484(ra) # 80000be4 <acquire>
  if(writable){
    80004a08:	02090d63          	beqz	s2,80004a42 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a0c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a10:	21848513          	addi	a0,s1,536
    80004a14:	ffffd097          	auipc	ra,0xffffd
    80004a18:	7ec080e7          	jalr	2028(ra) # 80002200 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a1c:	2204b783          	ld	a5,544(s1)
    80004a20:	eb95                	bnez	a5,80004a54 <pipeclose+0x64>
    release(&pi->lock);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	274080e7          	jalr	628(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	fca080e7          	jalr	-54(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a36:	60e2                	ld	ra,24(sp)
    80004a38:	6442                	ld	s0,16(sp)
    80004a3a:	64a2                	ld	s1,8(sp)
    80004a3c:	6902                	ld	s2,0(sp)
    80004a3e:	6105                	addi	sp,sp,32
    80004a40:	8082                	ret
    pi->readopen = 0;
    80004a42:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a46:	21c48513          	addi	a0,s1,540
    80004a4a:	ffffd097          	auipc	ra,0xffffd
    80004a4e:	7b6080e7          	jalr	1974(ra) # 80002200 <wakeup>
    80004a52:	b7e9                	j	80004a1c <pipeclose+0x2c>
    release(&pi->lock);
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	242080e7          	jalr	578(ra) # 80000c98 <release>
}
    80004a5e:	bfe1                	j	80004a36 <pipeclose+0x46>

0000000080004a60 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a60:	7159                	addi	sp,sp,-112
    80004a62:	f486                	sd	ra,104(sp)
    80004a64:	f0a2                	sd	s0,96(sp)
    80004a66:	eca6                	sd	s1,88(sp)
    80004a68:	e8ca                	sd	s2,80(sp)
    80004a6a:	e4ce                	sd	s3,72(sp)
    80004a6c:	e0d2                	sd	s4,64(sp)
    80004a6e:	fc56                	sd	s5,56(sp)
    80004a70:	f85a                	sd	s6,48(sp)
    80004a72:	f45e                	sd	s7,40(sp)
    80004a74:	f062                	sd	s8,32(sp)
    80004a76:	ec66                	sd	s9,24(sp)
    80004a78:	1880                	addi	s0,sp,112
    80004a7a:	84aa                	mv	s1,a0
    80004a7c:	8aae                	mv	s5,a1
    80004a7e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	f30080e7          	jalr	-208(ra) # 800019b0 <myproc>
    80004a88:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	158080e7          	jalr	344(ra) # 80000be4 <acquire>
  while(i < n){
    80004a94:	0d405163          	blez	s4,80004b56 <pipewrite+0xf6>
    80004a98:	8ba6                	mv	s7,s1
  int i = 0;
    80004a9a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a9c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a9e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aa2:	21c48c13          	addi	s8,s1,540
    80004aa6:	a08d                	j	80004b08 <pipewrite+0xa8>
      release(&pi->lock);
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	1ee080e7          	jalr	494(ra) # 80000c98 <release>
      return -1;
    80004ab2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	70a6                	ld	ra,104(sp)
    80004ab8:	7406                	ld	s0,96(sp)
    80004aba:	64e6                	ld	s1,88(sp)
    80004abc:	6946                	ld	s2,80(sp)
    80004abe:	69a6                	ld	s3,72(sp)
    80004ac0:	6a06                	ld	s4,64(sp)
    80004ac2:	7ae2                	ld	s5,56(sp)
    80004ac4:	7b42                	ld	s6,48(sp)
    80004ac6:	7ba2                	ld	s7,40(sp)
    80004ac8:	7c02                	ld	s8,32(sp)
    80004aca:	6ce2                	ld	s9,24(sp)
    80004acc:	6165                	addi	sp,sp,112
    80004ace:	8082                	ret
      wakeup(&pi->nread);
    80004ad0:	8566                	mv	a0,s9
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	72e080e7          	jalr	1838(ra) # 80002200 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ada:	85de                	mv	a1,s7
    80004adc:	8562                	mv	a0,s8
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	596080e7          	jalr	1430(ra) # 80002074 <sleep>
    80004ae6:	a839                	j	80004b04 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ae8:	21c4a783          	lw	a5,540(s1)
    80004aec:	0017871b          	addiw	a4,a5,1
    80004af0:	20e4ae23          	sw	a4,540(s1)
    80004af4:	1ff7f793          	andi	a5,a5,511
    80004af8:	97a6                	add	a5,a5,s1
    80004afa:	f9f44703          	lbu	a4,-97(s0)
    80004afe:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b02:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b04:	03495d63          	bge	s2,s4,80004b3e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b08:	2204a783          	lw	a5,544(s1)
    80004b0c:	dfd1                	beqz	a5,80004aa8 <pipewrite+0x48>
    80004b0e:	0289a783          	lw	a5,40(s3)
    80004b12:	fbd9                	bnez	a5,80004aa8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b14:	2184a783          	lw	a5,536(s1)
    80004b18:	21c4a703          	lw	a4,540(s1)
    80004b1c:	2007879b          	addiw	a5,a5,512
    80004b20:	faf708e3          	beq	a4,a5,80004ad0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b24:	4685                	li	a3,1
    80004b26:	01590633          	add	a2,s2,s5
    80004b2a:	f9f40593          	addi	a1,s0,-97
    80004b2e:	0509b503          	ld	a0,80(s3)
    80004b32:	ffffd097          	auipc	ra,0xffffd
    80004b36:	bcc080e7          	jalr	-1076(ra) # 800016fe <copyin>
    80004b3a:	fb6517e3          	bne	a0,s6,80004ae8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b3e:	21848513          	addi	a0,s1,536
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	6be080e7          	jalr	1726(ra) # 80002200 <wakeup>
  release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	14c080e7          	jalr	332(ra) # 80000c98 <release>
  return i;
    80004b54:	b785                	j	80004ab4 <pipewrite+0x54>
  int i = 0;
    80004b56:	4901                	li	s2,0
    80004b58:	b7dd                	j	80004b3e <pipewrite+0xde>

0000000080004b5a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b5a:	715d                	addi	sp,sp,-80
    80004b5c:	e486                	sd	ra,72(sp)
    80004b5e:	e0a2                	sd	s0,64(sp)
    80004b60:	fc26                	sd	s1,56(sp)
    80004b62:	f84a                	sd	s2,48(sp)
    80004b64:	f44e                	sd	s3,40(sp)
    80004b66:	f052                	sd	s4,32(sp)
    80004b68:	ec56                	sd	s5,24(sp)
    80004b6a:	e85a                	sd	s6,16(sp)
    80004b6c:	0880                	addi	s0,sp,80
    80004b6e:	84aa                	mv	s1,a0
    80004b70:	892e                	mv	s2,a1
    80004b72:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b74:	ffffd097          	auipc	ra,0xffffd
    80004b78:	e3c080e7          	jalr	-452(ra) # 800019b0 <myproc>
    80004b7c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b7e:	8b26                	mv	s6,s1
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	062080e7          	jalr	98(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8a:	2184a703          	lw	a4,536(s1)
    80004b8e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b92:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b96:	02f71463          	bne	a4,a5,80004bbe <piperead+0x64>
    80004b9a:	2244a783          	lw	a5,548(s1)
    80004b9e:	c385                	beqz	a5,80004bbe <piperead+0x64>
    if(pr->killed){
    80004ba0:	028a2783          	lw	a5,40(s4)
    80004ba4:	ebc1                	bnez	a5,80004c34 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ba6:	85da                	mv	a1,s6
    80004ba8:	854e                	mv	a0,s3
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	4ca080e7          	jalr	1226(ra) # 80002074 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb2:	2184a703          	lw	a4,536(s1)
    80004bb6:	21c4a783          	lw	a5,540(s1)
    80004bba:	fef700e3          	beq	a4,a5,80004b9a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bbe:	09505263          	blez	s5,80004c42 <piperead+0xe8>
    80004bc2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bc6:	2184a783          	lw	a5,536(s1)
    80004bca:	21c4a703          	lw	a4,540(s1)
    80004bce:	02f70d63          	beq	a4,a5,80004c08 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bd2:	0017871b          	addiw	a4,a5,1
    80004bd6:	20e4ac23          	sw	a4,536(s1)
    80004bda:	1ff7f793          	andi	a5,a5,511
    80004bde:	97a6                	add	a5,a5,s1
    80004be0:	0187c783          	lbu	a5,24(a5)
    80004be4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be8:	4685                	li	a3,1
    80004bea:	fbf40613          	addi	a2,s0,-65
    80004bee:	85ca                	mv	a1,s2
    80004bf0:	050a3503          	ld	a0,80(s4)
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	a7e080e7          	jalr	-1410(ra) # 80001672 <copyout>
    80004bfc:	01650663          	beq	a0,s6,80004c08 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c00:	2985                	addiw	s3,s3,1
    80004c02:	0905                	addi	s2,s2,1
    80004c04:	fd3a91e3          	bne	s5,s3,80004bc6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c08:	21c48513          	addi	a0,s1,540
    80004c0c:	ffffd097          	auipc	ra,0xffffd
    80004c10:	5f4080e7          	jalr	1524(ra) # 80002200 <wakeup>
  release(&pi->lock);
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	082080e7          	jalr	130(ra) # 80000c98 <release>
  return i;
}
    80004c1e:	854e                	mv	a0,s3
    80004c20:	60a6                	ld	ra,72(sp)
    80004c22:	6406                	ld	s0,64(sp)
    80004c24:	74e2                	ld	s1,56(sp)
    80004c26:	7942                	ld	s2,48(sp)
    80004c28:	79a2                	ld	s3,40(sp)
    80004c2a:	7a02                	ld	s4,32(sp)
    80004c2c:	6ae2                	ld	s5,24(sp)
    80004c2e:	6b42                	ld	s6,16(sp)
    80004c30:	6161                	addi	sp,sp,80
    80004c32:	8082                	ret
      release(&pi->lock);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	062080e7          	jalr	98(ra) # 80000c98 <release>
      return -1;
    80004c3e:	59fd                	li	s3,-1
    80004c40:	bff9                	j	80004c1e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c42:	4981                	li	s3,0
    80004c44:	b7d1                	j	80004c08 <piperead+0xae>

0000000080004c46 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c46:	df010113          	addi	sp,sp,-528
    80004c4a:	20113423          	sd	ra,520(sp)
    80004c4e:	20813023          	sd	s0,512(sp)
    80004c52:	ffa6                	sd	s1,504(sp)
    80004c54:	fbca                	sd	s2,496(sp)
    80004c56:	f7ce                	sd	s3,488(sp)
    80004c58:	f3d2                	sd	s4,480(sp)
    80004c5a:	efd6                	sd	s5,472(sp)
    80004c5c:	ebda                	sd	s6,464(sp)
    80004c5e:	e7de                	sd	s7,456(sp)
    80004c60:	e3e2                	sd	s8,448(sp)
    80004c62:	ff66                	sd	s9,440(sp)
    80004c64:	fb6a                	sd	s10,432(sp)
    80004c66:	f76e                	sd	s11,424(sp)
    80004c68:	0c00                	addi	s0,sp,528
    80004c6a:	84aa                	mv	s1,a0
    80004c6c:	dea43c23          	sd	a0,-520(s0)
    80004c70:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	d3c080e7          	jalr	-708(ra) # 800019b0 <myproc>
    80004c7c:	892a                	mv	s2,a0

  begin_op();
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	49c080e7          	jalr	1180(ra) # 8000411a <begin_op>

  if((ip = namei(path)) == 0){
    80004c86:	8526                	mv	a0,s1
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	276080e7          	jalr	630(ra) # 80003efe <namei>
    80004c90:	c92d                	beqz	a0,80004d02 <exec+0xbc>
    80004c92:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	ab4080e7          	jalr	-1356(ra) # 80003748 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c9c:	04000713          	li	a4,64
    80004ca0:	4681                	li	a3,0
    80004ca2:	e5040613          	addi	a2,s0,-432
    80004ca6:	4581                	li	a1,0
    80004ca8:	8526                	mv	a0,s1
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	d52080e7          	jalr	-686(ra) # 800039fc <readi>
    80004cb2:	04000793          	li	a5,64
    80004cb6:	00f51a63          	bne	a0,a5,80004cca <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cba:	e5042703          	lw	a4,-432(s0)
    80004cbe:	464c47b7          	lui	a5,0x464c4
    80004cc2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc6:	04f70463          	beq	a4,a5,80004d0e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	cde080e7          	jalr	-802(ra) # 800039aa <iunlockput>
    end_op();
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	4c6080e7          	jalr	1222(ra) # 8000419a <end_op>
  }
  return -1;
    80004cdc:	557d                	li	a0,-1
}
    80004cde:	20813083          	ld	ra,520(sp)
    80004ce2:	20013403          	ld	s0,512(sp)
    80004ce6:	74fe                	ld	s1,504(sp)
    80004ce8:	795e                	ld	s2,496(sp)
    80004cea:	79be                	ld	s3,488(sp)
    80004cec:	7a1e                	ld	s4,480(sp)
    80004cee:	6afe                	ld	s5,472(sp)
    80004cf0:	6b5e                	ld	s6,464(sp)
    80004cf2:	6bbe                	ld	s7,456(sp)
    80004cf4:	6c1e                	ld	s8,448(sp)
    80004cf6:	7cfa                	ld	s9,440(sp)
    80004cf8:	7d5a                	ld	s10,432(sp)
    80004cfa:	7dba                	ld	s11,424(sp)
    80004cfc:	21010113          	addi	sp,sp,528
    80004d00:	8082                	ret
    end_op();
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	498080e7          	jalr	1176(ra) # 8000419a <end_op>
    return -1;
    80004d0a:	557d                	li	a0,-1
    80004d0c:	bfc9                	j	80004cde <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d0e:	854a                	mv	a0,s2
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	d64080e7          	jalr	-668(ra) # 80001a74 <proc_pagetable>
    80004d18:	8baa                	mv	s7,a0
    80004d1a:	d945                	beqz	a0,80004cca <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1c:	e7042983          	lw	s3,-400(s0)
    80004d20:	e8845783          	lhu	a5,-376(s0)
    80004d24:	c7ad                	beqz	a5,80004d8e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d26:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d28:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d2a:	6c85                	lui	s9,0x1
    80004d2c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d30:	def43823          	sd	a5,-528(s0)
    80004d34:	a42d                	j	80004f5e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d36:	00004517          	auipc	a0,0x4
    80004d3a:	a6a50513          	addi	a0,a0,-1430 # 800087a0 <syscalls+0x280>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	800080e7          	jalr	-2048(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d46:	8756                	mv	a4,s5
    80004d48:	012d86bb          	addw	a3,s11,s2
    80004d4c:	4581                	li	a1,0
    80004d4e:	8526                	mv	a0,s1
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	cac080e7          	jalr	-852(ra) # 800039fc <readi>
    80004d58:	2501                	sext.w	a0,a0
    80004d5a:	1aaa9963          	bne	s5,a0,80004f0c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d5e:	6785                	lui	a5,0x1
    80004d60:	0127893b          	addw	s2,a5,s2
    80004d64:	77fd                	lui	a5,0xfffff
    80004d66:	01478a3b          	addw	s4,a5,s4
    80004d6a:	1f897163          	bgeu	s2,s8,80004f4c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d6e:	02091593          	slli	a1,s2,0x20
    80004d72:	9181                	srli	a1,a1,0x20
    80004d74:	95ea                	add	a1,a1,s10
    80004d76:	855e                	mv	a0,s7
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	2f6080e7          	jalr	758(ra) # 8000106e <walkaddr>
    80004d80:	862a                	mv	a2,a0
    if(pa == 0)
    80004d82:	d955                	beqz	a0,80004d36 <exec+0xf0>
      n = PGSIZE;
    80004d84:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d86:	fd9a70e3          	bgeu	s4,s9,80004d46 <exec+0x100>
      n = sz - i;
    80004d8a:	8ad2                	mv	s5,s4
    80004d8c:	bf6d                	j	80004d46 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d8e:	4901                	li	s2,0
  iunlockput(ip);
    80004d90:	8526                	mv	a0,s1
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	c18080e7          	jalr	-1000(ra) # 800039aa <iunlockput>
  end_op();
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	400080e7          	jalr	1024(ra) # 8000419a <end_op>
  p = myproc();
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	c0e080e7          	jalr	-1010(ra) # 800019b0 <myproc>
    80004daa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dac:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004db0:	6785                	lui	a5,0x1
    80004db2:	17fd                	addi	a5,a5,-1
    80004db4:	993e                	add	s2,s2,a5
    80004db6:	757d                	lui	a0,0xfffff
    80004db8:	00a977b3          	and	a5,s2,a0
    80004dbc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dc0:	6609                	lui	a2,0x2
    80004dc2:	963e                	add	a2,a2,a5
    80004dc4:	85be                	mv	a1,a5
    80004dc6:	855e                	mv	a0,s7
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	65a080e7          	jalr	1626(ra) # 80001422 <uvmalloc>
    80004dd0:	8b2a                	mv	s6,a0
  ip = 0;
    80004dd2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dd4:	12050c63          	beqz	a0,80004f0c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dd8:	75f9                	lui	a1,0xffffe
    80004dda:	95aa                	add	a1,a1,a0
    80004ddc:	855e                	mv	a0,s7
    80004dde:	ffffd097          	auipc	ra,0xffffd
    80004de2:	862080e7          	jalr	-1950(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004de6:	7c7d                	lui	s8,0xfffff
    80004de8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dea:	e0043783          	ld	a5,-512(s0)
    80004dee:	6388                	ld	a0,0(a5)
    80004df0:	c535                	beqz	a0,80004e5c <exec+0x216>
    80004df2:	e9040993          	addi	s3,s0,-368
    80004df6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dfa:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	068080e7          	jalr	104(ra) # 80000e64 <strlen>
    80004e04:	2505                	addiw	a0,a0,1
    80004e06:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e0a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e0e:	13896363          	bltu	s2,s8,80004f34 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e12:	e0043d83          	ld	s11,-512(s0)
    80004e16:	000dba03          	ld	s4,0(s11)
    80004e1a:	8552                	mv	a0,s4
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	048080e7          	jalr	72(ra) # 80000e64 <strlen>
    80004e24:	0015069b          	addiw	a3,a0,1
    80004e28:	8652                	mv	a2,s4
    80004e2a:	85ca                	mv	a1,s2
    80004e2c:	855e                	mv	a0,s7
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	844080e7          	jalr	-1980(ra) # 80001672 <copyout>
    80004e36:	10054363          	bltz	a0,80004f3c <exec+0x2f6>
    ustack[argc] = sp;
    80004e3a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e3e:	0485                	addi	s1,s1,1
    80004e40:	008d8793          	addi	a5,s11,8
    80004e44:	e0f43023          	sd	a5,-512(s0)
    80004e48:	008db503          	ld	a0,8(s11)
    80004e4c:	c911                	beqz	a0,80004e60 <exec+0x21a>
    if(argc >= MAXARG)
    80004e4e:	09a1                	addi	s3,s3,8
    80004e50:	fb3c96e3          	bne	s9,s3,80004dfc <exec+0x1b6>
  sz = sz1;
    80004e54:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e58:	4481                	li	s1,0
    80004e5a:	a84d                	j	80004f0c <exec+0x2c6>
  sp = sz;
    80004e5c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e5e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e60:	00349793          	slli	a5,s1,0x3
    80004e64:	f9040713          	addi	a4,s0,-112
    80004e68:	97ba                	add	a5,a5,a4
    80004e6a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e6e:	00148693          	addi	a3,s1,1
    80004e72:	068e                	slli	a3,a3,0x3
    80004e74:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e78:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e7c:	01897663          	bgeu	s2,s8,80004e88 <exec+0x242>
  sz = sz1;
    80004e80:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e84:	4481                	li	s1,0
    80004e86:	a059                	j	80004f0c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e88:	e9040613          	addi	a2,s0,-368
    80004e8c:	85ca                	mv	a1,s2
    80004e8e:	855e                	mv	a0,s7
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	7e2080e7          	jalr	2018(ra) # 80001672 <copyout>
    80004e98:	0a054663          	bltz	a0,80004f44 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e9c:	058ab783          	ld	a5,88(s5)
    80004ea0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ea4:	df843783          	ld	a5,-520(s0)
    80004ea8:	0007c703          	lbu	a4,0(a5)
    80004eac:	cf11                	beqz	a4,80004ec8 <exec+0x282>
    80004eae:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eb0:	02f00693          	li	a3,47
    80004eb4:	a039                	j	80004ec2 <exec+0x27c>
      last = s+1;
    80004eb6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004eba:	0785                	addi	a5,a5,1
    80004ebc:	fff7c703          	lbu	a4,-1(a5)
    80004ec0:	c701                	beqz	a4,80004ec8 <exec+0x282>
    if(*s == '/')
    80004ec2:	fed71ce3          	bne	a4,a3,80004eba <exec+0x274>
    80004ec6:	bfc5                	j	80004eb6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ec8:	4641                	li	a2,16
    80004eca:	df843583          	ld	a1,-520(s0)
    80004ece:	158a8513          	addi	a0,s5,344
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	f60080e7          	jalr	-160(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eda:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ede:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ee2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ee6:	058ab783          	ld	a5,88(s5)
    80004eea:	e6843703          	ld	a4,-408(s0)
    80004eee:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ef0:	058ab783          	ld	a5,88(s5)
    80004ef4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ef8:	85ea                	mv	a1,s10
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	c16080e7          	jalr	-1002(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f02:	0004851b          	sext.w	a0,s1
    80004f06:	bbe1                	j	80004cde <exec+0x98>
    80004f08:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f0c:	e0843583          	ld	a1,-504(s0)
    80004f10:	855e                	mv	a0,s7
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	bfe080e7          	jalr	-1026(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004f1a:	da0498e3          	bnez	s1,80004cca <exec+0x84>
  return -1;
    80004f1e:	557d                	li	a0,-1
    80004f20:	bb7d                	j	80004cde <exec+0x98>
    80004f22:	e1243423          	sd	s2,-504(s0)
    80004f26:	b7dd                	j	80004f0c <exec+0x2c6>
    80004f28:	e1243423          	sd	s2,-504(s0)
    80004f2c:	b7c5                	j	80004f0c <exec+0x2c6>
    80004f2e:	e1243423          	sd	s2,-504(s0)
    80004f32:	bfe9                	j	80004f0c <exec+0x2c6>
  sz = sz1;
    80004f34:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f38:	4481                	li	s1,0
    80004f3a:	bfc9                	j	80004f0c <exec+0x2c6>
  sz = sz1;
    80004f3c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f40:	4481                	li	s1,0
    80004f42:	b7e9                	j	80004f0c <exec+0x2c6>
  sz = sz1;
    80004f44:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f48:	4481                	li	s1,0
    80004f4a:	b7c9                	j	80004f0c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f4c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f50:	2b05                	addiw	s6,s6,1
    80004f52:	0389899b          	addiw	s3,s3,56
    80004f56:	e8845783          	lhu	a5,-376(s0)
    80004f5a:	e2fb5be3          	bge	s6,a5,80004d90 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f5e:	2981                	sext.w	s3,s3
    80004f60:	03800713          	li	a4,56
    80004f64:	86ce                	mv	a3,s3
    80004f66:	e1840613          	addi	a2,s0,-488
    80004f6a:	4581                	li	a1,0
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	fffff097          	auipc	ra,0xfffff
    80004f72:	a8e080e7          	jalr	-1394(ra) # 800039fc <readi>
    80004f76:	03800793          	li	a5,56
    80004f7a:	f8f517e3          	bne	a0,a5,80004f08 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f7e:	e1842783          	lw	a5,-488(s0)
    80004f82:	4705                	li	a4,1
    80004f84:	fce796e3          	bne	a5,a4,80004f50 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f88:	e4043603          	ld	a2,-448(s0)
    80004f8c:	e3843783          	ld	a5,-456(s0)
    80004f90:	f8f669e3          	bltu	a2,a5,80004f22 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f94:	e2843783          	ld	a5,-472(s0)
    80004f98:	963e                	add	a2,a2,a5
    80004f9a:	f8f667e3          	bltu	a2,a5,80004f28 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f9e:	85ca                	mv	a1,s2
    80004fa0:	855e                	mv	a0,s7
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	480080e7          	jalr	1152(ra) # 80001422 <uvmalloc>
    80004faa:	e0a43423          	sd	a0,-504(s0)
    80004fae:	d141                	beqz	a0,80004f2e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004fb0:	e2843d03          	ld	s10,-472(s0)
    80004fb4:	df043783          	ld	a5,-528(s0)
    80004fb8:	00fd77b3          	and	a5,s10,a5
    80004fbc:	fba1                	bnez	a5,80004f0c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fbe:	e2042d83          	lw	s11,-480(s0)
    80004fc2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fc6:	f80c03e3          	beqz	s8,80004f4c <exec+0x306>
    80004fca:	8a62                	mv	s4,s8
    80004fcc:	4901                	li	s2,0
    80004fce:	b345                	j	80004d6e <exec+0x128>

0000000080004fd0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fd0:	7179                	addi	sp,sp,-48
    80004fd2:	f406                	sd	ra,40(sp)
    80004fd4:	f022                	sd	s0,32(sp)
    80004fd6:	ec26                	sd	s1,24(sp)
    80004fd8:	e84a                	sd	s2,16(sp)
    80004fda:	1800                	addi	s0,sp,48
    80004fdc:	892e                	mv	s2,a1
    80004fde:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fe0:	fdc40593          	addi	a1,s0,-36
    80004fe4:	ffffe097          	auipc	ra,0xffffe
    80004fe8:	aa2080e7          	jalr	-1374(ra) # 80002a86 <argint>
    80004fec:	04054063          	bltz	a0,8000502c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ff0:	fdc42703          	lw	a4,-36(s0)
    80004ff4:	47bd                	li	a5,15
    80004ff6:	02e7ed63          	bltu	a5,a4,80005030 <argfd+0x60>
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	9b6080e7          	jalr	-1610(ra) # 800019b0 <myproc>
    80005002:	fdc42703          	lw	a4,-36(s0)
    80005006:	01a70793          	addi	a5,a4,26
    8000500a:	078e                	slli	a5,a5,0x3
    8000500c:	953e                	add	a0,a0,a5
    8000500e:	611c                	ld	a5,0(a0)
    80005010:	c395                	beqz	a5,80005034 <argfd+0x64>
    return -1;
  if(pfd)
    80005012:	00090463          	beqz	s2,8000501a <argfd+0x4a>
    *pfd = fd;
    80005016:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000501a:	4501                	li	a0,0
  if(pf)
    8000501c:	c091                	beqz	s1,80005020 <argfd+0x50>
    *pf = f;
    8000501e:	e09c                	sd	a5,0(s1)
}
    80005020:	70a2                	ld	ra,40(sp)
    80005022:	7402                	ld	s0,32(sp)
    80005024:	64e2                	ld	s1,24(sp)
    80005026:	6942                	ld	s2,16(sp)
    80005028:	6145                	addi	sp,sp,48
    8000502a:	8082                	ret
    return -1;
    8000502c:	557d                	li	a0,-1
    8000502e:	bfcd                	j	80005020 <argfd+0x50>
    return -1;
    80005030:	557d                	li	a0,-1
    80005032:	b7fd                	j	80005020 <argfd+0x50>
    80005034:	557d                	li	a0,-1
    80005036:	b7ed                	j	80005020 <argfd+0x50>

0000000080005038 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005038:	1101                	addi	sp,sp,-32
    8000503a:	ec06                	sd	ra,24(sp)
    8000503c:	e822                	sd	s0,16(sp)
    8000503e:	e426                	sd	s1,8(sp)
    80005040:	1000                	addi	s0,sp,32
    80005042:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	96c080e7          	jalr	-1684(ra) # 800019b0 <myproc>
    8000504c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000504e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005052:	4501                	li	a0,0
    80005054:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005056:	6398                	ld	a4,0(a5)
    80005058:	cb19                	beqz	a4,8000506e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000505a:	2505                	addiw	a0,a0,1
    8000505c:	07a1                	addi	a5,a5,8
    8000505e:	fed51ce3          	bne	a0,a3,80005056 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005062:	557d                	li	a0,-1
}
    80005064:	60e2                	ld	ra,24(sp)
    80005066:	6442                	ld	s0,16(sp)
    80005068:	64a2                	ld	s1,8(sp)
    8000506a:	6105                	addi	sp,sp,32
    8000506c:	8082                	ret
      p->ofile[fd] = f;
    8000506e:	01a50793          	addi	a5,a0,26
    80005072:	078e                	slli	a5,a5,0x3
    80005074:	963e                	add	a2,a2,a5
    80005076:	e204                	sd	s1,0(a2)
      return fd;
    80005078:	b7f5                	j	80005064 <fdalloc+0x2c>

000000008000507a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000507a:	715d                	addi	sp,sp,-80
    8000507c:	e486                	sd	ra,72(sp)
    8000507e:	e0a2                	sd	s0,64(sp)
    80005080:	fc26                	sd	s1,56(sp)
    80005082:	f84a                	sd	s2,48(sp)
    80005084:	f44e                	sd	s3,40(sp)
    80005086:	f052                	sd	s4,32(sp)
    80005088:	ec56                	sd	s5,24(sp)
    8000508a:	0880                	addi	s0,sp,80
    8000508c:	89ae                	mv	s3,a1
    8000508e:	8ab2                	mv	s5,a2
    80005090:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005092:	fb040593          	addi	a1,s0,-80
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	e86080e7          	jalr	-378(ra) # 80003f1c <nameiparent>
    8000509e:	892a                	mv	s2,a0
    800050a0:	12050f63          	beqz	a0,800051de <create+0x164>
    return 0;

  ilock(dp);
    800050a4:	ffffe097          	auipc	ra,0xffffe
    800050a8:	6a4080e7          	jalr	1700(ra) # 80003748 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050ac:	4601                	li	a2,0
    800050ae:	fb040593          	addi	a1,s0,-80
    800050b2:	854a                	mv	a0,s2
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	b78080e7          	jalr	-1160(ra) # 80003c2c <dirlookup>
    800050bc:	84aa                	mv	s1,a0
    800050be:	c921                	beqz	a0,8000510e <create+0x94>
    iunlockput(dp);
    800050c0:	854a                	mv	a0,s2
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	8e8080e7          	jalr	-1816(ra) # 800039aa <iunlockput>
    ilock(ip);
    800050ca:	8526                	mv	a0,s1
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	67c080e7          	jalr	1660(ra) # 80003748 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050d4:	2981                	sext.w	s3,s3
    800050d6:	4789                	li	a5,2
    800050d8:	02f99463          	bne	s3,a5,80005100 <create+0x86>
    800050dc:	0444d783          	lhu	a5,68(s1)
    800050e0:	37f9                	addiw	a5,a5,-2
    800050e2:	17c2                	slli	a5,a5,0x30
    800050e4:	93c1                	srli	a5,a5,0x30
    800050e6:	4705                	li	a4,1
    800050e8:	00f76c63          	bltu	a4,a5,80005100 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050ec:	8526                	mv	a0,s1
    800050ee:	60a6                	ld	ra,72(sp)
    800050f0:	6406                	ld	s0,64(sp)
    800050f2:	74e2                	ld	s1,56(sp)
    800050f4:	7942                	ld	s2,48(sp)
    800050f6:	79a2                	ld	s3,40(sp)
    800050f8:	7a02                	ld	s4,32(sp)
    800050fa:	6ae2                	ld	s5,24(sp)
    800050fc:	6161                	addi	sp,sp,80
    800050fe:	8082                	ret
    iunlockput(ip);
    80005100:	8526                	mv	a0,s1
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	8a8080e7          	jalr	-1880(ra) # 800039aa <iunlockput>
    return 0;
    8000510a:	4481                	li	s1,0
    8000510c:	b7c5                	j	800050ec <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000510e:	85ce                	mv	a1,s3
    80005110:	00092503          	lw	a0,0(s2)
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	49c080e7          	jalr	1180(ra) # 800035b0 <ialloc>
    8000511c:	84aa                	mv	s1,a0
    8000511e:	c529                	beqz	a0,80005168 <create+0xee>
  ilock(ip);
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	628080e7          	jalr	1576(ra) # 80003748 <ilock>
  ip->major = major;
    80005128:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000512c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005130:	4785                	li	a5,1
    80005132:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005136:	8526                	mv	a0,s1
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	546080e7          	jalr	1350(ra) # 8000367e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005140:	2981                	sext.w	s3,s3
    80005142:	4785                	li	a5,1
    80005144:	02f98a63          	beq	s3,a5,80005178 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005148:	40d0                	lw	a2,4(s1)
    8000514a:	fb040593          	addi	a1,s0,-80
    8000514e:	854a                	mv	a0,s2
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	cec080e7          	jalr	-788(ra) # 80003e3c <dirlink>
    80005158:	06054b63          	bltz	a0,800051ce <create+0x154>
  iunlockput(dp);
    8000515c:	854a                	mv	a0,s2
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	84c080e7          	jalr	-1972(ra) # 800039aa <iunlockput>
  return ip;
    80005166:	b759                	j	800050ec <create+0x72>
    panic("create: ialloc");
    80005168:	00003517          	auipc	a0,0x3
    8000516c:	65850513          	addi	a0,a0,1624 # 800087c0 <syscalls+0x2a0>
    80005170:	ffffb097          	auipc	ra,0xffffb
    80005174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005178:	04a95783          	lhu	a5,74(s2)
    8000517c:	2785                	addiw	a5,a5,1
    8000517e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005182:	854a                	mv	a0,s2
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	4fa080e7          	jalr	1274(ra) # 8000367e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000518c:	40d0                	lw	a2,4(s1)
    8000518e:	00003597          	auipc	a1,0x3
    80005192:	64258593          	addi	a1,a1,1602 # 800087d0 <syscalls+0x2b0>
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	ca4080e7          	jalr	-860(ra) # 80003e3c <dirlink>
    800051a0:	00054f63          	bltz	a0,800051be <create+0x144>
    800051a4:	00492603          	lw	a2,4(s2)
    800051a8:	00003597          	auipc	a1,0x3
    800051ac:	63058593          	addi	a1,a1,1584 # 800087d8 <syscalls+0x2b8>
    800051b0:	8526                	mv	a0,s1
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	c8a080e7          	jalr	-886(ra) # 80003e3c <dirlink>
    800051ba:	f80557e3          	bgez	a0,80005148 <create+0xce>
      panic("create dots");
    800051be:	00003517          	auipc	a0,0x3
    800051c2:	62250513          	addi	a0,a0,1570 # 800087e0 <syscalls+0x2c0>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
    panic("create: dirlink");
    800051ce:	00003517          	auipc	a0,0x3
    800051d2:	62250513          	addi	a0,a0,1570 # 800087f0 <syscalls+0x2d0>
    800051d6:	ffffb097          	auipc	ra,0xffffb
    800051da:	368080e7          	jalr	872(ra) # 8000053e <panic>
    return 0;
    800051de:	84aa                	mv	s1,a0
    800051e0:	b731                	j	800050ec <create+0x72>

00000000800051e2 <sys_dup>:
{
    800051e2:	7179                	addi	sp,sp,-48
    800051e4:	f406                	sd	ra,40(sp)
    800051e6:	f022                	sd	s0,32(sp)
    800051e8:	ec26                	sd	s1,24(sp)
    800051ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ec:	fd840613          	addi	a2,s0,-40
    800051f0:	4581                	li	a1,0
    800051f2:	4501                	li	a0,0
    800051f4:	00000097          	auipc	ra,0x0
    800051f8:	ddc080e7          	jalr	-548(ra) # 80004fd0 <argfd>
    return -1;
    800051fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051fe:	02054363          	bltz	a0,80005224 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005202:	fd843503          	ld	a0,-40(s0)
    80005206:	00000097          	auipc	ra,0x0
    8000520a:	e32080e7          	jalr	-462(ra) # 80005038 <fdalloc>
    8000520e:	84aa                	mv	s1,a0
    return -1;
    80005210:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005212:	00054963          	bltz	a0,80005224 <sys_dup+0x42>
  filedup(f);
    80005216:	fd843503          	ld	a0,-40(s0)
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	37a080e7          	jalr	890(ra) # 80004594 <filedup>
  return fd;
    80005222:	87a6                	mv	a5,s1
}
    80005224:	853e                	mv	a0,a5
    80005226:	70a2                	ld	ra,40(sp)
    80005228:	7402                	ld	s0,32(sp)
    8000522a:	64e2                	ld	s1,24(sp)
    8000522c:	6145                	addi	sp,sp,48
    8000522e:	8082                	ret

0000000080005230 <sys_read>:
{
    80005230:	7179                	addi	sp,sp,-48
    80005232:	f406                	sd	ra,40(sp)
    80005234:	f022                	sd	s0,32(sp)
    80005236:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005238:	fe840613          	addi	a2,s0,-24
    8000523c:	4581                	li	a1,0
    8000523e:	4501                	li	a0,0
    80005240:	00000097          	auipc	ra,0x0
    80005244:	d90080e7          	jalr	-624(ra) # 80004fd0 <argfd>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524a:	04054163          	bltz	a0,8000528c <sys_read+0x5c>
    8000524e:	fe440593          	addi	a1,s0,-28
    80005252:	4509                	li	a0,2
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	832080e7          	jalr	-1998(ra) # 80002a86 <argint>
    return -1;
    8000525c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525e:	02054763          	bltz	a0,8000528c <sys_read+0x5c>
    80005262:	fd840593          	addi	a1,s0,-40
    80005266:	4505                	li	a0,1
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	840080e7          	jalr	-1984(ra) # 80002aa8 <argaddr>
    return -1;
    80005270:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005272:	00054d63          	bltz	a0,8000528c <sys_read+0x5c>
  return fileread(f, p, n);
    80005276:	fe442603          	lw	a2,-28(s0)
    8000527a:	fd843583          	ld	a1,-40(s0)
    8000527e:	fe843503          	ld	a0,-24(s0)
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	49e080e7          	jalr	1182(ra) # 80004720 <fileread>
    8000528a:	87aa                	mv	a5,a0
}
    8000528c:	853e                	mv	a0,a5
    8000528e:	70a2                	ld	ra,40(sp)
    80005290:	7402                	ld	s0,32(sp)
    80005292:	6145                	addi	sp,sp,48
    80005294:	8082                	ret

0000000080005296 <sys_write>:
{
    80005296:	7179                	addi	sp,sp,-48
    80005298:	f406                	sd	ra,40(sp)
    8000529a:	f022                	sd	s0,32(sp)
    8000529c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529e:	fe840613          	addi	a2,s0,-24
    800052a2:	4581                	li	a1,0
    800052a4:	4501                	li	a0,0
    800052a6:	00000097          	auipc	ra,0x0
    800052aa:	d2a080e7          	jalr	-726(ra) # 80004fd0 <argfd>
    return -1;
    800052ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b0:	04054163          	bltz	a0,800052f2 <sys_write+0x5c>
    800052b4:	fe440593          	addi	a1,s0,-28
    800052b8:	4509                	li	a0,2
    800052ba:	ffffd097          	auipc	ra,0xffffd
    800052be:	7cc080e7          	jalr	1996(ra) # 80002a86 <argint>
    return -1;
    800052c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c4:	02054763          	bltz	a0,800052f2 <sys_write+0x5c>
    800052c8:	fd840593          	addi	a1,s0,-40
    800052cc:	4505                	li	a0,1
    800052ce:	ffffd097          	auipc	ra,0xffffd
    800052d2:	7da080e7          	jalr	2010(ra) # 80002aa8 <argaddr>
    return -1;
    800052d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d8:	00054d63          	bltz	a0,800052f2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052dc:	fe442603          	lw	a2,-28(s0)
    800052e0:	fd843583          	ld	a1,-40(s0)
    800052e4:	fe843503          	ld	a0,-24(s0)
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	4fa080e7          	jalr	1274(ra) # 800047e2 <filewrite>
    800052f0:	87aa                	mv	a5,a0
}
    800052f2:	853e                	mv	a0,a5
    800052f4:	70a2                	ld	ra,40(sp)
    800052f6:	7402                	ld	s0,32(sp)
    800052f8:	6145                	addi	sp,sp,48
    800052fa:	8082                	ret

00000000800052fc <sys_close>:
{
    800052fc:	1101                	addi	sp,sp,-32
    800052fe:	ec06                	sd	ra,24(sp)
    80005300:	e822                	sd	s0,16(sp)
    80005302:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005304:	fe040613          	addi	a2,s0,-32
    80005308:	fec40593          	addi	a1,s0,-20
    8000530c:	4501                	li	a0,0
    8000530e:	00000097          	auipc	ra,0x0
    80005312:	cc2080e7          	jalr	-830(ra) # 80004fd0 <argfd>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005318:	02054463          	bltz	a0,80005340 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	694080e7          	jalr	1684(ra) # 800019b0 <myproc>
    80005324:	fec42783          	lw	a5,-20(s0)
    80005328:	07e9                	addi	a5,a5,26
    8000532a:	078e                	slli	a5,a5,0x3
    8000532c:	97aa                	add	a5,a5,a0
    8000532e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005332:	fe043503          	ld	a0,-32(s0)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	2b0080e7          	jalr	688(ra) # 800045e6 <fileclose>
  return 0;
    8000533e:	4781                	li	a5,0
}
    80005340:	853e                	mv	a0,a5
    80005342:	60e2                	ld	ra,24(sp)
    80005344:	6442                	ld	s0,16(sp)
    80005346:	6105                	addi	sp,sp,32
    80005348:	8082                	ret

000000008000534a <sys_fstat>:
{
    8000534a:	1101                	addi	sp,sp,-32
    8000534c:	ec06                	sd	ra,24(sp)
    8000534e:	e822                	sd	s0,16(sp)
    80005350:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005352:	fe840613          	addi	a2,s0,-24
    80005356:	4581                	li	a1,0
    80005358:	4501                	li	a0,0
    8000535a:	00000097          	auipc	ra,0x0
    8000535e:	c76080e7          	jalr	-906(ra) # 80004fd0 <argfd>
    return -1;
    80005362:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005364:	02054563          	bltz	a0,8000538e <sys_fstat+0x44>
    80005368:	fe040593          	addi	a1,s0,-32
    8000536c:	4505                	li	a0,1
    8000536e:	ffffd097          	auipc	ra,0xffffd
    80005372:	73a080e7          	jalr	1850(ra) # 80002aa8 <argaddr>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005378:	00054b63          	bltz	a0,8000538e <sys_fstat+0x44>
  return filestat(f, st);
    8000537c:	fe043583          	ld	a1,-32(s0)
    80005380:	fe843503          	ld	a0,-24(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	32a080e7          	jalr	810(ra) # 800046ae <filestat>
    8000538c:	87aa                	mv	a5,a0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	60e2                	ld	ra,24(sp)
    80005392:	6442                	ld	s0,16(sp)
    80005394:	6105                	addi	sp,sp,32
    80005396:	8082                	ret

0000000080005398 <sys_link>:
{
    80005398:	7169                	addi	sp,sp,-304
    8000539a:	f606                	sd	ra,296(sp)
    8000539c:	f222                	sd	s0,288(sp)
    8000539e:	ee26                	sd	s1,280(sp)
    800053a0:	ea4a                	sd	s2,272(sp)
    800053a2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053a4:	08000613          	li	a2,128
    800053a8:	ed040593          	addi	a1,s0,-304
    800053ac:	4501                	li	a0,0
    800053ae:	ffffd097          	auipc	ra,0xffffd
    800053b2:	71c080e7          	jalr	1820(ra) # 80002aca <argstr>
    return -1;
    800053b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b8:	10054e63          	bltz	a0,800054d4 <sys_link+0x13c>
    800053bc:	08000613          	li	a2,128
    800053c0:	f5040593          	addi	a1,s0,-176
    800053c4:	4505                	li	a0,1
    800053c6:	ffffd097          	auipc	ra,0xffffd
    800053ca:	704080e7          	jalr	1796(ra) # 80002aca <argstr>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d0:	10054263          	bltz	a0,800054d4 <sys_link+0x13c>
  begin_op();
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	d46080e7          	jalr	-698(ra) # 8000411a <begin_op>
  if((ip = namei(old)) == 0){
    800053dc:	ed040513          	addi	a0,s0,-304
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	b1e080e7          	jalr	-1250(ra) # 80003efe <namei>
    800053e8:	84aa                	mv	s1,a0
    800053ea:	c551                	beqz	a0,80005476 <sys_link+0xde>
  ilock(ip);
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	35c080e7          	jalr	860(ra) # 80003748 <ilock>
  if(ip->type == T_DIR){
    800053f4:	04449703          	lh	a4,68(s1)
    800053f8:	4785                	li	a5,1
    800053fa:	08f70463          	beq	a4,a5,80005482 <sys_link+0xea>
  ip->nlink++;
    800053fe:	04a4d783          	lhu	a5,74(s1)
    80005402:	2785                	addiw	a5,a5,1
    80005404:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	274080e7          	jalr	628(ra) # 8000367e <iupdate>
  iunlock(ip);
    80005412:	8526                	mv	a0,s1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	3f6080e7          	jalr	1014(ra) # 8000380a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000541c:	fd040593          	addi	a1,s0,-48
    80005420:	f5040513          	addi	a0,s0,-176
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	af8080e7          	jalr	-1288(ra) # 80003f1c <nameiparent>
    8000542c:	892a                	mv	s2,a0
    8000542e:	c935                	beqz	a0,800054a2 <sys_link+0x10a>
  ilock(dp);
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	318080e7          	jalr	792(ra) # 80003748 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005438:	00092703          	lw	a4,0(s2)
    8000543c:	409c                	lw	a5,0(s1)
    8000543e:	04f71d63          	bne	a4,a5,80005498 <sys_link+0x100>
    80005442:	40d0                	lw	a2,4(s1)
    80005444:	fd040593          	addi	a1,s0,-48
    80005448:	854a                	mv	a0,s2
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	9f2080e7          	jalr	-1550(ra) # 80003e3c <dirlink>
    80005452:	04054363          	bltz	a0,80005498 <sys_link+0x100>
  iunlockput(dp);
    80005456:	854a                	mv	a0,s2
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	552080e7          	jalr	1362(ra) # 800039aa <iunlockput>
  iput(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	4a0080e7          	jalr	1184(ra) # 80003902 <iput>
  end_op();
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	d30080e7          	jalr	-720(ra) # 8000419a <end_op>
  return 0;
    80005472:	4781                	li	a5,0
    80005474:	a085                	j	800054d4 <sys_link+0x13c>
    end_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	d24080e7          	jalr	-732(ra) # 8000419a <end_op>
    return -1;
    8000547e:	57fd                	li	a5,-1
    80005480:	a891                	j	800054d4 <sys_link+0x13c>
    iunlockput(ip);
    80005482:	8526                	mv	a0,s1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	526080e7          	jalr	1318(ra) # 800039aa <iunlockput>
    end_op();
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	d0e080e7          	jalr	-754(ra) # 8000419a <end_op>
    return -1;
    80005494:	57fd                	li	a5,-1
    80005496:	a83d                	j	800054d4 <sys_link+0x13c>
    iunlockput(dp);
    80005498:	854a                	mv	a0,s2
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	510080e7          	jalr	1296(ra) # 800039aa <iunlockput>
  ilock(ip);
    800054a2:	8526                	mv	a0,s1
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	2a4080e7          	jalr	676(ra) # 80003748 <ilock>
  ip->nlink--;
    800054ac:	04a4d783          	lhu	a5,74(s1)
    800054b0:	37fd                	addiw	a5,a5,-1
    800054b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	1c6080e7          	jalr	454(ra) # 8000367e <iupdate>
  iunlockput(ip);
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	4e8080e7          	jalr	1256(ra) # 800039aa <iunlockput>
  end_op();
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	cd0080e7          	jalr	-816(ra) # 8000419a <end_op>
  return -1;
    800054d2:	57fd                	li	a5,-1
}
    800054d4:	853e                	mv	a0,a5
    800054d6:	70b2                	ld	ra,296(sp)
    800054d8:	7412                	ld	s0,288(sp)
    800054da:	64f2                	ld	s1,280(sp)
    800054dc:	6952                	ld	s2,272(sp)
    800054de:	6155                	addi	sp,sp,304
    800054e0:	8082                	ret

00000000800054e2 <sys_unlink>:
{
    800054e2:	7151                	addi	sp,sp,-240
    800054e4:	f586                	sd	ra,232(sp)
    800054e6:	f1a2                	sd	s0,224(sp)
    800054e8:	eda6                	sd	s1,216(sp)
    800054ea:	e9ca                	sd	s2,208(sp)
    800054ec:	e5ce                	sd	s3,200(sp)
    800054ee:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054f0:	08000613          	li	a2,128
    800054f4:	f3040593          	addi	a1,s0,-208
    800054f8:	4501                	li	a0,0
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	5d0080e7          	jalr	1488(ra) # 80002aca <argstr>
    80005502:	18054163          	bltz	a0,80005684 <sys_unlink+0x1a2>
  begin_op();
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	c14080e7          	jalr	-1004(ra) # 8000411a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000550e:	fb040593          	addi	a1,s0,-80
    80005512:	f3040513          	addi	a0,s0,-208
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	a06080e7          	jalr	-1530(ra) # 80003f1c <nameiparent>
    8000551e:	84aa                	mv	s1,a0
    80005520:	c979                	beqz	a0,800055f6 <sys_unlink+0x114>
  ilock(dp);
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	226080e7          	jalr	550(ra) # 80003748 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000552a:	00003597          	auipc	a1,0x3
    8000552e:	2a658593          	addi	a1,a1,678 # 800087d0 <syscalls+0x2b0>
    80005532:	fb040513          	addi	a0,s0,-80
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	6dc080e7          	jalr	1756(ra) # 80003c12 <namecmp>
    8000553e:	14050a63          	beqz	a0,80005692 <sys_unlink+0x1b0>
    80005542:	00003597          	auipc	a1,0x3
    80005546:	29658593          	addi	a1,a1,662 # 800087d8 <syscalls+0x2b8>
    8000554a:	fb040513          	addi	a0,s0,-80
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	6c4080e7          	jalr	1732(ra) # 80003c12 <namecmp>
    80005556:	12050e63          	beqz	a0,80005692 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000555a:	f2c40613          	addi	a2,s0,-212
    8000555e:	fb040593          	addi	a1,s0,-80
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	6c8080e7          	jalr	1736(ra) # 80003c2c <dirlookup>
    8000556c:	892a                	mv	s2,a0
    8000556e:	12050263          	beqz	a0,80005692 <sys_unlink+0x1b0>
  ilock(ip);
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	1d6080e7          	jalr	470(ra) # 80003748 <ilock>
  if(ip->nlink < 1)
    8000557a:	04a91783          	lh	a5,74(s2)
    8000557e:	08f05263          	blez	a5,80005602 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005582:	04491703          	lh	a4,68(s2)
    80005586:	4785                	li	a5,1
    80005588:	08f70563          	beq	a4,a5,80005612 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000558c:	4641                	li	a2,16
    8000558e:	4581                	li	a1,0
    80005590:	fc040513          	addi	a0,s0,-64
    80005594:	ffffb097          	auipc	ra,0xffffb
    80005598:	74c080e7          	jalr	1868(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000559c:	4741                	li	a4,16
    8000559e:	f2c42683          	lw	a3,-212(s0)
    800055a2:	fc040613          	addi	a2,s0,-64
    800055a6:	4581                	li	a1,0
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	54a080e7          	jalr	1354(ra) # 80003af4 <writei>
    800055b2:	47c1                	li	a5,16
    800055b4:	0af51563          	bne	a0,a5,8000565e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055b8:	04491703          	lh	a4,68(s2)
    800055bc:	4785                	li	a5,1
    800055be:	0af70863          	beq	a4,a5,8000566e <sys_unlink+0x18c>
  iunlockput(dp);
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	3e6080e7          	jalr	998(ra) # 800039aa <iunlockput>
  ip->nlink--;
    800055cc:	04a95783          	lhu	a5,74(s2)
    800055d0:	37fd                	addiw	a5,a5,-1
    800055d2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	0a6080e7          	jalr	166(ra) # 8000367e <iupdate>
  iunlockput(ip);
    800055e0:	854a                	mv	a0,s2
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	3c8080e7          	jalr	968(ra) # 800039aa <iunlockput>
  end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	bb0080e7          	jalr	-1104(ra) # 8000419a <end_op>
  return 0;
    800055f2:	4501                	li	a0,0
    800055f4:	a84d                	j	800056a6 <sys_unlink+0x1c4>
    end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	ba4080e7          	jalr	-1116(ra) # 8000419a <end_op>
    return -1;
    800055fe:	557d                	li	a0,-1
    80005600:	a05d                	j	800056a6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005602:	00003517          	auipc	a0,0x3
    80005606:	1fe50513          	addi	a0,a0,510 # 80008800 <syscalls+0x2e0>
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	f34080e7          	jalr	-204(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005612:	04c92703          	lw	a4,76(s2)
    80005616:	02000793          	li	a5,32
    8000561a:	f6e7f9e3          	bgeu	a5,a4,8000558c <sys_unlink+0xaa>
    8000561e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005622:	4741                	li	a4,16
    80005624:	86ce                	mv	a3,s3
    80005626:	f1840613          	addi	a2,s0,-232
    8000562a:	4581                	li	a1,0
    8000562c:	854a                	mv	a0,s2
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	3ce080e7          	jalr	974(ra) # 800039fc <readi>
    80005636:	47c1                	li	a5,16
    80005638:	00f51b63          	bne	a0,a5,8000564e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000563c:	f1845783          	lhu	a5,-232(s0)
    80005640:	e7a1                	bnez	a5,80005688 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005642:	29c1                	addiw	s3,s3,16
    80005644:	04c92783          	lw	a5,76(s2)
    80005648:	fcf9ede3          	bltu	s3,a5,80005622 <sys_unlink+0x140>
    8000564c:	b781                	j	8000558c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000564e:	00003517          	auipc	a0,0x3
    80005652:	1ca50513          	addi	a0,a0,458 # 80008818 <syscalls+0x2f8>
    80005656:	ffffb097          	auipc	ra,0xffffb
    8000565a:	ee8080e7          	jalr	-280(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000565e:	00003517          	auipc	a0,0x3
    80005662:	1d250513          	addi	a0,a0,466 # 80008830 <syscalls+0x310>
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>
    dp->nlink--;
    8000566e:	04a4d783          	lhu	a5,74(s1)
    80005672:	37fd                	addiw	a5,a5,-1
    80005674:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	004080e7          	jalr	4(ra) # 8000367e <iupdate>
    80005682:	b781                	j	800055c2 <sys_unlink+0xe0>
    return -1;
    80005684:	557d                	li	a0,-1
    80005686:	a005                	j	800056a6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	320080e7          	jalr	800(ra) # 800039aa <iunlockput>
  iunlockput(dp);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	316080e7          	jalr	790(ra) # 800039aa <iunlockput>
  end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	afe080e7          	jalr	-1282(ra) # 8000419a <end_op>
  return -1;
    800056a4:	557d                	li	a0,-1
}
    800056a6:	70ae                	ld	ra,232(sp)
    800056a8:	740e                	ld	s0,224(sp)
    800056aa:	64ee                	ld	s1,216(sp)
    800056ac:	694e                	ld	s2,208(sp)
    800056ae:	69ae                	ld	s3,200(sp)
    800056b0:	616d                	addi	sp,sp,240
    800056b2:	8082                	ret

00000000800056b4 <sys_open>:

uint64
sys_open(void)
{
    800056b4:	7131                	addi	sp,sp,-192
    800056b6:	fd06                	sd	ra,184(sp)
    800056b8:	f922                	sd	s0,176(sp)
    800056ba:	f526                	sd	s1,168(sp)
    800056bc:	f14a                	sd	s2,160(sp)
    800056be:	ed4e                	sd	s3,152(sp)
    800056c0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056c2:	08000613          	li	a2,128
    800056c6:	f5040593          	addi	a1,s0,-176
    800056ca:	4501                	li	a0,0
    800056cc:	ffffd097          	auipc	ra,0xffffd
    800056d0:	3fe080e7          	jalr	1022(ra) # 80002aca <argstr>
    return -1;
    800056d4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056d6:	0c054163          	bltz	a0,80005798 <sys_open+0xe4>
    800056da:	f4c40593          	addi	a1,s0,-180
    800056de:	4505                	li	a0,1
    800056e0:	ffffd097          	auipc	ra,0xffffd
    800056e4:	3a6080e7          	jalr	934(ra) # 80002a86 <argint>
    800056e8:	0a054863          	bltz	a0,80005798 <sys_open+0xe4>

  begin_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	a2e080e7          	jalr	-1490(ra) # 8000411a <begin_op>

  if(omode & O_CREATE){
    800056f4:	f4c42783          	lw	a5,-180(s0)
    800056f8:	2007f793          	andi	a5,a5,512
    800056fc:	cbdd                	beqz	a5,800057b2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056fe:	4681                	li	a3,0
    80005700:	4601                	li	a2,0
    80005702:	4589                	li	a1,2
    80005704:	f5040513          	addi	a0,s0,-176
    80005708:	00000097          	auipc	ra,0x0
    8000570c:	972080e7          	jalr	-1678(ra) # 8000507a <create>
    80005710:	892a                	mv	s2,a0
    if(ip == 0){
    80005712:	c959                	beqz	a0,800057a8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005714:	04491703          	lh	a4,68(s2)
    80005718:	478d                	li	a5,3
    8000571a:	00f71763          	bne	a4,a5,80005728 <sys_open+0x74>
    8000571e:	04695703          	lhu	a4,70(s2)
    80005722:	47a5                	li	a5,9
    80005724:	0ce7ec63          	bltu	a5,a4,800057fc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	e02080e7          	jalr	-510(ra) # 8000452a <filealloc>
    80005730:	89aa                	mv	s3,a0
    80005732:	10050263          	beqz	a0,80005836 <sys_open+0x182>
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	902080e7          	jalr	-1790(ra) # 80005038 <fdalloc>
    8000573e:	84aa                	mv	s1,a0
    80005740:	0e054663          	bltz	a0,8000582c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005744:	04491703          	lh	a4,68(s2)
    80005748:	478d                	li	a5,3
    8000574a:	0cf70463          	beq	a4,a5,80005812 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000574e:	4789                	li	a5,2
    80005750:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005754:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005758:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000575c:	f4c42783          	lw	a5,-180(s0)
    80005760:	0017c713          	xori	a4,a5,1
    80005764:	8b05                	andi	a4,a4,1
    80005766:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000576a:	0037f713          	andi	a4,a5,3
    8000576e:	00e03733          	snez	a4,a4
    80005772:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005776:	4007f793          	andi	a5,a5,1024
    8000577a:	c791                	beqz	a5,80005786 <sys_open+0xd2>
    8000577c:	04491703          	lh	a4,68(s2)
    80005780:	4789                	li	a5,2
    80005782:	08f70f63          	beq	a4,a5,80005820 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005786:	854a                	mv	a0,s2
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	082080e7          	jalr	130(ra) # 8000380a <iunlock>
  end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	a0a080e7          	jalr	-1526(ra) # 8000419a <end_op>

  return fd;
}
    80005798:	8526                	mv	a0,s1
    8000579a:	70ea                	ld	ra,184(sp)
    8000579c:	744a                	ld	s0,176(sp)
    8000579e:	74aa                	ld	s1,168(sp)
    800057a0:	790a                	ld	s2,160(sp)
    800057a2:	69ea                	ld	s3,152(sp)
    800057a4:	6129                	addi	sp,sp,192
    800057a6:	8082                	ret
      end_op();
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	9f2080e7          	jalr	-1550(ra) # 8000419a <end_op>
      return -1;
    800057b0:	b7e5                	j	80005798 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057b2:	f5040513          	addi	a0,s0,-176
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	748080e7          	jalr	1864(ra) # 80003efe <namei>
    800057be:	892a                	mv	s2,a0
    800057c0:	c905                	beqz	a0,800057f0 <sys_open+0x13c>
    ilock(ip);
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	f86080e7          	jalr	-122(ra) # 80003748 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057ca:	04491703          	lh	a4,68(s2)
    800057ce:	4785                	li	a5,1
    800057d0:	f4f712e3          	bne	a4,a5,80005714 <sys_open+0x60>
    800057d4:	f4c42783          	lw	a5,-180(s0)
    800057d8:	dba1                	beqz	a5,80005728 <sys_open+0x74>
      iunlockput(ip);
    800057da:	854a                	mv	a0,s2
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	1ce080e7          	jalr	462(ra) # 800039aa <iunlockput>
      end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	9b6080e7          	jalr	-1610(ra) # 8000419a <end_op>
      return -1;
    800057ec:	54fd                	li	s1,-1
    800057ee:	b76d                	j	80005798 <sys_open+0xe4>
      end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	9aa080e7          	jalr	-1622(ra) # 8000419a <end_op>
      return -1;
    800057f8:	54fd                	li	s1,-1
    800057fa:	bf79                	j	80005798 <sys_open+0xe4>
    iunlockput(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	1ac080e7          	jalr	428(ra) # 800039aa <iunlockput>
    end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	994080e7          	jalr	-1644(ra) # 8000419a <end_op>
    return -1;
    8000580e:	54fd                	li	s1,-1
    80005810:	b761                	j	80005798 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005812:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005816:	04691783          	lh	a5,70(s2)
    8000581a:	02f99223          	sh	a5,36(s3)
    8000581e:	bf2d                	j	80005758 <sys_open+0xa4>
    itrunc(ip);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	034080e7          	jalr	52(ra) # 80003856 <itrunc>
    8000582a:	bfb1                	j	80005786 <sys_open+0xd2>
      fileclose(f);
    8000582c:	854e                	mv	a0,s3
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	db8080e7          	jalr	-584(ra) # 800045e6 <fileclose>
    iunlockput(ip);
    80005836:	854a                	mv	a0,s2
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	172080e7          	jalr	370(ra) # 800039aa <iunlockput>
    end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	95a080e7          	jalr	-1702(ra) # 8000419a <end_op>
    return -1;
    80005848:	54fd                	li	s1,-1
    8000584a:	b7b9                	j	80005798 <sys_open+0xe4>

000000008000584c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000584c:	7175                	addi	sp,sp,-144
    8000584e:	e506                	sd	ra,136(sp)
    80005850:	e122                	sd	s0,128(sp)
    80005852:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	8c6080e7          	jalr	-1850(ra) # 8000411a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000585c:	08000613          	li	a2,128
    80005860:	f7040593          	addi	a1,s0,-144
    80005864:	4501                	li	a0,0
    80005866:	ffffd097          	auipc	ra,0xffffd
    8000586a:	264080e7          	jalr	612(ra) # 80002aca <argstr>
    8000586e:	02054963          	bltz	a0,800058a0 <sys_mkdir+0x54>
    80005872:	4681                	li	a3,0
    80005874:	4601                	li	a2,0
    80005876:	4585                	li	a1,1
    80005878:	f7040513          	addi	a0,s0,-144
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	7fe080e7          	jalr	2046(ra) # 8000507a <create>
    80005884:	cd11                	beqz	a0,800058a0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	124080e7          	jalr	292(ra) # 800039aa <iunlockput>
  end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	90c080e7          	jalr	-1780(ra) # 8000419a <end_op>
  return 0;
    80005896:	4501                	li	a0,0
}
    80005898:	60aa                	ld	ra,136(sp)
    8000589a:	640a                	ld	s0,128(sp)
    8000589c:	6149                	addi	sp,sp,144
    8000589e:	8082                	ret
    end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	8fa080e7          	jalr	-1798(ra) # 8000419a <end_op>
    return -1;
    800058a8:	557d                	li	a0,-1
    800058aa:	b7fd                	j	80005898 <sys_mkdir+0x4c>

00000000800058ac <sys_mknod>:

uint64
sys_mknod(void)
{
    800058ac:	7135                	addi	sp,sp,-160
    800058ae:	ed06                	sd	ra,152(sp)
    800058b0:	e922                	sd	s0,144(sp)
    800058b2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	866080e7          	jalr	-1946(ra) # 8000411a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058bc:	08000613          	li	a2,128
    800058c0:	f7040593          	addi	a1,s0,-144
    800058c4:	4501                	li	a0,0
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	204080e7          	jalr	516(ra) # 80002aca <argstr>
    800058ce:	04054a63          	bltz	a0,80005922 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058d2:	f6c40593          	addi	a1,s0,-148
    800058d6:	4505                	li	a0,1
    800058d8:	ffffd097          	auipc	ra,0xffffd
    800058dc:	1ae080e7          	jalr	430(ra) # 80002a86 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058e0:	04054163          	bltz	a0,80005922 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058e4:	f6840593          	addi	a1,s0,-152
    800058e8:	4509                	li	a0,2
    800058ea:	ffffd097          	auipc	ra,0xffffd
    800058ee:	19c080e7          	jalr	412(ra) # 80002a86 <argint>
     argint(1, &major) < 0 ||
    800058f2:	02054863          	bltz	a0,80005922 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058f6:	f6841683          	lh	a3,-152(s0)
    800058fa:	f6c41603          	lh	a2,-148(s0)
    800058fe:	458d                	li	a1,3
    80005900:	f7040513          	addi	a0,s0,-144
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	776080e7          	jalr	1910(ra) # 8000507a <create>
     argint(2, &minor) < 0 ||
    8000590c:	c919                	beqz	a0,80005922 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	09c080e7          	jalr	156(ra) # 800039aa <iunlockput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	884080e7          	jalr	-1916(ra) # 8000419a <end_op>
  return 0;
    8000591e:	4501                	li	a0,0
    80005920:	a031                	j	8000592c <sys_mknod+0x80>
    end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	878080e7          	jalr	-1928(ra) # 8000419a <end_op>
    return -1;
    8000592a:	557d                	li	a0,-1
}
    8000592c:	60ea                	ld	ra,152(sp)
    8000592e:	644a                	ld	s0,144(sp)
    80005930:	610d                	addi	sp,sp,160
    80005932:	8082                	ret

0000000080005934 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005934:	7135                	addi	sp,sp,-160
    80005936:	ed06                	sd	ra,152(sp)
    80005938:	e922                	sd	s0,144(sp)
    8000593a:	e526                	sd	s1,136(sp)
    8000593c:	e14a                	sd	s2,128(sp)
    8000593e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005940:	ffffc097          	auipc	ra,0xffffc
    80005944:	070080e7          	jalr	112(ra) # 800019b0 <myproc>
    80005948:	892a                	mv	s2,a0
  
  begin_op();
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	7d0080e7          	jalr	2000(ra) # 8000411a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005952:	08000613          	li	a2,128
    80005956:	f6040593          	addi	a1,s0,-160
    8000595a:	4501                	li	a0,0
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	16e080e7          	jalr	366(ra) # 80002aca <argstr>
    80005964:	04054b63          	bltz	a0,800059ba <sys_chdir+0x86>
    80005968:	f6040513          	addi	a0,s0,-160
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	592080e7          	jalr	1426(ra) # 80003efe <namei>
    80005974:	84aa                	mv	s1,a0
    80005976:	c131                	beqz	a0,800059ba <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	dd0080e7          	jalr	-560(ra) # 80003748 <ilock>
  if(ip->type != T_DIR){
    80005980:	04449703          	lh	a4,68(s1)
    80005984:	4785                	li	a5,1
    80005986:	04f71063          	bne	a4,a5,800059c6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	e7e080e7          	jalr	-386(ra) # 8000380a <iunlock>
  iput(p->cwd);
    80005994:	15093503          	ld	a0,336(s2)
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	f6a080e7          	jalr	-150(ra) # 80003902 <iput>
  end_op();
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	7fa080e7          	jalr	2042(ra) # 8000419a <end_op>
  p->cwd = ip;
    800059a8:	14993823          	sd	s1,336(s2)
  return 0;
    800059ac:	4501                	li	a0,0
}
    800059ae:	60ea                	ld	ra,152(sp)
    800059b0:	644a                	ld	s0,144(sp)
    800059b2:	64aa                	ld	s1,136(sp)
    800059b4:	690a                	ld	s2,128(sp)
    800059b6:	610d                	addi	sp,sp,160
    800059b8:	8082                	ret
    end_op();
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	7e0080e7          	jalr	2016(ra) # 8000419a <end_op>
    return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	b7ed                	j	800059ae <sys_chdir+0x7a>
    iunlockput(ip);
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	fe2080e7          	jalr	-30(ra) # 800039aa <iunlockput>
    end_op();
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	7ca080e7          	jalr	1994(ra) # 8000419a <end_op>
    return -1;
    800059d8:	557d                	li	a0,-1
    800059da:	bfd1                	j	800059ae <sys_chdir+0x7a>

00000000800059dc <sys_exec>:

uint64
sys_exec(void)
{
    800059dc:	7145                	addi	sp,sp,-464
    800059de:	e786                	sd	ra,456(sp)
    800059e0:	e3a2                	sd	s0,448(sp)
    800059e2:	ff26                	sd	s1,440(sp)
    800059e4:	fb4a                	sd	s2,432(sp)
    800059e6:	f74e                	sd	s3,424(sp)
    800059e8:	f352                	sd	s4,416(sp)
    800059ea:	ef56                	sd	s5,408(sp)
    800059ec:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f4040593          	addi	a1,s0,-192
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	0d2080e7          	jalr	210(ra) # 80002aca <argstr>
    return -1;
    80005a00:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a02:	0c054a63          	bltz	a0,80005ad6 <sys_exec+0xfa>
    80005a06:	e3840593          	addi	a1,s0,-456
    80005a0a:	4505                	li	a0,1
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	09c080e7          	jalr	156(ra) # 80002aa8 <argaddr>
    80005a14:	0c054163          	bltz	a0,80005ad6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a18:	10000613          	li	a2,256
    80005a1c:	4581                	li	a1,0
    80005a1e:	e4040513          	addi	a0,s0,-448
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	2be080e7          	jalr	702(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a2a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a2e:	89a6                	mv	s3,s1
    80005a30:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a32:	02000a13          	li	s4,32
    80005a36:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a3a:	00391513          	slli	a0,s2,0x3
    80005a3e:	e3040593          	addi	a1,s0,-464
    80005a42:	e3843783          	ld	a5,-456(s0)
    80005a46:	953e                	add	a0,a0,a5
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	fa4080e7          	jalr	-92(ra) # 800029ec <fetchaddr>
    80005a50:	02054a63          	bltz	a0,80005a84 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a54:	e3043783          	ld	a5,-464(s0)
    80005a58:	c3b9                	beqz	a5,80005a9e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	09a080e7          	jalr	154(ra) # 80000af4 <kalloc>
    80005a62:	85aa                	mv	a1,a0
    80005a64:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a68:	cd11                	beqz	a0,80005a84 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a6a:	6605                	lui	a2,0x1
    80005a6c:	e3043503          	ld	a0,-464(s0)
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	fce080e7          	jalr	-50(ra) # 80002a3e <fetchstr>
    80005a78:	00054663          	bltz	a0,80005a84 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a7c:	0905                	addi	s2,s2,1
    80005a7e:	09a1                	addi	s3,s3,8
    80005a80:	fb491be3          	bne	s2,s4,80005a36 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a84:	10048913          	addi	s2,s1,256
    80005a88:	6088                	ld	a0,0(s1)
    80005a8a:	c529                	beqz	a0,80005ad4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	f6c080e7          	jalr	-148(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a94:	04a1                	addi	s1,s1,8
    80005a96:	ff2499e3          	bne	s1,s2,80005a88 <sys_exec+0xac>
  return -1;
    80005a9a:	597d                	li	s2,-1
    80005a9c:	a82d                	j	80005ad6 <sys_exec+0xfa>
      argv[i] = 0;
    80005a9e:	0a8e                	slli	s5,s5,0x3
    80005aa0:	fc040793          	addi	a5,s0,-64
    80005aa4:	9abe                	add	s5,s5,a5
    80005aa6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005aaa:	e4040593          	addi	a1,s0,-448
    80005aae:	f4040513          	addi	a0,s0,-192
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	194080e7          	jalr	404(ra) # 80004c46 <exec>
    80005aba:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abc:	10048993          	addi	s3,s1,256
    80005ac0:	6088                	ld	a0,0(s1)
    80005ac2:	c911                	beqz	a0,80005ad6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	f34080e7          	jalr	-204(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005acc:	04a1                	addi	s1,s1,8
    80005ace:	ff3499e3          	bne	s1,s3,80005ac0 <sys_exec+0xe4>
    80005ad2:	a011                	j	80005ad6 <sys_exec+0xfa>
  return -1;
    80005ad4:	597d                	li	s2,-1
}
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	60be                	ld	ra,456(sp)
    80005ada:	641e                	ld	s0,448(sp)
    80005adc:	74fa                	ld	s1,440(sp)
    80005ade:	795a                	ld	s2,432(sp)
    80005ae0:	79ba                	ld	s3,424(sp)
    80005ae2:	7a1a                	ld	s4,416(sp)
    80005ae4:	6afa                	ld	s5,408(sp)
    80005ae6:	6179                	addi	sp,sp,464
    80005ae8:	8082                	ret

0000000080005aea <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aea:	7139                	addi	sp,sp,-64
    80005aec:	fc06                	sd	ra,56(sp)
    80005aee:	f822                	sd	s0,48(sp)
    80005af0:	f426                	sd	s1,40(sp)
    80005af2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005af4:	ffffc097          	auipc	ra,0xffffc
    80005af8:	ebc080e7          	jalr	-324(ra) # 800019b0 <myproc>
    80005afc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005afe:	fd840593          	addi	a1,s0,-40
    80005b02:	4501                	li	a0,0
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	fa4080e7          	jalr	-92(ra) # 80002aa8 <argaddr>
    return -1;
    80005b0c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b0e:	0e054063          	bltz	a0,80005bee <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b12:	fc840593          	addi	a1,s0,-56
    80005b16:	fd040513          	addi	a0,s0,-48
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	dfc080e7          	jalr	-516(ra) # 80004916 <pipealloc>
    return -1;
    80005b22:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b24:	0c054563          	bltz	a0,80005bee <sys_pipe+0x104>
  fd0 = -1;
    80005b28:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b2c:	fd043503          	ld	a0,-48(s0)
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	508080e7          	jalr	1288(ra) # 80005038 <fdalloc>
    80005b38:	fca42223          	sw	a0,-60(s0)
    80005b3c:	08054c63          	bltz	a0,80005bd4 <sys_pipe+0xea>
    80005b40:	fc843503          	ld	a0,-56(s0)
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	4f4080e7          	jalr	1268(ra) # 80005038 <fdalloc>
    80005b4c:	fca42023          	sw	a0,-64(s0)
    80005b50:	06054863          	bltz	a0,80005bc0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b54:	4691                	li	a3,4
    80005b56:	fc440613          	addi	a2,s0,-60
    80005b5a:	fd843583          	ld	a1,-40(s0)
    80005b5e:	68a8                	ld	a0,80(s1)
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	b12080e7          	jalr	-1262(ra) # 80001672 <copyout>
    80005b68:	02054063          	bltz	a0,80005b88 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b6c:	4691                	li	a3,4
    80005b6e:	fc040613          	addi	a2,s0,-64
    80005b72:	fd843583          	ld	a1,-40(s0)
    80005b76:	0591                	addi	a1,a1,4
    80005b78:	68a8                	ld	a0,80(s1)
    80005b7a:	ffffc097          	auipc	ra,0xffffc
    80005b7e:	af8080e7          	jalr	-1288(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b82:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b84:	06055563          	bgez	a0,80005bee <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b88:	fc442783          	lw	a5,-60(s0)
    80005b8c:	07e9                	addi	a5,a5,26
    80005b8e:	078e                	slli	a5,a5,0x3
    80005b90:	97a6                	add	a5,a5,s1
    80005b92:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b96:	fc042503          	lw	a0,-64(s0)
    80005b9a:	0569                	addi	a0,a0,26
    80005b9c:	050e                	slli	a0,a0,0x3
    80005b9e:	9526                	add	a0,a0,s1
    80005ba0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ba4:	fd043503          	ld	a0,-48(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	a3e080e7          	jalr	-1474(ra) # 800045e6 <fileclose>
    fileclose(wf);
    80005bb0:	fc843503          	ld	a0,-56(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	a32080e7          	jalr	-1486(ra) # 800045e6 <fileclose>
    return -1;
    80005bbc:	57fd                	li	a5,-1
    80005bbe:	a805                	j	80005bee <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bc0:	fc442783          	lw	a5,-60(s0)
    80005bc4:	0007c863          	bltz	a5,80005bd4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bc8:	01a78513          	addi	a0,a5,26
    80005bcc:	050e                	slli	a0,a0,0x3
    80005bce:	9526                	add	a0,a0,s1
    80005bd0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bd4:	fd043503          	ld	a0,-48(s0)
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	a0e080e7          	jalr	-1522(ra) # 800045e6 <fileclose>
    fileclose(wf);
    80005be0:	fc843503          	ld	a0,-56(s0)
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	a02080e7          	jalr	-1534(ra) # 800045e6 <fileclose>
    return -1;
    80005bec:	57fd                	li	a5,-1
}
    80005bee:	853e                	mv	a0,a5
    80005bf0:	70e2                	ld	ra,56(sp)
    80005bf2:	7442                	ld	s0,48(sp)
    80005bf4:	74a2                	ld	s1,40(sp)
    80005bf6:	6121                	addi	sp,sp,64
    80005bf8:	8082                	ret
    80005bfa:	0000                	unimp
    80005bfc:	0000                	unimp
	...

0000000080005c00 <kernelvec>:
    80005c00:	7111                	addi	sp,sp,-256
    80005c02:	e006                	sd	ra,0(sp)
    80005c04:	e40a                	sd	sp,8(sp)
    80005c06:	e80e                	sd	gp,16(sp)
    80005c08:	ec12                	sd	tp,24(sp)
    80005c0a:	f016                	sd	t0,32(sp)
    80005c0c:	f41a                	sd	t1,40(sp)
    80005c0e:	f81e                	sd	t2,48(sp)
    80005c10:	fc22                	sd	s0,56(sp)
    80005c12:	e0a6                	sd	s1,64(sp)
    80005c14:	e4aa                	sd	a0,72(sp)
    80005c16:	e8ae                	sd	a1,80(sp)
    80005c18:	ecb2                	sd	a2,88(sp)
    80005c1a:	f0b6                	sd	a3,96(sp)
    80005c1c:	f4ba                	sd	a4,104(sp)
    80005c1e:	f8be                	sd	a5,112(sp)
    80005c20:	fcc2                	sd	a6,120(sp)
    80005c22:	e146                	sd	a7,128(sp)
    80005c24:	e54a                	sd	s2,136(sp)
    80005c26:	e94e                	sd	s3,144(sp)
    80005c28:	ed52                	sd	s4,152(sp)
    80005c2a:	f156                	sd	s5,160(sp)
    80005c2c:	f55a                	sd	s6,168(sp)
    80005c2e:	f95e                	sd	s7,176(sp)
    80005c30:	fd62                	sd	s8,184(sp)
    80005c32:	e1e6                	sd	s9,192(sp)
    80005c34:	e5ea                	sd	s10,200(sp)
    80005c36:	e9ee                	sd	s11,208(sp)
    80005c38:	edf2                	sd	t3,216(sp)
    80005c3a:	f1f6                	sd	t4,224(sp)
    80005c3c:	f5fa                	sd	t5,232(sp)
    80005c3e:	f9fe                	sd	t6,240(sp)
    80005c40:	c79fc0ef          	jal	ra,800028b8 <kerneltrap>
    80005c44:	6082                	ld	ra,0(sp)
    80005c46:	6122                	ld	sp,8(sp)
    80005c48:	61c2                	ld	gp,16(sp)
    80005c4a:	7282                	ld	t0,32(sp)
    80005c4c:	7322                	ld	t1,40(sp)
    80005c4e:	73c2                	ld	t2,48(sp)
    80005c50:	7462                	ld	s0,56(sp)
    80005c52:	6486                	ld	s1,64(sp)
    80005c54:	6526                	ld	a0,72(sp)
    80005c56:	65c6                	ld	a1,80(sp)
    80005c58:	6666                	ld	a2,88(sp)
    80005c5a:	7686                	ld	a3,96(sp)
    80005c5c:	7726                	ld	a4,104(sp)
    80005c5e:	77c6                	ld	a5,112(sp)
    80005c60:	7866                	ld	a6,120(sp)
    80005c62:	688a                	ld	a7,128(sp)
    80005c64:	692a                	ld	s2,136(sp)
    80005c66:	69ca                	ld	s3,144(sp)
    80005c68:	6a6a                	ld	s4,152(sp)
    80005c6a:	7a8a                	ld	s5,160(sp)
    80005c6c:	7b2a                	ld	s6,168(sp)
    80005c6e:	7bca                	ld	s7,176(sp)
    80005c70:	7c6a                	ld	s8,184(sp)
    80005c72:	6c8e                	ld	s9,192(sp)
    80005c74:	6d2e                	ld	s10,200(sp)
    80005c76:	6dce                	ld	s11,208(sp)
    80005c78:	6e6e                	ld	t3,216(sp)
    80005c7a:	7e8e                	ld	t4,224(sp)
    80005c7c:	7f2e                	ld	t5,232(sp)
    80005c7e:	7fce                	ld	t6,240(sp)
    80005c80:	6111                	addi	sp,sp,256
    80005c82:	10200073          	sret
    80005c86:	00000013          	nop
    80005c8a:	00000013          	nop
    80005c8e:	0001                	nop

0000000080005c90 <timervec>:
    80005c90:	34051573          	csrrw	a0,mscratch,a0
    80005c94:	e10c                	sd	a1,0(a0)
    80005c96:	e510                	sd	a2,8(a0)
    80005c98:	e914                	sd	a3,16(a0)
    80005c9a:	6d0c                	ld	a1,24(a0)
    80005c9c:	7110                	ld	a2,32(a0)
    80005c9e:	6194                	ld	a3,0(a1)
    80005ca0:	96b2                	add	a3,a3,a2
    80005ca2:	e194                	sd	a3,0(a1)
    80005ca4:	4589                	li	a1,2
    80005ca6:	14459073          	csrw	sip,a1
    80005caa:	6914                	ld	a3,16(a0)
    80005cac:	6510                	ld	a2,8(a0)
    80005cae:	610c                	ld	a1,0(a0)
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	30200073          	mret
	...

0000000080005cba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cba:	1141                	addi	sp,sp,-16
    80005cbc:	e422                	sd	s0,8(sp)
    80005cbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cc0:	0c0007b7          	lui	a5,0xc000
    80005cc4:	4705                	li	a4,1
    80005cc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cc8:	c3d8                	sw	a4,4(a5)
}
    80005cca:	6422                	ld	s0,8(sp)
    80005ccc:	0141                	addi	sp,sp,16
    80005cce:	8082                	ret

0000000080005cd0 <plicinithart>:

void
plicinithart(void)
{
    80005cd0:	1141                	addi	sp,sp,-16
    80005cd2:	e406                	sd	ra,8(sp)
    80005cd4:	e022                	sd	s0,0(sp)
    80005cd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	cac080e7          	jalr	-852(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ce0:	0085171b          	slliw	a4,a0,0x8
    80005ce4:	0c0027b7          	lui	a5,0xc002
    80005ce8:	97ba                	add	a5,a5,a4
    80005cea:	40200713          	li	a4,1026
    80005cee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cf2:	00d5151b          	slliw	a0,a0,0xd
    80005cf6:	0c2017b7          	lui	a5,0xc201
    80005cfa:	953e                	add	a0,a0,a5
    80005cfc:	00052023          	sw	zero,0(a0)
}
    80005d00:	60a2                	ld	ra,8(sp)
    80005d02:	6402                	ld	s0,0(sp)
    80005d04:	0141                	addi	sp,sp,16
    80005d06:	8082                	ret

0000000080005d08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d08:	1141                	addi	sp,sp,-16
    80005d0a:	e406                	sd	ra,8(sp)
    80005d0c:	e022                	sd	s0,0(sp)
    80005d0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	c74080e7          	jalr	-908(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d18:	00d5179b          	slliw	a5,a0,0xd
    80005d1c:	0c201537          	lui	a0,0xc201
    80005d20:	953e                	add	a0,a0,a5
  return irq;
}
    80005d22:	4148                	lw	a0,4(a0)
    80005d24:	60a2                	ld	ra,8(sp)
    80005d26:	6402                	ld	s0,0(sp)
    80005d28:	0141                	addi	sp,sp,16
    80005d2a:	8082                	ret

0000000080005d2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d2c:	1101                	addi	sp,sp,-32
    80005d2e:	ec06                	sd	ra,24(sp)
    80005d30:	e822                	sd	s0,16(sp)
    80005d32:	e426                	sd	s1,8(sp)
    80005d34:	1000                	addi	s0,sp,32
    80005d36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	c4c080e7          	jalr	-948(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d40:	00d5151b          	slliw	a0,a0,0xd
    80005d44:	0c2017b7          	lui	a5,0xc201
    80005d48:	97aa                	add	a5,a5,a0
    80005d4a:	c3c4                	sw	s1,4(a5)
}
    80005d4c:	60e2                	ld	ra,24(sp)
    80005d4e:	6442                	ld	s0,16(sp)
    80005d50:	64a2                	ld	s1,8(sp)
    80005d52:	6105                	addi	sp,sp,32
    80005d54:	8082                	ret

0000000080005d56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d56:	1141                	addi	sp,sp,-16
    80005d58:	e406                	sd	ra,8(sp)
    80005d5a:	e022                	sd	s0,0(sp)
    80005d5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d5e:	479d                	li	a5,7
    80005d60:	06a7c963          	blt	a5,a0,80005dd2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d64:	0001d797          	auipc	a5,0x1d
    80005d68:	29c78793          	addi	a5,a5,668 # 80023000 <disk>
    80005d6c:	00a78733          	add	a4,a5,a0
    80005d70:	6789                	lui	a5,0x2
    80005d72:	97ba                	add	a5,a5,a4
    80005d74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d78:	e7ad                	bnez	a5,80005de2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d7a:	00451793          	slli	a5,a0,0x4
    80005d7e:	0001f717          	auipc	a4,0x1f
    80005d82:	28270713          	addi	a4,a4,642 # 80025000 <disk+0x2000>
    80005d86:	6314                	ld	a3,0(a4)
    80005d88:	96be                	add	a3,a3,a5
    80005d8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d8e:	6314                	ld	a3,0(a4)
    80005d90:	96be                	add	a3,a3,a5
    80005d92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d96:	6314                	ld	a3,0(a4)
    80005d98:	96be                	add	a3,a3,a5
    80005d9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d9e:	6318                	ld	a4,0(a4)
    80005da0:	97ba                	add	a5,a5,a4
    80005da2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005da6:	0001d797          	auipc	a5,0x1d
    80005daa:	25a78793          	addi	a5,a5,602 # 80023000 <disk>
    80005dae:	97aa                	add	a5,a5,a0
    80005db0:	6509                	lui	a0,0x2
    80005db2:	953e                	add	a0,a0,a5
    80005db4:	4785                	li	a5,1
    80005db6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dba:	0001f517          	auipc	a0,0x1f
    80005dbe:	25e50513          	addi	a0,a0,606 # 80025018 <disk+0x2018>
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	43e080e7          	jalr	1086(ra) # 80002200 <wakeup>
}
    80005dca:	60a2                	ld	ra,8(sp)
    80005dcc:	6402                	ld	s0,0(sp)
    80005dce:	0141                	addi	sp,sp,16
    80005dd0:	8082                	ret
    panic("free_desc 1");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	a6e50513          	addi	a0,a0,-1426 # 80008840 <syscalls+0x320>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005de2:	00003517          	auipc	a0,0x3
    80005de6:	a6e50513          	addi	a0,a0,-1426 # 80008850 <syscalls+0x330>
    80005dea:	ffffa097          	auipc	ra,0xffffa
    80005dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>

0000000080005df2 <virtio_disk_init>:
{
    80005df2:	1101                	addi	sp,sp,-32
    80005df4:	ec06                	sd	ra,24(sp)
    80005df6:	e822                	sd	s0,16(sp)
    80005df8:	e426                	sd	s1,8(sp)
    80005dfa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dfc:	00003597          	auipc	a1,0x3
    80005e00:	a6458593          	addi	a1,a1,-1436 # 80008860 <syscalls+0x340>
    80005e04:	0001f517          	auipc	a0,0x1f
    80005e08:	32450513          	addi	a0,a0,804 # 80025128 <disk+0x2128>
    80005e0c:	ffffb097          	auipc	ra,0xffffb
    80005e10:	d48080e7          	jalr	-696(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e14:	100017b7          	lui	a5,0x10001
    80005e18:	4398                	lw	a4,0(a5)
    80005e1a:	2701                	sext.w	a4,a4
    80005e1c:	747277b7          	lui	a5,0x74727
    80005e20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e24:	0ef71163          	bne	a4,a5,80005f06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e28:	100017b7          	lui	a5,0x10001
    80005e2c:	43dc                	lw	a5,4(a5)
    80005e2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e30:	4705                	li	a4,1
    80005e32:	0ce79a63          	bne	a5,a4,80005f06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e36:	100017b7          	lui	a5,0x10001
    80005e3a:	479c                	lw	a5,8(a5)
    80005e3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e3e:	4709                	li	a4,2
    80005e40:	0ce79363          	bne	a5,a4,80005f06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e44:	100017b7          	lui	a5,0x10001
    80005e48:	47d8                	lw	a4,12(a5)
    80005e4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4c:	554d47b7          	lui	a5,0x554d4
    80005e50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e54:	0af71963          	bne	a4,a5,80005f06 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e58:	100017b7          	lui	a5,0x10001
    80005e5c:	4705                	li	a4,1
    80005e5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e60:	470d                	li	a4,3
    80005e62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e66:	c7ffe737          	lui	a4,0xc7ffe
    80005e6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e70:	2701                	sext.w	a4,a4
    80005e72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e74:	472d                	li	a4,11
    80005e76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e78:	473d                	li	a4,15
    80005e7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e7c:	6705                	lui	a4,0x1
    80005e7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e84:	5bdc                	lw	a5,52(a5)
    80005e86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e88:	c7d9                	beqz	a5,80005f16 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e8a:	471d                	li	a4,7
    80005e8c:	08f77d63          	bgeu	a4,a5,80005f26 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e90:	100014b7          	lui	s1,0x10001
    80005e94:	47a1                	li	a5,8
    80005e96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e98:	6609                	lui	a2,0x2
    80005e9a:	4581                	li	a1,0
    80005e9c:	0001d517          	auipc	a0,0x1d
    80005ea0:	16450513          	addi	a0,a0,356 # 80023000 <disk>
    80005ea4:	ffffb097          	auipc	ra,0xffffb
    80005ea8:	e3c080e7          	jalr	-452(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005eac:	0001d717          	auipc	a4,0x1d
    80005eb0:	15470713          	addi	a4,a4,340 # 80023000 <disk>
    80005eb4:	00c75793          	srli	a5,a4,0xc
    80005eb8:	2781                	sext.w	a5,a5
    80005eba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ebc:	0001f797          	auipc	a5,0x1f
    80005ec0:	14478793          	addi	a5,a5,324 # 80025000 <disk+0x2000>
    80005ec4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ec6:	0001d717          	auipc	a4,0x1d
    80005eca:	1ba70713          	addi	a4,a4,442 # 80023080 <disk+0x80>
    80005ece:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ed0:	0001e717          	auipc	a4,0x1e
    80005ed4:	13070713          	addi	a4,a4,304 # 80024000 <disk+0x1000>
    80005ed8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eda:	4705                	li	a4,1
    80005edc:	00e78c23          	sb	a4,24(a5)
    80005ee0:	00e78ca3          	sb	a4,25(a5)
    80005ee4:	00e78d23          	sb	a4,26(a5)
    80005ee8:	00e78da3          	sb	a4,27(a5)
    80005eec:	00e78e23          	sb	a4,28(a5)
    80005ef0:	00e78ea3          	sb	a4,29(a5)
    80005ef4:	00e78f23          	sb	a4,30(a5)
    80005ef8:	00e78fa3          	sb	a4,31(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret
    panic("could not find virtio disk");
    80005f06:	00003517          	auipc	a0,0x3
    80005f0a:	96a50513          	addi	a0,a0,-1686 # 80008870 <syscalls+0x350>
    80005f0e:	ffffa097          	auipc	ra,0xffffa
    80005f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f16:	00003517          	auipc	a0,0x3
    80005f1a:	97a50513          	addi	a0,a0,-1670 # 80008890 <syscalls+0x370>
    80005f1e:	ffffa097          	auipc	ra,0xffffa
    80005f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f26:	00003517          	auipc	a0,0x3
    80005f2a:	98a50513          	addi	a0,a0,-1654 # 800088b0 <syscalls+0x390>
    80005f2e:	ffffa097          	auipc	ra,0xffffa
    80005f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>

0000000080005f36 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f36:	7159                	addi	sp,sp,-112
    80005f38:	f486                	sd	ra,104(sp)
    80005f3a:	f0a2                	sd	s0,96(sp)
    80005f3c:	eca6                	sd	s1,88(sp)
    80005f3e:	e8ca                	sd	s2,80(sp)
    80005f40:	e4ce                	sd	s3,72(sp)
    80005f42:	e0d2                	sd	s4,64(sp)
    80005f44:	fc56                	sd	s5,56(sp)
    80005f46:	f85a                	sd	s6,48(sp)
    80005f48:	f45e                	sd	s7,40(sp)
    80005f4a:	f062                	sd	s8,32(sp)
    80005f4c:	ec66                	sd	s9,24(sp)
    80005f4e:	e86a                	sd	s10,16(sp)
    80005f50:	1880                	addi	s0,sp,112
    80005f52:	892a                	mv	s2,a0
    80005f54:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f56:	00c52c83          	lw	s9,12(a0)
    80005f5a:	001c9c9b          	slliw	s9,s9,0x1
    80005f5e:	1c82                	slli	s9,s9,0x20
    80005f60:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f64:	0001f517          	auipc	a0,0x1f
    80005f68:	1c450513          	addi	a0,a0,452 # 80025128 <disk+0x2128>
    80005f6c:	ffffb097          	auipc	ra,0xffffb
    80005f70:	c78080e7          	jalr	-904(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f74:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f76:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f78:	0001db97          	auipc	s7,0x1d
    80005f7c:	088b8b93          	addi	s7,s7,136 # 80023000 <disk>
    80005f80:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f82:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f84:	8a4e                	mv	s4,s3
    80005f86:	a051                	j	8000600a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f88:	00fb86b3          	add	a3,s7,a5
    80005f8c:	96da                	add	a3,a3,s6
    80005f8e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f92:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f94:	0207c563          	bltz	a5,80005fbe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f98:	2485                	addiw	s1,s1,1
    80005f9a:	0711                	addi	a4,a4,4
    80005f9c:	25548063          	beq	s1,s5,800061dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005fa0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fa2:	0001f697          	auipc	a3,0x1f
    80005fa6:	07668693          	addi	a3,a3,118 # 80025018 <disk+0x2018>
    80005faa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fac:	0006c583          	lbu	a1,0(a3)
    80005fb0:	fde1                	bnez	a1,80005f88 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fb2:	2785                	addiw	a5,a5,1
    80005fb4:	0685                	addi	a3,a3,1
    80005fb6:	ff879be3          	bne	a5,s8,80005fac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fba:	57fd                	li	a5,-1
    80005fbc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fbe:	02905a63          	blez	s1,80005ff2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fc2:	f9042503          	lw	a0,-112(s0)
    80005fc6:	00000097          	auipc	ra,0x0
    80005fca:	d90080e7          	jalr	-624(ra) # 80005d56 <free_desc>
      for(int j = 0; j < i; j++)
    80005fce:	4785                	li	a5,1
    80005fd0:	0297d163          	bge	a5,s1,80005ff2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd4:	f9442503          	lw	a0,-108(s0)
    80005fd8:	00000097          	auipc	ra,0x0
    80005fdc:	d7e080e7          	jalr	-642(ra) # 80005d56 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe0:	4789                	li	a5,2
    80005fe2:	0097d863          	bge	a5,s1,80005ff2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fe6:	f9842503          	lw	a0,-104(s0)
    80005fea:	00000097          	auipc	ra,0x0
    80005fee:	d6c080e7          	jalr	-660(ra) # 80005d56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ff2:	0001f597          	auipc	a1,0x1f
    80005ff6:	13658593          	addi	a1,a1,310 # 80025128 <disk+0x2128>
    80005ffa:	0001f517          	auipc	a0,0x1f
    80005ffe:	01e50513          	addi	a0,a0,30 # 80025018 <disk+0x2018>
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	072080e7          	jalr	114(ra) # 80002074 <sleep>
  for(int i = 0; i < 3; i++){
    8000600a:	f9040713          	addi	a4,s0,-112
    8000600e:	84ce                	mv	s1,s3
    80006010:	bf41                	j	80005fa0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006012:	20058713          	addi	a4,a1,512
    80006016:	00471693          	slli	a3,a4,0x4
    8000601a:	0001d717          	auipc	a4,0x1d
    8000601e:	fe670713          	addi	a4,a4,-26 # 80023000 <disk>
    80006022:	9736                	add	a4,a4,a3
    80006024:	4685                	li	a3,1
    80006026:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000602a:	20058713          	addi	a4,a1,512
    8000602e:	00471693          	slli	a3,a4,0x4
    80006032:	0001d717          	auipc	a4,0x1d
    80006036:	fce70713          	addi	a4,a4,-50 # 80023000 <disk>
    8000603a:	9736                	add	a4,a4,a3
    8000603c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006040:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006044:	7679                	lui	a2,0xffffe
    80006046:	963e                	add	a2,a2,a5
    80006048:	0001f697          	auipc	a3,0x1f
    8000604c:	fb868693          	addi	a3,a3,-72 # 80025000 <disk+0x2000>
    80006050:	6298                	ld	a4,0(a3)
    80006052:	9732                	add	a4,a4,a2
    80006054:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006056:	6298                	ld	a4,0(a3)
    80006058:	9732                	add	a4,a4,a2
    8000605a:	4541                	li	a0,16
    8000605c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000605e:	6298                	ld	a4,0(a3)
    80006060:	9732                	add	a4,a4,a2
    80006062:	4505                	li	a0,1
    80006064:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006068:	f9442703          	lw	a4,-108(s0)
    8000606c:	6288                	ld	a0,0(a3)
    8000606e:	962a                	add	a2,a2,a0
    80006070:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006074:	0712                	slli	a4,a4,0x4
    80006076:	6290                	ld	a2,0(a3)
    80006078:	963a                	add	a2,a2,a4
    8000607a:	05890513          	addi	a0,s2,88
    8000607e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006080:	6294                	ld	a3,0(a3)
    80006082:	96ba                	add	a3,a3,a4
    80006084:	40000613          	li	a2,1024
    80006088:	c690                	sw	a2,8(a3)
  if(write)
    8000608a:	140d0063          	beqz	s10,800061ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000608e:	0001f697          	auipc	a3,0x1f
    80006092:	f726b683          	ld	a3,-142(a3) # 80025000 <disk+0x2000>
    80006096:	96ba                	add	a3,a3,a4
    80006098:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000609c:	0001d817          	auipc	a6,0x1d
    800060a0:	f6480813          	addi	a6,a6,-156 # 80023000 <disk>
    800060a4:	0001f517          	auipc	a0,0x1f
    800060a8:	f5c50513          	addi	a0,a0,-164 # 80025000 <disk+0x2000>
    800060ac:	6114                	ld	a3,0(a0)
    800060ae:	96ba                	add	a3,a3,a4
    800060b0:	00c6d603          	lhu	a2,12(a3)
    800060b4:	00166613          	ori	a2,a2,1
    800060b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060bc:	f9842683          	lw	a3,-104(s0)
    800060c0:	6110                	ld	a2,0(a0)
    800060c2:	9732                	add	a4,a4,a2
    800060c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060c8:	20058613          	addi	a2,a1,512
    800060cc:	0612                	slli	a2,a2,0x4
    800060ce:	9642                	add	a2,a2,a6
    800060d0:	577d                	li	a4,-1
    800060d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060d6:	00469713          	slli	a4,a3,0x4
    800060da:	6114                	ld	a3,0(a0)
    800060dc:	96ba                	add	a3,a3,a4
    800060de:	03078793          	addi	a5,a5,48
    800060e2:	97c2                	add	a5,a5,a6
    800060e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800060e6:	611c                	ld	a5,0(a0)
    800060e8:	97ba                	add	a5,a5,a4
    800060ea:	4685                	li	a3,1
    800060ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060ee:	611c                	ld	a5,0(a0)
    800060f0:	97ba                	add	a5,a5,a4
    800060f2:	4809                	li	a6,2
    800060f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060f8:	611c                	ld	a5,0(a0)
    800060fa:	973e                	add	a4,a4,a5
    800060fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006100:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006104:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006108:	6518                	ld	a4,8(a0)
    8000610a:	00275783          	lhu	a5,2(a4)
    8000610e:	8b9d                	andi	a5,a5,7
    80006110:	0786                	slli	a5,a5,0x1
    80006112:	97ba                	add	a5,a5,a4
    80006114:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006118:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000611c:	6518                	ld	a4,8(a0)
    8000611e:	00275783          	lhu	a5,2(a4)
    80006122:	2785                	addiw	a5,a5,1
    80006124:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006128:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000612c:	100017b7          	lui	a5,0x10001
    80006130:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006134:	00492703          	lw	a4,4(s2)
    80006138:	4785                	li	a5,1
    8000613a:	02f71163          	bne	a4,a5,8000615c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000613e:	0001f997          	auipc	s3,0x1f
    80006142:	fea98993          	addi	s3,s3,-22 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006146:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006148:	85ce                	mv	a1,s3
    8000614a:	854a                	mv	a0,s2
    8000614c:	ffffc097          	auipc	ra,0xffffc
    80006150:	f28080e7          	jalr	-216(ra) # 80002074 <sleep>
  while(b->disk == 1) {
    80006154:	00492783          	lw	a5,4(s2)
    80006158:	fe9788e3          	beq	a5,s1,80006148 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000615c:	f9042903          	lw	s2,-112(s0)
    80006160:	20090793          	addi	a5,s2,512
    80006164:	00479713          	slli	a4,a5,0x4
    80006168:	0001d797          	auipc	a5,0x1d
    8000616c:	e9878793          	addi	a5,a5,-360 # 80023000 <disk>
    80006170:	97ba                	add	a5,a5,a4
    80006172:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006176:	0001f997          	auipc	s3,0x1f
    8000617a:	e8a98993          	addi	s3,s3,-374 # 80025000 <disk+0x2000>
    8000617e:	00491713          	slli	a4,s2,0x4
    80006182:	0009b783          	ld	a5,0(s3)
    80006186:	97ba                	add	a5,a5,a4
    80006188:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000618c:	854a                	mv	a0,s2
    8000618e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006192:	00000097          	auipc	ra,0x0
    80006196:	bc4080e7          	jalr	-1084(ra) # 80005d56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000619a:	8885                	andi	s1,s1,1
    8000619c:	f0ed                	bnez	s1,8000617e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000619e:	0001f517          	auipc	a0,0x1f
    800061a2:	f8a50513          	addi	a0,a0,-118 # 80025128 <disk+0x2128>
    800061a6:	ffffb097          	auipc	ra,0xffffb
    800061aa:	af2080e7          	jalr	-1294(ra) # 80000c98 <release>
}
    800061ae:	70a6                	ld	ra,104(sp)
    800061b0:	7406                	ld	s0,96(sp)
    800061b2:	64e6                	ld	s1,88(sp)
    800061b4:	6946                	ld	s2,80(sp)
    800061b6:	69a6                	ld	s3,72(sp)
    800061b8:	6a06                	ld	s4,64(sp)
    800061ba:	7ae2                	ld	s5,56(sp)
    800061bc:	7b42                	ld	s6,48(sp)
    800061be:	7ba2                	ld	s7,40(sp)
    800061c0:	7c02                	ld	s8,32(sp)
    800061c2:	6ce2                	ld	s9,24(sp)
    800061c4:	6d42                	ld	s10,16(sp)
    800061c6:	6165                	addi	sp,sp,112
    800061c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ca:	0001f697          	auipc	a3,0x1f
    800061ce:	e366b683          	ld	a3,-458(a3) # 80025000 <disk+0x2000>
    800061d2:	96ba                	add	a3,a3,a4
    800061d4:	4609                	li	a2,2
    800061d6:	00c69623          	sh	a2,12(a3)
    800061da:	b5c9                	j	8000609c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061dc:	f9042583          	lw	a1,-112(s0)
    800061e0:	20058793          	addi	a5,a1,512
    800061e4:	0792                	slli	a5,a5,0x4
    800061e6:	0001d517          	auipc	a0,0x1d
    800061ea:	ec250513          	addi	a0,a0,-318 # 800230a8 <disk+0xa8>
    800061ee:	953e                	add	a0,a0,a5
  if(write)
    800061f0:	e20d11e3          	bnez	s10,80006012 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061f4:	20058713          	addi	a4,a1,512
    800061f8:	00471693          	slli	a3,a4,0x4
    800061fc:	0001d717          	auipc	a4,0x1d
    80006200:	e0470713          	addi	a4,a4,-508 # 80023000 <disk>
    80006204:	9736                	add	a4,a4,a3
    80006206:	0a072423          	sw	zero,168(a4)
    8000620a:	b505                	j	8000602a <virtio_disk_rw+0xf4>

000000008000620c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000620c:	1101                	addi	sp,sp,-32
    8000620e:	ec06                	sd	ra,24(sp)
    80006210:	e822                	sd	s0,16(sp)
    80006212:	e426                	sd	s1,8(sp)
    80006214:	e04a                	sd	s2,0(sp)
    80006216:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006218:	0001f517          	auipc	a0,0x1f
    8000621c:	f1050513          	addi	a0,a0,-240 # 80025128 <disk+0x2128>
    80006220:	ffffb097          	auipc	ra,0xffffb
    80006224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006228:	10001737          	lui	a4,0x10001
    8000622c:	533c                	lw	a5,96(a4)
    8000622e:	8b8d                	andi	a5,a5,3
    80006230:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006232:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006236:	0001f797          	auipc	a5,0x1f
    8000623a:	dca78793          	addi	a5,a5,-566 # 80025000 <disk+0x2000>
    8000623e:	6b94                	ld	a3,16(a5)
    80006240:	0207d703          	lhu	a4,32(a5)
    80006244:	0026d783          	lhu	a5,2(a3)
    80006248:	06f70163          	beq	a4,a5,800062aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000624c:	0001d917          	auipc	s2,0x1d
    80006250:	db490913          	addi	s2,s2,-588 # 80023000 <disk>
    80006254:	0001f497          	auipc	s1,0x1f
    80006258:	dac48493          	addi	s1,s1,-596 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000625c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006260:	6898                	ld	a4,16(s1)
    80006262:	0204d783          	lhu	a5,32(s1)
    80006266:	8b9d                	andi	a5,a5,7
    80006268:	078e                	slli	a5,a5,0x3
    8000626a:	97ba                	add	a5,a5,a4
    8000626c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000626e:	20078713          	addi	a4,a5,512
    80006272:	0712                	slli	a4,a4,0x4
    80006274:	974a                	add	a4,a4,s2
    80006276:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000627a:	e731                	bnez	a4,800062c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000627c:	20078793          	addi	a5,a5,512
    80006280:	0792                	slli	a5,a5,0x4
    80006282:	97ca                	add	a5,a5,s2
    80006284:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006286:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000628a:	ffffc097          	auipc	ra,0xffffc
    8000628e:	f76080e7          	jalr	-138(ra) # 80002200 <wakeup>

    disk.used_idx += 1;
    80006292:	0204d783          	lhu	a5,32(s1)
    80006296:	2785                	addiw	a5,a5,1
    80006298:	17c2                	slli	a5,a5,0x30
    8000629a:	93c1                	srli	a5,a5,0x30
    8000629c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062a0:	6898                	ld	a4,16(s1)
    800062a2:	00275703          	lhu	a4,2(a4)
    800062a6:	faf71be3          	bne	a4,a5,8000625c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062aa:	0001f517          	auipc	a0,0x1f
    800062ae:	e7e50513          	addi	a0,a0,-386 # 80025128 <disk+0x2128>
    800062b2:	ffffb097          	auipc	ra,0xffffb
    800062b6:	9e6080e7          	jalr	-1562(ra) # 80000c98 <release>
}
    800062ba:	60e2                	ld	ra,24(sp)
    800062bc:	6442                	ld	s0,16(sp)
    800062be:	64a2                	ld	s1,8(sp)
    800062c0:	6902                	ld	s2,0(sp)
    800062c2:	6105                	addi	sp,sp,32
    800062c4:	8082                	ret
      panic("virtio_disk_intr status");
    800062c6:	00002517          	auipc	a0,0x2
    800062ca:	60a50513          	addi	a0,a0,1546 # 800088d0 <syscalls+0x3b0>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
