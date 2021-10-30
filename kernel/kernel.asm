
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
    80000068:	eac78793          	addi	a5,a5,-340 # 80005f10 <timervec>
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
    80000130:	50c080e7          	jalr	1292(ra) # 80002638 <either_copyin>
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
    800001d8:	f12080e7          	jalr	-238(ra) # 800020e6 <sleep>
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
    80000214:	3d2080e7          	jalr	978(ra) # 800025e2 <either_copyout>
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
    800002f6:	39c080e7          	jalr	924(ra) # 8000268e <procdump>
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
    8000044a:	f78080e7          	jalr	-136(ra) # 800023be <wakeup>
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
    8000047c:	2a078793          	addi	a5,a5,672 # 80021718 <devsw>
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
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1740+0x160>
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
    800008a4:	b1e080e7          	jalr	-1250(ra) # 800023be <wakeup>
    
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
    80000930:	7ba080e7          	jalr	1978(ra) # 800020e6 <sleep>
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
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	91c080e7          	jalr	-1764(ra) # 800027f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	074080e7          	jalr	116(ra) # 80005f50 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	050080e7          	jalr	80(ra) # 80001f34 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1740+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1740+0x160>
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
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	87c080e7          	jalr	-1924(ra) # 800027c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	89c080e7          	jalr	-1892(ra) # 800027f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	fde080e7          	jalr	-34(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fec080e7          	jalr	-20(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	1d2080e7          	jalr	466(ra) # 8000313e <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	862080e7          	jalr	-1950(ra) # 800037d6 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	80c080e7          	jalr	-2036(ra) # 80004788 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	0ee080e7          	jalr	238(ra) # 80006072 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d10080e7          	jalr	-752(ra) # 80001c9c <userinit>
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
    80001872:	c62a0a13          	addi	s4,s4,-926 # 800174d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
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
    800018a8:	17848493          	addi	s1,s1,376
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
    8000193e:	b9698993          	addi	s3,s3,-1130 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17848493          	addi	s1,s1,376
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
    80001a04:	ef07a783          	lw	a5,-272(a5) # 800088f0 <first.1703>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	dfe080e7          	jalr	-514(ra) # 80002808 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ec07ab23          	sw	zero,-298(a5) # 800088f0 <first.1703>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	d32080e7          	jalr	-718(ra) # 80003756 <fsinit>
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
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	90290913          	addi	s2,s2,-1790 # 800174d0 <tickslock>
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
    80001bee:	17848493          	addi	s1,s1,376
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a09d                	j	80001c5e <allocproc+0xa4>
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
    80001c14:	cd21                	beqz	a0,80001c6c <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c125                	beqz	a0,80001c84 <allocproc+0xca>
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
  p->rtime = 0;
    80001c4a:	1604a623          	sw	zero,364(s1)
  p->etime = 0;
    80001c4e:	1604aa23          	sw	zero,372(s1)
  p->ctime = ticks;
    80001c52:	00007797          	auipc	a5,0x7
    80001c56:	3de7a783          	lw	a5,990(a5) # 80009030 <ticks>
    80001c5a:	16f4a823          	sw	a5,368(s1)
}
    80001c5e:	8526                	mv	a0,s1
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef4080e7          	jalr	-268(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	bff1                	j	80001c5e <allocproc+0xa4>
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	edc080e7          	jalr	-292(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	b7d1                	j	80001c5e <allocproc+0xa4>

0000000080001c9c <userinit>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	f14080e7          	jalr	-236(ra) # 80001bba <allocproc>
    80001cae:	84aa                	mv	s1,a0
  initproc = p;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	36a7bc23          	sd	a0,888(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb8:	03400613          	li	a2,52
    80001cbc:	00007597          	auipc	a1,0x7
    80001cc0:	c4458593          	addi	a1,a1,-956 # 80008900 <initcode>
    80001cc4:	6928                	ld	a0,80(a0)
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	6a2080e7          	jalr	1698(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cce:	6785                	lui	a5,0x1
    80001cd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd8:	6cb8                	ld	a4,88(s1)
    80001cda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cdc:	4641                	li	a2,16
    80001cde:	00006597          	auipc	a1,0x6
    80001ce2:	52258593          	addi	a1,a1,1314 # 80008200 <digits+0x1c0>
    80001ce6:	15848513          	addi	a0,s1,344
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	148080e7          	jalr	328(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	51e50513          	addi	a0,a0,1310 # 80008210 <digits+0x1d0>
    80001cfa:	00002097          	auipc	ra,0x2
    80001cfe:	48a080e7          	jalr	1162(ra) # 80004184 <namei>
    80001d02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d06:	478d                	li	a5,3
    80001d08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c84080e7          	jalr	-892(ra) # 800019b0 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  } else if(n < 0){
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6bc080e7          	jalr	1724(ra) # 80001422 <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	656080e7          	jalr	1622(ra) # 800013da <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7179                	addi	sp,sp,-48
    80001d94:	f406                	sd	ra,40(sp)
    80001d96:	f022                	sd	s0,32(sp)
    80001d98:	ec26                	sd	s1,24(sp)
    80001d9a:	e84a                	sd	s2,16(sp)
    80001d9c:	e44e                	sd	s3,8(sp)
    80001d9e:	e052                	sd	s4,0(sp)
    80001da0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	c0e080e7          	jalr	-1010(ra) # 800019b0 <myproc>
    80001daa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e0e080e7          	jalr	-498(ra) # 80001bba <allocproc>
    80001db4:	10050f63          	beqz	a0,80001ed2 <fork+0x140>
    80001db8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dba:	04893603          	ld	a2,72(s2)
    80001dbe:	692c                	ld	a1,80(a0)
    80001dc0:	05093503          	ld	a0,80(s2)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	7aa080e7          	jalr	1962(ra) # 8000156e <uvmcopy>
    80001dcc:	04054a63          	bltz	a0,80001e20 <fork+0x8e>
  np->trace_mask = p->trace_mask;
    80001dd0:	16892783          	lw	a5,360(s2)
    80001dd4:	16f9a423          	sw	a5,360(s3)
  np->sz = p->sz;
    80001dd8:	04893783          	ld	a5,72(s2)
    80001ddc:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001de0:	05893683          	ld	a3,88(s2)
    80001de4:	87b6                	mv	a5,a3
    80001de6:	0589b703          	ld	a4,88(s3)
    80001dea:	12068693          	addi	a3,a3,288
    80001dee:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df2:	6788                	ld	a0,8(a5)
    80001df4:	6b8c                	ld	a1,16(a5)
    80001df6:	6f90                	ld	a2,24(a5)
    80001df8:	01073023          	sd	a6,0(a4)
    80001dfc:	e708                	sd	a0,8(a4)
    80001dfe:	eb0c                	sd	a1,16(a4)
    80001e00:	ef10                	sd	a2,24(a4)
    80001e02:	02078793          	addi	a5,a5,32
    80001e06:	02070713          	addi	a4,a4,32
    80001e0a:	fed792e3          	bne	a5,a3,80001dee <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e0e:	0589b783          	ld	a5,88(s3)
    80001e12:	0607b823          	sd	zero,112(a5)
    80001e16:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e1a:	15000a13          	li	s4,336
    80001e1e:	a03d                	j	80001e4c <fork+0xba>
    freeproc(np);
    80001e20:	854e                	mv	a0,s3
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	d40080e7          	jalr	-704(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e2a:	854e                	mv	a0,s3
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
    return -1;
    80001e34:	5a7d                	li	s4,-1
    80001e36:	a069                	j	80001ec0 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e38:	00003097          	auipc	ra,0x3
    80001e3c:	9e2080e7          	jalr	-1566(ra) # 8000481a <filedup>
    80001e40:	009987b3          	add	a5,s3,s1
    80001e44:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	01448763          	beq	s1,s4,80001e56 <fork+0xc4>
    if(p->ofile[i])
    80001e4c:	009907b3          	add	a5,s2,s1
    80001e50:	6388                	ld	a0,0(a5)
    80001e52:	f17d                	bnez	a0,80001e38 <fork+0xa6>
    80001e54:	bfcd                	j	80001e46 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e56:	15093503          	ld	a0,336(s2)
    80001e5a:	00002097          	auipc	ra,0x2
    80001e5e:	b36080e7          	jalr	-1226(ra) # 80003990 <idup>
    80001e62:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e66:	4641                	li	a2,16
    80001e68:	15890593          	addi	a1,s2,344
    80001e6c:	15898513          	addi	a0,s3,344
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	fc2080e7          	jalr	-62(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e78:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e7c:	854e                	mv	a0,s3
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	e1a080e7          	jalr	-486(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e86:	0000f497          	auipc	s1,0xf
    80001e8a:	43248493          	addi	s1,s1,1074 # 800112b8 <wait_lock>
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	d54080e7          	jalr	-684(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e98:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	dfa080e7          	jalr	-518(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ea6:	854e                	mv	a0,s3
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	d3c080e7          	jalr	-708(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001eb0:	478d                	li	a5,3
    80001eb2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>
}
    80001ec0:	8552                	mv	a0,s4
    80001ec2:	70a2                	ld	ra,40(sp)
    80001ec4:	7402                	ld	s0,32(sp)
    80001ec6:	64e2                	ld	s1,24(sp)
    80001ec8:	6942                	ld	s2,16(sp)
    80001eca:	69a2                	ld	s3,8(sp)
    80001ecc:	6a02                	ld	s4,0(sp)
    80001ece:	6145                	addi	sp,sp,48
    80001ed0:	8082                	ret
    return -1;
    80001ed2:	5a7d                	li	s4,-1
    80001ed4:	b7f5                	j	80001ec0 <fork+0x12e>

0000000080001ed6 <update_time>:
{
    80001ed6:	7179                	addi	sp,sp,-48
    80001ed8:	f406                	sd	ra,40(sp)
    80001eda:	f022                	sd	s0,32(sp)
    80001edc:	ec26                	sd	s1,24(sp)
    80001ede:	e84a                	sd	s2,16(sp)
    80001ee0:	e44e                	sd	s3,8(sp)
    80001ee2:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ee4:	0000f497          	auipc	s1,0xf
    80001ee8:	7ec48493          	addi	s1,s1,2028 # 800116d0 <proc>
    if (p->state == RUNNING) {
    80001eec:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    80001eee:	00015917          	auipc	s2,0x15
    80001ef2:	5e290913          	addi	s2,s2,1506 # 800174d0 <tickslock>
    80001ef6:	a811                	j	80001f0a <update_time+0x34>
    release(&p->lock); 
    80001ef8:	8526                	mv	a0,s1
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	d9e080e7          	jalr	-610(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f02:	17848493          	addi	s1,s1,376
    80001f06:	03248063          	beq	s1,s2,80001f26 <update_time+0x50>
    acquire(&p->lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	cd8080e7          	jalr	-808(ra) # 80000be4 <acquire>
    if (p->state == RUNNING) {
    80001f14:	4c9c                	lw	a5,24(s1)
    80001f16:	ff3791e3          	bne	a5,s3,80001ef8 <update_time+0x22>
      p->rtime++;
    80001f1a:	16c4a783          	lw	a5,364(s1)
    80001f1e:	2785                	addiw	a5,a5,1
    80001f20:	16f4a623          	sw	a5,364(s1)
    80001f24:	bfd1                	j	80001ef8 <update_time+0x22>
}
    80001f26:	70a2                	ld	ra,40(sp)
    80001f28:	7402                	ld	s0,32(sp)
    80001f2a:	64e2                	ld	s1,24(sp)
    80001f2c:	6942                	ld	s2,16(sp)
    80001f2e:	69a2                	ld	s3,8(sp)
    80001f30:	6145                	addi	sp,sp,48
    80001f32:	8082                	ret

0000000080001f34 <scheduler>:
{
    80001f34:	7139                	addi	sp,sp,-64
    80001f36:	fc06                	sd	ra,56(sp)
    80001f38:	f822                	sd	s0,48(sp)
    80001f3a:	f426                	sd	s1,40(sp)
    80001f3c:	f04a                	sd	s2,32(sp)
    80001f3e:	ec4e                	sd	s3,24(sp)
    80001f40:	e852                	sd	s4,16(sp)
    80001f42:	e456                	sd	s5,8(sp)
    80001f44:	e05a                	sd	s6,0(sp)
    80001f46:	0080                	addi	s0,sp,64
    80001f48:	8792                	mv	a5,tp
  int id = r_tp();
    80001f4a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f4c:	00779a93          	slli	s5,a5,0x7
    80001f50:	0000f717          	auipc	a4,0xf
    80001f54:	35070713          	addi	a4,a4,848 # 800112a0 <pid_lock>
    80001f58:	9756                	add	a4,a4,s5
    80001f5a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f5e:	0000f717          	auipc	a4,0xf
    80001f62:	37a70713          	addi	a4,a4,890 # 800112d8 <cpus+0x8>
    80001f66:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f68:	498d                	li	s3,3
        p->state = RUNNING;
    80001f6a:	4b11                	li	s6,4
        c->proc = p;
    80001f6c:	079e                	slli	a5,a5,0x7
    80001f6e:	0000fa17          	auipc	s4,0xf
    80001f72:	332a0a13          	addi	s4,s4,818 # 800112a0 <pid_lock>
    80001f76:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f78:	00015917          	auipc	s2,0x15
    80001f7c:	55890913          	addi	s2,s2,1368 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f88:	10079073          	csrw	sstatus,a5
    80001f8c:	0000f497          	auipc	s1,0xf
    80001f90:	74448493          	addi	s1,s1,1860 # 800116d0 <proc>
    80001f94:	a03d                	j	80001fc2 <scheduler+0x8e>
        p->state = RUNNING;
    80001f96:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f9a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f9e:	06048593          	addi	a1,s1,96
    80001fa2:	8556                	mv	a0,s5
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	7ba080e7          	jalr	1978(ra) # 8000275e <swtch>
        c->proc = 0;
    80001fac:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fba:	17848493          	addi	s1,s1,376
    80001fbe:	fd2481e3          	beq	s1,s2,80001f80 <scheduler+0x4c>
      acquire(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c20080e7          	jalr	-992(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001fcc:	4c9c                	lw	a5,24(s1)
    80001fce:	ff3791e3          	bne	a5,s3,80001fb0 <scheduler+0x7c>
    80001fd2:	b7d1                	j	80001f96 <scheduler+0x62>

0000000080001fd4 <sched>:
{
    80001fd4:	7179                	addi	sp,sp,-48
    80001fd6:	f406                	sd	ra,40(sp)
    80001fd8:	f022                	sd	s0,32(sp)
    80001fda:	ec26                	sd	s1,24(sp)
    80001fdc:	e84a                	sd	s2,16(sp)
    80001fde:	e44e                	sd	s3,8(sp)
    80001fe0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	9ce080e7          	jalr	-1586(ra) # 800019b0 <myproc>
    80001fea:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	b7e080e7          	jalr	-1154(ra) # 80000b6a <holding>
    80001ff4:	c93d                	beqz	a0,8000206a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ff8:	2781                	sext.w	a5,a5
    80001ffa:	079e                	slli	a5,a5,0x7
    80001ffc:	0000f717          	auipc	a4,0xf
    80002000:	2a470713          	addi	a4,a4,676 # 800112a0 <pid_lock>
    80002004:	97ba                	add	a5,a5,a4
    80002006:	0a87a703          	lw	a4,168(a5)
    8000200a:	4785                	li	a5,1
    8000200c:	06f71763          	bne	a4,a5,8000207a <sched+0xa6>
  if(p->state == RUNNING)
    80002010:	4c98                	lw	a4,24(s1)
    80002012:	4791                	li	a5,4
    80002014:	06f70b63          	beq	a4,a5,8000208a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002018:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000201e:	efb5                	bnez	a5,8000209a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002020:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002022:	0000f917          	auipc	s2,0xf
    80002026:	27e90913          	addi	s2,s2,638 # 800112a0 <pid_lock>
    8000202a:	2781                	sext.w	a5,a5
    8000202c:	079e                	slli	a5,a5,0x7
    8000202e:	97ca                	add	a5,a5,s2
    80002030:	0ac7a983          	lw	s3,172(a5)
    80002034:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	0000f597          	auipc	a1,0xf
    8000203e:	29e58593          	addi	a1,a1,670 # 800112d8 <cpus+0x8>
    80002042:	95be                	add	a1,a1,a5
    80002044:	06048513          	addi	a0,s1,96
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	716080e7          	jalr	1814(ra) # 8000275e <swtch>
    80002050:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002052:	2781                	sext.w	a5,a5
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	97ca                	add	a5,a5,s2
    80002058:	0b37a623          	sw	s3,172(a5)
}
    8000205c:	70a2                	ld	ra,40(sp)
    8000205e:	7402                	ld	s0,32(sp)
    80002060:	64e2                	ld	s1,24(sp)
    80002062:	6942                	ld	s2,16(sp)
    80002064:	69a2                	ld	s3,8(sp)
    80002066:	6145                	addi	sp,sp,48
    80002068:	8082                	ret
    panic("sched p->lock");
    8000206a:	00006517          	auipc	a0,0x6
    8000206e:	1ae50513          	addi	a0,a0,430 # 80008218 <digits+0x1d8>
    80002072:	ffffe097          	auipc	ra,0xffffe
    80002076:	4cc080e7          	jalr	1228(ra) # 8000053e <panic>
    panic("sched locks");
    8000207a:	00006517          	auipc	a0,0x6
    8000207e:	1ae50513          	addi	a0,a0,430 # 80008228 <digits+0x1e8>
    80002082:	ffffe097          	auipc	ra,0xffffe
    80002086:	4bc080e7          	jalr	1212(ra) # 8000053e <panic>
    panic("sched running");
    8000208a:	00006517          	auipc	a0,0x6
    8000208e:	1ae50513          	addi	a0,a0,430 # 80008238 <digits+0x1f8>
    80002092:	ffffe097          	auipc	ra,0xffffe
    80002096:	4ac080e7          	jalr	1196(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	1ae50513          	addi	a0,a0,430 # 80008248 <digits+0x208>
    800020a2:	ffffe097          	auipc	ra,0xffffe
    800020a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>

00000000800020aa <yield>:
{
    800020aa:	1101                	addi	sp,sp,-32
    800020ac:	ec06                	sd	ra,24(sp)
    800020ae:	e822                	sd	s0,16(sp)
    800020b0:	e426                	sd	s1,8(sp)
    800020b2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	8fc080e7          	jalr	-1796(ra) # 800019b0 <myproc>
    800020bc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020c6:	478d                	li	a5,3
    800020c8:	cc9c                	sw	a5,24(s1)
  sched();
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	f0a080e7          	jalr	-246(ra) # 80001fd4 <sched>
  release(&p->lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>
}
    800020dc:	60e2                	ld	ra,24(sp)
    800020de:	6442                	ld	s0,16(sp)
    800020e0:	64a2                	ld	s1,8(sp)
    800020e2:	6105                	addi	sp,sp,32
    800020e4:	8082                	ret

00000000800020e6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020e6:	7179                	addi	sp,sp,-48
    800020e8:	f406                	sd	ra,40(sp)
    800020ea:	f022                	sd	s0,32(sp)
    800020ec:	ec26                	sd	s1,24(sp)
    800020ee:	e84a                	sd	s2,16(sp)
    800020f0:	e44e                	sd	s3,8(sp)
    800020f2:	1800                	addi	s0,sp,48
    800020f4:	89aa                	mv	s3,a0
    800020f6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	8b8080e7          	jalr	-1864(ra) # 800019b0 <myproc>
    80002100:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ae2080e7          	jalr	-1310(ra) # 80000be4 <acquire>
  release(lk);
    8000210a:	854a                	mv	a0,s2
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002114:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002118:	4789                	li	a5,2
    8000211a:	cc9c                	sw	a5,24(s1)

  sched();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	eb8080e7          	jalr	-328(ra) # 80001fd4 <sched>

  // Tidy up.
  p->chan = 0;
    80002124:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	b6e080e7          	jalr	-1170(ra) # 80000c98 <release>
  acquire(lk);
    80002132:	854a                	mv	a0,s2
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	ab0080e7          	jalr	-1360(ra) # 80000be4 <acquire>
}
    8000213c:	70a2                	ld	ra,40(sp)
    8000213e:	7402                	ld	s0,32(sp)
    80002140:	64e2                	ld	s1,24(sp)
    80002142:	6942                	ld	s2,16(sp)
    80002144:	69a2                	ld	s3,8(sp)
    80002146:	6145                	addi	sp,sp,48
    80002148:	8082                	ret

000000008000214a <wait>:
{
    8000214a:	715d                	addi	sp,sp,-80
    8000214c:	e486                	sd	ra,72(sp)
    8000214e:	e0a2                	sd	s0,64(sp)
    80002150:	fc26                	sd	s1,56(sp)
    80002152:	f84a                	sd	s2,48(sp)
    80002154:	f44e                	sd	s3,40(sp)
    80002156:	f052                	sd	s4,32(sp)
    80002158:	ec56                	sd	s5,24(sp)
    8000215a:	e85a                	sd	s6,16(sp)
    8000215c:	e45e                	sd	s7,8(sp)
    8000215e:	e062                	sd	s8,0(sp)
    80002160:	0880                	addi	s0,sp,80
    80002162:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	84c080e7          	jalr	-1972(ra) # 800019b0 <myproc>
    8000216c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000216e:	0000f517          	auipc	a0,0xf
    80002172:	14a50513          	addi	a0,a0,330 # 800112b8 <wait_lock>
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a6e080e7          	jalr	-1426(ra) # 80000be4 <acquire>
    havekids = 0;
    8000217e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002180:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002182:	00015997          	auipc	s3,0x15
    80002186:	34e98993          	addi	s3,s3,846 # 800174d0 <tickslock>
        havekids = 1;
    8000218a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000218c:	0000fc17          	auipc	s8,0xf
    80002190:	12cc0c13          	addi	s8,s8,300 # 800112b8 <wait_lock>
    havekids = 0;
    80002194:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002196:	0000f497          	auipc	s1,0xf
    8000219a:	53a48493          	addi	s1,s1,1338 # 800116d0 <proc>
    8000219e:	a0bd                	j	8000220c <wait+0xc2>
          pid = np->pid;
    800021a0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021a4:	000b0e63          	beqz	s6,800021c0 <wait+0x76>
    800021a8:	4691                	li	a3,4
    800021aa:	02c48613          	addi	a2,s1,44
    800021ae:	85da                	mv	a1,s6
    800021b0:	05093503          	ld	a0,80(s2)
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	4be080e7          	jalr	1214(ra) # 80001672 <copyout>
    800021bc:	02054563          	bltz	a0,800021e6 <wait+0x9c>
          freeproc(np);
    800021c0:	8526                	mv	a0,s1
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	9a0080e7          	jalr	-1632(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
          release(&wait_lock);
    800021d4:	0000f517          	auipc	a0,0xf
    800021d8:	0e450513          	addi	a0,a0,228 # 800112b8 <wait_lock>
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	abc080e7          	jalr	-1348(ra) # 80000c98 <release>
          return pid;
    800021e4:	a09d                	j	8000224a <wait+0x100>
            release(&np->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	ab0080e7          	jalr	-1360(ra) # 80000c98 <release>
            release(&wait_lock);
    800021f0:	0000f517          	auipc	a0,0xf
    800021f4:	0c850513          	addi	a0,a0,200 # 800112b8 <wait_lock>
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
            return -1;
    80002200:	59fd                	li	s3,-1
    80002202:	a0a1                	j	8000224a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002204:	17848493          	addi	s1,s1,376
    80002208:	03348463          	beq	s1,s3,80002230 <wait+0xe6>
      if(np->parent == p){
    8000220c:	7c9c                	ld	a5,56(s1)
    8000220e:	ff279be3          	bne	a5,s2,80002204 <wait+0xba>
        acquire(&np->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	9d0080e7          	jalr	-1584(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000221c:	4c9c                	lw	a5,24(s1)
    8000221e:	f94781e3          	beq	a5,s4,800021a0 <wait+0x56>
        release(&np->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a74080e7          	jalr	-1420(ra) # 80000c98 <release>
        havekids = 1;
    8000222c:	8756                	mv	a4,s5
    8000222e:	bfd9                	j	80002204 <wait+0xba>
    if(!havekids || p->killed){
    80002230:	c701                	beqz	a4,80002238 <wait+0xee>
    80002232:	02892783          	lw	a5,40(s2)
    80002236:	c79d                	beqz	a5,80002264 <wait+0x11a>
      release(&wait_lock);
    80002238:	0000f517          	auipc	a0,0xf
    8000223c:	08050513          	addi	a0,a0,128 # 800112b8 <wait_lock>
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
      return -1;
    80002248:	59fd                	li	s3,-1
}
    8000224a:	854e                	mv	a0,s3
    8000224c:	60a6                	ld	ra,72(sp)
    8000224e:	6406                	ld	s0,64(sp)
    80002250:	74e2                	ld	s1,56(sp)
    80002252:	7942                	ld	s2,48(sp)
    80002254:	79a2                	ld	s3,40(sp)
    80002256:	7a02                	ld	s4,32(sp)
    80002258:	6ae2                	ld	s5,24(sp)
    8000225a:	6b42                	ld	s6,16(sp)
    8000225c:	6ba2                	ld	s7,8(sp)
    8000225e:	6c02                	ld	s8,0(sp)
    80002260:	6161                	addi	sp,sp,80
    80002262:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002264:	85e2                	mv	a1,s8
    80002266:	854a                	mv	a0,s2
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	e7e080e7          	jalr	-386(ra) # 800020e6 <sleep>
    havekids = 0;
    80002270:	b715                	j	80002194 <wait+0x4a>

0000000080002272 <waitx>:
{
    80002272:	711d                	addi	sp,sp,-96
    80002274:	ec86                	sd	ra,88(sp)
    80002276:	e8a2                	sd	s0,80(sp)
    80002278:	e4a6                	sd	s1,72(sp)
    8000227a:	e0ca                	sd	s2,64(sp)
    8000227c:	fc4e                	sd	s3,56(sp)
    8000227e:	f852                	sd	s4,48(sp)
    80002280:	f456                	sd	s5,40(sp)
    80002282:	f05a                	sd	s6,32(sp)
    80002284:	ec5e                	sd	s7,24(sp)
    80002286:	e862                	sd	s8,16(sp)
    80002288:	e466                	sd	s9,8(sp)
    8000228a:	e06a                	sd	s10,0(sp)
    8000228c:	1080                	addi	s0,sp,96
    8000228e:	8b2a                	mv	s6,a0
    80002290:	8c2e                	mv	s8,a1
    80002292:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	71c080e7          	jalr	1820(ra) # 800019b0 <myproc>
    8000229c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000229e:	0000f517          	auipc	a0,0xf
    800022a2:	01a50513          	addi	a0,a0,26 # 800112b8 <wait_lock>
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	93e080e7          	jalr	-1730(ra) # 80000be4 <acquire>
    havekids = 0;
    800022ae:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800022b0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022b2:	00015997          	auipc	s3,0x15
    800022b6:	21e98993          	addi	s3,s3,542 # 800174d0 <tickslock>
        havekids = 1;
    800022ba:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022bc:	0000fd17          	auipc	s10,0xf
    800022c0:	ffcd0d13          	addi	s10,s10,-4 # 800112b8 <wait_lock>
    havekids = 0;
    800022c4:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800022c6:	0000f497          	auipc	s1,0xf
    800022ca:	40a48493          	addi	s1,s1,1034 # 800116d0 <proc>
    800022ce:	a059                	j	80002354 <waitx+0xe2>
          pid = np->pid;
    800022d0:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800022d4:	16c4a703          	lw	a4,364(s1)
    800022d8:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800022dc:	1704a783          	lw	a5,368(s1)
    800022e0:	9f3d                	addw	a4,a4,a5
    800022e2:	1744a783          	lw	a5,372(s1)
    800022e6:	9f99                	subw	a5,a5,a4
    800022e8:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ec:	000b0e63          	beqz	s6,80002308 <waitx+0x96>
    800022f0:	4691                	li	a3,4
    800022f2:	02c48613          	addi	a2,s1,44
    800022f6:	85da                	mv	a1,s6
    800022f8:	05093503          	ld	a0,80(s2)
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	376080e7          	jalr	886(ra) # 80001672 <copyout>
    80002304:	02054563          	bltz	a0,8000232e <waitx+0xbc>
          freeproc(np);
    80002308:	8526                	mv	a0,s1
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	858080e7          	jalr	-1960(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002312:	8526                	mv	a0,s1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
          release(&wait_lock);
    8000231c:	0000f517          	auipc	a0,0xf
    80002320:	f9c50513          	addi	a0,a0,-100 # 800112b8 <wait_lock>
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	974080e7          	jalr	-1676(ra) # 80000c98 <release>
          return pid;
    8000232c:	a09d                	j	80002392 <waitx+0x120>
            release(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
            release(&wait_lock);
    80002338:	0000f517          	auipc	a0,0xf
    8000233c:	f8050513          	addi	a0,a0,-128 # 800112b8 <wait_lock>
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
            return -1;
    80002348:	59fd                	li	s3,-1
    8000234a:	a0a1                	j	80002392 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    8000234c:	17848493          	addi	s1,s1,376
    80002350:	03348463          	beq	s1,s3,80002378 <waitx+0x106>
      if(np->parent == p){
    80002354:	7c9c                	ld	a5,56(s1)
    80002356:	ff279be3          	bne	a5,s2,8000234c <waitx+0xda>
        acquire(&np->lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	888080e7          	jalr	-1912(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002364:	4c9c                	lw	a5,24(s1)
    80002366:	f74785e3          	beq	a5,s4,800022d0 <waitx+0x5e>
        release(&np->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
        havekids = 1;
    80002374:	8756                	mv	a4,s5
    80002376:	bfd9                	j	8000234c <waitx+0xda>
    if(!havekids || p->killed){
    80002378:	c701                	beqz	a4,80002380 <waitx+0x10e>
    8000237a:	02892783          	lw	a5,40(s2)
    8000237e:	cb8d                	beqz	a5,800023b0 <waitx+0x13e>
      release(&wait_lock);
    80002380:	0000f517          	auipc	a0,0xf
    80002384:	f3850513          	addi	a0,a0,-200 # 800112b8 <wait_lock>
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
      return -1;
    80002390:	59fd                	li	s3,-1
}
    80002392:	854e                	mv	a0,s3
    80002394:	60e6                	ld	ra,88(sp)
    80002396:	6446                	ld	s0,80(sp)
    80002398:	64a6                	ld	s1,72(sp)
    8000239a:	6906                	ld	s2,64(sp)
    8000239c:	79e2                	ld	s3,56(sp)
    8000239e:	7a42                	ld	s4,48(sp)
    800023a0:	7aa2                	ld	s5,40(sp)
    800023a2:	7b02                	ld	s6,32(sp)
    800023a4:	6be2                	ld	s7,24(sp)
    800023a6:	6c42                	ld	s8,16(sp)
    800023a8:	6ca2                	ld	s9,8(sp)
    800023aa:	6d02                	ld	s10,0(sp)
    800023ac:	6125                	addi	sp,sp,96
    800023ae:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023b0:	85ea                	mv	a1,s10
    800023b2:	854a                	mv	a0,s2
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	d32080e7          	jalr	-718(ra) # 800020e6 <sleep>
    havekids = 0;
    800023bc:	b721                	j	800022c4 <waitx+0x52>

00000000800023be <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023be:	7139                	addi	sp,sp,-64
    800023c0:	fc06                	sd	ra,56(sp)
    800023c2:	f822                	sd	s0,48(sp)
    800023c4:	f426                	sd	s1,40(sp)
    800023c6:	f04a                	sd	s2,32(sp)
    800023c8:	ec4e                	sd	s3,24(sp)
    800023ca:	e852                	sd	s4,16(sp)
    800023cc:	e456                	sd	s5,8(sp)
    800023ce:	0080                	addi	s0,sp,64
    800023d0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023d2:	0000f497          	auipc	s1,0xf
    800023d6:	2fe48493          	addi	s1,s1,766 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023da:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023dc:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023de:	00015917          	auipc	s2,0x15
    800023e2:	0f290913          	addi	s2,s2,242 # 800174d0 <tickslock>
    800023e6:	a821                	j	800023fe <wakeup+0x40>
        p->state = RUNNABLE;
    800023e8:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8aa080e7          	jalr	-1878(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f6:	17848493          	addi	s1,s1,376
    800023fa:	03248463          	beq	s1,s2,80002422 <wakeup+0x64>
    if(p != myproc()){
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	5b2080e7          	jalr	1458(ra) # 800019b0 <myproc>
    80002406:	fea488e3          	beq	s1,a0,800023f6 <wakeup+0x38>
      acquire(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002414:	4c9c                	lw	a5,24(s1)
    80002416:	fd379be3          	bne	a5,s3,800023ec <wakeup+0x2e>
    8000241a:	709c                	ld	a5,32(s1)
    8000241c:	fd4798e3          	bne	a5,s4,800023ec <wakeup+0x2e>
    80002420:	b7e1                	j	800023e8 <wakeup+0x2a>
    }
  }
}
    80002422:	70e2                	ld	ra,56(sp)
    80002424:	7442                	ld	s0,48(sp)
    80002426:	74a2                	ld	s1,40(sp)
    80002428:	7902                	ld	s2,32(sp)
    8000242a:	69e2                	ld	s3,24(sp)
    8000242c:	6a42                	ld	s4,16(sp)
    8000242e:	6aa2                	ld	s5,8(sp)
    80002430:	6121                	addi	sp,sp,64
    80002432:	8082                	ret

0000000080002434 <reparent>:
{
    80002434:	7179                	addi	sp,sp,-48
    80002436:	f406                	sd	ra,40(sp)
    80002438:	f022                	sd	s0,32(sp)
    8000243a:	ec26                	sd	s1,24(sp)
    8000243c:	e84a                	sd	s2,16(sp)
    8000243e:	e44e                	sd	s3,8(sp)
    80002440:	e052                	sd	s4,0(sp)
    80002442:	1800                	addi	s0,sp,48
    80002444:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002446:	0000f497          	auipc	s1,0xf
    8000244a:	28a48493          	addi	s1,s1,650 # 800116d0 <proc>
      pp->parent = initproc;
    8000244e:	00007a17          	auipc	s4,0x7
    80002452:	bdaa0a13          	addi	s4,s4,-1062 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002456:	00015997          	auipc	s3,0x15
    8000245a:	07a98993          	addi	s3,s3,122 # 800174d0 <tickslock>
    8000245e:	a029                	j	80002468 <reparent+0x34>
    80002460:	17848493          	addi	s1,s1,376
    80002464:	01348d63          	beq	s1,s3,8000247e <reparent+0x4a>
    if(pp->parent == p){
    80002468:	7c9c                	ld	a5,56(s1)
    8000246a:	ff279be3          	bne	a5,s2,80002460 <reparent+0x2c>
      pp->parent = initproc;
    8000246e:	000a3503          	ld	a0,0(s4)
    80002472:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002474:	00000097          	auipc	ra,0x0
    80002478:	f4a080e7          	jalr	-182(ra) # 800023be <wakeup>
    8000247c:	b7d5                	j	80002460 <reparent+0x2c>
}
    8000247e:	70a2                	ld	ra,40(sp)
    80002480:	7402                	ld	s0,32(sp)
    80002482:	64e2                	ld	s1,24(sp)
    80002484:	6942                	ld	s2,16(sp)
    80002486:	69a2                	ld	s3,8(sp)
    80002488:	6a02                	ld	s4,0(sp)
    8000248a:	6145                	addi	sp,sp,48
    8000248c:	8082                	ret

000000008000248e <exit>:
{
    8000248e:	7179                	addi	sp,sp,-48
    80002490:	f406                	sd	ra,40(sp)
    80002492:	f022                	sd	s0,32(sp)
    80002494:	ec26                	sd	s1,24(sp)
    80002496:	e84a                	sd	s2,16(sp)
    80002498:	e44e                	sd	s3,8(sp)
    8000249a:	e052                	sd	s4,0(sp)
    8000249c:	1800                	addi	s0,sp,48
    8000249e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	510080e7          	jalr	1296(ra) # 800019b0 <myproc>
    800024a8:	89aa                	mv	s3,a0
  if(p == initproc)
    800024aa:	00007797          	auipc	a5,0x7
    800024ae:	b7e7b783          	ld	a5,-1154(a5) # 80009028 <initproc>
    800024b2:	0d050493          	addi	s1,a0,208
    800024b6:	15050913          	addi	s2,a0,336
    800024ba:	02a79363          	bne	a5,a0,800024e0 <exit+0x52>
    panic("init exiting");
    800024be:	00006517          	auipc	a0,0x6
    800024c2:	da250513          	addi	a0,a0,-606 # 80008260 <digits+0x220>
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	078080e7          	jalr	120(ra) # 8000053e <panic>
      fileclose(f);
    800024ce:	00002097          	auipc	ra,0x2
    800024d2:	39e080e7          	jalr	926(ra) # 8000486c <fileclose>
      p->ofile[fd] = 0;
    800024d6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024da:	04a1                	addi	s1,s1,8
    800024dc:	01248563          	beq	s1,s2,800024e6 <exit+0x58>
    if(p->ofile[fd]){
    800024e0:	6088                	ld	a0,0(s1)
    800024e2:	f575                	bnez	a0,800024ce <exit+0x40>
    800024e4:	bfdd                	j	800024da <exit+0x4c>
  begin_op();
    800024e6:	00002097          	auipc	ra,0x2
    800024ea:	eba080e7          	jalr	-326(ra) # 800043a0 <begin_op>
  iput(p->cwd);
    800024ee:	1509b503          	ld	a0,336(s3)
    800024f2:	00001097          	auipc	ra,0x1
    800024f6:	696080e7          	jalr	1686(ra) # 80003b88 <iput>
  end_op();
    800024fa:	00002097          	auipc	ra,0x2
    800024fe:	f26080e7          	jalr	-218(ra) # 80004420 <end_op>
  p->cwd = 0;
    80002502:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002506:	0000f497          	auipc	s1,0xf
    8000250a:	db248493          	addi	s1,s1,-590 # 800112b8 <wait_lock>
    8000250e:	8526                	mv	a0,s1
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	6d4080e7          	jalr	1748(ra) # 80000be4 <acquire>
  reparent(p);
    80002518:	854e                	mv	a0,s3
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	f1a080e7          	jalr	-230(ra) # 80002434 <reparent>
  wakeup(p->parent);
    80002522:	0389b503          	ld	a0,56(s3)
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	e98080e7          	jalr	-360(ra) # 800023be <wakeup>
  acquire(&p->lock);
    8000252e:	854e                	mv	a0,s3
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002538:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000253c:	4795                	li	a5,5
    8000253e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002542:	00007797          	auipc	a5,0x7
    80002546:	aee7a783          	lw	a5,-1298(a5) # 80009030 <ticks>
    8000254a:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	748080e7          	jalr	1864(ra) # 80000c98 <release>
  sched();
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	a7c080e7          	jalr	-1412(ra) # 80001fd4 <sched>
  panic("zombie exit");
    80002560:	00006517          	auipc	a0,0x6
    80002564:	d1050513          	addi	a0,a0,-752 # 80008270 <digits+0x230>
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	fd6080e7          	jalr	-42(ra) # 8000053e <panic>

0000000080002570 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002570:	7179                	addi	sp,sp,-48
    80002572:	f406                	sd	ra,40(sp)
    80002574:	f022                	sd	s0,32(sp)
    80002576:	ec26                	sd	s1,24(sp)
    80002578:	e84a                	sd	s2,16(sp)
    8000257a:	e44e                	sd	s3,8(sp)
    8000257c:	1800                	addi	s0,sp,48
    8000257e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002580:	0000f497          	auipc	s1,0xf
    80002584:	15048493          	addi	s1,s1,336 # 800116d0 <proc>
    80002588:	00015997          	auipc	s3,0x15
    8000258c:	f4898993          	addi	s3,s3,-184 # 800174d0 <tickslock>
    acquire(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	652080e7          	jalr	1618(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000259a:	589c                	lw	a5,48(s1)
    8000259c:	01278d63          	beq	a5,s2,800025b6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025a0:	8526                	mv	a0,s1
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	6f6080e7          	jalr	1782(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025aa:	17848493          	addi	s1,s1,376
    800025ae:	ff3491e3          	bne	s1,s3,80002590 <kill+0x20>
  }
  return -1;
    800025b2:	557d                	li	a0,-1
    800025b4:	a829                	j	800025ce <kill+0x5e>
      p->killed = 1;
    800025b6:	4785                	li	a5,1
    800025b8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025ba:	4c98                	lw	a4,24(s1)
    800025bc:	4789                	li	a5,2
    800025be:	00f70f63          	beq	a4,a5,800025dc <kill+0x6c>
      release(&p->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	6d4080e7          	jalr	1748(ra) # 80000c98 <release>
      return 0;
    800025cc:	4501                	li	a0,0
}
    800025ce:	70a2                	ld	ra,40(sp)
    800025d0:	7402                	ld	s0,32(sp)
    800025d2:	64e2                	ld	s1,24(sp)
    800025d4:	6942                	ld	s2,16(sp)
    800025d6:	69a2                	ld	s3,8(sp)
    800025d8:	6145                	addi	sp,sp,48
    800025da:	8082                	ret
        p->state = RUNNABLE;
    800025dc:	478d                	li	a5,3
    800025de:	cc9c                	sw	a5,24(s1)
    800025e0:	b7cd                	j	800025c2 <kill+0x52>

00000000800025e2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025e2:	7179                	addi	sp,sp,-48
    800025e4:	f406                	sd	ra,40(sp)
    800025e6:	f022                	sd	s0,32(sp)
    800025e8:	ec26                	sd	s1,24(sp)
    800025ea:	e84a                	sd	s2,16(sp)
    800025ec:	e44e                	sd	s3,8(sp)
    800025ee:	e052                	sd	s4,0(sp)
    800025f0:	1800                	addi	s0,sp,48
    800025f2:	84aa                	mv	s1,a0
    800025f4:	892e                	mv	s2,a1
    800025f6:	89b2                	mv	s3,a2
    800025f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025fa:	fffff097          	auipc	ra,0xfffff
    800025fe:	3b6080e7          	jalr	950(ra) # 800019b0 <myproc>
  if(user_dst){
    80002602:	c08d                	beqz	s1,80002624 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002604:	86d2                	mv	a3,s4
    80002606:	864e                	mv	a2,s3
    80002608:	85ca                	mv	a1,s2
    8000260a:	6928                	ld	a0,80(a0)
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	066080e7          	jalr	102(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002614:	70a2                	ld	ra,40(sp)
    80002616:	7402                	ld	s0,32(sp)
    80002618:	64e2                	ld	s1,24(sp)
    8000261a:	6942                	ld	s2,16(sp)
    8000261c:	69a2                	ld	s3,8(sp)
    8000261e:	6a02                	ld	s4,0(sp)
    80002620:	6145                	addi	sp,sp,48
    80002622:	8082                	ret
    memmove((char *)dst, src, len);
    80002624:	000a061b          	sext.w	a2,s4
    80002628:	85ce                	mv	a1,s3
    8000262a:	854a                	mv	a0,s2
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	714080e7          	jalr	1812(ra) # 80000d40 <memmove>
    return 0;
    80002634:	8526                	mv	a0,s1
    80002636:	bff9                	j	80002614 <either_copyout+0x32>

0000000080002638 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	e052                	sd	s4,0(sp)
    80002646:	1800                	addi	s0,sp,48
    80002648:	892a                	mv	s2,a0
    8000264a:	84ae                	mv	s1,a1
    8000264c:	89b2                	mv	s3,a2
    8000264e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	360080e7          	jalr	864(ra) # 800019b0 <myproc>
  if(user_src){
    80002658:	c08d                	beqz	s1,8000267a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000265a:	86d2                	mv	a3,s4
    8000265c:	864e                	mv	a2,s3
    8000265e:	85ca                	mv	a1,s2
    80002660:	6928                	ld	a0,80(a0)
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	09c080e7          	jalr	156(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000266a:	70a2                	ld	ra,40(sp)
    8000266c:	7402                	ld	s0,32(sp)
    8000266e:	64e2                	ld	s1,24(sp)
    80002670:	6942                	ld	s2,16(sp)
    80002672:	69a2                	ld	s3,8(sp)
    80002674:	6a02                	ld	s4,0(sp)
    80002676:	6145                	addi	sp,sp,48
    80002678:	8082                	ret
    memmove(dst, (char*)src, len);
    8000267a:	000a061b          	sext.w	a2,s4
    8000267e:	85ce                	mv	a1,s3
    80002680:	854a                	mv	a0,s2
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	6be080e7          	jalr	1726(ra) # 80000d40 <memmove>
    return 0;
    8000268a:	8526                	mv	a0,s1
    8000268c:	bff9                	j	8000266a <either_copyin+0x32>

000000008000268e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000268e:	715d                	addi	sp,sp,-80
    80002690:	e486                	sd	ra,72(sp)
    80002692:	e0a2                	sd	s0,64(sp)
    80002694:	fc26                	sd	s1,56(sp)
    80002696:	f84a                	sd	s2,48(sp)
    80002698:	f44e                	sd	s3,40(sp)
    8000269a:	f052                	sd	s4,32(sp)
    8000269c:	ec56                	sd	s5,24(sp)
    8000269e:	e85a                	sd	s6,16(sp)
    800026a0:	e45e                	sd	s7,8(sp)
    800026a2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026a4:	00006517          	auipc	a0,0x6
    800026a8:	d7c50513          	addi	a0,a0,-644 # 80008420 <states.1740+0x160>
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	edc080e7          	jalr	-292(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b4:	0000f497          	auipc	s1,0xf
    800026b8:	17448493          	addi	s1,s1,372 # 80011828 <proc+0x158>
    800026bc:	00015917          	auipc	s2,0x15
    800026c0:	f6c90913          	addi	s2,s2,-148 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026c6:	00006997          	auipc	s3,0x6
    800026ca:	bba98993          	addi	s3,s3,-1094 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800026ce:	00006a97          	auipc	s5,0x6
    800026d2:	bbaa8a93          	addi	s5,s5,-1094 # 80008288 <digits+0x248>
    printf("\n");
    800026d6:	00006a17          	auipc	s4,0x6
    800026da:	d4aa0a13          	addi	s4,s4,-694 # 80008420 <states.1740+0x160>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026de:	00006b97          	auipc	s7,0x6
    800026e2:	be2b8b93          	addi	s7,s7,-1054 # 800082c0 <states.1740>
    800026e6:	a00d                	j	80002708 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026e8:	ed86a583          	lw	a1,-296(a3)
    800026ec:	8556                	mv	a0,s5
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	e9a080e7          	jalr	-358(ra) # 80000588 <printf>
    printf("\n");
    800026f6:	8552                	mv	a0,s4
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	e90080e7          	jalr	-368(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002700:	17848493          	addi	s1,s1,376
    80002704:	03248163          	beq	s1,s2,80002726 <procdump+0x98>
    if(p->state == UNUSED)
    80002708:	86a6                	mv	a3,s1
    8000270a:	ec04a783          	lw	a5,-320(s1)
    8000270e:	dbed                	beqz	a5,80002700 <procdump+0x72>
      state = "???";
    80002710:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002712:	fcfb6be3          	bltu	s6,a5,800026e8 <procdump+0x5a>
    80002716:	1782                	slli	a5,a5,0x20
    80002718:	9381                	srli	a5,a5,0x20
    8000271a:	078e                	slli	a5,a5,0x3
    8000271c:	97de                	add	a5,a5,s7
    8000271e:	6390                	ld	a2,0(a5)
    80002720:	f661                	bnez	a2,800026e8 <procdump+0x5a>
      state = "???";
    80002722:	864e                	mv	a2,s3
    80002724:	b7d1                	j	800026e8 <procdump+0x5a>
  }
}
    80002726:	60a6                	ld	ra,72(sp)
    80002728:	6406                	ld	s0,64(sp)
    8000272a:	74e2                	ld	s1,56(sp)
    8000272c:	7942                	ld	s2,48(sp)
    8000272e:	79a2                	ld	s3,40(sp)
    80002730:	7a02                	ld	s4,32(sp)
    80002732:	6ae2                	ld	s5,24(sp)
    80002734:	6b42                	ld	s6,16(sp)
    80002736:	6ba2                	ld	s7,8(sp)
    80002738:	6161                	addi	sp,sp,80
    8000273a:	8082                	ret

000000008000273c <trace>:

// enabling tracing for the current process
void
trace(int trace_mask)
{
    8000273c:	1101                	addi	sp,sp,-32
    8000273e:	ec06                	sd	ra,24(sp)
    80002740:	e822                	sd	s0,16(sp)
    80002742:	e426                	sd	s1,8(sp)
    80002744:	1000                	addi	s0,sp,32
    80002746:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	268080e7          	jalr	616(ra) # 800019b0 <myproc>
  p->trace_mask = trace_mask;
    80002750:	16952423          	sw	s1,360(a0)
    80002754:	60e2                	ld	ra,24(sp)
    80002756:	6442                	ld	s0,16(sp)
    80002758:	64a2                	ld	s1,8(sp)
    8000275a:	6105                	addi	sp,sp,32
    8000275c:	8082                	ret

000000008000275e <swtch>:
    8000275e:	00153023          	sd	ra,0(a0)
    80002762:	00253423          	sd	sp,8(a0)
    80002766:	e900                	sd	s0,16(a0)
    80002768:	ed04                	sd	s1,24(a0)
    8000276a:	03253023          	sd	s2,32(a0)
    8000276e:	03353423          	sd	s3,40(a0)
    80002772:	03453823          	sd	s4,48(a0)
    80002776:	03553c23          	sd	s5,56(a0)
    8000277a:	05653023          	sd	s6,64(a0)
    8000277e:	05753423          	sd	s7,72(a0)
    80002782:	05853823          	sd	s8,80(a0)
    80002786:	05953c23          	sd	s9,88(a0)
    8000278a:	07a53023          	sd	s10,96(a0)
    8000278e:	07b53423          	sd	s11,104(a0)
    80002792:	0005b083          	ld	ra,0(a1)
    80002796:	0085b103          	ld	sp,8(a1)
    8000279a:	6980                	ld	s0,16(a1)
    8000279c:	6d84                	ld	s1,24(a1)
    8000279e:	0205b903          	ld	s2,32(a1)
    800027a2:	0285b983          	ld	s3,40(a1)
    800027a6:	0305ba03          	ld	s4,48(a1)
    800027aa:	0385ba83          	ld	s5,56(a1)
    800027ae:	0405bb03          	ld	s6,64(a1)
    800027b2:	0485bb83          	ld	s7,72(a1)
    800027b6:	0505bc03          	ld	s8,80(a1)
    800027ba:	0585bc83          	ld	s9,88(a1)
    800027be:	0605bd03          	ld	s10,96(a1)
    800027c2:	0685bd83          	ld	s11,104(a1)
    800027c6:	8082                	ret

00000000800027c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027c8:	1141                	addi	sp,sp,-16
    800027ca:	e406                	sd	ra,8(sp)
    800027cc:	e022                	sd	s0,0(sp)
    800027ce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027d0:	00006597          	auipc	a1,0x6
    800027d4:	b2058593          	addi	a1,a1,-1248 # 800082f0 <states.1740+0x30>
    800027d8:	00015517          	auipc	a0,0x15
    800027dc:	cf850513          	addi	a0,a0,-776 # 800174d0 <tickslock>
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800027e8:	60a2                	ld	ra,8(sp)
    800027ea:	6402                	ld	s0,0(sp)
    800027ec:	0141                	addi	sp,sp,16
    800027ee:	8082                	ret

00000000800027f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027f0:	1141                	addi	sp,sp,-16
    800027f2:	e422                	sd	s0,8(sp)
    800027f4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f6:	00003797          	auipc	a5,0x3
    800027fa:	68a78793          	addi	a5,a5,1674 # 80005e80 <kernelvec>
    800027fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002802:	6422                	ld	s0,8(sp)
    80002804:	0141                	addi	sp,sp,16
    80002806:	8082                	ret

0000000080002808 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002808:	1141                	addi	sp,sp,-16
    8000280a:	e406                	sd	ra,8(sp)
    8000280c:	e022                	sd	s0,0(sp)
    8000280e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	1a0080e7          	jalr	416(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002818:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000281c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000281e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002822:	00004617          	auipc	a2,0x4
    80002826:	7de60613          	addi	a2,a2,2014 # 80007000 <_trampoline>
    8000282a:	00004697          	auipc	a3,0x4
    8000282e:	7d668693          	addi	a3,a3,2006 # 80007000 <_trampoline>
    80002832:	8e91                	sub	a3,a3,a2
    80002834:	040007b7          	lui	a5,0x4000
    80002838:	17fd                	addi	a5,a5,-1
    8000283a:	07b2                	slli	a5,a5,0xc
    8000283c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002842:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002844:	180026f3          	csrr	a3,satp
    80002848:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000284a:	6d38                	ld	a4,88(a0)
    8000284c:	6134                	ld	a3,64(a0)
    8000284e:	6585                	lui	a1,0x1
    80002850:	96ae                	add	a3,a3,a1
    80002852:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002854:	6d38                	ld	a4,88(a0)
    80002856:	00000697          	auipc	a3,0x0
    8000285a:	14668693          	addi	a3,a3,326 # 8000299c <usertrap>
    8000285e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002860:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002862:	8692                	mv	a3,tp
    80002864:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002866:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000286a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000286e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002872:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002876:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002878:	6f18                	ld	a4,24(a4)
    8000287a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000287e:	692c                	ld	a1,80(a0)
    80002880:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002882:	00005717          	auipc	a4,0x5
    80002886:	80e70713          	addi	a4,a4,-2034 # 80007090 <userret>
    8000288a:	8f11                	sub	a4,a4,a2
    8000288c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000288e:	577d                	li	a4,-1
    80002890:	177e                	slli	a4,a4,0x3f
    80002892:	8dd9                	or	a1,a1,a4
    80002894:	02000537          	lui	a0,0x2000
    80002898:	157d                	addi	a0,a0,-1
    8000289a:	0536                	slli	a0,a0,0xd
    8000289c:	9782                	jalr	a5
}
    8000289e:	60a2                	ld	ra,8(sp)
    800028a0:	6402                	ld	s0,0(sp)
    800028a2:	0141                	addi	sp,sp,16
    800028a4:	8082                	ret

00000000800028a6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028a6:	1101                	addi	sp,sp,-32
    800028a8:	ec06                	sd	ra,24(sp)
    800028aa:	e822                	sd	s0,16(sp)
    800028ac:	e426                	sd	s1,8(sp)
    800028ae:	e04a                	sd	s2,0(sp)
    800028b0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028b2:	00015917          	auipc	s2,0x15
    800028b6:	c1e90913          	addi	s2,s2,-994 # 800174d0 <tickslock>
    800028ba:	854a                	mv	a0,s2
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	328080e7          	jalr	808(ra) # 80000be4 <acquire>
  ticks++;
    800028c4:	00006497          	auipc	s1,0x6
    800028c8:	76c48493          	addi	s1,s1,1900 # 80009030 <ticks>
    800028cc:	409c                	lw	a5,0(s1)
    800028ce:	2785                	addiw	a5,a5,1
    800028d0:	c09c                	sw	a5,0(s1)
  update_time();
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	604080e7          	jalr	1540(ra) # 80001ed6 <update_time>
  wakeup(&ticks);
    800028da:	8526                	mv	a0,s1
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	ae2080e7          	jalr	-1310(ra) # 800023be <wakeup>
  release(&tickslock);
    800028e4:	854a                	mv	a0,s2
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	3b2080e7          	jalr	946(ra) # 80000c98 <release>
}
    800028ee:	60e2                	ld	ra,24(sp)
    800028f0:	6442                	ld	s0,16(sp)
    800028f2:	64a2                	ld	s1,8(sp)
    800028f4:	6902                	ld	s2,0(sp)
    800028f6:	6105                	addi	sp,sp,32
    800028f8:	8082                	ret

00000000800028fa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028fa:	1101                	addi	sp,sp,-32
    800028fc:	ec06                	sd	ra,24(sp)
    800028fe:	e822                	sd	s0,16(sp)
    80002900:	e426                	sd	s1,8(sp)
    80002902:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002904:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002908:	00074d63          	bltz	a4,80002922 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000290c:	57fd                	li	a5,-1
    8000290e:	17fe                	slli	a5,a5,0x3f
    80002910:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002912:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002914:	06f70363          	beq	a4,a5,8000297a <devintr+0x80>
  }
}
    80002918:	60e2                	ld	ra,24(sp)
    8000291a:	6442                	ld	s0,16(sp)
    8000291c:	64a2                	ld	s1,8(sp)
    8000291e:	6105                	addi	sp,sp,32
    80002920:	8082                	ret
     (scause & 0xff) == 9){
    80002922:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002926:	46a5                	li	a3,9
    80002928:	fed792e3          	bne	a5,a3,8000290c <devintr+0x12>
    int irq = plic_claim();
    8000292c:	00003097          	auipc	ra,0x3
    80002930:	65c080e7          	jalr	1628(ra) # 80005f88 <plic_claim>
    80002934:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002936:	47a9                	li	a5,10
    80002938:	02f50763          	beq	a0,a5,80002966 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000293c:	4785                	li	a5,1
    8000293e:	02f50963          	beq	a0,a5,80002970 <devintr+0x76>
    return 1;
    80002942:	4505                	li	a0,1
    } else if(irq){
    80002944:	d8f1                	beqz	s1,80002918 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002946:	85a6                	mv	a1,s1
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	9b050513          	addi	a0,a0,-1616 # 800082f8 <states.1740+0x38>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	c38080e7          	jalr	-968(ra) # 80000588 <printf>
      plic_complete(irq);
    80002958:	8526                	mv	a0,s1
    8000295a:	00003097          	auipc	ra,0x3
    8000295e:	652080e7          	jalr	1618(ra) # 80005fac <plic_complete>
    return 1;
    80002962:	4505                	li	a0,1
    80002964:	bf55                	j	80002918 <devintr+0x1e>
      uartintr();
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	042080e7          	jalr	66(ra) # 800009a8 <uartintr>
    8000296e:	b7ed                	j	80002958 <devintr+0x5e>
      virtio_disk_intr();
    80002970:	00004097          	auipc	ra,0x4
    80002974:	b1c080e7          	jalr	-1252(ra) # 8000648c <virtio_disk_intr>
    80002978:	b7c5                	j	80002958 <devintr+0x5e>
    if(cpuid() == 0){
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	00a080e7          	jalr	10(ra) # 80001984 <cpuid>
    80002982:	c901                	beqz	a0,80002992 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002984:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002988:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000298a:	14479073          	csrw	sip,a5
    return 2;
    8000298e:	4509                	li	a0,2
    80002990:	b761                	j	80002918 <devintr+0x1e>
      clockintr();
    80002992:	00000097          	auipc	ra,0x0
    80002996:	f14080e7          	jalr	-236(ra) # 800028a6 <clockintr>
    8000299a:	b7ed                	j	80002984 <devintr+0x8a>

000000008000299c <usertrap>:
{
    8000299c:	1101                	addi	sp,sp,-32
    8000299e:	ec06                	sd	ra,24(sp)
    800029a0:	e822                	sd	s0,16(sp)
    800029a2:	e426                	sd	s1,8(sp)
    800029a4:	e04a                	sd	s2,0(sp)
    800029a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029ac:	1007f793          	andi	a5,a5,256
    800029b0:	e3ad                	bnez	a5,80002a12 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b2:	00003797          	auipc	a5,0x3
    800029b6:	4ce78793          	addi	a5,a5,1230 # 80005e80 <kernelvec>
    800029ba:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	ff2080e7          	jalr	-14(ra) # 800019b0 <myproc>
    800029c6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029c8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ca:	14102773          	csrr	a4,sepc
    800029ce:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029d4:	47a1                	li	a5,8
    800029d6:	04f71c63          	bne	a4,a5,80002a2e <usertrap+0x92>
    if(p->killed)
    800029da:	551c                	lw	a5,40(a0)
    800029dc:	e3b9                	bnez	a5,80002a22 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029de:	6cb8                	ld	a4,88(s1)
    800029e0:	6f1c                	ld	a5,24(a4)
    800029e2:	0791                	addi	a5,a5,4
    800029e4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ee:	10079073          	csrw	sstatus,a5
    syscall();
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	2e0080e7          	jalr	736(ra) # 80002cd2 <syscall>
  if(p->killed)
    800029fa:	549c                	lw	a5,40(s1)
    800029fc:	ebc1                	bnez	a5,80002a8c <usertrap+0xf0>
  usertrapret();
    800029fe:	00000097          	auipc	ra,0x0
    80002a02:	e0a080e7          	jalr	-502(ra) # 80002808 <usertrapret>
}
    80002a06:	60e2                	ld	ra,24(sp)
    80002a08:	6442                	ld	s0,16(sp)
    80002a0a:	64a2                	ld	s1,8(sp)
    80002a0c:	6902                	ld	s2,0(sp)
    80002a0e:	6105                	addi	sp,sp,32
    80002a10:	8082                	ret
    panic("usertrap: not from user mode");
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	90650513          	addi	a0,a0,-1786 # 80008318 <states.1740+0x58>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b24080e7          	jalr	-1244(ra) # 8000053e <panic>
      exit(-1);
    80002a22:	557d                	li	a0,-1
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	a6a080e7          	jalr	-1430(ra) # 8000248e <exit>
    80002a2c:	bf4d                	j	800029de <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	ecc080e7          	jalr	-308(ra) # 800028fa <devintr>
    80002a36:	892a                	mv	s2,a0
    80002a38:	c501                	beqz	a0,80002a40 <usertrap+0xa4>
  if(p->killed)
    80002a3a:	549c                	lw	a5,40(s1)
    80002a3c:	c3a1                	beqz	a5,80002a7c <usertrap+0xe0>
    80002a3e:	a815                	j	80002a72 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a40:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a44:	5890                	lw	a2,48(s1)
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	8f250513          	addi	a0,a0,-1806 # 80008338 <states.1740+0x78>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b3a080e7          	jalr	-1222(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a56:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a5a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	90a50513          	addi	a0,a0,-1782 # 80008368 <states.1740+0xa8>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	b22080e7          	jalr	-1246(ra) # 80000588 <printf>
    p->killed = 1;
    80002a6e:	4785                	li	a5,1
    80002a70:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a72:	557d                	li	a0,-1
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	a1a080e7          	jalr	-1510(ra) # 8000248e <exit>
  if(which_dev == 2)
    80002a7c:	4789                	li	a5,2
    80002a7e:	f8f910e3          	bne	s2,a5,800029fe <usertrap+0x62>
    yield();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	628080e7          	jalr	1576(ra) # 800020aa <yield>
    80002a8a:	bf95                	j	800029fe <usertrap+0x62>
  int which_dev = 0;
    80002a8c:	4901                	li	s2,0
    80002a8e:	b7d5                	j	80002a72 <usertrap+0xd6>

0000000080002a90 <kerneltrap>:
{
    80002a90:	7179                	addi	sp,sp,-48
    80002a92:	f406                	sd	ra,40(sp)
    80002a94:	f022                	sd	s0,32(sp)
    80002a96:	ec26                	sd	s1,24(sp)
    80002a98:	e84a                	sd	s2,16(sp)
    80002a9a:	e44e                	sd	s3,8(sp)
    80002a9c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aaa:	1004f793          	andi	a5,s1,256
    80002aae:	cb85                	beqz	a5,80002ade <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ab6:	ef85                	bnez	a5,80002aee <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	e42080e7          	jalr	-446(ra) # 800028fa <devintr>
    80002ac0:	cd1d                	beqz	a0,80002afe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac2:	4789                	li	a5,2
    80002ac4:	06f50a63          	beq	a0,a5,80002b38 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002acc:	10049073          	csrw	sstatus,s1
}
    80002ad0:	70a2                	ld	ra,40(sp)
    80002ad2:	7402                	ld	s0,32(sp)
    80002ad4:	64e2                	ld	s1,24(sp)
    80002ad6:	6942                	ld	s2,16(sp)
    80002ad8:	69a2                	ld	s3,8(sp)
    80002ada:	6145                	addi	sp,sp,48
    80002adc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	8aa50513          	addi	a0,a0,-1878 # 80008388 <states.1740+0xc8>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	a58080e7          	jalr	-1448(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	8c250513          	addi	a0,a0,-1854 # 800083b0 <states.1740+0xf0>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a48080e7          	jalr	-1464(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002afe:	85ce                	mv	a1,s3
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	8d050513          	addi	a0,a0,-1840 # 800083d0 <states.1740+0x110>
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a80080e7          	jalr	-1408(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b14:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	8c850513          	addi	a0,a0,-1848 # 800083e0 <states.1740+0x120>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a68080e7          	jalr	-1432(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	8d050513          	addi	a0,a0,-1840 # 800083f8 <states.1740+0x138>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a0e080e7          	jalr	-1522(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	e78080e7          	jalr	-392(ra) # 800019b0 <myproc>
    80002b40:	d541                	beqz	a0,80002ac8 <kerneltrap+0x38>
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	e6e080e7          	jalr	-402(ra) # 800019b0 <myproc>
    80002b4a:	4d18                	lw	a4,24(a0)
    80002b4c:	4791                	li	a5,4
    80002b4e:	f6f71de3          	bne	a4,a5,80002ac8 <kerneltrap+0x38>
    yield();
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	558080e7          	jalr	1368(ra) # 800020aa <yield>
    80002b5a:	b7bd                	j	80002ac8 <kerneltrap+0x38>

0000000080002b5c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
    80002b66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e48080e7          	jalr	-440(ra) # 800019b0 <myproc>
  switch (n) {
    80002b70:	4795                	li	a5,5
    80002b72:	0497e163          	bltu	a5,s1,80002bb4 <argraw+0x58>
    80002b76:	048a                	slli	s1,s1,0x2
    80002b78:	00006717          	auipc	a4,0x6
    80002b7c:	99070713          	addi	a4,a4,-1648 # 80008508 <states.1740+0x248>
    80002b80:	94ba                	add	s1,s1,a4
    80002b82:	409c                	lw	a5,0(s1)
    80002b84:	97ba                	add	a5,a5,a4
    80002b86:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b88:	6d3c                	ld	a5,88(a0)
    80002b8a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b8c:	60e2                	ld	ra,24(sp)
    80002b8e:	6442                	ld	s0,16(sp)
    80002b90:	64a2                	ld	s1,8(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret
    return p->trapframe->a1;
    80002b96:	6d3c                	ld	a5,88(a0)
    80002b98:	7fa8                	ld	a0,120(a5)
    80002b9a:	bfcd                	j	80002b8c <argraw+0x30>
    return p->trapframe->a2;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	63c8                	ld	a0,128(a5)
    80002ba0:	b7f5                	j	80002b8c <argraw+0x30>
    return p->trapframe->a3;
    80002ba2:	6d3c                	ld	a5,88(a0)
    80002ba4:	67c8                	ld	a0,136(a5)
    80002ba6:	b7dd                	j	80002b8c <argraw+0x30>
    return p->trapframe->a4;
    80002ba8:	6d3c                	ld	a5,88(a0)
    80002baa:	6bc8                	ld	a0,144(a5)
    80002bac:	b7c5                	j	80002b8c <argraw+0x30>
    return p->trapframe->a5;
    80002bae:	6d3c                	ld	a5,88(a0)
    80002bb0:	6fc8                	ld	a0,152(a5)
    80002bb2:	bfe9                	j	80002b8c <argraw+0x30>
  panic("argraw");
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	85450513          	addi	a0,a0,-1964 # 80008408 <states.1740+0x148>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	982080e7          	jalr	-1662(ra) # 8000053e <panic>

0000000080002bc4 <fetchaddr>:
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84aa                	mv	s1,a0
    80002bd2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	ddc080e7          	jalr	-548(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bdc:	653c                	ld	a5,72(a0)
    80002bde:	02f4f863          	bgeu	s1,a5,80002c0e <fetchaddr+0x4a>
    80002be2:	00848713          	addi	a4,s1,8
    80002be6:	02e7e663          	bltu	a5,a4,80002c12 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bea:	46a1                	li	a3,8
    80002bec:	8626                	mv	a2,s1
    80002bee:	85ca                	mv	a1,s2
    80002bf0:	6928                	ld	a0,80(a0)
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	b0c080e7          	jalr	-1268(ra) # 800016fe <copyin>
    80002bfa:	00a03533          	snez	a0,a0
    80002bfe:	40a00533          	neg	a0,a0
}
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6902                	ld	s2,0(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
    return -1;
    80002c0e:	557d                	li	a0,-1
    80002c10:	bfcd                	j	80002c02 <fetchaddr+0x3e>
    80002c12:	557d                	li	a0,-1
    80002c14:	b7fd                	j	80002c02 <fetchaddr+0x3e>

0000000080002c16 <fetchstr>:
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	e44e                	sd	s3,8(sp)
    80002c22:	1800                	addi	s0,sp,48
    80002c24:	892a                	mv	s2,a0
    80002c26:	84ae                	mv	s1,a1
    80002c28:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	d86080e7          	jalr	-634(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c32:	86ce                	mv	a3,s3
    80002c34:	864a                	mv	a2,s2
    80002c36:	85a6                	mv	a1,s1
    80002c38:	6928                	ld	a0,80(a0)
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	b50080e7          	jalr	-1200(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c42:	00054763          	bltz	a0,80002c50 <fetchstr+0x3a>
  return strlen(buf);
    80002c46:	8526                	mv	a0,s1
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	21c080e7          	jalr	540(ra) # 80000e64 <strlen>
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	69a2                	ld	s3,8(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret

0000000080002c5e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	e426                	sd	s1,8(sp)
    80002c66:	1000                	addi	s0,sp,32
    80002c68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	ef2080e7          	jalr	-270(ra) # 80002b5c <argraw>
    80002c72:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c74:	4501                	li	a0,0
    80002c76:	60e2                	ld	ra,24(sp)
    80002c78:	6442                	ld	s0,16(sp)
    80002c7a:	64a2                	ld	s1,8(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	1000                	addi	s0,sp,32
    80002c8a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	ed0080e7          	jalr	-304(ra) # 80002b5c <argraw>
    80002c94:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c96:	4501                	li	a0,0
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	64a2                	ld	s1,8(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret

0000000080002ca2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ca2:	1101                	addi	sp,sp,-32
    80002ca4:	ec06                	sd	ra,24(sp)
    80002ca6:	e822                	sd	s0,16(sp)
    80002ca8:	e426                	sd	s1,8(sp)
    80002caa:	e04a                	sd	s2,0(sp)
    80002cac:	1000                	addi	s0,sp,32
    80002cae:	84ae                	mv	s1,a1
    80002cb0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	eaa080e7          	jalr	-342(ra) # 80002b5c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cba:	864a                	mv	a2,s2
    80002cbc:	85a6                	mv	a1,s1
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	f58080e7          	jalr	-168(ra) # 80002c16 <fetchstr>
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	64a2                	ld	s1,8(sp)
    80002ccc:	6902                	ld	s2,0(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret

0000000080002cd2 <syscall>:
};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002cd2:	711d                	addi	sp,sp,-96
    80002cd4:	ec86                	sd	ra,88(sp)
    80002cd6:	e8a2                	sd	s0,80(sp)
    80002cd8:	e4a6                	sd	s1,72(sp)
    80002cda:	e0ca                	sd	s2,64(sp)
    80002cdc:	fc4e                	sd	s3,56(sp)
    80002cde:	f852                	sd	s4,48(sp)
    80002ce0:	f456                	sd	s5,40(sp)
    80002ce2:	f05a                	sd	s6,32(sp)
    80002ce4:	ec5e                	sd	s7,24(sp)
    80002ce6:	e862                	sd	s8,16(sp)
    80002ce8:	e466                	sd	s9,8(sp)
    80002cea:	e06a                	sd	s10,0(sp)
    80002cec:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	cc2080e7          	jalr	-830(ra) # 800019b0 <myproc>
    80002cf6:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002cf8:	6d24                	ld	s1,88(a0)
    80002cfa:	74dc                	ld	a5,168(s1)
    80002cfc:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d00:	37fd                	addiw	a5,a5,-1
    80002d02:	4759                	li	a4,22
    80002d04:	06f76f63          	bltu	a4,a5,80002d82 <syscall+0xb0>
    80002d08:	003b1713          	slli	a4,s6,0x3
    80002d0c:	00006797          	auipc	a5,0x6
    80002d10:	81478793          	addi	a5,a5,-2028 # 80008520 <syscalls>
    80002d14:	97ba                	add	a5,a5,a4
    80002d16:	0007bd03          	ld	s10,0(a5)
    80002d1a:	060d0463          	beqz	s10,80002d82 <syscall+0xb0>
    80002d1e:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002d20:	fffb0c1b          	addiw	s8,s6,-1
    80002d24:	004c1713          	slli	a4,s8,0x4
    80002d28:	00006797          	auipc	a5,0x6
    80002d2c:	c1078793          	addi	a5,a5,-1008 # 80008938 <syscall_arg_infos>
    80002d30:	97ba                	add	a5,a5,a4
    80002d32:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002d36:	00299793          	slli	a5,s3,0x2
    80002d3a:	07bd                	addi	a5,a5,15
    80002d3c:	9bc1                	andi	a5,a5,-16
    80002d3e:	40f10133          	sub	sp,sp,a5
    80002d42:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002d44:	0f305363          	blez	s3,80002e2a <syscall+0x158>
    80002d48:	8ade                	mv	s5,s7
    80002d4a:	895e                	mv	s2,s7
    80002d4c:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002d4e:	8526                	mv	a0,s1
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	e0c080e7          	jalr	-500(ra) # 80002b5c <argraw>
    80002d58:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002d5c:	2485                	addiw	s1,s1,1
    80002d5e:	0911                	addi	s2,s2,4
    80002d60:	fe9997e3          	bne	s3,s1,80002d4e <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002d64:	058a3483          	ld	s1,88(s4)
    80002d68:	9d02                	jalr	s10
    80002d6a:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002d6c:	4785                	li	a5,1
    80002d6e:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002d72:	168a2b03          	lw	s6,360(s4)
    80002d76:	0167f7b3          	and	a5,a5,s6
    80002d7a:	2781                	sext.w	a5,a5
    80002d7c:	e7a1                	bnez	a5,80002dc4 <syscall+0xf2>
    80002d7e:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d80:	a015                	j	80002da4 <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d82:	86da                	mv	a3,s6
    80002d84:	158a0613          	addi	a2,s4,344
    80002d88:	030a2583          	lw	a1,48(s4)
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	69c50513          	addi	a0,a0,1692 # 80008428 <states.1740+0x168>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7f4080e7          	jalr	2036(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d9c:	058a3783          	ld	a5,88(s4)
    80002da0:	577d                	li	a4,-1
    80002da2:	fbb8                	sd	a4,112(a5)
  }
}
    80002da4:	fa040113          	addi	sp,s0,-96
    80002da8:	60e6                	ld	ra,88(sp)
    80002daa:	6446                	ld	s0,80(sp)
    80002dac:	64a6                	ld	s1,72(sp)
    80002dae:	6906                	ld	s2,64(sp)
    80002db0:	79e2                	ld	s3,56(sp)
    80002db2:	7a42                	ld	s4,48(sp)
    80002db4:	7aa2                	ld	s5,40(sp)
    80002db6:	7b02                	ld	s6,32(sp)
    80002db8:	6be2                	ld	s7,24(sp)
    80002dba:	6c42                	ld	s8,16(sp)
    80002dbc:	6ca2                	ld	s9,8(sp)
    80002dbe:	6d02                	ld	s10,0(sp)
    80002dc0:	6125                	addi	sp,sp,96
    80002dc2:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002dc4:	0c12                	slli	s8,s8,0x4
    80002dc6:	00006797          	auipc	a5,0x6
    80002dca:	b7278793          	addi	a5,a5,-1166 # 80008938 <syscall_arg_infos>
    80002dce:	9c3e                	add	s8,s8,a5
    80002dd0:	008c3603          	ld	a2,8(s8)
    80002dd4:	030a2583          	lw	a1,48(s4)
    80002dd8:	00005517          	auipc	a0,0x5
    80002ddc:	67050513          	addi	a0,a0,1648 # 80008448 <states.1740+0x188>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	7a8080e7          	jalr	1960(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002de8:	fff9879b          	addiw	a5,s3,-1
    80002dec:	1782                	slli	a5,a5,0x20
    80002dee:	9381                	srli	a5,a5,0x20
    80002df0:	0785                	addi	a5,a5,1
    80002df2:	078a                	slli	a5,a5,0x2
    80002df4:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80002df6:	00005497          	auipc	s1,0x5
    80002dfa:	61a48493          	addi	s1,s1,1562 # 80008410 <states.1740+0x150>
    80002dfe:	000aa583          	lw	a1,0(s5)
    80002e02:	8526                	mv	a0,s1
    80002e04:	ffffd097          	auipc	ra,0xffffd
    80002e08:	784080e7          	jalr	1924(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002e0c:	0a91                	addi	s5,s5,4
    80002e0e:	ff7a98e3          	bne	s5,s7,80002dfe <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    80002e12:	058a3783          	ld	a5,88(s4)
    80002e16:	7bac                	ld	a1,112(a5)
    80002e18:	00005517          	auipc	a0,0x5
    80002e1c:	60050513          	addi	a0,a0,1536 # 80008418 <states.1740+0x158>
    80002e20:	ffffd097          	auipc	ra,0xffffd
    80002e24:	768080e7          	jalr	1896(ra) # 80000588 <printf>
    80002e28:	bf99                	j	80002d7e <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002e2a:	9d02                	jalr	s10
    80002e2c:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002e2e:	4785                	li	a5,1
    80002e30:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002e34:	168a2703          	lw	a4,360(s4)
    80002e38:	8ff9                	and	a5,a5,a4
    80002e3a:	2781                	sext.w	a5,a5
    80002e3c:	d3a9                	beqz	a5,80002d7e <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002e3e:	0c12                	slli	s8,s8,0x4
    80002e40:	00006797          	auipc	a5,0x6
    80002e44:	af878793          	addi	a5,a5,-1288 # 80008938 <syscall_arg_infos>
    80002e48:	97e2                	add	a5,a5,s8
    80002e4a:	6790                	ld	a2,8(a5)
    80002e4c:	030a2583          	lw	a1,48(s4)
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	5f850513          	addi	a0,a0,1528 # 80008448 <states.1740+0x188>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	730080e7          	jalr	1840(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002e60:	bf4d                	j	80002e12 <syscall+0x140>

0000000080002e62 <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e6a:	fec40593          	addi	a1,s0,-20
    80002e6e:	4501                	li	a0,0
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	dee080e7          	jalr	-530(ra) # 80002c5e <argint>
    return -1;
    80002e78:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e7a:	00054963          	bltz	a0,80002e8c <sys_exit+0x2a>
  exit(n);
    80002e7e:	fec42503          	lw	a0,-20(s0)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	60c080e7          	jalr	1548(ra) # 8000248e <exit>
  return 0;  // not reached
    80002e8a:	4781                	li	a5,0
}
    80002e8c:	853e                	mv	a0,a5
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e96:	1141                	addi	sp,sp,-16
    80002e98:	e406                	sd	ra,8(sp)
    80002e9a:	e022                	sd	s0,0(sp)
    80002e9c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	b12080e7          	jalr	-1262(ra) # 800019b0 <myproc>
}
    80002ea6:	5908                	lw	a0,48(a0)
    80002ea8:	60a2                	ld	ra,8(sp)
    80002eaa:	6402                	ld	s0,0(sp)
    80002eac:	0141                	addi	sp,sp,16
    80002eae:	8082                	ret

0000000080002eb0 <sys_fork>:

uint64
sys_fork(void)
{
    80002eb0:	1141                	addi	sp,sp,-16
    80002eb2:	e406                	sd	ra,8(sp)
    80002eb4:	e022                	sd	s0,0(sp)
    80002eb6:	0800                	addi	s0,sp,16
  return fork();
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	eda080e7          	jalr	-294(ra) # 80001d92 <fork>
}
    80002ec0:	60a2                	ld	ra,8(sp)
    80002ec2:	6402                	ld	s0,0(sp)
    80002ec4:	0141                	addi	sp,sp,16
    80002ec6:	8082                	ret

0000000080002ec8 <sys_wait>:

uint64
sys_wait(void)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ed0:	fe840593          	addi	a1,s0,-24
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	daa080e7          	jalr	-598(ra) # 80002c80 <argaddr>
    80002ede:	87aa                	mv	a5,a0
    return -1;
    80002ee0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ee2:	0007c863          	bltz	a5,80002ef2 <sys_wait+0x2a>
  return wait(p);
    80002ee6:	fe843503          	ld	a0,-24(s0)
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	260080e7          	jalr	608(ra) # 8000214a <wait>
}
    80002ef2:	60e2                	ld	ra,24(sp)
    80002ef4:	6442                	ld	s0,16(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_waitx>:

uint64
sys_waitx(void)
{
    80002efa:	7139                	addi	sp,sp,-64
    80002efc:	fc06                	sd	ra,56(sp)
    80002efe:	f822                	sd	s0,48(sp)
    80002f00:	f426                	sd	s1,40(sp)
    80002f02:	f04a                	sd	s2,32(sp)
    80002f04:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002f06:	fd840593          	addi	a1,s0,-40
    80002f0a:	4501                	li	a0,0
    80002f0c:	00000097          	auipc	ra,0x0
    80002f10:	d74080e7          	jalr	-652(ra) # 80002c80 <argaddr>
    return -1;
    80002f14:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002f16:	08054063          	bltz	a0,80002f96 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f1a:	fd040593          	addi	a1,s0,-48
    80002f1e:	4505                	li	a0,1
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	d60080e7          	jalr	-672(ra) # 80002c80 <argaddr>
    return -1;
    80002f28:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f2a:	06054663          	bltz	a0,80002f96 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80002f2e:	fc840593          	addi	a1,s0,-56
    80002f32:	4509                	li	a0,2
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	d4c080e7          	jalr	-692(ra) # 80002c80 <argaddr>
    return -1;
    80002f3c:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002f3e:	04054c63          	bltz	a0,80002f96 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80002f42:	fc040613          	addi	a2,s0,-64
    80002f46:	fc440593          	addi	a1,s0,-60
    80002f4a:	fd843503          	ld	a0,-40(s0)
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	324080e7          	jalr	804(ra) # 80002272 <waitx>
    80002f56:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	a58080e7          	jalr	-1448(ra) # 800019b0 <myproc>
    80002f60:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002f62:	4691                	li	a3,4
    80002f64:	fc440613          	addi	a2,s0,-60
    80002f68:	fd043583          	ld	a1,-48(s0)
    80002f6c:	6928                	ld	a0,80(a0)
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	704080e7          	jalr	1796(ra) # 80001672 <copyout>
    return -1;
    80002f76:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002f78:	00054f63          	bltz	a0,80002f96 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002f7c:	4691                	li	a3,4
    80002f7e:	fc040613          	addi	a2,s0,-64
    80002f82:	fc843583          	ld	a1,-56(s0)
    80002f86:	68a8                	ld	a0,80(s1)
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	6ea080e7          	jalr	1770(ra) # 80001672 <copyout>
    80002f90:	00054a63          	bltz	a0,80002fa4 <sys_waitx+0xaa>
    return -1;
  return ret;
    80002f94:	87ca                	mv	a5,s2
}
    80002f96:	853e                	mv	a0,a5
    80002f98:	70e2                	ld	ra,56(sp)
    80002f9a:	7442                	ld	s0,48(sp)
    80002f9c:	74a2                	ld	s1,40(sp)
    80002f9e:	7902                	ld	s2,32(sp)
    80002fa0:	6121                	addi	sp,sp,64
    80002fa2:	8082                	ret
    return -1;
    80002fa4:	57fd                	li	a5,-1
    80002fa6:	bfc5                	j	80002f96 <sys_waitx+0x9c>

0000000080002fa8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fa8:	7179                	addi	sp,sp,-48
    80002faa:	f406                	sd	ra,40(sp)
    80002fac:	f022                	sd	s0,32(sp)
    80002fae:	ec26                	sd	s1,24(sp)
    80002fb0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fb2:	fdc40593          	addi	a1,s0,-36
    80002fb6:	4501                	li	a0,0
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	ca6080e7          	jalr	-858(ra) # 80002c5e <argint>
    80002fc0:	87aa                	mv	a5,a0
    return -1;
    80002fc2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002fc4:	0207c063          	bltz	a5,80002fe4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	9e8080e7          	jalr	-1560(ra) # 800019b0 <myproc>
    80002fd0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fd2:	fdc42503          	lw	a0,-36(s0)
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	d48080e7          	jalr	-696(ra) # 80001d1e <growproc>
    80002fde:	00054863          	bltz	a0,80002fee <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fe2:	8526                	mv	a0,s1
}
    80002fe4:	70a2                	ld	ra,40(sp)
    80002fe6:	7402                	ld	s0,32(sp)
    80002fe8:	64e2                	ld	s1,24(sp)
    80002fea:	6145                	addi	sp,sp,48
    80002fec:	8082                	ret
    return -1;
    80002fee:	557d                	li	a0,-1
    80002ff0:	bfd5                	j	80002fe4 <sys_sbrk+0x3c>

0000000080002ff2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ff2:	7139                	addi	sp,sp,-64
    80002ff4:	fc06                	sd	ra,56(sp)
    80002ff6:	f822                	sd	s0,48(sp)
    80002ff8:	f426                	sd	s1,40(sp)
    80002ffa:	f04a                	sd	s2,32(sp)
    80002ffc:	ec4e                	sd	s3,24(sp)
    80002ffe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003000:	fcc40593          	addi	a1,s0,-52
    80003004:	4501                	li	a0,0
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	c58080e7          	jalr	-936(ra) # 80002c5e <argint>
    return -1;
    8000300e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003010:	06054563          	bltz	a0,8000307a <sys_sleep+0x88>
  acquire(&tickslock);
    80003014:	00014517          	auipc	a0,0x14
    80003018:	4bc50513          	addi	a0,a0,1212 # 800174d0 <tickslock>
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	bc8080e7          	jalr	-1080(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003024:	00006917          	auipc	s2,0x6
    80003028:	00c92903          	lw	s2,12(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000302c:	fcc42783          	lw	a5,-52(s0)
    80003030:	cf85                	beqz	a5,80003068 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003032:	00014997          	auipc	s3,0x14
    80003036:	49e98993          	addi	s3,s3,1182 # 800174d0 <tickslock>
    8000303a:	00006497          	auipc	s1,0x6
    8000303e:	ff648493          	addi	s1,s1,-10 # 80009030 <ticks>
    if(myproc()->killed){
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	96e080e7          	jalr	-1682(ra) # 800019b0 <myproc>
    8000304a:	551c                	lw	a5,40(a0)
    8000304c:	ef9d                	bnez	a5,8000308a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000304e:	85ce                	mv	a1,s3
    80003050:	8526                	mv	a0,s1
    80003052:	fffff097          	auipc	ra,0xfffff
    80003056:	094080e7          	jalr	148(ra) # 800020e6 <sleep>
  while(ticks - ticks0 < n){
    8000305a:	409c                	lw	a5,0(s1)
    8000305c:	412787bb          	subw	a5,a5,s2
    80003060:	fcc42703          	lw	a4,-52(s0)
    80003064:	fce7efe3          	bltu	a5,a4,80003042 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003068:	00014517          	auipc	a0,0x14
    8000306c:	46850513          	addi	a0,a0,1128 # 800174d0 <tickslock>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	c28080e7          	jalr	-984(ra) # 80000c98 <release>
  return 0;
    80003078:	4781                	li	a5,0
}
    8000307a:	853e                	mv	a0,a5
    8000307c:	70e2                	ld	ra,56(sp)
    8000307e:	7442                	ld	s0,48(sp)
    80003080:	74a2                	ld	s1,40(sp)
    80003082:	7902                	ld	s2,32(sp)
    80003084:	69e2                	ld	s3,24(sp)
    80003086:	6121                	addi	sp,sp,64
    80003088:	8082                	ret
      release(&tickslock);
    8000308a:	00014517          	auipc	a0,0x14
    8000308e:	44650513          	addi	a0,a0,1094 # 800174d0 <tickslock>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>
      return -1;
    8000309a:	57fd                	li	a5,-1
    8000309c:	bff9                	j	8000307a <sys_sleep+0x88>

000000008000309e <sys_kill>:

uint64
sys_kill(void)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030a6:	fec40593          	addi	a1,s0,-20
    800030aa:	4501                	li	a0,0
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	bb2080e7          	jalr	-1102(ra) # 80002c5e <argint>
    800030b4:	87aa                	mv	a5,a0
    return -1;
    800030b6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030b8:	0007c863          	bltz	a5,800030c8 <sys_kill+0x2a>
  return kill(pid);
    800030bc:	fec42503          	lw	a0,-20(s0)
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	4b0080e7          	jalr	1200(ra) # 80002570 <kill>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret

00000000800030d0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	e426                	sd	s1,8(sp)
    800030d8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030da:	00014517          	auipc	a0,0x14
    800030de:	3f650513          	addi	a0,a0,1014 # 800174d0 <tickslock>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030ea:	00006497          	auipc	s1,0x6
    800030ee:	f464a483          	lw	s1,-186(s1) # 80009030 <ticks>
  release(&tickslock);
    800030f2:	00014517          	auipc	a0,0x14
    800030f6:	3de50513          	addi	a0,a0,990 # 800174d0 <tickslock>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	b9e080e7          	jalr	-1122(ra) # 80000c98 <release>
  return xticks;
}
    80003102:	02049513          	slli	a0,s1,0x20
    80003106:	9101                	srli	a0,a0,0x20
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    8000311a:	fec40593          	addi	a1,s0,-20
    8000311e:	4501                	li	a0,0
    80003120:	00000097          	auipc	ra,0x0
    80003124:	b3e080e7          	jalr	-1218(ra) # 80002c5e <argint>
  trace(n);
    80003128:	fec42503          	lw	a0,-20(s0)
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	610080e7          	jalr	1552(ra) # 8000273c <trace>
  return 0; // if the syscall is successful, return 0
}
    80003134:	4501                	li	a0,0
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret

000000008000313e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000313e:	7179                	addi	sp,sp,-48
    80003140:	f406                	sd	ra,40(sp)
    80003142:	f022                	sd	s0,32(sp)
    80003144:	ec26                	sd	s1,24(sp)
    80003146:	e84a                	sd	s2,16(sp)
    80003148:	e44e                	sd	s3,8(sp)
    8000314a:	e052                	sd	s4,0(sp)
    8000314c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000314e:	00005597          	auipc	a1,0x5
    80003152:	49258593          	addi	a1,a1,1170 # 800085e0 <syscalls+0xc0>
    80003156:	00014517          	auipc	a0,0x14
    8000315a:	39250513          	addi	a0,a0,914 # 800174e8 <bcache>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	9f6080e7          	jalr	-1546(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003166:	0001c797          	auipc	a5,0x1c
    8000316a:	38278793          	addi	a5,a5,898 # 8001f4e8 <bcache+0x8000>
    8000316e:	0001c717          	auipc	a4,0x1c
    80003172:	5e270713          	addi	a4,a4,1506 # 8001f750 <bcache+0x8268>
    80003176:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000317a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000317e:	00014497          	auipc	s1,0x14
    80003182:	38248493          	addi	s1,s1,898 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80003186:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003188:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000318a:	00005a17          	auipc	s4,0x5
    8000318e:	45ea0a13          	addi	s4,s4,1118 # 800085e8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003192:	2b893783          	ld	a5,696(s2)
    80003196:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003198:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000319c:	85d2                	mv	a1,s4
    8000319e:	01048513          	addi	a0,s1,16
    800031a2:	00001097          	auipc	ra,0x1
    800031a6:	4bc080e7          	jalr	1212(ra) # 8000465e <initsleeplock>
    bcache.head.next->prev = b;
    800031aa:	2b893783          	ld	a5,696(s2)
    800031ae:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031b0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031b4:	45848493          	addi	s1,s1,1112
    800031b8:	fd349de3          	bne	s1,s3,80003192 <binit+0x54>
  }
}
    800031bc:	70a2                	ld	ra,40(sp)
    800031be:	7402                	ld	s0,32(sp)
    800031c0:	64e2                	ld	s1,24(sp)
    800031c2:	6942                	ld	s2,16(sp)
    800031c4:	69a2                	ld	s3,8(sp)
    800031c6:	6a02                	ld	s4,0(sp)
    800031c8:	6145                	addi	sp,sp,48
    800031ca:	8082                	ret

00000000800031cc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031cc:	7179                	addi	sp,sp,-48
    800031ce:	f406                	sd	ra,40(sp)
    800031d0:	f022                	sd	s0,32(sp)
    800031d2:	ec26                	sd	s1,24(sp)
    800031d4:	e84a                	sd	s2,16(sp)
    800031d6:	e44e                	sd	s3,8(sp)
    800031d8:	1800                	addi	s0,sp,48
    800031da:	89aa                	mv	s3,a0
    800031dc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	30a50513          	addi	a0,a0,778 # 800174e8 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	9fe080e7          	jalr	-1538(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031ee:	0001c497          	auipc	s1,0x1c
    800031f2:	5b24b483          	ld	s1,1458(s1) # 8001f7a0 <bcache+0x82b8>
    800031f6:	0001c797          	auipc	a5,0x1c
    800031fa:	55a78793          	addi	a5,a5,1370 # 8001f750 <bcache+0x8268>
    800031fe:	02f48f63          	beq	s1,a5,8000323c <bread+0x70>
    80003202:	873e                	mv	a4,a5
    80003204:	a021                	j	8000320c <bread+0x40>
    80003206:	68a4                	ld	s1,80(s1)
    80003208:	02e48a63          	beq	s1,a4,8000323c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000320c:	449c                	lw	a5,8(s1)
    8000320e:	ff379ce3          	bne	a5,s3,80003206 <bread+0x3a>
    80003212:	44dc                	lw	a5,12(s1)
    80003214:	ff2799e3          	bne	a5,s2,80003206 <bread+0x3a>
      b->refcnt++;
    80003218:	40bc                	lw	a5,64(s1)
    8000321a:	2785                	addiw	a5,a5,1
    8000321c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000321e:	00014517          	auipc	a0,0x14
    80003222:	2ca50513          	addi	a0,a0,714 # 800174e8 <bcache>
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	a72080e7          	jalr	-1422(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000322e:	01048513          	addi	a0,s1,16
    80003232:	00001097          	auipc	ra,0x1
    80003236:	466080e7          	jalr	1126(ra) # 80004698 <acquiresleep>
      return b;
    8000323a:	a8b9                	j	80003298 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000323c:	0001c497          	auipc	s1,0x1c
    80003240:	55c4b483          	ld	s1,1372(s1) # 8001f798 <bcache+0x82b0>
    80003244:	0001c797          	auipc	a5,0x1c
    80003248:	50c78793          	addi	a5,a5,1292 # 8001f750 <bcache+0x8268>
    8000324c:	00f48863          	beq	s1,a5,8000325c <bread+0x90>
    80003250:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003252:	40bc                	lw	a5,64(s1)
    80003254:	cf81                	beqz	a5,8000326c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003256:	64a4                	ld	s1,72(s1)
    80003258:	fee49de3          	bne	s1,a4,80003252 <bread+0x86>
  panic("bget: no buffers");
    8000325c:	00005517          	auipc	a0,0x5
    80003260:	39450513          	addi	a0,a0,916 # 800085f0 <syscalls+0xd0>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	2da080e7          	jalr	730(ra) # 8000053e <panic>
      b->dev = dev;
    8000326c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003270:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003274:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003278:	4785                	li	a5,1
    8000327a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	26c50513          	addi	a0,a0,620 # 800174e8 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000328c:	01048513          	addi	a0,s1,16
    80003290:	00001097          	auipc	ra,0x1
    80003294:	408080e7          	jalr	1032(ra) # 80004698 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003298:	409c                	lw	a5,0(s1)
    8000329a:	cb89                	beqz	a5,800032ac <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000329c:	8526                	mv	a0,s1
    8000329e:	70a2                	ld	ra,40(sp)
    800032a0:	7402                	ld	s0,32(sp)
    800032a2:	64e2                	ld	s1,24(sp)
    800032a4:	6942                	ld	s2,16(sp)
    800032a6:	69a2                	ld	s3,8(sp)
    800032a8:	6145                	addi	sp,sp,48
    800032aa:	8082                	ret
    virtio_disk_rw(b, 0);
    800032ac:	4581                	li	a1,0
    800032ae:	8526                	mv	a0,s1
    800032b0:	00003097          	auipc	ra,0x3
    800032b4:	f06080e7          	jalr	-250(ra) # 800061b6 <virtio_disk_rw>
    b->valid = 1;
    800032b8:	4785                	li	a5,1
    800032ba:	c09c                	sw	a5,0(s1)
  return b;
    800032bc:	b7c5                	j	8000329c <bread+0xd0>

00000000800032be <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032be:	1101                	addi	sp,sp,-32
    800032c0:	ec06                	sd	ra,24(sp)
    800032c2:	e822                	sd	s0,16(sp)
    800032c4:	e426                	sd	s1,8(sp)
    800032c6:	1000                	addi	s0,sp,32
    800032c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ca:	0541                	addi	a0,a0,16
    800032cc:	00001097          	auipc	ra,0x1
    800032d0:	466080e7          	jalr	1126(ra) # 80004732 <holdingsleep>
    800032d4:	cd01                	beqz	a0,800032ec <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032d6:	4585                	li	a1,1
    800032d8:	8526                	mv	a0,s1
    800032da:	00003097          	auipc	ra,0x3
    800032de:	edc080e7          	jalr	-292(ra) # 800061b6 <virtio_disk_rw>
}
    800032e2:	60e2                	ld	ra,24(sp)
    800032e4:	6442                	ld	s0,16(sp)
    800032e6:	64a2                	ld	s1,8(sp)
    800032e8:	6105                	addi	sp,sp,32
    800032ea:	8082                	ret
    panic("bwrite");
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	31c50513          	addi	a0,a0,796 # 80008608 <syscalls+0xe8>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>

00000000800032fc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032fc:	1101                	addi	sp,sp,-32
    800032fe:	ec06                	sd	ra,24(sp)
    80003300:	e822                	sd	s0,16(sp)
    80003302:	e426                	sd	s1,8(sp)
    80003304:	e04a                	sd	s2,0(sp)
    80003306:	1000                	addi	s0,sp,32
    80003308:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000330a:	01050913          	addi	s2,a0,16
    8000330e:	854a                	mv	a0,s2
    80003310:	00001097          	auipc	ra,0x1
    80003314:	422080e7          	jalr	1058(ra) # 80004732 <holdingsleep>
    80003318:	c92d                	beqz	a0,8000338a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000331a:	854a                	mv	a0,s2
    8000331c:	00001097          	auipc	ra,0x1
    80003320:	3d2080e7          	jalr	978(ra) # 800046ee <releasesleep>

  acquire(&bcache.lock);
    80003324:	00014517          	auipc	a0,0x14
    80003328:	1c450513          	addi	a0,a0,452 # 800174e8 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	8b8080e7          	jalr	-1864(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003334:	40bc                	lw	a5,64(s1)
    80003336:	37fd                	addiw	a5,a5,-1
    80003338:	0007871b          	sext.w	a4,a5
    8000333c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000333e:	eb05                	bnez	a4,8000336e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003340:	68bc                	ld	a5,80(s1)
    80003342:	64b8                	ld	a4,72(s1)
    80003344:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003346:	64bc                	ld	a5,72(s1)
    80003348:	68b8                	ld	a4,80(s1)
    8000334a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000334c:	0001c797          	auipc	a5,0x1c
    80003350:	19c78793          	addi	a5,a5,412 # 8001f4e8 <bcache+0x8000>
    80003354:	2b87b703          	ld	a4,696(a5)
    80003358:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000335a:	0001c717          	auipc	a4,0x1c
    8000335e:	3f670713          	addi	a4,a4,1014 # 8001f750 <bcache+0x8268>
    80003362:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003364:	2b87b703          	ld	a4,696(a5)
    80003368:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000336a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000336e:	00014517          	auipc	a0,0x14
    80003372:	17a50513          	addi	a0,a0,378 # 800174e8 <bcache>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	922080e7          	jalr	-1758(ra) # 80000c98 <release>
}
    8000337e:	60e2                	ld	ra,24(sp)
    80003380:	6442                	ld	s0,16(sp)
    80003382:	64a2                	ld	s1,8(sp)
    80003384:	6902                	ld	s2,0(sp)
    80003386:	6105                	addi	sp,sp,32
    80003388:	8082                	ret
    panic("brelse");
    8000338a:	00005517          	auipc	a0,0x5
    8000338e:	28650513          	addi	a0,a0,646 # 80008610 <syscalls+0xf0>
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	1ac080e7          	jalr	428(ra) # 8000053e <panic>

000000008000339a <bpin>:

void
bpin(struct buf *b) {
    8000339a:	1101                	addi	sp,sp,-32
    8000339c:	ec06                	sd	ra,24(sp)
    8000339e:	e822                	sd	s0,16(sp)
    800033a0:	e426                	sd	s1,8(sp)
    800033a2:	1000                	addi	s0,sp,32
    800033a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033a6:	00014517          	auipc	a0,0x14
    800033aa:	14250513          	addi	a0,a0,322 # 800174e8 <bcache>
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	836080e7          	jalr	-1994(ra) # 80000be4 <acquire>
  b->refcnt++;
    800033b6:	40bc                	lw	a5,64(s1)
    800033b8:	2785                	addiw	a5,a5,1
    800033ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033bc:	00014517          	auipc	a0,0x14
    800033c0:	12c50513          	addi	a0,a0,300 # 800174e8 <bcache>
    800033c4:	ffffe097          	auipc	ra,0xffffe
    800033c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
}
    800033cc:	60e2                	ld	ra,24(sp)
    800033ce:	6442                	ld	s0,16(sp)
    800033d0:	64a2                	ld	s1,8(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <bunpin>:

void
bunpin(struct buf *b) {
    800033d6:	1101                	addi	sp,sp,-32
    800033d8:	ec06                	sd	ra,24(sp)
    800033da:	e822                	sd	s0,16(sp)
    800033dc:	e426                	sd	s1,8(sp)
    800033de:	1000                	addi	s0,sp,32
    800033e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033e2:	00014517          	auipc	a0,0x14
    800033e6:	10650513          	addi	a0,a0,262 # 800174e8 <bcache>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	7fa080e7          	jalr	2042(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033f2:	40bc                	lw	a5,64(s1)
    800033f4:	37fd                	addiw	a5,a5,-1
    800033f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033f8:	00014517          	auipc	a0,0x14
    800033fc:	0f050513          	addi	a0,a0,240 # 800174e8 <bcache>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	898080e7          	jalr	-1896(ra) # 80000c98 <release>
}
    80003408:	60e2                	ld	ra,24(sp)
    8000340a:	6442                	ld	s0,16(sp)
    8000340c:	64a2                	ld	s1,8(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret

0000000080003412 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003412:	1101                	addi	sp,sp,-32
    80003414:	ec06                	sd	ra,24(sp)
    80003416:	e822                	sd	s0,16(sp)
    80003418:	e426                	sd	s1,8(sp)
    8000341a:	e04a                	sd	s2,0(sp)
    8000341c:	1000                	addi	s0,sp,32
    8000341e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003420:	00d5d59b          	srliw	a1,a1,0xd
    80003424:	0001c797          	auipc	a5,0x1c
    80003428:	7a07a783          	lw	a5,1952(a5) # 8001fbc4 <sb+0x1c>
    8000342c:	9dbd                	addw	a1,a1,a5
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	d9e080e7          	jalr	-610(ra) # 800031cc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003436:	0074f713          	andi	a4,s1,7
    8000343a:	4785                	li	a5,1
    8000343c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003440:	14ce                	slli	s1,s1,0x33
    80003442:	90d9                	srli	s1,s1,0x36
    80003444:	00950733          	add	a4,a0,s1
    80003448:	05874703          	lbu	a4,88(a4)
    8000344c:	00e7f6b3          	and	a3,a5,a4
    80003450:	c69d                	beqz	a3,8000347e <bfree+0x6c>
    80003452:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003454:	94aa                	add	s1,s1,a0
    80003456:	fff7c793          	not	a5,a5
    8000345a:	8ff9                	and	a5,a5,a4
    8000345c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003460:	00001097          	auipc	ra,0x1
    80003464:	118080e7          	jalr	280(ra) # 80004578 <log_write>
  brelse(bp);
    80003468:	854a                	mv	a0,s2
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	e92080e7          	jalr	-366(ra) # 800032fc <brelse>
}
    80003472:	60e2                	ld	ra,24(sp)
    80003474:	6442                	ld	s0,16(sp)
    80003476:	64a2                	ld	s1,8(sp)
    80003478:	6902                	ld	s2,0(sp)
    8000347a:	6105                	addi	sp,sp,32
    8000347c:	8082                	ret
    panic("freeing free block");
    8000347e:	00005517          	auipc	a0,0x5
    80003482:	19a50513          	addi	a0,a0,410 # 80008618 <syscalls+0xf8>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	0b8080e7          	jalr	184(ra) # 8000053e <panic>

000000008000348e <balloc>:
{
    8000348e:	711d                	addi	sp,sp,-96
    80003490:	ec86                	sd	ra,88(sp)
    80003492:	e8a2                	sd	s0,80(sp)
    80003494:	e4a6                	sd	s1,72(sp)
    80003496:	e0ca                	sd	s2,64(sp)
    80003498:	fc4e                	sd	s3,56(sp)
    8000349a:	f852                	sd	s4,48(sp)
    8000349c:	f456                	sd	s5,40(sp)
    8000349e:	f05a                	sd	s6,32(sp)
    800034a0:	ec5e                	sd	s7,24(sp)
    800034a2:	e862                	sd	s8,16(sp)
    800034a4:	e466                	sd	s9,8(sp)
    800034a6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034a8:	0001c797          	auipc	a5,0x1c
    800034ac:	7047a783          	lw	a5,1796(a5) # 8001fbac <sb+0x4>
    800034b0:	cbd1                	beqz	a5,80003544 <balloc+0xb6>
    800034b2:	8baa                	mv	s7,a0
    800034b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034b6:	0001cb17          	auipc	s6,0x1c
    800034ba:	6f2b0b13          	addi	s6,s6,1778 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034c4:	6c89                	lui	s9,0x2
    800034c6:	a831                	j	800034e2 <balloc+0x54>
    brelse(bp);
    800034c8:	854a                	mv	a0,s2
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	e32080e7          	jalr	-462(ra) # 800032fc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034d2:	015c87bb          	addw	a5,s9,s5
    800034d6:	00078a9b          	sext.w	s5,a5
    800034da:	004b2703          	lw	a4,4(s6)
    800034de:	06eaf363          	bgeu	s5,a4,80003544 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034e2:	41fad79b          	sraiw	a5,s5,0x1f
    800034e6:	0137d79b          	srliw	a5,a5,0x13
    800034ea:	015787bb          	addw	a5,a5,s5
    800034ee:	40d7d79b          	sraiw	a5,a5,0xd
    800034f2:	01cb2583          	lw	a1,28(s6)
    800034f6:	9dbd                	addw	a1,a1,a5
    800034f8:	855e                	mv	a0,s7
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	cd2080e7          	jalr	-814(ra) # 800031cc <bread>
    80003502:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003504:	004b2503          	lw	a0,4(s6)
    80003508:	000a849b          	sext.w	s1,s5
    8000350c:	8662                	mv	a2,s8
    8000350e:	faa4fde3          	bgeu	s1,a0,800034c8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003512:	41f6579b          	sraiw	a5,a2,0x1f
    80003516:	01d7d69b          	srliw	a3,a5,0x1d
    8000351a:	00c6873b          	addw	a4,a3,a2
    8000351e:	00777793          	andi	a5,a4,7
    80003522:	9f95                	subw	a5,a5,a3
    80003524:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003528:	4037571b          	sraiw	a4,a4,0x3
    8000352c:	00e906b3          	add	a3,s2,a4
    80003530:	0586c683          	lbu	a3,88(a3)
    80003534:	00d7f5b3          	and	a1,a5,a3
    80003538:	cd91                	beqz	a1,80003554 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000353a:	2605                	addiw	a2,a2,1
    8000353c:	2485                	addiw	s1,s1,1
    8000353e:	fd4618e3          	bne	a2,s4,8000350e <balloc+0x80>
    80003542:	b759                	j	800034c8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	0ec50513          	addi	a0,a0,236 # 80008630 <syscalls+0x110>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	ff2080e7          	jalr	-14(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003554:	974a                	add	a4,a4,s2
    80003556:	8fd5                	or	a5,a5,a3
    80003558:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000355c:	854a                	mv	a0,s2
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	01a080e7          	jalr	26(ra) # 80004578 <log_write>
        brelse(bp);
    80003566:	854a                	mv	a0,s2
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	d94080e7          	jalr	-620(ra) # 800032fc <brelse>
  bp = bread(dev, bno);
    80003570:	85a6                	mv	a1,s1
    80003572:	855e                	mv	a0,s7
    80003574:	00000097          	auipc	ra,0x0
    80003578:	c58080e7          	jalr	-936(ra) # 800031cc <bread>
    8000357c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000357e:	40000613          	li	a2,1024
    80003582:	4581                	li	a1,0
    80003584:	05850513          	addi	a0,a0,88
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	758080e7          	jalr	1880(ra) # 80000ce0 <memset>
  log_write(bp);
    80003590:	854a                	mv	a0,s2
    80003592:	00001097          	auipc	ra,0x1
    80003596:	fe6080e7          	jalr	-26(ra) # 80004578 <log_write>
  brelse(bp);
    8000359a:	854a                	mv	a0,s2
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	d60080e7          	jalr	-672(ra) # 800032fc <brelse>
}
    800035a4:	8526                	mv	a0,s1
    800035a6:	60e6                	ld	ra,88(sp)
    800035a8:	6446                	ld	s0,80(sp)
    800035aa:	64a6                	ld	s1,72(sp)
    800035ac:	6906                	ld	s2,64(sp)
    800035ae:	79e2                	ld	s3,56(sp)
    800035b0:	7a42                	ld	s4,48(sp)
    800035b2:	7aa2                	ld	s5,40(sp)
    800035b4:	7b02                	ld	s6,32(sp)
    800035b6:	6be2                	ld	s7,24(sp)
    800035b8:	6c42                	ld	s8,16(sp)
    800035ba:	6ca2                	ld	s9,8(sp)
    800035bc:	6125                	addi	sp,sp,96
    800035be:	8082                	ret

00000000800035c0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035c0:	7179                	addi	sp,sp,-48
    800035c2:	f406                	sd	ra,40(sp)
    800035c4:	f022                	sd	s0,32(sp)
    800035c6:	ec26                	sd	s1,24(sp)
    800035c8:	e84a                	sd	s2,16(sp)
    800035ca:	e44e                	sd	s3,8(sp)
    800035cc:	e052                	sd	s4,0(sp)
    800035ce:	1800                	addi	s0,sp,48
    800035d0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035d2:	47ad                	li	a5,11
    800035d4:	04b7fe63          	bgeu	a5,a1,80003630 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035d8:	ff45849b          	addiw	s1,a1,-12
    800035dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035e0:	0ff00793          	li	a5,255
    800035e4:	0ae7e363          	bltu	a5,a4,8000368a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035e8:	08052583          	lw	a1,128(a0)
    800035ec:	c5ad                	beqz	a1,80003656 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035ee:	00092503          	lw	a0,0(s2)
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	bda080e7          	jalr	-1062(ra) # 800031cc <bread>
    800035fa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035fc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003600:	02049593          	slli	a1,s1,0x20
    80003604:	9181                	srli	a1,a1,0x20
    80003606:	058a                	slli	a1,a1,0x2
    80003608:	00b784b3          	add	s1,a5,a1
    8000360c:	0004a983          	lw	s3,0(s1)
    80003610:	04098d63          	beqz	s3,8000366a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003614:	8552                	mv	a0,s4
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	ce6080e7          	jalr	-794(ra) # 800032fc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000361e:	854e                	mv	a0,s3
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	69a2                	ld	s3,8(sp)
    8000362a:	6a02                	ld	s4,0(sp)
    8000362c:	6145                	addi	sp,sp,48
    8000362e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003630:	02059493          	slli	s1,a1,0x20
    80003634:	9081                	srli	s1,s1,0x20
    80003636:	048a                	slli	s1,s1,0x2
    80003638:	94aa                	add	s1,s1,a0
    8000363a:	0504a983          	lw	s3,80(s1)
    8000363e:	fe0990e3          	bnez	s3,8000361e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003642:	4108                	lw	a0,0(a0)
    80003644:	00000097          	auipc	ra,0x0
    80003648:	e4a080e7          	jalr	-438(ra) # 8000348e <balloc>
    8000364c:	0005099b          	sext.w	s3,a0
    80003650:	0534a823          	sw	s3,80(s1)
    80003654:	b7e9                	j	8000361e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003656:	4108                	lw	a0,0(a0)
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	e36080e7          	jalr	-458(ra) # 8000348e <balloc>
    80003660:	0005059b          	sext.w	a1,a0
    80003664:	08b92023          	sw	a1,128(s2)
    80003668:	b759                	j	800035ee <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000366a:	00092503          	lw	a0,0(s2)
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	e20080e7          	jalr	-480(ra) # 8000348e <balloc>
    80003676:	0005099b          	sext.w	s3,a0
    8000367a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000367e:	8552                	mv	a0,s4
    80003680:	00001097          	auipc	ra,0x1
    80003684:	ef8080e7          	jalr	-264(ra) # 80004578 <log_write>
    80003688:	b771                	j	80003614 <bmap+0x54>
  panic("bmap: out of range");
    8000368a:	00005517          	auipc	a0,0x5
    8000368e:	fbe50513          	addi	a0,a0,-66 # 80008648 <syscalls+0x128>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>

000000008000369a <iget>:
{
    8000369a:	7179                	addi	sp,sp,-48
    8000369c:	f406                	sd	ra,40(sp)
    8000369e:	f022                	sd	s0,32(sp)
    800036a0:	ec26                	sd	s1,24(sp)
    800036a2:	e84a                	sd	s2,16(sp)
    800036a4:	e44e                	sd	s3,8(sp)
    800036a6:	e052                	sd	s4,0(sp)
    800036a8:	1800                	addi	s0,sp,48
    800036aa:	89aa                	mv	s3,a0
    800036ac:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036ae:	0001c517          	auipc	a0,0x1c
    800036b2:	51a50513          	addi	a0,a0,1306 # 8001fbc8 <itable>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	52e080e7          	jalr	1326(ra) # 80000be4 <acquire>
  empty = 0;
    800036be:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036c0:	0001c497          	auipc	s1,0x1c
    800036c4:	52048493          	addi	s1,s1,1312 # 8001fbe0 <itable+0x18>
    800036c8:	0001e697          	auipc	a3,0x1e
    800036cc:	fa868693          	addi	a3,a3,-88 # 80021670 <log>
    800036d0:	a039                	j	800036de <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036d2:	02090b63          	beqz	s2,80003708 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036d6:	08848493          	addi	s1,s1,136
    800036da:	02d48a63          	beq	s1,a3,8000370e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036de:	449c                	lw	a5,8(s1)
    800036e0:	fef059e3          	blez	a5,800036d2 <iget+0x38>
    800036e4:	4098                	lw	a4,0(s1)
    800036e6:	ff3716e3          	bne	a4,s3,800036d2 <iget+0x38>
    800036ea:	40d8                	lw	a4,4(s1)
    800036ec:	ff4713e3          	bne	a4,s4,800036d2 <iget+0x38>
      ip->ref++;
    800036f0:	2785                	addiw	a5,a5,1
    800036f2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036f4:	0001c517          	auipc	a0,0x1c
    800036f8:	4d450513          	addi	a0,a0,1236 # 8001fbc8 <itable>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	59c080e7          	jalr	1436(ra) # 80000c98 <release>
      return ip;
    80003704:	8926                	mv	s2,s1
    80003706:	a03d                	j	80003734 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003708:	f7f9                	bnez	a5,800036d6 <iget+0x3c>
    8000370a:	8926                	mv	s2,s1
    8000370c:	b7e9                	j	800036d6 <iget+0x3c>
  if(empty == 0)
    8000370e:	02090c63          	beqz	s2,80003746 <iget+0xac>
  ip->dev = dev;
    80003712:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003716:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000371a:	4785                	li	a5,1
    8000371c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003720:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003724:	0001c517          	auipc	a0,0x1c
    80003728:	4a450513          	addi	a0,a0,1188 # 8001fbc8 <itable>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	56c080e7          	jalr	1388(ra) # 80000c98 <release>
}
    80003734:	854a                	mv	a0,s2
    80003736:	70a2                	ld	ra,40(sp)
    80003738:	7402                	ld	s0,32(sp)
    8000373a:	64e2                	ld	s1,24(sp)
    8000373c:	6942                	ld	s2,16(sp)
    8000373e:	69a2                	ld	s3,8(sp)
    80003740:	6a02                	ld	s4,0(sp)
    80003742:	6145                	addi	sp,sp,48
    80003744:	8082                	ret
    panic("iget: no inodes");
    80003746:	00005517          	auipc	a0,0x5
    8000374a:	f1a50513          	addi	a0,a0,-230 # 80008660 <syscalls+0x140>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>

0000000080003756 <fsinit>:
fsinit(int dev) {
    80003756:	7179                	addi	sp,sp,-48
    80003758:	f406                	sd	ra,40(sp)
    8000375a:	f022                	sd	s0,32(sp)
    8000375c:	ec26                	sd	s1,24(sp)
    8000375e:	e84a                	sd	s2,16(sp)
    80003760:	e44e                	sd	s3,8(sp)
    80003762:	1800                	addi	s0,sp,48
    80003764:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003766:	4585                	li	a1,1
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	a64080e7          	jalr	-1436(ra) # 800031cc <bread>
    80003770:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003772:	0001c997          	auipc	s3,0x1c
    80003776:	43698993          	addi	s3,s3,1078 # 8001fba8 <sb>
    8000377a:	02000613          	li	a2,32
    8000377e:	05850593          	addi	a1,a0,88
    80003782:	854e                	mv	a0,s3
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	5bc080e7          	jalr	1468(ra) # 80000d40 <memmove>
  brelse(bp);
    8000378c:	8526                	mv	a0,s1
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	b6e080e7          	jalr	-1170(ra) # 800032fc <brelse>
  if(sb.magic != FSMAGIC)
    80003796:	0009a703          	lw	a4,0(s3)
    8000379a:	102037b7          	lui	a5,0x10203
    8000379e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037a2:	02f71263          	bne	a4,a5,800037c6 <fsinit+0x70>
  initlog(dev, &sb);
    800037a6:	0001c597          	auipc	a1,0x1c
    800037aa:	40258593          	addi	a1,a1,1026 # 8001fba8 <sb>
    800037ae:	854a                	mv	a0,s2
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	b4c080e7          	jalr	-1204(ra) # 800042fc <initlog>
}
    800037b8:	70a2                	ld	ra,40(sp)
    800037ba:	7402                	ld	s0,32(sp)
    800037bc:	64e2                	ld	s1,24(sp)
    800037be:	6942                	ld	s2,16(sp)
    800037c0:	69a2                	ld	s3,8(sp)
    800037c2:	6145                	addi	sp,sp,48
    800037c4:	8082                	ret
    panic("invalid file system");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	eaa50513          	addi	a0,a0,-342 # 80008670 <syscalls+0x150>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>

00000000800037d6 <iinit>:
{
    800037d6:	7179                	addi	sp,sp,-48
    800037d8:	f406                	sd	ra,40(sp)
    800037da:	f022                	sd	s0,32(sp)
    800037dc:	ec26                	sd	s1,24(sp)
    800037de:	e84a                	sd	s2,16(sp)
    800037e0:	e44e                	sd	s3,8(sp)
    800037e2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037e4:	00005597          	auipc	a1,0x5
    800037e8:	ea458593          	addi	a1,a1,-348 # 80008688 <syscalls+0x168>
    800037ec:	0001c517          	auipc	a0,0x1c
    800037f0:	3dc50513          	addi	a0,a0,988 # 8001fbc8 <itable>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	360080e7          	jalr	864(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037fc:	0001c497          	auipc	s1,0x1c
    80003800:	3f448493          	addi	s1,s1,1012 # 8001fbf0 <itable+0x28>
    80003804:	0001e997          	auipc	s3,0x1e
    80003808:	e7c98993          	addi	s3,s3,-388 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000380c:	00005917          	auipc	s2,0x5
    80003810:	e8490913          	addi	s2,s2,-380 # 80008690 <syscalls+0x170>
    80003814:	85ca                	mv	a1,s2
    80003816:	8526                	mv	a0,s1
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	e46080e7          	jalr	-442(ra) # 8000465e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003820:	08848493          	addi	s1,s1,136
    80003824:	ff3498e3          	bne	s1,s3,80003814 <iinit+0x3e>
}
    80003828:	70a2                	ld	ra,40(sp)
    8000382a:	7402                	ld	s0,32(sp)
    8000382c:	64e2                	ld	s1,24(sp)
    8000382e:	6942                	ld	s2,16(sp)
    80003830:	69a2                	ld	s3,8(sp)
    80003832:	6145                	addi	sp,sp,48
    80003834:	8082                	ret

0000000080003836 <ialloc>:
{
    80003836:	715d                	addi	sp,sp,-80
    80003838:	e486                	sd	ra,72(sp)
    8000383a:	e0a2                	sd	s0,64(sp)
    8000383c:	fc26                	sd	s1,56(sp)
    8000383e:	f84a                	sd	s2,48(sp)
    80003840:	f44e                	sd	s3,40(sp)
    80003842:	f052                	sd	s4,32(sp)
    80003844:	ec56                	sd	s5,24(sp)
    80003846:	e85a                	sd	s6,16(sp)
    80003848:	e45e                	sd	s7,8(sp)
    8000384a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000384c:	0001c717          	auipc	a4,0x1c
    80003850:	36872703          	lw	a4,872(a4) # 8001fbb4 <sb+0xc>
    80003854:	4785                	li	a5,1
    80003856:	04e7fa63          	bgeu	a5,a4,800038aa <ialloc+0x74>
    8000385a:	8aaa                	mv	s5,a0
    8000385c:	8bae                	mv	s7,a1
    8000385e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003860:	0001ca17          	auipc	s4,0x1c
    80003864:	348a0a13          	addi	s4,s4,840 # 8001fba8 <sb>
    80003868:	00048b1b          	sext.w	s6,s1
    8000386c:	0044d593          	srli	a1,s1,0x4
    80003870:	018a2783          	lw	a5,24(s4)
    80003874:	9dbd                	addw	a1,a1,a5
    80003876:	8556                	mv	a0,s5
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	954080e7          	jalr	-1708(ra) # 800031cc <bread>
    80003880:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003882:	05850993          	addi	s3,a0,88
    80003886:	00f4f793          	andi	a5,s1,15
    8000388a:	079a                	slli	a5,a5,0x6
    8000388c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000388e:	00099783          	lh	a5,0(s3)
    80003892:	c785                	beqz	a5,800038ba <ialloc+0x84>
    brelse(bp);
    80003894:	00000097          	auipc	ra,0x0
    80003898:	a68080e7          	jalr	-1432(ra) # 800032fc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000389c:	0485                	addi	s1,s1,1
    8000389e:	00ca2703          	lw	a4,12(s4)
    800038a2:	0004879b          	sext.w	a5,s1
    800038a6:	fce7e1e3          	bltu	a5,a4,80003868 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038aa:	00005517          	auipc	a0,0x5
    800038ae:	dee50513          	addi	a0,a0,-530 # 80008698 <syscalls+0x178>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	c8c080e7          	jalr	-884(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800038ba:	04000613          	li	a2,64
    800038be:	4581                	li	a1,0
    800038c0:	854e                	mv	a0,s3
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	41e080e7          	jalr	1054(ra) # 80000ce0 <memset>
      dip->type = type;
    800038ca:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038ce:	854a                	mv	a0,s2
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	ca8080e7          	jalr	-856(ra) # 80004578 <log_write>
      brelse(bp);
    800038d8:	854a                	mv	a0,s2
    800038da:	00000097          	auipc	ra,0x0
    800038de:	a22080e7          	jalr	-1502(ra) # 800032fc <brelse>
      return iget(dev, inum);
    800038e2:	85da                	mv	a1,s6
    800038e4:	8556                	mv	a0,s5
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	db4080e7          	jalr	-588(ra) # 8000369a <iget>
}
    800038ee:	60a6                	ld	ra,72(sp)
    800038f0:	6406                	ld	s0,64(sp)
    800038f2:	74e2                	ld	s1,56(sp)
    800038f4:	7942                	ld	s2,48(sp)
    800038f6:	79a2                	ld	s3,40(sp)
    800038f8:	7a02                	ld	s4,32(sp)
    800038fa:	6ae2                	ld	s5,24(sp)
    800038fc:	6b42                	ld	s6,16(sp)
    800038fe:	6ba2                	ld	s7,8(sp)
    80003900:	6161                	addi	sp,sp,80
    80003902:	8082                	ret

0000000080003904 <iupdate>:
{
    80003904:	1101                	addi	sp,sp,-32
    80003906:	ec06                	sd	ra,24(sp)
    80003908:	e822                	sd	s0,16(sp)
    8000390a:	e426                	sd	s1,8(sp)
    8000390c:	e04a                	sd	s2,0(sp)
    8000390e:	1000                	addi	s0,sp,32
    80003910:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003912:	415c                	lw	a5,4(a0)
    80003914:	0047d79b          	srliw	a5,a5,0x4
    80003918:	0001c597          	auipc	a1,0x1c
    8000391c:	2a85a583          	lw	a1,680(a1) # 8001fbc0 <sb+0x18>
    80003920:	9dbd                	addw	a1,a1,a5
    80003922:	4108                	lw	a0,0(a0)
    80003924:	00000097          	auipc	ra,0x0
    80003928:	8a8080e7          	jalr	-1880(ra) # 800031cc <bread>
    8000392c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000392e:	05850793          	addi	a5,a0,88
    80003932:	40c8                	lw	a0,4(s1)
    80003934:	893d                	andi	a0,a0,15
    80003936:	051a                	slli	a0,a0,0x6
    80003938:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000393a:	04449703          	lh	a4,68(s1)
    8000393e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003942:	04649703          	lh	a4,70(s1)
    80003946:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000394a:	04849703          	lh	a4,72(s1)
    8000394e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003952:	04a49703          	lh	a4,74(s1)
    80003956:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000395a:	44f8                	lw	a4,76(s1)
    8000395c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000395e:	03400613          	li	a2,52
    80003962:	05048593          	addi	a1,s1,80
    80003966:	0531                	addi	a0,a0,12
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	3d8080e7          	jalr	984(ra) # 80000d40 <memmove>
  log_write(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00001097          	auipc	ra,0x1
    80003976:	c06080e7          	jalr	-1018(ra) # 80004578 <log_write>
  brelse(bp);
    8000397a:	854a                	mv	a0,s2
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	980080e7          	jalr	-1664(ra) # 800032fc <brelse>
}
    80003984:	60e2                	ld	ra,24(sp)
    80003986:	6442                	ld	s0,16(sp)
    80003988:	64a2                	ld	s1,8(sp)
    8000398a:	6902                	ld	s2,0(sp)
    8000398c:	6105                	addi	sp,sp,32
    8000398e:	8082                	ret

0000000080003990 <idup>:
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	1000                	addi	s0,sp,32
    8000399a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000399c:	0001c517          	auipc	a0,0x1c
    800039a0:	22c50513          	addi	a0,a0,556 # 8001fbc8 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	240080e7          	jalr	576(ra) # 80000be4 <acquire>
  ip->ref++;
    800039ac:	449c                	lw	a5,8(s1)
    800039ae:	2785                	addiw	a5,a5,1
    800039b0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b2:	0001c517          	auipc	a0,0x1c
    800039b6:	21650513          	addi	a0,a0,534 # 8001fbc8 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	2de080e7          	jalr	734(ra) # 80000c98 <release>
}
    800039c2:	8526                	mv	a0,s1
    800039c4:	60e2                	ld	ra,24(sp)
    800039c6:	6442                	ld	s0,16(sp)
    800039c8:	64a2                	ld	s1,8(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret

00000000800039ce <ilock>:
{
    800039ce:	1101                	addi	sp,sp,-32
    800039d0:	ec06                	sd	ra,24(sp)
    800039d2:	e822                	sd	s0,16(sp)
    800039d4:	e426                	sd	s1,8(sp)
    800039d6:	e04a                	sd	s2,0(sp)
    800039d8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039da:	c115                	beqz	a0,800039fe <ilock+0x30>
    800039dc:	84aa                	mv	s1,a0
    800039de:	451c                	lw	a5,8(a0)
    800039e0:	00f05f63          	blez	a5,800039fe <ilock+0x30>
  acquiresleep(&ip->lock);
    800039e4:	0541                	addi	a0,a0,16
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	cb2080e7          	jalr	-846(ra) # 80004698 <acquiresleep>
  if(ip->valid == 0){
    800039ee:	40bc                	lw	a5,64(s1)
    800039f0:	cf99                	beqz	a5,80003a0e <ilock+0x40>
}
    800039f2:	60e2                	ld	ra,24(sp)
    800039f4:	6442                	ld	s0,16(sp)
    800039f6:	64a2                	ld	s1,8(sp)
    800039f8:	6902                	ld	s2,0(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret
    panic("ilock");
    800039fe:	00005517          	auipc	a0,0x5
    80003a02:	cb250513          	addi	a0,a0,-846 # 800086b0 <syscalls+0x190>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	b38080e7          	jalr	-1224(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a0e:	40dc                	lw	a5,4(s1)
    80003a10:	0047d79b          	srliw	a5,a5,0x4
    80003a14:	0001c597          	auipc	a1,0x1c
    80003a18:	1ac5a583          	lw	a1,428(a1) # 8001fbc0 <sb+0x18>
    80003a1c:	9dbd                	addw	a1,a1,a5
    80003a1e:	4088                	lw	a0,0(s1)
    80003a20:	fffff097          	auipc	ra,0xfffff
    80003a24:	7ac080e7          	jalr	1964(ra) # 800031cc <bread>
    80003a28:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a2a:	05850593          	addi	a1,a0,88
    80003a2e:	40dc                	lw	a5,4(s1)
    80003a30:	8bbd                	andi	a5,a5,15
    80003a32:	079a                	slli	a5,a5,0x6
    80003a34:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a36:	00059783          	lh	a5,0(a1)
    80003a3a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a3e:	00259783          	lh	a5,2(a1)
    80003a42:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a46:	00459783          	lh	a5,4(a1)
    80003a4a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a4e:	00659783          	lh	a5,6(a1)
    80003a52:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a56:	459c                	lw	a5,8(a1)
    80003a58:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a5a:	03400613          	li	a2,52
    80003a5e:	05b1                	addi	a1,a1,12
    80003a60:	05048513          	addi	a0,s1,80
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	2dc080e7          	jalr	732(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	88e080e7          	jalr	-1906(ra) # 800032fc <brelse>
    ip->valid = 1;
    80003a76:	4785                	li	a5,1
    80003a78:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a7a:	04449783          	lh	a5,68(s1)
    80003a7e:	fbb5                	bnez	a5,800039f2 <ilock+0x24>
      panic("ilock: no type");
    80003a80:	00005517          	auipc	a0,0x5
    80003a84:	c3850513          	addi	a0,a0,-968 # 800086b8 <syscalls+0x198>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>

0000000080003a90 <iunlock>:
{
    80003a90:	1101                	addi	sp,sp,-32
    80003a92:	ec06                	sd	ra,24(sp)
    80003a94:	e822                	sd	s0,16(sp)
    80003a96:	e426                	sd	s1,8(sp)
    80003a98:	e04a                	sd	s2,0(sp)
    80003a9a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a9c:	c905                	beqz	a0,80003acc <iunlock+0x3c>
    80003a9e:	84aa                	mv	s1,a0
    80003aa0:	01050913          	addi	s2,a0,16
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	00001097          	auipc	ra,0x1
    80003aaa:	c8c080e7          	jalr	-884(ra) # 80004732 <holdingsleep>
    80003aae:	cd19                	beqz	a0,80003acc <iunlock+0x3c>
    80003ab0:	449c                	lw	a5,8(s1)
    80003ab2:	00f05d63          	blez	a5,80003acc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	00001097          	auipc	ra,0x1
    80003abc:	c36080e7          	jalr	-970(ra) # 800046ee <releasesleep>
}
    80003ac0:	60e2                	ld	ra,24(sp)
    80003ac2:	6442                	ld	s0,16(sp)
    80003ac4:	64a2                	ld	s1,8(sp)
    80003ac6:	6902                	ld	s2,0(sp)
    80003ac8:	6105                	addi	sp,sp,32
    80003aca:	8082                	ret
    panic("iunlock");
    80003acc:	00005517          	auipc	a0,0x5
    80003ad0:	bfc50513          	addi	a0,a0,-1028 # 800086c8 <syscalls+0x1a8>
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	a6a080e7          	jalr	-1430(ra) # 8000053e <panic>

0000000080003adc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003adc:	7179                	addi	sp,sp,-48
    80003ade:	f406                	sd	ra,40(sp)
    80003ae0:	f022                	sd	s0,32(sp)
    80003ae2:	ec26                	sd	s1,24(sp)
    80003ae4:	e84a                	sd	s2,16(sp)
    80003ae6:	e44e                	sd	s3,8(sp)
    80003ae8:	e052                	sd	s4,0(sp)
    80003aea:	1800                	addi	s0,sp,48
    80003aec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aee:	05050493          	addi	s1,a0,80
    80003af2:	08050913          	addi	s2,a0,128
    80003af6:	a021                	j	80003afe <itrunc+0x22>
    80003af8:	0491                	addi	s1,s1,4
    80003afa:	01248d63          	beq	s1,s2,80003b14 <itrunc+0x38>
    if(ip->addrs[i]){
    80003afe:	408c                	lw	a1,0(s1)
    80003b00:	dde5                	beqz	a1,80003af8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b02:	0009a503          	lw	a0,0(s3)
    80003b06:	00000097          	auipc	ra,0x0
    80003b0a:	90c080e7          	jalr	-1780(ra) # 80003412 <bfree>
      ip->addrs[i] = 0;
    80003b0e:	0004a023          	sw	zero,0(s1)
    80003b12:	b7dd                	j	80003af8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b14:	0809a583          	lw	a1,128(s3)
    80003b18:	e185                	bnez	a1,80003b38 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b1a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b1e:	854e                	mv	a0,s3
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	de4080e7          	jalr	-540(ra) # 80003904 <iupdate>
}
    80003b28:	70a2                	ld	ra,40(sp)
    80003b2a:	7402                	ld	s0,32(sp)
    80003b2c:	64e2                	ld	s1,24(sp)
    80003b2e:	6942                	ld	s2,16(sp)
    80003b30:	69a2                	ld	s3,8(sp)
    80003b32:	6a02                	ld	s4,0(sp)
    80003b34:	6145                	addi	sp,sp,48
    80003b36:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b38:	0009a503          	lw	a0,0(s3)
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	690080e7          	jalr	1680(ra) # 800031cc <bread>
    80003b44:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b46:	05850493          	addi	s1,a0,88
    80003b4a:	45850913          	addi	s2,a0,1112
    80003b4e:	a811                	j	80003b62 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b50:	0009a503          	lw	a0,0(s3)
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	8be080e7          	jalr	-1858(ra) # 80003412 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b5c:	0491                	addi	s1,s1,4
    80003b5e:	01248563          	beq	s1,s2,80003b68 <itrunc+0x8c>
      if(a[j])
    80003b62:	408c                	lw	a1,0(s1)
    80003b64:	dde5                	beqz	a1,80003b5c <itrunc+0x80>
    80003b66:	b7ed                	j	80003b50 <itrunc+0x74>
    brelse(bp);
    80003b68:	8552                	mv	a0,s4
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	792080e7          	jalr	1938(ra) # 800032fc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b72:	0809a583          	lw	a1,128(s3)
    80003b76:	0009a503          	lw	a0,0(s3)
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	898080e7          	jalr	-1896(ra) # 80003412 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b82:	0809a023          	sw	zero,128(s3)
    80003b86:	bf51                	j	80003b1a <itrunc+0x3e>

0000000080003b88 <iput>:
{
    80003b88:	1101                	addi	sp,sp,-32
    80003b8a:	ec06                	sd	ra,24(sp)
    80003b8c:	e822                	sd	s0,16(sp)
    80003b8e:	e426                	sd	s1,8(sp)
    80003b90:	e04a                	sd	s2,0(sp)
    80003b92:	1000                	addi	s0,sp,32
    80003b94:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b96:	0001c517          	auipc	a0,0x1c
    80003b9a:	03250513          	addi	a0,a0,50 # 8001fbc8 <itable>
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	046080e7          	jalr	70(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ba6:	4498                	lw	a4,8(s1)
    80003ba8:	4785                	li	a5,1
    80003baa:	02f70363          	beq	a4,a5,80003bd0 <iput+0x48>
  ip->ref--;
    80003bae:	449c                	lw	a5,8(s1)
    80003bb0:	37fd                	addiw	a5,a5,-1
    80003bb2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bb4:	0001c517          	auipc	a0,0x1c
    80003bb8:	01450513          	addi	a0,a0,20 # 8001fbc8 <itable>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	0dc080e7          	jalr	220(ra) # 80000c98 <release>
}
    80003bc4:	60e2                	ld	ra,24(sp)
    80003bc6:	6442                	ld	s0,16(sp)
    80003bc8:	64a2                	ld	s1,8(sp)
    80003bca:	6902                	ld	s2,0(sp)
    80003bcc:	6105                	addi	sp,sp,32
    80003bce:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd0:	40bc                	lw	a5,64(s1)
    80003bd2:	dff1                	beqz	a5,80003bae <iput+0x26>
    80003bd4:	04a49783          	lh	a5,74(s1)
    80003bd8:	fbf9                	bnez	a5,80003bae <iput+0x26>
    acquiresleep(&ip->lock);
    80003bda:	01048913          	addi	s2,s1,16
    80003bde:	854a                	mv	a0,s2
    80003be0:	00001097          	auipc	ra,0x1
    80003be4:	ab8080e7          	jalr	-1352(ra) # 80004698 <acquiresleep>
    release(&itable.lock);
    80003be8:	0001c517          	auipc	a0,0x1c
    80003bec:	fe050513          	addi	a0,a0,-32 # 8001fbc8 <itable>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	0a8080e7          	jalr	168(ra) # 80000c98 <release>
    itrunc(ip);
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	ee2080e7          	jalr	-286(ra) # 80003adc <itrunc>
    ip->type = 0;
    80003c02:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c06:	8526                	mv	a0,s1
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	cfc080e7          	jalr	-772(ra) # 80003904 <iupdate>
    ip->valid = 0;
    80003c10:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c14:	854a                	mv	a0,s2
    80003c16:	00001097          	auipc	ra,0x1
    80003c1a:	ad8080e7          	jalr	-1320(ra) # 800046ee <releasesleep>
    acquire(&itable.lock);
    80003c1e:	0001c517          	auipc	a0,0x1c
    80003c22:	faa50513          	addi	a0,a0,-86 # 8001fbc8 <itable>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	fbe080e7          	jalr	-66(ra) # 80000be4 <acquire>
    80003c2e:	b741                	j	80003bae <iput+0x26>

0000000080003c30 <iunlockput>:
{
    80003c30:	1101                	addi	sp,sp,-32
    80003c32:	ec06                	sd	ra,24(sp)
    80003c34:	e822                	sd	s0,16(sp)
    80003c36:	e426                	sd	s1,8(sp)
    80003c38:	1000                	addi	s0,sp,32
    80003c3a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	e54080e7          	jalr	-428(ra) # 80003a90 <iunlock>
  iput(ip);
    80003c44:	8526                	mv	a0,s1
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	f42080e7          	jalr	-190(ra) # 80003b88 <iput>
}
    80003c4e:	60e2                	ld	ra,24(sp)
    80003c50:	6442                	ld	s0,16(sp)
    80003c52:	64a2                	ld	s1,8(sp)
    80003c54:	6105                	addi	sp,sp,32
    80003c56:	8082                	ret

0000000080003c58 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c58:	1141                	addi	sp,sp,-16
    80003c5a:	e422                	sd	s0,8(sp)
    80003c5c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c5e:	411c                	lw	a5,0(a0)
    80003c60:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c62:	415c                	lw	a5,4(a0)
    80003c64:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c66:	04451783          	lh	a5,68(a0)
    80003c6a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c6e:	04a51783          	lh	a5,74(a0)
    80003c72:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c76:	04c56783          	lwu	a5,76(a0)
    80003c7a:	e99c                	sd	a5,16(a1)
}
    80003c7c:	6422                	ld	s0,8(sp)
    80003c7e:	0141                	addi	sp,sp,16
    80003c80:	8082                	ret

0000000080003c82 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c82:	457c                	lw	a5,76(a0)
    80003c84:	0ed7e963          	bltu	a5,a3,80003d76 <readi+0xf4>
{
    80003c88:	7159                	addi	sp,sp,-112
    80003c8a:	f486                	sd	ra,104(sp)
    80003c8c:	f0a2                	sd	s0,96(sp)
    80003c8e:	eca6                	sd	s1,88(sp)
    80003c90:	e8ca                	sd	s2,80(sp)
    80003c92:	e4ce                	sd	s3,72(sp)
    80003c94:	e0d2                	sd	s4,64(sp)
    80003c96:	fc56                	sd	s5,56(sp)
    80003c98:	f85a                	sd	s6,48(sp)
    80003c9a:	f45e                	sd	s7,40(sp)
    80003c9c:	f062                	sd	s8,32(sp)
    80003c9e:	ec66                	sd	s9,24(sp)
    80003ca0:	e86a                	sd	s10,16(sp)
    80003ca2:	e46e                	sd	s11,8(sp)
    80003ca4:	1880                	addi	s0,sp,112
    80003ca6:	8baa                	mv	s7,a0
    80003ca8:	8c2e                	mv	s8,a1
    80003caa:	8ab2                	mv	s5,a2
    80003cac:	84b6                	mv	s1,a3
    80003cae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cb0:	9f35                	addw	a4,a4,a3
    return 0;
    80003cb2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cb4:	0ad76063          	bltu	a4,a3,80003d54 <readi+0xd2>
  if(off + n > ip->size)
    80003cb8:	00e7f463          	bgeu	a5,a4,80003cc0 <readi+0x3e>
    n = ip->size - off;
    80003cbc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cc0:	0a0b0963          	beqz	s6,80003d72 <readi+0xf0>
    80003cc4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cca:	5cfd                	li	s9,-1
    80003ccc:	a82d                	j	80003d06 <readi+0x84>
    80003cce:	020a1d93          	slli	s11,s4,0x20
    80003cd2:	020ddd93          	srli	s11,s11,0x20
    80003cd6:	05890613          	addi	a2,s2,88
    80003cda:	86ee                	mv	a3,s11
    80003cdc:	963a                	add	a2,a2,a4
    80003cde:	85d6                	mv	a1,s5
    80003ce0:	8562                	mv	a0,s8
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	900080e7          	jalr	-1792(ra) # 800025e2 <either_copyout>
    80003cea:	05950d63          	beq	a0,s9,80003d44 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cee:	854a                	mv	a0,s2
    80003cf0:	fffff097          	auipc	ra,0xfffff
    80003cf4:	60c080e7          	jalr	1548(ra) # 800032fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf8:	013a09bb          	addw	s3,s4,s3
    80003cfc:	009a04bb          	addw	s1,s4,s1
    80003d00:	9aee                	add	s5,s5,s11
    80003d02:	0569f763          	bgeu	s3,s6,80003d50 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d06:	000ba903          	lw	s2,0(s7)
    80003d0a:	00a4d59b          	srliw	a1,s1,0xa
    80003d0e:	855e                	mv	a0,s7
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	8b0080e7          	jalr	-1872(ra) # 800035c0 <bmap>
    80003d18:	0005059b          	sext.w	a1,a0
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	4ae080e7          	jalr	1198(ra) # 800031cc <bread>
    80003d26:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d28:	3ff4f713          	andi	a4,s1,1023
    80003d2c:	40ed07bb          	subw	a5,s10,a4
    80003d30:	413b06bb          	subw	a3,s6,s3
    80003d34:	8a3e                	mv	s4,a5
    80003d36:	2781                	sext.w	a5,a5
    80003d38:	0006861b          	sext.w	a2,a3
    80003d3c:	f8f679e3          	bgeu	a2,a5,80003cce <readi+0x4c>
    80003d40:	8a36                	mv	s4,a3
    80003d42:	b771                	j	80003cce <readi+0x4c>
      brelse(bp);
    80003d44:	854a                	mv	a0,s2
    80003d46:	fffff097          	auipc	ra,0xfffff
    80003d4a:	5b6080e7          	jalr	1462(ra) # 800032fc <brelse>
      tot = -1;
    80003d4e:	59fd                	li	s3,-1
  }
  return tot;
    80003d50:	0009851b          	sext.w	a0,s3
}
    80003d54:	70a6                	ld	ra,104(sp)
    80003d56:	7406                	ld	s0,96(sp)
    80003d58:	64e6                	ld	s1,88(sp)
    80003d5a:	6946                	ld	s2,80(sp)
    80003d5c:	69a6                	ld	s3,72(sp)
    80003d5e:	6a06                	ld	s4,64(sp)
    80003d60:	7ae2                	ld	s5,56(sp)
    80003d62:	7b42                	ld	s6,48(sp)
    80003d64:	7ba2                	ld	s7,40(sp)
    80003d66:	7c02                	ld	s8,32(sp)
    80003d68:	6ce2                	ld	s9,24(sp)
    80003d6a:	6d42                	ld	s10,16(sp)
    80003d6c:	6da2                	ld	s11,8(sp)
    80003d6e:	6165                	addi	sp,sp,112
    80003d70:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d72:	89da                	mv	s3,s6
    80003d74:	bff1                	j	80003d50 <readi+0xce>
    return 0;
    80003d76:	4501                	li	a0,0
}
    80003d78:	8082                	ret

0000000080003d7a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d7a:	457c                	lw	a5,76(a0)
    80003d7c:	10d7e863          	bltu	a5,a3,80003e8c <writei+0x112>
{
    80003d80:	7159                	addi	sp,sp,-112
    80003d82:	f486                	sd	ra,104(sp)
    80003d84:	f0a2                	sd	s0,96(sp)
    80003d86:	eca6                	sd	s1,88(sp)
    80003d88:	e8ca                	sd	s2,80(sp)
    80003d8a:	e4ce                	sd	s3,72(sp)
    80003d8c:	e0d2                	sd	s4,64(sp)
    80003d8e:	fc56                	sd	s5,56(sp)
    80003d90:	f85a                	sd	s6,48(sp)
    80003d92:	f45e                	sd	s7,40(sp)
    80003d94:	f062                	sd	s8,32(sp)
    80003d96:	ec66                	sd	s9,24(sp)
    80003d98:	e86a                	sd	s10,16(sp)
    80003d9a:	e46e                	sd	s11,8(sp)
    80003d9c:	1880                	addi	s0,sp,112
    80003d9e:	8b2a                	mv	s6,a0
    80003da0:	8c2e                	mv	s8,a1
    80003da2:	8ab2                	mv	s5,a2
    80003da4:	8936                	mv	s2,a3
    80003da6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003da8:	00e687bb          	addw	a5,a3,a4
    80003dac:	0ed7e263          	bltu	a5,a3,80003e90 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003db0:	00043737          	lui	a4,0x43
    80003db4:	0ef76063          	bltu	a4,a5,80003e94 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db8:	0c0b8863          	beqz	s7,80003e88 <writei+0x10e>
    80003dbc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dbe:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dc2:	5cfd                	li	s9,-1
    80003dc4:	a091                	j	80003e08 <writei+0x8e>
    80003dc6:	02099d93          	slli	s11,s3,0x20
    80003dca:	020ddd93          	srli	s11,s11,0x20
    80003dce:	05848513          	addi	a0,s1,88
    80003dd2:	86ee                	mv	a3,s11
    80003dd4:	8656                	mv	a2,s5
    80003dd6:	85e2                	mv	a1,s8
    80003dd8:	953a                	add	a0,a0,a4
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	85e080e7          	jalr	-1954(ra) # 80002638 <either_copyin>
    80003de2:	07950263          	beq	a0,s9,80003e46 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003de6:	8526                	mv	a0,s1
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	790080e7          	jalr	1936(ra) # 80004578 <log_write>
    brelse(bp);
    80003df0:	8526                	mv	a0,s1
    80003df2:	fffff097          	auipc	ra,0xfffff
    80003df6:	50a080e7          	jalr	1290(ra) # 800032fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dfa:	01498a3b          	addw	s4,s3,s4
    80003dfe:	0129893b          	addw	s2,s3,s2
    80003e02:	9aee                	add	s5,s5,s11
    80003e04:	057a7663          	bgeu	s4,s7,80003e50 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e08:	000b2483          	lw	s1,0(s6)
    80003e0c:	00a9559b          	srliw	a1,s2,0xa
    80003e10:	855a                	mv	a0,s6
    80003e12:	fffff097          	auipc	ra,0xfffff
    80003e16:	7ae080e7          	jalr	1966(ra) # 800035c0 <bmap>
    80003e1a:	0005059b          	sext.w	a1,a0
    80003e1e:	8526                	mv	a0,s1
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	3ac080e7          	jalr	940(ra) # 800031cc <bread>
    80003e28:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e2a:	3ff97713          	andi	a4,s2,1023
    80003e2e:	40ed07bb          	subw	a5,s10,a4
    80003e32:	414b86bb          	subw	a3,s7,s4
    80003e36:	89be                	mv	s3,a5
    80003e38:	2781                	sext.w	a5,a5
    80003e3a:	0006861b          	sext.w	a2,a3
    80003e3e:	f8f674e3          	bgeu	a2,a5,80003dc6 <writei+0x4c>
    80003e42:	89b6                	mv	s3,a3
    80003e44:	b749                	j	80003dc6 <writei+0x4c>
      brelse(bp);
    80003e46:	8526                	mv	a0,s1
    80003e48:	fffff097          	auipc	ra,0xfffff
    80003e4c:	4b4080e7          	jalr	1204(ra) # 800032fc <brelse>
  }

  if(off > ip->size)
    80003e50:	04cb2783          	lw	a5,76(s6)
    80003e54:	0127f463          	bgeu	a5,s2,80003e5c <writei+0xe2>
    ip->size = off;
    80003e58:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e5c:	855a                	mv	a0,s6
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	aa6080e7          	jalr	-1370(ra) # 80003904 <iupdate>

  return tot;
    80003e66:	000a051b          	sext.w	a0,s4
}
    80003e6a:	70a6                	ld	ra,104(sp)
    80003e6c:	7406                	ld	s0,96(sp)
    80003e6e:	64e6                	ld	s1,88(sp)
    80003e70:	6946                	ld	s2,80(sp)
    80003e72:	69a6                	ld	s3,72(sp)
    80003e74:	6a06                	ld	s4,64(sp)
    80003e76:	7ae2                	ld	s5,56(sp)
    80003e78:	7b42                	ld	s6,48(sp)
    80003e7a:	7ba2                	ld	s7,40(sp)
    80003e7c:	7c02                	ld	s8,32(sp)
    80003e7e:	6ce2                	ld	s9,24(sp)
    80003e80:	6d42                	ld	s10,16(sp)
    80003e82:	6da2                	ld	s11,8(sp)
    80003e84:	6165                	addi	sp,sp,112
    80003e86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e88:	8a5e                	mv	s4,s7
    80003e8a:	bfc9                	j	80003e5c <writei+0xe2>
    return -1;
    80003e8c:	557d                	li	a0,-1
}
    80003e8e:	8082                	ret
    return -1;
    80003e90:	557d                	li	a0,-1
    80003e92:	bfe1                	j	80003e6a <writei+0xf0>
    return -1;
    80003e94:	557d                	li	a0,-1
    80003e96:	bfd1                	j	80003e6a <writei+0xf0>

0000000080003e98 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e98:	1141                	addi	sp,sp,-16
    80003e9a:	e406                	sd	ra,8(sp)
    80003e9c:	e022                	sd	s0,0(sp)
    80003e9e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ea0:	4639                	li	a2,14
    80003ea2:	ffffd097          	auipc	ra,0xffffd
    80003ea6:	f16080e7          	jalr	-234(ra) # 80000db8 <strncmp>
}
    80003eaa:	60a2                	ld	ra,8(sp)
    80003eac:	6402                	ld	s0,0(sp)
    80003eae:	0141                	addi	sp,sp,16
    80003eb0:	8082                	ret

0000000080003eb2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eb2:	7139                	addi	sp,sp,-64
    80003eb4:	fc06                	sd	ra,56(sp)
    80003eb6:	f822                	sd	s0,48(sp)
    80003eb8:	f426                	sd	s1,40(sp)
    80003eba:	f04a                	sd	s2,32(sp)
    80003ebc:	ec4e                	sd	s3,24(sp)
    80003ebe:	e852                	sd	s4,16(sp)
    80003ec0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ec2:	04451703          	lh	a4,68(a0)
    80003ec6:	4785                	li	a5,1
    80003ec8:	00f71a63          	bne	a4,a5,80003edc <dirlookup+0x2a>
    80003ecc:	892a                	mv	s2,a0
    80003ece:	89ae                	mv	s3,a1
    80003ed0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed2:	457c                	lw	a5,76(a0)
    80003ed4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ed6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed8:	e79d                	bnez	a5,80003f06 <dirlookup+0x54>
    80003eda:	a8a5                	j	80003f52 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003edc:	00004517          	auipc	a0,0x4
    80003ee0:	7f450513          	addi	a0,a0,2036 # 800086d0 <syscalls+0x1b0>
    80003ee4:	ffffc097          	auipc	ra,0xffffc
    80003ee8:	65a080e7          	jalr	1626(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003eec:	00004517          	auipc	a0,0x4
    80003ef0:	7fc50513          	addi	a0,a0,2044 # 800086e8 <syscalls+0x1c8>
    80003ef4:	ffffc097          	auipc	ra,0xffffc
    80003ef8:	64a080e7          	jalr	1610(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efc:	24c1                	addiw	s1,s1,16
    80003efe:	04c92783          	lw	a5,76(s2)
    80003f02:	04f4f763          	bgeu	s1,a5,80003f50 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f06:	4741                	li	a4,16
    80003f08:	86a6                	mv	a3,s1
    80003f0a:	fc040613          	addi	a2,s0,-64
    80003f0e:	4581                	li	a1,0
    80003f10:	854a                	mv	a0,s2
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	d70080e7          	jalr	-656(ra) # 80003c82 <readi>
    80003f1a:	47c1                	li	a5,16
    80003f1c:	fcf518e3          	bne	a0,a5,80003eec <dirlookup+0x3a>
    if(de.inum == 0)
    80003f20:	fc045783          	lhu	a5,-64(s0)
    80003f24:	dfe1                	beqz	a5,80003efc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f26:	fc240593          	addi	a1,s0,-62
    80003f2a:	854e                	mv	a0,s3
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	f6c080e7          	jalr	-148(ra) # 80003e98 <namecmp>
    80003f34:	f561                	bnez	a0,80003efc <dirlookup+0x4a>
      if(poff)
    80003f36:	000a0463          	beqz	s4,80003f3e <dirlookup+0x8c>
        *poff = off;
    80003f3a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f3e:	fc045583          	lhu	a1,-64(s0)
    80003f42:	00092503          	lw	a0,0(s2)
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	754080e7          	jalr	1876(ra) # 8000369a <iget>
    80003f4e:	a011                	j	80003f52 <dirlookup+0xa0>
  return 0;
    80003f50:	4501                	li	a0,0
}
    80003f52:	70e2                	ld	ra,56(sp)
    80003f54:	7442                	ld	s0,48(sp)
    80003f56:	74a2                	ld	s1,40(sp)
    80003f58:	7902                	ld	s2,32(sp)
    80003f5a:	69e2                	ld	s3,24(sp)
    80003f5c:	6a42                	ld	s4,16(sp)
    80003f5e:	6121                	addi	sp,sp,64
    80003f60:	8082                	ret

0000000080003f62 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f62:	711d                	addi	sp,sp,-96
    80003f64:	ec86                	sd	ra,88(sp)
    80003f66:	e8a2                	sd	s0,80(sp)
    80003f68:	e4a6                	sd	s1,72(sp)
    80003f6a:	e0ca                	sd	s2,64(sp)
    80003f6c:	fc4e                	sd	s3,56(sp)
    80003f6e:	f852                	sd	s4,48(sp)
    80003f70:	f456                	sd	s5,40(sp)
    80003f72:	f05a                	sd	s6,32(sp)
    80003f74:	ec5e                	sd	s7,24(sp)
    80003f76:	e862                	sd	s8,16(sp)
    80003f78:	e466                	sd	s9,8(sp)
    80003f7a:	1080                	addi	s0,sp,96
    80003f7c:	84aa                	mv	s1,a0
    80003f7e:	8b2e                	mv	s6,a1
    80003f80:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f82:	00054703          	lbu	a4,0(a0)
    80003f86:	02f00793          	li	a5,47
    80003f8a:	02f70363          	beq	a4,a5,80003fb0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f8e:	ffffe097          	auipc	ra,0xffffe
    80003f92:	a22080e7          	jalr	-1502(ra) # 800019b0 <myproc>
    80003f96:	15053503          	ld	a0,336(a0)
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	9f6080e7          	jalr	-1546(ra) # 80003990 <idup>
    80003fa2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fa4:	02f00913          	li	s2,47
  len = path - s;
    80003fa8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003faa:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fac:	4c05                	li	s8,1
    80003fae:	a865                	j	80004066 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fb0:	4585                	li	a1,1
    80003fb2:	4505                	li	a0,1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	6e6080e7          	jalr	1766(ra) # 8000369a <iget>
    80003fbc:	89aa                	mv	s3,a0
    80003fbe:	b7dd                	j	80003fa4 <namex+0x42>
      iunlockput(ip);
    80003fc0:	854e                	mv	a0,s3
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	c6e080e7          	jalr	-914(ra) # 80003c30 <iunlockput>
      return 0;
    80003fca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fcc:	854e                	mv	a0,s3
    80003fce:	60e6                	ld	ra,88(sp)
    80003fd0:	6446                	ld	s0,80(sp)
    80003fd2:	64a6                	ld	s1,72(sp)
    80003fd4:	6906                	ld	s2,64(sp)
    80003fd6:	79e2                	ld	s3,56(sp)
    80003fd8:	7a42                	ld	s4,48(sp)
    80003fda:	7aa2                	ld	s5,40(sp)
    80003fdc:	7b02                	ld	s6,32(sp)
    80003fde:	6be2                	ld	s7,24(sp)
    80003fe0:	6c42                	ld	s8,16(sp)
    80003fe2:	6ca2                	ld	s9,8(sp)
    80003fe4:	6125                	addi	sp,sp,96
    80003fe6:	8082                	ret
      iunlock(ip);
    80003fe8:	854e                	mv	a0,s3
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	aa6080e7          	jalr	-1370(ra) # 80003a90 <iunlock>
      return ip;
    80003ff2:	bfe9                	j	80003fcc <namex+0x6a>
      iunlockput(ip);
    80003ff4:	854e                	mv	a0,s3
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	c3a080e7          	jalr	-966(ra) # 80003c30 <iunlockput>
      return 0;
    80003ffe:	89d2                	mv	s3,s4
    80004000:	b7f1                	j	80003fcc <namex+0x6a>
  len = path - s;
    80004002:	40b48633          	sub	a2,s1,a1
    80004006:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000400a:	094cd463          	bge	s9,s4,80004092 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000400e:	4639                	li	a2,14
    80004010:	8556                	mv	a0,s5
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	d2e080e7          	jalr	-722(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	01279763          	bne	a5,s2,8000402c <namex+0xca>
    path++;
    80004022:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004024:	0004c783          	lbu	a5,0(s1)
    80004028:	ff278de3          	beq	a5,s2,80004022 <namex+0xc0>
    ilock(ip);
    8000402c:	854e                	mv	a0,s3
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	9a0080e7          	jalr	-1632(ra) # 800039ce <ilock>
    if(ip->type != T_DIR){
    80004036:	04499783          	lh	a5,68(s3)
    8000403a:	f98793e3          	bne	a5,s8,80003fc0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000403e:	000b0563          	beqz	s6,80004048 <namex+0xe6>
    80004042:	0004c783          	lbu	a5,0(s1)
    80004046:	d3cd                	beqz	a5,80003fe8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004048:	865e                	mv	a2,s7
    8000404a:	85d6                	mv	a1,s5
    8000404c:	854e                	mv	a0,s3
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	e64080e7          	jalr	-412(ra) # 80003eb2 <dirlookup>
    80004056:	8a2a                	mv	s4,a0
    80004058:	dd51                	beqz	a0,80003ff4 <namex+0x92>
    iunlockput(ip);
    8000405a:	854e                	mv	a0,s3
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	bd4080e7          	jalr	-1068(ra) # 80003c30 <iunlockput>
    ip = next;
    80004064:	89d2                	mv	s3,s4
  while(*path == '/')
    80004066:	0004c783          	lbu	a5,0(s1)
    8000406a:	05279763          	bne	a5,s2,800040b8 <namex+0x156>
    path++;
    8000406e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004070:	0004c783          	lbu	a5,0(s1)
    80004074:	ff278de3          	beq	a5,s2,8000406e <namex+0x10c>
  if(*path == 0)
    80004078:	c79d                	beqz	a5,800040a6 <namex+0x144>
    path++;
    8000407a:	85a6                	mv	a1,s1
  len = path - s;
    8000407c:	8a5e                	mv	s4,s7
    8000407e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004080:	01278963          	beq	a5,s2,80004092 <namex+0x130>
    80004084:	dfbd                	beqz	a5,80004002 <namex+0xa0>
    path++;
    80004086:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004088:	0004c783          	lbu	a5,0(s1)
    8000408c:	ff279ce3          	bne	a5,s2,80004084 <namex+0x122>
    80004090:	bf8d                	j	80004002 <namex+0xa0>
    memmove(name, s, len);
    80004092:	2601                	sext.w	a2,a2
    80004094:	8556                	mv	a0,s5
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	caa080e7          	jalr	-854(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000409e:	9a56                	add	s4,s4,s5
    800040a0:	000a0023          	sb	zero,0(s4)
    800040a4:	bf9d                	j	8000401a <namex+0xb8>
  if(nameiparent){
    800040a6:	f20b03e3          	beqz	s6,80003fcc <namex+0x6a>
    iput(ip);
    800040aa:	854e                	mv	a0,s3
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	adc080e7          	jalr	-1316(ra) # 80003b88 <iput>
    return 0;
    800040b4:	4981                	li	s3,0
    800040b6:	bf19                	j	80003fcc <namex+0x6a>
  if(*path == 0)
    800040b8:	d7fd                	beqz	a5,800040a6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040ba:	0004c783          	lbu	a5,0(s1)
    800040be:	85a6                	mv	a1,s1
    800040c0:	b7d1                	j	80004084 <namex+0x122>

00000000800040c2 <dirlink>:
{
    800040c2:	7139                	addi	sp,sp,-64
    800040c4:	fc06                	sd	ra,56(sp)
    800040c6:	f822                	sd	s0,48(sp)
    800040c8:	f426                	sd	s1,40(sp)
    800040ca:	f04a                	sd	s2,32(sp)
    800040cc:	ec4e                	sd	s3,24(sp)
    800040ce:	e852                	sd	s4,16(sp)
    800040d0:	0080                	addi	s0,sp,64
    800040d2:	892a                	mv	s2,a0
    800040d4:	8a2e                	mv	s4,a1
    800040d6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040d8:	4601                	li	a2,0
    800040da:	00000097          	auipc	ra,0x0
    800040de:	dd8080e7          	jalr	-552(ra) # 80003eb2 <dirlookup>
    800040e2:	e93d                	bnez	a0,80004158 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e4:	04c92483          	lw	s1,76(s2)
    800040e8:	c49d                	beqz	s1,80004116 <dirlink+0x54>
    800040ea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ec:	4741                	li	a4,16
    800040ee:	86a6                	mv	a3,s1
    800040f0:	fc040613          	addi	a2,s0,-64
    800040f4:	4581                	li	a1,0
    800040f6:	854a                	mv	a0,s2
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	b8a080e7          	jalr	-1142(ra) # 80003c82 <readi>
    80004100:	47c1                	li	a5,16
    80004102:	06f51163          	bne	a0,a5,80004164 <dirlink+0xa2>
    if(de.inum == 0)
    80004106:	fc045783          	lhu	a5,-64(s0)
    8000410a:	c791                	beqz	a5,80004116 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000410c:	24c1                	addiw	s1,s1,16
    8000410e:	04c92783          	lw	a5,76(s2)
    80004112:	fcf4ede3          	bltu	s1,a5,800040ec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004116:	4639                	li	a2,14
    80004118:	85d2                	mv	a1,s4
    8000411a:	fc240513          	addi	a0,s0,-62
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	cd6080e7          	jalr	-810(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004126:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412a:	4741                	li	a4,16
    8000412c:	86a6                	mv	a3,s1
    8000412e:	fc040613          	addi	a2,s0,-64
    80004132:	4581                	li	a1,0
    80004134:	854a                	mv	a0,s2
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	c44080e7          	jalr	-956(ra) # 80003d7a <writei>
    8000413e:	872a                	mv	a4,a0
    80004140:	47c1                	li	a5,16
  return 0;
    80004142:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004144:	02f71863          	bne	a4,a5,80004174 <dirlink+0xb2>
}
    80004148:	70e2                	ld	ra,56(sp)
    8000414a:	7442                	ld	s0,48(sp)
    8000414c:	74a2                	ld	s1,40(sp)
    8000414e:	7902                	ld	s2,32(sp)
    80004150:	69e2                	ld	s3,24(sp)
    80004152:	6a42                	ld	s4,16(sp)
    80004154:	6121                	addi	sp,sp,64
    80004156:	8082                	ret
    iput(ip);
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	a30080e7          	jalr	-1488(ra) # 80003b88 <iput>
    return -1;
    80004160:	557d                	li	a0,-1
    80004162:	b7dd                	j	80004148 <dirlink+0x86>
      panic("dirlink read");
    80004164:	00004517          	auipc	a0,0x4
    80004168:	59450513          	addi	a0,a0,1428 # 800086f8 <syscalls+0x1d8>
    8000416c:	ffffc097          	auipc	ra,0xffffc
    80004170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>
    panic("dirlink");
    80004174:	00004517          	auipc	a0,0x4
    80004178:	68c50513          	addi	a0,a0,1676 # 80008800 <syscalls+0x2e0>
    8000417c:	ffffc097          	auipc	ra,0xffffc
    80004180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>

0000000080004184 <namei>:

struct inode*
namei(char *path)
{
    80004184:	1101                	addi	sp,sp,-32
    80004186:	ec06                	sd	ra,24(sp)
    80004188:	e822                	sd	s0,16(sp)
    8000418a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000418c:	fe040613          	addi	a2,s0,-32
    80004190:	4581                	li	a1,0
    80004192:	00000097          	auipc	ra,0x0
    80004196:	dd0080e7          	jalr	-560(ra) # 80003f62 <namex>
}
    8000419a:	60e2                	ld	ra,24(sp)
    8000419c:	6442                	ld	s0,16(sp)
    8000419e:	6105                	addi	sp,sp,32
    800041a0:	8082                	ret

00000000800041a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041a2:	1141                	addi	sp,sp,-16
    800041a4:	e406                	sd	ra,8(sp)
    800041a6:	e022                	sd	s0,0(sp)
    800041a8:	0800                	addi	s0,sp,16
    800041aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041ac:	4585                	li	a1,1
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	db4080e7          	jalr	-588(ra) # 80003f62 <namex>
}
    800041b6:	60a2                	ld	ra,8(sp)
    800041b8:	6402                	ld	s0,0(sp)
    800041ba:	0141                	addi	sp,sp,16
    800041bc:	8082                	ret

00000000800041be <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041be:	1101                	addi	sp,sp,-32
    800041c0:	ec06                	sd	ra,24(sp)
    800041c2:	e822                	sd	s0,16(sp)
    800041c4:	e426                	sd	s1,8(sp)
    800041c6:	e04a                	sd	s2,0(sp)
    800041c8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041ca:	0001d917          	auipc	s2,0x1d
    800041ce:	4a690913          	addi	s2,s2,1190 # 80021670 <log>
    800041d2:	01892583          	lw	a1,24(s2)
    800041d6:	02892503          	lw	a0,40(s2)
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	ff2080e7          	jalr	-14(ra) # 800031cc <bread>
    800041e2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041e4:	02c92683          	lw	a3,44(s2)
    800041e8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041ea:	02d05763          	blez	a3,80004218 <write_head+0x5a>
    800041ee:	0001d797          	auipc	a5,0x1d
    800041f2:	4b278793          	addi	a5,a5,1202 # 800216a0 <log+0x30>
    800041f6:	05c50713          	addi	a4,a0,92
    800041fa:	36fd                	addiw	a3,a3,-1
    800041fc:	1682                	slli	a3,a3,0x20
    800041fe:	9281                	srli	a3,a3,0x20
    80004200:	068a                	slli	a3,a3,0x2
    80004202:	0001d617          	auipc	a2,0x1d
    80004206:	4a260613          	addi	a2,a2,1186 # 800216a4 <log+0x34>
    8000420a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000420c:	4390                	lw	a2,0(a5)
    8000420e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004210:	0791                	addi	a5,a5,4
    80004212:	0711                	addi	a4,a4,4
    80004214:	fed79ce3          	bne	a5,a3,8000420c <write_head+0x4e>
  }
  bwrite(buf);
    80004218:	8526                	mv	a0,s1
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	0a4080e7          	jalr	164(ra) # 800032be <bwrite>
  brelse(buf);
    80004222:	8526                	mv	a0,s1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	0d8080e7          	jalr	216(ra) # 800032fc <brelse>
}
    8000422c:	60e2                	ld	ra,24(sp)
    8000422e:	6442                	ld	s0,16(sp)
    80004230:	64a2                	ld	s1,8(sp)
    80004232:	6902                	ld	s2,0(sp)
    80004234:	6105                	addi	sp,sp,32
    80004236:	8082                	ret

0000000080004238 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004238:	0001d797          	auipc	a5,0x1d
    8000423c:	4647a783          	lw	a5,1124(a5) # 8002169c <log+0x2c>
    80004240:	0af05d63          	blez	a5,800042fa <install_trans+0xc2>
{
    80004244:	7139                	addi	sp,sp,-64
    80004246:	fc06                	sd	ra,56(sp)
    80004248:	f822                	sd	s0,48(sp)
    8000424a:	f426                	sd	s1,40(sp)
    8000424c:	f04a                	sd	s2,32(sp)
    8000424e:	ec4e                	sd	s3,24(sp)
    80004250:	e852                	sd	s4,16(sp)
    80004252:	e456                	sd	s5,8(sp)
    80004254:	e05a                	sd	s6,0(sp)
    80004256:	0080                	addi	s0,sp,64
    80004258:	8b2a                	mv	s6,a0
    8000425a:	0001da97          	auipc	s5,0x1d
    8000425e:	446a8a93          	addi	s5,s5,1094 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004262:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004264:	0001d997          	auipc	s3,0x1d
    80004268:	40c98993          	addi	s3,s3,1036 # 80021670 <log>
    8000426c:	a035                	j	80004298 <install_trans+0x60>
      bunpin(dbuf);
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	166080e7          	jalr	358(ra) # 800033d6 <bunpin>
    brelse(lbuf);
    80004278:	854a                	mv	a0,s2
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	082080e7          	jalr	130(ra) # 800032fc <brelse>
    brelse(dbuf);
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	078080e7          	jalr	120(ra) # 800032fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	2a05                	addiw	s4,s4,1
    8000428e:	0a91                	addi	s5,s5,4
    80004290:	02c9a783          	lw	a5,44(s3)
    80004294:	04fa5963          	bge	s4,a5,800042e6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004298:	0189a583          	lw	a1,24(s3)
    8000429c:	014585bb          	addw	a1,a1,s4
    800042a0:	2585                	addiw	a1,a1,1
    800042a2:	0289a503          	lw	a0,40(s3)
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	f26080e7          	jalr	-218(ra) # 800031cc <bread>
    800042ae:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042b0:	000aa583          	lw	a1,0(s5)
    800042b4:	0289a503          	lw	a0,40(s3)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	f14080e7          	jalr	-236(ra) # 800031cc <bread>
    800042c0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042c2:	40000613          	li	a2,1024
    800042c6:	05890593          	addi	a1,s2,88
    800042ca:	05850513          	addi	a0,a0,88
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	a72080e7          	jalr	-1422(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042d6:	8526                	mv	a0,s1
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	fe6080e7          	jalr	-26(ra) # 800032be <bwrite>
    if(recovering == 0)
    800042e0:	f80b1ce3          	bnez	s6,80004278 <install_trans+0x40>
    800042e4:	b769                	j	8000426e <install_trans+0x36>
}
    800042e6:	70e2                	ld	ra,56(sp)
    800042e8:	7442                	ld	s0,48(sp)
    800042ea:	74a2                	ld	s1,40(sp)
    800042ec:	7902                	ld	s2,32(sp)
    800042ee:	69e2                	ld	s3,24(sp)
    800042f0:	6a42                	ld	s4,16(sp)
    800042f2:	6aa2                	ld	s5,8(sp)
    800042f4:	6b02                	ld	s6,0(sp)
    800042f6:	6121                	addi	sp,sp,64
    800042f8:	8082                	ret
    800042fa:	8082                	ret

00000000800042fc <initlog>:
{
    800042fc:	7179                	addi	sp,sp,-48
    800042fe:	f406                	sd	ra,40(sp)
    80004300:	f022                	sd	s0,32(sp)
    80004302:	ec26                	sd	s1,24(sp)
    80004304:	e84a                	sd	s2,16(sp)
    80004306:	e44e                	sd	s3,8(sp)
    80004308:	1800                	addi	s0,sp,48
    8000430a:	892a                	mv	s2,a0
    8000430c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000430e:	0001d497          	auipc	s1,0x1d
    80004312:	36248493          	addi	s1,s1,866 # 80021670 <log>
    80004316:	00004597          	auipc	a1,0x4
    8000431a:	3f258593          	addi	a1,a1,1010 # 80008708 <syscalls+0x1e8>
    8000431e:	8526                	mv	a0,s1
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	834080e7          	jalr	-1996(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004328:	0149a583          	lw	a1,20(s3)
    8000432c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000432e:	0109a783          	lw	a5,16(s3)
    80004332:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004334:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004338:	854a                	mv	a0,s2
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	e92080e7          	jalr	-366(ra) # 800031cc <bread>
  log.lh.n = lh->n;
    80004342:	4d3c                	lw	a5,88(a0)
    80004344:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004346:	02f05563          	blez	a5,80004370 <initlog+0x74>
    8000434a:	05c50713          	addi	a4,a0,92
    8000434e:	0001d697          	auipc	a3,0x1d
    80004352:	35268693          	addi	a3,a3,850 # 800216a0 <log+0x30>
    80004356:	37fd                	addiw	a5,a5,-1
    80004358:	1782                	slli	a5,a5,0x20
    8000435a:	9381                	srli	a5,a5,0x20
    8000435c:	078a                	slli	a5,a5,0x2
    8000435e:	06050613          	addi	a2,a0,96
    80004362:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004364:	4310                	lw	a2,0(a4)
    80004366:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004368:	0711                	addi	a4,a4,4
    8000436a:	0691                	addi	a3,a3,4
    8000436c:	fef71ce3          	bne	a4,a5,80004364 <initlog+0x68>
  brelse(buf);
    80004370:	fffff097          	auipc	ra,0xfffff
    80004374:	f8c080e7          	jalr	-116(ra) # 800032fc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004378:	4505                	li	a0,1
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	ebe080e7          	jalr	-322(ra) # 80004238 <install_trans>
  log.lh.n = 0;
    80004382:	0001d797          	auipc	a5,0x1d
    80004386:	3007ad23          	sw	zero,794(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	e34080e7          	jalr	-460(ra) # 800041be <write_head>
}
    80004392:	70a2                	ld	ra,40(sp)
    80004394:	7402                	ld	s0,32(sp)
    80004396:	64e2                	ld	s1,24(sp)
    80004398:	6942                	ld	s2,16(sp)
    8000439a:	69a2                	ld	s3,8(sp)
    8000439c:	6145                	addi	sp,sp,48
    8000439e:	8082                	ret

00000000800043a0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043a0:	1101                	addi	sp,sp,-32
    800043a2:	ec06                	sd	ra,24(sp)
    800043a4:	e822                	sd	s0,16(sp)
    800043a6:	e426                	sd	s1,8(sp)
    800043a8:	e04a                	sd	s2,0(sp)
    800043aa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043ac:	0001d517          	auipc	a0,0x1d
    800043b0:	2c450513          	addi	a0,a0,708 # 80021670 <log>
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800043bc:	0001d497          	auipc	s1,0x1d
    800043c0:	2b448493          	addi	s1,s1,692 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043c4:	4979                	li	s2,30
    800043c6:	a039                	j	800043d4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043c8:	85a6                	mv	a1,s1
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffe097          	auipc	ra,0xffffe
    800043d0:	d1a080e7          	jalr	-742(ra) # 800020e6 <sleep>
    if(log.committing){
    800043d4:	50dc                	lw	a5,36(s1)
    800043d6:	fbed                	bnez	a5,800043c8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043d8:	509c                	lw	a5,32(s1)
    800043da:	0017871b          	addiw	a4,a5,1
    800043de:	0007069b          	sext.w	a3,a4
    800043e2:	0027179b          	slliw	a5,a4,0x2
    800043e6:	9fb9                	addw	a5,a5,a4
    800043e8:	0017979b          	slliw	a5,a5,0x1
    800043ec:	54d8                	lw	a4,44(s1)
    800043ee:	9fb9                	addw	a5,a5,a4
    800043f0:	00f95963          	bge	s2,a5,80004402 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043f4:	85a6                	mv	a1,s1
    800043f6:	8526                	mv	a0,s1
    800043f8:	ffffe097          	auipc	ra,0xffffe
    800043fc:	cee080e7          	jalr	-786(ra) # 800020e6 <sleep>
    80004400:	bfd1                	j	800043d4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004402:	0001d517          	auipc	a0,0x1d
    80004406:	26e50513          	addi	a0,a0,622 # 80021670 <log>
    8000440a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	88c080e7          	jalr	-1908(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004414:	60e2                	ld	ra,24(sp)
    80004416:	6442                	ld	s0,16(sp)
    80004418:	64a2                	ld	s1,8(sp)
    8000441a:	6902                	ld	s2,0(sp)
    8000441c:	6105                	addi	sp,sp,32
    8000441e:	8082                	ret

0000000080004420 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004420:	7139                	addi	sp,sp,-64
    80004422:	fc06                	sd	ra,56(sp)
    80004424:	f822                	sd	s0,48(sp)
    80004426:	f426                	sd	s1,40(sp)
    80004428:	f04a                	sd	s2,32(sp)
    8000442a:	ec4e                	sd	s3,24(sp)
    8000442c:	e852                	sd	s4,16(sp)
    8000442e:	e456                	sd	s5,8(sp)
    80004430:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004432:	0001d497          	auipc	s1,0x1d
    80004436:	23e48493          	addi	s1,s1,574 # 80021670 <log>
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004444:	509c                	lw	a5,32(s1)
    80004446:	37fd                	addiw	a5,a5,-1
    80004448:	0007891b          	sext.w	s2,a5
    8000444c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000444e:	50dc                	lw	a5,36(s1)
    80004450:	efb9                	bnez	a5,800044ae <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004452:	06091663          	bnez	s2,800044be <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004456:	0001d497          	auipc	s1,0x1d
    8000445a:	21a48493          	addi	s1,s1,538 # 80021670 <log>
    8000445e:	4785                	li	a5,1
    80004460:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004462:	8526                	mv	a0,s1
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	834080e7          	jalr	-1996(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000446c:	54dc                	lw	a5,44(s1)
    8000446e:	06f04763          	bgtz	a5,800044dc <end_op+0xbc>
    acquire(&log.lock);
    80004472:	0001d497          	auipc	s1,0x1d
    80004476:	1fe48493          	addi	s1,s1,510 # 80021670 <log>
    8000447a:	8526                	mv	a0,s1
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	768080e7          	jalr	1896(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004484:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004488:	8526                	mv	a0,s1
    8000448a:	ffffe097          	auipc	ra,0xffffe
    8000448e:	f34080e7          	jalr	-204(ra) # 800023be <wakeup>
    release(&log.lock);
    80004492:	8526                	mv	a0,s1
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
}
    8000449c:	70e2                	ld	ra,56(sp)
    8000449e:	7442                	ld	s0,48(sp)
    800044a0:	74a2                	ld	s1,40(sp)
    800044a2:	7902                	ld	s2,32(sp)
    800044a4:	69e2                	ld	s3,24(sp)
    800044a6:	6a42                	ld	s4,16(sp)
    800044a8:	6aa2                	ld	s5,8(sp)
    800044aa:	6121                	addi	sp,sp,64
    800044ac:	8082                	ret
    panic("log.committing");
    800044ae:	00004517          	auipc	a0,0x4
    800044b2:	26250513          	addi	a0,a0,610 # 80008710 <syscalls+0x1f0>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	088080e7          	jalr	136(ra) # 8000053e <panic>
    wakeup(&log);
    800044be:	0001d497          	auipc	s1,0x1d
    800044c2:	1b248493          	addi	s1,s1,434 # 80021670 <log>
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffe097          	auipc	ra,0xffffe
    800044cc:	ef6080e7          	jalr	-266(ra) # 800023be <wakeup>
  release(&log.lock);
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
  if(do_commit){
    800044da:	b7c9                	j	8000449c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044dc:	0001da97          	auipc	s5,0x1d
    800044e0:	1c4a8a93          	addi	s5,s5,452 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044e4:	0001da17          	auipc	s4,0x1d
    800044e8:	18ca0a13          	addi	s4,s4,396 # 80021670 <log>
    800044ec:	018a2583          	lw	a1,24(s4)
    800044f0:	012585bb          	addw	a1,a1,s2
    800044f4:	2585                	addiw	a1,a1,1
    800044f6:	028a2503          	lw	a0,40(s4)
    800044fa:	fffff097          	auipc	ra,0xfffff
    800044fe:	cd2080e7          	jalr	-814(ra) # 800031cc <bread>
    80004502:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004504:	000aa583          	lw	a1,0(s5)
    80004508:	028a2503          	lw	a0,40(s4)
    8000450c:	fffff097          	auipc	ra,0xfffff
    80004510:	cc0080e7          	jalr	-832(ra) # 800031cc <bread>
    80004514:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004516:	40000613          	li	a2,1024
    8000451a:	05850593          	addi	a1,a0,88
    8000451e:	05848513          	addi	a0,s1,88
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	81e080e7          	jalr	-2018(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000452a:	8526                	mv	a0,s1
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	d92080e7          	jalr	-622(ra) # 800032be <bwrite>
    brelse(from);
    80004534:	854e                	mv	a0,s3
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	dc6080e7          	jalr	-570(ra) # 800032fc <brelse>
    brelse(to);
    8000453e:	8526                	mv	a0,s1
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	dbc080e7          	jalr	-580(ra) # 800032fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004548:	2905                	addiw	s2,s2,1
    8000454a:	0a91                	addi	s5,s5,4
    8000454c:	02ca2783          	lw	a5,44(s4)
    80004550:	f8f94ee3          	blt	s2,a5,800044ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004554:	00000097          	auipc	ra,0x0
    80004558:	c6a080e7          	jalr	-918(ra) # 800041be <write_head>
    install_trans(0); // Now install writes to home locations
    8000455c:	4501                	li	a0,0
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	cda080e7          	jalr	-806(ra) # 80004238 <install_trans>
    log.lh.n = 0;
    80004566:	0001d797          	auipc	a5,0x1d
    8000456a:	1207ab23          	sw	zero,310(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000456e:	00000097          	auipc	ra,0x0
    80004572:	c50080e7          	jalr	-944(ra) # 800041be <write_head>
    80004576:	bdf5                	j	80004472 <end_op+0x52>

0000000080004578 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004578:	1101                	addi	sp,sp,-32
    8000457a:	ec06                	sd	ra,24(sp)
    8000457c:	e822                	sd	s0,16(sp)
    8000457e:	e426                	sd	s1,8(sp)
    80004580:	e04a                	sd	s2,0(sp)
    80004582:	1000                	addi	s0,sp,32
    80004584:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004586:	0001d917          	auipc	s2,0x1d
    8000458a:	0ea90913          	addi	s2,s2,234 # 80021670 <log>
    8000458e:	854a                	mv	a0,s2
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	654080e7          	jalr	1620(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004598:	02c92603          	lw	a2,44(s2)
    8000459c:	47f5                	li	a5,29
    8000459e:	06c7c563          	blt	a5,a2,80004608 <log_write+0x90>
    800045a2:	0001d797          	auipc	a5,0x1d
    800045a6:	0ea7a783          	lw	a5,234(a5) # 8002168c <log+0x1c>
    800045aa:	37fd                	addiw	a5,a5,-1
    800045ac:	04f65e63          	bge	a2,a5,80004608 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045b0:	0001d797          	auipc	a5,0x1d
    800045b4:	0e07a783          	lw	a5,224(a5) # 80021690 <log+0x20>
    800045b8:	06f05063          	blez	a5,80004618 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045bc:	4781                	li	a5,0
    800045be:	06c05563          	blez	a2,80004628 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045c2:	44cc                	lw	a1,12(s1)
    800045c4:	0001d717          	auipc	a4,0x1d
    800045c8:	0dc70713          	addi	a4,a4,220 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045cc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045ce:	4314                	lw	a3,0(a4)
    800045d0:	04b68c63          	beq	a3,a1,80004628 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045d4:	2785                	addiw	a5,a5,1
    800045d6:	0711                	addi	a4,a4,4
    800045d8:	fef61be3          	bne	a2,a5,800045ce <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045dc:	0621                	addi	a2,a2,8
    800045de:	060a                	slli	a2,a2,0x2
    800045e0:	0001d797          	auipc	a5,0x1d
    800045e4:	09078793          	addi	a5,a5,144 # 80021670 <log>
    800045e8:	963e                	add	a2,a2,a5
    800045ea:	44dc                	lw	a5,12(s1)
    800045ec:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045ee:	8526                	mv	a0,s1
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	daa080e7          	jalr	-598(ra) # 8000339a <bpin>
    log.lh.n++;
    800045f8:	0001d717          	auipc	a4,0x1d
    800045fc:	07870713          	addi	a4,a4,120 # 80021670 <log>
    80004600:	575c                	lw	a5,44(a4)
    80004602:	2785                	addiw	a5,a5,1
    80004604:	d75c                	sw	a5,44(a4)
    80004606:	a835                	j	80004642 <log_write+0xca>
    panic("too big a transaction");
    80004608:	00004517          	auipc	a0,0x4
    8000460c:	11850513          	addi	a0,a0,280 # 80008720 <syscalls+0x200>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004618:	00004517          	auipc	a0,0x4
    8000461c:	12050513          	addi	a0,a0,288 # 80008738 <syscalls+0x218>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004628:	00878713          	addi	a4,a5,8
    8000462c:	00271693          	slli	a3,a4,0x2
    80004630:	0001d717          	auipc	a4,0x1d
    80004634:	04070713          	addi	a4,a4,64 # 80021670 <log>
    80004638:	9736                	add	a4,a4,a3
    8000463a:	44d4                	lw	a3,12(s1)
    8000463c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000463e:	faf608e3          	beq	a2,a5,800045ee <log_write+0x76>
  }
  release(&log.lock);
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	02e50513          	addi	a0,a0,46 # 80021670 <log>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	64e080e7          	jalr	1614(ra) # 80000c98 <release>
}
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6902                	ld	s2,0(sp)
    8000465a:	6105                	addi	sp,sp,32
    8000465c:	8082                	ret

000000008000465e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	e426                	sd	s1,8(sp)
    80004666:	e04a                	sd	s2,0(sp)
    80004668:	1000                	addi	s0,sp,32
    8000466a:	84aa                	mv	s1,a0
    8000466c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000466e:	00004597          	auipc	a1,0x4
    80004672:	0ea58593          	addi	a1,a1,234 # 80008758 <syscalls+0x238>
    80004676:	0521                	addi	a0,a0,8
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	4dc080e7          	jalr	1244(ra) # 80000b54 <initlock>
  lk->name = name;
    80004680:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004684:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004688:	0204a423          	sw	zero,40(s1)
}
    8000468c:	60e2                	ld	ra,24(sp)
    8000468e:	6442                	ld	s0,16(sp)
    80004690:	64a2                	ld	s1,8(sp)
    80004692:	6902                	ld	s2,0(sp)
    80004694:	6105                	addi	sp,sp,32
    80004696:	8082                	ret

0000000080004698 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004698:	1101                	addi	sp,sp,-32
    8000469a:	ec06                	sd	ra,24(sp)
    8000469c:	e822                	sd	s0,16(sp)
    8000469e:	e426                	sd	s1,8(sp)
    800046a0:	e04a                	sd	s2,0(sp)
    800046a2:	1000                	addi	s0,sp,32
    800046a4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a6:	00850913          	addi	s2,a0,8
    800046aa:	854a                	mv	a0,s2
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800046b4:	409c                	lw	a5,0(s1)
    800046b6:	cb89                	beqz	a5,800046c8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046b8:	85ca                	mv	a1,s2
    800046ba:	8526                	mv	a0,s1
    800046bc:	ffffe097          	auipc	ra,0xffffe
    800046c0:	a2a080e7          	jalr	-1494(ra) # 800020e6 <sleep>
  while (lk->locked) {
    800046c4:	409c                	lw	a5,0(s1)
    800046c6:	fbed                	bnez	a5,800046b8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046c8:	4785                	li	a5,1
    800046ca:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046cc:	ffffd097          	auipc	ra,0xffffd
    800046d0:	2e4080e7          	jalr	740(ra) # 800019b0 <myproc>
    800046d4:	591c                	lw	a5,48(a0)
    800046d6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046d8:	854a                	mv	a0,s2
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	5be080e7          	jalr	1470(ra) # 80000c98 <release>
}
    800046e2:	60e2                	ld	ra,24(sp)
    800046e4:	6442                	ld	s0,16(sp)
    800046e6:	64a2                	ld	s1,8(sp)
    800046e8:	6902                	ld	s2,0(sp)
    800046ea:	6105                	addi	sp,sp,32
    800046ec:	8082                	ret

00000000800046ee <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046ee:	1101                	addi	sp,sp,-32
    800046f0:	ec06                	sd	ra,24(sp)
    800046f2:	e822                	sd	s0,16(sp)
    800046f4:	e426                	sd	s1,8(sp)
    800046f6:	e04a                	sd	s2,0(sp)
    800046f8:	1000                	addi	s0,sp,32
    800046fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046fc:	00850913          	addi	s2,a0,8
    80004700:	854a                	mv	a0,s2
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4e2080e7          	jalr	1250(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000470a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000470e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004712:	8526                	mv	a0,s1
    80004714:	ffffe097          	auipc	ra,0xffffe
    80004718:	caa080e7          	jalr	-854(ra) # 800023be <wakeup>
  release(&lk->lk);
    8000471c:	854a                	mv	a0,s2
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	57a080e7          	jalr	1402(ra) # 80000c98 <release>
}
    80004726:	60e2                	ld	ra,24(sp)
    80004728:	6442                	ld	s0,16(sp)
    8000472a:	64a2                	ld	s1,8(sp)
    8000472c:	6902                	ld	s2,0(sp)
    8000472e:	6105                	addi	sp,sp,32
    80004730:	8082                	ret

0000000080004732 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004732:	7179                	addi	sp,sp,-48
    80004734:	f406                	sd	ra,40(sp)
    80004736:	f022                	sd	s0,32(sp)
    80004738:	ec26                	sd	s1,24(sp)
    8000473a:	e84a                	sd	s2,16(sp)
    8000473c:	e44e                	sd	s3,8(sp)
    8000473e:	1800                	addi	s0,sp,48
    80004740:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004742:	00850913          	addi	s2,a0,8
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	49c080e7          	jalr	1180(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004750:	409c                	lw	a5,0(s1)
    80004752:	ef99                	bnez	a5,80004770 <holdingsleep+0x3e>
    80004754:	4481                	li	s1,0
  release(&lk->lk);
    80004756:	854a                	mv	a0,s2
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	540080e7          	jalr	1344(ra) # 80000c98 <release>
  return r;
}
    80004760:	8526                	mv	a0,s1
    80004762:	70a2                	ld	ra,40(sp)
    80004764:	7402                	ld	s0,32(sp)
    80004766:	64e2                	ld	s1,24(sp)
    80004768:	6942                	ld	s2,16(sp)
    8000476a:	69a2                	ld	s3,8(sp)
    8000476c:	6145                	addi	sp,sp,48
    8000476e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004770:	0284a983          	lw	s3,40(s1)
    80004774:	ffffd097          	auipc	ra,0xffffd
    80004778:	23c080e7          	jalr	572(ra) # 800019b0 <myproc>
    8000477c:	5904                	lw	s1,48(a0)
    8000477e:	413484b3          	sub	s1,s1,s3
    80004782:	0014b493          	seqz	s1,s1
    80004786:	bfc1                	j	80004756 <holdingsleep+0x24>

0000000080004788 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004788:	1141                	addi	sp,sp,-16
    8000478a:	e406                	sd	ra,8(sp)
    8000478c:	e022                	sd	s0,0(sp)
    8000478e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004790:	00004597          	auipc	a1,0x4
    80004794:	fd858593          	addi	a1,a1,-40 # 80008768 <syscalls+0x248>
    80004798:	0001d517          	auipc	a0,0x1d
    8000479c:	02050513          	addi	a0,a0,32 # 800217b8 <ftable>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	3b4080e7          	jalr	948(ra) # 80000b54 <initlock>
}
    800047a8:	60a2                	ld	ra,8(sp)
    800047aa:	6402                	ld	s0,0(sp)
    800047ac:	0141                	addi	sp,sp,16
    800047ae:	8082                	ret

00000000800047b0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047b0:	1101                	addi	sp,sp,-32
    800047b2:	ec06                	sd	ra,24(sp)
    800047b4:	e822                	sd	s0,16(sp)
    800047b6:	e426                	sd	s1,8(sp)
    800047b8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047ba:	0001d517          	auipc	a0,0x1d
    800047be:	ffe50513          	addi	a0,a0,-2 # 800217b8 <ftable>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	422080e7          	jalr	1058(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047ca:	0001d497          	auipc	s1,0x1d
    800047ce:	00648493          	addi	s1,s1,6 # 800217d0 <ftable+0x18>
    800047d2:	0001e717          	auipc	a4,0x1e
    800047d6:	f9e70713          	addi	a4,a4,-98 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800047da:	40dc                	lw	a5,4(s1)
    800047dc:	cf99                	beqz	a5,800047fa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047de:	02848493          	addi	s1,s1,40
    800047e2:	fee49ce3          	bne	s1,a4,800047da <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047e6:	0001d517          	auipc	a0,0x1d
    800047ea:	fd250513          	addi	a0,a0,-46 # 800217b8 <ftable>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	4aa080e7          	jalr	1194(ra) # 80000c98 <release>
  return 0;
    800047f6:	4481                	li	s1,0
    800047f8:	a819                	j	8000480e <filealloc+0x5e>
      f->ref = 1;
    800047fa:	4785                	li	a5,1
    800047fc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047fe:	0001d517          	auipc	a0,0x1d
    80004802:	fba50513          	addi	a0,a0,-70 # 800217b8 <ftable>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	492080e7          	jalr	1170(ra) # 80000c98 <release>
}
    8000480e:	8526                	mv	a0,s1
    80004810:	60e2                	ld	ra,24(sp)
    80004812:	6442                	ld	s0,16(sp)
    80004814:	64a2                	ld	s1,8(sp)
    80004816:	6105                	addi	sp,sp,32
    80004818:	8082                	ret

000000008000481a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000481a:	1101                	addi	sp,sp,-32
    8000481c:	ec06                	sd	ra,24(sp)
    8000481e:	e822                	sd	s0,16(sp)
    80004820:	e426                	sd	s1,8(sp)
    80004822:	1000                	addi	s0,sp,32
    80004824:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004826:	0001d517          	auipc	a0,0x1d
    8000482a:	f9250513          	addi	a0,a0,-110 # 800217b8 <ftable>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	3b6080e7          	jalr	950(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004836:	40dc                	lw	a5,4(s1)
    80004838:	02f05263          	blez	a5,8000485c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000483c:	2785                	addiw	a5,a5,1
    8000483e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004840:	0001d517          	auipc	a0,0x1d
    80004844:	f7850513          	addi	a0,a0,-136 # 800217b8 <ftable>
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	450080e7          	jalr	1104(ra) # 80000c98 <release>
  return f;
}
    80004850:	8526                	mv	a0,s1
    80004852:	60e2                	ld	ra,24(sp)
    80004854:	6442                	ld	s0,16(sp)
    80004856:	64a2                	ld	s1,8(sp)
    80004858:	6105                	addi	sp,sp,32
    8000485a:	8082                	ret
    panic("filedup");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	f1450513          	addi	a0,a0,-236 # 80008770 <syscalls+0x250>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	cda080e7          	jalr	-806(ra) # 8000053e <panic>

000000008000486c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000486c:	7139                	addi	sp,sp,-64
    8000486e:	fc06                	sd	ra,56(sp)
    80004870:	f822                	sd	s0,48(sp)
    80004872:	f426                	sd	s1,40(sp)
    80004874:	f04a                	sd	s2,32(sp)
    80004876:	ec4e                	sd	s3,24(sp)
    80004878:	e852                	sd	s4,16(sp)
    8000487a:	e456                	sd	s5,8(sp)
    8000487c:	0080                	addi	s0,sp,64
    8000487e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004880:	0001d517          	auipc	a0,0x1d
    80004884:	f3850513          	addi	a0,a0,-200 # 800217b8 <ftable>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	35c080e7          	jalr	860(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004890:	40dc                	lw	a5,4(s1)
    80004892:	06f05163          	blez	a5,800048f4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004896:	37fd                	addiw	a5,a5,-1
    80004898:	0007871b          	sext.w	a4,a5
    8000489c:	c0dc                	sw	a5,4(s1)
    8000489e:	06e04363          	bgtz	a4,80004904 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048a2:	0004a903          	lw	s2,0(s1)
    800048a6:	0094ca83          	lbu	s5,9(s1)
    800048aa:	0104ba03          	ld	s4,16(s1)
    800048ae:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048b2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048b6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048ba:	0001d517          	auipc	a0,0x1d
    800048be:	efe50513          	addi	a0,a0,-258 # 800217b8 <ftable>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	3d6080e7          	jalr	982(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800048ca:	4785                	li	a5,1
    800048cc:	04f90d63          	beq	s2,a5,80004926 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048d0:	3979                	addiw	s2,s2,-2
    800048d2:	4785                	li	a5,1
    800048d4:	0527e063          	bltu	a5,s2,80004914 <fileclose+0xa8>
    begin_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	ac8080e7          	jalr	-1336(ra) # 800043a0 <begin_op>
    iput(ff.ip);
    800048e0:	854e                	mv	a0,s3
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	2a6080e7          	jalr	678(ra) # 80003b88 <iput>
    end_op();
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	b36080e7          	jalr	-1226(ra) # 80004420 <end_op>
    800048f2:	a00d                	j	80004914 <fileclose+0xa8>
    panic("fileclose");
    800048f4:	00004517          	auipc	a0,0x4
    800048f8:	e8450513          	addi	a0,a0,-380 # 80008778 <syscalls+0x258>
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004904:	0001d517          	auipc	a0,0x1d
    80004908:	eb450513          	addi	a0,a0,-332 # 800217b8 <ftable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	38c080e7          	jalr	908(ra) # 80000c98 <release>
  }
}
    80004914:	70e2                	ld	ra,56(sp)
    80004916:	7442                	ld	s0,48(sp)
    80004918:	74a2                	ld	s1,40(sp)
    8000491a:	7902                	ld	s2,32(sp)
    8000491c:	69e2                	ld	s3,24(sp)
    8000491e:	6a42                	ld	s4,16(sp)
    80004920:	6aa2                	ld	s5,8(sp)
    80004922:	6121                	addi	sp,sp,64
    80004924:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004926:	85d6                	mv	a1,s5
    80004928:	8552                	mv	a0,s4
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	34c080e7          	jalr	844(ra) # 80004c76 <pipeclose>
    80004932:	b7cd                	j	80004914 <fileclose+0xa8>

0000000080004934 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004934:	715d                	addi	sp,sp,-80
    80004936:	e486                	sd	ra,72(sp)
    80004938:	e0a2                	sd	s0,64(sp)
    8000493a:	fc26                	sd	s1,56(sp)
    8000493c:	f84a                	sd	s2,48(sp)
    8000493e:	f44e                	sd	s3,40(sp)
    80004940:	0880                	addi	s0,sp,80
    80004942:	84aa                	mv	s1,a0
    80004944:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004946:	ffffd097          	auipc	ra,0xffffd
    8000494a:	06a080e7          	jalr	106(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000494e:	409c                	lw	a5,0(s1)
    80004950:	37f9                	addiw	a5,a5,-2
    80004952:	4705                	li	a4,1
    80004954:	04f76763          	bltu	a4,a5,800049a2 <filestat+0x6e>
    80004958:	892a                	mv	s2,a0
    ilock(f->ip);
    8000495a:	6c88                	ld	a0,24(s1)
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	072080e7          	jalr	114(ra) # 800039ce <ilock>
    stati(f->ip, &st);
    80004964:	fb840593          	addi	a1,s0,-72
    80004968:	6c88                	ld	a0,24(s1)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	2ee080e7          	jalr	750(ra) # 80003c58 <stati>
    iunlock(f->ip);
    80004972:	6c88                	ld	a0,24(s1)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	11c080e7          	jalr	284(ra) # 80003a90 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000497c:	46e1                	li	a3,24
    8000497e:	fb840613          	addi	a2,s0,-72
    80004982:	85ce                	mv	a1,s3
    80004984:	05093503          	ld	a0,80(s2)
    80004988:	ffffd097          	auipc	ra,0xffffd
    8000498c:	cea080e7          	jalr	-790(ra) # 80001672 <copyout>
    80004990:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004994:	60a6                	ld	ra,72(sp)
    80004996:	6406                	ld	s0,64(sp)
    80004998:	74e2                	ld	s1,56(sp)
    8000499a:	7942                	ld	s2,48(sp)
    8000499c:	79a2                	ld	s3,40(sp)
    8000499e:	6161                	addi	sp,sp,80
    800049a0:	8082                	ret
  return -1;
    800049a2:	557d                	li	a0,-1
    800049a4:	bfc5                	j	80004994 <filestat+0x60>

00000000800049a6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049a6:	7179                	addi	sp,sp,-48
    800049a8:	f406                	sd	ra,40(sp)
    800049aa:	f022                	sd	s0,32(sp)
    800049ac:	ec26                	sd	s1,24(sp)
    800049ae:	e84a                	sd	s2,16(sp)
    800049b0:	e44e                	sd	s3,8(sp)
    800049b2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049b4:	00854783          	lbu	a5,8(a0)
    800049b8:	c3d5                	beqz	a5,80004a5c <fileread+0xb6>
    800049ba:	84aa                	mv	s1,a0
    800049bc:	89ae                	mv	s3,a1
    800049be:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049c0:	411c                	lw	a5,0(a0)
    800049c2:	4705                	li	a4,1
    800049c4:	04e78963          	beq	a5,a4,80004a16 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049c8:	470d                	li	a4,3
    800049ca:	04e78d63          	beq	a5,a4,80004a24 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ce:	4709                	li	a4,2
    800049d0:	06e79e63          	bne	a5,a4,80004a4c <fileread+0xa6>
    ilock(f->ip);
    800049d4:	6d08                	ld	a0,24(a0)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	ff8080e7          	jalr	-8(ra) # 800039ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049de:	874a                	mv	a4,s2
    800049e0:	5094                	lw	a3,32(s1)
    800049e2:	864e                	mv	a2,s3
    800049e4:	4585                	li	a1,1
    800049e6:	6c88                	ld	a0,24(s1)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	29a080e7          	jalr	666(ra) # 80003c82 <readi>
    800049f0:	892a                	mv	s2,a0
    800049f2:	00a05563          	blez	a0,800049fc <fileread+0x56>
      f->off += r;
    800049f6:	509c                	lw	a5,32(s1)
    800049f8:	9fa9                	addw	a5,a5,a0
    800049fa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049fc:	6c88                	ld	a0,24(s1)
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	092080e7          	jalr	146(ra) # 80003a90 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a06:	854a                	mv	a0,s2
    80004a08:	70a2                	ld	ra,40(sp)
    80004a0a:	7402                	ld	s0,32(sp)
    80004a0c:	64e2                	ld	s1,24(sp)
    80004a0e:	6942                	ld	s2,16(sp)
    80004a10:	69a2                	ld	s3,8(sp)
    80004a12:	6145                	addi	sp,sp,48
    80004a14:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a16:	6908                	ld	a0,16(a0)
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	3c8080e7          	jalr	968(ra) # 80004de0 <piperead>
    80004a20:	892a                	mv	s2,a0
    80004a22:	b7d5                	j	80004a06 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a24:	02451783          	lh	a5,36(a0)
    80004a28:	03079693          	slli	a3,a5,0x30
    80004a2c:	92c1                	srli	a3,a3,0x30
    80004a2e:	4725                	li	a4,9
    80004a30:	02d76863          	bltu	a4,a3,80004a60 <fileread+0xba>
    80004a34:	0792                	slli	a5,a5,0x4
    80004a36:	0001d717          	auipc	a4,0x1d
    80004a3a:	ce270713          	addi	a4,a4,-798 # 80021718 <devsw>
    80004a3e:	97ba                	add	a5,a5,a4
    80004a40:	639c                	ld	a5,0(a5)
    80004a42:	c38d                	beqz	a5,80004a64 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a44:	4505                	li	a0,1
    80004a46:	9782                	jalr	a5
    80004a48:	892a                	mv	s2,a0
    80004a4a:	bf75                	j	80004a06 <fileread+0x60>
    panic("fileread");
    80004a4c:	00004517          	auipc	a0,0x4
    80004a50:	d3c50513          	addi	a0,a0,-708 # 80008788 <syscalls+0x268>
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
    return -1;
    80004a5c:	597d                	li	s2,-1
    80004a5e:	b765                	j	80004a06 <fileread+0x60>
      return -1;
    80004a60:	597d                	li	s2,-1
    80004a62:	b755                	j	80004a06 <fileread+0x60>
    80004a64:	597d                	li	s2,-1
    80004a66:	b745                	j	80004a06 <fileread+0x60>

0000000080004a68 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a68:	715d                	addi	sp,sp,-80
    80004a6a:	e486                	sd	ra,72(sp)
    80004a6c:	e0a2                	sd	s0,64(sp)
    80004a6e:	fc26                	sd	s1,56(sp)
    80004a70:	f84a                	sd	s2,48(sp)
    80004a72:	f44e                	sd	s3,40(sp)
    80004a74:	f052                	sd	s4,32(sp)
    80004a76:	ec56                	sd	s5,24(sp)
    80004a78:	e85a                	sd	s6,16(sp)
    80004a7a:	e45e                	sd	s7,8(sp)
    80004a7c:	e062                	sd	s8,0(sp)
    80004a7e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a80:	00954783          	lbu	a5,9(a0)
    80004a84:	10078663          	beqz	a5,80004b90 <filewrite+0x128>
    80004a88:	892a                	mv	s2,a0
    80004a8a:	8aae                	mv	s5,a1
    80004a8c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a8e:	411c                	lw	a5,0(a0)
    80004a90:	4705                	li	a4,1
    80004a92:	02e78263          	beq	a5,a4,80004ab6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a96:	470d                	li	a4,3
    80004a98:	02e78663          	beq	a5,a4,80004ac4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a9c:	4709                	li	a4,2
    80004a9e:	0ee79163          	bne	a5,a4,80004b80 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004aa2:	0ac05d63          	blez	a2,80004b5c <filewrite+0xf4>
    int i = 0;
    80004aa6:	4981                	li	s3,0
    80004aa8:	6b05                	lui	s6,0x1
    80004aaa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aae:	6b85                	lui	s7,0x1
    80004ab0:	c00b8b9b          	addiw	s7,s7,-1024
    80004ab4:	a861                	j	80004b4c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ab6:	6908                	ld	a0,16(a0)
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	22e080e7          	jalr	558(ra) # 80004ce6 <pipewrite>
    80004ac0:	8a2a                	mv	s4,a0
    80004ac2:	a045                	j	80004b62 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ac4:	02451783          	lh	a5,36(a0)
    80004ac8:	03079693          	slli	a3,a5,0x30
    80004acc:	92c1                	srli	a3,a3,0x30
    80004ace:	4725                	li	a4,9
    80004ad0:	0cd76263          	bltu	a4,a3,80004b94 <filewrite+0x12c>
    80004ad4:	0792                	slli	a5,a5,0x4
    80004ad6:	0001d717          	auipc	a4,0x1d
    80004ada:	c4270713          	addi	a4,a4,-958 # 80021718 <devsw>
    80004ade:	97ba                	add	a5,a5,a4
    80004ae0:	679c                	ld	a5,8(a5)
    80004ae2:	cbdd                	beqz	a5,80004b98 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ae4:	4505                	li	a0,1
    80004ae6:	9782                	jalr	a5
    80004ae8:	8a2a                	mv	s4,a0
    80004aea:	a8a5                	j	80004b62 <filewrite+0xfa>
    80004aec:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	8b0080e7          	jalr	-1872(ra) # 800043a0 <begin_op>
      ilock(f->ip);
    80004af8:	01893503          	ld	a0,24(s2)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	ed2080e7          	jalr	-302(ra) # 800039ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b04:	8762                	mv	a4,s8
    80004b06:	02092683          	lw	a3,32(s2)
    80004b0a:	01598633          	add	a2,s3,s5
    80004b0e:	4585                	li	a1,1
    80004b10:	01893503          	ld	a0,24(s2)
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	266080e7          	jalr	614(ra) # 80003d7a <writei>
    80004b1c:	84aa                	mv	s1,a0
    80004b1e:	00a05763          	blez	a0,80004b2c <filewrite+0xc4>
        f->off += r;
    80004b22:	02092783          	lw	a5,32(s2)
    80004b26:	9fa9                	addw	a5,a5,a0
    80004b28:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b2c:	01893503          	ld	a0,24(s2)
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	f60080e7          	jalr	-160(ra) # 80003a90 <iunlock>
      end_op();
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	8e8080e7          	jalr	-1816(ra) # 80004420 <end_op>

      if(r != n1){
    80004b40:	009c1f63          	bne	s8,s1,80004b5e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b44:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b48:	0149db63          	bge	s3,s4,80004b5e <filewrite+0xf6>
      int n1 = n - i;
    80004b4c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b50:	84be                	mv	s1,a5
    80004b52:	2781                	sext.w	a5,a5
    80004b54:	f8fb5ce3          	bge	s6,a5,80004aec <filewrite+0x84>
    80004b58:	84de                	mv	s1,s7
    80004b5a:	bf49                	j	80004aec <filewrite+0x84>
    int i = 0;
    80004b5c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b5e:	013a1f63          	bne	s4,s3,80004b7c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b62:	8552                	mv	a0,s4
    80004b64:	60a6                	ld	ra,72(sp)
    80004b66:	6406                	ld	s0,64(sp)
    80004b68:	74e2                	ld	s1,56(sp)
    80004b6a:	7942                	ld	s2,48(sp)
    80004b6c:	79a2                	ld	s3,40(sp)
    80004b6e:	7a02                	ld	s4,32(sp)
    80004b70:	6ae2                	ld	s5,24(sp)
    80004b72:	6b42                	ld	s6,16(sp)
    80004b74:	6ba2                	ld	s7,8(sp)
    80004b76:	6c02                	ld	s8,0(sp)
    80004b78:	6161                	addi	sp,sp,80
    80004b7a:	8082                	ret
    ret = (i == n ? n : -1);
    80004b7c:	5a7d                	li	s4,-1
    80004b7e:	b7d5                	j	80004b62 <filewrite+0xfa>
    panic("filewrite");
    80004b80:	00004517          	auipc	a0,0x4
    80004b84:	c1850513          	addi	a0,a0,-1000 # 80008798 <syscalls+0x278>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	9b6080e7          	jalr	-1610(ra) # 8000053e <panic>
    return -1;
    80004b90:	5a7d                	li	s4,-1
    80004b92:	bfc1                	j	80004b62 <filewrite+0xfa>
      return -1;
    80004b94:	5a7d                	li	s4,-1
    80004b96:	b7f1                	j	80004b62 <filewrite+0xfa>
    80004b98:	5a7d                	li	s4,-1
    80004b9a:	b7e1                	j	80004b62 <filewrite+0xfa>

0000000080004b9c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b9c:	7179                	addi	sp,sp,-48
    80004b9e:	f406                	sd	ra,40(sp)
    80004ba0:	f022                	sd	s0,32(sp)
    80004ba2:	ec26                	sd	s1,24(sp)
    80004ba4:	e84a                	sd	s2,16(sp)
    80004ba6:	e44e                	sd	s3,8(sp)
    80004ba8:	e052                	sd	s4,0(sp)
    80004baa:	1800                	addi	s0,sp,48
    80004bac:	84aa                	mv	s1,a0
    80004bae:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bb0:	0005b023          	sd	zero,0(a1)
    80004bb4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bb8:	00000097          	auipc	ra,0x0
    80004bbc:	bf8080e7          	jalr	-1032(ra) # 800047b0 <filealloc>
    80004bc0:	e088                	sd	a0,0(s1)
    80004bc2:	c551                	beqz	a0,80004c4e <pipealloc+0xb2>
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	bec080e7          	jalr	-1044(ra) # 800047b0 <filealloc>
    80004bcc:	00aa3023          	sd	a0,0(s4)
    80004bd0:	c92d                	beqz	a0,80004c42 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	f22080e7          	jalr	-222(ra) # 80000af4 <kalloc>
    80004bda:	892a                	mv	s2,a0
    80004bdc:	c125                	beqz	a0,80004c3c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bde:	4985                	li	s3,1
    80004be0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004be4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004be8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bec:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bf0:	00004597          	auipc	a1,0x4
    80004bf4:	88858593          	addi	a1,a1,-1912 # 80008478 <states.1740+0x1b8>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	f5c080e7          	jalr	-164(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004c00:	609c                	ld	a5,0(s1)
    80004c02:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c06:	609c                	ld	a5,0(s1)
    80004c08:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c0c:	609c                	ld	a5,0(s1)
    80004c0e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c12:	609c                	ld	a5,0(s1)
    80004c14:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c18:	000a3783          	ld	a5,0(s4)
    80004c1c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c20:	000a3783          	ld	a5,0(s4)
    80004c24:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c28:	000a3783          	ld	a5,0(s4)
    80004c2c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c30:	000a3783          	ld	a5,0(s4)
    80004c34:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c38:	4501                	li	a0,0
    80004c3a:	a025                	j	80004c62 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c3c:	6088                	ld	a0,0(s1)
    80004c3e:	e501                	bnez	a0,80004c46 <pipealloc+0xaa>
    80004c40:	a039                	j	80004c4e <pipealloc+0xb2>
    80004c42:	6088                	ld	a0,0(s1)
    80004c44:	c51d                	beqz	a0,80004c72 <pipealloc+0xd6>
    fileclose(*f0);
    80004c46:	00000097          	auipc	ra,0x0
    80004c4a:	c26080e7          	jalr	-986(ra) # 8000486c <fileclose>
  if(*f1)
    80004c4e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c52:	557d                	li	a0,-1
  if(*f1)
    80004c54:	c799                	beqz	a5,80004c62 <pipealloc+0xc6>
    fileclose(*f1);
    80004c56:	853e                	mv	a0,a5
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	c14080e7          	jalr	-1004(ra) # 8000486c <fileclose>
  return -1;
    80004c60:	557d                	li	a0,-1
}
    80004c62:	70a2                	ld	ra,40(sp)
    80004c64:	7402                	ld	s0,32(sp)
    80004c66:	64e2                	ld	s1,24(sp)
    80004c68:	6942                	ld	s2,16(sp)
    80004c6a:	69a2                	ld	s3,8(sp)
    80004c6c:	6a02                	ld	s4,0(sp)
    80004c6e:	6145                	addi	sp,sp,48
    80004c70:	8082                	ret
  return -1;
    80004c72:	557d                	li	a0,-1
    80004c74:	b7fd                	j	80004c62 <pipealloc+0xc6>

0000000080004c76 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c76:	1101                	addi	sp,sp,-32
    80004c78:	ec06                	sd	ra,24(sp)
    80004c7a:	e822                	sd	s0,16(sp)
    80004c7c:	e426                	sd	s1,8(sp)
    80004c7e:	e04a                	sd	s2,0(sp)
    80004c80:	1000                	addi	s0,sp,32
    80004c82:	84aa                	mv	s1,a0
    80004c84:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	f5e080e7          	jalr	-162(ra) # 80000be4 <acquire>
  if(writable){
    80004c8e:	02090d63          	beqz	s2,80004cc8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c92:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c96:	21848513          	addi	a0,s1,536
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	724080e7          	jalr	1828(ra) # 800023be <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ca2:	2204b783          	ld	a5,544(s1)
    80004ca6:	eb95                	bnez	a5,80004cda <pipeclose+0x64>
    release(&pi->lock);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	fee080e7          	jalr	-18(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	d44080e7          	jalr	-700(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004cbc:	60e2                	ld	ra,24(sp)
    80004cbe:	6442                	ld	s0,16(sp)
    80004cc0:	64a2                	ld	s1,8(sp)
    80004cc2:	6902                	ld	s2,0(sp)
    80004cc4:	6105                	addi	sp,sp,32
    80004cc6:	8082                	ret
    pi->readopen = 0;
    80004cc8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ccc:	21c48513          	addi	a0,s1,540
    80004cd0:	ffffd097          	auipc	ra,0xffffd
    80004cd4:	6ee080e7          	jalr	1774(ra) # 800023be <wakeup>
    80004cd8:	b7e9                	j	80004ca2 <pipeclose+0x2c>
    release(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	fbc080e7          	jalr	-68(ra) # 80000c98 <release>
}
    80004ce4:	bfe1                	j	80004cbc <pipeclose+0x46>

0000000080004ce6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ce6:	7159                	addi	sp,sp,-112
    80004ce8:	f486                	sd	ra,104(sp)
    80004cea:	f0a2                	sd	s0,96(sp)
    80004cec:	eca6                	sd	s1,88(sp)
    80004cee:	e8ca                	sd	s2,80(sp)
    80004cf0:	e4ce                	sd	s3,72(sp)
    80004cf2:	e0d2                	sd	s4,64(sp)
    80004cf4:	fc56                	sd	s5,56(sp)
    80004cf6:	f85a                	sd	s6,48(sp)
    80004cf8:	f45e                	sd	s7,40(sp)
    80004cfa:	f062                	sd	s8,32(sp)
    80004cfc:	ec66                	sd	s9,24(sp)
    80004cfe:	1880                	addi	s0,sp,112
    80004d00:	84aa                	mv	s1,a0
    80004d02:	8aae                	mv	s5,a1
    80004d04:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	caa080e7          	jalr	-854(ra) # 800019b0 <myproc>
    80004d0e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d10:	8526                	mv	a0,s1
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	ed2080e7          	jalr	-302(ra) # 80000be4 <acquire>
  while(i < n){
    80004d1a:	0d405163          	blez	s4,80004ddc <pipewrite+0xf6>
    80004d1e:	8ba6                	mv	s7,s1
  int i = 0;
    80004d20:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d22:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d24:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d28:	21c48c13          	addi	s8,s1,540
    80004d2c:	a08d                	j	80004d8e <pipewrite+0xa8>
      release(&pi->lock);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	f68080e7          	jalr	-152(ra) # 80000c98 <release>
      return -1;
    80004d38:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d3a:	854a                	mv	a0,s2
    80004d3c:	70a6                	ld	ra,104(sp)
    80004d3e:	7406                	ld	s0,96(sp)
    80004d40:	64e6                	ld	s1,88(sp)
    80004d42:	6946                	ld	s2,80(sp)
    80004d44:	69a6                	ld	s3,72(sp)
    80004d46:	6a06                	ld	s4,64(sp)
    80004d48:	7ae2                	ld	s5,56(sp)
    80004d4a:	7b42                	ld	s6,48(sp)
    80004d4c:	7ba2                	ld	s7,40(sp)
    80004d4e:	7c02                	ld	s8,32(sp)
    80004d50:	6ce2                	ld	s9,24(sp)
    80004d52:	6165                	addi	sp,sp,112
    80004d54:	8082                	ret
      wakeup(&pi->nread);
    80004d56:	8566                	mv	a0,s9
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	666080e7          	jalr	1638(ra) # 800023be <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d60:	85de                	mv	a1,s7
    80004d62:	8562                	mv	a0,s8
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	382080e7          	jalr	898(ra) # 800020e6 <sleep>
    80004d6c:	a839                	j	80004d8a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d6e:	21c4a783          	lw	a5,540(s1)
    80004d72:	0017871b          	addiw	a4,a5,1
    80004d76:	20e4ae23          	sw	a4,540(s1)
    80004d7a:	1ff7f793          	andi	a5,a5,511
    80004d7e:	97a6                	add	a5,a5,s1
    80004d80:	f9f44703          	lbu	a4,-97(s0)
    80004d84:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d88:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d8a:	03495d63          	bge	s2,s4,80004dc4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d8e:	2204a783          	lw	a5,544(s1)
    80004d92:	dfd1                	beqz	a5,80004d2e <pipewrite+0x48>
    80004d94:	0289a783          	lw	a5,40(s3)
    80004d98:	fbd9                	bnez	a5,80004d2e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d9a:	2184a783          	lw	a5,536(s1)
    80004d9e:	21c4a703          	lw	a4,540(s1)
    80004da2:	2007879b          	addiw	a5,a5,512
    80004da6:	faf708e3          	beq	a4,a5,80004d56 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004daa:	4685                	li	a3,1
    80004dac:	01590633          	add	a2,s2,s5
    80004db0:	f9f40593          	addi	a1,s0,-97
    80004db4:	0509b503          	ld	a0,80(s3)
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	946080e7          	jalr	-1722(ra) # 800016fe <copyin>
    80004dc0:	fb6517e3          	bne	a0,s6,80004d6e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004dc4:	21848513          	addi	a0,s1,536
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	5f6080e7          	jalr	1526(ra) # 800023be <wakeup>
  release(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	ec6080e7          	jalr	-314(ra) # 80000c98 <release>
  return i;
    80004dda:	b785                	j	80004d3a <pipewrite+0x54>
  int i = 0;
    80004ddc:	4901                	li	s2,0
    80004dde:	b7dd                	j	80004dc4 <pipewrite+0xde>

0000000080004de0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004de0:	715d                	addi	sp,sp,-80
    80004de2:	e486                	sd	ra,72(sp)
    80004de4:	e0a2                	sd	s0,64(sp)
    80004de6:	fc26                	sd	s1,56(sp)
    80004de8:	f84a                	sd	s2,48(sp)
    80004dea:	f44e                	sd	s3,40(sp)
    80004dec:	f052                	sd	s4,32(sp)
    80004dee:	ec56                	sd	s5,24(sp)
    80004df0:	e85a                	sd	s6,16(sp)
    80004df2:	0880                	addi	s0,sp,80
    80004df4:	84aa                	mv	s1,a0
    80004df6:	892e                	mv	s2,a1
    80004df8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	bb6080e7          	jalr	-1098(ra) # 800019b0 <myproc>
    80004e02:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e04:	8b26                	mv	s6,s1
    80004e06:	8526                	mv	a0,s1
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	ddc080e7          	jalr	-548(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e10:	2184a703          	lw	a4,536(s1)
    80004e14:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e18:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1c:	02f71463          	bne	a4,a5,80004e44 <piperead+0x64>
    80004e20:	2244a783          	lw	a5,548(s1)
    80004e24:	c385                	beqz	a5,80004e44 <piperead+0x64>
    if(pr->killed){
    80004e26:	028a2783          	lw	a5,40(s4)
    80004e2a:	ebc1                	bnez	a5,80004eba <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e2c:	85da                	mv	a1,s6
    80004e2e:	854e                	mv	a0,s3
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	2b6080e7          	jalr	694(ra) # 800020e6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e38:	2184a703          	lw	a4,536(s1)
    80004e3c:	21c4a783          	lw	a5,540(s1)
    80004e40:	fef700e3          	beq	a4,a5,80004e20 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e44:	09505263          	blez	s5,80004ec8 <piperead+0xe8>
    80004e48:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e4c:	2184a783          	lw	a5,536(s1)
    80004e50:	21c4a703          	lw	a4,540(s1)
    80004e54:	02f70d63          	beq	a4,a5,80004e8e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e58:	0017871b          	addiw	a4,a5,1
    80004e5c:	20e4ac23          	sw	a4,536(s1)
    80004e60:	1ff7f793          	andi	a5,a5,511
    80004e64:	97a6                	add	a5,a5,s1
    80004e66:	0187c783          	lbu	a5,24(a5)
    80004e6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e6e:	4685                	li	a3,1
    80004e70:	fbf40613          	addi	a2,s0,-65
    80004e74:	85ca                	mv	a1,s2
    80004e76:	050a3503          	ld	a0,80(s4)
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	7f8080e7          	jalr	2040(ra) # 80001672 <copyout>
    80004e82:	01650663          	beq	a0,s6,80004e8e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e86:	2985                	addiw	s3,s3,1
    80004e88:	0905                	addi	s2,s2,1
    80004e8a:	fd3a91e3          	bne	s5,s3,80004e4c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e8e:	21c48513          	addi	a0,s1,540
    80004e92:	ffffd097          	auipc	ra,0xffffd
    80004e96:	52c080e7          	jalr	1324(ra) # 800023be <wakeup>
  release(&pi->lock);
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
  return i;
}
    80004ea4:	854e                	mv	a0,s3
    80004ea6:	60a6                	ld	ra,72(sp)
    80004ea8:	6406                	ld	s0,64(sp)
    80004eaa:	74e2                	ld	s1,56(sp)
    80004eac:	7942                	ld	s2,48(sp)
    80004eae:	79a2                	ld	s3,40(sp)
    80004eb0:	7a02                	ld	s4,32(sp)
    80004eb2:	6ae2                	ld	s5,24(sp)
    80004eb4:	6b42                	ld	s6,16(sp)
    80004eb6:	6161                	addi	sp,sp,80
    80004eb8:	8082                	ret
      release(&pi->lock);
    80004eba:	8526                	mv	a0,s1
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	ddc080e7          	jalr	-548(ra) # 80000c98 <release>
      return -1;
    80004ec4:	59fd                	li	s3,-1
    80004ec6:	bff9                	j	80004ea4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec8:	4981                	li	s3,0
    80004eca:	b7d1                	j	80004e8e <piperead+0xae>

0000000080004ecc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ecc:	df010113          	addi	sp,sp,-528
    80004ed0:	20113423          	sd	ra,520(sp)
    80004ed4:	20813023          	sd	s0,512(sp)
    80004ed8:	ffa6                	sd	s1,504(sp)
    80004eda:	fbca                	sd	s2,496(sp)
    80004edc:	f7ce                	sd	s3,488(sp)
    80004ede:	f3d2                	sd	s4,480(sp)
    80004ee0:	efd6                	sd	s5,472(sp)
    80004ee2:	ebda                	sd	s6,464(sp)
    80004ee4:	e7de                	sd	s7,456(sp)
    80004ee6:	e3e2                	sd	s8,448(sp)
    80004ee8:	ff66                	sd	s9,440(sp)
    80004eea:	fb6a                	sd	s10,432(sp)
    80004eec:	f76e                	sd	s11,424(sp)
    80004eee:	0c00                	addi	s0,sp,528
    80004ef0:	84aa                	mv	s1,a0
    80004ef2:	dea43c23          	sd	a0,-520(s0)
    80004ef6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	ab6080e7          	jalr	-1354(ra) # 800019b0 <myproc>
    80004f02:	892a                	mv	s2,a0

  begin_op();
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	49c080e7          	jalr	1180(ra) # 800043a0 <begin_op>

  if((ip = namei(path)) == 0){
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	276080e7          	jalr	630(ra) # 80004184 <namei>
    80004f16:	c92d                	beqz	a0,80004f88 <exec+0xbc>
    80004f18:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	ab4080e7          	jalr	-1356(ra) # 800039ce <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f22:	04000713          	li	a4,64
    80004f26:	4681                	li	a3,0
    80004f28:	e5040613          	addi	a2,s0,-432
    80004f2c:	4581                	li	a1,0
    80004f2e:	8526                	mv	a0,s1
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	d52080e7          	jalr	-686(ra) # 80003c82 <readi>
    80004f38:	04000793          	li	a5,64
    80004f3c:	00f51a63          	bne	a0,a5,80004f50 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f40:	e5042703          	lw	a4,-432(s0)
    80004f44:	464c47b7          	lui	a5,0x464c4
    80004f48:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f4c:	04f70463          	beq	a4,a5,80004f94 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f50:	8526                	mv	a0,s1
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	cde080e7          	jalr	-802(ra) # 80003c30 <iunlockput>
    end_op();
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	4c6080e7          	jalr	1222(ra) # 80004420 <end_op>
  }
  return -1;
    80004f62:	557d                	li	a0,-1
}
    80004f64:	20813083          	ld	ra,520(sp)
    80004f68:	20013403          	ld	s0,512(sp)
    80004f6c:	74fe                	ld	s1,504(sp)
    80004f6e:	795e                	ld	s2,496(sp)
    80004f70:	79be                	ld	s3,488(sp)
    80004f72:	7a1e                	ld	s4,480(sp)
    80004f74:	6afe                	ld	s5,472(sp)
    80004f76:	6b5e                	ld	s6,464(sp)
    80004f78:	6bbe                	ld	s7,456(sp)
    80004f7a:	6c1e                	ld	s8,448(sp)
    80004f7c:	7cfa                	ld	s9,440(sp)
    80004f7e:	7d5a                	ld	s10,432(sp)
    80004f80:	7dba                	ld	s11,424(sp)
    80004f82:	21010113          	addi	sp,sp,528
    80004f86:	8082                	ret
    end_op();
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	498080e7          	jalr	1176(ra) # 80004420 <end_op>
    return -1;
    80004f90:	557d                	li	a0,-1
    80004f92:	bfc9                	j	80004f64 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f94:	854a                	mv	a0,s2
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	ade080e7          	jalr	-1314(ra) # 80001a74 <proc_pagetable>
    80004f9e:	8baa                	mv	s7,a0
    80004fa0:	d945                	beqz	a0,80004f50 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa2:	e7042983          	lw	s3,-400(s0)
    80004fa6:	e8845783          	lhu	a5,-376(s0)
    80004faa:	c7ad                	beqz	a5,80005014 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fac:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fae:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004fb0:	6c85                	lui	s9,0x1
    80004fb2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fb6:	def43823          	sd	a5,-528(s0)
    80004fba:	a42d                	j	800051e4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fbc:	00003517          	auipc	a0,0x3
    80004fc0:	7ec50513          	addi	a0,a0,2028 # 800087a8 <syscalls+0x288>
    80004fc4:	ffffb097          	auipc	ra,0xffffb
    80004fc8:	57a080e7          	jalr	1402(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fcc:	8756                	mv	a4,s5
    80004fce:	012d86bb          	addw	a3,s11,s2
    80004fd2:	4581                	li	a1,0
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	cac080e7          	jalr	-852(ra) # 80003c82 <readi>
    80004fde:	2501                	sext.w	a0,a0
    80004fe0:	1aaa9963          	bne	s5,a0,80005192 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fe4:	6785                	lui	a5,0x1
    80004fe6:	0127893b          	addw	s2,a5,s2
    80004fea:	77fd                	lui	a5,0xfffff
    80004fec:	01478a3b          	addw	s4,a5,s4
    80004ff0:	1f897163          	bgeu	s2,s8,800051d2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ff4:	02091593          	slli	a1,s2,0x20
    80004ff8:	9181                	srli	a1,a1,0x20
    80004ffa:	95ea                	add	a1,a1,s10
    80004ffc:	855e                	mv	a0,s7
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	070080e7          	jalr	112(ra) # 8000106e <walkaddr>
    80005006:	862a                	mv	a2,a0
    if(pa == 0)
    80005008:	d955                	beqz	a0,80004fbc <exec+0xf0>
      n = PGSIZE;
    8000500a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000500c:	fd9a70e3          	bgeu	s4,s9,80004fcc <exec+0x100>
      n = sz - i;
    80005010:	8ad2                	mv	s5,s4
    80005012:	bf6d                	j	80004fcc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005014:	4901                	li	s2,0
  iunlockput(ip);
    80005016:	8526                	mv	a0,s1
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	c18080e7          	jalr	-1000(ra) # 80003c30 <iunlockput>
  end_op();
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	400080e7          	jalr	1024(ra) # 80004420 <end_op>
  p = myproc();
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	988080e7          	jalr	-1656(ra) # 800019b0 <myproc>
    80005030:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005032:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005036:	6785                	lui	a5,0x1
    80005038:	17fd                	addi	a5,a5,-1
    8000503a:	993e                	add	s2,s2,a5
    8000503c:	757d                	lui	a0,0xfffff
    8000503e:	00a977b3          	and	a5,s2,a0
    80005042:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005046:	6609                	lui	a2,0x2
    80005048:	963e                	add	a2,a2,a5
    8000504a:	85be                	mv	a1,a5
    8000504c:	855e                	mv	a0,s7
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	3d4080e7          	jalr	980(ra) # 80001422 <uvmalloc>
    80005056:	8b2a                	mv	s6,a0
  ip = 0;
    80005058:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000505a:	12050c63          	beqz	a0,80005192 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000505e:	75f9                	lui	a1,0xffffe
    80005060:	95aa                	add	a1,a1,a0
    80005062:	855e                	mv	a0,s7
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	5dc080e7          	jalr	1500(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000506c:	7c7d                	lui	s8,0xfffff
    8000506e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005070:	e0043783          	ld	a5,-512(s0)
    80005074:	6388                	ld	a0,0(a5)
    80005076:	c535                	beqz	a0,800050e2 <exec+0x216>
    80005078:	e9040993          	addi	s3,s0,-368
    8000507c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005080:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	de2080e7          	jalr	-542(ra) # 80000e64 <strlen>
    8000508a:	2505                	addiw	a0,a0,1
    8000508c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005090:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005094:	13896363          	bltu	s2,s8,800051ba <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005098:	e0043d83          	ld	s11,-512(s0)
    8000509c:	000dba03          	ld	s4,0(s11)
    800050a0:	8552                	mv	a0,s4
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	dc2080e7          	jalr	-574(ra) # 80000e64 <strlen>
    800050aa:	0015069b          	addiw	a3,a0,1
    800050ae:	8652                	mv	a2,s4
    800050b0:	85ca                	mv	a1,s2
    800050b2:	855e                	mv	a0,s7
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	5be080e7          	jalr	1470(ra) # 80001672 <copyout>
    800050bc:	10054363          	bltz	a0,800051c2 <exec+0x2f6>
    ustack[argc] = sp;
    800050c0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050c4:	0485                	addi	s1,s1,1
    800050c6:	008d8793          	addi	a5,s11,8
    800050ca:	e0f43023          	sd	a5,-512(s0)
    800050ce:	008db503          	ld	a0,8(s11)
    800050d2:	c911                	beqz	a0,800050e6 <exec+0x21a>
    if(argc >= MAXARG)
    800050d4:	09a1                	addi	s3,s3,8
    800050d6:	fb3c96e3          	bne	s9,s3,80005082 <exec+0x1b6>
  sz = sz1;
    800050da:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050de:	4481                	li	s1,0
    800050e0:	a84d                	j	80005192 <exec+0x2c6>
  sp = sz;
    800050e2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050e4:	4481                	li	s1,0
  ustack[argc] = 0;
    800050e6:	00349793          	slli	a5,s1,0x3
    800050ea:	f9040713          	addi	a4,s0,-112
    800050ee:	97ba                	add	a5,a5,a4
    800050f0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050f4:	00148693          	addi	a3,s1,1
    800050f8:	068e                	slli	a3,a3,0x3
    800050fa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050fe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005102:	01897663          	bgeu	s2,s8,8000510e <exec+0x242>
  sz = sz1;
    80005106:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000510a:	4481                	li	s1,0
    8000510c:	a059                	j	80005192 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000510e:	e9040613          	addi	a2,s0,-368
    80005112:	85ca                	mv	a1,s2
    80005114:	855e                	mv	a0,s7
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	55c080e7          	jalr	1372(ra) # 80001672 <copyout>
    8000511e:	0a054663          	bltz	a0,800051ca <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005122:	058ab783          	ld	a5,88(s5)
    80005126:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000512a:	df843783          	ld	a5,-520(s0)
    8000512e:	0007c703          	lbu	a4,0(a5)
    80005132:	cf11                	beqz	a4,8000514e <exec+0x282>
    80005134:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005136:	02f00693          	li	a3,47
    8000513a:	a039                	j	80005148 <exec+0x27c>
      last = s+1;
    8000513c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005140:	0785                	addi	a5,a5,1
    80005142:	fff7c703          	lbu	a4,-1(a5)
    80005146:	c701                	beqz	a4,8000514e <exec+0x282>
    if(*s == '/')
    80005148:	fed71ce3          	bne	a4,a3,80005140 <exec+0x274>
    8000514c:	bfc5                	j	8000513c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000514e:	4641                	li	a2,16
    80005150:	df843583          	ld	a1,-520(s0)
    80005154:	158a8513          	addi	a0,s5,344
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	cda080e7          	jalr	-806(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005160:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005164:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005168:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000516c:	058ab783          	ld	a5,88(s5)
    80005170:	e6843703          	ld	a4,-408(s0)
    80005174:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005176:	058ab783          	ld	a5,88(s5)
    8000517a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000517e:	85ea                	mv	a1,s10
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	990080e7          	jalr	-1648(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005188:	0004851b          	sext.w	a0,s1
    8000518c:	bbe1                	j	80004f64 <exec+0x98>
    8000518e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005192:	e0843583          	ld	a1,-504(s0)
    80005196:	855e                	mv	a0,s7
    80005198:	ffffd097          	auipc	ra,0xffffd
    8000519c:	978080e7          	jalr	-1672(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800051a0:	da0498e3          	bnez	s1,80004f50 <exec+0x84>
  return -1;
    800051a4:	557d                	li	a0,-1
    800051a6:	bb7d                	j	80004f64 <exec+0x98>
    800051a8:	e1243423          	sd	s2,-504(s0)
    800051ac:	b7dd                	j	80005192 <exec+0x2c6>
    800051ae:	e1243423          	sd	s2,-504(s0)
    800051b2:	b7c5                	j	80005192 <exec+0x2c6>
    800051b4:	e1243423          	sd	s2,-504(s0)
    800051b8:	bfe9                	j	80005192 <exec+0x2c6>
  sz = sz1;
    800051ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051be:	4481                	li	s1,0
    800051c0:	bfc9                	j	80005192 <exec+0x2c6>
  sz = sz1;
    800051c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c6:	4481                	li	s1,0
    800051c8:	b7e9                	j	80005192 <exec+0x2c6>
  sz = sz1;
    800051ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051ce:	4481                	li	s1,0
    800051d0:	b7c9                	j	80005192 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051d2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d6:	2b05                	addiw	s6,s6,1
    800051d8:	0389899b          	addiw	s3,s3,56
    800051dc:	e8845783          	lhu	a5,-376(s0)
    800051e0:	e2fb5be3          	bge	s6,a5,80005016 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051e4:	2981                	sext.w	s3,s3
    800051e6:	03800713          	li	a4,56
    800051ea:	86ce                	mv	a3,s3
    800051ec:	e1840613          	addi	a2,s0,-488
    800051f0:	4581                	li	a1,0
    800051f2:	8526                	mv	a0,s1
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	a8e080e7          	jalr	-1394(ra) # 80003c82 <readi>
    800051fc:	03800793          	li	a5,56
    80005200:	f8f517e3          	bne	a0,a5,8000518e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005204:	e1842783          	lw	a5,-488(s0)
    80005208:	4705                	li	a4,1
    8000520a:	fce796e3          	bne	a5,a4,800051d6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000520e:	e4043603          	ld	a2,-448(s0)
    80005212:	e3843783          	ld	a5,-456(s0)
    80005216:	f8f669e3          	bltu	a2,a5,800051a8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000521a:	e2843783          	ld	a5,-472(s0)
    8000521e:	963e                	add	a2,a2,a5
    80005220:	f8f667e3          	bltu	a2,a5,800051ae <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005224:	85ca                	mv	a1,s2
    80005226:	855e                	mv	a0,s7
    80005228:	ffffc097          	auipc	ra,0xffffc
    8000522c:	1fa080e7          	jalr	506(ra) # 80001422 <uvmalloc>
    80005230:	e0a43423          	sd	a0,-504(s0)
    80005234:	d141                	beqz	a0,800051b4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005236:	e2843d03          	ld	s10,-472(s0)
    8000523a:	df043783          	ld	a5,-528(s0)
    8000523e:	00fd77b3          	and	a5,s10,a5
    80005242:	fba1                	bnez	a5,80005192 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005244:	e2042d83          	lw	s11,-480(s0)
    80005248:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000524c:	f80c03e3          	beqz	s8,800051d2 <exec+0x306>
    80005250:	8a62                	mv	s4,s8
    80005252:	4901                	li	s2,0
    80005254:	b345                	j	80004ff4 <exec+0x128>

0000000080005256 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005256:	7179                	addi	sp,sp,-48
    80005258:	f406                	sd	ra,40(sp)
    8000525a:	f022                	sd	s0,32(sp)
    8000525c:	ec26                	sd	s1,24(sp)
    8000525e:	e84a                	sd	s2,16(sp)
    80005260:	1800                	addi	s0,sp,48
    80005262:	892e                	mv	s2,a1
    80005264:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005266:	fdc40593          	addi	a1,s0,-36
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	9f4080e7          	jalr	-1548(ra) # 80002c5e <argint>
    80005272:	04054063          	bltz	a0,800052b2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005276:	fdc42703          	lw	a4,-36(s0)
    8000527a:	47bd                	li	a5,15
    8000527c:	02e7ed63          	bltu	a5,a4,800052b6 <argfd+0x60>
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	730080e7          	jalr	1840(ra) # 800019b0 <myproc>
    80005288:	fdc42703          	lw	a4,-36(s0)
    8000528c:	01a70793          	addi	a5,a4,26
    80005290:	078e                	slli	a5,a5,0x3
    80005292:	953e                	add	a0,a0,a5
    80005294:	611c                	ld	a5,0(a0)
    80005296:	c395                	beqz	a5,800052ba <argfd+0x64>
    return -1;
  if(pfd)
    80005298:	00090463          	beqz	s2,800052a0 <argfd+0x4a>
    *pfd = fd;
    8000529c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052a0:	4501                	li	a0,0
  if(pf)
    800052a2:	c091                	beqz	s1,800052a6 <argfd+0x50>
    *pf = f;
    800052a4:	e09c                	sd	a5,0(s1)
}
    800052a6:	70a2                	ld	ra,40(sp)
    800052a8:	7402                	ld	s0,32(sp)
    800052aa:	64e2                	ld	s1,24(sp)
    800052ac:	6942                	ld	s2,16(sp)
    800052ae:	6145                	addi	sp,sp,48
    800052b0:	8082                	ret
    return -1;
    800052b2:	557d                	li	a0,-1
    800052b4:	bfcd                	j	800052a6 <argfd+0x50>
    return -1;
    800052b6:	557d                	li	a0,-1
    800052b8:	b7fd                	j	800052a6 <argfd+0x50>
    800052ba:	557d                	li	a0,-1
    800052bc:	b7ed                	j	800052a6 <argfd+0x50>

00000000800052be <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052be:	1101                	addi	sp,sp,-32
    800052c0:	ec06                	sd	ra,24(sp)
    800052c2:	e822                	sd	s0,16(sp)
    800052c4:	e426                	sd	s1,8(sp)
    800052c6:	1000                	addi	s0,sp,32
    800052c8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	6e6080e7          	jalr	1766(ra) # 800019b0 <myproc>
    800052d2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052d4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800052d8:	4501                	li	a0,0
    800052da:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052dc:	6398                	ld	a4,0(a5)
    800052de:	cb19                	beqz	a4,800052f4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052e0:	2505                	addiw	a0,a0,1
    800052e2:	07a1                	addi	a5,a5,8
    800052e4:	fed51ce3          	bne	a0,a3,800052dc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052e8:	557d                	li	a0,-1
}
    800052ea:	60e2                	ld	ra,24(sp)
    800052ec:	6442                	ld	s0,16(sp)
    800052ee:	64a2                	ld	s1,8(sp)
    800052f0:	6105                	addi	sp,sp,32
    800052f2:	8082                	ret
      p->ofile[fd] = f;
    800052f4:	01a50793          	addi	a5,a0,26
    800052f8:	078e                	slli	a5,a5,0x3
    800052fa:	963e                	add	a2,a2,a5
    800052fc:	e204                	sd	s1,0(a2)
      return fd;
    800052fe:	b7f5                	j	800052ea <fdalloc+0x2c>

0000000080005300 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005300:	715d                	addi	sp,sp,-80
    80005302:	e486                	sd	ra,72(sp)
    80005304:	e0a2                	sd	s0,64(sp)
    80005306:	fc26                	sd	s1,56(sp)
    80005308:	f84a                	sd	s2,48(sp)
    8000530a:	f44e                	sd	s3,40(sp)
    8000530c:	f052                	sd	s4,32(sp)
    8000530e:	ec56                	sd	s5,24(sp)
    80005310:	0880                	addi	s0,sp,80
    80005312:	89ae                	mv	s3,a1
    80005314:	8ab2                	mv	s5,a2
    80005316:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005318:	fb040593          	addi	a1,s0,-80
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	e86080e7          	jalr	-378(ra) # 800041a2 <nameiparent>
    80005324:	892a                	mv	s2,a0
    80005326:	12050f63          	beqz	a0,80005464 <create+0x164>
    return 0;

  ilock(dp);
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	6a4080e7          	jalr	1700(ra) # 800039ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005332:	4601                	li	a2,0
    80005334:	fb040593          	addi	a1,s0,-80
    80005338:	854a                	mv	a0,s2
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	b78080e7          	jalr	-1160(ra) # 80003eb2 <dirlookup>
    80005342:	84aa                	mv	s1,a0
    80005344:	c921                	beqz	a0,80005394 <create+0x94>
    iunlockput(dp);
    80005346:	854a                	mv	a0,s2
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	8e8080e7          	jalr	-1816(ra) # 80003c30 <iunlockput>
    ilock(ip);
    80005350:	8526                	mv	a0,s1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	67c080e7          	jalr	1660(ra) # 800039ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000535a:	2981                	sext.w	s3,s3
    8000535c:	4789                	li	a5,2
    8000535e:	02f99463          	bne	s3,a5,80005386 <create+0x86>
    80005362:	0444d783          	lhu	a5,68(s1)
    80005366:	37f9                	addiw	a5,a5,-2
    80005368:	17c2                	slli	a5,a5,0x30
    8000536a:	93c1                	srli	a5,a5,0x30
    8000536c:	4705                	li	a4,1
    8000536e:	00f76c63          	bltu	a4,a5,80005386 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005372:	8526                	mv	a0,s1
    80005374:	60a6                	ld	ra,72(sp)
    80005376:	6406                	ld	s0,64(sp)
    80005378:	74e2                	ld	s1,56(sp)
    8000537a:	7942                	ld	s2,48(sp)
    8000537c:	79a2                	ld	s3,40(sp)
    8000537e:	7a02                	ld	s4,32(sp)
    80005380:	6ae2                	ld	s5,24(sp)
    80005382:	6161                	addi	sp,sp,80
    80005384:	8082                	ret
    iunlockput(ip);
    80005386:	8526                	mv	a0,s1
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	8a8080e7          	jalr	-1880(ra) # 80003c30 <iunlockput>
    return 0;
    80005390:	4481                	li	s1,0
    80005392:	b7c5                	j	80005372 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005394:	85ce                	mv	a1,s3
    80005396:	00092503          	lw	a0,0(s2)
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	49c080e7          	jalr	1180(ra) # 80003836 <ialloc>
    800053a2:	84aa                	mv	s1,a0
    800053a4:	c529                	beqz	a0,800053ee <create+0xee>
  ilock(ip);
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	628080e7          	jalr	1576(ra) # 800039ce <ilock>
  ip->major = major;
    800053ae:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053b2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053b6:	4785                	li	a5,1
    800053b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	546080e7          	jalr	1350(ra) # 80003904 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053c6:	2981                	sext.w	s3,s3
    800053c8:	4785                	li	a5,1
    800053ca:	02f98a63          	beq	s3,a5,800053fe <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053ce:	40d0                	lw	a2,4(s1)
    800053d0:	fb040593          	addi	a1,s0,-80
    800053d4:	854a                	mv	a0,s2
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	cec080e7          	jalr	-788(ra) # 800040c2 <dirlink>
    800053de:	06054b63          	bltz	a0,80005454 <create+0x154>
  iunlockput(dp);
    800053e2:	854a                	mv	a0,s2
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	84c080e7          	jalr	-1972(ra) # 80003c30 <iunlockput>
  return ip;
    800053ec:	b759                	j	80005372 <create+0x72>
    panic("create: ialloc");
    800053ee:	00003517          	auipc	a0,0x3
    800053f2:	3da50513          	addi	a0,a0,986 # 800087c8 <syscalls+0x2a8>
    800053f6:	ffffb097          	auipc	ra,0xffffb
    800053fa:	148080e7          	jalr	328(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053fe:	04a95783          	lhu	a5,74(s2)
    80005402:	2785                	addiw	a5,a5,1
    80005404:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005408:	854a                	mv	a0,s2
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	4fa080e7          	jalr	1274(ra) # 80003904 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005412:	40d0                	lw	a2,4(s1)
    80005414:	00003597          	auipc	a1,0x3
    80005418:	3c458593          	addi	a1,a1,964 # 800087d8 <syscalls+0x2b8>
    8000541c:	8526                	mv	a0,s1
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	ca4080e7          	jalr	-860(ra) # 800040c2 <dirlink>
    80005426:	00054f63          	bltz	a0,80005444 <create+0x144>
    8000542a:	00492603          	lw	a2,4(s2)
    8000542e:	00003597          	auipc	a1,0x3
    80005432:	3b258593          	addi	a1,a1,946 # 800087e0 <syscalls+0x2c0>
    80005436:	8526                	mv	a0,s1
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	c8a080e7          	jalr	-886(ra) # 800040c2 <dirlink>
    80005440:	f80557e3          	bgez	a0,800053ce <create+0xce>
      panic("create dots");
    80005444:	00003517          	auipc	a0,0x3
    80005448:	3a450513          	addi	a0,a0,932 # 800087e8 <syscalls+0x2c8>
    8000544c:	ffffb097          	auipc	ra,0xffffb
    80005450:	0f2080e7          	jalr	242(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005454:	00003517          	auipc	a0,0x3
    80005458:	3a450513          	addi	a0,a0,932 # 800087f8 <syscalls+0x2d8>
    8000545c:	ffffb097          	auipc	ra,0xffffb
    80005460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>
    return 0;
    80005464:	84aa                	mv	s1,a0
    80005466:	b731                	j	80005372 <create+0x72>

0000000080005468 <sys_dup>:
{
    80005468:	7179                	addi	sp,sp,-48
    8000546a:	f406                	sd	ra,40(sp)
    8000546c:	f022                	sd	s0,32(sp)
    8000546e:	ec26                	sd	s1,24(sp)
    80005470:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005472:	fd840613          	addi	a2,s0,-40
    80005476:	4581                	li	a1,0
    80005478:	4501                	li	a0,0
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	ddc080e7          	jalr	-548(ra) # 80005256 <argfd>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005484:	02054363          	bltz	a0,800054aa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005488:	fd843503          	ld	a0,-40(s0)
    8000548c:	00000097          	auipc	ra,0x0
    80005490:	e32080e7          	jalr	-462(ra) # 800052be <fdalloc>
    80005494:	84aa                	mv	s1,a0
    return -1;
    80005496:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005498:	00054963          	bltz	a0,800054aa <sys_dup+0x42>
  filedup(f);
    8000549c:	fd843503          	ld	a0,-40(s0)
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	37a080e7          	jalr	890(ra) # 8000481a <filedup>
  return fd;
    800054a8:	87a6                	mv	a5,s1
}
    800054aa:	853e                	mv	a0,a5
    800054ac:	70a2                	ld	ra,40(sp)
    800054ae:	7402                	ld	s0,32(sp)
    800054b0:	64e2                	ld	s1,24(sp)
    800054b2:	6145                	addi	sp,sp,48
    800054b4:	8082                	ret

00000000800054b6 <sys_read>:
{
    800054b6:	7179                	addi	sp,sp,-48
    800054b8:	f406                	sd	ra,40(sp)
    800054ba:	f022                	sd	s0,32(sp)
    800054bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054be:	fe840613          	addi	a2,s0,-24
    800054c2:	4581                	li	a1,0
    800054c4:	4501                	li	a0,0
    800054c6:	00000097          	auipc	ra,0x0
    800054ca:	d90080e7          	jalr	-624(ra) # 80005256 <argfd>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d0:	04054163          	bltz	a0,80005512 <sys_read+0x5c>
    800054d4:	fe440593          	addi	a1,s0,-28
    800054d8:	4509                	li	a0,2
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	784080e7          	jalr	1924(ra) # 80002c5e <argint>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	02054763          	bltz	a0,80005512 <sys_read+0x5c>
    800054e8:	fd840593          	addi	a1,s0,-40
    800054ec:	4505                	li	a0,1
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	792080e7          	jalr	1938(ra) # 80002c80 <argaddr>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f8:	00054d63          	bltz	a0,80005512 <sys_read+0x5c>
  return fileread(f, p, n);
    800054fc:	fe442603          	lw	a2,-28(s0)
    80005500:	fd843583          	ld	a1,-40(s0)
    80005504:	fe843503          	ld	a0,-24(s0)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	49e080e7          	jalr	1182(ra) # 800049a6 <fileread>
    80005510:	87aa                	mv	a5,a0
}
    80005512:	853e                	mv	a0,a5
    80005514:	70a2                	ld	ra,40(sp)
    80005516:	7402                	ld	s0,32(sp)
    80005518:	6145                	addi	sp,sp,48
    8000551a:	8082                	ret

000000008000551c <sys_write>:
{
    8000551c:	7179                	addi	sp,sp,-48
    8000551e:	f406                	sd	ra,40(sp)
    80005520:	f022                	sd	s0,32(sp)
    80005522:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005524:	fe840613          	addi	a2,s0,-24
    80005528:	4581                	li	a1,0
    8000552a:	4501                	li	a0,0
    8000552c:	00000097          	auipc	ra,0x0
    80005530:	d2a080e7          	jalr	-726(ra) # 80005256 <argfd>
    return -1;
    80005534:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005536:	04054163          	bltz	a0,80005578 <sys_write+0x5c>
    8000553a:	fe440593          	addi	a1,s0,-28
    8000553e:	4509                	li	a0,2
    80005540:	ffffd097          	auipc	ra,0xffffd
    80005544:	71e080e7          	jalr	1822(ra) # 80002c5e <argint>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554a:	02054763          	bltz	a0,80005578 <sys_write+0x5c>
    8000554e:	fd840593          	addi	a1,s0,-40
    80005552:	4505                	li	a0,1
    80005554:	ffffd097          	auipc	ra,0xffffd
    80005558:	72c080e7          	jalr	1836(ra) # 80002c80 <argaddr>
    return -1;
    8000555c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000555e:	00054d63          	bltz	a0,80005578 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005562:	fe442603          	lw	a2,-28(s0)
    80005566:	fd843583          	ld	a1,-40(s0)
    8000556a:	fe843503          	ld	a0,-24(s0)
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	4fa080e7          	jalr	1274(ra) # 80004a68 <filewrite>
    80005576:	87aa                	mv	a5,a0
}
    80005578:	853e                	mv	a0,a5
    8000557a:	70a2                	ld	ra,40(sp)
    8000557c:	7402                	ld	s0,32(sp)
    8000557e:	6145                	addi	sp,sp,48
    80005580:	8082                	ret

0000000080005582 <sys_close>:
{
    80005582:	1101                	addi	sp,sp,-32
    80005584:	ec06                	sd	ra,24(sp)
    80005586:	e822                	sd	s0,16(sp)
    80005588:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000558a:	fe040613          	addi	a2,s0,-32
    8000558e:	fec40593          	addi	a1,s0,-20
    80005592:	4501                	li	a0,0
    80005594:	00000097          	auipc	ra,0x0
    80005598:	cc2080e7          	jalr	-830(ra) # 80005256 <argfd>
    return -1;
    8000559c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000559e:	02054463          	bltz	a0,800055c6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	40e080e7          	jalr	1038(ra) # 800019b0 <myproc>
    800055aa:	fec42783          	lw	a5,-20(s0)
    800055ae:	07e9                	addi	a5,a5,26
    800055b0:	078e                	slli	a5,a5,0x3
    800055b2:	97aa                	add	a5,a5,a0
    800055b4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055b8:	fe043503          	ld	a0,-32(s0)
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	2b0080e7          	jalr	688(ra) # 8000486c <fileclose>
  return 0;
    800055c4:	4781                	li	a5,0
}
    800055c6:	853e                	mv	a0,a5
    800055c8:	60e2                	ld	ra,24(sp)
    800055ca:	6442                	ld	s0,16(sp)
    800055cc:	6105                	addi	sp,sp,32
    800055ce:	8082                	ret

00000000800055d0 <sys_fstat>:
{
    800055d0:	1101                	addi	sp,sp,-32
    800055d2:	ec06                	sd	ra,24(sp)
    800055d4:	e822                	sd	s0,16(sp)
    800055d6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d8:	fe840613          	addi	a2,s0,-24
    800055dc:	4581                	li	a1,0
    800055de:	4501                	li	a0,0
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	c76080e7          	jalr	-906(ra) # 80005256 <argfd>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ea:	02054563          	bltz	a0,80005614 <sys_fstat+0x44>
    800055ee:	fe040593          	addi	a1,s0,-32
    800055f2:	4505                	li	a0,1
    800055f4:	ffffd097          	auipc	ra,0xffffd
    800055f8:	68c080e7          	jalr	1676(ra) # 80002c80 <argaddr>
    return -1;
    800055fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055fe:	00054b63          	bltz	a0,80005614 <sys_fstat+0x44>
  return filestat(f, st);
    80005602:	fe043583          	ld	a1,-32(s0)
    80005606:	fe843503          	ld	a0,-24(s0)
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	32a080e7          	jalr	810(ra) # 80004934 <filestat>
    80005612:	87aa                	mv	a5,a0
}
    80005614:	853e                	mv	a0,a5
    80005616:	60e2                	ld	ra,24(sp)
    80005618:	6442                	ld	s0,16(sp)
    8000561a:	6105                	addi	sp,sp,32
    8000561c:	8082                	ret

000000008000561e <sys_link>:
{
    8000561e:	7169                	addi	sp,sp,-304
    80005620:	f606                	sd	ra,296(sp)
    80005622:	f222                	sd	s0,288(sp)
    80005624:	ee26                	sd	s1,280(sp)
    80005626:	ea4a                	sd	s2,272(sp)
    80005628:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562a:	08000613          	li	a2,128
    8000562e:	ed040593          	addi	a1,s0,-304
    80005632:	4501                	li	a0,0
    80005634:	ffffd097          	auipc	ra,0xffffd
    80005638:	66e080e7          	jalr	1646(ra) # 80002ca2 <argstr>
    return -1;
    8000563c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000563e:	10054e63          	bltz	a0,8000575a <sys_link+0x13c>
    80005642:	08000613          	li	a2,128
    80005646:	f5040593          	addi	a1,s0,-176
    8000564a:	4505                	li	a0,1
    8000564c:	ffffd097          	auipc	ra,0xffffd
    80005650:	656080e7          	jalr	1622(ra) # 80002ca2 <argstr>
    return -1;
    80005654:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005656:	10054263          	bltz	a0,8000575a <sys_link+0x13c>
  begin_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	d46080e7          	jalr	-698(ra) # 800043a0 <begin_op>
  if((ip = namei(old)) == 0){
    80005662:	ed040513          	addi	a0,s0,-304
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	b1e080e7          	jalr	-1250(ra) # 80004184 <namei>
    8000566e:	84aa                	mv	s1,a0
    80005670:	c551                	beqz	a0,800056fc <sys_link+0xde>
  ilock(ip);
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	35c080e7          	jalr	860(ra) # 800039ce <ilock>
  if(ip->type == T_DIR){
    8000567a:	04449703          	lh	a4,68(s1)
    8000567e:	4785                	li	a5,1
    80005680:	08f70463          	beq	a4,a5,80005708 <sys_link+0xea>
  ip->nlink++;
    80005684:	04a4d783          	lhu	a5,74(s1)
    80005688:	2785                	addiw	a5,a5,1
    8000568a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	274080e7          	jalr	628(ra) # 80003904 <iupdate>
  iunlock(ip);
    80005698:	8526                	mv	a0,s1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	3f6080e7          	jalr	1014(ra) # 80003a90 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056a2:	fd040593          	addi	a1,s0,-48
    800056a6:	f5040513          	addi	a0,s0,-176
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	af8080e7          	jalr	-1288(ra) # 800041a2 <nameiparent>
    800056b2:	892a                	mv	s2,a0
    800056b4:	c935                	beqz	a0,80005728 <sys_link+0x10a>
  ilock(dp);
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	318080e7          	jalr	792(ra) # 800039ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056be:	00092703          	lw	a4,0(s2)
    800056c2:	409c                	lw	a5,0(s1)
    800056c4:	04f71d63          	bne	a4,a5,8000571e <sys_link+0x100>
    800056c8:	40d0                	lw	a2,4(s1)
    800056ca:	fd040593          	addi	a1,s0,-48
    800056ce:	854a                	mv	a0,s2
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	9f2080e7          	jalr	-1550(ra) # 800040c2 <dirlink>
    800056d8:	04054363          	bltz	a0,8000571e <sys_link+0x100>
  iunlockput(dp);
    800056dc:	854a                	mv	a0,s2
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	552080e7          	jalr	1362(ra) # 80003c30 <iunlockput>
  iput(ip);
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	4a0080e7          	jalr	1184(ra) # 80003b88 <iput>
  end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	d30080e7          	jalr	-720(ra) # 80004420 <end_op>
  return 0;
    800056f8:	4781                	li	a5,0
    800056fa:	a085                	j	8000575a <sys_link+0x13c>
    end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	d24080e7          	jalr	-732(ra) # 80004420 <end_op>
    return -1;
    80005704:	57fd                	li	a5,-1
    80005706:	a891                	j	8000575a <sys_link+0x13c>
    iunlockput(ip);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	526080e7          	jalr	1318(ra) # 80003c30 <iunlockput>
    end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	d0e080e7          	jalr	-754(ra) # 80004420 <end_op>
    return -1;
    8000571a:	57fd                	li	a5,-1
    8000571c:	a83d                	j	8000575a <sys_link+0x13c>
    iunlockput(dp);
    8000571e:	854a                	mv	a0,s2
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	510080e7          	jalr	1296(ra) # 80003c30 <iunlockput>
  ilock(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	2a4080e7          	jalr	676(ra) # 800039ce <ilock>
  ip->nlink--;
    80005732:	04a4d783          	lhu	a5,74(s1)
    80005736:	37fd                	addiw	a5,a5,-1
    80005738:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	1c6080e7          	jalr	454(ra) # 80003904 <iupdate>
  iunlockput(ip);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	4e8080e7          	jalr	1256(ra) # 80003c30 <iunlockput>
  end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	cd0080e7          	jalr	-816(ra) # 80004420 <end_op>
  return -1;
    80005758:	57fd                	li	a5,-1
}
    8000575a:	853e                	mv	a0,a5
    8000575c:	70b2                	ld	ra,296(sp)
    8000575e:	7412                	ld	s0,288(sp)
    80005760:	64f2                	ld	s1,280(sp)
    80005762:	6952                	ld	s2,272(sp)
    80005764:	6155                	addi	sp,sp,304
    80005766:	8082                	ret

0000000080005768 <sys_unlink>:
{
    80005768:	7151                	addi	sp,sp,-240
    8000576a:	f586                	sd	ra,232(sp)
    8000576c:	f1a2                	sd	s0,224(sp)
    8000576e:	eda6                	sd	s1,216(sp)
    80005770:	e9ca                	sd	s2,208(sp)
    80005772:	e5ce                	sd	s3,200(sp)
    80005774:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005776:	08000613          	li	a2,128
    8000577a:	f3040593          	addi	a1,s0,-208
    8000577e:	4501                	li	a0,0
    80005780:	ffffd097          	auipc	ra,0xffffd
    80005784:	522080e7          	jalr	1314(ra) # 80002ca2 <argstr>
    80005788:	18054163          	bltz	a0,8000590a <sys_unlink+0x1a2>
  begin_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	c14080e7          	jalr	-1004(ra) # 800043a0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005794:	fb040593          	addi	a1,s0,-80
    80005798:	f3040513          	addi	a0,s0,-208
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	a06080e7          	jalr	-1530(ra) # 800041a2 <nameiparent>
    800057a4:	84aa                	mv	s1,a0
    800057a6:	c979                	beqz	a0,8000587c <sys_unlink+0x114>
  ilock(dp);
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	226080e7          	jalr	550(ra) # 800039ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057b0:	00003597          	auipc	a1,0x3
    800057b4:	02858593          	addi	a1,a1,40 # 800087d8 <syscalls+0x2b8>
    800057b8:	fb040513          	addi	a0,s0,-80
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	6dc080e7          	jalr	1756(ra) # 80003e98 <namecmp>
    800057c4:	14050a63          	beqz	a0,80005918 <sys_unlink+0x1b0>
    800057c8:	00003597          	auipc	a1,0x3
    800057cc:	01858593          	addi	a1,a1,24 # 800087e0 <syscalls+0x2c0>
    800057d0:	fb040513          	addi	a0,s0,-80
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	6c4080e7          	jalr	1732(ra) # 80003e98 <namecmp>
    800057dc:	12050e63          	beqz	a0,80005918 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057e0:	f2c40613          	addi	a2,s0,-212
    800057e4:	fb040593          	addi	a1,s0,-80
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	6c8080e7          	jalr	1736(ra) # 80003eb2 <dirlookup>
    800057f2:	892a                	mv	s2,a0
    800057f4:	12050263          	beqz	a0,80005918 <sys_unlink+0x1b0>
  ilock(ip);
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	1d6080e7          	jalr	470(ra) # 800039ce <ilock>
  if(ip->nlink < 1)
    80005800:	04a91783          	lh	a5,74(s2)
    80005804:	08f05263          	blez	a5,80005888 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005808:	04491703          	lh	a4,68(s2)
    8000580c:	4785                	li	a5,1
    8000580e:	08f70563          	beq	a4,a5,80005898 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005812:	4641                	li	a2,16
    80005814:	4581                	li	a1,0
    80005816:	fc040513          	addi	a0,s0,-64
    8000581a:	ffffb097          	auipc	ra,0xffffb
    8000581e:	4c6080e7          	jalr	1222(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005822:	4741                	li	a4,16
    80005824:	f2c42683          	lw	a3,-212(s0)
    80005828:	fc040613          	addi	a2,s0,-64
    8000582c:	4581                	li	a1,0
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	54a080e7          	jalr	1354(ra) # 80003d7a <writei>
    80005838:	47c1                	li	a5,16
    8000583a:	0af51563          	bne	a0,a5,800058e4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000583e:	04491703          	lh	a4,68(s2)
    80005842:	4785                	li	a5,1
    80005844:	0af70863          	beq	a4,a5,800058f4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	3e6080e7          	jalr	998(ra) # 80003c30 <iunlockput>
  ip->nlink--;
    80005852:	04a95783          	lhu	a5,74(s2)
    80005856:	37fd                	addiw	a5,a5,-1
    80005858:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000585c:	854a                	mv	a0,s2
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	0a6080e7          	jalr	166(ra) # 80003904 <iupdate>
  iunlockput(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	3c8080e7          	jalr	968(ra) # 80003c30 <iunlockput>
  end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	bb0080e7          	jalr	-1104(ra) # 80004420 <end_op>
  return 0;
    80005878:	4501                	li	a0,0
    8000587a:	a84d                	j	8000592c <sys_unlink+0x1c4>
    end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	ba4080e7          	jalr	-1116(ra) # 80004420 <end_op>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	a05d                	j	8000592c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005888:	00003517          	auipc	a0,0x3
    8000588c:	f8050513          	addi	a0,a0,-128 # 80008808 <syscalls+0x2e8>
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005898:	04c92703          	lw	a4,76(s2)
    8000589c:	02000793          	li	a5,32
    800058a0:	f6e7f9e3          	bgeu	a5,a4,80005812 <sys_unlink+0xaa>
    800058a4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a8:	4741                	li	a4,16
    800058aa:	86ce                	mv	a3,s3
    800058ac:	f1840613          	addi	a2,s0,-232
    800058b0:	4581                	li	a1,0
    800058b2:	854a                	mv	a0,s2
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	3ce080e7          	jalr	974(ra) # 80003c82 <readi>
    800058bc:	47c1                	li	a5,16
    800058be:	00f51b63          	bne	a0,a5,800058d4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058c2:	f1845783          	lhu	a5,-232(s0)
    800058c6:	e7a1                	bnez	a5,8000590e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c8:	29c1                	addiw	s3,s3,16
    800058ca:	04c92783          	lw	a5,76(s2)
    800058ce:	fcf9ede3          	bltu	s3,a5,800058a8 <sys_unlink+0x140>
    800058d2:	b781                	j	80005812 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058d4:	00003517          	auipc	a0,0x3
    800058d8:	f4c50513          	addi	a0,a0,-180 # 80008820 <syscalls+0x300>
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>
    panic("unlink: writei");
    800058e4:	00003517          	auipc	a0,0x3
    800058e8:	f5450513          	addi	a0,a0,-172 # 80008838 <syscalls+0x318>
    800058ec:	ffffb097          	auipc	ra,0xffffb
    800058f0:	c52080e7          	jalr	-942(ra) # 8000053e <panic>
    dp->nlink--;
    800058f4:	04a4d783          	lhu	a5,74(s1)
    800058f8:	37fd                	addiw	a5,a5,-1
    800058fa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	004080e7          	jalr	4(ra) # 80003904 <iupdate>
    80005908:	b781                	j	80005848 <sys_unlink+0xe0>
    return -1;
    8000590a:	557d                	li	a0,-1
    8000590c:	a005                	j	8000592c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	320080e7          	jalr	800(ra) # 80003c30 <iunlockput>
  iunlockput(dp);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	316080e7          	jalr	790(ra) # 80003c30 <iunlockput>
  end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	afe080e7          	jalr	-1282(ra) # 80004420 <end_op>
  return -1;
    8000592a:	557d                	li	a0,-1
}
    8000592c:	70ae                	ld	ra,232(sp)
    8000592e:	740e                	ld	s0,224(sp)
    80005930:	64ee                	ld	s1,216(sp)
    80005932:	694e                	ld	s2,208(sp)
    80005934:	69ae                	ld	s3,200(sp)
    80005936:	616d                	addi	sp,sp,240
    80005938:	8082                	ret

000000008000593a <sys_open>:

uint64
sys_open(void)
{
    8000593a:	7131                	addi	sp,sp,-192
    8000593c:	fd06                	sd	ra,184(sp)
    8000593e:	f922                	sd	s0,176(sp)
    80005940:	f526                	sd	s1,168(sp)
    80005942:	f14a                	sd	s2,160(sp)
    80005944:	ed4e                	sd	s3,152(sp)
    80005946:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005948:	08000613          	li	a2,128
    8000594c:	f5040593          	addi	a1,s0,-176
    80005950:	4501                	li	a0,0
    80005952:	ffffd097          	auipc	ra,0xffffd
    80005956:	350080e7          	jalr	848(ra) # 80002ca2 <argstr>
    return -1;
    8000595a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000595c:	0c054163          	bltz	a0,80005a1e <sys_open+0xe4>
    80005960:	f4c40593          	addi	a1,s0,-180
    80005964:	4505                	li	a0,1
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	2f8080e7          	jalr	760(ra) # 80002c5e <argint>
    8000596e:	0a054863          	bltz	a0,80005a1e <sys_open+0xe4>

  begin_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	a2e080e7          	jalr	-1490(ra) # 800043a0 <begin_op>

  if(omode & O_CREATE){
    8000597a:	f4c42783          	lw	a5,-180(s0)
    8000597e:	2007f793          	andi	a5,a5,512
    80005982:	cbdd                	beqz	a5,80005a38 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005984:	4681                	li	a3,0
    80005986:	4601                	li	a2,0
    80005988:	4589                	li	a1,2
    8000598a:	f5040513          	addi	a0,s0,-176
    8000598e:	00000097          	auipc	ra,0x0
    80005992:	972080e7          	jalr	-1678(ra) # 80005300 <create>
    80005996:	892a                	mv	s2,a0
    if(ip == 0){
    80005998:	c959                	beqz	a0,80005a2e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000599a:	04491703          	lh	a4,68(s2)
    8000599e:	478d                	li	a5,3
    800059a0:	00f71763          	bne	a4,a5,800059ae <sys_open+0x74>
    800059a4:	04695703          	lhu	a4,70(s2)
    800059a8:	47a5                	li	a5,9
    800059aa:	0ce7ec63          	bltu	a5,a4,80005a82 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	e02080e7          	jalr	-510(ra) # 800047b0 <filealloc>
    800059b6:	89aa                	mv	s3,a0
    800059b8:	10050263          	beqz	a0,80005abc <sys_open+0x182>
    800059bc:	00000097          	auipc	ra,0x0
    800059c0:	902080e7          	jalr	-1790(ra) # 800052be <fdalloc>
    800059c4:	84aa                	mv	s1,a0
    800059c6:	0e054663          	bltz	a0,80005ab2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059ca:	04491703          	lh	a4,68(s2)
    800059ce:	478d                	li	a5,3
    800059d0:	0cf70463          	beq	a4,a5,80005a98 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059d4:	4789                	li	a5,2
    800059d6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059da:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059de:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059e2:	f4c42783          	lw	a5,-180(s0)
    800059e6:	0017c713          	xori	a4,a5,1
    800059ea:	8b05                	andi	a4,a4,1
    800059ec:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059f0:	0037f713          	andi	a4,a5,3
    800059f4:	00e03733          	snez	a4,a4
    800059f8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059fc:	4007f793          	andi	a5,a5,1024
    80005a00:	c791                	beqz	a5,80005a0c <sys_open+0xd2>
    80005a02:	04491703          	lh	a4,68(s2)
    80005a06:	4789                	li	a5,2
    80005a08:	08f70f63          	beq	a4,a5,80005aa6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a0c:	854a                	mv	a0,s2
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	082080e7          	jalr	130(ra) # 80003a90 <iunlock>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	a0a080e7          	jalr	-1526(ra) # 80004420 <end_op>

  return fd;
}
    80005a1e:	8526                	mv	a0,s1
    80005a20:	70ea                	ld	ra,184(sp)
    80005a22:	744a                	ld	s0,176(sp)
    80005a24:	74aa                	ld	s1,168(sp)
    80005a26:	790a                	ld	s2,160(sp)
    80005a28:	69ea                	ld	s3,152(sp)
    80005a2a:	6129                	addi	sp,sp,192
    80005a2c:	8082                	ret
      end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	9f2080e7          	jalr	-1550(ra) # 80004420 <end_op>
      return -1;
    80005a36:	b7e5                	j	80005a1e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a38:	f5040513          	addi	a0,s0,-176
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	748080e7          	jalr	1864(ra) # 80004184 <namei>
    80005a44:	892a                	mv	s2,a0
    80005a46:	c905                	beqz	a0,80005a76 <sys_open+0x13c>
    ilock(ip);
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	f86080e7          	jalr	-122(ra) # 800039ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a50:	04491703          	lh	a4,68(s2)
    80005a54:	4785                	li	a5,1
    80005a56:	f4f712e3          	bne	a4,a5,8000599a <sys_open+0x60>
    80005a5a:	f4c42783          	lw	a5,-180(s0)
    80005a5e:	dba1                	beqz	a5,800059ae <sys_open+0x74>
      iunlockput(ip);
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	1ce080e7          	jalr	462(ra) # 80003c30 <iunlockput>
      end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	9b6080e7          	jalr	-1610(ra) # 80004420 <end_op>
      return -1;
    80005a72:	54fd                	li	s1,-1
    80005a74:	b76d                	j	80005a1e <sys_open+0xe4>
      end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	9aa080e7          	jalr	-1622(ra) # 80004420 <end_op>
      return -1;
    80005a7e:	54fd                	li	s1,-1
    80005a80:	bf79                	j	80005a1e <sys_open+0xe4>
    iunlockput(ip);
    80005a82:	854a                	mv	a0,s2
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	1ac080e7          	jalr	428(ra) # 80003c30 <iunlockput>
    end_op();
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	994080e7          	jalr	-1644(ra) # 80004420 <end_op>
    return -1;
    80005a94:	54fd                	li	s1,-1
    80005a96:	b761                	j	80005a1e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a98:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a9c:	04691783          	lh	a5,70(s2)
    80005aa0:	02f99223          	sh	a5,36(s3)
    80005aa4:	bf2d                	j	800059de <sys_open+0xa4>
    itrunc(ip);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	034080e7          	jalr	52(ra) # 80003adc <itrunc>
    80005ab0:	bfb1                	j	80005a0c <sys_open+0xd2>
      fileclose(f);
    80005ab2:	854e                	mv	a0,s3
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	db8080e7          	jalr	-584(ra) # 8000486c <fileclose>
    iunlockput(ip);
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	172080e7          	jalr	370(ra) # 80003c30 <iunlockput>
    end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	95a080e7          	jalr	-1702(ra) # 80004420 <end_op>
    return -1;
    80005ace:	54fd                	li	s1,-1
    80005ad0:	b7b9                	j	80005a1e <sys_open+0xe4>

0000000080005ad2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ad2:	7175                	addi	sp,sp,-144
    80005ad4:	e506                	sd	ra,136(sp)
    80005ad6:	e122                	sd	s0,128(sp)
    80005ad8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	8c6080e7          	jalr	-1850(ra) # 800043a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ae2:	08000613          	li	a2,128
    80005ae6:	f7040593          	addi	a1,s0,-144
    80005aea:	4501                	li	a0,0
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	1b6080e7          	jalr	438(ra) # 80002ca2 <argstr>
    80005af4:	02054963          	bltz	a0,80005b26 <sys_mkdir+0x54>
    80005af8:	4681                	li	a3,0
    80005afa:	4601                	li	a2,0
    80005afc:	4585                	li	a1,1
    80005afe:	f7040513          	addi	a0,s0,-144
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	7fe080e7          	jalr	2046(ra) # 80005300 <create>
    80005b0a:	cd11                	beqz	a0,80005b26 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	124080e7          	jalr	292(ra) # 80003c30 <iunlockput>
  end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	90c080e7          	jalr	-1780(ra) # 80004420 <end_op>
  return 0;
    80005b1c:	4501                	li	a0,0
}
    80005b1e:	60aa                	ld	ra,136(sp)
    80005b20:	640a                	ld	s0,128(sp)
    80005b22:	6149                	addi	sp,sp,144
    80005b24:	8082                	ret
    end_op();
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	8fa080e7          	jalr	-1798(ra) # 80004420 <end_op>
    return -1;
    80005b2e:	557d                	li	a0,-1
    80005b30:	b7fd                	j	80005b1e <sys_mkdir+0x4c>

0000000080005b32 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b32:	7135                	addi	sp,sp,-160
    80005b34:	ed06                	sd	ra,152(sp)
    80005b36:	e922                	sd	s0,144(sp)
    80005b38:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	866080e7          	jalr	-1946(ra) # 800043a0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b42:	08000613          	li	a2,128
    80005b46:	f7040593          	addi	a1,s0,-144
    80005b4a:	4501                	li	a0,0
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	156080e7          	jalr	342(ra) # 80002ca2 <argstr>
    80005b54:	04054a63          	bltz	a0,80005ba8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b58:	f6c40593          	addi	a1,s0,-148
    80005b5c:	4505                	li	a0,1
    80005b5e:	ffffd097          	auipc	ra,0xffffd
    80005b62:	100080e7          	jalr	256(ra) # 80002c5e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b66:	04054163          	bltz	a0,80005ba8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b6a:	f6840593          	addi	a1,s0,-152
    80005b6e:	4509                	li	a0,2
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	0ee080e7          	jalr	238(ra) # 80002c5e <argint>
     argint(1, &major) < 0 ||
    80005b78:	02054863          	bltz	a0,80005ba8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b7c:	f6841683          	lh	a3,-152(s0)
    80005b80:	f6c41603          	lh	a2,-148(s0)
    80005b84:	458d                	li	a1,3
    80005b86:	f7040513          	addi	a0,s0,-144
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	776080e7          	jalr	1910(ra) # 80005300 <create>
     argint(2, &minor) < 0 ||
    80005b92:	c919                	beqz	a0,80005ba8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	09c080e7          	jalr	156(ra) # 80003c30 <iunlockput>
  end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	884080e7          	jalr	-1916(ra) # 80004420 <end_op>
  return 0;
    80005ba4:	4501                	li	a0,0
    80005ba6:	a031                	j	80005bb2 <sys_mknod+0x80>
    end_op();
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	878080e7          	jalr	-1928(ra) # 80004420 <end_op>
    return -1;
    80005bb0:	557d                	li	a0,-1
}
    80005bb2:	60ea                	ld	ra,152(sp)
    80005bb4:	644a                	ld	s0,144(sp)
    80005bb6:	610d                	addi	sp,sp,160
    80005bb8:	8082                	ret

0000000080005bba <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bba:	7135                	addi	sp,sp,-160
    80005bbc:	ed06                	sd	ra,152(sp)
    80005bbe:	e922                	sd	s0,144(sp)
    80005bc0:	e526                	sd	s1,136(sp)
    80005bc2:	e14a                	sd	s2,128(sp)
    80005bc4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bc6:	ffffc097          	auipc	ra,0xffffc
    80005bca:	dea080e7          	jalr	-534(ra) # 800019b0 <myproc>
    80005bce:	892a                	mv	s2,a0
  
  begin_op();
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	7d0080e7          	jalr	2000(ra) # 800043a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bd8:	08000613          	li	a2,128
    80005bdc:	f6040593          	addi	a1,s0,-160
    80005be0:	4501                	li	a0,0
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	0c0080e7          	jalr	192(ra) # 80002ca2 <argstr>
    80005bea:	04054b63          	bltz	a0,80005c40 <sys_chdir+0x86>
    80005bee:	f6040513          	addi	a0,s0,-160
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	592080e7          	jalr	1426(ra) # 80004184 <namei>
    80005bfa:	84aa                	mv	s1,a0
    80005bfc:	c131                	beqz	a0,80005c40 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	dd0080e7          	jalr	-560(ra) # 800039ce <ilock>
  if(ip->type != T_DIR){
    80005c06:	04449703          	lh	a4,68(s1)
    80005c0a:	4785                	li	a5,1
    80005c0c:	04f71063          	bne	a4,a5,80005c4c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c10:	8526                	mv	a0,s1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	e7e080e7          	jalr	-386(ra) # 80003a90 <iunlock>
  iput(p->cwd);
    80005c1a:	15093503          	ld	a0,336(s2)
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	f6a080e7          	jalr	-150(ra) # 80003b88 <iput>
  end_op();
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	7fa080e7          	jalr	2042(ra) # 80004420 <end_op>
  p->cwd = ip;
    80005c2e:	14993823          	sd	s1,336(s2)
  return 0;
    80005c32:	4501                	li	a0,0
}
    80005c34:	60ea                	ld	ra,152(sp)
    80005c36:	644a                	ld	s0,144(sp)
    80005c38:	64aa                	ld	s1,136(sp)
    80005c3a:	690a                	ld	s2,128(sp)
    80005c3c:	610d                	addi	sp,sp,160
    80005c3e:	8082                	ret
    end_op();
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	7e0080e7          	jalr	2016(ra) # 80004420 <end_op>
    return -1;
    80005c48:	557d                	li	a0,-1
    80005c4a:	b7ed                	j	80005c34 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	fe2080e7          	jalr	-30(ra) # 80003c30 <iunlockput>
    end_op();
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	7ca080e7          	jalr	1994(ra) # 80004420 <end_op>
    return -1;
    80005c5e:	557d                	li	a0,-1
    80005c60:	bfd1                	j	80005c34 <sys_chdir+0x7a>

0000000080005c62 <sys_exec>:

uint64
sys_exec(void)
{
    80005c62:	7145                	addi	sp,sp,-464
    80005c64:	e786                	sd	ra,456(sp)
    80005c66:	e3a2                	sd	s0,448(sp)
    80005c68:	ff26                	sd	s1,440(sp)
    80005c6a:	fb4a                	sd	s2,432(sp)
    80005c6c:	f74e                	sd	s3,424(sp)
    80005c6e:	f352                	sd	s4,416(sp)
    80005c70:	ef56                	sd	s5,408(sp)
    80005c72:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c74:	08000613          	li	a2,128
    80005c78:	f4040593          	addi	a1,s0,-192
    80005c7c:	4501                	li	a0,0
    80005c7e:	ffffd097          	auipc	ra,0xffffd
    80005c82:	024080e7          	jalr	36(ra) # 80002ca2 <argstr>
    return -1;
    80005c86:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c88:	0c054a63          	bltz	a0,80005d5c <sys_exec+0xfa>
    80005c8c:	e3840593          	addi	a1,s0,-456
    80005c90:	4505                	li	a0,1
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	fee080e7          	jalr	-18(ra) # 80002c80 <argaddr>
    80005c9a:	0c054163          	bltz	a0,80005d5c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c9e:	10000613          	li	a2,256
    80005ca2:	4581                	li	a1,0
    80005ca4:	e4040513          	addi	a0,s0,-448
    80005ca8:	ffffb097          	auipc	ra,0xffffb
    80005cac:	038080e7          	jalr	56(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cb0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cb4:	89a6                	mv	s3,s1
    80005cb6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cb8:	02000a13          	li	s4,32
    80005cbc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cc0:	00391513          	slli	a0,s2,0x3
    80005cc4:	e3040593          	addi	a1,s0,-464
    80005cc8:	e3843783          	ld	a5,-456(s0)
    80005ccc:	953e                	add	a0,a0,a5
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	ef6080e7          	jalr	-266(ra) # 80002bc4 <fetchaddr>
    80005cd6:	02054a63          	bltz	a0,80005d0a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cda:	e3043783          	ld	a5,-464(s0)
    80005cde:	c3b9                	beqz	a5,80005d24 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ce0:	ffffb097          	auipc	ra,0xffffb
    80005ce4:	e14080e7          	jalr	-492(ra) # 80000af4 <kalloc>
    80005ce8:	85aa                	mv	a1,a0
    80005cea:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cee:	cd11                	beqz	a0,80005d0a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cf0:	6605                	lui	a2,0x1
    80005cf2:	e3043503          	ld	a0,-464(s0)
    80005cf6:	ffffd097          	auipc	ra,0xffffd
    80005cfa:	f20080e7          	jalr	-224(ra) # 80002c16 <fetchstr>
    80005cfe:	00054663          	bltz	a0,80005d0a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d02:	0905                	addi	s2,s2,1
    80005d04:	09a1                	addi	s3,s3,8
    80005d06:	fb491be3          	bne	s2,s4,80005cbc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0a:	10048913          	addi	s2,s1,256
    80005d0e:	6088                	ld	a0,0(s1)
    80005d10:	c529                	beqz	a0,80005d5a <sys_exec+0xf8>
    kfree(argv[i]);
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	ce6080e7          	jalr	-794(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d1a:	04a1                	addi	s1,s1,8
    80005d1c:	ff2499e3          	bne	s1,s2,80005d0e <sys_exec+0xac>
  return -1;
    80005d20:	597d                	li	s2,-1
    80005d22:	a82d                	j	80005d5c <sys_exec+0xfa>
      argv[i] = 0;
    80005d24:	0a8e                	slli	s5,s5,0x3
    80005d26:	fc040793          	addi	a5,s0,-64
    80005d2a:	9abe                	add	s5,s5,a5
    80005d2c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d30:	e4040593          	addi	a1,s0,-448
    80005d34:	f4040513          	addi	a0,s0,-192
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	194080e7          	jalr	404(ra) # 80004ecc <exec>
    80005d40:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d42:	10048993          	addi	s3,s1,256
    80005d46:	6088                	ld	a0,0(s1)
    80005d48:	c911                	beqz	a0,80005d5c <sys_exec+0xfa>
    kfree(argv[i]);
    80005d4a:	ffffb097          	auipc	ra,0xffffb
    80005d4e:	cae080e7          	jalr	-850(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d52:	04a1                	addi	s1,s1,8
    80005d54:	ff3499e3          	bne	s1,s3,80005d46 <sys_exec+0xe4>
    80005d58:	a011                	j	80005d5c <sys_exec+0xfa>
  return -1;
    80005d5a:	597d                	li	s2,-1
}
    80005d5c:	854a                	mv	a0,s2
    80005d5e:	60be                	ld	ra,456(sp)
    80005d60:	641e                	ld	s0,448(sp)
    80005d62:	74fa                	ld	s1,440(sp)
    80005d64:	795a                	ld	s2,432(sp)
    80005d66:	79ba                	ld	s3,424(sp)
    80005d68:	7a1a                	ld	s4,416(sp)
    80005d6a:	6afa                	ld	s5,408(sp)
    80005d6c:	6179                	addi	sp,sp,464
    80005d6e:	8082                	ret

0000000080005d70 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d70:	7139                	addi	sp,sp,-64
    80005d72:	fc06                	sd	ra,56(sp)
    80005d74:	f822                	sd	s0,48(sp)
    80005d76:	f426                	sd	s1,40(sp)
    80005d78:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d7a:	ffffc097          	auipc	ra,0xffffc
    80005d7e:	c36080e7          	jalr	-970(ra) # 800019b0 <myproc>
    80005d82:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d84:	fd840593          	addi	a1,s0,-40
    80005d88:	4501                	li	a0,0
    80005d8a:	ffffd097          	auipc	ra,0xffffd
    80005d8e:	ef6080e7          	jalr	-266(ra) # 80002c80 <argaddr>
    return -1;
    80005d92:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d94:	0e054063          	bltz	a0,80005e74 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d98:	fc840593          	addi	a1,s0,-56
    80005d9c:	fd040513          	addi	a0,s0,-48
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	dfc080e7          	jalr	-516(ra) # 80004b9c <pipealloc>
    return -1;
    80005da8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005daa:	0c054563          	bltz	a0,80005e74 <sys_pipe+0x104>
  fd0 = -1;
    80005dae:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005db2:	fd043503          	ld	a0,-48(s0)
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	508080e7          	jalr	1288(ra) # 800052be <fdalloc>
    80005dbe:	fca42223          	sw	a0,-60(s0)
    80005dc2:	08054c63          	bltz	a0,80005e5a <sys_pipe+0xea>
    80005dc6:	fc843503          	ld	a0,-56(s0)
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	4f4080e7          	jalr	1268(ra) # 800052be <fdalloc>
    80005dd2:	fca42023          	sw	a0,-64(s0)
    80005dd6:	06054863          	bltz	a0,80005e46 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dda:	4691                	li	a3,4
    80005ddc:	fc440613          	addi	a2,s0,-60
    80005de0:	fd843583          	ld	a1,-40(s0)
    80005de4:	68a8                	ld	a0,80(s1)
    80005de6:	ffffc097          	auipc	ra,0xffffc
    80005dea:	88c080e7          	jalr	-1908(ra) # 80001672 <copyout>
    80005dee:	02054063          	bltz	a0,80005e0e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005df2:	4691                	li	a3,4
    80005df4:	fc040613          	addi	a2,s0,-64
    80005df8:	fd843583          	ld	a1,-40(s0)
    80005dfc:	0591                	addi	a1,a1,4
    80005dfe:	68a8                	ld	a0,80(s1)
    80005e00:	ffffc097          	auipc	ra,0xffffc
    80005e04:	872080e7          	jalr	-1934(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e08:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e0a:	06055563          	bgez	a0,80005e74 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e0e:	fc442783          	lw	a5,-60(s0)
    80005e12:	07e9                	addi	a5,a5,26
    80005e14:	078e                	slli	a5,a5,0x3
    80005e16:	97a6                	add	a5,a5,s1
    80005e18:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e1c:	fc042503          	lw	a0,-64(s0)
    80005e20:	0569                	addi	a0,a0,26
    80005e22:	050e                	slli	a0,a0,0x3
    80005e24:	9526                	add	a0,a0,s1
    80005e26:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e2a:	fd043503          	ld	a0,-48(s0)
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	a3e080e7          	jalr	-1474(ra) # 8000486c <fileclose>
    fileclose(wf);
    80005e36:	fc843503          	ld	a0,-56(s0)
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	a32080e7          	jalr	-1486(ra) # 8000486c <fileclose>
    return -1;
    80005e42:	57fd                	li	a5,-1
    80005e44:	a805                	j	80005e74 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e46:	fc442783          	lw	a5,-60(s0)
    80005e4a:	0007c863          	bltz	a5,80005e5a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e4e:	01a78513          	addi	a0,a5,26
    80005e52:	050e                	slli	a0,a0,0x3
    80005e54:	9526                	add	a0,a0,s1
    80005e56:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e5a:	fd043503          	ld	a0,-48(s0)
    80005e5e:	fffff097          	auipc	ra,0xfffff
    80005e62:	a0e080e7          	jalr	-1522(ra) # 8000486c <fileclose>
    fileclose(wf);
    80005e66:	fc843503          	ld	a0,-56(s0)
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	a02080e7          	jalr	-1534(ra) # 8000486c <fileclose>
    return -1;
    80005e72:	57fd                	li	a5,-1
}
    80005e74:	853e                	mv	a0,a5
    80005e76:	70e2                	ld	ra,56(sp)
    80005e78:	7442                	ld	s0,48(sp)
    80005e7a:	74a2                	ld	s1,40(sp)
    80005e7c:	6121                	addi	sp,sp,64
    80005e7e:	8082                	ret

0000000080005e80 <kernelvec>:
    80005e80:	7111                	addi	sp,sp,-256
    80005e82:	e006                	sd	ra,0(sp)
    80005e84:	e40a                	sd	sp,8(sp)
    80005e86:	e80e                	sd	gp,16(sp)
    80005e88:	ec12                	sd	tp,24(sp)
    80005e8a:	f016                	sd	t0,32(sp)
    80005e8c:	f41a                	sd	t1,40(sp)
    80005e8e:	f81e                	sd	t2,48(sp)
    80005e90:	fc22                	sd	s0,56(sp)
    80005e92:	e0a6                	sd	s1,64(sp)
    80005e94:	e4aa                	sd	a0,72(sp)
    80005e96:	e8ae                	sd	a1,80(sp)
    80005e98:	ecb2                	sd	a2,88(sp)
    80005e9a:	f0b6                	sd	a3,96(sp)
    80005e9c:	f4ba                	sd	a4,104(sp)
    80005e9e:	f8be                	sd	a5,112(sp)
    80005ea0:	fcc2                	sd	a6,120(sp)
    80005ea2:	e146                	sd	a7,128(sp)
    80005ea4:	e54a                	sd	s2,136(sp)
    80005ea6:	e94e                	sd	s3,144(sp)
    80005ea8:	ed52                	sd	s4,152(sp)
    80005eaa:	f156                	sd	s5,160(sp)
    80005eac:	f55a                	sd	s6,168(sp)
    80005eae:	f95e                	sd	s7,176(sp)
    80005eb0:	fd62                	sd	s8,184(sp)
    80005eb2:	e1e6                	sd	s9,192(sp)
    80005eb4:	e5ea                	sd	s10,200(sp)
    80005eb6:	e9ee                	sd	s11,208(sp)
    80005eb8:	edf2                	sd	t3,216(sp)
    80005eba:	f1f6                	sd	t4,224(sp)
    80005ebc:	f5fa                	sd	t5,232(sp)
    80005ebe:	f9fe                	sd	t6,240(sp)
    80005ec0:	bd1fc0ef          	jal	ra,80002a90 <kerneltrap>
    80005ec4:	6082                	ld	ra,0(sp)
    80005ec6:	6122                	ld	sp,8(sp)
    80005ec8:	61c2                	ld	gp,16(sp)
    80005eca:	7282                	ld	t0,32(sp)
    80005ecc:	7322                	ld	t1,40(sp)
    80005ece:	73c2                	ld	t2,48(sp)
    80005ed0:	7462                	ld	s0,56(sp)
    80005ed2:	6486                	ld	s1,64(sp)
    80005ed4:	6526                	ld	a0,72(sp)
    80005ed6:	65c6                	ld	a1,80(sp)
    80005ed8:	6666                	ld	a2,88(sp)
    80005eda:	7686                	ld	a3,96(sp)
    80005edc:	7726                	ld	a4,104(sp)
    80005ede:	77c6                	ld	a5,112(sp)
    80005ee0:	7866                	ld	a6,120(sp)
    80005ee2:	688a                	ld	a7,128(sp)
    80005ee4:	692a                	ld	s2,136(sp)
    80005ee6:	69ca                	ld	s3,144(sp)
    80005ee8:	6a6a                	ld	s4,152(sp)
    80005eea:	7a8a                	ld	s5,160(sp)
    80005eec:	7b2a                	ld	s6,168(sp)
    80005eee:	7bca                	ld	s7,176(sp)
    80005ef0:	7c6a                	ld	s8,184(sp)
    80005ef2:	6c8e                	ld	s9,192(sp)
    80005ef4:	6d2e                	ld	s10,200(sp)
    80005ef6:	6dce                	ld	s11,208(sp)
    80005ef8:	6e6e                	ld	t3,216(sp)
    80005efa:	7e8e                	ld	t4,224(sp)
    80005efc:	7f2e                	ld	t5,232(sp)
    80005efe:	7fce                	ld	t6,240(sp)
    80005f00:	6111                	addi	sp,sp,256
    80005f02:	10200073          	sret
    80005f06:	00000013          	nop
    80005f0a:	00000013          	nop
    80005f0e:	0001                	nop

0000000080005f10 <timervec>:
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	e10c                	sd	a1,0(a0)
    80005f16:	e510                	sd	a2,8(a0)
    80005f18:	e914                	sd	a3,16(a0)
    80005f1a:	6d0c                	ld	a1,24(a0)
    80005f1c:	7110                	ld	a2,32(a0)
    80005f1e:	6194                	ld	a3,0(a1)
    80005f20:	96b2                	add	a3,a3,a2
    80005f22:	e194                	sd	a3,0(a1)
    80005f24:	4589                	li	a1,2
    80005f26:	14459073          	csrw	sip,a1
    80005f2a:	6914                	ld	a3,16(a0)
    80005f2c:	6510                	ld	a2,8(a0)
    80005f2e:	610c                	ld	a1,0(a0)
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	30200073          	mret
	...

0000000080005f3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f3a:	1141                	addi	sp,sp,-16
    80005f3c:	e422                	sd	s0,8(sp)
    80005f3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f40:	0c0007b7          	lui	a5,0xc000
    80005f44:	4705                	li	a4,1
    80005f46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f48:	c3d8                	sw	a4,4(a5)
}
    80005f4a:	6422                	ld	s0,8(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret

0000000080005f50 <plicinithart>:

void
plicinithart(void)
{
    80005f50:	1141                	addi	sp,sp,-16
    80005f52:	e406                	sd	ra,8(sp)
    80005f54:	e022                	sd	s0,0(sp)
    80005f56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	a2c080e7          	jalr	-1492(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f60:	0085171b          	slliw	a4,a0,0x8
    80005f64:	0c0027b7          	lui	a5,0xc002
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	40200713          	li	a4,1026
    80005f6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f72:	00d5151b          	slliw	a0,a0,0xd
    80005f76:	0c2017b7          	lui	a5,0xc201
    80005f7a:	953e                	add	a0,a0,a5
    80005f7c:	00052023          	sw	zero,0(a0)
}
    80005f80:	60a2                	ld	ra,8(sp)
    80005f82:	6402                	ld	s0,0(sp)
    80005f84:	0141                	addi	sp,sp,16
    80005f86:	8082                	ret

0000000080005f88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f88:	1141                	addi	sp,sp,-16
    80005f8a:	e406                	sd	ra,8(sp)
    80005f8c:	e022                	sd	s0,0(sp)
    80005f8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f90:	ffffc097          	auipc	ra,0xffffc
    80005f94:	9f4080e7          	jalr	-1548(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f98:	00d5179b          	slliw	a5,a0,0xd
    80005f9c:	0c201537          	lui	a0,0xc201
    80005fa0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fa2:	4148                	lw	a0,4(a0)
    80005fa4:	60a2                	ld	ra,8(sp)
    80005fa6:	6402                	ld	s0,0(sp)
    80005fa8:	0141                	addi	sp,sp,16
    80005faa:	8082                	ret

0000000080005fac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fac:	1101                	addi	sp,sp,-32
    80005fae:	ec06                	sd	ra,24(sp)
    80005fb0:	e822                	sd	s0,16(sp)
    80005fb2:	e426                	sd	s1,8(sp)
    80005fb4:	1000                	addi	s0,sp,32
    80005fb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	9cc080e7          	jalr	-1588(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fc0:	00d5151b          	slliw	a0,a0,0xd
    80005fc4:	0c2017b7          	lui	a5,0xc201
    80005fc8:	97aa                	add	a5,a5,a0
    80005fca:	c3c4                	sw	s1,4(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret

0000000080005fd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fd6:	1141                	addi	sp,sp,-16
    80005fd8:	e406                	sd	ra,8(sp)
    80005fda:	e022                	sd	s0,0(sp)
    80005fdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fde:	479d                	li	a5,7
    80005fe0:	06a7c963          	blt	a5,a0,80006052 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005fe4:	0001d797          	auipc	a5,0x1d
    80005fe8:	01c78793          	addi	a5,a5,28 # 80023000 <disk>
    80005fec:	00a78733          	add	a4,a5,a0
    80005ff0:	6789                	lui	a5,0x2
    80005ff2:	97ba                	add	a5,a5,a4
    80005ff4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ff8:	e7ad                	bnez	a5,80006062 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ffa:	00451793          	slli	a5,a0,0x4
    80005ffe:	0001f717          	auipc	a4,0x1f
    80006002:	00270713          	addi	a4,a4,2 # 80025000 <disk+0x2000>
    80006006:	6314                	ld	a3,0(a4)
    80006008:	96be                	add	a3,a3,a5
    8000600a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000600e:	6314                	ld	a3,0(a4)
    80006010:	96be                	add	a3,a3,a5
    80006012:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006016:	6314                	ld	a3,0(a4)
    80006018:	96be                	add	a3,a3,a5
    8000601a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000601e:	6318                	ld	a4,0(a4)
    80006020:	97ba                	add	a5,a5,a4
    80006022:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006026:	0001d797          	auipc	a5,0x1d
    8000602a:	fda78793          	addi	a5,a5,-38 # 80023000 <disk>
    8000602e:	97aa                	add	a5,a5,a0
    80006030:	6509                	lui	a0,0x2
    80006032:	953e                	add	a0,a0,a5
    80006034:	4785                	li	a5,1
    80006036:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000603a:	0001f517          	auipc	a0,0x1f
    8000603e:	fde50513          	addi	a0,a0,-34 # 80025018 <disk+0x2018>
    80006042:	ffffc097          	auipc	ra,0xffffc
    80006046:	37c080e7          	jalr	892(ra) # 800023be <wakeup>
}
    8000604a:	60a2                	ld	ra,8(sp)
    8000604c:	6402                	ld	s0,0(sp)
    8000604e:	0141                	addi	sp,sp,16
    80006050:	8082                	ret
    panic("free_desc 1");
    80006052:	00002517          	auipc	a0,0x2
    80006056:	7f650513          	addi	a0,a0,2038 # 80008848 <syscalls+0x328>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e4080e7          	jalr	1252(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	7f650513          	addi	a0,a0,2038 # 80008858 <syscalls+0x338>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>

0000000080006072 <virtio_disk_init>:
{
    80006072:	1101                	addi	sp,sp,-32
    80006074:	ec06                	sd	ra,24(sp)
    80006076:	e822                	sd	s0,16(sp)
    80006078:	e426                	sd	s1,8(sp)
    8000607a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000607c:	00002597          	auipc	a1,0x2
    80006080:	7ec58593          	addi	a1,a1,2028 # 80008868 <syscalls+0x348>
    80006084:	0001f517          	auipc	a0,0x1f
    80006088:	0a450513          	addi	a0,a0,164 # 80025128 <disk+0x2128>
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	ac8080e7          	jalr	-1336(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006094:	100017b7          	lui	a5,0x10001
    80006098:	4398                	lw	a4,0(a5)
    8000609a:	2701                	sext.w	a4,a4
    8000609c:	747277b7          	lui	a5,0x74727
    800060a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060a4:	0ef71163          	bne	a4,a5,80006186 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060a8:	100017b7          	lui	a5,0x10001
    800060ac:	43dc                	lw	a5,4(a5)
    800060ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060b0:	4705                	li	a4,1
    800060b2:	0ce79a63          	bne	a5,a4,80006186 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060b6:	100017b7          	lui	a5,0x10001
    800060ba:	479c                	lw	a5,8(a5)
    800060bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060be:	4709                	li	a4,2
    800060c0:	0ce79363          	bne	a5,a4,80006186 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060c4:	100017b7          	lui	a5,0x10001
    800060c8:	47d8                	lw	a4,12(a5)
    800060ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060cc:	554d47b7          	lui	a5,0x554d4
    800060d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060d4:	0af71963          	bne	a4,a5,80006186 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d8:	100017b7          	lui	a5,0x10001
    800060dc:	4705                	li	a4,1
    800060de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e0:	470d                	li	a4,3
    800060e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060e6:	c7ffe737          	lui	a4,0xc7ffe
    800060ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800060ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060f0:	2701                	sext.w	a4,a4
    800060f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f4:	472d                	li	a4,11
    800060f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f8:	473d                	li	a4,15
    800060fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060fc:	6705                	lui	a4,0x1
    800060fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006100:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006104:	5bdc                	lw	a5,52(a5)
    80006106:	2781                	sext.w	a5,a5
  if(max == 0)
    80006108:	c7d9                	beqz	a5,80006196 <virtio_disk_init+0x124>
  if(max < NUM)
    8000610a:	471d                	li	a4,7
    8000610c:	08f77d63          	bgeu	a4,a5,800061a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006110:	100014b7          	lui	s1,0x10001
    80006114:	47a1                	li	a5,8
    80006116:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006118:	6609                	lui	a2,0x2
    8000611a:	4581                	li	a1,0
    8000611c:	0001d517          	auipc	a0,0x1d
    80006120:	ee450513          	addi	a0,a0,-284 # 80023000 <disk>
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	bbc080e7          	jalr	-1092(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000612c:	0001d717          	auipc	a4,0x1d
    80006130:	ed470713          	addi	a4,a4,-300 # 80023000 <disk>
    80006134:	00c75793          	srli	a5,a4,0xc
    80006138:	2781                	sext.w	a5,a5
    8000613a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000613c:	0001f797          	auipc	a5,0x1f
    80006140:	ec478793          	addi	a5,a5,-316 # 80025000 <disk+0x2000>
    80006144:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006146:	0001d717          	auipc	a4,0x1d
    8000614a:	f3a70713          	addi	a4,a4,-198 # 80023080 <disk+0x80>
    8000614e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006150:	0001e717          	auipc	a4,0x1e
    80006154:	eb070713          	addi	a4,a4,-336 # 80024000 <disk+0x1000>
    80006158:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000615a:	4705                	li	a4,1
    8000615c:	00e78c23          	sb	a4,24(a5)
    80006160:	00e78ca3          	sb	a4,25(a5)
    80006164:	00e78d23          	sb	a4,26(a5)
    80006168:	00e78da3          	sb	a4,27(a5)
    8000616c:	00e78e23          	sb	a4,28(a5)
    80006170:	00e78ea3          	sb	a4,29(a5)
    80006174:	00e78f23          	sb	a4,30(a5)
    80006178:	00e78fa3          	sb	a4,31(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret
    panic("could not find virtio disk");
    80006186:	00002517          	auipc	a0,0x2
    8000618a:	6f250513          	addi	a0,a0,1778 # 80008878 <syscalls+0x358>
    8000618e:	ffffa097          	auipc	ra,0xffffa
    80006192:	3b0080e7          	jalr	944(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006196:	00002517          	auipc	a0,0x2
    8000619a:	70250513          	addi	a0,a0,1794 # 80008898 <syscalls+0x378>
    8000619e:	ffffa097          	auipc	ra,0xffffa
    800061a2:	3a0080e7          	jalr	928(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800061a6:	00002517          	auipc	a0,0x2
    800061aa:	71250513          	addi	a0,a0,1810 # 800088b8 <syscalls+0x398>
    800061ae:	ffffa097          	auipc	ra,0xffffa
    800061b2:	390080e7          	jalr	912(ra) # 8000053e <panic>

00000000800061b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b6:	7159                	addi	sp,sp,-112
    800061b8:	f486                	sd	ra,104(sp)
    800061ba:	f0a2                	sd	s0,96(sp)
    800061bc:	eca6                	sd	s1,88(sp)
    800061be:	e8ca                	sd	s2,80(sp)
    800061c0:	e4ce                	sd	s3,72(sp)
    800061c2:	e0d2                	sd	s4,64(sp)
    800061c4:	fc56                	sd	s5,56(sp)
    800061c6:	f85a                	sd	s6,48(sp)
    800061c8:	f45e                	sd	s7,40(sp)
    800061ca:	f062                	sd	s8,32(sp)
    800061cc:	ec66                	sd	s9,24(sp)
    800061ce:	e86a                	sd	s10,16(sp)
    800061d0:	1880                	addi	s0,sp,112
    800061d2:	892a                	mv	s2,a0
    800061d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d6:	00c52c83          	lw	s9,12(a0)
    800061da:	001c9c9b          	slliw	s9,s9,0x1
    800061de:	1c82                	slli	s9,s9,0x20
    800061e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061e4:	0001f517          	auipc	a0,0x1f
    800061e8:	f4450513          	addi	a0,a0,-188 # 80025128 <disk+0x2128>
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	9f8080e7          	jalr	-1544(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800061f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061f8:	0001db97          	auipc	s7,0x1d
    800061fc:	e08b8b93          	addi	s7,s7,-504 # 80023000 <disk>
    80006200:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006202:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006204:	8a4e                	mv	s4,s3
    80006206:	a051                	j	8000628a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006208:	00fb86b3          	add	a3,s7,a5
    8000620c:	96da                	add	a3,a3,s6
    8000620e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006212:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006214:	0207c563          	bltz	a5,8000623e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006218:	2485                	addiw	s1,s1,1
    8000621a:	0711                	addi	a4,a4,4
    8000621c:	25548063          	beq	s1,s5,8000645c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006220:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006222:	0001f697          	auipc	a3,0x1f
    80006226:	df668693          	addi	a3,a3,-522 # 80025018 <disk+0x2018>
    8000622a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000622c:	0006c583          	lbu	a1,0(a3)
    80006230:	fde1                	bnez	a1,80006208 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006232:	2785                	addiw	a5,a5,1
    80006234:	0685                	addi	a3,a3,1
    80006236:	ff879be3          	bne	a5,s8,8000622c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000623a:	57fd                	li	a5,-1
    8000623c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000623e:	02905a63          	blez	s1,80006272 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006242:	f9042503          	lw	a0,-112(s0)
    80006246:	00000097          	auipc	ra,0x0
    8000624a:	d90080e7          	jalr	-624(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    8000624e:	4785                	li	a5,1
    80006250:	0297d163          	bge	a5,s1,80006272 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006254:	f9442503          	lw	a0,-108(s0)
    80006258:	00000097          	auipc	ra,0x0
    8000625c:	d7e080e7          	jalr	-642(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006260:	4789                	li	a5,2
    80006262:	0097d863          	bge	a5,s1,80006272 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006266:	f9842503          	lw	a0,-104(s0)
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	d6c080e7          	jalr	-660(ra) # 80005fd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006272:	0001f597          	auipc	a1,0x1f
    80006276:	eb658593          	addi	a1,a1,-330 # 80025128 <disk+0x2128>
    8000627a:	0001f517          	auipc	a0,0x1f
    8000627e:	d9e50513          	addi	a0,a0,-610 # 80025018 <disk+0x2018>
    80006282:	ffffc097          	auipc	ra,0xffffc
    80006286:	e64080e7          	jalr	-412(ra) # 800020e6 <sleep>
  for(int i = 0; i < 3; i++){
    8000628a:	f9040713          	addi	a4,s0,-112
    8000628e:	84ce                	mv	s1,s3
    80006290:	bf41                	j	80006220 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006292:	20058713          	addi	a4,a1,512
    80006296:	00471693          	slli	a3,a4,0x4
    8000629a:	0001d717          	auipc	a4,0x1d
    8000629e:	d6670713          	addi	a4,a4,-666 # 80023000 <disk>
    800062a2:	9736                	add	a4,a4,a3
    800062a4:	4685                	li	a3,1
    800062a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062aa:	20058713          	addi	a4,a1,512
    800062ae:	00471693          	slli	a3,a4,0x4
    800062b2:	0001d717          	auipc	a4,0x1d
    800062b6:	d4e70713          	addi	a4,a4,-690 # 80023000 <disk>
    800062ba:	9736                	add	a4,a4,a3
    800062bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c4:	7679                	lui	a2,0xffffe
    800062c6:	963e                	add	a2,a2,a5
    800062c8:	0001f697          	auipc	a3,0x1f
    800062cc:	d3868693          	addi	a3,a3,-712 # 80025000 <disk+0x2000>
    800062d0:	6298                	ld	a4,0(a3)
    800062d2:	9732                	add	a4,a4,a2
    800062d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062d6:	6298                	ld	a4,0(a3)
    800062d8:	9732                	add	a4,a4,a2
    800062da:	4541                	li	a0,16
    800062dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062de:	6298                	ld	a4,0(a3)
    800062e0:	9732                	add	a4,a4,a2
    800062e2:	4505                	li	a0,1
    800062e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062e8:	f9442703          	lw	a4,-108(s0)
    800062ec:	6288                	ld	a0,0(a3)
    800062ee:	962a                	add	a2,a2,a0
    800062f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062f4:	0712                	slli	a4,a4,0x4
    800062f6:	6290                	ld	a2,0(a3)
    800062f8:	963a                	add	a2,a2,a4
    800062fa:	05890513          	addi	a0,s2,88
    800062fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006300:	6294                	ld	a3,0(a3)
    80006302:	96ba                	add	a3,a3,a4
    80006304:	40000613          	li	a2,1024
    80006308:	c690                	sw	a2,8(a3)
  if(write)
    8000630a:	140d0063          	beqz	s10,8000644a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000630e:	0001f697          	auipc	a3,0x1f
    80006312:	cf26b683          	ld	a3,-782(a3) # 80025000 <disk+0x2000>
    80006316:	96ba                	add	a3,a3,a4
    80006318:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000631c:	0001d817          	auipc	a6,0x1d
    80006320:	ce480813          	addi	a6,a6,-796 # 80023000 <disk>
    80006324:	0001f517          	auipc	a0,0x1f
    80006328:	cdc50513          	addi	a0,a0,-804 # 80025000 <disk+0x2000>
    8000632c:	6114                	ld	a3,0(a0)
    8000632e:	96ba                	add	a3,a3,a4
    80006330:	00c6d603          	lhu	a2,12(a3)
    80006334:	00166613          	ori	a2,a2,1
    80006338:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000633c:	f9842683          	lw	a3,-104(s0)
    80006340:	6110                	ld	a2,0(a0)
    80006342:	9732                	add	a4,a4,a2
    80006344:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006348:	20058613          	addi	a2,a1,512
    8000634c:	0612                	slli	a2,a2,0x4
    8000634e:	9642                	add	a2,a2,a6
    80006350:	577d                	li	a4,-1
    80006352:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006356:	00469713          	slli	a4,a3,0x4
    8000635a:	6114                	ld	a3,0(a0)
    8000635c:	96ba                	add	a3,a3,a4
    8000635e:	03078793          	addi	a5,a5,48
    80006362:	97c2                	add	a5,a5,a6
    80006364:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006366:	611c                	ld	a5,0(a0)
    80006368:	97ba                	add	a5,a5,a4
    8000636a:	4685                	li	a3,1
    8000636c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000636e:	611c                	ld	a5,0(a0)
    80006370:	97ba                	add	a5,a5,a4
    80006372:	4809                	li	a6,2
    80006374:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006378:	611c                	ld	a5,0(a0)
    8000637a:	973e                	add	a4,a4,a5
    8000637c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006380:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006384:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006388:	6518                	ld	a4,8(a0)
    8000638a:	00275783          	lhu	a5,2(a4)
    8000638e:	8b9d                	andi	a5,a5,7
    80006390:	0786                	slli	a5,a5,0x1
    80006392:	97ba                	add	a5,a5,a4
    80006394:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006398:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000639c:	6518                	ld	a4,8(a0)
    8000639e:	00275783          	lhu	a5,2(a4)
    800063a2:	2785                	addiw	a5,a5,1
    800063a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ac:	100017b7          	lui	a5,0x10001
    800063b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063b4:	00492703          	lw	a4,4(s2)
    800063b8:	4785                	li	a5,1
    800063ba:	02f71163          	bne	a4,a5,800063dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800063be:	0001f997          	auipc	s3,0x1f
    800063c2:	d6a98993          	addi	s3,s3,-662 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800063c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063c8:	85ce                	mv	a1,s3
    800063ca:	854a                	mv	a0,s2
    800063cc:	ffffc097          	auipc	ra,0xffffc
    800063d0:	d1a080e7          	jalr	-742(ra) # 800020e6 <sleep>
  while(b->disk == 1) {
    800063d4:	00492783          	lw	a5,4(s2)
    800063d8:	fe9788e3          	beq	a5,s1,800063c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800063dc:	f9042903          	lw	s2,-112(s0)
    800063e0:	20090793          	addi	a5,s2,512
    800063e4:	00479713          	slli	a4,a5,0x4
    800063e8:	0001d797          	auipc	a5,0x1d
    800063ec:	c1878793          	addi	a5,a5,-1000 # 80023000 <disk>
    800063f0:	97ba                	add	a5,a5,a4
    800063f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063f6:	0001f997          	auipc	s3,0x1f
    800063fa:	c0a98993          	addi	s3,s3,-1014 # 80025000 <disk+0x2000>
    800063fe:	00491713          	slli	a4,s2,0x4
    80006402:	0009b783          	ld	a5,0(s3)
    80006406:	97ba                	add	a5,a5,a4
    80006408:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000640c:	854a                	mv	a0,s2
    8000640e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006412:	00000097          	auipc	ra,0x0
    80006416:	bc4080e7          	jalr	-1084(ra) # 80005fd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000641a:	8885                	andi	s1,s1,1
    8000641c:	f0ed                	bnez	s1,800063fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000641e:	0001f517          	auipc	a0,0x1f
    80006422:	d0a50513          	addi	a0,a0,-758 # 80025128 <disk+0x2128>
    80006426:	ffffb097          	auipc	ra,0xffffb
    8000642a:	872080e7          	jalr	-1934(ra) # 80000c98 <release>
}
    8000642e:	70a6                	ld	ra,104(sp)
    80006430:	7406                	ld	s0,96(sp)
    80006432:	64e6                	ld	s1,88(sp)
    80006434:	6946                	ld	s2,80(sp)
    80006436:	69a6                	ld	s3,72(sp)
    80006438:	6a06                	ld	s4,64(sp)
    8000643a:	7ae2                	ld	s5,56(sp)
    8000643c:	7b42                	ld	s6,48(sp)
    8000643e:	7ba2                	ld	s7,40(sp)
    80006440:	7c02                	ld	s8,32(sp)
    80006442:	6ce2                	ld	s9,24(sp)
    80006444:	6d42                	ld	s10,16(sp)
    80006446:	6165                	addi	sp,sp,112
    80006448:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000644a:	0001f697          	auipc	a3,0x1f
    8000644e:	bb66b683          	ld	a3,-1098(a3) # 80025000 <disk+0x2000>
    80006452:	96ba                	add	a3,a3,a4
    80006454:	4609                	li	a2,2
    80006456:	00c69623          	sh	a2,12(a3)
    8000645a:	b5c9                	j	8000631c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000645c:	f9042583          	lw	a1,-112(s0)
    80006460:	20058793          	addi	a5,a1,512
    80006464:	0792                	slli	a5,a5,0x4
    80006466:	0001d517          	auipc	a0,0x1d
    8000646a:	c4250513          	addi	a0,a0,-958 # 800230a8 <disk+0xa8>
    8000646e:	953e                	add	a0,a0,a5
  if(write)
    80006470:	e20d11e3          	bnez	s10,80006292 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006474:	20058713          	addi	a4,a1,512
    80006478:	00471693          	slli	a3,a4,0x4
    8000647c:	0001d717          	auipc	a4,0x1d
    80006480:	b8470713          	addi	a4,a4,-1148 # 80023000 <disk>
    80006484:	9736                	add	a4,a4,a3
    80006486:	0a072423          	sw	zero,168(a4)
    8000648a:	b505                	j	800062aa <virtio_disk_rw+0xf4>

000000008000648c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000648c:	1101                	addi	sp,sp,-32
    8000648e:	ec06                	sd	ra,24(sp)
    80006490:	e822                	sd	s0,16(sp)
    80006492:	e426                	sd	s1,8(sp)
    80006494:	e04a                	sd	s2,0(sp)
    80006496:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006498:	0001f517          	auipc	a0,0x1f
    8000649c:	c9050513          	addi	a0,a0,-880 # 80025128 <disk+0x2128>
    800064a0:	ffffa097          	auipc	ra,0xffffa
    800064a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064a8:	10001737          	lui	a4,0x10001
    800064ac:	533c                	lw	a5,96(a4)
    800064ae:	8b8d                	andi	a5,a5,3
    800064b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064b6:	0001f797          	auipc	a5,0x1f
    800064ba:	b4a78793          	addi	a5,a5,-1206 # 80025000 <disk+0x2000>
    800064be:	6b94                	ld	a3,16(a5)
    800064c0:	0207d703          	lhu	a4,32(a5)
    800064c4:	0026d783          	lhu	a5,2(a3)
    800064c8:	06f70163          	beq	a4,a5,8000652a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064cc:	0001d917          	auipc	s2,0x1d
    800064d0:	b3490913          	addi	s2,s2,-1228 # 80023000 <disk>
    800064d4:	0001f497          	auipc	s1,0x1f
    800064d8:	b2c48493          	addi	s1,s1,-1236 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064e0:	6898                	ld	a4,16(s1)
    800064e2:	0204d783          	lhu	a5,32(s1)
    800064e6:	8b9d                	andi	a5,a5,7
    800064e8:	078e                	slli	a5,a5,0x3
    800064ea:	97ba                	add	a5,a5,a4
    800064ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064ee:	20078713          	addi	a4,a5,512
    800064f2:	0712                	slli	a4,a4,0x4
    800064f4:	974a                	add	a4,a4,s2
    800064f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064fa:	e731                	bnez	a4,80006546 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064fc:	20078793          	addi	a5,a5,512
    80006500:	0792                	slli	a5,a5,0x4
    80006502:	97ca                	add	a5,a5,s2
    80006504:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006506:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000650a:	ffffc097          	auipc	ra,0xffffc
    8000650e:	eb4080e7          	jalr	-332(ra) # 800023be <wakeup>

    disk.used_idx += 1;
    80006512:	0204d783          	lhu	a5,32(s1)
    80006516:	2785                	addiw	a5,a5,1
    80006518:	17c2                	slli	a5,a5,0x30
    8000651a:	93c1                	srli	a5,a5,0x30
    8000651c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006520:	6898                	ld	a4,16(s1)
    80006522:	00275703          	lhu	a4,2(a4)
    80006526:	faf71be3          	bne	a4,a5,800064dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000652a:	0001f517          	auipc	a0,0x1f
    8000652e:	bfe50513          	addi	a0,a0,-1026 # 80025128 <disk+0x2128>
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	766080e7          	jalr	1894(ra) # 80000c98 <release>
}
    8000653a:	60e2                	ld	ra,24(sp)
    8000653c:	6442                	ld	s0,16(sp)
    8000653e:	64a2                	ld	s1,8(sp)
    80006540:	6902                	ld	s2,0(sp)
    80006542:	6105                	addi	sp,sp,32
    80006544:	8082                	ret
      panic("virtio_disk_intr status");
    80006546:	00002517          	auipc	a0,0x2
    8000654a:	39250513          	addi	a0,a0,914 # 800088d8 <syscalls+0x3b8>
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	ff0080e7          	jalr	-16(ra) # 8000053e <panic>
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
