
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
    80000130:	54a080e7          	jalr	1354(ra) # 80002676 <either_copyin>
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
    800001d8:	f50080e7          	jalr	-176(ra) # 80002124 <sleep>
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
    80000214:	410080e7          	jalr	1040(ra) # 80002620 <either_copyout>
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
    800002f6:	3da080e7          	jalr	986(ra) # 800026cc <procdump>
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
    8000044a:	fb6080e7          	jalr	-74(ra) # 800023fc <wakeup>
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
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1743+0x160>
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
    800008a4:	b5c080e7          	jalr	-1188(ra) # 800023fc <wakeup>
    
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
    80000930:	7f8080e7          	jalr	2040(ra) # 80002124 <sleep>
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
    80000ed8:	95a080e7          	jalr	-1702(ra) # 8000282e <trapinithart>
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
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1743+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1743+0x160>
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
    80000f50:	8ba080e7          	jalr	-1862(ra) # 80002806 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8da080e7          	jalr	-1830(ra) # 8000282e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	fde080e7          	jalr	-34(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fec080e7          	jalr	-20(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	1c8080e7          	jalr	456(ra) # 80003134 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	858080e7          	jalr	-1960(ra) # 800037cc <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	802080e7          	jalr	-2046(ra) # 8000477e <fileinit>
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
    80001a04:	ef07a783          	lw	a5,-272(a5) # 800088f0 <first.1706>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e3c080e7          	jalr	-452(ra) # 80002846 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ec07ab23          	sw	zero,-298(a5) # 800088f0 <first.1706>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	d28080e7          	jalr	-728(ra) # 8000374c <fsinit>
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
    80001cfe:	480080e7          	jalr	1152(ra) # 8000417a <namei>
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
    80001e3c:	9d8080e7          	jalr	-1576(ra) # 80004810 <filedup>
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
    80001e5e:	b2c080e7          	jalr	-1236(ra) # 80003986 <idup>
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
    80001f4c:	00779693          	slli	a3,a5,0x7
    80001f50:	0000f717          	auipc	a4,0xf
    80001f54:	35070713          	addi	a4,a4,848 # 800112a0 <pid_lock>
    80001f58:	9736                	add	a4,a4,a3
    80001f5a:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &minimum->context);
    80001f5e:	0000f717          	auipc	a4,0xf
    80001f62:	37a70713          	addi	a4,a4,890 # 800112d8 <cpus+0x8>
    80001f66:	00e68b33          	add	s6,a3,a4
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f6a:	00015497          	auipc	s1,0x15
    80001f6e:	56648493          	addi	s1,s1,1382 # 800174d0 <tickslock>
    int chosenFlag = 0;
    80001f72:	4981                	li	s3,0
      c->proc = minimum;
    80001f74:	0000fa17          	auipc	s4,0xf
    80001f78:	32ca0a13          	addi	s4,s4,812 # 800112a0 <pid_lock>
    80001f7c:	9a36                	add	s4,s4,a3
    80001f7e:	a0b5                	j	80001fea <scheduler+0xb6>
        if(minimum == 0)
    80001f80:	08090763          	beqz	s2,8000200e <scheduler+0xda>
        else if(p->ctime < minimum->ctime)
    80001f84:	ff87a503          	lw	a0,-8(a5)
    80001f88:	17092683          	lw	a3,368(s2)
    80001f8c:	00d57363          	bgeu	a0,a3,80001f92 <scheduler+0x5e>
    80001f90:	8932                	mv	s2,a2
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f92:	02977c63          	bgeu	a4,s1,80001fca <scheduler+0x96>
    80001f96:	8542                	mv	a0,a6
    80001f98:	17878793          	addi	a5,a5,376
    80001f9c:	e8878613          	addi	a2,a5,-376
      if(p->state == RUNNABLE)
    80001fa0:	873e                	mv	a4,a5
    80001fa2:	ea07a683          	lw	a3,-352(a5)
    80001fa6:	fcb68de3          	beq	a3,a1,80001f80 <scheduler+0x4c>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001faa:	fe97e7e3          	bltu	a5,s1,80001f98 <scheduler+0x64>
    if(chosenFlag == 0)
    80001fae:	ed11                	bnez	a0,80001fca <scheduler+0x96>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb8:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fbc:	00010797          	auipc	a5,0x10
    80001fc0:	88c78793          	addi	a5,a5,-1908 # 80011848 <proc+0x178>
    int chosenFlag = 0;
    80001fc4:	854e                	mv	a0,s3
    struct proc *minimum = 0;
    80001fc6:	894e                	mv	s2,s3
    80001fc8:	bfd1                	j	80001f9c <scheduler+0x68>
    acquire(&minimum->lock);
    80001fca:	8aca                	mv	s5,s2
    80001fcc:	854a                	mv	a0,s2
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	c16080e7          	jalr	-1002(ra) # 80000be4 <acquire>
    if(minimum->state == RUNNABLE)
    80001fd6:	01892703          	lw	a4,24(s2)
    80001fda:	478d                	li	a5,3
    80001fdc:	00f70a63          	beq	a4,a5,80001ff0 <scheduler+0xbc>
    release(&minimum->lock);
    80001fe0:	8556                	mv	a0,s5
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
      if(p->state == RUNNABLE)
    80001fea:	458d                	li	a1,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fec:	4805                	li	a6,1
    80001fee:	b7c9                	j	80001fb0 <scheduler+0x7c>
      minimum->state = RUNNING;
    80001ff0:	4791                	li	a5,4
    80001ff2:	00f92c23          	sw	a5,24(s2)
      c->proc = minimum;
    80001ff6:	032a3823          	sd	s2,48(s4)
      swtch(&c->context, &minimum->context);
    80001ffa:	06090593          	addi	a1,s2,96
    80001ffe:	855a                	mv	a0,s6
    80002000:	00000097          	auipc	ra,0x0
    80002004:	79c080e7          	jalr	1948(ra) # 8000279c <swtch>
      c->proc = 0;
    80002008:	020a3823          	sd	zero,48(s4)
    8000200c:	bfd1                	j	80001fe0 <scheduler+0xac>
    8000200e:	8932                	mv	s2,a2
    80002010:	b749                	j	80001f92 <scheduler+0x5e>

0000000080002012 <sched>:
{
    80002012:	7179                	addi	sp,sp,-48
    80002014:	f406                	sd	ra,40(sp)
    80002016:	f022                	sd	s0,32(sp)
    80002018:	ec26                	sd	s1,24(sp)
    8000201a:	e84a                	sd	s2,16(sp)
    8000201c:	e44e                	sd	s3,8(sp)
    8000201e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002020:	00000097          	auipc	ra,0x0
    80002024:	990080e7          	jalr	-1648(ra) # 800019b0 <myproc>
    80002028:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	b40080e7          	jalr	-1216(ra) # 80000b6a <holding>
    80002032:	c93d                	beqz	a0,800020a8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	0000f717          	auipc	a4,0xf
    8000203e:	26670713          	addi	a4,a4,614 # 800112a0 <pid_lock>
    80002042:	97ba                	add	a5,a5,a4
    80002044:	0a87a703          	lw	a4,168(a5)
    80002048:	4785                	li	a5,1
    8000204a:	06f71763          	bne	a4,a5,800020b8 <sched+0xa6>
  if(p->state == RUNNING)
    8000204e:	4c98                	lw	a4,24(s1)
    80002050:	4791                	li	a5,4
    80002052:	06f70b63          	beq	a4,a5,800020c8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002056:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000205a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000205c:	efb5                	bnez	a5,800020d8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000205e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002060:	0000f917          	auipc	s2,0xf
    80002064:	24090913          	addi	s2,s2,576 # 800112a0 <pid_lock>
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	97ca                	add	a5,a5,s2
    8000206e:	0ac7a983          	lw	s3,172(a5)
    80002072:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002074:	2781                	sext.w	a5,a5
    80002076:	079e                	slli	a5,a5,0x7
    80002078:	0000f597          	auipc	a1,0xf
    8000207c:	26058593          	addi	a1,a1,608 # 800112d8 <cpus+0x8>
    80002080:	95be                	add	a1,a1,a5
    80002082:	06048513          	addi	a0,s1,96
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	716080e7          	jalr	1814(ra) # 8000279c <swtch>
    8000208e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002090:	2781                	sext.w	a5,a5
    80002092:	079e                	slli	a5,a5,0x7
    80002094:	97ca                	add	a5,a5,s2
    80002096:	0b37a623          	sw	s3,172(a5)
}
    8000209a:	70a2                	ld	ra,40(sp)
    8000209c:	7402                	ld	s0,32(sp)
    8000209e:	64e2                	ld	s1,24(sp)
    800020a0:	6942                	ld	s2,16(sp)
    800020a2:	69a2                	ld	s3,8(sp)
    800020a4:	6145                	addi	sp,sp,48
    800020a6:	8082                	ret
    panic("sched p->lock");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	17050513          	addi	a0,a0,368 # 80008218 <digits+0x1d8>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	48e080e7          	jalr	1166(ra) # 8000053e <panic>
    panic("sched locks");
    800020b8:	00006517          	auipc	a0,0x6
    800020bc:	17050513          	addi	a0,a0,368 # 80008228 <digits+0x1e8>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	47e080e7          	jalr	1150(ra) # 8000053e <panic>
    panic("sched running");
    800020c8:	00006517          	auipc	a0,0x6
    800020cc:	17050513          	addi	a0,a0,368 # 80008238 <digits+0x1f8>
    800020d0:	ffffe097          	auipc	ra,0xffffe
    800020d4:	46e080e7          	jalr	1134(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020d8:	00006517          	auipc	a0,0x6
    800020dc:	17050513          	addi	a0,a0,368 # 80008248 <digits+0x208>
    800020e0:	ffffe097          	auipc	ra,0xffffe
    800020e4:	45e080e7          	jalr	1118(ra) # 8000053e <panic>

00000000800020e8 <yield>:
{
    800020e8:	1101                	addi	sp,sp,-32
    800020ea:	ec06                	sd	ra,24(sp)
    800020ec:	e822                	sd	s0,16(sp)
    800020ee:	e426                	sd	s1,8(sp)
    800020f0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	8be080e7          	jalr	-1858(ra) # 800019b0 <myproc>
    800020fa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002104:	478d                	li	a5,3
    80002106:	cc9c                	sw	a5,24(s1)
  sched();
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	f0a080e7          	jalr	-246(ra) # 80002012 <sched>
  release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b86080e7          	jalr	-1146(ra) # 80000c98 <release>
}
    8000211a:	60e2                	ld	ra,24(sp)
    8000211c:	6442                	ld	s0,16(sp)
    8000211e:	64a2                	ld	s1,8(sp)
    80002120:	6105                	addi	sp,sp,32
    80002122:	8082                	ret

0000000080002124 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002124:	7179                	addi	sp,sp,-48
    80002126:	f406                	sd	ra,40(sp)
    80002128:	f022                	sd	s0,32(sp)
    8000212a:	ec26                	sd	s1,24(sp)
    8000212c:	e84a                	sd	s2,16(sp)
    8000212e:	e44e                	sd	s3,8(sp)
    80002130:	1800                	addi	s0,sp,48
    80002132:	89aa                	mv	s3,a0
    80002134:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	87a080e7          	jalr	-1926(ra) # 800019b0 <myproc>
    8000213e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	aa4080e7          	jalr	-1372(ra) # 80000be4 <acquire>
  release(lk);
    80002148:	854a                	mv	a0,s2
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b4e080e7          	jalr	-1202(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002152:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002156:	4789                	li	a5,2
    80002158:	cc9c                	sw	a5,24(s1)

  sched();
    8000215a:	00000097          	auipc	ra,0x0
    8000215e:	eb8080e7          	jalr	-328(ra) # 80002012 <sched>

  // Tidy up.
  p->chan = 0;
    80002162:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
  acquire(lk);
    80002170:	854a                	mv	a0,s2
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a72080e7          	jalr	-1422(ra) # 80000be4 <acquire>
}
    8000217a:	70a2                	ld	ra,40(sp)
    8000217c:	7402                	ld	s0,32(sp)
    8000217e:	64e2                	ld	s1,24(sp)
    80002180:	6942                	ld	s2,16(sp)
    80002182:	69a2                	ld	s3,8(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <wait>:
{
    80002188:	715d                	addi	sp,sp,-80
    8000218a:	e486                	sd	ra,72(sp)
    8000218c:	e0a2                	sd	s0,64(sp)
    8000218e:	fc26                	sd	s1,56(sp)
    80002190:	f84a                	sd	s2,48(sp)
    80002192:	f44e                	sd	s3,40(sp)
    80002194:	f052                	sd	s4,32(sp)
    80002196:	ec56                	sd	s5,24(sp)
    80002198:	e85a                	sd	s6,16(sp)
    8000219a:	e45e                	sd	s7,8(sp)
    8000219c:	e062                	sd	s8,0(sp)
    8000219e:	0880                	addi	s0,sp,80
    800021a0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	80e080e7          	jalr	-2034(ra) # 800019b0 <myproc>
    800021aa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021ac:	0000f517          	auipc	a0,0xf
    800021b0:	10c50513          	addi	a0,a0,268 # 800112b8 <wait_lock>
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	a30080e7          	jalr	-1488(ra) # 80000be4 <acquire>
    havekids = 0;
    800021bc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021be:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021c0:	00015997          	auipc	s3,0x15
    800021c4:	31098993          	addi	s3,s3,784 # 800174d0 <tickslock>
        havekids = 1;
    800021c8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021ca:	0000fc17          	auipc	s8,0xf
    800021ce:	0eec0c13          	addi	s8,s8,238 # 800112b8 <wait_lock>
    havekids = 0;
    800021d2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021d4:	0000f497          	auipc	s1,0xf
    800021d8:	4fc48493          	addi	s1,s1,1276 # 800116d0 <proc>
    800021dc:	a0bd                	j	8000224a <wait+0xc2>
          pid = np->pid;
    800021de:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021e2:	000b0e63          	beqz	s6,800021fe <wait+0x76>
    800021e6:	4691                	li	a3,4
    800021e8:	02c48613          	addi	a2,s1,44
    800021ec:	85da                	mv	a1,s6
    800021ee:	05093503          	ld	a0,80(s2)
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	480080e7          	jalr	1152(ra) # 80001672 <copyout>
    800021fa:	02054563          	bltz	a0,80002224 <wait+0x9c>
          freeproc(np);
    800021fe:	8526                	mv	a0,s1
    80002200:	00000097          	auipc	ra,0x0
    80002204:	962080e7          	jalr	-1694(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a8e080e7          	jalr	-1394(ra) # 80000c98 <release>
          release(&wait_lock);
    80002212:	0000f517          	auipc	a0,0xf
    80002216:	0a650513          	addi	a0,a0,166 # 800112b8 <wait_lock>
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
          return pid;
    80002222:	a09d                	j	80002288 <wait+0x100>
            release(&np->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a72080e7          	jalr	-1422(ra) # 80000c98 <release>
            release(&wait_lock);
    8000222e:	0000f517          	auipc	a0,0xf
    80002232:	08a50513          	addi	a0,a0,138 # 800112b8 <wait_lock>
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a62080e7          	jalr	-1438(ra) # 80000c98 <release>
            return -1;
    8000223e:	59fd                	li	s3,-1
    80002240:	a0a1                	j	80002288 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002242:	17848493          	addi	s1,s1,376
    80002246:	03348463          	beq	s1,s3,8000226e <wait+0xe6>
      if(np->parent == p){
    8000224a:	7c9c                	ld	a5,56(s1)
    8000224c:	ff279be3          	bne	a5,s2,80002242 <wait+0xba>
        acquire(&np->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	992080e7          	jalr	-1646(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000225a:	4c9c                	lw	a5,24(s1)
    8000225c:	f94781e3          	beq	a5,s4,800021de <wait+0x56>
        release(&np->lock);
    80002260:	8526                	mv	a0,s1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
        havekids = 1;
    8000226a:	8756                	mv	a4,s5
    8000226c:	bfd9                	j	80002242 <wait+0xba>
    if(!havekids || p->killed){
    8000226e:	c701                	beqz	a4,80002276 <wait+0xee>
    80002270:	02892783          	lw	a5,40(s2)
    80002274:	c79d                	beqz	a5,800022a2 <wait+0x11a>
      release(&wait_lock);
    80002276:	0000f517          	auipc	a0,0xf
    8000227a:	04250513          	addi	a0,a0,66 # 800112b8 <wait_lock>
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a1a080e7          	jalr	-1510(ra) # 80000c98 <release>
      return -1;
    80002286:	59fd                	li	s3,-1
}
    80002288:	854e                	mv	a0,s3
    8000228a:	60a6                	ld	ra,72(sp)
    8000228c:	6406                	ld	s0,64(sp)
    8000228e:	74e2                	ld	s1,56(sp)
    80002290:	7942                	ld	s2,48(sp)
    80002292:	79a2                	ld	s3,40(sp)
    80002294:	7a02                	ld	s4,32(sp)
    80002296:	6ae2                	ld	s5,24(sp)
    80002298:	6b42                	ld	s6,16(sp)
    8000229a:	6ba2                	ld	s7,8(sp)
    8000229c:	6c02                	ld	s8,0(sp)
    8000229e:	6161                	addi	sp,sp,80
    800022a0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022a2:	85e2                	mv	a1,s8
    800022a4:	854a                	mv	a0,s2
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	e7e080e7          	jalr	-386(ra) # 80002124 <sleep>
    havekids = 0;
    800022ae:	b715                	j	800021d2 <wait+0x4a>

00000000800022b0 <waitx>:
{
    800022b0:	711d                	addi	sp,sp,-96
    800022b2:	ec86                	sd	ra,88(sp)
    800022b4:	e8a2                	sd	s0,80(sp)
    800022b6:	e4a6                	sd	s1,72(sp)
    800022b8:	e0ca                	sd	s2,64(sp)
    800022ba:	fc4e                	sd	s3,56(sp)
    800022bc:	f852                	sd	s4,48(sp)
    800022be:	f456                	sd	s5,40(sp)
    800022c0:	f05a                	sd	s6,32(sp)
    800022c2:	ec5e                	sd	s7,24(sp)
    800022c4:	e862                	sd	s8,16(sp)
    800022c6:	e466                	sd	s9,8(sp)
    800022c8:	e06a                	sd	s10,0(sp)
    800022ca:	1080                	addi	s0,sp,96
    800022cc:	8b2a                	mv	s6,a0
    800022ce:	8c2e                	mv	s8,a1
    800022d0:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	6de080e7          	jalr	1758(ra) # 800019b0 <myproc>
    800022da:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022dc:	0000f517          	auipc	a0,0xf
    800022e0:	fdc50513          	addi	a0,a0,-36 # 800112b8 <wait_lock>
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	900080e7          	jalr	-1792(ra) # 80000be4 <acquire>
    havekids = 0;
    800022ec:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800022ee:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	1e098993          	addi	s3,s3,480 # 800174d0 <tickslock>
        havekids = 1;
    800022f8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022fa:	0000fd17          	auipc	s10,0xf
    800022fe:	fbed0d13          	addi	s10,s10,-66 # 800112b8 <wait_lock>
    havekids = 0;
    80002302:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002304:	0000f497          	auipc	s1,0xf
    80002308:	3cc48493          	addi	s1,s1,972 # 800116d0 <proc>
    8000230c:	a059                	j	80002392 <waitx+0xe2>
          pid = np->pid;
    8000230e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002312:	16c4a703          	lw	a4,364(s1)
    80002316:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000231a:	1704a783          	lw	a5,368(s1)
    8000231e:	9f3d                	addw	a4,a4,a5
    80002320:	1744a783          	lw	a5,372(s1)
    80002324:	9f99                	subw	a5,a5,a4
    80002326:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000232a:	000b0e63          	beqz	s6,80002346 <waitx+0x96>
    8000232e:	4691                	li	a3,4
    80002330:	02c48613          	addi	a2,s1,44
    80002334:	85da                	mv	a1,s6
    80002336:	05093503          	ld	a0,80(s2)
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	338080e7          	jalr	824(ra) # 80001672 <copyout>
    80002342:	02054563          	bltz	a0,8000236c <waitx+0xbc>
          freeproc(np);
    80002346:	8526                	mv	a0,s1
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	81a080e7          	jalr	-2022(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	946080e7          	jalr	-1722(ra) # 80000c98 <release>
          release(&wait_lock);
    8000235a:	0000f517          	auipc	a0,0xf
    8000235e:	f5e50513          	addi	a0,a0,-162 # 800112b8 <wait_lock>
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
          return pid;
    8000236a:	a09d                	j	800023d0 <waitx+0x120>
            release(&np->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	92a080e7          	jalr	-1750(ra) # 80000c98 <release>
            release(&wait_lock);
    80002376:	0000f517          	auipc	a0,0xf
    8000237a:	f4250513          	addi	a0,a0,-190 # 800112b8 <wait_lock>
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
            return -1;
    80002386:	59fd                	li	s3,-1
    80002388:	a0a1                	j	800023d0 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    8000238a:	17848493          	addi	s1,s1,376
    8000238e:	03348463          	beq	s1,s3,800023b6 <waitx+0x106>
      if(np->parent == p){
    80002392:	7c9c                	ld	a5,56(s1)
    80002394:	ff279be3          	bne	a5,s2,8000238a <waitx+0xda>
        acquire(&np->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	84a080e7          	jalr	-1974(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023a2:	4c9c                	lw	a5,24(s1)
    800023a4:	f74785e3          	beq	a5,s4,8000230e <waitx+0x5e>
        release(&np->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	8ee080e7          	jalr	-1810(ra) # 80000c98 <release>
        havekids = 1;
    800023b2:	8756                	mv	a4,s5
    800023b4:	bfd9                	j	8000238a <waitx+0xda>
    if(!havekids || p->killed){
    800023b6:	c701                	beqz	a4,800023be <waitx+0x10e>
    800023b8:	02892783          	lw	a5,40(s2)
    800023bc:	cb8d                	beqz	a5,800023ee <waitx+0x13e>
      release(&wait_lock);
    800023be:	0000f517          	auipc	a0,0xf
    800023c2:	efa50513          	addi	a0,a0,-262 # 800112b8 <wait_lock>
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
      return -1;
    800023ce:	59fd                	li	s3,-1
}
    800023d0:	854e                	mv	a0,s3
    800023d2:	60e6                	ld	ra,88(sp)
    800023d4:	6446                	ld	s0,80(sp)
    800023d6:	64a6                	ld	s1,72(sp)
    800023d8:	6906                	ld	s2,64(sp)
    800023da:	79e2                	ld	s3,56(sp)
    800023dc:	7a42                	ld	s4,48(sp)
    800023de:	7aa2                	ld	s5,40(sp)
    800023e0:	7b02                	ld	s6,32(sp)
    800023e2:	6be2                	ld	s7,24(sp)
    800023e4:	6c42                	ld	s8,16(sp)
    800023e6:	6ca2                	ld	s9,8(sp)
    800023e8:	6d02                	ld	s10,0(sp)
    800023ea:	6125                	addi	sp,sp,96
    800023ec:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023ee:	85ea                	mv	a1,s10
    800023f0:	854a                	mv	a0,s2
    800023f2:	00000097          	auipc	ra,0x0
    800023f6:	d32080e7          	jalr	-718(ra) # 80002124 <sleep>
    havekids = 0;
    800023fa:	b721                	j	80002302 <waitx+0x52>

00000000800023fc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023fc:	7139                	addi	sp,sp,-64
    800023fe:	fc06                	sd	ra,56(sp)
    80002400:	f822                	sd	s0,48(sp)
    80002402:	f426                	sd	s1,40(sp)
    80002404:	f04a                	sd	s2,32(sp)
    80002406:	ec4e                	sd	s3,24(sp)
    80002408:	e852                	sd	s4,16(sp)
    8000240a:	e456                	sd	s5,8(sp)
    8000240c:	0080                	addi	s0,sp,64
    8000240e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002410:	0000f497          	auipc	s1,0xf
    80002414:	2c048493          	addi	s1,s1,704 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002418:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000241a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241c:	00015917          	auipc	s2,0x15
    80002420:	0b490913          	addi	s2,s2,180 # 800174d0 <tickslock>
    80002424:	a821                	j	8000243c <wakeup+0x40>
        p->state = RUNNABLE;
    80002426:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002434:	17848493          	addi	s1,s1,376
    80002438:	03248463          	beq	s1,s2,80002460 <wakeup+0x64>
    if(p != myproc()){
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	574080e7          	jalr	1396(ra) # 800019b0 <myproc>
    80002444:	fea488e3          	beq	s1,a0,80002434 <wakeup+0x38>
      acquire(&p->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	79a080e7          	jalr	1946(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002452:	4c9c                	lw	a5,24(s1)
    80002454:	fd379be3          	bne	a5,s3,8000242a <wakeup+0x2e>
    80002458:	709c                	ld	a5,32(s1)
    8000245a:	fd4798e3          	bne	a5,s4,8000242a <wakeup+0x2e>
    8000245e:	b7e1                	j	80002426 <wakeup+0x2a>
    }
  }
}
    80002460:	70e2                	ld	ra,56(sp)
    80002462:	7442                	ld	s0,48(sp)
    80002464:	74a2                	ld	s1,40(sp)
    80002466:	7902                	ld	s2,32(sp)
    80002468:	69e2                	ld	s3,24(sp)
    8000246a:	6a42                	ld	s4,16(sp)
    8000246c:	6aa2                	ld	s5,8(sp)
    8000246e:	6121                	addi	sp,sp,64
    80002470:	8082                	ret

0000000080002472 <reparent>:
{
    80002472:	7179                	addi	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	ec26                	sd	s1,24(sp)
    8000247a:	e84a                	sd	s2,16(sp)
    8000247c:	e44e                	sd	s3,8(sp)
    8000247e:	e052                	sd	s4,0(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002484:	0000f497          	auipc	s1,0xf
    80002488:	24c48493          	addi	s1,s1,588 # 800116d0 <proc>
      pp->parent = initproc;
    8000248c:	00007a17          	auipc	s4,0x7
    80002490:	b9ca0a13          	addi	s4,s4,-1124 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002494:	00015997          	auipc	s3,0x15
    80002498:	03c98993          	addi	s3,s3,60 # 800174d0 <tickslock>
    8000249c:	a029                	j	800024a6 <reparent+0x34>
    8000249e:	17848493          	addi	s1,s1,376
    800024a2:	01348d63          	beq	s1,s3,800024bc <reparent+0x4a>
    if(pp->parent == p){
    800024a6:	7c9c                	ld	a5,56(s1)
    800024a8:	ff279be3          	bne	a5,s2,8000249e <reparent+0x2c>
      pp->parent = initproc;
    800024ac:	000a3503          	ld	a0,0(s4)
    800024b0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	f4a080e7          	jalr	-182(ra) # 800023fc <wakeup>
    800024ba:	b7d5                	j	8000249e <reparent+0x2c>
}
    800024bc:	70a2                	ld	ra,40(sp)
    800024be:	7402                	ld	s0,32(sp)
    800024c0:	64e2                	ld	s1,24(sp)
    800024c2:	6942                	ld	s2,16(sp)
    800024c4:	69a2                	ld	s3,8(sp)
    800024c6:	6a02                	ld	s4,0(sp)
    800024c8:	6145                	addi	sp,sp,48
    800024ca:	8082                	ret

00000000800024cc <exit>:
{
    800024cc:	7179                	addi	sp,sp,-48
    800024ce:	f406                	sd	ra,40(sp)
    800024d0:	f022                	sd	s0,32(sp)
    800024d2:	ec26                	sd	s1,24(sp)
    800024d4:	e84a                	sd	s2,16(sp)
    800024d6:	e44e                	sd	s3,8(sp)
    800024d8:	e052                	sd	s4,0(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	4d2080e7          	jalr	1234(ra) # 800019b0 <myproc>
    800024e6:	89aa                	mv	s3,a0
  if(p == initproc)
    800024e8:	00007797          	auipc	a5,0x7
    800024ec:	b407b783          	ld	a5,-1216(a5) # 80009028 <initproc>
    800024f0:	0d050493          	addi	s1,a0,208
    800024f4:	15050913          	addi	s2,a0,336
    800024f8:	02a79363          	bne	a5,a0,8000251e <exit+0x52>
    panic("init exiting");
    800024fc:	00006517          	auipc	a0,0x6
    80002500:	d6450513          	addi	a0,a0,-668 # 80008260 <digits+0x220>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	03a080e7          	jalr	58(ra) # 8000053e <panic>
      fileclose(f);
    8000250c:	00002097          	auipc	ra,0x2
    80002510:	356080e7          	jalr	854(ra) # 80004862 <fileclose>
      p->ofile[fd] = 0;
    80002514:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002518:	04a1                	addi	s1,s1,8
    8000251a:	01248563          	beq	s1,s2,80002524 <exit+0x58>
    if(p->ofile[fd]){
    8000251e:	6088                	ld	a0,0(s1)
    80002520:	f575                	bnez	a0,8000250c <exit+0x40>
    80002522:	bfdd                	j	80002518 <exit+0x4c>
  begin_op();
    80002524:	00002097          	auipc	ra,0x2
    80002528:	e72080e7          	jalr	-398(ra) # 80004396 <begin_op>
  iput(p->cwd);
    8000252c:	1509b503          	ld	a0,336(s3)
    80002530:	00001097          	auipc	ra,0x1
    80002534:	64e080e7          	jalr	1614(ra) # 80003b7e <iput>
  end_op();
    80002538:	00002097          	auipc	ra,0x2
    8000253c:	ede080e7          	jalr	-290(ra) # 80004416 <end_op>
  p->cwd = 0;
    80002540:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002544:	0000f497          	auipc	s1,0xf
    80002548:	d7448493          	addi	s1,s1,-652 # 800112b8 <wait_lock>
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	696080e7          	jalr	1686(ra) # 80000be4 <acquire>
  reparent(p);
    80002556:	854e                	mv	a0,s3
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	f1a080e7          	jalr	-230(ra) # 80002472 <reparent>
  wakeup(p->parent);
    80002560:	0389b503          	ld	a0,56(s3)
    80002564:	00000097          	auipc	ra,0x0
    80002568:	e98080e7          	jalr	-360(ra) # 800023fc <wakeup>
  acquire(&p->lock);
    8000256c:	854e                	mv	a0,s3
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	676080e7          	jalr	1654(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002576:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000257a:	4795                	li	a5,5
    8000257c:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002580:	00007797          	auipc	a5,0x7
    80002584:	ab07a783          	lw	a5,-1360(a5) # 80009030 <ticks>
    80002588:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
  sched();
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	a7c080e7          	jalr	-1412(ra) # 80002012 <sched>
  panic("zombie exit");
    8000259e:	00006517          	auipc	a0,0x6
    800025a2:	cd250513          	addi	a0,a0,-814 # 80008270 <digits+0x230>
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>

00000000800025ae <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025be:	0000f497          	auipc	s1,0xf
    800025c2:	11248493          	addi	s1,s1,274 # 800116d0 <proc>
    800025c6:	00015997          	auipc	s3,0x15
    800025ca:	f0a98993          	addi	s3,s3,-246 # 800174d0 <tickslock>
    acquire(&p->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	614080e7          	jalr	1556(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025d8:	589c                	lw	a5,48(s1)
    800025da:	01278d63          	beq	a5,s2,800025f4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e8:	17848493          	addi	s1,s1,376
    800025ec:	ff3491e3          	bne	s1,s3,800025ce <kill+0x20>
  }
  return -1;
    800025f0:	557d                	li	a0,-1
    800025f2:	a829                	j	8000260c <kill+0x5e>
      p->killed = 1;
    800025f4:	4785                	li	a5,1
    800025f6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025f8:	4c98                	lw	a4,24(s1)
    800025fa:	4789                	li	a5,2
    800025fc:	00f70f63          	beq	a4,a5,8000261a <kill+0x6c>
      release(&p->lock);
    80002600:	8526                	mv	a0,s1
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	696080e7          	jalr	1686(ra) # 80000c98 <release>
      return 0;
    8000260a:	4501                	li	a0,0
}
    8000260c:	70a2                	ld	ra,40(sp)
    8000260e:	7402                	ld	s0,32(sp)
    80002610:	64e2                	ld	s1,24(sp)
    80002612:	6942                	ld	s2,16(sp)
    80002614:	69a2                	ld	s3,8(sp)
    80002616:	6145                	addi	sp,sp,48
    80002618:	8082                	ret
        p->state = RUNNABLE;
    8000261a:	478d                	li	a5,3
    8000261c:	cc9c                	sw	a5,24(s1)
    8000261e:	b7cd                	j	80002600 <kill+0x52>

0000000080002620 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002620:	7179                	addi	sp,sp,-48
    80002622:	f406                	sd	ra,40(sp)
    80002624:	f022                	sd	s0,32(sp)
    80002626:	ec26                	sd	s1,24(sp)
    80002628:	e84a                	sd	s2,16(sp)
    8000262a:	e44e                	sd	s3,8(sp)
    8000262c:	e052                	sd	s4,0(sp)
    8000262e:	1800                	addi	s0,sp,48
    80002630:	84aa                	mv	s1,a0
    80002632:	892e                	mv	s2,a1
    80002634:	89b2                	mv	s3,a2
    80002636:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002638:	fffff097          	auipc	ra,0xfffff
    8000263c:	378080e7          	jalr	888(ra) # 800019b0 <myproc>
  if(user_dst){
    80002640:	c08d                	beqz	s1,80002662 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002642:	86d2                	mv	a3,s4
    80002644:	864e                	mv	a2,s3
    80002646:	85ca                	mv	a1,s2
    80002648:	6928                	ld	a0,80(a0)
    8000264a:	fffff097          	auipc	ra,0xfffff
    8000264e:	028080e7          	jalr	40(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002652:	70a2                	ld	ra,40(sp)
    80002654:	7402                	ld	s0,32(sp)
    80002656:	64e2                	ld	s1,24(sp)
    80002658:	6942                	ld	s2,16(sp)
    8000265a:	69a2                	ld	s3,8(sp)
    8000265c:	6a02                	ld	s4,0(sp)
    8000265e:	6145                	addi	sp,sp,48
    80002660:	8082                	ret
    memmove((char *)dst, src, len);
    80002662:	000a061b          	sext.w	a2,s4
    80002666:	85ce                	mv	a1,s3
    80002668:	854a                	mv	a0,s2
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	6d6080e7          	jalr	1750(ra) # 80000d40 <memmove>
    return 0;
    80002672:	8526                	mv	a0,s1
    80002674:	bff9                	j	80002652 <either_copyout+0x32>

0000000080002676 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002676:	7179                	addi	sp,sp,-48
    80002678:	f406                	sd	ra,40(sp)
    8000267a:	f022                	sd	s0,32(sp)
    8000267c:	ec26                	sd	s1,24(sp)
    8000267e:	e84a                	sd	s2,16(sp)
    80002680:	e44e                	sd	s3,8(sp)
    80002682:	e052                	sd	s4,0(sp)
    80002684:	1800                	addi	s0,sp,48
    80002686:	892a                	mv	s2,a0
    80002688:	84ae                	mv	s1,a1
    8000268a:	89b2                	mv	s3,a2
    8000268c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000268e:	fffff097          	auipc	ra,0xfffff
    80002692:	322080e7          	jalr	802(ra) # 800019b0 <myproc>
  if(user_src){
    80002696:	c08d                	beqz	s1,800026b8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002698:	86d2                	mv	a3,s4
    8000269a:	864e                	mv	a2,s3
    8000269c:	85ca                	mv	a1,s2
    8000269e:	6928                	ld	a0,80(a0)
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	05e080e7          	jalr	94(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026a8:	70a2                	ld	ra,40(sp)
    800026aa:	7402                	ld	s0,32(sp)
    800026ac:	64e2                	ld	s1,24(sp)
    800026ae:	6942                	ld	s2,16(sp)
    800026b0:	69a2                	ld	s3,8(sp)
    800026b2:	6a02                	ld	s4,0(sp)
    800026b4:	6145                	addi	sp,sp,48
    800026b6:	8082                	ret
    memmove(dst, (char*)src, len);
    800026b8:	000a061b          	sext.w	a2,s4
    800026bc:	85ce                	mv	a1,s3
    800026be:	854a                	mv	a0,s2
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	680080e7          	jalr	1664(ra) # 80000d40 <memmove>
    return 0;
    800026c8:	8526                	mv	a0,s1
    800026ca:	bff9                	j	800026a8 <either_copyin+0x32>

00000000800026cc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026cc:	715d                	addi	sp,sp,-80
    800026ce:	e486                	sd	ra,72(sp)
    800026d0:	e0a2                	sd	s0,64(sp)
    800026d2:	fc26                	sd	s1,56(sp)
    800026d4:	f84a                	sd	s2,48(sp)
    800026d6:	f44e                	sd	s3,40(sp)
    800026d8:	f052                	sd	s4,32(sp)
    800026da:	ec56                	sd	s5,24(sp)
    800026dc:	e85a                	sd	s6,16(sp)
    800026de:	e45e                	sd	s7,8(sp)
    800026e0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026e2:	00006517          	auipc	a0,0x6
    800026e6:	d3e50513          	addi	a0,a0,-706 # 80008420 <states.1743+0x160>
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	e9e080e7          	jalr	-354(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026f2:	0000f497          	auipc	s1,0xf
    800026f6:	13648493          	addi	s1,s1,310 # 80011828 <proc+0x158>
    800026fa:	00015917          	auipc	s2,0x15
    800026fe:	f2e90913          	addi	s2,s2,-210 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002702:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002704:	00006997          	auipc	s3,0x6
    80002708:	b7c98993          	addi	s3,s3,-1156 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000270c:	00006a97          	auipc	s5,0x6
    80002710:	b7ca8a93          	addi	s5,s5,-1156 # 80008288 <digits+0x248>
    printf("\n");
    80002714:	00006a17          	auipc	s4,0x6
    80002718:	d0ca0a13          	addi	s4,s4,-756 # 80008420 <states.1743+0x160>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271c:	00006b97          	auipc	s7,0x6
    80002720:	ba4b8b93          	addi	s7,s7,-1116 # 800082c0 <states.1743>
    80002724:	a00d                	j	80002746 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002726:	ed86a583          	lw	a1,-296(a3)
    8000272a:	8556                	mv	a0,s5
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	e5c080e7          	jalr	-420(ra) # 80000588 <printf>
    printf("\n");
    80002734:	8552                	mv	a0,s4
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	e52080e7          	jalr	-430(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000273e:	17848493          	addi	s1,s1,376
    80002742:	03248163          	beq	s1,s2,80002764 <procdump+0x98>
    if(p->state == UNUSED)
    80002746:	86a6                	mv	a3,s1
    80002748:	ec04a783          	lw	a5,-320(s1)
    8000274c:	dbed                	beqz	a5,8000273e <procdump+0x72>
      state = "???";
    8000274e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002750:	fcfb6be3          	bltu	s6,a5,80002726 <procdump+0x5a>
    80002754:	1782                	slli	a5,a5,0x20
    80002756:	9381                	srli	a5,a5,0x20
    80002758:	078e                	slli	a5,a5,0x3
    8000275a:	97de                	add	a5,a5,s7
    8000275c:	6390                	ld	a2,0(a5)
    8000275e:	f661                	bnez	a2,80002726 <procdump+0x5a>
      state = "???";
    80002760:	864e                	mv	a2,s3
    80002762:	b7d1                	j	80002726 <procdump+0x5a>
  }
}
    80002764:	60a6                	ld	ra,72(sp)
    80002766:	6406                	ld	s0,64(sp)
    80002768:	74e2                	ld	s1,56(sp)
    8000276a:	7942                	ld	s2,48(sp)
    8000276c:	79a2                	ld	s3,40(sp)
    8000276e:	7a02                	ld	s4,32(sp)
    80002770:	6ae2                	ld	s5,24(sp)
    80002772:	6b42                	ld	s6,16(sp)
    80002774:	6ba2                	ld	s7,8(sp)
    80002776:	6161                	addi	sp,sp,80
    80002778:	8082                	ret

000000008000277a <trace>:

// enabling tracing for the current process
void
trace(int trace_mask)
{
    8000277a:	1101                	addi	sp,sp,-32
    8000277c:	ec06                	sd	ra,24(sp)
    8000277e:	e822                	sd	s0,16(sp)
    80002780:	e426                	sd	s1,8(sp)
    80002782:	1000                	addi	s0,sp,32
    80002784:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002786:	fffff097          	auipc	ra,0xfffff
    8000278a:	22a080e7          	jalr	554(ra) # 800019b0 <myproc>
  p->trace_mask = trace_mask;
    8000278e:	16952423          	sw	s1,360(a0)
    80002792:	60e2                	ld	ra,24(sp)
    80002794:	6442                	ld	s0,16(sp)
    80002796:	64a2                	ld	s1,8(sp)
    80002798:	6105                	addi	sp,sp,32
    8000279a:	8082                	ret

000000008000279c <swtch>:
    8000279c:	00153023          	sd	ra,0(a0)
    800027a0:	00253423          	sd	sp,8(a0)
    800027a4:	e900                	sd	s0,16(a0)
    800027a6:	ed04                	sd	s1,24(a0)
    800027a8:	03253023          	sd	s2,32(a0)
    800027ac:	03353423          	sd	s3,40(a0)
    800027b0:	03453823          	sd	s4,48(a0)
    800027b4:	03553c23          	sd	s5,56(a0)
    800027b8:	05653023          	sd	s6,64(a0)
    800027bc:	05753423          	sd	s7,72(a0)
    800027c0:	05853823          	sd	s8,80(a0)
    800027c4:	05953c23          	sd	s9,88(a0)
    800027c8:	07a53023          	sd	s10,96(a0)
    800027cc:	07b53423          	sd	s11,104(a0)
    800027d0:	0005b083          	ld	ra,0(a1)
    800027d4:	0085b103          	ld	sp,8(a1)
    800027d8:	6980                	ld	s0,16(a1)
    800027da:	6d84                	ld	s1,24(a1)
    800027dc:	0205b903          	ld	s2,32(a1)
    800027e0:	0285b983          	ld	s3,40(a1)
    800027e4:	0305ba03          	ld	s4,48(a1)
    800027e8:	0385ba83          	ld	s5,56(a1)
    800027ec:	0405bb03          	ld	s6,64(a1)
    800027f0:	0485bb83          	ld	s7,72(a1)
    800027f4:	0505bc03          	ld	s8,80(a1)
    800027f8:	0585bc83          	ld	s9,88(a1)
    800027fc:	0605bd03          	ld	s10,96(a1)
    80002800:	0685bd83          	ld	s11,104(a1)
    80002804:	8082                	ret

0000000080002806 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002806:	1141                	addi	sp,sp,-16
    80002808:	e406                	sd	ra,8(sp)
    8000280a:	e022                	sd	s0,0(sp)
    8000280c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000280e:	00006597          	auipc	a1,0x6
    80002812:	ae258593          	addi	a1,a1,-1310 # 800082f0 <states.1743+0x30>
    80002816:	00015517          	auipc	a0,0x15
    8000281a:	cba50513          	addi	a0,a0,-838 # 800174d0 <tickslock>
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	336080e7          	jalr	822(ra) # 80000b54 <initlock>
}
    80002826:	60a2                	ld	ra,8(sp)
    80002828:	6402                	ld	s0,0(sp)
    8000282a:	0141                	addi	sp,sp,16
    8000282c:	8082                	ret

000000008000282e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000282e:	1141                	addi	sp,sp,-16
    80002830:	e422                	sd	s0,8(sp)
    80002832:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002834:	00003797          	auipc	a5,0x3
    80002838:	64c78793          	addi	a5,a5,1612 # 80005e80 <kernelvec>
    8000283c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002840:	6422                	ld	s0,8(sp)
    80002842:	0141                	addi	sp,sp,16
    80002844:	8082                	ret

0000000080002846 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002846:	1141                	addi	sp,sp,-16
    80002848:	e406                	sd	ra,8(sp)
    8000284a:	e022                	sd	s0,0(sp)
    8000284c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	162080e7          	jalr	354(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002856:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000285a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000285c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002860:	00004617          	auipc	a2,0x4
    80002864:	7a060613          	addi	a2,a2,1952 # 80007000 <_trampoline>
    80002868:	00004697          	auipc	a3,0x4
    8000286c:	79868693          	addi	a3,a3,1944 # 80007000 <_trampoline>
    80002870:	8e91                	sub	a3,a3,a2
    80002872:	040007b7          	lui	a5,0x4000
    80002876:	17fd                	addi	a5,a5,-1
    80002878:	07b2                	slli	a5,a5,0xc
    8000287a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000287c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002880:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002882:	180026f3          	csrr	a3,satp
    80002886:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002888:	6d38                	ld	a4,88(a0)
    8000288a:	6134                	ld	a3,64(a0)
    8000288c:	6585                	lui	a1,0x1
    8000288e:	96ae                	add	a3,a3,a1
    80002890:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002892:	6d38                	ld	a4,88(a0)
    80002894:	00000697          	auipc	a3,0x0
    80002898:	14668693          	addi	a3,a3,326 # 800029da <usertrap>
    8000289c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000289e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028a0:	8692                	mv	a3,tp
    800028a2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028a8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028ac:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028b4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b6:	6f18                	ld	a4,24(a4)
    800028b8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028bc:	692c                	ld	a1,80(a0)
    800028be:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028c0:	00004717          	auipc	a4,0x4
    800028c4:	7d070713          	addi	a4,a4,2000 # 80007090 <userret>
    800028c8:	8f11                	sub	a4,a4,a2
    800028ca:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028cc:	577d                	li	a4,-1
    800028ce:	177e                	slli	a4,a4,0x3f
    800028d0:	8dd9                	or	a1,a1,a4
    800028d2:	02000537          	lui	a0,0x2000
    800028d6:	157d                	addi	a0,a0,-1
    800028d8:	0536                	slli	a0,a0,0xd
    800028da:	9782                	jalr	a5
}
    800028dc:	60a2                	ld	ra,8(sp)
    800028de:	6402                	ld	s0,0(sp)
    800028e0:	0141                	addi	sp,sp,16
    800028e2:	8082                	ret

00000000800028e4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028e4:	1101                	addi	sp,sp,-32
    800028e6:	ec06                	sd	ra,24(sp)
    800028e8:	e822                	sd	s0,16(sp)
    800028ea:	e426                	sd	s1,8(sp)
    800028ec:	e04a                	sd	s2,0(sp)
    800028ee:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028f0:	00015917          	auipc	s2,0x15
    800028f4:	be090913          	addi	s2,s2,-1056 # 800174d0 <tickslock>
    800028f8:	854a                	mv	a0,s2
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	2ea080e7          	jalr	746(ra) # 80000be4 <acquire>
  ticks++;
    80002902:	00006497          	auipc	s1,0x6
    80002906:	72e48493          	addi	s1,s1,1838 # 80009030 <ticks>
    8000290a:	409c                	lw	a5,0(s1)
    8000290c:	2785                	addiw	a5,a5,1
    8000290e:	c09c                	sw	a5,0(s1)
  update_time();
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	5c6080e7          	jalr	1478(ra) # 80001ed6 <update_time>
  wakeup(&ticks);
    80002918:	8526                	mv	a0,s1
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	ae2080e7          	jalr	-1310(ra) # 800023fc <wakeup>
  release(&tickslock);
    80002922:	854a                	mv	a0,s2
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	374080e7          	jalr	884(ra) # 80000c98 <release>
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	64a2                	ld	s1,8(sp)
    80002932:	6902                	ld	s2,0(sp)
    80002934:	6105                	addi	sp,sp,32
    80002936:	8082                	ret

0000000080002938 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002938:	1101                	addi	sp,sp,-32
    8000293a:	ec06                	sd	ra,24(sp)
    8000293c:	e822                	sd	s0,16(sp)
    8000293e:	e426                	sd	s1,8(sp)
    80002940:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002942:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002946:	00074d63          	bltz	a4,80002960 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000294a:	57fd                	li	a5,-1
    8000294c:	17fe                	slli	a5,a5,0x3f
    8000294e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002950:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002952:	06f70363          	beq	a4,a5,800029b8 <devintr+0x80>
  }
}
    80002956:	60e2                	ld	ra,24(sp)
    80002958:	6442                	ld	s0,16(sp)
    8000295a:	64a2                	ld	s1,8(sp)
    8000295c:	6105                	addi	sp,sp,32
    8000295e:	8082                	ret
     (scause & 0xff) == 9){
    80002960:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002964:	46a5                	li	a3,9
    80002966:	fed792e3          	bne	a5,a3,8000294a <devintr+0x12>
    int irq = plic_claim();
    8000296a:	00003097          	auipc	ra,0x3
    8000296e:	61e080e7          	jalr	1566(ra) # 80005f88 <plic_claim>
    80002972:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002974:	47a9                	li	a5,10
    80002976:	02f50763          	beq	a0,a5,800029a4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000297a:	4785                	li	a5,1
    8000297c:	02f50963          	beq	a0,a5,800029ae <devintr+0x76>
    return 1;
    80002980:	4505                	li	a0,1
    } else if(irq){
    80002982:	d8f1                	beqz	s1,80002956 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002984:	85a6                	mv	a1,s1
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	97250513          	addi	a0,a0,-1678 # 800082f8 <states.1743+0x38>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	bfa080e7          	jalr	-1030(ra) # 80000588 <printf>
      plic_complete(irq);
    80002996:	8526                	mv	a0,s1
    80002998:	00003097          	auipc	ra,0x3
    8000299c:	614080e7          	jalr	1556(ra) # 80005fac <plic_complete>
    return 1;
    800029a0:	4505                	li	a0,1
    800029a2:	bf55                	j	80002956 <devintr+0x1e>
      uartintr();
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	004080e7          	jalr	4(ra) # 800009a8 <uartintr>
    800029ac:	b7ed                	j	80002996 <devintr+0x5e>
      virtio_disk_intr();
    800029ae:	00004097          	auipc	ra,0x4
    800029b2:	ade080e7          	jalr	-1314(ra) # 8000648c <virtio_disk_intr>
    800029b6:	b7c5                	j	80002996 <devintr+0x5e>
    if(cpuid() == 0){
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	fcc080e7          	jalr	-52(ra) # 80001984 <cpuid>
    800029c0:	c901                	beqz	a0,800029d0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029c8:	14479073          	csrw	sip,a5
    return 2;
    800029cc:	4509                	li	a0,2
    800029ce:	b761                	j	80002956 <devintr+0x1e>
      clockintr();
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	f14080e7          	jalr	-236(ra) # 800028e4 <clockintr>
    800029d8:	b7ed                	j	800029c2 <devintr+0x8a>

00000000800029da <usertrap>:
{
    800029da:	1101                	addi	sp,sp,-32
    800029dc:	ec06                	sd	ra,24(sp)
    800029de:	e822                	sd	s0,16(sp)
    800029e0:	e426                	sd	s1,8(sp)
    800029e2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029e8:	1007f793          	andi	a5,a5,256
    800029ec:	e3a5                	bnez	a5,80002a4c <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ee:	00003797          	auipc	a5,0x3
    800029f2:	49278793          	addi	a5,a5,1170 # 80005e80 <kernelvec>
    800029f6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	fb6080e7          	jalr	-74(ra) # 800019b0 <myproc>
    80002a02:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a04:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	14102773          	csrr	a4,sepc
    80002a0a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a10:	47a1                	li	a5,8
    80002a12:	04f71b63          	bne	a4,a5,80002a68 <usertrap+0x8e>
    if(p->killed)
    80002a16:	551c                	lw	a5,40(a0)
    80002a18:	e3b1                	bnez	a5,80002a5c <usertrap+0x82>
    p->trapframe->epc += 4;
    80002a1a:	6cb8                	ld	a4,88(s1)
    80002a1c:	6f1c                	ld	a5,24(a4)
    80002a1e:	0791                	addi	a5,a5,4
    80002a20:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a26:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	29a080e7          	jalr	666(ra) # 80002cc8 <syscall>
  if(p->killed)
    80002a36:	549c                	lw	a5,40(s1)
    80002a38:	e7b5                	bnez	a5,80002aa4 <usertrap+0xca>
  usertrapret();
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	e0c080e7          	jalr	-500(ra) # 80002846 <usertrapret>
}
    80002a42:	60e2                	ld	ra,24(sp)
    80002a44:	6442                	ld	s0,16(sp)
    80002a46:	64a2                	ld	s1,8(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	8cc50513          	addi	a0,a0,-1844 # 80008318 <states.1743+0x58>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
      exit(-1);
    80002a5c:	557d                	li	a0,-1
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	a6e080e7          	jalr	-1426(ra) # 800024cc <exit>
    80002a66:	bf55                	j	80002a1a <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	ed0080e7          	jalr	-304(ra) # 80002938 <devintr>
    80002a70:	f179                	bnez	a0,80002a36 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a72:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a76:	5890                	lw	a2,48(s1)
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	8c050513          	addi	a0,a0,-1856 # 80008338 <states.1743+0x78>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b08080e7          	jalr	-1272(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a8c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	8d850513          	addi	a0,a0,-1832 # 80008368 <states.1743+0xa8>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	af0080e7          	jalr	-1296(ra) # 80000588 <printf>
    p->killed = 1;
    80002aa0:	4785                	li	a5,1
    80002aa2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002aa4:	557d                	li	a0,-1
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	a26080e7          	jalr	-1498(ra) # 800024cc <exit>
    80002aae:	b771                	j	80002a3a <usertrap+0x60>

0000000080002ab0 <kerneltrap>:
{
    80002ab0:	7179                	addi	sp,sp,-48
    80002ab2:	f406                	sd	ra,40(sp)
    80002ab4:	f022                	sd	s0,32(sp)
    80002ab6:	ec26                	sd	s1,24(sp)
    80002ab8:	e84a                	sd	s2,16(sp)
    80002aba:	e44e                	sd	s3,8(sp)
    80002abc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002abe:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aca:	1004f793          	andi	a5,s1,256
    80002ace:	c78d                	beqz	a5,80002af8 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ad4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ad6:	eb8d                	bnez	a5,80002b08 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	e60080e7          	jalr	-416(ra) # 80002938 <devintr>
    80002ae0:	cd05                	beqz	a0,80002b18 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae6:	10049073          	csrw	sstatus,s1
}
    80002aea:	70a2                	ld	ra,40(sp)
    80002aec:	7402                	ld	s0,32(sp)
    80002aee:	64e2                	ld	s1,24(sp)
    80002af0:	6942                	ld	s2,16(sp)
    80002af2:	69a2                	ld	s3,8(sp)
    80002af4:	6145                	addi	sp,sp,48
    80002af6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002af8:	00006517          	auipc	a0,0x6
    80002afc:	89050513          	addi	a0,a0,-1904 # 80008388 <states.1743+0xc8>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a3e080e7          	jalr	-1474(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b08:	00006517          	auipc	a0,0x6
    80002b0c:	8a850513          	addi	a0,a0,-1880 # 800083b0 <states.1743+0xf0>
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	a2e080e7          	jalr	-1490(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b18:	85ce                	mv	a1,s3
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	8b650513          	addi	a0,a0,-1866 # 800083d0 <states.1743+0x110>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a66080e7          	jalr	-1434(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b2e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	8ae50513          	addi	a0,a0,-1874 # 800083e0 <states.1743+0x120>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a4e080e7          	jalr	-1458(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	8b650513          	addi	a0,a0,-1866 # 800083f8 <states.1743+0x138>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	9f4080e7          	jalr	-1548(ra) # 8000053e <panic>

0000000080002b52 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b52:	1101                	addi	sp,sp,-32
    80002b54:	ec06                	sd	ra,24(sp)
    80002b56:	e822                	sd	s0,16(sp)
    80002b58:	e426                	sd	s1,8(sp)
    80002b5a:	1000                	addi	s0,sp,32
    80002b5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	e52080e7          	jalr	-430(ra) # 800019b0 <myproc>
  switch (n) {
    80002b66:	4795                	li	a5,5
    80002b68:	0497e163          	bltu	a5,s1,80002baa <argraw+0x58>
    80002b6c:	048a                	slli	s1,s1,0x2
    80002b6e:	00006717          	auipc	a4,0x6
    80002b72:	99a70713          	addi	a4,a4,-1638 # 80008508 <states.1743+0x248>
    80002b76:	94ba                	add	s1,s1,a4
    80002b78:	409c                	lw	a5,0(s1)
    80002b7a:	97ba                	add	a5,a5,a4
    80002b7c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b7e:	6d3c                	ld	a5,88(a0)
    80002b80:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret
    return p->trapframe->a1;
    80002b8c:	6d3c                	ld	a5,88(a0)
    80002b8e:	7fa8                	ld	a0,120(a5)
    80002b90:	bfcd                	j	80002b82 <argraw+0x30>
    return p->trapframe->a2;
    80002b92:	6d3c                	ld	a5,88(a0)
    80002b94:	63c8                	ld	a0,128(a5)
    80002b96:	b7f5                	j	80002b82 <argraw+0x30>
    return p->trapframe->a3;
    80002b98:	6d3c                	ld	a5,88(a0)
    80002b9a:	67c8                	ld	a0,136(a5)
    80002b9c:	b7dd                	j	80002b82 <argraw+0x30>
    return p->trapframe->a4;
    80002b9e:	6d3c                	ld	a5,88(a0)
    80002ba0:	6bc8                	ld	a0,144(a5)
    80002ba2:	b7c5                	j	80002b82 <argraw+0x30>
    return p->trapframe->a5;
    80002ba4:	6d3c                	ld	a5,88(a0)
    80002ba6:	6fc8                	ld	a0,152(a5)
    80002ba8:	bfe9                	j	80002b82 <argraw+0x30>
  panic("argraw");
    80002baa:	00006517          	auipc	a0,0x6
    80002bae:	85e50513          	addi	a0,a0,-1954 # 80008408 <states.1743+0x148>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>

0000000080002bba <fetchaddr>:
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	e04a                	sd	s2,0(sp)
    80002bc4:	1000                	addi	s0,sp,32
    80002bc6:	84aa                	mv	s1,a0
    80002bc8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	de6080e7          	jalr	-538(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bd2:	653c                	ld	a5,72(a0)
    80002bd4:	02f4f863          	bgeu	s1,a5,80002c04 <fetchaddr+0x4a>
    80002bd8:	00848713          	addi	a4,s1,8
    80002bdc:	02e7e663          	bltu	a5,a4,80002c08 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002be0:	46a1                	li	a3,8
    80002be2:	8626                	mv	a2,s1
    80002be4:	85ca                	mv	a1,s2
    80002be6:	6928                	ld	a0,80(a0)
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	b16080e7          	jalr	-1258(ra) # 800016fe <copyin>
    80002bf0:	00a03533          	snez	a0,a0
    80002bf4:	40a00533          	neg	a0,a0
}
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6902                	ld	s2,0(sp)
    80002c00:	6105                	addi	sp,sp,32
    80002c02:	8082                	ret
    return -1;
    80002c04:	557d                	li	a0,-1
    80002c06:	bfcd                	j	80002bf8 <fetchaddr+0x3e>
    80002c08:	557d                	li	a0,-1
    80002c0a:	b7fd                	j	80002bf8 <fetchaddr+0x3e>

0000000080002c0c <fetchstr>:
{
    80002c0c:	7179                	addi	sp,sp,-48
    80002c0e:	f406                	sd	ra,40(sp)
    80002c10:	f022                	sd	s0,32(sp)
    80002c12:	ec26                	sd	s1,24(sp)
    80002c14:	e84a                	sd	s2,16(sp)
    80002c16:	e44e                	sd	s3,8(sp)
    80002c18:	1800                	addi	s0,sp,48
    80002c1a:	892a                	mv	s2,a0
    80002c1c:	84ae                	mv	s1,a1
    80002c1e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	d90080e7          	jalr	-624(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c28:	86ce                	mv	a3,s3
    80002c2a:	864a                	mv	a2,s2
    80002c2c:	85a6                	mv	a1,s1
    80002c2e:	6928                	ld	a0,80(a0)
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	b5a080e7          	jalr	-1190(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c38:	00054763          	bltz	a0,80002c46 <fetchstr+0x3a>
  return strlen(buf);
    80002c3c:	8526                	mv	a0,s1
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	226080e7          	jalr	550(ra) # 80000e64 <strlen>
}
    80002c46:	70a2                	ld	ra,40(sp)
    80002c48:	7402                	ld	s0,32(sp)
    80002c4a:	64e2                	ld	s1,24(sp)
    80002c4c:	6942                	ld	s2,16(sp)
    80002c4e:	69a2                	ld	s3,8(sp)
    80002c50:	6145                	addi	sp,sp,48
    80002c52:	8082                	ret

0000000080002c54 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	e426                	sd	s1,8(sp)
    80002c5c:	1000                	addi	s0,sp,32
    80002c5e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	ef2080e7          	jalr	-270(ra) # 80002b52 <argraw>
    80002c68:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c6a:	4501                	li	a0,0
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret

0000000080002c76 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	1000                	addi	s0,sp,32
    80002c80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	ed0080e7          	jalr	-304(ra) # 80002b52 <argraw>
    80002c8a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c8c:	4501                	li	a0,0
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret

0000000080002c98 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	e04a                	sd	s2,0(sp)
    80002ca2:	1000                	addi	s0,sp,32
    80002ca4:	84ae                	mv	s1,a1
    80002ca6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	eaa080e7          	jalr	-342(ra) # 80002b52 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cb0:	864a                	mv	a2,s2
    80002cb2:	85a6                	mv	a1,s1
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	f58080e7          	jalr	-168(ra) # 80002c0c <fetchstr>
}
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	64a2                	ld	s1,8(sp)
    80002cc2:	6902                	ld	s2,0(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret

0000000080002cc8 <syscall>:
};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002cc8:	711d                	addi	sp,sp,-96
    80002cca:	ec86                	sd	ra,88(sp)
    80002ccc:	e8a2                	sd	s0,80(sp)
    80002cce:	e4a6                	sd	s1,72(sp)
    80002cd0:	e0ca                	sd	s2,64(sp)
    80002cd2:	fc4e                	sd	s3,56(sp)
    80002cd4:	f852                	sd	s4,48(sp)
    80002cd6:	f456                	sd	s5,40(sp)
    80002cd8:	f05a                	sd	s6,32(sp)
    80002cda:	ec5e                	sd	s7,24(sp)
    80002cdc:	e862                	sd	s8,16(sp)
    80002cde:	e466                	sd	s9,8(sp)
    80002ce0:	e06a                	sd	s10,0(sp)
    80002ce2:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	ccc080e7          	jalr	-820(ra) # 800019b0 <myproc>
    80002cec:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002cee:	6d24                	ld	s1,88(a0)
    80002cf0:	74dc                	ld	a5,168(s1)
    80002cf2:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cf6:	37fd                	addiw	a5,a5,-1
    80002cf8:	4759                	li	a4,22
    80002cfa:	06f76f63          	bltu	a4,a5,80002d78 <syscall+0xb0>
    80002cfe:	003b1713          	slli	a4,s6,0x3
    80002d02:	00006797          	auipc	a5,0x6
    80002d06:	81e78793          	addi	a5,a5,-2018 # 80008520 <syscalls>
    80002d0a:	97ba                	add	a5,a5,a4
    80002d0c:	0007bd03          	ld	s10,0(a5)
    80002d10:	060d0463          	beqz	s10,80002d78 <syscall+0xb0>
    80002d14:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002d16:	fffb0c1b          	addiw	s8,s6,-1
    80002d1a:	004c1713          	slli	a4,s8,0x4
    80002d1e:	00006797          	auipc	a5,0x6
    80002d22:	c1a78793          	addi	a5,a5,-998 # 80008938 <syscall_arg_infos>
    80002d26:	97ba                	add	a5,a5,a4
    80002d28:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002d2c:	00299793          	slli	a5,s3,0x2
    80002d30:	07bd                	addi	a5,a5,15
    80002d32:	9bc1                	andi	a5,a5,-16
    80002d34:	40f10133          	sub	sp,sp,a5
    80002d38:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002d3a:	0f305363          	blez	s3,80002e20 <syscall+0x158>
    80002d3e:	8ade                	mv	s5,s7
    80002d40:	895e                	mv	s2,s7
    80002d42:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002d44:	8526                	mv	a0,s1
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	e0c080e7          	jalr	-500(ra) # 80002b52 <argraw>
    80002d4e:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002d52:	2485                	addiw	s1,s1,1
    80002d54:	0911                	addi	s2,s2,4
    80002d56:	fe9997e3          	bne	s3,s1,80002d44 <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002d5a:	058a3483          	ld	s1,88(s4)
    80002d5e:	9d02                	jalr	s10
    80002d60:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002d62:	4785                	li	a5,1
    80002d64:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002d68:	168a2b03          	lw	s6,360(s4)
    80002d6c:	0167f7b3          	and	a5,a5,s6
    80002d70:	2781                	sext.w	a5,a5
    80002d72:	e7a1                	bnez	a5,80002dba <syscall+0xf2>
    80002d74:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d76:	a015                	j	80002d9a <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d78:	86da                	mv	a3,s6
    80002d7a:	158a0613          	addi	a2,s4,344
    80002d7e:	030a2583          	lw	a1,48(s4)
    80002d82:	00005517          	auipc	a0,0x5
    80002d86:	6a650513          	addi	a0,a0,1702 # 80008428 <states.1743+0x168>
    80002d8a:	ffffd097          	auipc	ra,0xffffd
    80002d8e:	7fe080e7          	jalr	2046(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d92:	058a3783          	ld	a5,88(s4)
    80002d96:	577d                	li	a4,-1
    80002d98:	fbb8                	sd	a4,112(a5)
  }
}
    80002d9a:	fa040113          	addi	sp,s0,-96
    80002d9e:	60e6                	ld	ra,88(sp)
    80002da0:	6446                	ld	s0,80(sp)
    80002da2:	64a6                	ld	s1,72(sp)
    80002da4:	6906                	ld	s2,64(sp)
    80002da6:	79e2                	ld	s3,56(sp)
    80002da8:	7a42                	ld	s4,48(sp)
    80002daa:	7aa2                	ld	s5,40(sp)
    80002dac:	7b02                	ld	s6,32(sp)
    80002dae:	6be2                	ld	s7,24(sp)
    80002db0:	6c42                	ld	s8,16(sp)
    80002db2:	6ca2                	ld	s9,8(sp)
    80002db4:	6d02                	ld	s10,0(sp)
    80002db6:	6125                	addi	sp,sp,96
    80002db8:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002dba:	0c12                	slli	s8,s8,0x4
    80002dbc:	00006797          	auipc	a5,0x6
    80002dc0:	b7c78793          	addi	a5,a5,-1156 # 80008938 <syscall_arg_infos>
    80002dc4:	9c3e                	add	s8,s8,a5
    80002dc6:	008c3603          	ld	a2,8(s8)
    80002dca:	030a2583          	lw	a1,48(s4)
    80002dce:	00005517          	auipc	a0,0x5
    80002dd2:	67a50513          	addi	a0,a0,1658 # 80008448 <states.1743+0x188>
    80002dd6:	ffffd097          	auipc	ra,0xffffd
    80002dda:	7b2080e7          	jalr	1970(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002dde:	fff9879b          	addiw	a5,s3,-1
    80002de2:	1782                	slli	a5,a5,0x20
    80002de4:	9381                	srli	a5,a5,0x20
    80002de6:	0785                	addi	a5,a5,1
    80002de8:	078a                	slli	a5,a5,0x2
    80002dea:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80002dec:	00005497          	auipc	s1,0x5
    80002df0:	62448493          	addi	s1,s1,1572 # 80008410 <states.1743+0x150>
    80002df4:	000aa583          	lw	a1,0(s5)
    80002df8:	8526                	mv	a0,s1
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	78e080e7          	jalr	1934(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002e02:	0a91                	addi	s5,s5,4
    80002e04:	ff7a98e3          	bne	s5,s7,80002df4 <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    80002e08:	058a3783          	ld	a5,88(s4)
    80002e0c:	7bac                	ld	a1,112(a5)
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	60a50513          	addi	a0,a0,1546 # 80008418 <states.1743+0x158>
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	772080e7          	jalr	1906(ra) # 80000588 <printf>
    80002e1e:	bf99                	j	80002d74 <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002e20:	9d02                	jalr	s10
    80002e22:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002e24:	4785                	li	a5,1
    80002e26:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002e2a:	168a2703          	lw	a4,360(s4)
    80002e2e:	8ff9                	and	a5,a5,a4
    80002e30:	2781                	sext.w	a5,a5
    80002e32:	d3a9                	beqz	a5,80002d74 <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002e34:	0c12                	slli	s8,s8,0x4
    80002e36:	00006797          	auipc	a5,0x6
    80002e3a:	b0278793          	addi	a5,a5,-1278 # 80008938 <syscall_arg_infos>
    80002e3e:	97e2                	add	a5,a5,s8
    80002e40:	6790                	ld	a2,8(a5)
    80002e42:	030a2583          	lw	a1,48(s4)
    80002e46:	00005517          	auipc	a0,0x5
    80002e4a:	60250513          	addi	a0,a0,1538 # 80008448 <states.1743+0x188>
    80002e4e:	ffffd097          	auipc	ra,0xffffd
    80002e52:	73a080e7          	jalr	1850(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002e56:	bf4d                	j	80002e08 <syscall+0x140>

0000000080002e58 <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e60:	fec40593          	addi	a1,s0,-20
    80002e64:	4501                	li	a0,0
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	dee080e7          	jalr	-530(ra) # 80002c54 <argint>
    return -1;
    80002e6e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e70:	00054963          	bltz	a0,80002e82 <sys_exit+0x2a>
  exit(n);
    80002e74:	fec42503          	lw	a0,-20(s0)
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	654080e7          	jalr	1620(ra) # 800024cc <exit>
  return 0;  // not reached
    80002e80:	4781                	li	a5,0
}
    80002e82:	853e                	mv	a0,a5
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e8c:	1141                	addi	sp,sp,-16
    80002e8e:	e406                	sd	ra,8(sp)
    80002e90:	e022                	sd	s0,0(sp)
    80002e92:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	b1c080e7          	jalr	-1252(ra) # 800019b0 <myproc>
}
    80002e9c:	5908                	lw	a0,48(a0)
    80002e9e:	60a2                	ld	ra,8(sp)
    80002ea0:	6402                	ld	s0,0(sp)
    80002ea2:	0141                	addi	sp,sp,16
    80002ea4:	8082                	ret

0000000080002ea6 <sys_fork>:

uint64
sys_fork(void)
{
    80002ea6:	1141                	addi	sp,sp,-16
    80002ea8:	e406                	sd	ra,8(sp)
    80002eaa:	e022                	sd	s0,0(sp)
    80002eac:	0800                	addi	s0,sp,16
  return fork();
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	ee4080e7          	jalr	-284(ra) # 80001d92 <fork>
}
    80002eb6:	60a2                	ld	ra,8(sp)
    80002eb8:	6402                	ld	s0,0(sp)
    80002eba:	0141                	addi	sp,sp,16
    80002ebc:	8082                	ret

0000000080002ebe <sys_wait>:

uint64
sys_wait(void)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ec6:	fe840593          	addi	a1,s0,-24
    80002eca:	4501                	li	a0,0
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	daa080e7          	jalr	-598(ra) # 80002c76 <argaddr>
    80002ed4:	87aa                	mv	a5,a0
    return -1;
    80002ed6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ed8:	0007c863          	bltz	a5,80002ee8 <sys_wait+0x2a>
  return wait(p);
    80002edc:	fe843503          	ld	a0,-24(s0)
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	2a8080e7          	jalr	680(ra) # 80002188 <wait>
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002ef0:	7139                	addi	sp,sp,-64
    80002ef2:	fc06                	sd	ra,56(sp)
    80002ef4:	f822                	sd	s0,48(sp)
    80002ef6:	f426                	sd	s1,40(sp)
    80002ef8:	f04a                	sd	s2,32(sp)
    80002efa:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002efc:	fd840593          	addi	a1,s0,-40
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	d74080e7          	jalr	-652(ra) # 80002c76 <argaddr>
    return -1;
    80002f0a:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002f0c:	08054063          	bltz	a0,80002f8c <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f10:	fd040593          	addi	a1,s0,-48
    80002f14:	4505                	li	a0,1
    80002f16:	00000097          	auipc	ra,0x0
    80002f1a:	d60080e7          	jalr	-672(ra) # 80002c76 <argaddr>
    return -1;
    80002f1e:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f20:	06054663          	bltz	a0,80002f8c <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80002f24:	fc840593          	addi	a1,s0,-56
    80002f28:	4509                	li	a0,2
    80002f2a:	00000097          	auipc	ra,0x0
    80002f2e:	d4c080e7          	jalr	-692(ra) # 80002c76 <argaddr>
    return -1;
    80002f32:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002f34:	04054c63          	bltz	a0,80002f8c <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80002f38:	fc040613          	addi	a2,s0,-64
    80002f3c:	fc440593          	addi	a1,s0,-60
    80002f40:	fd843503          	ld	a0,-40(s0)
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	36c080e7          	jalr	876(ra) # 800022b0 <waitx>
    80002f4c:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	a62080e7          	jalr	-1438(ra) # 800019b0 <myproc>
    80002f56:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002f58:	4691                	li	a3,4
    80002f5a:	fc440613          	addi	a2,s0,-60
    80002f5e:	fd043583          	ld	a1,-48(s0)
    80002f62:	6928                	ld	a0,80(a0)
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	70e080e7          	jalr	1806(ra) # 80001672 <copyout>
    return -1;
    80002f6c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002f6e:	00054f63          	bltz	a0,80002f8c <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002f72:	4691                	li	a3,4
    80002f74:	fc040613          	addi	a2,s0,-64
    80002f78:	fc843583          	ld	a1,-56(s0)
    80002f7c:	68a8                	ld	a0,80(s1)
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	6f4080e7          	jalr	1780(ra) # 80001672 <copyout>
    80002f86:	00054a63          	bltz	a0,80002f9a <sys_waitx+0xaa>
    return -1;
  return ret;
    80002f8a:	87ca                	mv	a5,s2
}
    80002f8c:	853e                	mv	a0,a5
    80002f8e:	70e2                	ld	ra,56(sp)
    80002f90:	7442                	ld	s0,48(sp)
    80002f92:	74a2                	ld	s1,40(sp)
    80002f94:	7902                	ld	s2,32(sp)
    80002f96:	6121                	addi	sp,sp,64
    80002f98:	8082                	ret
    return -1;
    80002f9a:	57fd                	li	a5,-1
    80002f9c:	bfc5                	j	80002f8c <sys_waitx+0x9c>

0000000080002f9e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f9e:	7179                	addi	sp,sp,-48
    80002fa0:	f406                	sd	ra,40(sp)
    80002fa2:	f022                	sd	s0,32(sp)
    80002fa4:	ec26                	sd	s1,24(sp)
    80002fa6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fa8:	fdc40593          	addi	a1,s0,-36
    80002fac:	4501                	li	a0,0
    80002fae:	00000097          	auipc	ra,0x0
    80002fb2:	ca6080e7          	jalr	-858(ra) # 80002c54 <argint>
    80002fb6:	87aa                	mv	a5,a0
    return -1;
    80002fb8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002fba:	0207c063          	bltz	a5,80002fda <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	9f2080e7          	jalr	-1550(ra) # 800019b0 <myproc>
    80002fc6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fc8:	fdc42503          	lw	a0,-36(s0)
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	d52080e7          	jalr	-686(ra) # 80001d1e <growproc>
    80002fd4:	00054863          	bltz	a0,80002fe4 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fd8:	8526                	mv	a0,s1
}
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6145                	addi	sp,sp,48
    80002fe2:	8082                	ret
    return -1;
    80002fe4:	557d                	li	a0,-1
    80002fe6:	bfd5                	j	80002fda <sys_sbrk+0x3c>

0000000080002fe8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fe8:	7139                	addi	sp,sp,-64
    80002fea:	fc06                	sd	ra,56(sp)
    80002fec:	f822                	sd	s0,48(sp)
    80002fee:	f426                	sd	s1,40(sp)
    80002ff0:	f04a                	sd	s2,32(sp)
    80002ff2:	ec4e                	sd	s3,24(sp)
    80002ff4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ff6:	fcc40593          	addi	a1,s0,-52
    80002ffa:	4501                	li	a0,0
    80002ffc:	00000097          	auipc	ra,0x0
    80003000:	c58080e7          	jalr	-936(ra) # 80002c54 <argint>
    return -1;
    80003004:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003006:	06054563          	bltz	a0,80003070 <sys_sleep+0x88>
  acquire(&tickslock);
    8000300a:	00014517          	auipc	a0,0x14
    8000300e:	4c650513          	addi	a0,a0,1222 # 800174d0 <tickslock>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	bd2080e7          	jalr	-1070(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000301a:	00006917          	auipc	s2,0x6
    8000301e:	01692903          	lw	s2,22(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003022:	fcc42783          	lw	a5,-52(s0)
    80003026:	cf85                	beqz	a5,8000305e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003028:	00014997          	auipc	s3,0x14
    8000302c:	4a898993          	addi	s3,s3,1192 # 800174d0 <tickslock>
    80003030:	00006497          	auipc	s1,0x6
    80003034:	00048493          	mv	s1,s1
    if(myproc()->killed){
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	978080e7          	jalr	-1672(ra) # 800019b0 <myproc>
    80003040:	551c                	lw	a5,40(a0)
    80003042:	ef9d                	bnez	a5,80003080 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003044:	85ce                	mv	a1,s3
    80003046:	8526                	mv	a0,s1
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	0dc080e7          	jalr	220(ra) # 80002124 <sleep>
  while(ticks - ticks0 < n){
    80003050:	409c                	lw	a5,0(s1)
    80003052:	412787bb          	subw	a5,a5,s2
    80003056:	fcc42703          	lw	a4,-52(s0)
    8000305a:	fce7efe3          	bltu	a5,a4,80003038 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000305e:	00014517          	auipc	a0,0x14
    80003062:	47250513          	addi	a0,a0,1138 # 800174d0 <tickslock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c32080e7          	jalr	-974(ra) # 80000c98 <release>
  return 0;
    8000306e:	4781                	li	a5,0
}
    80003070:	853e                	mv	a0,a5
    80003072:	70e2                	ld	ra,56(sp)
    80003074:	7442                	ld	s0,48(sp)
    80003076:	74a2                	ld	s1,40(sp)
    80003078:	7902                	ld	s2,32(sp)
    8000307a:	69e2                	ld	s3,24(sp)
    8000307c:	6121                	addi	sp,sp,64
    8000307e:	8082                	ret
      release(&tickslock);
    80003080:	00014517          	auipc	a0,0x14
    80003084:	45050513          	addi	a0,a0,1104 # 800174d0 <tickslock>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	c10080e7          	jalr	-1008(ra) # 80000c98 <release>
      return -1;
    80003090:	57fd                	li	a5,-1
    80003092:	bff9                	j	80003070 <sys_sleep+0x88>

0000000080003094 <sys_kill>:

uint64
sys_kill(void)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000309c:	fec40593          	addi	a1,s0,-20
    800030a0:	4501                	li	a0,0
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	bb2080e7          	jalr	-1102(ra) # 80002c54 <argint>
    800030aa:	87aa                	mv	a5,a0
    return -1;
    800030ac:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ae:	0007c863          	bltz	a5,800030be <sys_kill+0x2a>
  return kill(pid);
    800030b2:	fec42503          	lw	a0,-20(s0)
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	4f8080e7          	jalr	1272(ra) # 800025ae <kill>
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	40050513          	addi	a0,a0,1024 # 800174d0 <tickslock>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	b0c080e7          	jalr	-1268(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030e0:	00006497          	auipc	s1,0x6
    800030e4:	f504a483          	lw	s1,-176(s1) # 80009030 <ticks>
  release(&tickslock);
    800030e8:	00014517          	auipc	a0,0x14
    800030ec:	3e850513          	addi	a0,a0,1000 # 800174d0 <tickslock>
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	ba8080e7          	jalr	-1112(ra) # 80000c98 <release>
  return xticks;
}
    800030f8:	02049513          	slli	a0,s1,0x20
    800030fc:	9101                	srli	a0,a0,0x20
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret

0000000080003108 <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    80003110:	fec40593          	addi	a1,s0,-20
    80003114:	4501                	li	a0,0
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	b3e080e7          	jalr	-1218(ra) # 80002c54 <argint>
  trace(n);
    8000311e:	fec42503          	lw	a0,-20(s0)
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	658080e7          	jalr	1624(ra) # 8000277a <trace>
  return 0; // if the syscall is successful, return 0
}
    8000312a:	4501                	li	a0,0
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	6105                	addi	sp,sp,32
    80003132:	8082                	ret

0000000080003134 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003134:	7179                	addi	sp,sp,-48
    80003136:	f406                	sd	ra,40(sp)
    80003138:	f022                	sd	s0,32(sp)
    8000313a:	ec26                	sd	s1,24(sp)
    8000313c:	e84a                	sd	s2,16(sp)
    8000313e:	e44e                	sd	s3,8(sp)
    80003140:	e052                	sd	s4,0(sp)
    80003142:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003144:	00005597          	auipc	a1,0x5
    80003148:	49c58593          	addi	a1,a1,1180 # 800085e0 <syscalls+0xc0>
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	39c50513          	addi	a0,a0,924 # 800174e8 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	a00080e7          	jalr	-1536(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000315c:	0001c797          	auipc	a5,0x1c
    80003160:	38c78793          	addi	a5,a5,908 # 8001f4e8 <bcache+0x8000>
    80003164:	0001c717          	auipc	a4,0x1c
    80003168:	5ec70713          	addi	a4,a4,1516 # 8001f750 <bcache+0x8268>
    8000316c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003170:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003174:	00014497          	auipc	s1,0x14
    80003178:	38c48493          	addi	s1,s1,908 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    8000317c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000317e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003180:	00005a17          	auipc	s4,0x5
    80003184:	468a0a13          	addi	s4,s4,1128 # 800085e8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003188:	2b893783          	ld	a5,696(s2)
    8000318c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000318e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003192:	85d2                	mv	a1,s4
    80003194:	01048513          	addi	a0,s1,16
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	4bc080e7          	jalr	1212(ra) # 80004654 <initsleeplock>
    bcache.head.next->prev = b;
    800031a0:	2b893783          	ld	a5,696(s2)
    800031a4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031a6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031aa:	45848493          	addi	s1,s1,1112
    800031ae:	fd349de3          	bne	s1,s3,80003188 <binit+0x54>
  }
}
    800031b2:	70a2                	ld	ra,40(sp)
    800031b4:	7402                	ld	s0,32(sp)
    800031b6:	64e2                	ld	s1,24(sp)
    800031b8:	6942                	ld	s2,16(sp)
    800031ba:	69a2                	ld	s3,8(sp)
    800031bc:	6a02                	ld	s4,0(sp)
    800031be:	6145                	addi	sp,sp,48
    800031c0:	8082                	ret

00000000800031c2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031c2:	7179                	addi	sp,sp,-48
    800031c4:	f406                	sd	ra,40(sp)
    800031c6:	f022                	sd	s0,32(sp)
    800031c8:	ec26                	sd	s1,24(sp)
    800031ca:	e84a                	sd	s2,16(sp)
    800031cc:	e44e                	sd	s3,8(sp)
    800031ce:	1800                	addi	s0,sp,48
    800031d0:	89aa                	mv	s3,a0
    800031d2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031d4:	00014517          	auipc	a0,0x14
    800031d8:	31450513          	addi	a0,a0,788 # 800174e8 <bcache>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	a08080e7          	jalr	-1528(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031e4:	0001c497          	auipc	s1,0x1c
    800031e8:	5bc4b483          	ld	s1,1468(s1) # 8001f7a0 <bcache+0x82b8>
    800031ec:	0001c797          	auipc	a5,0x1c
    800031f0:	56478793          	addi	a5,a5,1380 # 8001f750 <bcache+0x8268>
    800031f4:	02f48f63          	beq	s1,a5,80003232 <bread+0x70>
    800031f8:	873e                	mv	a4,a5
    800031fa:	a021                	j	80003202 <bread+0x40>
    800031fc:	68a4                	ld	s1,80(s1)
    800031fe:	02e48a63          	beq	s1,a4,80003232 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003202:	449c                	lw	a5,8(s1)
    80003204:	ff379ce3          	bne	a5,s3,800031fc <bread+0x3a>
    80003208:	44dc                	lw	a5,12(s1)
    8000320a:	ff2799e3          	bne	a5,s2,800031fc <bread+0x3a>
      b->refcnt++;
    8000320e:	40bc                	lw	a5,64(s1)
    80003210:	2785                	addiw	a5,a5,1
    80003212:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003214:	00014517          	auipc	a0,0x14
    80003218:	2d450513          	addi	a0,a0,724 # 800174e8 <bcache>
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003224:	01048513          	addi	a0,s1,16
    80003228:	00001097          	auipc	ra,0x1
    8000322c:	466080e7          	jalr	1126(ra) # 8000468e <acquiresleep>
      return b;
    80003230:	a8b9                	j	8000328e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003232:	0001c497          	auipc	s1,0x1c
    80003236:	5664b483          	ld	s1,1382(s1) # 8001f798 <bcache+0x82b0>
    8000323a:	0001c797          	auipc	a5,0x1c
    8000323e:	51678793          	addi	a5,a5,1302 # 8001f750 <bcache+0x8268>
    80003242:	00f48863          	beq	s1,a5,80003252 <bread+0x90>
    80003246:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003248:	40bc                	lw	a5,64(s1)
    8000324a:	cf81                	beqz	a5,80003262 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000324c:	64a4                	ld	s1,72(s1)
    8000324e:	fee49de3          	bne	s1,a4,80003248 <bread+0x86>
  panic("bget: no buffers");
    80003252:	00005517          	auipc	a0,0x5
    80003256:	39e50513          	addi	a0,a0,926 # 800085f0 <syscalls+0xd0>
    8000325a:	ffffd097          	auipc	ra,0xffffd
    8000325e:	2e4080e7          	jalr	740(ra) # 8000053e <panic>
      b->dev = dev;
    80003262:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003266:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000326a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000326e:	4785                	li	a5,1
    80003270:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003272:	00014517          	auipc	a0,0x14
    80003276:	27650513          	addi	a0,a0,630 # 800174e8 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a1e080e7          	jalr	-1506(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003282:	01048513          	addi	a0,s1,16
    80003286:	00001097          	auipc	ra,0x1
    8000328a:	408080e7          	jalr	1032(ra) # 8000468e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000328e:	409c                	lw	a5,0(s1)
    80003290:	cb89                	beqz	a5,800032a2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003292:	8526                	mv	a0,s1
    80003294:	70a2                	ld	ra,40(sp)
    80003296:	7402                	ld	s0,32(sp)
    80003298:	64e2                	ld	s1,24(sp)
    8000329a:	6942                	ld	s2,16(sp)
    8000329c:	69a2                	ld	s3,8(sp)
    8000329e:	6145                	addi	sp,sp,48
    800032a0:	8082                	ret
    virtio_disk_rw(b, 0);
    800032a2:	4581                	li	a1,0
    800032a4:	8526                	mv	a0,s1
    800032a6:	00003097          	auipc	ra,0x3
    800032aa:	f10080e7          	jalr	-240(ra) # 800061b6 <virtio_disk_rw>
    b->valid = 1;
    800032ae:	4785                	li	a5,1
    800032b0:	c09c                	sw	a5,0(s1)
  return b;
    800032b2:	b7c5                	j	80003292 <bread+0xd0>

00000000800032b4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	1000                	addi	s0,sp,32
    800032be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c0:	0541                	addi	a0,a0,16
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	466080e7          	jalr	1126(ra) # 80004728 <holdingsleep>
    800032ca:	cd01                	beqz	a0,800032e2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032cc:	4585                	li	a1,1
    800032ce:	8526                	mv	a0,s1
    800032d0:	00003097          	auipc	ra,0x3
    800032d4:	ee6080e7          	jalr	-282(ra) # 800061b6 <virtio_disk_rw>
}
    800032d8:	60e2                	ld	ra,24(sp)
    800032da:	6442                	ld	s0,16(sp)
    800032dc:	64a2                	ld	s1,8(sp)
    800032de:	6105                	addi	sp,sp,32
    800032e0:	8082                	ret
    panic("bwrite");
    800032e2:	00005517          	auipc	a0,0x5
    800032e6:	32650513          	addi	a0,a0,806 # 80008608 <syscalls+0xe8>
    800032ea:	ffffd097          	auipc	ra,0xffffd
    800032ee:	254080e7          	jalr	596(ra) # 8000053e <panic>

00000000800032f2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	e04a                	sd	s2,0(sp)
    800032fc:	1000                	addi	s0,sp,32
    800032fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003300:	01050913          	addi	s2,a0,16
    80003304:	854a                	mv	a0,s2
    80003306:	00001097          	auipc	ra,0x1
    8000330a:	422080e7          	jalr	1058(ra) # 80004728 <holdingsleep>
    8000330e:	c92d                	beqz	a0,80003380 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003310:	854a                	mv	a0,s2
    80003312:	00001097          	auipc	ra,0x1
    80003316:	3d2080e7          	jalr	978(ra) # 800046e4 <releasesleep>

  acquire(&bcache.lock);
    8000331a:	00014517          	auipc	a0,0x14
    8000331e:	1ce50513          	addi	a0,a0,462 # 800174e8 <bcache>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	8c2080e7          	jalr	-1854(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000332a:	40bc                	lw	a5,64(s1)
    8000332c:	37fd                	addiw	a5,a5,-1
    8000332e:	0007871b          	sext.w	a4,a5
    80003332:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003334:	eb05                	bnez	a4,80003364 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003336:	68bc                	ld	a5,80(s1)
    80003338:	64b8                	ld	a4,72(s1)
    8000333a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000333c:	64bc                	ld	a5,72(s1)
    8000333e:	68b8                	ld	a4,80(s1)
    80003340:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003342:	0001c797          	auipc	a5,0x1c
    80003346:	1a678793          	addi	a5,a5,422 # 8001f4e8 <bcache+0x8000>
    8000334a:	2b87b703          	ld	a4,696(a5)
    8000334e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003350:	0001c717          	auipc	a4,0x1c
    80003354:	40070713          	addi	a4,a4,1024 # 8001f750 <bcache+0x8268>
    80003358:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000335a:	2b87b703          	ld	a4,696(a5)
    8000335e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003360:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003364:	00014517          	auipc	a0,0x14
    80003368:	18450513          	addi	a0,a0,388 # 800174e8 <bcache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6902                	ld	s2,0(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret
    panic("brelse");
    80003380:	00005517          	auipc	a0,0x5
    80003384:	29050513          	addi	a0,a0,656 # 80008610 <syscalls+0xf0>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1b6080e7          	jalr	438(ra) # 8000053e <panic>

0000000080003390 <bpin>:

void
bpin(struct buf *b) {
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	1000                	addi	s0,sp,32
    8000339a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	14c50513          	addi	a0,a0,332 # 800174e8 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	840080e7          	jalr	-1984(ra) # 80000be4 <acquire>
  b->refcnt++;
    800033ac:	40bc                	lw	a5,64(s1)
    800033ae:	2785                	addiw	a5,a5,1
    800033b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b2:	00014517          	auipc	a0,0x14
    800033b6:	13650513          	addi	a0,a0,310 # 800174e8 <bcache>
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	8de080e7          	jalr	-1826(ra) # 80000c98 <release>
}
    800033c2:	60e2                	ld	ra,24(sp)
    800033c4:	6442                	ld	s0,16(sp)
    800033c6:	64a2                	ld	s1,8(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret

00000000800033cc <bunpin>:

void
bunpin(struct buf *b) {
    800033cc:	1101                	addi	sp,sp,-32
    800033ce:	ec06                	sd	ra,24(sp)
    800033d0:	e822                	sd	s0,16(sp)
    800033d2:	e426                	sd	s1,8(sp)
    800033d4:	1000                	addi	s0,sp,32
    800033d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033d8:	00014517          	auipc	a0,0x14
    800033dc:	11050513          	addi	a0,a0,272 # 800174e8 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	804080e7          	jalr	-2044(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033e8:	40bc                	lw	a5,64(s1)
    800033ea:	37fd                	addiw	a5,a5,-1
    800033ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033ee:	00014517          	auipc	a0,0x14
    800033f2:	0fa50513          	addi	a0,a0,250 # 800174e8 <bcache>
    800033f6:	ffffe097          	auipc	ra,0xffffe
    800033fa:	8a2080e7          	jalr	-1886(ra) # 80000c98 <release>
}
    800033fe:	60e2                	ld	ra,24(sp)
    80003400:	6442                	ld	s0,16(sp)
    80003402:	64a2                	ld	s1,8(sp)
    80003404:	6105                	addi	sp,sp,32
    80003406:	8082                	ret

0000000080003408 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003408:	1101                	addi	sp,sp,-32
    8000340a:	ec06                	sd	ra,24(sp)
    8000340c:	e822                	sd	s0,16(sp)
    8000340e:	e426                	sd	s1,8(sp)
    80003410:	e04a                	sd	s2,0(sp)
    80003412:	1000                	addi	s0,sp,32
    80003414:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003416:	00d5d59b          	srliw	a1,a1,0xd
    8000341a:	0001c797          	auipc	a5,0x1c
    8000341e:	7aa7a783          	lw	a5,1962(a5) # 8001fbc4 <sb+0x1c>
    80003422:	9dbd                	addw	a1,a1,a5
    80003424:	00000097          	auipc	ra,0x0
    80003428:	d9e080e7          	jalr	-610(ra) # 800031c2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000342c:	0074f713          	andi	a4,s1,7
    80003430:	4785                	li	a5,1
    80003432:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003436:	14ce                	slli	s1,s1,0x33
    80003438:	90d9                	srli	s1,s1,0x36
    8000343a:	00950733          	add	a4,a0,s1
    8000343e:	05874703          	lbu	a4,88(a4)
    80003442:	00e7f6b3          	and	a3,a5,a4
    80003446:	c69d                	beqz	a3,80003474 <bfree+0x6c>
    80003448:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000344a:	94aa                	add	s1,s1,a0
    8000344c:	fff7c793          	not	a5,a5
    80003450:	8ff9                	and	a5,a5,a4
    80003452:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	118080e7          	jalr	280(ra) # 8000456e <log_write>
  brelse(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	00000097          	auipc	ra,0x0
    80003464:	e92080e7          	jalr	-366(ra) # 800032f2 <brelse>
}
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	64a2                	ld	s1,8(sp)
    8000346e:	6902                	ld	s2,0(sp)
    80003470:	6105                	addi	sp,sp,32
    80003472:	8082                	ret
    panic("freeing free block");
    80003474:	00005517          	auipc	a0,0x5
    80003478:	1a450513          	addi	a0,a0,420 # 80008618 <syscalls+0xf8>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	0c2080e7          	jalr	194(ra) # 8000053e <panic>

0000000080003484 <balloc>:
{
    80003484:	711d                	addi	sp,sp,-96
    80003486:	ec86                	sd	ra,88(sp)
    80003488:	e8a2                	sd	s0,80(sp)
    8000348a:	e4a6                	sd	s1,72(sp)
    8000348c:	e0ca                	sd	s2,64(sp)
    8000348e:	fc4e                	sd	s3,56(sp)
    80003490:	f852                	sd	s4,48(sp)
    80003492:	f456                	sd	s5,40(sp)
    80003494:	f05a                	sd	s6,32(sp)
    80003496:	ec5e                	sd	s7,24(sp)
    80003498:	e862                	sd	s8,16(sp)
    8000349a:	e466                	sd	s9,8(sp)
    8000349c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000349e:	0001c797          	auipc	a5,0x1c
    800034a2:	70e7a783          	lw	a5,1806(a5) # 8001fbac <sb+0x4>
    800034a6:	cbd1                	beqz	a5,8000353a <balloc+0xb6>
    800034a8:	8baa                	mv	s7,a0
    800034aa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034ac:	0001cb17          	auipc	s6,0x1c
    800034b0:	6fcb0b13          	addi	s6,s6,1788 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034b6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ba:	6c89                	lui	s9,0x2
    800034bc:	a831                	j	800034d8 <balloc+0x54>
    brelse(bp);
    800034be:	854a                	mv	a0,s2
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	e32080e7          	jalr	-462(ra) # 800032f2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034c8:	015c87bb          	addw	a5,s9,s5
    800034cc:	00078a9b          	sext.w	s5,a5
    800034d0:	004b2703          	lw	a4,4(s6)
    800034d4:	06eaf363          	bgeu	s5,a4,8000353a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034d8:	41fad79b          	sraiw	a5,s5,0x1f
    800034dc:	0137d79b          	srliw	a5,a5,0x13
    800034e0:	015787bb          	addw	a5,a5,s5
    800034e4:	40d7d79b          	sraiw	a5,a5,0xd
    800034e8:	01cb2583          	lw	a1,28(s6)
    800034ec:	9dbd                	addw	a1,a1,a5
    800034ee:	855e                	mv	a0,s7
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	cd2080e7          	jalr	-814(ra) # 800031c2 <bread>
    800034f8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fa:	004b2503          	lw	a0,4(s6)
    800034fe:	000a849b          	sext.w	s1,s5
    80003502:	8662                	mv	a2,s8
    80003504:	faa4fde3          	bgeu	s1,a0,800034be <balloc+0x3a>
      m = 1 << (bi % 8);
    80003508:	41f6579b          	sraiw	a5,a2,0x1f
    8000350c:	01d7d69b          	srliw	a3,a5,0x1d
    80003510:	00c6873b          	addw	a4,a3,a2
    80003514:	00777793          	andi	a5,a4,7
    80003518:	9f95                	subw	a5,a5,a3
    8000351a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000351e:	4037571b          	sraiw	a4,a4,0x3
    80003522:	00e906b3          	add	a3,s2,a4
    80003526:	0586c683          	lbu	a3,88(a3)
    8000352a:	00d7f5b3          	and	a1,a5,a3
    8000352e:	cd91                	beqz	a1,8000354a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003530:	2605                	addiw	a2,a2,1
    80003532:	2485                	addiw	s1,s1,1
    80003534:	fd4618e3          	bne	a2,s4,80003504 <balloc+0x80>
    80003538:	b759                	j	800034be <balloc+0x3a>
  panic("balloc: out of blocks");
    8000353a:	00005517          	auipc	a0,0x5
    8000353e:	0f650513          	addi	a0,a0,246 # 80008630 <syscalls+0x110>
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	ffc080e7          	jalr	-4(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000354a:	974a                	add	a4,a4,s2
    8000354c:	8fd5                	or	a5,a5,a3
    8000354e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003552:	854a                	mv	a0,s2
    80003554:	00001097          	auipc	ra,0x1
    80003558:	01a080e7          	jalr	26(ra) # 8000456e <log_write>
        brelse(bp);
    8000355c:	854a                	mv	a0,s2
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	d94080e7          	jalr	-620(ra) # 800032f2 <brelse>
  bp = bread(dev, bno);
    80003566:	85a6                	mv	a1,s1
    80003568:	855e                	mv	a0,s7
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	c58080e7          	jalr	-936(ra) # 800031c2 <bread>
    80003572:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003574:	40000613          	li	a2,1024
    80003578:	4581                	li	a1,0
    8000357a:	05850513          	addi	a0,a0,88
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	762080e7          	jalr	1890(ra) # 80000ce0 <memset>
  log_write(bp);
    80003586:	854a                	mv	a0,s2
    80003588:	00001097          	auipc	ra,0x1
    8000358c:	fe6080e7          	jalr	-26(ra) # 8000456e <log_write>
  brelse(bp);
    80003590:	854a                	mv	a0,s2
    80003592:	00000097          	auipc	ra,0x0
    80003596:	d60080e7          	jalr	-672(ra) # 800032f2 <brelse>
}
    8000359a:	8526                	mv	a0,s1
    8000359c:	60e6                	ld	ra,88(sp)
    8000359e:	6446                	ld	s0,80(sp)
    800035a0:	64a6                	ld	s1,72(sp)
    800035a2:	6906                	ld	s2,64(sp)
    800035a4:	79e2                	ld	s3,56(sp)
    800035a6:	7a42                	ld	s4,48(sp)
    800035a8:	7aa2                	ld	s5,40(sp)
    800035aa:	7b02                	ld	s6,32(sp)
    800035ac:	6be2                	ld	s7,24(sp)
    800035ae:	6c42                	ld	s8,16(sp)
    800035b0:	6ca2                	ld	s9,8(sp)
    800035b2:	6125                	addi	sp,sp,96
    800035b4:	8082                	ret

00000000800035b6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035b6:	7179                	addi	sp,sp,-48
    800035b8:	f406                	sd	ra,40(sp)
    800035ba:	f022                	sd	s0,32(sp)
    800035bc:	ec26                	sd	s1,24(sp)
    800035be:	e84a                	sd	s2,16(sp)
    800035c0:	e44e                	sd	s3,8(sp)
    800035c2:	e052                	sd	s4,0(sp)
    800035c4:	1800                	addi	s0,sp,48
    800035c6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035c8:	47ad                	li	a5,11
    800035ca:	04b7fe63          	bgeu	a5,a1,80003626 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035ce:	ff45849b          	addiw	s1,a1,-12
    800035d2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035d6:	0ff00793          	li	a5,255
    800035da:	0ae7e363          	bltu	a5,a4,80003680 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035de:	08052583          	lw	a1,128(a0)
    800035e2:	c5ad                	beqz	a1,8000364c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035e4:	00092503          	lw	a0,0(s2)
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	bda080e7          	jalr	-1062(ra) # 800031c2 <bread>
    800035f0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035f2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035f6:	02049593          	slli	a1,s1,0x20
    800035fa:	9181                	srli	a1,a1,0x20
    800035fc:	058a                	slli	a1,a1,0x2
    800035fe:	00b784b3          	add	s1,a5,a1
    80003602:	0004a983          	lw	s3,0(s1)
    80003606:	04098d63          	beqz	s3,80003660 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000360a:	8552                	mv	a0,s4
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	ce6080e7          	jalr	-794(ra) # 800032f2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003614:	854e                	mv	a0,s3
    80003616:	70a2                	ld	ra,40(sp)
    80003618:	7402                	ld	s0,32(sp)
    8000361a:	64e2                	ld	s1,24(sp)
    8000361c:	6942                	ld	s2,16(sp)
    8000361e:	69a2                	ld	s3,8(sp)
    80003620:	6a02                	ld	s4,0(sp)
    80003622:	6145                	addi	sp,sp,48
    80003624:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003626:	02059493          	slli	s1,a1,0x20
    8000362a:	9081                	srli	s1,s1,0x20
    8000362c:	048a                	slli	s1,s1,0x2
    8000362e:	94aa                	add	s1,s1,a0
    80003630:	0504a983          	lw	s3,80(s1)
    80003634:	fe0990e3          	bnez	s3,80003614 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003638:	4108                	lw	a0,0(a0)
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	e4a080e7          	jalr	-438(ra) # 80003484 <balloc>
    80003642:	0005099b          	sext.w	s3,a0
    80003646:	0534a823          	sw	s3,80(s1)
    8000364a:	b7e9                	j	80003614 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000364c:	4108                	lw	a0,0(a0)
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	e36080e7          	jalr	-458(ra) # 80003484 <balloc>
    80003656:	0005059b          	sext.w	a1,a0
    8000365a:	08b92023          	sw	a1,128(s2)
    8000365e:	b759                	j	800035e4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003660:	00092503          	lw	a0,0(s2)
    80003664:	00000097          	auipc	ra,0x0
    80003668:	e20080e7          	jalr	-480(ra) # 80003484 <balloc>
    8000366c:	0005099b          	sext.w	s3,a0
    80003670:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003674:	8552                	mv	a0,s4
    80003676:	00001097          	auipc	ra,0x1
    8000367a:	ef8080e7          	jalr	-264(ra) # 8000456e <log_write>
    8000367e:	b771                	j	8000360a <bmap+0x54>
  panic("bmap: out of range");
    80003680:	00005517          	auipc	a0,0x5
    80003684:	fc850513          	addi	a0,a0,-56 # 80008648 <syscalls+0x128>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	eb6080e7          	jalr	-330(ra) # 8000053e <panic>

0000000080003690 <iget>:
{
    80003690:	7179                	addi	sp,sp,-48
    80003692:	f406                	sd	ra,40(sp)
    80003694:	f022                	sd	s0,32(sp)
    80003696:	ec26                	sd	s1,24(sp)
    80003698:	e84a                	sd	s2,16(sp)
    8000369a:	e44e                	sd	s3,8(sp)
    8000369c:	e052                	sd	s4,0(sp)
    8000369e:	1800                	addi	s0,sp,48
    800036a0:	89aa                	mv	s3,a0
    800036a2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036a4:	0001c517          	auipc	a0,0x1c
    800036a8:	52450513          	addi	a0,a0,1316 # 8001fbc8 <itable>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  empty = 0;
    800036b4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036b6:	0001c497          	auipc	s1,0x1c
    800036ba:	52a48493          	addi	s1,s1,1322 # 8001fbe0 <itable+0x18>
    800036be:	0001e697          	auipc	a3,0x1e
    800036c2:	fb268693          	addi	a3,a3,-78 # 80021670 <log>
    800036c6:	a039                	j	800036d4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c8:	02090b63          	beqz	s2,800036fe <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036cc:	08848493          	addi	s1,s1,136
    800036d0:	02d48a63          	beq	s1,a3,80003704 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036d4:	449c                	lw	a5,8(s1)
    800036d6:	fef059e3          	blez	a5,800036c8 <iget+0x38>
    800036da:	4098                	lw	a4,0(s1)
    800036dc:	ff3716e3          	bne	a4,s3,800036c8 <iget+0x38>
    800036e0:	40d8                	lw	a4,4(s1)
    800036e2:	ff4713e3          	bne	a4,s4,800036c8 <iget+0x38>
      ip->ref++;
    800036e6:	2785                	addiw	a5,a5,1
    800036e8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036ea:	0001c517          	auipc	a0,0x1c
    800036ee:	4de50513          	addi	a0,a0,1246 # 8001fbc8 <itable>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	5a6080e7          	jalr	1446(ra) # 80000c98 <release>
      return ip;
    800036fa:	8926                	mv	s2,s1
    800036fc:	a03d                	j	8000372a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036fe:	f7f9                	bnez	a5,800036cc <iget+0x3c>
    80003700:	8926                	mv	s2,s1
    80003702:	b7e9                	j	800036cc <iget+0x3c>
  if(empty == 0)
    80003704:	02090c63          	beqz	s2,8000373c <iget+0xac>
  ip->dev = dev;
    80003708:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000370c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003710:	4785                	li	a5,1
    80003712:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003716:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000371a:	0001c517          	auipc	a0,0x1c
    8000371e:	4ae50513          	addi	a0,a0,1198 # 8001fbc8 <itable>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	576080e7          	jalr	1398(ra) # 80000c98 <release>
}
    8000372a:	854a                	mv	a0,s2
    8000372c:	70a2                	ld	ra,40(sp)
    8000372e:	7402                	ld	s0,32(sp)
    80003730:	64e2                	ld	s1,24(sp)
    80003732:	6942                	ld	s2,16(sp)
    80003734:	69a2                	ld	s3,8(sp)
    80003736:	6a02                	ld	s4,0(sp)
    80003738:	6145                	addi	sp,sp,48
    8000373a:	8082                	ret
    panic("iget: no inodes");
    8000373c:	00005517          	auipc	a0,0x5
    80003740:	f2450513          	addi	a0,a0,-220 # 80008660 <syscalls+0x140>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	dfa080e7          	jalr	-518(ra) # 8000053e <panic>

000000008000374c <fsinit>:
fsinit(int dev) {
    8000374c:	7179                	addi	sp,sp,-48
    8000374e:	f406                	sd	ra,40(sp)
    80003750:	f022                	sd	s0,32(sp)
    80003752:	ec26                	sd	s1,24(sp)
    80003754:	e84a                	sd	s2,16(sp)
    80003756:	e44e                	sd	s3,8(sp)
    80003758:	1800                	addi	s0,sp,48
    8000375a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000375c:	4585                	li	a1,1
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	a64080e7          	jalr	-1436(ra) # 800031c2 <bread>
    80003766:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003768:	0001c997          	auipc	s3,0x1c
    8000376c:	44098993          	addi	s3,s3,1088 # 8001fba8 <sb>
    80003770:	02000613          	li	a2,32
    80003774:	05850593          	addi	a1,a0,88
    80003778:	854e                	mv	a0,s3
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	5c6080e7          	jalr	1478(ra) # 80000d40 <memmove>
  brelse(bp);
    80003782:	8526                	mv	a0,s1
    80003784:	00000097          	auipc	ra,0x0
    80003788:	b6e080e7          	jalr	-1170(ra) # 800032f2 <brelse>
  if(sb.magic != FSMAGIC)
    8000378c:	0009a703          	lw	a4,0(s3)
    80003790:	102037b7          	lui	a5,0x10203
    80003794:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003798:	02f71263          	bne	a4,a5,800037bc <fsinit+0x70>
  initlog(dev, &sb);
    8000379c:	0001c597          	auipc	a1,0x1c
    800037a0:	40c58593          	addi	a1,a1,1036 # 8001fba8 <sb>
    800037a4:	854a                	mv	a0,s2
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	b4c080e7          	jalr	-1204(ra) # 800042f2 <initlog>
}
    800037ae:	70a2                	ld	ra,40(sp)
    800037b0:	7402                	ld	s0,32(sp)
    800037b2:	64e2                	ld	s1,24(sp)
    800037b4:	6942                	ld	s2,16(sp)
    800037b6:	69a2                	ld	s3,8(sp)
    800037b8:	6145                	addi	sp,sp,48
    800037ba:	8082                	ret
    panic("invalid file system");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	eb450513          	addi	a0,a0,-332 # 80008670 <syscalls+0x150>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>

00000000800037cc <iinit>:
{
    800037cc:	7179                	addi	sp,sp,-48
    800037ce:	f406                	sd	ra,40(sp)
    800037d0:	f022                	sd	s0,32(sp)
    800037d2:	ec26                	sd	s1,24(sp)
    800037d4:	e84a                	sd	s2,16(sp)
    800037d6:	e44e                	sd	s3,8(sp)
    800037d8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037da:	00005597          	auipc	a1,0x5
    800037de:	eae58593          	addi	a1,a1,-338 # 80008688 <syscalls+0x168>
    800037e2:	0001c517          	auipc	a0,0x1c
    800037e6:	3e650513          	addi	a0,a0,998 # 8001fbc8 <itable>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	36a080e7          	jalr	874(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037f2:	0001c497          	auipc	s1,0x1c
    800037f6:	3fe48493          	addi	s1,s1,1022 # 8001fbf0 <itable+0x28>
    800037fa:	0001e997          	auipc	s3,0x1e
    800037fe:	e8698993          	addi	s3,s3,-378 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003802:	00005917          	auipc	s2,0x5
    80003806:	e8e90913          	addi	s2,s2,-370 # 80008690 <syscalls+0x170>
    8000380a:	85ca                	mv	a1,s2
    8000380c:	8526                	mv	a0,s1
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	e46080e7          	jalr	-442(ra) # 80004654 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003816:	08848493          	addi	s1,s1,136
    8000381a:	ff3498e3          	bne	s1,s3,8000380a <iinit+0x3e>
}
    8000381e:	70a2                	ld	ra,40(sp)
    80003820:	7402                	ld	s0,32(sp)
    80003822:	64e2                	ld	s1,24(sp)
    80003824:	6942                	ld	s2,16(sp)
    80003826:	69a2                	ld	s3,8(sp)
    80003828:	6145                	addi	sp,sp,48
    8000382a:	8082                	ret

000000008000382c <ialloc>:
{
    8000382c:	715d                	addi	sp,sp,-80
    8000382e:	e486                	sd	ra,72(sp)
    80003830:	e0a2                	sd	s0,64(sp)
    80003832:	fc26                	sd	s1,56(sp)
    80003834:	f84a                	sd	s2,48(sp)
    80003836:	f44e                	sd	s3,40(sp)
    80003838:	f052                	sd	s4,32(sp)
    8000383a:	ec56                	sd	s5,24(sp)
    8000383c:	e85a                	sd	s6,16(sp)
    8000383e:	e45e                	sd	s7,8(sp)
    80003840:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003842:	0001c717          	auipc	a4,0x1c
    80003846:	37272703          	lw	a4,882(a4) # 8001fbb4 <sb+0xc>
    8000384a:	4785                	li	a5,1
    8000384c:	04e7fa63          	bgeu	a5,a4,800038a0 <ialloc+0x74>
    80003850:	8aaa                	mv	s5,a0
    80003852:	8bae                	mv	s7,a1
    80003854:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003856:	0001ca17          	auipc	s4,0x1c
    8000385a:	352a0a13          	addi	s4,s4,850 # 8001fba8 <sb>
    8000385e:	00048b1b          	sext.w	s6,s1
    80003862:	0044d593          	srli	a1,s1,0x4
    80003866:	018a2783          	lw	a5,24(s4)
    8000386a:	9dbd                	addw	a1,a1,a5
    8000386c:	8556                	mv	a0,s5
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	954080e7          	jalr	-1708(ra) # 800031c2 <bread>
    80003876:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003878:	05850993          	addi	s3,a0,88
    8000387c:	00f4f793          	andi	a5,s1,15
    80003880:	079a                	slli	a5,a5,0x6
    80003882:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003884:	00099783          	lh	a5,0(s3)
    80003888:	c785                	beqz	a5,800038b0 <ialloc+0x84>
    brelse(bp);
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	a68080e7          	jalr	-1432(ra) # 800032f2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003892:	0485                	addi	s1,s1,1
    80003894:	00ca2703          	lw	a4,12(s4)
    80003898:	0004879b          	sext.w	a5,s1
    8000389c:	fce7e1e3          	bltu	a5,a4,8000385e <ialloc+0x32>
  panic("ialloc: no inodes");
    800038a0:	00005517          	auipc	a0,0x5
    800038a4:	df850513          	addi	a0,a0,-520 # 80008698 <syscalls+0x178>
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	c96080e7          	jalr	-874(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800038b0:	04000613          	li	a2,64
    800038b4:	4581                	li	a1,0
    800038b6:	854e                	mv	a0,s3
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	428080e7          	jalr	1064(ra) # 80000ce0 <memset>
      dip->type = type;
    800038c0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038c4:	854a                	mv	a0,s2
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	ca8080e7          	jalr	-856(ra) # 8000456e <log_write>
      brelse(bp);
    800038ce:	854a                	mv	a0,s2
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	a22080e7          	jalr	-1502(ra) # 800032f2 <brelse>
      return iget(dev, inum);
    800038d8:	85da                	mv	a1,s6
    800038da:	8556                	mv	a0,s5
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	db4080e7          	jalr	-588(ra) # 80003690 <iget>
}
    800038e4:	60a6                	ld	ra,72(sp)
    800038e6:	6406                	ld	s0,64(sp)
    800038e8:	74e2                	ld	s1,56(sp)
    800038ea:	7942                	ld	s2,48(sp)
    800038ec:	79a2                	ld	s3,40(sp)
    800038ee:	7a02                	ld	s4,32(sp)
    800038f0:	6ae2                	ld	s5,24(sp)
    800038f2:	6b42                	ld	s6,16(sp)
    800038f4:	6ba2                	ld	s7,8(sp)
    800038f6:	6161                	addi	sp,sp,80
    800038f8:	8082                	ret

00000000800038fa <iupdate>:
{
    800038fa:	1101                	addi	sp,sp,-32
    800038fc:	ec06                	sd	ra,24(sp)
    800038fe:	e822                	sd	s0,16(sp)
    80003900:	e426                	sd	s1,8(sp)
    80003902:	e04a                	sd	s2,0(sp)
    80003904:	1000                	addi	s0,sp,32
    80003906:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003908:	415c                	lw	a5,4(a0)
    8000390a:	0047d79b          	srliw	a5,a5,0x4
    8000390e:	0001c597          	auipc	a1,0x1c
    80003912:	2b25a583          	lw	a1,690(a1) # 8001fbc0 <sb+0x18>
    80003916:	9dbd                	addw	a1,a1,a5
    80003918:	4108                	lw	a0,0(a0)
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	8a8080e7          	jalr	-1880(ra) # 800031c2 <bread>
    80003922:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003924:	05850793          	addi	a5,a0,88
    80003928:	40c8                	lw	a0,4(s1)
    8000392a:	893d                	andi	a0,a0,15
    8000392c:	051a                	slli	a0,a0,0x6
    8000392e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003930:	04449703          	lh	a4,68(s1)
    80003934:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003938:	04649703          	lh	a4,70(s1)
    8000393c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003940:	04849703          	lh	a4,72(s1)
    80003944:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003948:	04a49703          	lh	a4,74(s1)
    8000394c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003950:	44f8                	lw	a4,76(s1)
    80003952:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003954:	03400613          	li	a2,52
    80003958:	05048593          	addi	a1,s1,80
    8000395c:	0531                	addi	a0,a0,12
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	3e2080e7          	jalr	994(ra) # 80000d40 <memmove>
  log_write(bp);
    80003966:	854a                	mv	a0,s2
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	c06080e7          	jalr	-1018(ra) # 8000456e <log_write>
  brelse(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00000097          	auipc	ra,0x0
    80003976:	980080e7          	jalr	-1664(ra) # 800032f2 <brelse>
}
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6902                	ld	s2,0(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret

0000000080003986 <idup>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	1000                	addi	s0,sp,32
    80003990:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003992:	0001c517          	auipc	a0,0x1c
    80003996:	23650513          	addi	a0,a0,566 # 8001fbc8 <itable>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	24a080e7          	jalr	586(ra) # 80000be4 <acquire>
  ip->ref++;
    800039a2:	449c                	lw	a5,8(s1)
    800039a4:	2785                	addiw	a5,a5,1
    800039a6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039a8:	0001c517          	auipc	a0,0x1c
    800039ac:	22050513          	addi	a0,a0,544 # 8001fbc8 <itable>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	2e8080e7          	jalr	744(ra) # 80000c98 <release>
}
    800039b8:	8526                	mv	a0,s1
    800039ba:	60e2                	ld	ra,24(sp)
    800039bc:	6442                	ld	s0,16(sp)
    800039be:	64a2                	ld	s1,8(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret

00000000800039c4 <ilock>:
{
    800039c4:	1101                	addi	sp,sp,-32
    800039c6:	ec06                	sd	ra,24(sp)
    800039c8:	e822                	sd	s0,16(sp)
    800039ca:	e426                	sd	s1,8(sp)
    800039cc:	e04a                	sd	s2,0(sp)
    800039ce:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039d0:	c115                	beqz	a0,800039f4 <ilock+0x30>
    800039d2:	84aa                	mv	s1,a0
    800039d4:	451c                	lw	a5,8(a0)
    800039d6:	00f05f63          	blez	a5,800039f4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039da:	0541                	addi	a0,a0,16
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	cb2080e7          	jalr	-846(ra) # 8000468e <acquiresleep>
  if(ip->valid == 0){
    800039e4:	40bc                	lw	a5,64(s1)
    800039e6:	cf99                	beqz	a5,80003a04 <ilock+0x40>
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6902                	ld	s2,0(sp)
    800039f0:	6105                	addi	sp,sp,32
    800039f2:	8082                	ret
    panic("ilock");
    800039f4:	00005517          	auipc	a0,0x5
    800039f8:	cbc50513          	addi	a0,a0,-836 # 800086b0 <syscalls+0x190>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a04:	40dc                	lw	a5,4(s1)
    80003a06:	0047d79b          	srliw	a5,a5,0x4
    80003a0a:	0001c597          	auipc	a1,0x1c
    80003a0e:	1b65a583          	lw	a1,438(a1) # 8001fbc0 <sb+0x18>
    80003a12:	9dbd                	addw	a1,a1,a5
    80003a14:	4088                	lw	a0,0(s1)
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	7ac080e7          	jalr	1964(ra) # 800031c2 <bread>
    80003a1e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a20:	05850593          	addi	a1,a0,88
    80003a24:	40dc                	lw	a5,4(s1)
    80003a26:	8bbd                	andi	a5,a5,15
    80003a28:	079a                	slli	a5,a5,0x6
    80003a2a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a2c:	00059783          	lh	a5,0(a1)
    80003a30:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a34:	00259783          	lh	a5,2(a1)
    80003a38:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a3c:	00459783          	lh	a5,4(a1)
    80003a40:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a44:	00659783          	lh	a5,6(a1)
    80003a48:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a4c:	459c                	lw	a5,8(a1)
    80003a4e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a50:	03400613          	li	a2,52
    80003a54:	05b1                	addi	a1,a1,12
    80003a56:	05048513          	addi	a0,s1,80
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	2e6080e7          	jalr	742(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a62:	854a                	mv	a0,s2
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	88e080e7          	jalr	-1906(ra) # 800032f2 <brelse>
    ip->valid = 1;
    80003a6c:	4785                	li	a5,1
    80003a6e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a70:	04449783          	lh	a5,68(s1)
    80003a74:	fbb5                	bnez	a5,800039e8 <ilock+0x24>
      panic("ilock: no type");
    80003a76:	00005517          	auipc	a0,0x5
    80003a7a:	c4250513          	addi	a0,a0,-958 # 800086b8 <syscalls+0x198>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>

0000000080003a86 <iunlock>:
{
    80003a86:	1101                	addi	sp,sp,-32
    80003a88:	ec06                	sd	ra,24(sp)
    80003a8a:	e822                	sd	s0,16(sp)
    80003a8c:	e426                	sd	s1,8(sp)
    80003a8e:	e04a                	sd	s2,0(sp)
    80003a90:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a92:	c905                	beqz	a0,80003ac2 <iunlock+0x3c>
    80003a94:	84aa                	mv	s1,a0
    80003a96:	01050913          	addi	s2,a0,16
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	c8c080e7          	jalr	-884(ra) # 80004728 <holdingsleep>
    80003aa4:	cd19                	beqz	a0,80003ac2 <iunlock+0x3c>
    80003aa6:	449c                	lw	a5,8(s1)
    80003aa8:	00f05d63          	blez	a5,80003ac2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	c36080e7          	jalr	-970(ra) # 800046e4 <releasesleep>
}
    80003ab6:	60e2                	ld	ra,24(sp)
    80003ab8:	6442                	ld	s0,16(sp)
    80003aba:	64a2                	ld	s1,8(sp)
    80003abc:	6902                	ld	s2,0(sp)
    80003abe:	6105                	addi	sp,sp,32
    80003ac0:	8082                	ret
    panic("iunlock");
    80003ac2:	00005517          	auipc	a0,0x5
    80003ac6:	c0650513          	addi	a0,a0,-1018 # 800086c8 <syscalls+0x1a8>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	a74080e7          	jalr	-1420(ra) # 8000053e <panic>

0000000080003ad2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ad2:	7179                	addi	sp,sp,-48
    80003ad4:	f406                	sd	ra,40(sp)
    80003ad6:	f022                	sd	s0,32(sp)
    80003ad8:	ec26                	sd	s1,24(sp)
    80003ada:	e84a                	sd	s2,16(sp)
    80003adc:	e44e                	sd	s3,8(sp)
    80003ade:	e052                	sd	s4,0(sp)
    80003ae0:	1800                	addi	s0,sp,48
    80003ae2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ae4:	05050493          	addi	s1,a0,80
    80003ae8:	08050913          	addi	s2,a0,128
    80003aec:	a021                	j	80003af4 <itrunc+0x22>
    80003aee:	0491                	addi	s1,s1,4
    80003af0:	01248d63          	beq	s1,s2,80003b0a <itrunc+0x38>
    if(ip->addrs[i]){
    80003af4:	408c                	lw	a1,0(s1)
    80003af6:	dde5                	beqz	a1,80003aee <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003af8:	0009a503          	lw	a0,0(s3)
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	90c080e7          	jalr	-1780(ra) # 80003408 <bfree>
      ip->addrs[i] = 0;
    80003b04:	0004a023          	sw	zero,0(s1)
    80003b08:	b7dd                	j	80003aee <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b0a:	0809a583          	lw	a1,128(s3)
    80003b0e:	e185                	bnez	a1,80003b2e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b10:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b14:	854e                	mv	a0,s3
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	de4080e7          	jalr	-540(ra) # 800038fa <iupdate>
}
    80003b1e:	70a2                	ld	ra,40(sp)
    80003b20:	7402                	ld	s0,32(sp)
    80003b22:	64e2                	ld	s1,24(sp)
    80003b24:	6942                	ld	s2,16(sp)
    80003b26:	69a2                	ld	s3,8(sp)
    80003b28:	6a02                	ld	s4,0(sp)
    80003b2a:	6145                	addi	sp,sp,48
    80003b2c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b2e:	0009a503          	lw	a0,0(s3)
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	690080e7          	jalr	1680(ra) # 800031c2 <bread>
    80003b3a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b3c:	05850493          	addi	s1,a0,88
    80003b40:	45850913          	addi	s2,a0,1112
    80003b44:	a811                	j	80003b58 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b46:	0009a503          	lw	a0,0(s3)
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	8be080e7          	jalr	-1858(ra) # 80003408 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b52:	0491                	addi	s1,s1,4
    80003b54:	01248563          	beq	s1,s2,80003b5e <itrunc+0x8c>
      if(a[j])
    80003b58:	408c                	lw	a1,0(s1)
    80003b5a:	dde5                	beqz	a1,80003b52 <itrunc+0x80>
    80003b5c:	b7ed                	j	80003b46 <itrunc+0x74>
    brelse(bp);
    80003b5e:	8552                	mv	a0,s4
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	792080e7          	jalr	1938(ra) # 800032f2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b68:	0809a583          	lw	a1,128(s3)
    80003b6c:	0009a503          	lw	a0,0(s3)
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	898080e7          	jalr	-1896(ra) # 80003408 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b78:	0809a023          	sw	zero,128(s3)
    80003b7c:	bf51                	j	80003b10 <itrunc+0x3e>

0000000080003b7e <iput>:
{
    80003b7e:	1101                	addi	sp,sp,-32
    80003b80:	ec06                	sd	ra,24(sp)
    80003b82:	e822                	sd	s0,16(sp)
    80003b84:	e426                	sd	s1,8(sp)
    80003b86:	e04a                	sd	s2,0(sp)
    80003b88:	1000                	addi	s0,sp,32
    80003b8a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b8c:	0001c517          	auipc	a0,0x1c
    80003b90:	03c50513          	addi	a0,a0,60 # 8001fbc8 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	050080e7          	jalr	80(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b9c:	4498                	lw	a4,8(s1)
    80003b9e:	4785                	li	a5,1
    80003ba0:	02f70363          	beq	a4,a5,80003bc6 <iput+0x48>
  ip->ref--;
    80003ba4:	449c                	lw	a5,8(s1)
    80003ba6:	37fd                	addiw	a5,a5,-1
    80003ba8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003baa:	0001c517          	auipc	a0,0x1c
    80003bae:	01e50513          	addi	a0,a0,30 # 8001fbc8 <itable>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
}
    80003bba:	60e2                	ld	ra,24(sp)
    80003bbc:	6442                	ld	s0,16(sp)
    80003bbe:	64a2                	ld	s1,8(sp)
    80003bc0:	6902                	ld	s2,0(sp)
    80003bc2:	6105                	addi	sp,sp,32
    80003bc4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc6:	40bc                	lw	a5,64(s1)
    80003bc8:	dff1                	beqz	a5,80003ba4 <iput+0x26>
    80003bca:	04a49783          	lh	a5,74(s1)
    80003bce:	fbf9                	bnez	a5,80003ba4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bd0:	01048913          	addi	s2,s1,16
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	ab8080e7          	jalr	-1352(ra) # 8000468e <acquiresleep>
    release(&itable.lock);
    80003bde:	0001c517          	auipc	a0,0x1c
    80003be2:	fea50513          	addi	a0,a0,-22 # 8001fbc8 <itable>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
    itrunc(ip);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	ee2080e7          	jalr	-286(ra) # 80003ad2 <itrunc>
    ip->type = 0;
    80003bf8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bfc:	8526                	mv	a0,s1
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	cfc080e7          	jalr	-772(ra) # 800038fa <iupdate>
    ip->valid = 0;
    80003c06:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	00001097          	auipc	ra,0x1
    80003c10:	ad8080e7          	jalr	-1320(ra) # 800046e4 <releasesleep>
    acquire(&itable.lock);
    80003c14:	0001c517          	auipc	a0,0x1c
    80003c18:	fb450513          	addi	a0,a0,-76 # 8001fbc8 <itable>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	fc8080e7          	jalr	-56(ra) # 80000be4 <acquire>
    80003c24:	b741                	j	80003ba4 <iput+0x26>

0000000080003c26 <iunlockput>:
{
    80003c26:	1101                	addi	sp,sp,-32
    80003c28:	ec06                	sd	ra,24(sp)
    80003c2a:	e822                	sd	s0,16(sp)
    80003c2c:	e426                	sd	s1,8(sp)
    80003c2e:	1000                	addi	s0,sp,32
    80003c30:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	e54080e7          	jalr	-428(ra) # 80003a86 <iunlock>
  iput(ip);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	f42080e7          	jalr	-190(ra) # 80003b7e <iput>
}
    80003c44:	60e2                	ld	ra,24(sp)
    80003c46:	6442                	ld	s0,16(sp)
    80003c48:	64a2                	ld	s1,8(sp)
    80003c4a:	6105                	addi	sp,sp,32
    80003c4c:	8082                	ret

0000000080003c4e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c4e:	1141                	addi	sp,sp,-16
    80003c50:	e422                	sd	s0,8(sp)
    80003c52:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c54:	411c                	lw	a5,0(a0)
    80003c56:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c58:	415c                	lw	a5,4(a0)
    80003c5a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c5c:	04451783          	lh	a5,68(a0)
    80003c60:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c64:	04a51783          	lh	a5,74(a0)
    80003c68:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c6c:	04c56783          	lwu	a5,76(a0)
    80003c70:	e99c                	sd	a5,16(a1)
}
    80003c72:	6422                	ld	s0,8(sp)
    80003c74:	0141                	addi	sp,sp,16
    80003c76:	8082                	ret

0000000080003c78 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c78:	457c                	lw	a5,76(a0)
    80003c7a:	0ed7e963          	bltu	a5,a3,80003d6c <readi+0xf4>
{
    80003c7e:	7159                	addi	sp,sp,-112
    80003c80:	f486                	sd	ra,104(sp)
    80003c82:	f0a2                	sd	s0,96(sp)
    80003c84:	eca6                	sd	s1,88(sp)
    80003c86:	e8ca                	sd	s2,80(sp)
    80003c88:	e4ce                	sd	s3,72(sp)
    80003c8a:	e0d2                	sd	s4,64(sp)
    80003c8c:	fc56                	sd	s5,56(sp)
    80003c8e:	f85a                	sd	s6,48(sp)
    80003c90:	f45e                	sd	s7,40(sp)
    80003c92:	f062                	sd	s8,32(sp)
    80003c94:	ec66                	sd	s9,24(sp)
    80003c96:	e86a                	sd	s10,16(sp)
    80003c98:	e46e                	sd	s11,8(sp)
    80003c9a:	1880                	addi	s0,sp,112
    80003c9c:	8baa                	mv	s7,a0
    80003c9e:	8c2e                	mv	s8,a1
    80003ca0:	8ab2                	mv	s5,a2
    80003ca2:	84b6                	mv	s1,a3
    80003ca4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ca6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ca8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003caa:	0ad76063          	bltu	a4,a3,80003d4a <readi+0xd2>
  if(off + n > ip->size)
    80003cae:	00e7f463          	bgeu	a5,a4,80003cb6 <readi+0x3e>
    n = ip->size - off;
    80003cb2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb6:	0a0b0963          	beqz	s6,80003d68 <readi+0xf0>
    80003cba:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cbc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cc0:	5cfd                	li	s9,-1
    80003cc2:	a82d                	j	80003cfc <readi+0x84>
    80003cc4:	020a1d93          	slli	s11,s4,0x20
    80003cc8:	020ddd93          	srli	s11,s11,0x20
    80003ccc:	05890613          	addi	a2,s2,88
    80003cd0:	86ee                	mv	a3,s11
    80003cd2:	963a                	add	a2,a2,a4
    80003cd4:	85d6                	mv	a1,s5
    80003cd6:	8562                	mv	a0,s8
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	948080e7          	jalr	-1720(ra) # 80002620 <either_copyout>
    80003ce0:	05950d63          	beq	a0,s9,80003d3a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ce4:	854a                	mv	a0,s2
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	60c080e7          	jalr	1548(ra) # 800032f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cee:	013a09bb          	addw	s3,s4,s3
    80003cf2:	009a04bb          	addw	s1,s4,s1
    80003cf6:	9aee                	add	s5,s5,s11
    80003cf8:	0569f763          	bgeu	s3,s6,80003d46 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cfc:	000ba903          	lw	s2,0(s7)
    80003d00:	00a4d59b          	srliw	a1,s1,0xa
    80003d04:	855e                	mv	a0,s7
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	8b0080e7          	jalr	-1872(ra) # 800035b6 <bmap>
    80003d0e:	0005059b          	sext.w	a1,a0
    80003d12:	854a                	mv	a0,s2
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	4ae080e7          	jalr	1198(ra) # 800031c2 <bread>
    80003d1c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d1e:	3ff4f713          	andi	a4,s1,1023
    80003d22:	40ed07bb          	subw	a5,s10,a4
    80003d26:	413b06bb          	subw	a3,s6,s3
    80003d2a:	8a3e                	mv	s4,a5
    80003d2c:	2781                	sext.w	a5,a5
    80003d2e:	0006861b          	sext.w	a2,a3
    80003d32:	f8f679e3          	bgeu	a2,a5,80003cc4 <readi+0x4c>
    80003d36:	8a36                	mv	s4,a3
    80003d38:	b771                	j	80003cc4 <readi+0x4c>
      brelse(bp);
    80003d3a:	854a                	mv	a0,s2
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	5b6080e7          	jalr	1462(ra) # 800032f2 <brelse>
      tot = -1;
    80003d44:	59fd                	li	s3,-1
  }
  return tot;
    80003d46:	0009851b          	sext.w	a0,s3
}
    80003d4a:	70a6                	ld	ra,104(sp)
    80003d4c:	7406                	ld	s0,96(sp)
    80003d4e:	64e6                	ld	s1,88(sp)
    80003d50:	6946                	ld	s2,80(sp)
    80003d52:	69a6                	ld	s3,72(sp)
    80003d54:	6a06                	ld	s4,64(sp)
    80003d56:	7ae2                	ld	s5,56(sp)
    80003d58:	7b42                	ld	s6,48(sp)
    80003d5a:	7ba2                	ld	s7,40(sp)
    80003d5c:	7c02                	ld	s8,32(sp)
    80003d5e:	6ce2                	ld	s9,24(sp)
    80003d60:	6d42                	ld	s10,16(sp)
    80003d62:	6da2                	ld	s11,8(sp)
    80003d64:	6165                	addi	sp,sp,112
    80003d66:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d68:	89da                	mv	s3,s6
    80003d6a:	bff1                	j	80003d46 <readi+0xce>
    return 0;
    80003d6c:	4501                	li	a0,0
}
    80003d6e:	8082                	ret

0000000080003d70 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d70:	457c                	lw	a5,76(a0)
    80003d72:	10d7e863          	bltu	a5,a3,80003e82 <writei+0x112>
{
    80003d76:	7159                	addi	sp,sp,-112
    80003d78:	f486                	sd	ra,104(sp)
    80003d7a:	f0a2                	sd	s0,96(sp)
    80003d7c:	eca6                	sd	s1,88(sp)
    80003d7e:	e8ca                	sd	s2,80(sp)
    80003d80:	e4ce                	sd	s3,72(sp)
    80003d82:	e0d2                	sd	s4,64(sp)
    80003d84:	fc56                	sd	s5,56(sp)
    80003d86:	f85a                	sd	s6,48(sp)
    80003d88:	f45e                	sd	s7,40(sp)
    80003d8a:	f062                	sd	s8,32(sp)
    80003d8c:	ec66                	sd	s9,24(sp)
    80003d8e:	e86a                	sd	s10,16(sp)
    80003d90:	e46e                	sd	s11,8(sp)
    80003d92:	1880                	addi	s0,sp,112
    80003d94:	8b2a                	mv	s6,a0
    80003d96:	8c2e                	mv	s8,a1
    80003d98:	8ab2                	mv	s5,a2
    80003d9a:	8936                	mv	s2,a3
    80003d9c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d9e:	00e687bb          	addw	a5,a3,a4
    80003da2:	0ed7e263          	bltu	a5,a3,80003e86 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003da6:	00043737          	lui	a4,0x43
    80003daa:	0ef76063          	bltu	a4,a5,80003e8a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dae:	0c0b8863          	beqz	s7,80003e7e <writei+0x10e>
    80003db2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003db8:	5cfd                	li	s9,-1
    80003dba:	a091                	j	80003dfe <writei+0x8e>
    80003dbc:	02099d93          	slli	s11,s3,0x20
    80003dc0:	020ddd93          	srli	s11,s11,0x20
    80003dc4:	05848513          	addi	a0,s1,88
    80003dc8:	86ee                	mv	a3,s11
    80003dca:	8656                	mv	a2,s5
    80003dcc:	85e2                	mv	a1,s8
    80003dce:	953a                	add	a0,a0,a4
    80003dd0:	fffff097          	auipc	ra,0xfffff
    80003dd4:	8a6080e7          	jalr	-1882(ra) # 80002676 <either_copyin>
    80003dd8:	07950263          	beq	a0,s9,80003e3c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ddc:	8526                	mv	a0,s1
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	790080e7          	jalr	1936(ra) # 8000456e <log_write>
    brelse(bp);
    80003de6:	8526                	mv	a0,s1
    80003de8:	fffff097          	auipc	ra,0xfffff
    80003dec:	50a080e7          	jalr	1290(ra) # 800032f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df0:	01498a3b          	addw	s4,s3,s4
    80003df4:	0129893b          	addw	s2,s3,s2
    80003df8:	9aee                	add	s5,s5,s11
    80003dfa:	057a7663          	bgeu	s4,s7,80003e46 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dfe:	000b2483          	lw	s1,0(s6)
    80003e02:	00a9559b          	srliw	a1,s2,0xa
    80003e06:	855a                	mv	a0,s6
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	7ae080e7          	jalr	1966(ra) # 800035b6 <bmap>
    80003e10:	0005059b          	sext.w	a1,a0
    80003e14:	8526                	mv	a0,s1
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	3ac080e7          	jalr	940(ra) # 800031c2 <bread>
    80003e1e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e20:	3ff97713          	andi	a4,s2,1023
    80003e24:	40ed07bb          	subw	a5,s10,a4
    80003e28:	414b86bb          	subw	a3,s7,s4
    80003e2c:	89be                	mv	s3,a5
    80003e2e:	2781                	sext.w	a5,a5
    80003e30:	0006861b          	sext.w	a2,a3
    80003e34:	f8f674e3          	bgeu	a2,a5,80003dbc <writei+0x4c>
    80003e38:	89b6                	mv	s3,a3
    80003e3a:	b749                	j	80003dbc <writei+0x4c>
      brelse(bp);
    80003e3c:	8526                	mv	a0,s1
    80003e3e:	fffff097          	auipc	ra,0xfffff
    80003e42:	4b4080e7          	jalr	1204(ra) # 800032f2 <brelse>
  }

  if(off > ip->size)
    80003e46:	04cb2783          	lw	a5,76(s6)
    80003e4a:	0127f463          	bgeu	a5,s2,80003e52 <writei+0xe2>
    ip->size = off;
    80003e4e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e52:	855a                	mv	a0,s6
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	aa6080e7          	jalr	-1370(ra) # 800038fa <iupdate>

  return tot;
    80003e5c:	000a051b          	sext.w	a0,s4
}
    80003e60:	70a6                	ld	ra,104(sp)
    80003e62:	7406                	ld	s0,96(sp)
    80003e64:	64e6                	ld	s1,88(sp)
    80003e66:	6946                	ld	s2,80(sp)
    80003e68:	69a6                	ld	s3,72(sp)
    80003e6a:	6a06                	ld	s4,64(sp)
    80003e6c:	7ae2                	ld	s5,56(sp)
    80003e6e:	7b42                	ld	s6,48(sp)
    80003e70:	7ba2                	ld	s7,40(sp)
    80003e72:	7c02                	ld	s8,32(sp)
    80003e74:	6ce2                	ld	s9,24(sp)
    80003e76:	6d42                	ld	s10,16(sp)
    80003e78:	6da2                	ld	s11,8(sp)
    80003e7a:	6165                	addi	sp,sp,112
    80003e7c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e7e:	8a5e                	mv	s4,s7
    80003e80:	bfc9                	j	80003e52 <writei+0xe2>
    return -1;
    80003e82:	557d                	li	a0,-1
}
    80003e84:	8082                	ret
    return -1;
    80003e86:	557d                	li	a0,-1
    80003e88:	bfe1                	j	80003e60 <writei+0xf0>
    return -1;
    80003e8a:	557d                	li	a0,-1
    80003e8c:	bfd1                	j	80003e60 <writei+0xf0>

0000000080003e8e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e8e:	1141                	addi	sp,sp,-16
    80003e90:	e406                	sd	ra,8(sp)
    80003e92:	e022                	sd	s0,0(sp)
    80003e94:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e96:	4639                	li	a2,14
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	f20080e7          	jalr	-224(ra) # 80000db8 <strncmp>
}
    80003ea0:	60a2                	ld	ra,8(sp)
    80003ea2:	6402                	ld	s0,0(sp)
    80003ea4:	0141                	addi	sp,sp,16
    80003ea6:	8082                	ret

0000000080003ea8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ea8:	7139                	addi	sp,sp,-64
    80003eaa:	fc06                	sd	ra,56(sp)
    80003eac:	f822                	sd	s0,48(sp)
    80003eae:	f426                	sd	s1,40(sp)
    80003eb0:	f04a                	sd	s2,32(sp)
    80003eb2:	ec4e                	sd	s3,24(sp)
    80003eb4:	e852                	sd	s4,16(sp)
    80003eb6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eb8:	04451703          	lh	a4,68(a0)
    80003ebc:	4785                	li	a5,1
    80003ebe:	00f71a63          	bne	a4,a5,80003ed2 <dirlookup+0x2a>
    80003ec2:	892a                	mv	s2,a0
    80003ec4:	89ae                	mv	s3,a1
    80003ec6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec8:	457c                	lw	a5,76(a0)
    80003eca:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ecc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ece:	e79d                	bnez	a5,80003efc <dirlookup+0x54>
    80003ed0:	a8a5                	j	80003f48 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ed2:	00004517          	auipc	a0,0x4
    80003ed6:	7fe50513          	addi	a0,a0,2046 # 800086d0 <syscalls+0x1b0>
    80003eda:	ffffc097          	auipc	ra,0xffffc
    80003ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ee2:	00005517          	auipc	a0,0x5
    80003ee6:	80650513          	addi	a0,a0,-2042 # 800086e8 <syscalls+0x1c8>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef2:	24c1                	addiw	s1,s1,16
    80003ef4:	04c92783          	lw	a5,76(s2)
    80003ef8:	04f4f763          	bgeu	s1,a5,80003f46 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efc:	4741                	li	a4,16
    80003efe:	86a6                	mv	a3,s1
    80003f00:	fc040613          	addi	a2,s0,-64
    80003f04:	4581                	li	a1,0
    80003f06:	854a                	mv	a0,s2
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	d70080e7          	jalr	-656(ra) # 80003c78 <readi>
    80003f10:	47c1                	li	a5,16
    80003f12:	fcf518e3          	bne	a0,a5,80003ee2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f16:	fc045783          	lhu	a5,-64(s0)
    80003f1a:	dfe1                	beqz	a5,80003ef2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f1c:	fc240593          	addi	a1,s0,-62
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	f6c080e7          	jalr	-148(ra) # 80003e8e <namecmp>
    80003f2a:	f561                	bnez	a0,80003ef2 <dirlookup+0x4a>
      if(poff)
    80003f2c:	000a0463          	beqz	s4,80003f34 <dirlookup+0x8c>
        *poff = off;
    80003f30:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f34:	fc045583          	lhu	a1,-64(s0)
    80003f38:	00092503          	lw	a0,0(s2)
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	754080e7          	jalr	1876(ra) # 80003690 <iget>
    80003f44:	a011                	j	80003f48 <dirlookup+0xa0>
  return 0;
    80003f46:	4501                	li	a0,0
}
    80003f48:	70e2                	ld	ra,56(sp)
    80003f4a:	7442                	ld	s0,48(sp)
    80003f4c:	74a2                	ld	s1,40(sp)
    80003f4e:	7902                	ld	s2,32(sp)
    80003f50:	69e2                	ld	s3,24(sp)
    80003f52:	6a42                	ld	s4,16(sp)
    80003f54:	6121                	addi	sp,sp,64
    80003f56:	8082                	ret

0000000080003f58 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f58:	711d                	addi	sp,sp,-96
    80003f5a:	ec86                	sd	ra,88(sp)
    80003f5c:	e8a2                	sd	s0,80(sp)
    80003f5e:	e4a6                	sd	s1,72(sp)
    80003f60:	e0ca                	sd	s2,64(sp)
    80003f62:	fc4e                	sd	s3,56(sp)
    80003f64:	f852                	sd	s4,48(sp)
    80003f66:	f456                	sd	s5,40(sp)
    80003f68:	f05a                	sd	s6,32(sp)
    80003f6a:	ec5e                	sd	s7,24(sp)
    80003f6c:	e862                	sd	s8,16(sp)
    80003f6e:	e466                	sd	s9,8(sp)
    80003f70:	1080                	addi	s0,sp,96
    80003f72:	84aa                	mv	s1,a0
    80003f74:	8b2e                	mv	s6,a1
    80003f76:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f78:	00054703          	lbu	a4,0(a0)
    80003f7c:	02f00793          	li	a5,47
    80003f80:	02f70363          	beq	a4,a5,80003fa6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f84:	ffffe097          	auipc	ra,0xffffe
    80003f88:	a2c080e7          	jalr	-1492(ra) # 800019b0 <myproc>
    80003f8c:	15053503          	ld	a0,336(a0)
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	9f6080e7          	jalr	-1546(ra) # 80003986 <idup>
    80003f98:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f9a:	02f00913          	li	s2,47
  len = path - s;
    80003f9e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003fa0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fa2:	4c05                	li	s8,1
    80003fa4:	a865                	j	8000405c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fa6:	4585                	li	a1,1
    80003fa8:	4505                	li	a0,1
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	6e6080e7          	jalr	1766(ra) # 80003690 <iget>
    80003fb2:	89aa                	mv	s3,a0
    80003fb4:	b7dd                	j	80003f9a <namex+0x42>
      iunlockput(ip);
    80003fb6:	854e                	mv	a0,s3
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	c6e080e7          	jalr	-914(ra) # 80003c26 <iunlockput>
      return 0;
    80003fc0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fc2:	854e                	mv	a0,s3
    80003fc4:	60e6                	ld	ra,88(sp)
    80003fc6:	6446                	ld	s0,80(sp)
    80003fc8:	64a6                	ld	s1,72(sp)
    80003fca:	6906                	ld	s2,64(sp)
    80003fcc:	79e2                	ld	s3,56(sp)
    80003fce:	7a42                	ld	s4,48(sp)
    80003fd0:	7aa2                	ld	s5,40(sp)
    80003fd2:	7b02                	ld	s6,32(sp)
    80003fd4:	6be2                	ld	s7,24(sp)
    80003fd6:	6c42                	ld	s8,16(sp)
    80003fd8:	6ca2                	ld	s9,8(sp)
    80003fda:	6125                	addi	sp,sp,96
    80003fdc:	8082                	ret
      iunlock(ip);
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	aa6080e7          	jalr	-1370(ra) # 80003a86 <iunlock>
      return ip;
    80003fe8:	bfe9                	j	80003fc2 <namex+0x6a>
      iunlockput(ip);
    80003fea:	854e                	mv	a0,s3
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	c3a080e7          	jalr	-966(ra) # 80003c26 <iunlockput>
      return 0;
    80003ff4:	89d2                	mv	s3,s4
    80003ff6:	b7f1                	j	80003fc2 <namex+0x6a>
  len = path - s;
    80003ff8:	40b48633          	sub	a2,s1,a1
    80003ffc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004000:	094cd463          	bge	s9,s4,80004088 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004004:	4639                	li	a2,14
    80004006:	8556                	mv	a0,s5
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	d38080e7          	jalr	-712(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	01279763          	bne	a5,s2,80004022 <namex+0xca>
    path++;
    80004018:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	ff278de3          	beq	a5,s2,80004018 <namex+0xc0>
    ilock(ip);
    80004022:	854e                	mv	a0,s3
    80004024:	00000097          	auipc	ra,0x0
    80004028:	9a0080e7          	jalr	-1632(ra) # 800039c4 <ilock>
    if(ip->type != T_DIR){
    8000402c:	04499783          	lh	a5,68(s3)
    80004030:	f98793e3          	bne	a5,s8,80003fb6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004034:	000b0563          	beqz	s6,8000403e <namex+0xe6>
    80004038:	0004c783          	lbu	a5,0(s1)
    8000403c:	d3cd                	beqz	a5,80003fde <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000403e:	865e                	mv	a2,s7
    80004040:	85d6                	mv	a1,s5
    80004042:	854e                	mv	a0,s3
    80004044:	00000097          	auipc	ra,0x0
    80004048:	e64080e7          	jalr	-412(ra) # 80003ea8 <dirlookup>
    8000404c:	8a2a                	mv	s4,a0
    8000404e:	dd51                	beqz	a0,80003fea <namex+0x92>
    iunlockput(ip);
    80004050:	854e                	mv	a0,s3
    80004052:	00000097          	auipc	ra,0x0
    80004056:	bd4080e7          	jalr	-1068(ra) # 80003c26 <iunlockput>
    ip = next;
    8000405a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000405c:	0004c783          	lbu	a5,0(s1)
    80004060:	05279763          	bne	a5,s2,800040ae <namex+0x156>
    path++;
    80004064:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004066:	0004c783          	lbu	a5,0(s1)
    8000406a:	ff278de3          	beq	a5,s2,80004064 <namex+0x10c>
  if(*path == 0)
    8000406e:	c79d                	beqz	a5,8000409c <namex+0x144>
    path++;
    80004070:	85a6                	mv	a1,s1
  len = path - s;
    80004072:	8a5e                	mv	s4,s7
    80004074:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004076:	01278963          	beq	a5,s2,80004088 <namex+0x130>
    8000407a:	dfbd                	beqz	a5,80003ff8 <namex+0xa0>
    path++;
    8000407c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000407e:	0004c783          	lbu	a5,0(s1)
    80004082:	ff279ce3          	bne	a5,s2,8000407a <namex+0x122>
    80004086:	bf8d                	j	80003ff8 <namex+0xa0>
    memmove(name, s, len);
    80004088:	2601                	sext.w	a2,a2
    8000408a:	8556                	mv	a0,s5
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	cb4080e7          	jalr	-844(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004094:	9a56                	add	s4,s4,s5
    80004096:	000a0023          	sb	zero,0(s4)
    8000409a:	bf9d                	j	80004010 <namex+0xb8>
  if(nameiparent){
    8000409c:	f20b03e3          	beqz	s6,80003fc2 <namex+0x6a>
    iput(ip);
    800040a0:	854e                	mv	a0,s3
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	adc080e7          	jalr	-1316(ra) # 80003b7e <iput>
    return 0;
    800040aa:	4981                	li	s3,0
    800040ac:	bf19                	j	80003fc2 <namex+0x6a>
  if(*path == 0)
    800040ae:	d7fd                	beqz	a5,8000409c <namex+0x144>
  while(*path != '/' && *path != 0)
    800040b0:	0004c783          	lbu	a5,0(s1)
    800040b4:	85a6                	mv	a1,s1
    800040b6:	b7d1                	j	8000407a <namex+0x122>

00000000800040b8 <dirlink>:
{
    800040b8:	7139                	addi	sp,sp,-64
    800040ba:	fc06                	sd	ra,56(sp)
    800040bc:	f822                	sd	s0,48(sp)
    800040be:	f426                	sd	s1,40(sp)
    800040c0:	f04a                	sd	s2,32(sp)
    800040c2:	ec4e                	sd	s3,24(sp)
    800040c4:	e852                	sd	s4,16(sp)
    800040c6:	0080                	addi	s0,sp,64
    800040c8:	892a                	mv	s2,a0
    800040ca:	8a2e                	mv	s4,a1
    800040cc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040ce:	4601                	li	a2,0
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	dd8080e7          	jalr	-552(ra) # 80003ea8 <dirlookup>
    800040d8:	e93d                	bnez	a0,8000414e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040da:	04c92483          	lw	s1,76(s2)
    800040de:	c49d                	beqz	s1,8000410c <dirlink+0x54>
    800040e0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e2:	4741                	li	a4,16
    800040e4:	86a6                	mv	a3,s1
    800040e6:	fc040613          	addi	a2,s0,-64
    800040ea:	4581                	li	a1,0
    800040ec:	854a                	mv	a0,s2
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	b8a080e7          	jalr	-1142(ra) # 80003c78 <readi>
    800040f6:	47c1                	li	a5,16
    800040f8:	06f51163          	bne	a0,a5,8000415a <dirlink+0xa2>
    if(de.inum == 0)
    800040fc:	fc045783          	lhu	a5,-64(s0)
    80004100:	c791                	beqz	a5,8000410c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004102:	24c1                	addiw	s1,s1,16
    80004104:	04c92783          	lw	a5,76(s2)
    80004108:	fcf4ede3          	bltu	s1,a5,800040e2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000410c:	4639                	li	a2,14
    8000410e:	85d2                	mv	a1,s4
    80004110:	fc240513          	addi	a0,s0,-62
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	ce0080e7          	jalr	-800(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000411c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004120:	4741                	li	a4,16
    80004122:	86a6                	mv	a3,s1
    80004124:	fc040613          	addi	a2,s0,-64
    80004128:	4581                	li	a1,0
    8000412a:	854a                	mv	a0,s2
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	c44080e7          	jalr	-956(ra) # 80003d70 <writei>
    80004134:	872a                	mv	a4,a0
    80004136:	47c1                	li	a5,16
  return 0;
    80004138:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000413a:	02f71863          	bne	a4,a5,8000416a <dirlink+0xb2>
}
    8000413e:	70e2                	ld	ra,56(sp)
    80004140:	7442                	ld	s0,48(sp)
    80004142:	74a2                	ld	s1,40(sp)
    80004144:	7902                	ld	s2,32(sp)
    80004146:	69e2                	ld	s3,24(sp)
    80004148:	6a42                	ld	s4,16(sp)
    8000414a:	6121                	addi	sp,sp,64
    8000414c:	8082                	ret
    iput(ip);
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	a30080e7          	jalr	-1488(ra) # 80003b7e <iput>
    return -1;
    80004156:	557d                	li	a0,-1
    80004158:	b7dd                	j	8000413e <dirlink+0x86>
      panic("dirlink read");
    8000415a:	00004517          	auipc	a0,0x4
    8000415e:	59e50513          	addi	a0,a0,1438 # 800086f8 <syscalls+0x1d8>
    80004162:	ffffc097          	auipc	ra,0xffffc
    80004166:	3dc080e7          	jalr	988(ra) # 8000053e <panic>
    panic("dirlink");
    8000416a:	00004517          	auipc	a0,0x4
    8000416e:	69650513          	addi	a0,a0,1686 # 80008800 <syscalls+0x2e0>
    80004172:	ffffc097          	auipc	ra,0xffffc
    80004176:	3cc080e7          	jalr	972(ra) # 8000053e <panic>

000000008000417a <namei>:

struct inode*
namei(char *path)
{
    8000417a:	1101                	addi	sp,sp,-32
    8000417c:	ec06                	sd	ra,24(sp)
    8000417e:	e822                	sd	s0,16(sp)
    80004180:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004182:	fe040613          	addi	a2,s0,-32
    80004186:	4581                	li	a1,0
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	dd0080e7          	jalr	-560(ra) # 80003f58 <namex>
}
    80004190:	60e2                	ld	ra,24(sp)
    80004192:	6442                	ld	s0,16(sp)
    80004194:	6105                	addi	sp,sp,32
    80004196:	8082                	ret

0000000080004198 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004198:	1141                	addi	sp,sp,-16
    8000419a:	e406                	sd	ra,8(sp)
    8000419c:	e022                	sd	s0,0(sp)
    8000419e:	0800                	addi	s0,sp,16
    800041a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041a2:	4585                	li	a1,1
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	db4080e7          	jalr	-588(ra) # 80003f58 <namex>
}
    800041ac:	60a2                	ld	ra,8(sp)
    800041ae:	6402                	ld	s0,0(sp)
    800041b0:	0141                	addi	sp,sp,16
    800041b2:	8082                	ret

00000000800041b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041b4:	1101                	addi	sp,sp,-32
    800041b6:	ec06                	sd	ra,24(sp)
    800041b8:	e822                	sd	s0,16(sp)
    800041ba:	e426                	sd	s1,8(sp)
    800041bc:	e04a                	sd	s2,0(sp)
    800041be:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041c0:	0001d917          	auipc	s2,0x1d
    800041c4:	4b090913          	addi	s2,s2,1200 # 80021670 <log>
    800041c8:	01892583          	lw	a1,24(s2)
    800041cc:	02892503          	lw	a0,40(s2)
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	ff2080e7          	jalr	-14(ra) # 800031c2 <bread>
    800041d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041da:	02c92683          	lw	a3,44(s2)
    800041de:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041e0:	02d05763          	blez	a3,8000420e <write_head+0x5a>
    800041e4:	0001d797          	auipc	a5,0x1d
    800041e8:	4bc78793          	addi	a5,a5,1212 # 800216a0 <log+0x30>
    800041ec:	05c50713          	addi	a4,a0,92
    800041f0:	36fd                	addiw	a3,a3,-1
    800041f2:	1682                	slli	a3,a3,0x20
    800041f4:	9281                	srli	a3,a3,0x20
    800041f6:	068a                	slli	a3,a3,0x2
    800041f8:	0001d617          	auipc	a2,0x1d
    800041fc:	4ac60613          	addi	a2,a2,1196 # 800216a4 <log+0x34>
    80004200:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004202:	4390                	lw	a2,0(a5)
    80004204:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004206:	0791                	addi	a5,a5,4
    80004208:	0711                	addi	a4,a4,4
    8000420a:	fed79ce3          	bne	a5,a3,80004202 <write_head+0x4e>
  }
  bwrite(buf);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	0a4080e7          	jalr	164(ra) # 800032b4 <bwrite>
  brelse(buf);
    80004218:	8526                	mv	a0,s1
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	0d8080e7          	jalr	216(ra) # 800032f2 <brelse>
}
    80004222:	60e2                	ld	ra,24(sp)
    80004224:	6442                	ld	s0,16(sp)
    80004226:	64a2                	ld	s1,8(sp)
    80004228:	6902                	ld	s2,0(sp)
    8000422a:	6105                	addi	sp,sp,32
    8000422c:	8082                	ret

000000008000422e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422e:	0001d797          	auipc	a5,0x1d
    80004232:	46e7a783          	lw	a5,1134(a5) # 8002169c <log+0x2c>
    80004236:	0af05d63          	blez	a5,800042f0 <install_trans+0xc2>
{
    8000423a:	7139                	addi	sp,sp,-64
    8000423c:	fc06                	sd	ra,56(sp)
    8000423e:	f822                	sd	s0,48(sp)
    80004240:	f426                	sd	s1,40(sp)
    80004242:	f04a                	sd	s2,32(sp)
    80004244:	ec4e                	sd	s3,24(sp)
    80004246:	e852                	sd	s4,16(sp)
    80004248:	e456                	sd	s5,8(sp)
    8000424a:	e05a                	sd	s6,0(sp)
    8000424c:	0080                	addi	s0,sp,64
    8000424e:	8b2a                	mv	s6,a0
    80004250:	0001da97          	auipc	s5,0x1d
    80004254:	450a8a93          	addi	s5,s5,1104 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004258:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000425a:	0001d997          	auipc	s3,0x1d
    8000425e:	41698993          	addi	s3,s3,1046 # 80021670 <log>
    80004262:	a035                	j	8000428e <install_trans+0x60>
      bunpin(dbuf);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	166080e7          	jalr	358(ra) # 800033cc <bunpin>
    brelse(lbuf);
    8000426e:	854a                	mv	a0,s2
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	082080e7          	jalr	130(ra) # 800032f2 <brelse>
    brelse(dbuf);
    80004278:	8526                	mv	a0,s1
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	078080e7          	jalr	120(ra) # 800032f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004282:	2a05                	addiw	s4,s4,1
    80004284:	0a91                	addi	s5,s5,4
    80004286:	02c9a783          	lw	a5,44(s3)
    8000428a:	04fa5963          	bge	s4,a5,800042dc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000428e:	0189a583          	lw	a1,24(s3)
    80004292:	014585bb          	addw	a1,a1,s4
    80004296:	2585                	addiw	a1,a1,1
    80004298:	0289a503          	lw	a0,40(s3)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	f26080e7          	jalr	-218(ra) # 800031c2 <bread>
    800042a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042a6:	000aa583          	lw	a1,0(s5)
    800042aa:	0289a503          	lw	a0,40(s3)
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	f14080e7          	jalr	-236(ra) # 800031c2 <bread>
    800042b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042b8:	40000613          	li	a2,1024
    800042bc:	05890593          	addi	a1,s2,88
    800042c0:	05850513          	addi	a0,a0,88
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	a7c080e7          	jalr	-1412(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	fe6080e7          	jalr	-26(ra) # 800032b4 <bwrite>
    if(recovering == 0)
    800042d6:	f80b1ce3          	bnez	s6,8000426e <install_trans+0x40>
    800042da:	b769                	j	80004264 <install_trans+0x36>
}
    800042dc:	70e2                	ld	ra,56(sp)
    800042de:	7442                	ld	s0,48(sp)
    800042e0:	74a2                	ld	s1,40(sp)
    800042e2:	7902                	ld	s2,32(sp)
    800042e4:	69e2                	ld	s3,24(sp)
    800042e6:	6a42                	ld	s4,16(sp)
    800042e8:	6aa2                	ld	s5,8(sp)
    800042ea:	6b02                	ld	s6,0(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    800042f0:	8082                	ret

00000000800042f2 <initlog>:
{
    800042f2:	7179                	addi	sp,sp,-48
    800042f4:	f406                	sd	ra,40(sp)
    800042f6:	f022                	sd	s0,32(sp)
    800042f8:	ec26                	sd	s1,24(sp)
    800042fa:	e84a                	sd	s2,16(sp)
    800042fc:	e44e                	sd	s3,8(sp)
    800042fe:	1800                	addi	s0,sp,48
    80004300:	892a                	mv	s2,a0
    80004302:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004304:	0001d497          	auipc	s1,0x1d
    80004308:	36c48493          	addi	s1,s1,876 # 80021670 <log>
    8000430c:	00004597          	auipc	a1,0x4
    80004310:	3fc58593          	addi	a1,a1,1020 # 80008708 <syscalls+0x1e8>
    80004314:	8526                	mv	a0,s1
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	83e080e7          	jalr	-1986(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000431e:	0149a583          	lw	a1,20(s3)
    80004322:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004324:	0109a783          	lw	a5,16(s3)
    80004328:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000432a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000432e:	854a                	mv	a0,s2
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	e92080e7          	jalr	-366(ra) # 800031c2 <bread>
  log.lh.n = lh->n;
    80004338:	4d3c                	lw	a5,88(a0)
    8000433a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000433c:	02f05563          	blez	a5,80004366 <initlog+0x74>
    80004340:	05c50713          	addi	a4,a0,92
    80004344:	0001d697          	auipc	a3,0x1d
    80004348:	35c68693          	addi	a3,a3,860 # 800216a0 <log+0x30>
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	1782                	slli	a5,a5,0x20
    80004350:	9381                	srli	a5,a5,0x20
    80004352:	078a                	slli	a5,a5,0x2
    80004354:	06050613          	addi	a2,a0,96
    80004358:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000435a:	4310                	lw	a2,0(a4)
    8000435c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000435e:	0711                	addi	a4,a4,4
    80004360:	0691                	addi	a3,a3,4
    80004362:	fef71ce3          	bne	a4,a5,8000435a <initlog+0x68>
  brelse(buf);
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	f8c080e7          	jalr	-116(ra) # 800032f2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000436e:	4505                	li	a0,1
    80004370:	00000097          	auipc	ra,0x0
    80004374:	ebe080e7          	jalr	-322(ra) # 8000422e <install_trans>
  log.lh.n = 0;
    80004378:	0001d797          	auipc	a5,0x1d
    8000437c:	3207a223          	sw	zero,804(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    80004380:	00000097          	auipc	ra,0x0
    80004384:	e34080e7          	jalr	-460(ra) # 800041b4 <write_head>
}
    80004388:	70a2                	ld	ra,40(sp)
    8000438a:	7402                	ld	s0,32(sp)
    8000438c:	64e2                	ld	s1,24(sp)
    8000438e:	6942                	ld	s2,16(sp)
    80004390:	69a2                	ld	s3,8(sp)
    80004392:	6145                	addi	sp,sp,48
    80004394:	8082                	ret

0000000080004396 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004396:	1101                	addi	sp,sp,-32
    80004398:	ec06                	sd	ra,24(sp)
    8000439a:	e822                	sd	s0,16(sp)
    8000439c:	e426                	sd	s1,8(sp)
    8000439e:	e04a                	sd	s2,0(sp)
    800043a0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043a2:	0001d517          	auipc	a0,0x1d
    800043a6:	2ce50513          	addi	a0,a0,718 # 80021670 <log>
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800043b2:	0001d497          	auipc	s1,0x1d
    800043b6:	2be48493          	addi	s1,s1,702 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ba:	4979                	li	s2,30
    800043bc:	a039                	j	800043ca <begin_op+0x34>
      sleep(&log, &log.lock);
    800043be:	85a6                	mv	a1,s1
    800043c0:	8526                	mv	a0,s1
    800043c2:	ffffe097          	auipc	ra,0xffffe
    800043c6:	d62080e7          	jalr	-670(ra) # 80002124 <sleep>
    if(log.committing){
    800043ca:	50dc                	lw	a5,36(s1)
    800043cc:	fbed                	bnez	a5,800043be <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ce:	509c                	lw	a5,32(s1)
    800043d0:	0017871b          	addiw	a4,a5,1
    800043d4:	0007069b          	sext.w	a3,a4
    800043d8:	0027179b          	slliw	a5,a4,0x2
    800043dc:	9fb9                	addw	a5,a5,a4
    800043de:	0017979b          	slliw	a5,a5,0x1
    800043e2:	54d8                	lw	a4,44(s1)
    800043e4:	9fb9                	addw	a5,a5,a4
    800043e6:	00f95963          	bge	s2,a5,800043f8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043ea:	85a6                	mv	a1,s1
    800043ec:	8526                	mv	a0,s1
    800043ee:	ffffe097          	auipc	ra,0xffffe
    800043f2:	d36080e7          	jalr	-714(ra) # 80002124 <sleep>
    800043f6:	bfd1                	j	800043ca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043f8:	0001d517          	auipc	a0,0x1d
    800043fc:	27850513          	addi	a0,a0,632 # 80021670 <log>
    80004400:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	64a2                	ld	s1,8(sp)
    80004410:	6902                	ld	s2,0(sp)
    80004412:	6105                	addi	sp,sp,32
    80004414:	8082                	ret

0000000080004416 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004416:	7139                	addi	sp,sp,-64
    80004418:	fc06                	sd	ra,56(sp)
    8000441a:	f822                	sd	s0,48(sp)
    8000441c:	f426                	sd	s1,40(sp)
    8000441e:	f04a                	sd	s2,32(sp)
    80004420:	ec4e                	sd	s3,24(sp)
    80004422:	e852                	sd	s4,16(sp)
    80004424:	e456                	sd	s5,8(sp)
    80004426:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004428:	0001d497          	auipc	s1,0x1d
    8000442c:	24848493          	addi	s1,s1,584 # 80021670 <log>
    80004430:	8526                	mv	a0,s1
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000443a:	509c                	lw	a5,32(s1)
    8000443c:	37fd                	addiw	a5,a5,-1
    8000443e:	0007891b          	sext.w	s2,a5
    80004442:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004444:	50dc                	lw	a5,36(s1)
    80004446:	efb9                	bnez	a5,800044a4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004448:	06091663          	bnez	s2,800044b4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000444c:	0001d497          	auipc	s1,0x1d
    80004450:	22448493          	addi	s1,s1,548 # 80021670 <log>
    80004454:	4785                	li	a5,1
    80004456:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004462:	54dc                	lw	a5,44(s1)
    80004464:	06f04763          	bgtz	a5,800044d2 <end_op+0xbc>
    acquire(&log.lock);
    80004468:	0001d497          	auipc	s1,0x1d
    8000446c:	20848493          	addi	s1,s1,520 # 80021670 <log>
    80004470:	8526                	mv	a0,s1
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	772080e7          	jalr	1906(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000447a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffe097          	auipc	ra,0xffffe
    80004484:	f7c080e7          	jalr	-132(ra) # 800023fc <wakeup>
    release(&log.lock);
    80004488:	8526                	mv	a0,s1
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	80e080e7          	jalr	-2034(ra) # 80000c98 <release>
}
    80004492:	70e2                	ld	ra,56(sp)
    80004494:	7442                	ld	s0,48(sp)
    80004496:	74a2                	ld	s1,40(sp)
    80004498:	7902                	ld	s2,32(sp)
    8000449a:	69e2                	ld	s3,24(sp)
    8000449c:	6a42                	ld	s4,16(sp)
    8000449e:	6aa2                	ld	s5,8(sp)
    800044a0:	6121                	addi	sp,sp,64
    800044a2:	8082                	ret
    panic("log.committing");
    800044a4:	00004517          	auipc	a0,0x4
    800044a8:	26c50513          	addi	a0,a0,620 # 80008710 <syscalls+0x1f0>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
    wakeup(&log);
    800044b4:	0001d497          	auipc	s1,0x1d
    800044b8:	1bc48493          	addi	s1,s1,444 # 80021670 <log>
    800044bc:	8526                	mv	a0,s1
    800044be:	ffffe097          	auipc	ra,0xffffe
    800044c2:	f3e080e7          	jalr	-194(ra) # 800023fc <wakeup>
  release(&log.lock);
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
  if(do_commit){
    800044d0:	b7c9                	j	80004492 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d2:	0001da97          	auipc	s5,0x1d
    800044d6:	1cea8a93          	addi	s5,s5,462 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044da:	0001da17          	auipc	s4,0x1d
    800044de:	196a0a13          	addi	s4,s4,406 # 80021670 <log>
    800044e2:	018a2583          	lw	a1,24(s4)
    800044e6:	012585bb          	addw	a1,a1,s2
    800044ea:	2585                	addiw	a1,a1,1
    800044ec:	028a2503          	lw	a0,40(s4)
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	cd2080e7          	jalr	-814(ra) # 800031c2 <bread>
    800044f8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044fa:	000aa583          	lw	a1,0(s5)
    800044fe:	028a2503          	lw	a0,40(s4)
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	cc0080e7          	jalr	-832(ra) # 800031c2 <bread>
    8000450a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000450c:	40000613          	li	a2,1024
    80004510:	05850593          	addi	a1,a0,88
    80004514:	05848513          	addi	a0,s1,88
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	828080e7          	jalr	-2008(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	d92080e7          	jalr	-622(ra) # 800032b4 <bwrite>
    brelse(from);
    8000452a:	854e                	mv	a0,s3
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	dc6080e7          	jalr	-570(ra) # 800032f2 <brelse>
    brelse(to);
    80004534:	8526                	mv	a0,s1
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	dbc080e7          	jalr	-580(ra) # 800032f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000453e:	2905                	addiw	s2,s2,1
    80004540:	0a91                	addi	s5,s5,4
    80004542:	02ca2783          	lw	a5,44(s4)
    80004546:	f8f94ee3          	blt	s2,a5,800044e2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	c6a080e7          	jalr	-918(ra) # 800041b4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004552:	4501                	li	a0,0
    80004554:	00000097          	auipc	ra,0x0
    80004558:	cda080e7          	jalr	-806(ra) # 8000422e <install_trans>
    log.lh.n = 0;
    8000455c:	0001d797          	auipc	a5,0x1d
    80004560:	1407a023          	sw	zero,320(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004564:	00000097          	auipc	ra,0x0
    80004568:	c50080e7          	jalr	-944(ra) # 800041b4 <write_head>
    8000456c:	bdf5                	j	80004468 <end_op+0x52>

000000008000456e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
    8000457a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000457c:	0001d917          	auipc	s2,0x1d
    80004580:	0f490913          	addi	s2,s2,244 # 80021670 <log>
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	65e080e7          	jalr	1630(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000458e:	02c92603          	lw	a2,44(s2)
    80004592:	47f5                	li	a5,29
    80004594:	06c7c563          	blt	a5,a2,800045fe <log_write+0x90>
    80004598:	0001d797          	auipc	a5,0x1d
    8000459c:	0f47a783          	lw	a5,244(a5) # 8002168c <log+0x1c>
    800045a0:	37fd                	addiw	a5,a5,-1
    800045a2:	04f65e63          	bge	a2,a5,800045fe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045a6:	0001d797          	auipc	a5,0x1d
    800045aa:	0ea7a783          	lw	a5,234(a5) # 80021690 <log+0x20>
    800045ae:	06f05063          	blez	a5,8000460e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045b2:	4781                	li	a5,0
    800045b4:	06c05563          	blez	a2,8000461e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045b8:	44cc                	lw	a1,12(s1)
    800045ba:	0001d717          	auipc	a4,0x1d
    800045be:	0e670713          	addi	a4,a4,230 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045c2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045c4:	4314                	lw	a3,0(a4)
    800045c6:	04b68c63          	beq	a3,a1,8000461e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045ca:	2785                	addiw	a5,a5,1
    800045cc:	0711                	addi	a4,a4,4
    800045ce:	fef61be3          	bne	a2,a5,800045c4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045d2:	0621                	addi	a2,a2,8
    800045d4:	060a                	slli	a2,a2,0x2
    800045d6:	0001d797          	auipc	a5,0x1d
    800045da:	09a78793          	addi	a5,a5,154 # 80021670 <log>
    800045de:	963e                	add	a2,a2,a5
    800045e0:	44dc                	lw	a5,12(s1)
    800045e2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045e4:	8526                	mv	a0,s1
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	daa080e7          	jalr	-598(ra) # 80003390 <bpin>
    log.lh.n++;
    800045ee:	0001d717          	auipc	a4,0x1d
    800045f2:	08270713          	addi	a4,a4,130 # 80021670 <log>
    800045f6:	575c                	lw	a5,44(a4)
    800045f8:	2785                	addiw	a5,a5,1
    800045fa:	d75c                	sw	a5,44(a4)
    800045fc:	a835                	j	80004638 <log_write+0xca>
    panic("too big a transaction");
    800045fe:	00004517          	auipc	a0,0x4
    80004602:	12250513          	addi	a0,a0,290 # 80008720 <syscalls+0x200>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000460e:	00004517          	auipc	a0,0x4
    80004612:	12a50513          	addi	a0,a0,298 # 80008738 <syscalls+0x218>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	f28080e7          	jalr	-216(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000461e:	00878713          	addi	a4,a5,8
    80004622:	00271693          	slli	a3,a4,0x2
    80004626:	0001d717          	auipc	a4,0x1d
    8000462a:	04a70713          	addi	a4,a4,74 # 80021670 <log>
    8000462e:	9736                	add	a4,a4,a3
    80004630:	44d4                	lw	a3,12(s1)
    80004632:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004634:	faf608e3          	beq	a2,a5,800045e4 <log_write+0x76>
  }
  release(&log.lock);
    80004638:	0001d517          	auipc	a0,0x1d
    8000463c:	03850513          	addi	a0,a0,56 # 80021670 <log>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004654:	1101                	addi	sp,sp,-32
    80004656:	ec06                	sd	ra,24(sp)
    80004658:	e822                	sd	s0,16(sp)
    8000465a:	e426                	sd	s1,8(sp)
    8000465c:	e04a                	sd	s2,0(sp)
    8000465e:	1000                	addi	s0,sp,32
    80004660:	84aa                	mv	s1,a0
    80004662:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004664:	00004597          	auipc	a1,0x4
    80004668:	0f458593          	addi	a1,a1,244 # 80008758 <syscalls+0x238>
    8000466c:	0521                	addi	a0,a0,8
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	4e6080e7          	jalr	1254(ra) # 80000b54 <initlock>
  lk->name = name;
    80004676:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000467a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000467e:	0204a423          	sw	zero,40(s1)
}
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6902                	ld	s2,0(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	e04a                	sd	s2,0(sp)
    80004698:	1000                	addi	s0,sp,32
    8000469a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000469c:	00850913          	addi	s2,a0,8
    800046a0:	854a                	mv	a0,s2
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	542080e7          	jalr	1346(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800046aa:	409c                	lw	a5,0(s1)
    800046ac:	cb89                	beqz	a5,800046be <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046ae:	85ca                	mv	a1,s2
    800046b0:	8526                	mv	a0,s1
    800046b2:	ffffe097          	auipc	ra,0xffffe
    800046b6:	a72080e7          	jalr	-1422(ra) # 80002124 <sleep>
  while (lk->locked) {
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	fbed                	bnez	a5,800046ae <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046be:	4785                	li	a5,1
    800046c0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046c2:	ffffd097          	auipc	ra,0xffffd
    800046c6:	2ee080e7          	jalr	750(ra) # 800019b0 <myproc>
    800046ca:	591c                	lw	a5,48(a0)
    800046cc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046ce:	854a                	mv	a0,s2
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5c8080e7          	jalr	1480(ra) # 80000c98 <release>
}
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6902                	ld	s2,0(sp)
    800046e0:	6105                	addi	sp,sp,32
    800046e2:	8082                	ret

00000000800046e4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046e4:	1101                	addi	sp,sp,-32
    800046e6:	ec06                	sd	ra,24(sp)
    800046e8:	e822                	sd	s0,16(sp)
    800046ea:	e426                	sd	s1,8(sp)
    800046ec:	e04a                	sd	s2,0(sp)
    800046ee:	1000                	addi	s0,sp,32
    800046f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046f2:	00850913          	addi	s2,a0,8
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4ec080e7          	jalr	1260(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004700:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004704:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004708:	8526                	mv	a0,s1
    8000470a:	ffffe097          	auipc	ra,0xffffe
    8000470e:	cf2080e7          	jalr	-782(ra) # 800023fc <wakeup>
  release(&lk->lk);
    80004712:	854a                	mv	a0,s2
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	584080e7          	jalr	1412(ra) # 80000c98 <release>
}
    8000471c:	60e2                	ld	ra,24(sp)
    8000471e:	6442                	ld	s0,16(sp)
    80004720:	64a2                	ld	s1,8(sp)
    80004722:	6902                	ld	s2,0(sp)
    80004724:	6105                	addi	sp,sp,32
    80004726:	8082                	ret

0000000080004728 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004728:	7179                	addi	sp,sp,-48
    8000472a:	f406                	sd	ra,40(sp)
    8000472c:	f022                	sd	s0,32(sp)
    8000472e:	ec26                	sd	s1,24(sp)
    80004730:	e84a                	sd	s2,16(sp)
    80004732:	e44e                	sd	s3,8(sp)
    80004734:	1800                	addi	s0,sp,48
    80004736:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004738:	00850913          	addi	s2,a0,8
    8000473c:	854a                	mv	a0,s2
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004746:	409c                	lw	a5,0(s1)
    80004748:	ef99                	bnez	a5,80004766 <holdingsleep+0x3e>
    8000474a:	4481                	li	s1,0
  release(&lk->lk);
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	54a080e7          	jalr	1354(ra) # 80000c98 <release>
  return r;
}
    80004756:	8526                	mv	a0,s1
    80004758:	70a2                	ld	ra,40(sp)
    8000475a:	7402                	ld	s0,32(sp)
    8000475c:	64e2                	ld	s1,24(sp)
    8000475e:	6942                	ld	s2,16(sp)
    80004760:	69a2                	ld	s3,8(sp)
    80004762:	6145                	addi	sp,sp,48
    80004764:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004766:	0284a983          	lw	s3,40(s1)
    8000476a:	ffffd097          	auipc	ra,0xffffd
    8000476e:	246080e7          	jalr	582(ra) # 800019b0 <myproc>
    80004772:	5904                	lw	s1,48(a0)
    80004774:	413484b3          	sub	s1,s1,s3
    80004778:	0014b493          	seqz	s1,s1
    8000477c:	bfc1                	j	8000474c <holdingsleep+0x24>

000000008000477e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000477e:	1141                	addi	sp,sp,-16
    80004780:	e406                	sd	ra,8(sp)
    80004782:	e022                	sd	s0,0(sp)
    80004784:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004786:	00004597          	auipc	a1,0x4
    8000478a:	fe258593          	addi	a1,a1,-30 # 80008768 <syscalls+0x248>
    8000478e:	0001d517          	auipc	a0,0x1d
    80004792:	02a50513          	addi	a0,a0,42 # 800217b8 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	3be080e7          	jalr	958(ra) # 80000b54 <initlock>
}
    8000479e:	60a2                	ld	ra,8(sp)
    800047a0:	6402                	ld	s0,0(sp)
    800047a2:	0141                	addi	sp,sp,16
    800047a4:	8082                	ret

00000000800047a6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047a6:	1101                	addi	sp,sp,-32
    800047a8:	ec06                	sd	ra,24(sp)
    800047aa:	e822                	sd	s0,16(sp)
    800047ac:	e426                	sd	s1,8(sp)
    800047ae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047b0:	0001d517          	auipc	a0,0x1d
    800047b4:	00850513          	addi	a0,a0,8 # 800217b8 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	42c080e7          	jalr	1068(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047c0:	0001d497          	auipc	s1,0x1d
    800047c4:	01048493          	addi	s1,s1,16 # 800217d0 <ftable+0x18>
    800047c8:	0001e717          	auipc	a4,0x1e
    800047cc:	fa870713          	addi	a4,a4,-88 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800047d0:	40dc                	lw	a5,4(s1)
    800047d2:	cf99                	beqz	a5,800047f0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d4:	02848493          	addi	s1,s1,40
    800047d8:	fee49ce3          	bne	s1,a4,800047d0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	fdc50513          	addi	a0,a0,-36 # 800217b8 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4b4080e7          	jalr	1204(ra) # 80000c98 <release>
  return 0;
    800047ec:	4481                	li	s1,0
    800047ee:	a819                	j	80004804 <filealloc+0x5e>
      f->ref = 1;
    800047f0:	4785                	li	a5,1
    800047f2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047f4:	0001d517          	auipc	a0,0x1d
    800047f8:	fc450513          	addi	a0,a0,-60 # 800217b8 <ftable>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	49c080e7          	jalr	1180(ra) # 80000c98 <release>
}
    80004804:	8526                	mv	a0,s1
    80004806:	60e2                	ld	ra,24(sp)
    80004808:	6442                	ld	s0,16(sp)
    8000480a:	64a2                	ld	s1,8(sp)
    8000480c:	6105                	addi	sp,sp,32
    8000480e:	8082                	ret

0000000080004810 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004810:	1101                	addi	sp,sp,-32
    80004812:	ec06                	sd	ra,24(sp)
    80004814:	e822                	sd	s0,16(sp)
    80004816:	e426                	sd	s1,8(sp)
    80004818:	1000                	addi	s0,sp,32
    8000481a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	f9c50513          	addi	a0,a0,-100 # 800217b8 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3c0080e7          	jalr	960(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000482c:	40dc                	lw	a5,4(s1)
    8000482e:	02f05263          	blez	a5,80004852 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004832:	2785                	addiw	a5,a5,1
    80004834:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	f8250513          	addi	a0,a0,-126 # 800217b8 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	45a080e7          	jalr	1114(ra) # 80000c98 <release>
  return f;
}
    80004846:	8526                	mv	a0,s1
    80004848:	60e2                	ld	ra,24(sp)
    8000484a:	6442                	ld	s0,16(sp)
    8000484c:	64a2                	ld	s1,8(sp)
    8000484e:	6105                	addi	sp,sp,32
    80004850:	8082                	ret
    panic("filedup");
    80004852:	00004517          	auipc	a0,0x4
    80004856:	f1e50513          	addi	a0,a0,-226 # 80008770 <syscalls+0x250>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>

0000000080004862 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004862:	7139                	addi	sp,sp,-64
    80004864:	fc06                	sd	ra,56(sp)
    80004866:	f822                	sd	s0,48(sp)
    80004868:	f426                	sd	s1,40(sp)
    8000486a:	f04a                	sd	s2,32(sp)
    8000486c:	ec4e                	sd	s3,24(sp)
    8000486e:	e852                	sd	s4,16(sp)
    80004870:	e456                	sd	s5,8(sp)
    80004872:	0080                	addi	s0,sp,64
    80004874:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004876:	0001d517          	auipc	a0,0x1d
    8000487a:	f4250513          	addi	a0,a0,-190 # 800217b8 <ftable>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	366080e7          	jalr	870(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004886:	40dc                	lw	a5,4(s1)
    80004888:	06f05163          	blez	a5,800048ea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000488c:	37fd                	addiw	a5,a5,-1
    8000488e:	0007871b          	sext.w	a4,a5
    80004892:	c0dc                	sw	a5,4(s1)
    80004894:	06e04363          	bgtz	a4,800048fa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004898:	0004a903          	lw	s2,0(s1)
    8000489c:	0094ca83          	lbu	s5,9(s1)
    800048a0:	0104ba03          	ld	s4,16(s1)
    800048a4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048a8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048ac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048b0:	0001d517          	auipc	a0,0x1d
    800048b4:	f0850513          	addi	a0,a0,-248 # 800217b8 <ftable>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	3e0080e7          	jalr	992(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800048c0:	4785                	li	a5,1
    800048c2:	04f90d63          	beq	s2,a5,8000491c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048c6:	3979                	addiw	s2,s2,-2
    800048c8:	4785                	li	a5,1
    800048ca:	0527e063          	bltu	a5,s2,8000490a <fileclose+0xa8>
    begin_op();
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	ac8080e7          	jalr	-1336(ra) # 80004396 <begin_op>
    iput(ff.ip);
    800048d6:	854e                	mv	a0,s3
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	2a6080e7          	jalr	678(ra) # 80003b7e <iput>
    end_op();
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	b36080e7          	jalr	-1226(ra) # 80004416 <end_op>
    800048e8:	a00d                	j	8000490a <fileclose+0xa8>
    panic("fileclose");
    800048ea:	00004517          	auipc	a0,0x4
    800048ee:	e8e50513          	addi	a0,a0,-370 # 80008778 <syscalls+0x258>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	c4c080e7          	jalr	-948(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048fa:	0001d517          	auipc	a0,0x1d
    800048fe:	ebe50513          	addi	a0,a0,-322 # 800217b8 <ftable>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	396080e7          	jalr	918(ra) # 80000c98 <release>
  }
}
    8000490a:	70e2                	ld	ra,56(sp)
    8000490c:	7442                	ld	s0,48(sp)
    8000490e:	74a2                	ld	s1,40(sp)
    80004910:	7902                	ld	s2,32(sp)
    80004912:	69e2                	ld	s3,24(sp)
    80004914:	6a42                	ld	s4,16(sp)
    80004916:	6aa2                	ld	s5,8(sp)
    80004918:	6121                	addi	sp,sp,64
    8000491a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000491c:	85d6                	mv	a1,s5
    8000491e:	8552                	mv	a0,s4
    80004920:	00000097          	auipc	ra,0x0
    80004924:	34c080e7          	jalr	844(ra) # 80004c6c <pipeclose>
    80004928:	b7cd                	j	8000490a <fileclose+0xa8>

000000008000492a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000492a:	715d                	addi	sp,sp,-80
    8000492c:	e486                	sd	ra,72(sp)
    8000492e:	e0a2                	sd	s0,64(sp)
    80004930:	fc26                	sd	s1,56(sp)
    80004932:	f84a                	sd	s2,48(sp)
    80004934:	f44e                	sd	s3,40(sp)
    80004936:	0880                	addi	s0,sp,80
    80004938:	84aa                	mv	s1,a0
    8000493a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000493c:	ffffd097          	auipc	ra,0xffffd
    80004940:	074080e7          	jalr	116(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004944:	409c                	lw	a5,0(s1)
    80004946:	37f9                	addiw	a5,a5,-2
    80004948:	4705                	li	a4,1
    8000494a:	04f76763          	bltu	a4,a5,80004998 <filestat+0x6e>
    8000494e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004950:	6c88                	ld	a0,24(s1)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	072080e7          	jalr	114(ra) # 800039c4 <ilock>
    stati(f->ip, &st);
    8000495a:	fb840593          	addi	a1,s0,-72
    8000495e:	6c88                	ld	a0,24(s1)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	2ee080e7          	jalr	750(ra) # 80003c4e <stati>
    iunlock(f->ip);
    80004968:	6c88                	ld	a0,24(s1)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	11c080e7          	jalr	284(ra) # 80003a86 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004972:	46e1                	li	a3,24
    80004974:	fb840613          	addi	a2,s0,-72
    80004978:	85ce                	mv	a1,s3
    8000497a:	05093503          	ld	a0,80(s2)
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	cf4080e7          	jalr	-780(ra) # 80001672 <copyout>
    80004986:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000498a:	60a6                	ld	ra,72(sp)
    8000498c:	6406                	ld	s0,64(sp)
    8000498e:	74e2                	ld	s1,56(sp)
    80004990:	7942                	ld	s2,48(sp)
    80004992:	79a2                	ld	s3,40(sp)
    80004994:	6161                	addi	sp,sp,80
    80004996:	8082                	ret
  return -1;
    80004998:	557d                	li	a0,-1
    8000499a:	bfc5                	j	8000498a <filestat+0x60>

000000008000499c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000499c:	7179                	addi	sp,sp,-48
    8000499e:	f406                	sd	ra,40(sp)
    800049a0:	f022                	sd	s0,32(sp)
    800049a2:	ec26                	sd	s1,24(sp)
    800049a4:	e84a                	sd	s2,16(sp)
    800049a6:	e44e                	sd	s3,8(sp)
    800049a8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049aa:	00854783          	lbu	a5,8(a0)
    800049ae:	c3d5                	beqz	a5,80004a52 <fileread+0xb6>
    800049b0:	84aa                	mv	s1,a0
    800049b2:	89ae                	mv	s3,a1
    800049b4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b6:	411c                	lw	a5,0(a0)
    800049b8:	4705                	li	a4,1
    800049ba:	04e78963          	beq	a5,a4,80004a0c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049be:	470d                	li	a4,3
    800049c0:	04e78d63          	beq	a5,a4,80004a1a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c4:	4709                	li	a4,2
    800049c6:	06e79e63          	bne	a5,a4,80004a42 <fileread+0xa6>
    ilock(f->ip);
    800049ca:	6d08                	ld	a0,24(a0)
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	ff8080e7          	jalr	-8(ra) # 800039c4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049d4:	874a                	mv	a4,s2
    800049d6:	5094                	lw	a3,32(s1)
    800049d8:	864e                	mv	a2,s3
    800049da:	4585                	li	a1,1
    800049dc:	6c88                	ld	a0,24(s1)
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	29a080e7          	jalr	666(ra) # 80003c78 <readi>
    800049e6:	892a                	mv	s2,a0
    800049e8:	00a05563          	blez	a0,800049f2 <fileread+0x56>
      f->off += r;
    800049ec:	509c                	lw	a5,32(s1)
    800049ee:	9fa9                	addw	a5,a5,a0
    800049f0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049f2:	6c88                	ld	a0,24(s1)
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	092080e7          	jalr	146(ra) # 80003a86 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049fc:	854a                	mv	a0,s2
    800049fe:	70a2                	ld	ra,40(sp)
    80004a00:	7402                	ld	s0,32(sp)
    80004a02:	64e2                	ld	s1,24(sp)
    80004a04:	6942                	ld	s2,16(sp)
    80004a06:	69a2                	ld	s3,8(sp)
    80004a08:	6145                	addi	sp,sp,48
    80004a0a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a0c:	6908                	ld	a0,16(a0)
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	3c8080e7          	jalr	968(ra) # 80004dd6 <piperead>
    80004a16:	892a                	mv	s2,a0
    80004a18:	b7d5                	j	800049fc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a1a:	02451783          	lh	a5,36(a0)
    80004a1e:	03079693          	slli	a3,a5,0x30
    80004a22:	92c1                	srli	a3,a3,0x30
    80004a24:	4725                	li	a4,9
    80004a26:	02d76863          	bltu	a4,a3,80004a56 <fileread+0xba>
    80004a2a:	0792                	slli	a5,a5,0x4
    80004a2c:	0001d717          	auipc	a4,0x1d
    80004a30:	cec70713          	addi	a4,a4,-788 # 80021718 <devsw>
    80004a34:	97ba                	add	a5,a5,a4
    80004a36:	639c                	ld	a5,0(a5)
    80004a38:	c38d                	beqz	a5,80004a5a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a3a:	4505                	li	a0,1
    80004a3c:	9782                	jalr	a5
    80004a3e:	892a                	mv	s2,a0
    80004a40:	bf75                	j	800049fc <fileread+0x60>
    panic("fileread");
    80004a42:	00004517          	auipc	a0,0x4
    80004a46:	d4650513          	addi	a0,a0,-698 # 80008788 <syscalls+0x268>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	af4080e7          	jalr	-1292(ra) # 8000053e <panic>
    return -1;
    80004a52:	597d                	li	s2,-1
    80004a54:	b765                	j	800049fc <fileread+0x60>
      return -1;
    80004a56:	597d                	li	s2,-1
    80004a58:	b755                	j	800049fc <fileread+0x60>
    80004a5a:	597d                	li	s2,-1
    80004a5c:	b745                	j	800049fc <fileread+0x60>

0000000080004a5e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a5e:	715d                	addi	sp,sp,-80
    80004a60:	e486                	sd	ra,72(sp)
    80004a62:	e0a2                	sd	s0,64(sp)
    80004a64:	fc26                	sd	s1,56(sp)
    80004a66:	f84a                	sd	s2,48(sp)
    80004a68:	f44e                	sd	s3,40(sp)
    80004a6a:	f052                	sd	s4,32(sp)
    80004a6c:	ec56                	sd	s5,24(sp)
    80004a6e:	e85a                	sd	s6,16(sp)
    80004a70:	e45e                	sd	s7,8(sp)
    80004a72:	e062                	sd	s8,0(sp)
    80004a74:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a76:	00954783          	lbu	a5,9(a0)
    80004a7a:	10078663          	beqz	a5,80004b86 <filewrite+0x128>
    80004a7e:	892a                	mv	s2,a0
    80004a80:	8aae                	mv	s5,a1
    80004a82:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a84:	411c                	lw	a5,0(a0)
    80004a86:	4705                	li	a4,1
    80004a88:	02e78263          	beq	a5,a4,80004aac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a8c:	470d                	li	a4,3
    80004a8e:	02e78663          	beq	a5,a4,80004aba <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a92:	4709                	li	a4,2
    80004a94:	0ee79163          	bne	a5,a4,80004b76 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a98:	0ac05d63          	blez	a2,80004b52 <filewrite+0xf4>
    int i = 0;
    80004a9c:	4981                	li	s3,0
    80004a9e:	6b05                	lui	s6,0x1
    80004aa0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aa4:	6b85                	lui	s7,0x1
    80004aa6:	c00b8b9b          	addiw	s7,s7,-1024
    80004aaa:	a861                	j	80004b42 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004aac:	6908                	ld	a0,16(a0)
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	22e080e7          	jalr	558(ra) # 80004cdc <pipewrite>
    80004ab6:	8a2a                	mv	s4,a0
    80004ab8:	a045                	j	80004b58 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aba:	02451783          	lh	a5,36(a0)
    80004abe:	03079693          	slli	a3,a5,0x30
    80004ac2:	92c1                	srli	a3,a3,0x30
    80004ac4:	4725                	li	a4,9
    80004ac6:	0cd76263          	bltu	a4,a3,80004b8a <filewrite+0x12c>
    80004aca:	0792                	slli	a5,a5,0x4
    80004acc:	0001d717          	auipc	a4,0x1d
    80004ad0:	c4c70713          	addi	a4,a4,-948 # 80021718 <devsw>
    80004ad4:	97ba                	add	a5,a5,a4
    80004ad6:	679c                	ld	a5,8(a5)
    80004ad8:	cbdd                	beqz	a5,80004b8e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ada:	4505                	li	a0,1
    80004adc:	9782                	jalr	a5
    80004ade:	8a2a                	mv	s4,a0
    80004ae0:	a8a5                	j	80004b58 <filewrite+0xfa>
    80004ae2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	8b0080e7          	jalr	-1872(ra) # 80004396 <begin_op>
      ilock(f->ip);
    80004aee:	01893503          	ld	a0,24(s2)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	ed2080e7          	jalr	-302(ra) # 800039c4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004afa:	8762                	mv	a4,s8
    80004afc:	02092683          	lw	a3,32(s2)
    80004b00:	01598633          	add	a2,s3,s5
    80004b04:	4585                	li	a1,1
    80004b06:	01893503          	ld	a0,24(s2)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	266080e7          	jalr	614(ra) # 80003d70 <writei>
    80004b12:	84aa                	mv	s1,a0
    80004b14:	00a05763          	blez	a0,80004b22 <filewrite+0xc4>
        f->off += r;
    80004b18:	02092783          	lw	a5,32(s2)
    80004b1c:	9fa9                	addw	a5,a5,a0
    80004b1e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b22:	01893503          	ld	a0,24(s2)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	f60080e7          	jalr	-160(ra) # 80003a86 <iunlock>
      end_op();
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	8e8080e7          	jalr	-1816(ra) # 80004416 <end_op>

      if(r != n1){
    80004b36:	009c1f63          	bne	s8,s1,80004b54 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b3a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b3e:	0149db63          	bge	s3,s4,80004b54 <filewrite+0xf6>
      int n1 = n - i;
    80004b42:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b46:	84be                	mv	s1,a5
    80004b48:	2781                	sext.w	a5,a5
    80004b4a:	f8fb5ce3          	bge	s6,a5,80004ae2 <filewrite+0x84>
    80004b4e:	84de                	mv	s1,s7
    80004b50:	bf49                	j	80004ae2 <filewrite+0x84>
    int i = 0;
    80004b52:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b54:	013a1f63          	bne	s4,s3,80004b72 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b58:	8552                	mv	a0,s4
    80004b5a:	60a6                	ld	ra,72(sp)
    80004b5c:	6406                	ld	s0,64(sp)
    80004b5e:	74e2                	ld	s1,56(sp)
    80004b60:	7942                	ld	s2,48(sp)
    80004b62:	79a2                	ld	s3,40(sp)
    80004b64:	7a02                	ld	s4,32(sp)
    80004b66:	6ae2                	ld	s5,24(sp)
    80004b68:	6b42                	ld	s6,16(sp)
    80004b6a:	6ba2                	ld	s7,8(sp)
    80004b6c:	6c02                	ld	s8,0(sp)
    80004b6e:	6161                	addi	sp,sp,80
    80004b70:	8082                	ret
    ret = (i == n ? n : -1);
    80004b72:	5a7d                	li	s4,-1
    80004b74:	b7d5                	j	80004b58 <filewrite+0xfa>
    panic("filewrite");
    80004b76:	00004517          	auipc	a0,0x4
    80004b7a:	c2250513          	addi	a0,a0,-990 # 80008798 <syscalls+0x278>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	9c0080e7          	jalr	-1600(ra) # 8000053e <panic>
    return -1;
    80004b86:	5a7d                	li	s4,-1
    80004b88:	bfc1                	j	80004b58 <filewrite+0xfa>
      return -1;
    80004b8a:	5a7d                	li	s4,-1
    80004b8c:	b7f1                	j	80004b58 <filewrite+0xfa>
    80004b8e:	5a7d                	li	s4,-1
    80004b90:	b7e1                	j	80004b58 <filewrite+0xfa>

0000000080004b92 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b92:	7179                	addi	sp,sp,-48
    80004b94:	f406                	sd	ra,40(sp)
    80004b96:	f022                	sd	s0,32(sp)
    80004b98:	ec26                	sd	s1,24(sp)
    80004b9a:	e84a                	sd	s2,16(sp)
    80004b9c:	e44e                	sd	s3,8(sp)
    80004b9e:	e052                	sd	s4,0(sp)
    80004ba0:	1800                	addi	s0,sp,48
    80004ba2:	84aa                	mv	s1,a0
    80004ba4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ba6:	0005b023          	sd	zero,0(a1)
    80004baa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bae:	00000097          	auipc	ra,0x0
    80004bb2:	bf8080e7          	jalr	-1032(ra) # 800047a6 <filealloc>
    80004bb6:	e088                	sd	a0,0(s1)
    80004bb8:	c551                	beqz	a0,80004c44 <pipealloc+0xb2>
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	bec080e7          	jalr	-1044(ra) # 800047a6 <filealloc>
    80004bc2:	00aa3023          	sd	a0,0(s4)
    80004bc6:	c92d                	beqz	a0,80004c38 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	f2c080e7          	jalr	-212(ra) # 80000af4 <kalloc>
    80004bd0:	892a                	mv	s2,a0
    80004bd2:	c125                	beqz	a0,80004c32 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bd4:	4985                	li	s3,1
    80004bd6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bda:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bde:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004be2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004be6:	00004597          	auipc	a1,0x4
    80004bea:	89258593          	addi	a1,a1,-1902 # 80008478 <states.1743+0x1b8>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	f66080e7          	jalr	-154(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004bf6:	609c                	ld	a5,0(s1)
    80004bf8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bfc:	609c                	ld	a5,0(s1)
    80004bfe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c02:	609c                	ld	a5,0(s1)
    80004c04:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c08:	609c                	ld	a5,0(s1)
    80004c0a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c0e:	000a3783          	ld	a5,0(s4)
    80004c12:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c16:	000a3783          	ld	a5,0(s4)
    80004c1a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c1e:	000a3783          	ld	a5,0(s4)
    80004c22:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c26:	000a3783          	ld	a5,0(s4)
    80004c2a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c2e:	4501                	li	a0,0
    80004c30:	a025                	j	80004c58 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c32:	6088                	ld	a0,0(s1)
    80004c34:	e501                	bnez	a0,80004c3c <pipealloc+0xaa>
    80004c36:	a039                	j	80004c44 <pipealloc+0xb2>
    80004c38:	6088                	ld	a0,0(s1)
    80004c3a:	c51d                	beqz	a0,80004c68 <pipealloc+0xd6>
    fileclose(*f0);
    80004c3c:	00000097          	auipc	ra,0x0
    80004c40:	c26080e7          	jalr	-986(ra) # 80004862 <fileclose>
  if(*f1)
    80004c44:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c48:	557d                	li	a0,-1
  if(*f1)
    80004c4a:	c799                	beqz	a5,80004c58 <pipealloc+0xc6>
    fileclose(*f1);
    80004c4c:	853e                	mv	a0,a5
    80004c4e:	00000097          	auipc	ra,0x0
    80004c52:	c14080e7          	jalr	-1004(ra) # 80004862 <fileclose>
  return -1;
    80004c56:	557d                	li	a0,-1
}
    80004c58:	70a2                	ld	ra,40(sp)
    80004c5a:	7402                	ld	s0,32(sp)
    80004c5c:	64e2                	ld	s1,24(sp)
    80004c5e:	6942                	ld	s2,16(sp)
    80004c60:	69a2                	ld	s3,8(sp)
    80004c62:	6a02                	ld	s4,0(sp)
    80004c64:	6145                	addi	sp,sp,48
    80004c66:	8082                	ret
  return -1;
    80004c68:	557d                	li	a0,-1
    80004c6a:	b7fd                	j	80004c58 <pipealloc+0xc6>

0000000080004c6c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c6c:	1101                	addi	sp,sp,-32
    80004c6e:	ec06                	sd	ra,24(sp)
    80004c70:	e822                	sd	s0,16(sp)
    80004c72:	e426                	sd	s1,8(sp)
    80004c74:	e04a                	sd	s2,0(sp)
    80004c76:	1000                	addi	s0,sp,32
    80004c78:	84aa                	mv	s1,a0
    80004c7a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	f68080e7          	jalr	-152(ra) # 80000be4 <acquire>
  if(writable){
    80004c84:	02090d63          	beqz	s2,80004cbe <pipeclose+0x52>
    pi->writeopen = 0;
    80004c88:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c8c:	21848513          	addi	a0,s1,536
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	76c080e7          	jalr	1900(ra) # 800023fc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c98:	2204b783          	ld	a5,544(s1)
    80004c9c:	eb95                	bnez	a5,80004cd0 <pipeclose+0x64>
    release(&pi->lock);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	ff8080e7          	jalr	-8(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	d4e080e7          	jalr	-690(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004cb2:	60e2                	ld	ra,24(sp)
    80004cb4:	6442                	ld	s0,16(sp)
    80004cb6:	64a2                	ld	s1,8(sp)
    80004cb8:	6902                	ld	s2,0(sp)
    80004cba:	6105                	addi	sp,sp,32
    80004cbc:	8082                	ret
    pi->readopen = 0;
    80004cbe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cc2:	21c48513          	addi	a0,s1,540
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	736080e7          	jalr	1846(ra) # 800023fc <wakeup>
    80004cce:	b7e9                	j	80004c98 <pipeclose+0x2c>
    release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fc6080e7          	jalr	-58(ra) # 80000c98 <release>
}
    80004cda:	bfe1                	j	80004cb2 <pipeclose+0x46>

0000000080004cdc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cdc:	7159                	addi	sp,sp,-112
    80004cde:	f486                	sd	ra,104(sp)
    80004ce0:	f0a2                	sd	s0,96(sp)
    80004ce2:	eca6                	sd	s1,88(sp)
    80004ce4:	e8ca                	sd	s2,80(sp)
    80004ce6:	e4ce                	sd	s3,72(sp)
    80004ce8:	e0d2                	sd	s4,64(sp)
    80004cea:	fc56                	sd	s5,56(sp)
    80004cec:	f85a                	sd	s6,48(sp)
    80004cee:	f45e                	sd	s7,40(sp)
    80004cf0:	f062                	sd	s8,32(sp)
    80004cf2:	ec66                	sd	s9,24(sp)
    80004cf4:	1880                	addi	s0,sp,112
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	8aae                	mv	s5,a1
    80004cfa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	cb4080e7          	jalr	-844(ra) # 800019b0 <myproc>
    80004d04:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	edc080e7          	jalr	-292(ra) # 80000be4 <acquire>
  while(i < n){
    80004d10:	0d405163          	blez	s4,80004dd2 <pipewrite+0xf6>
    80004d14:	8ba6                	mv	s7,s1
  int i = 0;
    80004d16:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d18:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d1a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d1e:	21c48c13          	addi	s8,s1,540
    80004d22:	a08d                	j	80004d84 <pipewrite+0xa8>
      release(&pi->lock);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f72080e7          	jalr	-142(ra) # 80000c98 <release>
      return -1;
    80004d2e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d30:	854a                	mv	a0,s2
    80004d32:	70a6                	ld	ra,104(sp)
    80004d34:	7406                	ld	s0,96(sp)
    80004d36:	64e6                	ld	s1,88(sp)
    80004d38:	6946                	ld	s2,80(sp)
    80004d3a:	69a6                	ld	s3,72(sp)
    80004d3c:	6a06                	ld	s4,64(sp)
    80004d3e:	7ae2                	ld	s5,56(sp)
    80004d40:	7b42                	ld	s6,48(sp)
    80004d42:	7ba2                	ld	s7,40(sp)
    80004d44:	7c02                	ld	s8,32(sp)
    80004d46:	6ce2                	ld	s9,24(sp)
    80004d48:	6165                	addi	sp,sp,112
    80004d4a:	8082                	ret
      wakeup(&pi->nread);
    80004d4c:	8566                	mv	a0,s9
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	6ae080e7          	jalr	1710(ra) # 800023fc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d56:	85de                	mv	a1,s7
    80004d58:	8562                	mv	a0,s8
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	3ca080e7          	jalr	970(ra) # 80002124 <sleep>
    80004d62:	a839                	j	80004d80 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d64:	21c4a783          	lw	a5,540(s1)
    80004d68:	0017871b          	addiw	a4,a5,1
    80004d6c:	20e4ae23          	sw	a4,540(s1)
    80004d70:	1ff7f793          	andi	a5,a5,511
    80004d74:	97a6                	add	a5,a5,s1
    80004d76:	f9f44703          	lbu	a4,-97(s0)
    80004d7a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d7e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d80:	03495d63          	bge	s2,s4,80004dba <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d84:	2204a783          	lw	a5,544(s1)
    80004d88:	dfd1                	beqz	a5,80004d24 <pipewrite+0x48>
    80004d8a:	0289a783          	lw	a5,40(s3)
    80004d8e:	fbd9                	bnez	a5,80004d24 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d90:	2184a783          	lw	a5,536(s1)
    80004d94:	21c4a703          	lw	a4,540(s1)
    80004d98:	2007879b          	addiw	a5,a5,512
    80004d9c:	faf708e3          	beq	a4,a5,80004d4c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da0:	4685                	li	a3,1
    80004da2:	01590633          	add	a2,s2,s5
    80004da6:	f9f40593          	addi	a1,s0,-97
    80004daa:	0509b503          	ld	a0,80(s3)
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	950080e7          	jalr	-1712(ra) # 800016fe <copyin>
    80004db6:	fb6517e3          	bne	a0,s6,80004d64 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004dba:	21848513          	addi	a0,s1,536
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	63e080e7          	jalr	1598(ra) # 800023fc <wakeup>
  release(&pi->lock);
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	ed0080e7          	jalr	-304(ra) # 80000c98 <release>
  return i;
    80004dd0:	b785                	j	80004d30 <pipewrite+0x54>
  int i = 0;
    80004dd2:	4901                	li	s2,0
    80004dd4:	b7dd                	j	80004dba <pipewrite+0xde>

0000000080004dd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dd6:	715d                	addi	sp,sp,-80
    80004dd8:	e486                	sd	ra,72(sp)
    80004dda:	e0a2                	sd	s0,64(sp)
    80004ddc:	fc26                	sd	s1,56(sp)
    80004dde:	f84a                	sd	s2,48(sp)
    80004de0:	f44e                	sd	s3,40(sp)
    80004de2:	f052                	sd	s4,32(sp)
    80004de4:	ec56                	sd	s5,24(sp)
    80004de6:	e85a                	sd	s6,16(sp)
    80004de8:	0880                	addi	s0,sp,80
    80004dea:	84aa                	mv	s1,a0
    80004dec:	892e                	mv	s2,a1
    80004dee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	bc0080e7          	jalr	-1088(ra) # 800019b0 <myproc>
    80004df8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dfa:	8b26                	mv	s6,s1
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	de6080e7          	jalr	-538(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e06:	2184a703          	lw	a4,536(s1)
    80004e0a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e0e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e12:	02f71463          	bne	a4,a5,80004e3a <piperead+0x64>
    80004e16:	2244a783          	lw	a5,548(s1)
    80004e1a:	c385                	beqz	a5,80004e3a <piperead+0x64>
    if(pr->killed){
    80004e1c:	028a2783          	lw	a5,40(s4)
    80004e20:	ebc1                	bnez	a5,80004eb0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e22:	85da                	mv	a1,s6
    80004e24:	854e                	mv	a0,s3
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	2fe080e7          	jalr	766(ra) # 80002124 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e2e:	2184a703          	lw	a4,536(s1)
    80004e32:	21c4a783          	lw	a5,540(s1)
    80004e36:	fef700e3          	beq	a4,a5,80004e16 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e3a:	09505263          	blez	s5,80004ebe <piperead+0xe8>
    80004e3e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e40:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e42:	2184a783          	lw	a5,536(s1)
    80004e46:	21c4a703          	lw	a4,540(s1)
    80004e4a:	02f70d63          	beq	a4,a5,80004e84 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e4e:	0017871b          	addiw	a4,a5,1
    80004e52:	20e4ac23          	sw	a4,536(s1)
    80004e56:	1ff7f793          	andi	a5,a5,511
    80004e5a:	97a6                	add	a5,a5,s1
    80004e5c:	0187c783          	lbu	a5,24(a5)
    80004e60:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e64:	4685                	li	a3,1
    80004e66:	fbf40613          	addi	a2,s0,-65
    80004e6a:	85ca                	mv	a1,s2
    80004e6c:	050a3503          	ld	a0,80(s4)
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	802080e7          	jalr	-2046(ra) # 80001672 <copyout>
    80004e78:	01650663          	beq	a0,s6,80004e84 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e7c:	2985                	addiw	s3,s3,1
    80004e7e:	0905                	addi	s2,s2,1
    80004e80:	fd3a91e3          	bne	s5,s3,80004e42 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e84:	21c48513          	addi	a0,s1,540
    80004e88:	ffffd097          	auipc	ra,0xffffd
    80004e8c:	574080e7          	jalr	1396(ra) # 800023fc <wakeup>
  release(&pi->lock);
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
  return i;
}
    80004e9a:	854e                	mv	a0,s3
    80004e9c:	60a6                	ld	ra,72(sp)
    80004e9e:	6406                	ld	s0,64(sp)
    80004ea0:	74e2                	ld	s1,56(sp)
    80004ea2:	7942                	ld	s2,48(sp)
    80004ea4:	79a2                	ld	s3,40(sp)
    80004ea6:	7a02                	ld	s4,32(sp)
    80004ea8:	6ae2                	ld	s5,24(sp)
    80004eaa:	6b42                	ld	s6,16(sp)
    80004eac:	6161                	addi	sp,sp,80
    80004eae:	8082                	ret
      release(&pi->lock);
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
      return -1;
    80004eba:	59fd                	li	s3,-1
    80004ebc:	bff9                	j	80004e9a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ebe:	4981                	li	s3,0
    80004ec0:	b7d1                	j	80004e84 <piperead+0xae>

0000000080004ec2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ec2:	df010113          	addi	sp,sp,-528
    80004ec6:	20113423          	sd	ra,520(sp)
    80004eca:	20813023          	sd	s0,512(sp)
    80004ece:	ffa6                	sd	s1,504(sp)
    80004ed0:	fbca                	sd	s2,496(sp)
    80004ed2:	f7ce                	sd	s3,488(sp)
    80004ed4:	f3d2                	sd	s4,480(sp)
    80004ed6:	efd6                	sd	s5,472(sp)
    80004ed8:	ebda                	sd	s6,464(sp)
    80004eda:	e7de                	sd	s7,456(sp)
    80004edc:	e3e2                	sd	s8,448(sp)
    80004ede:	ff66                	sd	s9,440(sp)
    80004ee0:	fb6a                	sd	s10,432(sp)
    80004ee2:	f76e                	sd	s11,424(sp)
    80004ee4:	0c00                	addi	s0,sp,528
    80004ee6:	84aa                	mv	s1,a0
    80004ee8:	dea43c23          	sd	a0,-520(s0)
    80004eec:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	ac0080e7          	jalr	-1344(ra) # 800019b0 <myproc>
    80004ef8:	892a                	mv	s2,a0

  begin_op();
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	49c080e7          	jalr	1180(ra) # 80004396 <begin_op>

  if((ip = namei(path)) == 0){
    80004f02:	8526                	mv	a0,s1
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	276080e7          	jalr	630(ra) # 8000417a <namei>
    80004f0c:	c92d                	beqz	a0,80004f7e <exec+0xbc>
    80004f0e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	ab4080e7          	jalr	-1356(ra) # 800039c4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f18:	04000713          	li	a4,64
    80004f1c:	4681                	li	a3,0
    80004f1e:	e5040613          	addi	a2,s0,-432
    80004f22:	4581                	li	a1,0
    80004f24:	8526                	mv	a0,s1
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	d52080e7          	jalr	-686(ra) # 80003c78 <readi>
    80004f2e:	04000793          	li	a5,64
    80004f32:	00f51a63          	bne	a0,a5,80004f46 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f36:	e5042703          	lw	a4,-432(s0)
    80004f3a:	464c47b7          	lui	a5,0x464c4
    80004f3e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f42:	04f70463          	beq	a4,a5,80004f8a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f46:	8526                	mv	a0,s1
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	cde080e7          	jalr	-802(ra) # 80003c26 <iunlockput>
    end_op();
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	4c6080e7          	jalr	1222(ra) # 80004416 <end_op>
  }
  return -1;
    80004f58:	557d                	li	a0,-1
}
    80004f5a:	20813083          	ld	ra,520(sp)
    80004f5e:	20013403          	ld	s0,512(sp)
    80004f62:	74fe                	ld	s1,504(sp)
    80004f64:	795e                	ld	s2,496(sp)
    80004f66:	79be                	ld	s3,488(sp)
    80004f68:	7a1e                	ld	s4,480(sp)
    80004f6a:	6afe                	ld	s5,472(sp)
    80004f6c:	6b5e                	ld	s6,464(sp)
    80004f6e:	6bbe                	ld	s7,456(sp)
    80004f70:	6c1e                	ld	s8,448(sp)
    80004f72:	7cfa                	ld	s9,440(sp)
    80004f74:	7d5a                	ld	s10,432(sp)
    80004f76:	7dba                	ld	s11,424(sp)
    80004f78:	21010113          	addi	sp,sp,528
    80004f7c:	8082                	ret
    end_op();
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	498080e7          	jalr	1176(ra) # 80004416 <end_op>
    return -1;
    80004f86:	557d                	li	a0,-1
    80004f88:	bfc9                	j	80004f5a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f8a:	854a                	mv	a0,s2
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	ae8080e7          	jalr	-1304(ra) # 80001a74 <proc_pagetable>
    80004f94:	8baa                	mv	s7,a0
    80004f96:	d945                	beqz	a0,80004f46 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f98:	e7042983          	lw	s3,-400(s0)
    80004f9c:	e8845783          	lhu	a5,-376(s0)
    80004fa0:	c7ad                	beqz	a5,8000500a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fa2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004fa6:	6c85                	lui	s9,0x1
    80004fa8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fac:	def43823          	sd	a5,-528(s0)
    80004fb0:	a42d                	j	800051da <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fb2:	00003517          	auipc	a0,0x3
    80004fb6:	7f650513          	addi	a0,a0,2038 # 800087a8 <syscalls+0x288>
    80004fba:	ffffb097          	auipc	ra,0xffffb
    80004fbe:	584080e7          	jalr	1412(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fc2:	8756                	mv	a4,s5
    80004fc4:	012d86bb          	addw	a3,s11,s2
    80004fc8:	4581                	li	a1,0
    80004fca:	8526                	mv	a0,s1
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	cac080e7          	jalr	-852(ra) # 80003c78 <readi>
    80004fd4:	2501                	sext.w	a0,a0
    80004fd6:	1aaa9963          	bne	s5,a0,80005188 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fda:	6785                	lui	a5,0x1
    80004fdc:	0127893b          	addw	s2,a5,s2
    80004fe0:	77fd                	lui	a5,0xfffff
    80004fe2:	01478a3b          	addw	s4,a5,s4
    80004fe6:	1f897163          	bgeu	s2,s8,800051c8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fea:	02091593          	slli	a1,s2,0x20
    80004fee:	9181                	srli	a1,a1,0x20
    80004ff0:	95ea                	add	a1,a1,s10
    80004ff2:	855e                	mv	a0,s7
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	07a080e7          	jalr	122(ra) # 8000106e <walkaddr>
    80004ffc:	862a                	mv	a2,a0
    if(pa == 0)
    80004ffe:	d955                	beqz	a0,80004fb2 <exec+0xf0>
      n = PGSIZE;
    80005000:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005002:	fd9a70e3          	bgeu	s4,s9,80004fc2 <exec+0x100>
      n = sz - i;
    80005006:	8ad2                	mv	s5,s4
    80005008:	bf6d                	j	80004fc2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000500a:	4901                	li	s2,0
  iunlockput(ip);
    8000500c:	8526                	mv	a0,s1
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	c18080e7          	jalr	-1000(ra) # 80003c26 <iunlockput>
  end_op();
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	400080e7          	jalr	1024(ra) # 80004416 <end_op>
  p = myproc();
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	992080e7          	jalr	-1646(ra) # 800019b0 <myproc>
    80005026:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005028:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000502c:	6785                	lui	a5,0x1
    8000502e:	17fd                	addi	a5,a5,-1
    80005030:	993e                	add	s2,s2,a5
    80005032:	757d                	lui	a0,0xfffff
    80005034:	00a977b3          	and	a5,s2,a0
    80005038:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000503c:	6609                	lui	a2,0x2
    8000503e:	963e                	add	a2,a2,a5
    80005040:	85be                	mv	a1,a5
    80005042:	855e                	mv	a0,s7
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	3de080e7          	jalr	990(ra) # 80001422 <uvmalloc>
    8000504c:	8b2a                	mv	s6,a0
  ip = 0;
    8000504e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005050:	12050c63          	beqz	a0,80005188 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005054:	75f9                	lui	a1,0xffffe
    80005056:	95aa                	add	a1,a1,a0
    80005058:	855e                	mv	a0,s7
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	5e6080e7          	jalr	1510(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005062:	7c7d                	lui	s8,0xfffff
    80005064:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005066:	e0043783          	ld	a5,-512(s0)
    8000506a:	6388                	ld	a0,0(a5)
    8000506c:	c535                	beqz	a0,800050d8 <exec+0x216>
    8000506e:	e9040993          	addi	s3,s0,-368
    80005072:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005076:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	dec080e7          	jalr	-532(ra) # 80000e64 <strlen>
    80005080:	2505                	addiw	a0,a0,1
    80005082:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005086:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000508a:	13896363          	bltu	s2,s8,800051b0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000508e:	e0043d83          	ld	s11,-512(s0)
    80005092:	000dba03          	ld	s4,0(s11)
    80005096:	8552                	mv	a0,s4
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	dcc080e7          	jalr	-564(ra) # 80000e64 <strlen>
    800050a0:	0015069b          	addiw	a3,a0,1
    800050a4:	8652                	mv	a2,s4
    800050a6:	85ca                	mv	a1,s2
    800050a8:	855e                	mv	a0,s7
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	5c8080e7          	jalr	1480(ra) # 80001672 <copyout>
    800050b2:	10054363          	bltz	a0,800051b8 <exec+0x2f6>
    ustack[argc] = sp;
    800050b6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050ba:	0485                	addi	s1,s1,1
    800050bc:	008d8793          	addi	a5,s11,8
    800050c0:	e0f43023          	sd	a5,-512(s0)
    800050c4:	008db503          	ld	a0,8(s11)
    800050c8:	c911                	beqz	a0,800050dc <exec+0x21a>
    if(argc >= MAXARG)
    800050ca:	09a1                	addi	s3,s3,8
    800050cc:	fb3c96e3          	bne	s9,s3,80005078 <exec+0x1b6>
  sz = sz1;
    800050d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d4:	4481                	li	s1,0
    800050d6:	a84d                	j	80005188 <exec+0x2c6>
  sp = sz;
    800050d8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050da:	4481                	li	s1,0
  ustack[argc] = 0;
    800050dc:	00349793          	slli	a5,s1,0x3
    800050e0:	f9040713          	addi	a4,s0,-112
    800050e4:	97ba                	add	a5,a5,a4
    800050e6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050ea:	00148693          	addi	a3,s1,1
    800050ee:	068e                	slli	a3,a3,0x3
    800050f0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050f4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050f8:	01897663          	bgeu	s2,s8,80005104 <exec+0x242>
  sz = sz1;
    800050fc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005100:	4481                	li	s1,0
    80005102:	a059                	j	80005188 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005104:	e9040613          	addi	a2,s0,-368
    80005108:	85ca                	mv	a1,s2
    8000510a:	855e                	mv	a0,s7
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	566080e7          	jalr	1382(ra) # 80001672 <copyout>
    80005114:	0a054663          	bltz	a0,800051c0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005118:	058ab783          	ld	a5,88(s5)
    8000511c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005120:	df843783          	ld	a5,-520(s0)
    80005124:	0007c703          	lbu	a4,0(a5)
    80005128:	cf11                	beqz	a4,80005144 <exec+0x282>
    8000512a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000512c:	02f00693          	li	a3,47
    80005130:	a039                	j	8000513e <exec+0x27c>
      last = s+1;
    80005132:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005136:	0785                	addi	a5,a5,1
    80005138:	fff7c703          	lbu	a4,-1(a5)
    8000513c:	c701                	beqz	a4,80005144 <exec+0x282>
    if(*s == '/')
    8000513e:	fed71ce3          	bne	a4,a3,80005136 <exec+0x274>
    80005142:	bfc5                	j	80005132 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005144:	4641                	li	a2,16
    80005146:	df843583          	ld	a1,-520(s0)
    8000514a:	158a8513          	addi	a0,s5,344
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	ce4080e7          	jalr	-796(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005156:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000515a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000515e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005162:	058ab783          	ld	a5,88(s5)
    80005166:	e6843703          	ld	a4,-408(s0)
    8000516a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000516c:	058ab783          	ld	a5,88(s5)
    80005170:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005174:	85ea                	mv	a1,s10
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	99a080e7          	jalr	-1638(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000517e:	0004851b          	sext.w	a0,s1
    80005182:	bbe1                	j	80004f5a <exec+0x98>
    80005184:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005188:	e0843583          	ld	a1,-504(s0)
    8000518c:	855e                	mv	a0,s7
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	982080e7          	jalr	-1662(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005196:	da0498e3          	bnez	s1,80004f46 <exec+0x84>
  return -1;
    8000519a:	557d                	li	a0,-1
    8000519c:	bb7d                	j	80004f5a <exec+0x98>
    8000519e:	e1243423          	sd	s2,-504(s0)
    800051a2:	b7dd                	j	80005188 <exec+0x2c6>
    800051a4:	e1243423          	sd	s2,-504(s0)
    800051a8:	b7c5                	j	80005188 <exec+0x2c6>
    800051aa:	e1243423          	sd	s2,-504(s0)
    800051ae:	bfe9                	j	80005188 <exec+0x2c6>
  sz = sz1;
    800051b0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051b4:	4481                	li	s1,0
    800051b6:	bfc9                	j	80005188 <exec+0x2c6>
  sz = sz1;
    800051b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051bc:	4481                	li	s1,0
    800051be:	b7e9                	j	80005188 <exec+0x2c6>
  sz = sz1;
    800051c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c4:	4481                	li	s1,0
    800051c6:	b7c9                	j	80005188 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051cc:	2b05                	addiw	s6,s6,1
    800051ce:	0389899b          	addiw	s3,s3,56
    800051d2:	e8845783          	lhu	a5,-376(s0)
    800051d6:	e2fb5be3          	bge	s6,a5,8000500c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051da:	2981                	sext.w	s3,s3
    800051dc:	03800713          	li	a4,56
    800051e0:	86ce                	mv	a3,s3
    800051e2:	e1840613          	addi	a2,s0,-488
    800051e6:	4581                	li	a1,0
    800051e8:	8526                	mv	a0,s1
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	a8e080e7          	jalr	-1394(ra) # 80003c78 <readi>
    800051f2:	03800793          	li	a5,56
    800051f6:	f8f517e3          	bne	a0,a5,80005184 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051fa:	e1842783          	lw	a5,-488(s0)
    800051fe:	4705                	li	a4,1
    80005200:	fce796e3          	bne	a5,a4,800051cc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005204:	e4043603          	ld	a2,-448(s0)
    80005208:	e3843783          	ld	a5,-456(s0)
    8000520c:	f8f669e3          	bltu	a2,a5,8000519e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005210:	e2843783          	ld	a5,-472(s0)
    80005214:	963e                	add	a2,a2,a5
    80005216:	f8f667e3          	bltu	a2,a5,800051a4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000521a:	85ca                	mv	a1,s2
    8000521c:	855e                	mv	a0,s7
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	204080e7          	jalr	516(ra) # 80001422 <uvmalloc>
    80005226:	e0a43423          	sd	a0,-504(s0)
    8000522a:	d141                	beqz	a0,800051aa <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000522c:	e2843d03          	ld	s10,-472(s0)
    80005230:	df043783          	ld	a5,-528(s0)
    80005234:	00fd77b3          	and	a5,s10,a5
    80005238:	fba1                	bnez	a5,80005188 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000523a:	e2042d83          	lw	s11,-480(s0)
    8000523e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005242:	f80c03e3          	beqz	s8,800051c8 <exec+0x306>
    80005246:	8a62                	mv	s4,s8
    80005248:	4901                	li	s2,0
    8000524a:	b345                	j	80004fea <exec+0x128>

000000008000524c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	ec26                	sd	s1,24(sp)
    80005254:	e84a                	sd	s2,16(sp)
    80005256:	1800                	addi	s0,sp,48
    80005258:	892e                	mv	s2,a1
    8000525a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000525c:	fdc40593          	addi	a1,s0,-36
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	9f4080e7          	jalr	-1548(ra) # 80002c54 <argint>
    80005268:	04054063          	bltz	a0,800052a8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000526c:	fdc42703          	lw	a4,-36(s0)
    80005270:	47bd                	li	a5,15
    80005272:	02e7ed63          	bltu	a5,a4,800052ac <argfd+0x60>
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	73a080e7          	jalr	1850(ra) # 800019b0 <myproc>
    8000527e:	fdc42703          	lw	a4,-36(s0)
    80005282:	01a70793          	addi	a5,a4,26
    80005286:	078e                	slli	a5,a5,0x3
    80005288:	953e                	add	a0,a0,a5
    8000528a:	611c                	ld	a5,0(a0)
    8000528c:	c395                	beqz	a5,800052b0 <argfd+0x64>
    return -1;
  if(pfd)
    8000528e:	00090463          	beqz	s2,80005296 <argfd+0x4a>
    *pfd = fd;
    80005292:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005296:	4501                	li	a0,0
  if(pf)
    80005298:	c091                	beqz	s1,8000529c <argfd+0x50>
    *pf = f;
    8000529a:	e09c                	sd	a5,0(s1)
}
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	64e2                	ld	s1,24(sp)
    800052a2:	6942                	ld	s2,16(sp)
    800052a4:	6145                	addi	sp,sp,48
    800052a6:	8082                	ret
    return -1;
    800052a8:	557d                	li	a0,-1
    800052aa:	bfcd                	j	8000529c <argfd+0x50>
    return -1;
    800052ac:	557d                	li	a0,-1
    800052ae:	b7fd                	j	8000529c <argfd+0x50>
    800052b0:	557d                	li	a0,-1
    800052b2:	b7ed                	j	8000529c <argfd+0x50>

00000000800052b4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052b4:	1101                	addi	sp,sp,-32
    800052b6:	ec06                	sd	ra,24(sp)
    800052b8:	e822                	sd	s0,16(sp)
    800052ba:	e426                	sd	s1,8(sp)
    800052bc:	1000                	addi	s0,sp,32
    800052be:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	6f0080e7          	jalr	1776(ra) # 800019b0 <myproc>
    800052c8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ca:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800052ce:	4501                	li	a0,0
    800052d0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052d2:	6398                	ld	a4,0(a5)
    800052d4:	cb19                	beqz	a4,800052ea <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052d6:	2505                	addiw	a0,a0,1
    800052d8:	07a1                	addi	a5,a5,8
    800052da:	fed51ce3          	bne	a0,a3,800052d2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052de:	557d                	li	a0,-1
}
    800052e0:	60e2                	ld	ra,24(sp)
    800052e2:	6442                	ld	s0,16(sp)
    800052e4:	64a2                	ld	s1,8(sp)
    800052e6:	6105                	addi	sp,sp,32
    800052e8:	8082                	ret
      p->ofile[fd] = f;
    800052ea:	01a50793          	addi	a5,a0,26
    800052ee:	078e                	slli	a5,a5,0x3
    800052f0:	963e                	add	a2,a2,a5
    800052f2:	e204                	sd	s1,0(a2)
      return fd;
    800052f4:	b7f5                	j	800052e0 <fdalloc+0x2c>

00000000800052f6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052f6:	715d                	addi	sp,sp,-80
    800052f8:	e486                	sd	ra,72(sp)
    800052fa:	e0a2                	sd	s0,64(sp)
    800052fc:	fc26                	sd	s1,56(sp)
    800052fe:	f84a                	sd	s2,48(sp)
    80005300:	f44e                	sd	s3,40(sp)
    80005302:	f052                	sd	s4,32(sp)
    80005304:	ec56                	sd	s5,24(sp)
    80005306:	0880                	addi	s0,sp,80
    80005308:	89ae                	mv	s3,a1
    8000530a:	8ab2                	mv	s5,a2
    8000530c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000530e:	fb040593          	addi	a1,s0,-80
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	e86080e7          	jalr	-378(ra) # 80004198 <nameiparent>
    8000531a:	892a                	mv	s2,a0
    8000531c:	12050f63          	beqz	a0,8000545a <create+0x164>
    return 0;

  ilock(dp);
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	6a4080e7          	jalr	1700(ra) # 800039c4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005328:	4601                	li	a2,0
    8000532a:	fb040593          	addi	a1,s0,-80
    8000532e:	854a                	mv	a0,s2
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	b78080e7          	jalr	-1160(ra) # 80003ea8 <dirlookup>
    80005338:	84aa                	mv	s1,a0
    8000533a:	c921                	beqz	a0,8000538a <create+0x94>
    iunlockput(dp);
    8000533c:	854a                	mv	a0,s2
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	8e8080e7          	jalr	-1816(ra) # 80003c26 <iunlockput>
    ilock(ip);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	67c080e7          	jalr	1660(ra) # 800039c4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005350:	2981                	sext.w	s3,s3
    80005352:	4789                	li	a5,2
    80005354:	02f99463          	bne	s3,a5,8000537c <create+0x86>
    80005358:	0444d783          	lhu	a5,68(s1)
    8000535c:	37f9                	addiw	a5,a5,-2
    8000535e:	17c2                	slli	a5,a5,0x30
    80005360:	93c1                	srli	a5,a5,0x30
    80005362:	4705                	li	a4,1
    80005364:	00f76c63          	bltu	a4,a5,8000537c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005368:	8526                	mv	a0,s1
    8000536a:	60a6                	ld	ra,72(sp)
    8000536c:	6406                	ld	s0,64(sp)
    8000536e:	74e2                	ld	s1,56(sp)
    80005370:	7942                	ld	s2,48(sp)
    80005372:	79a2                	ld	s3,40(sp)
    80005374:	7a02                	ld	s4,32(sp)
    80005376:	6ae2                	ld	s5,24(sp)
    80005378:	6161                	addi	sp,sp,80
    8000537a:	8082                	ret
    iunlockput(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	8a8080e7          	jalr	-1880(ra) # 80003c26 <iunlockput>
    return 0;
    80005386:	4481                	li	s1,0
    80005388:	b7c5                	j	80005368 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000538a:	85ce                	mv	a1,s3
    8000538c:	00092503          	lw	a0,0(s2)
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	49c080e7          	jalr	1180(ra) # 8000382c <ialloc>
    80005398:	84aa                	mv	s1,a0
    8000539a:	c529                	beqz	a0,800053e4 <create+0xee>
  ilock(ip);
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	628080e7          	jalr	1576(ra) # 800039c4 <ilock>
  ip->major = major;
    800053a4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053a8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053ac:	4785                	li	a5,1
    800053ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	546080e7          	jalr	1350(ra) # 800038fa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053bc:	2981                	sext.w	s3,s3
    800053be:	4785                	li	a5,1
    800053c0:	02f98a63          	beq	s3,a5,800053f4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053c4:	40d0                	lw	a2,4(s1)
    800053c6:	fb040593          	addi	a1,s0,-80
    800053ca:	854a                	mv	a0,s2
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	cec080e7          	jalr	-788(ra) # 800040b8 <dirlink>
    800053d4:	06054b63          	bltz	a0,8000544a <create+0x154>
  iunlockput(dp);
    800053d8:	854a                	mv	a0,s2
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	84c080e7          	jalr	-1972(ra) # 80003c26 <iunlockput>
  return ip;
    800053e2:	b759                	j	80005368 <create+0x72>
    panic("create: ialloc");
    800053e4:	00003517          	auipc	a0,0x3
    800053e8:	3e450513          	addi	a0,a0,996 # 800087c8 <syscalls+0x2a8>
    800053ec:	ffffb097          	auipc	ra,0xffffb
    800053f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053f4:	04a95783          	lhu	a5,74(s2)
    800053f8:	2785                	addiw	a5,a5,1
    800053fa:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053fe:	854a                	mv	a0,s2
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	4fa080e7          	jalr	1274(ra) # 800038fa <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005408:	40d0                	lw	a2,4(s1)
    8000540a:	00003597          	auipc	a1,0x3
    8000540e:	3ce58593          	addi	a1,a1,974 # 800087d8 <syscalls+0x2b8>
    80005412:	8526                	mv	a0,s1
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	ca4080e7          	jalr	-860(ra) # 800040b8 <dirlink>
    8000541c:	00054f63          	bltz	a0,8000543a <create+0x144>
    80005420:	00492603          	lw	a2,4(s2)
    80005424:	00003597          	auipc	a1,0x3
    80005428:	3bc58593          	addi	a1,a1,956 # 800087e0 <syscalls+0x2c0>
    8000542c:	8526                	mv	a0,s1
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	c8a080e7          	jalr	-886(ra) # 800040b8 <dirlink>
    80005436:	f80557e3          	bgez	a0,800053c4 <create+0xce>
      panic("create dots");
    8000543a:	00003517          	auipc	a0,0x3
    8000543e:	3ae50513          	addi	a0,a0,942 # 800087e8 <syscalls+0x2c8>
    80005442:	ffffb097          	auipc	ra,0xffffb
    80005446:	0fc080e7          	jalr	252(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000544a:	00003517          	auipc	a0,0x3
    8000544e:	3ae50513          	addi	a0,a0,942 # 800087f8 <syscalls+0x2d8>
    80005452:	ffffb097          	auipc	ra,0xffffb
    80005456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>
    return 0;
    8000545a:	84aa                	mv	s1,a0
    8000545c:	b731                	j	80005368 <create+0x72>

000000008000545e <sys_dup>:
{
    8000545e:	7179                	addi	sp,sp,-48
    80005460:	f406                	sd	ra,40(sp)
    80005462:	f022                	sd	s0,32(sp)
    80005464:	ec26                	sd	s1,24(sp)
    80005466:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005468:	fd840613          	addi	a2,s0,-40
    8000546c:	4581                	li	a1,0
    8000546e:	4501                	li	a0,0
    80005470:	00000097          	auipc	ra,0x0
    80005474:	ddc080e7          	jalr	-548(ra) # 8000524c <argfd>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000547a:	02054363          	bltz	a0,800054a0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000547e:	fd843503          	ld	a0,-40(s0)
    80005482:	00000097          	auipc	ra,0x0
    80005486:	e32080e7          	jalr	-462(ra) # 800052b4 <fdalloc>
    8000548a:	84aa                	mv	s1,a0
    return -1;
    8000548c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000548e:	00054963          	bltz	a0,800054a0 <sys_dup+0x42>
  filedup(f);
    80005492:	fd843503          	ld	a0,-40(s0)
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	37a080e7          	jalr	890(ra) # 80004810 <filedup>
  return fd;
    8000549e:	87a6                	mv	a5,s1
}
    800054a0:	853e                	mv	a0,a5
    800054a2:	70a2                	ld	ra,40(sp)
    800054a4:	7402                	ld	s0,32(sp)
    800054a6:	64e2                	ld	s1,24(sp)
    800054a8:	6145                	addi	sp,sp,48
    800054aa:	8082                	ret

00000000800054ac <sys_read>:
{
    800054ac:	7179                	addi	sp,sp,-48
    800054ae:	f406                	sd	ra,40(sp)
    800054b0:	f022                	sd	s0,32(sp)
    800054b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b4:	fe840613          	addi	a2,s0,-24
    800054b8:	4581                	li	a1,0
    800054ba:	4501                	li	a0,0
    800054bc:	00000097          	auipc	ra,0x0
    800054c0:	d90080e7          	jalr	-624(ra) # 8000524c <argfd>
    return -1;
    800054c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c6:	04054163          	bltz	a0,80005508 <sys_read+0x5c>
    800054ca:	fe440593          	addi	a1,s0,-28
    800054ce:	4509                	li	a0,2
    800054d0:	ffffd097          	auipc	ra,0xffffd
    800054d4:	784080e7          	jalr	1924(ra) # 80002c54 <argint>
    return -1;
    800054d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054da:	02054763          	bltz	a0,80005508 <sys_read+0x5c>
    800054de:	fd840593          	addi	a1,s0,-40
    800054e2:	4505                	li	a0,1
    800054e4:	ffffd097          	auipc	ra,0xffffd
    800054e8:	792080e7          	jalr	1938(ra) # 80002c76 <argaddr>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ee:	00054d63          	bltz	a0,80005508 <sys_read+0x5c>
  return fileread(f, p, n);
    800054f2:	fe442603          	lw	a2,-28(s0)
    800054f6:	fd843583          	ld	a1,-40(s0)
    800054fa:	fe843503          	ld	a0,-24(s0)
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	49e080e7          	jalr	1182(ra) # 8000499c <fileread>
    80005506:	87aa                	mv	a5,a0
}
    80005508:	853e                	mv	a0,a5
    8000550a:	70a2                	ld	ra,40(sp)
    8000550c:	7402                	ld	s0,32(sp)
    8000550e:	6145                	addi	sp,sp,48
    80005510:	8082                	ret

0000000080005512 <sys_write>:
{
    80005512:	7179                	addi	sp,sp,-48
    80005514:	f406                	sd	ra,40(sp)
    80005516:	f022                	sd	s0,32(sp)
    80005518:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551a:	fe840613          	addi	a2,s0,-24
    8000551e:	4581                	li	a1,0
    80005520:	4501                	li	a0,0
    80005522:	00000097          	auipc	ra,0x0
    80005526:	d2a080e7          	jalr	-726(ra) # 8000524c <argfd>
    return -1;
    8000552a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552c:	04054163          	bltz	a0,8000556e <sys_write+0x5c>
    80005530:	fe440593          	addi	a1,s0,-28
    80005534:	4509                	li	a0,2
    80005536:	ffffd097          	auipc	ra,0xffffd
    8000553a:	71e080e7          	jalr	1822(ra) # 80002c54 <argint>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005540:	02054763          	bltz	a0,8000556e <sys_write+0x5c>
    80005544:	fd840593          	addi	a1,s0,-40
    80005548:	4505                	li	a0,1
    8000554a:	ffffd097          	auipc	ra,0xffffd
    8000554e:	72c080e7          	jalr	1836(ra) # 80002c76 <argaddr>
    return -1;
    80005552:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005554:	00054d63          	bltz	a0,8000556e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005558:	fe442603          	lw	a2,-28(s0)
    8000555c:	fd843583          	ld	a1,-40(s0)
    80005560:	fe843503          	ld	a0,-24(s0)
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	4fa080e7          	jalr	1274(ra) # 80004a5e <filewrite>
    8000556c:	87aa                	mv	a5,a0
}
    8000556e:	853e                	mv	a0,a5
    80005570:	70a2                	ld	ra,40(sp)
    80005572:	7402                	ld	s0,32(sp)
    80005574:	6145                	addi	sp,sp,48
    80005576:	8082                	ret

0000000080005578 <sys_close>:
{
    80005578:	1101                	addi	sp,sp,-32
    8000557a:	ec06                	sd	ra,24(sp)
    8000557c:	e822                	sd	s0,16(sp)
    8000557e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005580:	fe040613          	addi	a2,s0,-32
    80005584:	fec40593          	addi	a1,s0,-20
    80005588:	4501                	li	a0,0
    8000558a:	00000097          	auipc	ra,0x0
    8000558e:	cc2080e7          	jalr	-830(ra) # 8000524c <argfd>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005594:	02054463          	bltz	a0,800055bc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	418080e7          	jalr	1048(ra) # 800019b0 <myproc>
    800055a0:	fec42783          	lw	a5,-20(s0)
    800055a4:	07e9                	addi	a5,a5,26
    800055a6:	078e                	slli	a5,a5,0x3
    800055a8:	97aa                	add	a5,a5,a0
    800055aa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055ae:	fe043503          	ld	a0,-32(s0)
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	2b0080e7          	jalr	688(ra) # 80004862 <fileclose>
  return 0;
    800055ba:	4781                	li	a5,0
}
    800055bc:	853e                	mv	a0,a5
    800055be:	60e2                	ld	ra,24(sp)
    800055c0:	6442                	ld	s0,16(sp)
    800055c2:	6105                	addi	sp,sp,32
    800055c4:	8082                	ret

00000000800055c6 <sys_fstat>:
{
    800055c6:	1101                	addi	sp,sp,-32
    800055c8:	ec06                	sd	ra,24(sp)
    800055ca:	e822                	sd	s0,16(sp)
    800055cc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ce:	fe840613          	addi	a2,s0,-24
    800055d2:	4581                	li	a1,0
    800055d4:	4501                	li	a0,0
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	c76080e7          	jalr	-906(ra) # 8000524c <argfd>
    return -1;
    800055de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e0:	02054563          	bltz	a0,8000560a <sys_fstat+0x44>
    800055e4:	fe040593          	addi	a1,s0,-32
    800055e8:	4505                	li	a0,1
    800055ea:	ffffd097          	auipc	ra,0xffffd
    800055ee:	68c080e7          	jalr	1676(ra) # 80002c76 <argaddr>
    return -1;
    800055f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f4:	00054b63          	bltz	a0,8000560a <sys_fstat+0x44>
  return filestat(f, st);
    800055f8:	fe043583          	ld	a1,-32(s0)
    800055fc:	fe843503          	ld	a0,-24(s0)
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	32a080e7          	jalr	810(ra) # 8000492a <filestat>
    80005608:	87aa                	mv	a5,a0
}
    8000560a:	853e                	mv	a0,a5
    8000560c:	60e2                	ld	ra,24(sp)
    8000560e:	6442                	ld	s0,16(sp)
    80005610:	6105                	addi	sp,sp,32
    80005612:	8082                	ret

0000000080005614 <sys_link>:
{
    80005614:	7169                	addi	sp,sp,-304
    80005616:	f606                	sd	ra,296(sp)
    80005618:	f222                	sd	s0,288(sp)
    8000561a:	ee26                	sd	s1,280(sp)
    8000561c:	ea4a                	sd	s2,272(sp)
    8000561e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005620:	08000613          	li	a2,128
    80005624:	ed040593          	addi	a1,s0,-304
    80005628:	4501                	li	a0,0
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	66e080e7          	jalr	1646(ra) # 80002c98 <argstr>
    return -1;
    80005632:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005634:	10054e63          	bltz	a0,80005750 <sys_link+0x13c>
    80005638:	08000613          	li	a2,128
    8000563c:	f5040593          	addi	a1,s0,-176
    80005640:	4505                	li	a0,1
    80005642:	ffffd097          	auipc	ra,0xffffd
    80005646:	656080e7          	jalr	1622(ra) # 80002c98 <argstr>
    return -1;
    8000564a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000564c:	10054263          	bltz	a0,80005750 <sys_link+0x13c>
  begin_op();
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	d46080e7          	jalr	-698(ra) # 80004396 <begin_op>
  if((ip = namei(old)) == 0){
    80005658:	ed040513          	addi	a0,s0,-304
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	b1e080e7          	jalr	-1250(ra) # 8000417a <namei>
    80005664:	84aa                	mv	s1,a0
    80005666:	c551                	beqz	a0,800056f2 <sys_link+0xde>
  ilock(ip);
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	35c080e7          	jalr	860(ra) # 800039c4 <ilock>
  if(ip->type == T_DIR){
    80005670:	04449703          	lh	a4,68(s1)
    80005674:	4785                	li	a5,1
    80005676:	08f70463          	beq	a4,a5,800056fe <sys_link+0xea>
  ip->nlink++;
    8000567a:	04a4d783          	lhu	a5,74(s1)
    8000567e:	2785                	addiw	a5,a5,1
    80005680:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	274080e7          	jalr	628(ra) # 800038fa <iupdate>
  iunlock(ip);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	3f6080e7          	jalr	1014(ra) # 80003a86 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005698:	fd040593          	addi	a1,s0,-48
    8000569c:	f5040513          	addi	a0,s0,-176
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	af8080e7          	jalr	-1288(ra) # 80004198 <nameiparent>
    800056a8:	892a                	mv	s2,a0
    800056aa:	c935                	beqz	a0,8000571e <sys_link+0x10a>
  ilock(dp);
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	318080e7          	jalr	792(ra) # 800039c4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056b4:	00092703          	lw	a4,0(s2)
    800056b8:	409c                	lw	a5,0(s1)
    800056ba:	04f71d63          	bne	a4,a5,80005714 <sys_link+0x100>
    800056be:	40d0                	lw	a2,4(s1)
    800056c0:	fd040593          	addi	a1,s0,-48
    800056c4:	854a                	mv	a0,s2
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	9f2080e7          	jalr	-1550(ra) # 800040b8 <dirlink>
    800056ce:	04054363          	bltz	a0,80005714 <sys_link+0x100>
  iunlockput(dp);
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	552080e7          	jalr	1362(ra) # 80003c26 <iunlockput>
  iput(ip);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	4a0080e7          	jalr	1184(ra) # 80003b7e <iput>
  end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	d30080e7          	jalr	-720(ra) # 80004416 <end_op>
  return 0;
    800056ee:	4781                	li	a5,0
    800056f0:	a085                	j	80005750 <sys_link+0x13c>
    end_op();
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	d24080e7          	jalr	-732(ra) # 80004416 <end_op>
    return -1;
    800056fa:	57fd                	li	a5,-1
    800056fc:	a891                	j	80005750 <sys_link+0x13c>
    iunlockput(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	526080e7          	jalr	1318(ra) # 80003c26 <iunlockput>
    end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	d0e080e7          	jalr	-754(ra) # 80004416 <end_op>
    return -1;
    80005710:	57fd                	li	a5,-1
    80005712:	a83d                	j	80005750 <sys_link+0x13c>
    iunlockput(dp);
    80005714:	854a                	mv	a0,s2
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	510080e7          	jalr	1296(ra) # 80003c26 <iunlockput>
  ilock(ip);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	2a4080e7          	jalr	676(ra) # 800039c4 <ilock>
  ip->nlink--;
    80005728:	04a4d783          	lhu	a5,74(s1)
    8000572c:	37fd                	addiw	a5,a5,-1
    8000572e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	1c6080e7          	jalr	454(ra) # 800038fa <iupdate>
  iunlockput(ip);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	4e8080e7          	jalr	1256(ra) # 80003c26 <iunlockput>
  end_op();
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	cd0080e7          	jalr	-816(ra) # 80004416 <end_op>
  return -1;
    8000574e:	57fd                	li	a5,-1
}
    80005750:	853e                	mv	a0,a5
    80005752:	70b2                	ld	ra,296(sp)
    80005754:	7412                	ld	s0,288(sp)
    80005756:	64f2                	ld	s1,280(sp)
    80005758:	6952                	ld	s2,272(sp)
    8000575a:	6155                	addi	sp,sp,304
    8000575c:	8082                	ret

000000008000575e <sys_unlink>:
{
    8000575e:	7151                	addi	sp,sp,-240
    80005760:	f586                	sd	ra,232(sp)
    80005762:	f1a2                	sd	s0,224(sp)
    80005764:	eda6                	sd	s1,216(sp)
    80005766:	e9ca                	sd	s2,208(sp)
    80005768:	e5ce                	sd	s3,200(sp)
    8000576a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000576c:	08000613          	li	a2,128
    80005770:	f3040593          	addi	a1,s0,-208
    80005774:	4501                	li	a0,0
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	522080e7          	jalr	1314(ra) # 80002c98 <argstr>
    8000577e:	18054163          	bltz	a0,80005900 <sys_unlink+0x1a2>
  begin_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	c14080e7          	jalr	-1004(ra) # 80004396 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000578a:	fb040593          	addi	a1,s0,-80
    8000578e:	f3040513          	addi	a0,s0,-208
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	a06080e7          	jalr	-1530(ra) # 80004198 <nameiparent>
    8000579a:	84aa                	mv	s1,a0
    8000579c:	c979                	beqz	a0,80005872 <sys_unlink+0x114>
  ilock(dp);
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	226080e7          	jalr	550(ra) # 800039c4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057a6:	00003597          	auipc	a1,0x3
    800057aa:	03258593          	addi	a1,a1,50 # 800087d8 <syscalls+0x2b8>
    800057ae:	fb040513          	addi	a0,s0,-80
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	6dc080e7          	jalr	1756(ra) # 80003e8e <namecmp>
    800057ba:	14050a63          	beqz	a0,8000590e <sys_unlink+0x1b0>
    800057be:	00003597          	auipc	a1,0x3
    800057c2:	02258593          	addi	a1,a1,34 # 800087e0 <syscalls+0x2c0>
    800057c6:	fb040513          	addi	a0,s0,-80
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	6c4080e7          	jalr	1732(ra) # 80003e8e <namecmp>
    800057d2:	12050e63          	beqz	a0,8000590e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057d6:	f2c40613          	addi	a2,s0,-212
    800057da:	fb040593          	addi	a1,s0,-80
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	6c8080e7          	jalr	1736(ra) # 80003ea8 <dirlookup>
    800057e8:	892a                	mv	s2,a0
    800057ea:	12050263          	beqz	a0,8000590e <sys_unlink+0x1b0>
  ilock(ip);
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	1d6080e7          	jalr	470(ra) # 800039c4 <ilock>
  if(ip->nlink < 1)
    800057f6:	04a91783          	lh	a5,74(s2)
    800057fa:	08f05263          	blez	a5,8000587e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	4785                	li	a5,1
    80005804:	08f70563          	beq	a4,a5,8000588e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005808:	4641                	li	a2,16
    8000580a:	4581                	li	a1,0
    8000580c:	fc040513          	addi	a0,s0,-64
    80005810:	ffffb097          	auipc	ra,0xffffb
    80005814:	4d0080e7          	jalr	1232(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005818:	4741                	li	a4,16
    8000581a:	f2c42683          	lw	a3,-212(s0)
    8000581e:	fc040613          	addi	a2,s0,-64
    80005822:	4581                	li	a1,0
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	54a080e7          	jalr	1354(ra) # 80003d70 <writei>
    8000582e:	47c1                	li	a5,16
    80005830:	0af51563          	bne	a0,a5,800058da <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005834:	04491703          	lh	a4,68(s2)
    80005838:	4785                	li	a5,1
    8000583a:	0af70863          	beq	a4,a5,800058ea <sys_unlink+0x18c>
  iunlockput(dp);
    8000583e:	8526                	mv	a0,s1
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	3e6080e7          	jalr	998(ra) # 80003c26 <iunlockput>
  ip->nlink--;
    80005848:	04a95783          	lhu	a5,74(s2)
    8000584c:	37fd                	addiw	a5,a5,-1
    8000584e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	0a6080e7          	jalr	166(ra) # 800038fa <iupdate>
  iunlockput(ip);
    8000585c:	854a                	mv	a0,s2
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	3c8080e7          	jalr	968(ra) # 80003c26 <iunlockput>
  end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	bb0080e7          	jalr	-1104(ra) # 80004416 <end_op>
  return 0;
    8000586e:	4501                	li	a0,0
    80005870:	a84d                	j	80005922 <sys_unlink+0x1c4>
    end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	ba4080e7          	jalr	-1116(ra) # 80004416 <end_op>
    return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	a05d                	j	80005922 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000587e:	00003517          	auipc	a0,0x3
    80005882:	f8a50513          	addi	a0,a0,-118 # 80008808 <syscalls+0x2e8>
    80005886:	ffffb097          	auipc	ra,0xffffb
    8000588a:	cb8080e7          	jalr	-840(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000588e:	04c92703          	lw	a4,76(s2)
    80005892:	02000793          	li	a5,32
    80005896:	f6e7f9e3          	bgeu	a5,a4,80005808 <sys_unlink+0xaa>
    8000589a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000589e:	4741                	li	a4,16
    800058a0:	86ce                	mv	a3,s3
    800058a2:	f1840613          	addi	a2,s0,-232
    800058a6:	4581                	li	a1,0
    800058a8:	854a                	mv	a0,s2
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	3ce080e7          	jalr	974(ra) # 80003c78 <readi>
    800058b2:	47c1                	li	a5,16
    800058b4:	00f51b63          	bne	a0,a5,800058ca <sys_unlink+0x16c>
    if(de.inum != 0)
    800058b8:	f1845783          	lhu	a5,-232(s0)
    800058bc:	e7a1                	bnez	a5,80005904 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058be:	29c1                	addiw	s3,s3,16
    800058c0:	04c92783          	lw	a5,76(s2)
    800058c4:	fcf9ede3          	bltu	s3,a5,8000589e <sys_unlink+0x140>
    800058c8:	b781                	j	80005808 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058ca:	00003517          	auipc	a0,0x3
    800058ce:	f5650513          	addi	a0,a0,-170 # 80008820 <syscalls+0x300>
    800058d2:	ffffb097          	auipc	ra,0xffffb
    800058d6:	c6c080e7          	jalr	-916(ra) # 8000053e <panic>
    panic("unlink: writei");
    800058da:	00003517          	auipc	a0,0x3
    800058de:	f5e50513          	addi	a0,a0,-162 # 80008838 <syscalls+0x318>
    800058e2:	ffffb097          	auipc	ra,0xffffb
    800058e6:	c5c080e7          	jalr	-932(ra) # 8000053e <panic>
    dp->nlink--;
    800058ea:	04a4d783          	lhu	a5,74(s1)
    800058ee:	37fd                	addiw	a5,a5,-1
    800058f0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	004080e7          	jalr	4(ra) # 800038fa <iupdate>
    800058fe:	b781                	j	8000583e <sys_unlink+0xe0>
    return -1;
    80005900:	557d                	li	a0,-1
    80005902:	a005                	j	80005922 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005904:	854a                	mv	a0,s2
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	320080e7          	jalr	800(ra) # 80003c26 <iunlockput>
  iunlockput(dp);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	316080e7          	jalr	790(ra) # 80003c26 <iunlockput>
  end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	afe080e7          	jalr	-1282(ra) # 80004416 <end_op>
  return -1;
    80005920:	557d                	li	a0,-1
}
    80005922:	70ae                	ld	ra,232(sp)
    80005924:	740e                	ld	s0,224(sp)
    80005926:	64ee                	ld	s1,216(sp)
    80005928:	694e                	ld	s2,208(sp)
    8000592a:	69ae                	ld	s3,200(sp)
    8000592c:	616d                	addi	sp,sp,240
    8000592e:	8082                	ret

0000000080005930 <sys_open>:

uint64
sys_open(void)
{
    80005930:	7131                	addi	sp,sp,-192
    80005932:	fd06                	sd	ra,184(sp)
    80005934:	f922                	sd	s0,176(sp)
    80005936:	f526                	sd	s1,168(sp)
    80005938:	f14a                	sd	s2,160(sp)
    8000593a:	ed4e                	sd	s3,152(sp)
    8000593c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000593e:	08000613          	li	a2,128
    80005942:	f5040593          	addi	a1,s0,-176
    80005946:	4501                	li	a0,0
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	350080e7          	jalr	848(ra) # 80002c98 <argstr>
    return -1;
    80005950:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005952:	0c054163          	bltz	a0,80005a14 <sys_open+0xe4>
    80005956:	f4c40593          	addi	a1,s0,-180
    8000595a:	4505                	li	a0,1
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	2f8080e7          	jalr	760(ra) # 80002c54 <argint>
    80005964:	0a054863          	bltz	a0,80005a14 <sys_open+0xe4>

  begin_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	a2e080e7          	jalr	-1490(ra) # 80004396 <begin_op>

  if(omode & O_CREATE){
    80005970:	f4c42783          	lw	a5,-180(s0)
    80005974:	2007f793          	andi	a5,a5,512
    80005978:	cbdd                	beqz	a5,80005a2e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000597a:	4681                	li	a3,0
    8000597c:	4601                	li	a2,0
    8000597e:	4589                	li	a1,2
    80005980:	f5040513          	addi	a0,s0,-176
    80005984:	00000097          	auipc	ra,0x0
    80005988:	972080e7          	jalr	-1678(ra) # 800052f6 <create>
    8000598c:	892a                	mv	s2,a0
    if(ip == 0){
    8000598e:	c959                	beqz	a0,80005a24 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005990:	04491703          	lh	a4,68(s2)
    80005994:	478d                	li	a5,3
    80005996:	00f71763          	bne	a4,a5,800059a4 <sys_open+0x74>
    8000599a:	04695703          	lhu	a4,70(s2)
    8000599e:	47a5                	li	a5,9
    800059a0:	0ce7ec63          	bltu	a5,a4,80005a78 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	e02080e7          	jalr	-510(ra) # 800047a6 <filealloc>
    800059ac:	89aa                	mv	s3,a0
    800059ae:	10050263          	beqz	a0,80005ab2 <sys_open+0x182>
    800059b2:	00000097          	auipc	ra,0x0
    800059b6:	902080e7          	jalr	-1790(ra) # 800052b4 <fdalloc>
    800059ba:	84aa                	mv	s1,a0
    800059bc:	0e054663          	bltz	a0,80005aa8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059c0:	04491703          	lh	a4,68(s2)
    800059c4:	478d                	li	a5,3
    800059c6:	0cf70463          	beq	a4,a5,80005a8e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059ca:	4789                	li	a5,2
    800059cc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059d0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059d4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059d8:	f4c42783          	lw	a5,-180(s0)
    800059dc:	0017c713          	xori	a4,a5,1
    800059e0:	8b05                	andi	a4,a4,1
    800059e2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059e6:	0037f713          	andi	a4,a5,3
    800059ea:	00e03733          	snez	a4,a4
    800059ee:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059f2:	4007f793          	andi	a5,a5,1024
    800059f6:	c791                	beqz	a5,80005a02 <sys_open+0xd2>
    800059f8:	04491703          	lh	a4,68(s2)
    800059fc:	4789                	li	a5,2
    800059fe:	08f70f63          	beq	a4,a5,80005a9c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a02:	854a                	mv	a0,s2
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	082080e7          	jalr	130(ra) # 80003a86 <iunlock>
  end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	a0a080e7          	jalr	-1526(ra) # 80004416 <end_op>

  return fd;
}
    80005a14:	8526                	mv	a0,s1
    80005a16:	70ea                	ld	ra,184(sp)
    80005a18:	744a                	ld	s0,176(sp)
    80005a1a:	74aa                	ld	s1,168(sp)
    80005a1c:	790a                	ld	s2,160(sp)
    80005a1e:	69ea                	ld	s3,152(sp)
    80005a20:	6129                	addi	sp,sp,192
    80005a22:	8082                	ret
      end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	9f2080e7          	jalr	-1550(ra) # 80004416 <end_op>
      return -1;
    80005a2c:	b7e5                	j	80005a14 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a2e:	f5040513          	addi	a0,s0,-176
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	748080e7          	jalr	1864(ra) # 8000417a <namei>
    80005a3a:	892a                	mv	s2,a0
    80005a3c:	c905                	beqz	a0,80005a6c <sys_open+0x13c>
    ilock(ip);
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	f86080e7          	jalr	-122(ra) # 800039c4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a46:	04491703          	lh	a4,68(s2)
    80005a4a:	4785                	li	a5,1
    80005a4c:	f4f712e3          	bne	a4,a5,80005990 <sys_open+0x60>
    80005a50:	f4c42783          	lw	a5,-180(s0)
    80005a54:	dba1                	beqz	a5,800059a4 <sys_open+0x74>
      iunlockput(ip);
    80005a56:	854a                	mv	a0,s2
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	1ce080e7          	jalr	462(ra) # 80003c26 <iunlockput>
      end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	9b6080e7          	jalr	-1610(ra) # 80004416 <end_op>
      return -1;
    80005a68:	54fd                	li	s1,-1
    80005a6a:	b76d                	j	80005a14 <sys_open+0xe4>
      end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	9aa080e7          	jalr	-1622(ra) # 80004416 <end_op>
      return -1;
    80005a74:	54fd                	li	s1,-1
    80005a76:	bf79                	j	80005a14 <sys_open+0xe4>
    iunlockput(ip);
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	1ac080e7          	jalr	428(ra) # 80003c26 <iunlockput>
    end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	994080e7          	jalr	-1644(ra) # 80004416 <end_op>
    return -1;
    80005a8a:	54fd                	li	s1,-1
    80005a8c:	b761                	j	80005a14 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a8e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a92:	04691783          	lh	a5,70(s2)
    80005a96:	02f99223          	sh	a5,36(s3)
    80005a9a:	bf2d                	j	800059d4 <sys_open+0xa4>
    itrunc(ip);
    80005a9c:	854a                	mv	a0,s2
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	034080e7          	jalr	52(ra) # 80003ad2 <itrunc>
    80005aa6:	bfb1                	j	80005a02 <sys_open+0xd2>
      fileclose(f);
    80005aa8:	854e                	mv	a0,s3
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	db8080e7          	jalr	-584(ra) # 80004862 <fileclose>
    iunlockput(ip);
    80005ab2:	854a                	mv	a0,s2
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	172080e7          	jalr	370(ra) # 80003c26 <iunlockput>
    end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	95a080e7          	jalr	-1702(ra) # 80004416 <end_op>
    return -1;
    80005ac4:	54fd                	li	s1,-1
    80005ac6:	b7b9                	j	80005a14 <sys_open+0xe4>

0000000080005ac8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ac8:	7175                	addi	sp,sp,-144
    80005aca:	e506                	sd	ra,136(sp)
    80005acc:	e122                	sd	s0,128(sp)
    80005ace:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	8c6080e7          	jalr	-1850(ra) # 80004396 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ad8:	08000613          	li	a2,128
    80005adc:	f7040593          	addi	a1,s0,-144
    80005ae0:	4501                	li	a0,0
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	1b6080e7          	jalr	438(ra) # 80002c98 <argstr>
    80005aea:	02054963          	bltz	a0,80005b1c <sys_mkdir+0x54>
    80005aee:	4681                	li	a3,0
    80005af0:	4601                	li	a2,0
    80005af2:	4585                	li	a1,1
    80005af4:	f7040513          	addi	a0,s0,-144
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	7fe080e7          	jalr	2046(ra) # 800052f6 <create>
    80005b00:	cd11                	beqz	a0,80005b1c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	124080e7          	jalr	292(ra) # 80003c26 <iunlockput>
  end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	90c080e7          	jalr	-1780(ra) # 80004416 <end_op>
  return 0;
    80005b12:	4501                	li	a0,0
}
    80005b14:	60aa                	ld	ra,136(sp)
    80005b16:	640a                	ld	s0,128(sp)
    80005b18:	6149                	addi	sp,sp,144
    80005b1a:	8082                	ret
    end_op();
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	8fa080e7          	jalr	-1798(ra) # 80004416 <end_op>
    return -1;
    80005b24:	557d                	li	a0,-1
    80005b26:	b7fd                	j	80005b14 <sys_mkdir+0x4c>

0000000080005b28 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b28:	7135                	addi	sp,sp,-160
    80005b2a:	ed06                	sd	ra,152(sp)
    80005b2c:	e922                	sd	s0,144(sp)
    80005b2e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	866080e7          	jalr	-1946(ra) # 80004396 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b38:	08000613          	li	a2,128
    80005b3c:	f7040593          	addi	a1,s0,-144
    80005b40:	4501                	li	a0,0
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	156080e7          	jalr	342(ra) # 80002c98 <argstr>
    80005b4a:	04054a63          	bltz	a0,80005b9e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b4e:	f6c40593          	addi	a1,s0,-148
    80005b52:	4505                	li	a0,1
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	100080e7          	jalr	256(ra) # 80002c54 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b5c:	04054163          	bltz	a0,80005b9e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b60:	f6840593          	addi	a1,s0,-152
    80005b64:	4509                	li	a0,2
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	0ee080e7          	jalr	238(ra) # 80002c54 <argint>
     argint(1, &major) < 0 ||
    80005b6e:	02054863          	bltz	a0,80005b9e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b72:	f6841683          	lh	a3,-152(s0)
    80005b76:	f6c41603          	lh	a2,-148(s0)
    80005b7a:	458d                	li	a1,3
    80005b7c:	f7040513          	addi	a0,s0,-144
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	776080e7          	jalr	1910(ra) # 800052f6 <create>
     argint(2, &minor) < 0 ||
    80005b88:	c919                	beqz	a0,80005b9e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	09c080e7          	jalr	156(ra) # 80003c26 <iunlockput>
  end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	884080e7          	jalr	-1916(ra) # 80004416 <end_op>
  return 0;
    80005b9a:	4501                	li	a0,0
    80005b9c:	a031                	j	80005ba8 <sys_mknod+0x80>
    end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	878080e7          	jalr	-1928(ra) # 80004416 <end_op>
    return -1;
    80005ba6:	557d                	li	a0,-1
}
    80005ba8:	60ea                	ld	ra,152(sp)
    80005baa:	644a                	ld	s0,144(sp)
    80005bac:	610d                	addi	sp,sp,160
    80005bae:	8082                	ret

0000000080005bb0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bb0:	7135                	addi	sp,sp,-160
    80005bb2:	ed06                	sd	ra,152(sp)
    80005bb4:	e922                	sd	s0,144(sp)
    80005bb6:	e526                	sd	s1,136(sp)
    80005bb8:	e14a                	sd	s2,128(sp)
    80005bba:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bbc:	ffffc097          	auipc	ra,0xffffc
    80005bc0:	df4080e7          	jalr	-524(ra) # 800019b0 <myproc>
    80005bc4:	892a                	mv	s2,a0
  
  begin_op();
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	7d0080e7          	jalr	2000(ra) # 80004396 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bce:	08000613          	li	a2,128
    80005bd2:	f6040593          	addi	a1,s0,-160
    80005bd6:	4501                	li	a0,0
    80005bd8:	ffffd097          	auipc	ra,0xffffd
    80005bdc:	0c0080e7          	jalr	192(ra) # 80002c98 <argstr>
    80005be0:	04054b63          	bltz	a0,80005c36 <sys_chdir+0x86>
    80005be4:	f6040513          	addi	a0,s0,-160
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	592080e7          	jalr	1426(ra) # 8000417a <namei>
    80005bf0:	84aa                	mv	s1,a0
    80005bf2:	c131                	beqz	a0,80005c36 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	dd0080e7          	jalr	-560(ra) # 800039c4 <ilock>
  if(ip->type != T_DIR){
    80005bfc:	04449703          	lh	a4,68(s1)
    80005c00:	4785                	li	a5,1
    80005c02:	04f71063          	bne	a4,a5,80005c42 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	e7e080e7          	jalr	-386(ra) # 80003a86 <iunlock>
  iput(p->cwd);
    80005c10:	15093503          	ld	a0,336(s2)
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	f6a080e7          	jalr	-150(ra) # 80003b7e <iput>
  end_op();
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	7fa080e7          	jalr	2042(ra) # 80004416 <end_op>
  p->cwd = ip;
    80005c24:	14993823          	sd	s1,336(s2)
  return 0;
    80005c28:	4501                	li	a0,0
}
    80005c2a:	60ea                	ld	ra,152(sp)
    80005c2c:	644a                	ld	s0,144(sp)
    80005c2e:	64aa                	ld	s1,136(sp)
    80005c30:	690a                	ld	s2,128(sp)
    80005c32:	610d                	addi	sp,sp,160
    80005c34:	8082                	ret
    end_op();
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	7e0080e7          	jalr	2016(ra) # 80004416 <end_op>
    return -1;
    80005c3e:	557d                	li	a0,-1
    80005c40:	b7ed                	j	80005c2a <sys_chdir+0x7a>
    iunlockput(ip);
    80005c42:	8526                	mv	a0,s1
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	fe2080e7          	jalr	-30(ra) # 80003c26 <iunlockput>
    end_op();
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	7ca080e7          	jalr	1994(ra) # 80004416 <end_op>
    return -1;
    80005c54:	557d                	li	a0,-1
    80005c56:	bfd1                	j	80005c2a <sys_chdir+0x7a>

0000000080005c58 <sys_exec>:

uint64
sys_exec(void)
{
    80005c58:	7145                	addi	sp,sp,-464
    80005c5a:	e786                	sd	ra,456(sp)
    80005c5c:	e3a2                	sd	s0,448(sp)
    80005c5e:	ff26                	sd	s1,440(sp)
    80005c60:	fb4a                	sd	s2,432(sp)
    80005c62:	f74e                	sd	s3,424(sp)
    80005c64:	f352                	sd	s4,416(sp)
    80005c66:	ef56                	sd	s5,408(sp)
    80005c68:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c6a:	08000613          	li	a2,128
    80005c6e:	f4040593          	addi	a1,s0,-192
    80005c72:	4501                	li	a0,0
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	024080e7          	jalr	36(ra) # 80002c98 <argstr>
    return -1;
    80005c7c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c7e:	0c054a63          	bltz	a0,80005d52 <sys_exec+0xfa>
    80005c82:	e3840593          	addi	a1,s0,-456
    80005c86:	4505                	li	a0,1
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	fee080e7          	jalr	-18(ra) # 80002c76 <argaddr>
    80005c90:	0c054163          	bltz	a0,80005d52 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c94:	10000613          	li	a2,256
    80005c98:	4581                	li	a1,0
    80005c9a:	e4040513          	addi	a0,s0,-448
    80005c9e:	ffffb097          	auipc	ra,0xffffb
    80005ca2:	042080e7          	jalr	66(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ca6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005caa:	89a6                	mv	s3,s1
    80005cac:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cae:	02000a13          	li	s4,32
    80005cb2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cb6:	00391513          	slli	a0,s2,0x3
    80005cba:	e3040593          	addi	a1,s0,-464
    80005cbe:	e3843783          	ld	a5,-456(s0)
    80005cc2:	953e                	add	a0,a0,a5
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	ef6080e7          	jalr	-266(ra) # 80002bba <fetchaddr>
    80005ccc:	02054a63          	bltz	a0,80005d00 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cd0:	e3043783          	ld	a5,-464(s0)
    80005cd4:	c3b9                	beqz	a5,80005d1a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cd6:	ffffb097          	auipc	ra,0xffffb
    80005cda:	e1e080e7          	jalr	-482(ra) # 80000af4 <kalloc>
    80005cde:	85aa                	mv	a1,a0
    80005ce0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ce4:	cd11                	beqz	a0,80005d00 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ce6:	6605                	lui	a2,0x1
    80005ce8:	e3043503          	ld	a0,-464(s0)
    80005cec:	ffffd097          	auipc	ra,0xffffd
    80005cf0:	f20080e7          	jalr	-224(ra) # 80002c0c <fetchstr>
    80005cf4:	00054663          	bltz	a0,80005d00 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cf8:	0905                	addi	s2,s2,1
    80005cfa:	09a1                	addi	s3,s3,8
    80005cfc:	fb491be3          	bne	s2,s4,80005cb2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d00:	10048913          	addi	s2,s1,256
    80005d04:	6088                	ld	a0,0(s1)
    80005d06:	c529                	beqz	a0,80005d50 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d08:	ffffb097          	auipc	ra,0xffffb
    80005d0c:	cf0080e7          	jalr	-784(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d10:	04a1                	addi	s1,s1,8
    80005d12:	ff2499e3          	bne	s1,s2,80005d04 <sys_exec+0xac>
  return -1;
    80005d16:	597d                	li	s2,-1
    80005d18:	a82d                	j	80005d52 <sys_exec+0xfa>
      argv[i] = 0;
    80005d1a:	0a8e                	slli	s5,s5,0x3
    80005d1c:	fc040793          	addi	a5,s0,-64
    80005d20:	9abe                	add	s5,s5,a5
    80005d22:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d26:	e4040593          	addi	a1,s0,-448
    80005d2a:	f4040513          	addi	a0,s0,-192
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	194080e7          	jalr	404(ra) # 80004ec2 <exec>
    80005d36:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d38:	10048993          	addi	s3,s1,256
    80005d3c:	6088                	ld	a0,0(s1)
    80005d3e:	c911                	beqz	a0,80005d52 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	cb8080e7          	jalr	-840(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d48:	04a1                	addi	s1,s1,8
    80005d4a:	ff3499e3          	bne	s1,s3,80005d3c <sys_exec+0xe4>
    80005d4e:	a011                	j	80005d52 <sys_exec+0xfa>
  return -1;
    80005d50:	597d                	li	s2,-1
}
    80005d52:	854a                	mv	a0,s2
    80005d54:	60be                	ld	ra,456(sp)
    80005d56:	641e                	ld	s0,448(sp)
    80005d58:	74fa                	ld	s1,440(sp)
    80005d5a:	795a                	ld	s2,432(sp)
    80005d5c:	79ba                	ld	s3,424(sp)
    80005d5e:	7a1a                	ld	s4,416(sp)
    80005d60:	6afa                	ld	s5,408(sp)
    80005d62:	6179                	addi	sp,sp,464
    80005d64:	8082                	ret

0000000080005d66 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d66:	7139                	addi	sp,sp,-64
    80005d68:	fc06                	sd	ra,56(sp)
    80005d6a:	f822                	sd	s0,48(sp)
    80005d6c:	f426                	sd	s1,40(sp)
    80005d6e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	c40080e7          	jalr	-960(ra) # 800019b0 <myproc>
    80005d78:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d7a:	fd840593          	addi	a1,s0,-40
    80005d7e:	4501                	li	a0,0
    80005d80:	ffffd097          	auipc	ra,0xffffd
    80005d84:	ef6080e7          	jalr	-266(ra) # 80002c76 <argaddr>
    return -1;
    80005d88:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d8a:	0e054063          	bltz	a0,80005e6a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d8e:	fc840593          	addi	a1,s0,-56
    80005d92:	fd040513          	addi	a0,s0,-48
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	dfc080e7          	jalr	-516(ra) # 80004b92 <pipealloc>
    return -1;
    80005d9e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005da0:	0c054563          	bltz	a0,80005e6a <sys_pipe+0x104>
  fd0 = -1;
    80005da4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005da8:	fd043503          	ld	a0,-48(s0)
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	508080e7          	jalr	1288(ra) # 800052b4 <fdalloc>
    80005db4:	fca42223          	sw	a0,-60(s0)
    80005db8:	08054c63          	bltz	a0,80005e50 <sys_pipe+0xea>
    80005dbc:	fc843503          	ld	a0,-56(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	4f4080e7          	jalr	1268(ra) # 800052b4 <fdalloc>
    80005dc8:	fca42023          	sw	a0,-64(s0)
    80005dcc:	06054863          	bltz	a0,80005e3c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dd0:	4691                	li	a3,4
    80005dd2:	fc440613          	addi	a2,s0,-60
    80005dd6:	fd843583          	ld	a1,-40(s0)
    80005dda:	68a8                	ld	a0,80(s1)
    80005ddc:	ffffc097          	auipc	ra,0xffffc
    80005de0:	896080e7          	jalr	-1898(ra) # 80001672 <copyout>
    80005de4:	02054063          	bltz	a0,80005e04 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005de8:	4691                	li	a3,4
    80005dea:	fc040613          	addi	a2,s0,-64
    80005dee:	fd843583          	ld	a1,-40(s0)
    80005df2:	0591                	addi	a1,a1,4
    80005df4:	68a8                	ld	a0,80(s1)
    80005df6:	ffffc097          	auipc	ra,0xffffc
    80005dfa:	87c080e7          	jalr	-1924(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dfe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e00:	06055563          	bgez	a0,80005e6a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e04:	fc442783          	lw	a5,-60(s0)
    80005e08:	07e9                	addi	a5,a5,26
    80005e0a:	078e                	slli	a5,a5,0x3
    80005e0c:	97a6                	add	a5,a5,s1
    80005e0e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e12:	fc042503          	lw	a0,-64(s0)
    80005e16:	0569                	addi	a0,a0,26
    80005e18:	050e                	slli	a0,a0,0x3
    80005e1a:	9526                	add	a0,a0,s1
    80005e1c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e20:	fd043503          	ld	a0,-48(s0)
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	a3e080e7          	jalr	-1474(ra) # 80004862 <fileclose>
    fileclose(wf);
    80005e2c:	fc843503          	ld	a0,-56(s0)
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	a32080e7          	jalr	-1486(ra) # 80004862 <fileclose>
    return -1;
    80005e38:	57fd                	li	a5,-1
    80005e3a:	a805                	j	80005e6a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e3c:	fc442783          	lw	a5,-60(s0)
    80005e40:	0007c863          	bltz	a5,80005e50 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e44:	01a78513          	addi	a0,a5,26
    80005e48:	050e                	slli	a0,a0,0x3
    80005e4a:	9526                	add	a0,a0,s1
    80005e4c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e50:	fd043503          	ld	a0,-48(s0)
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	a0e080e7          	jalr	-1522(ra) # 80004862 <fileclose>
    fileclose(wf);
    80005e5c:	fc843503          	ld	a0,-56(s0)
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	a02080e7          	jalr	-1534(ra) # 80004862 <fileclose>
    return -1;
    80005e68:	57fd                	li	a5,-1
}
    80005e6a:	853e                	mv	a0,a5
    80005e6c:	70e2                	ld	ra,56(sp)
    80005e6e:	7442                	ld	s0,48(sp)
    80005e70:	74a2                	ld	s1,40(sp)
    80005e72:	6121                	addi	sp,sp,64
    80005e74:	8082                	ret
	...

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
    80005ec0:	bf1fc0ef          	jal	ra,80002ab0 <kerneltrap>
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
    80006046:	3ba080e7          	jalr	954(ra) # 800023fc <wakeup>
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
    80006286:	ea2080e7          	jalr	-350(ra) # 80002124 <sleep>
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
    800063d0:	d58080e7          	jalr	-680(ra) # 80002124 <sleep>
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
    8000650e:	ef2080e7          	jalr	-270(ra) # 800023fc <wakeup>

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
