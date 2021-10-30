
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
    80000068:	fac78793          	addi	a5,a5,-84 # 80006010 <timervec>
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
    80000130:	648080e7          	jalr	1608(ra) # 80002774 <either_copyin>
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
    800001d8:	02e080e7          	jalr	46(ra) # 80002202 <sleep>
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
    80000214:	50e080e7          	jalr	1294(ra) # 8000271e <either_copyout>
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
    800002f6:	4d8080e7          	jalr	1240(ra) # 800027ca <procdump>
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
    8000044a:	094080e7          	jalr	148(ra) # 800024da <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	8a078793          	addi	a5,a5,-1888 # 80021d18 <devsw>
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
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1753+0x160>
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
    800008a4:	c3a080e7          	jalr	-966(ra) # 800024da <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	8d6080e7          	jalr	-1834(ra) # 80002202 <sleep>
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
    80000ed8:	a58080e7          	jalr	-1448(ra) # 8000292c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	174080e7          	jalr	372(ra) # 80006050 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	070080e7          	jalr	112(ra) # 80001f54 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1753+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1753+0x160>
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
    80000f50:	9b8080e7          	jalr	-1608(ra) # 80002904 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9d8080e7          	jalr	-1576(ra) # 8000292c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	0de080e7          	jalr	222(ra) # 8000603a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	0ec080e7          	jalr	236(ra) # 80006050 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	2c6080e7          	jalr	710(ra) # 80003232 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	956080e7          	jalr	-1706(ra) # 800038ca <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	900080e7          	jalr	-1792(ra) # 8000487c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	1ee080e7          	jalr	494(ra) # 80006172 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d26080e7          	jalr	-730(ra) # 80001cb2 <userinit>
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
    80001872:	262a0a13          	addi	s4,s4,610 # 80017ad0 <tickslock>
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
    800018a8:	19048493          	addi	s1,s1,400
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
    8000193e:	19698993          	addi	s3,s3,406 # 80017ad0 <tickslock>
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
    80001968:	19048493          	addi	s1,s1,400
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
    80001a04:	ef07a783          	lw	a5,-272(a5) # 800088f0 <first.1716>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	f3a080e7          	jalr	-198(ra) # 80002944 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ec07ab23          	sw	zero,-298(a5) # 800088f0 <first.1716>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	e26080e7          	jalr	-474(ra) # 8000384a <fsinit>
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
    80001bd2:	f0290913          	addi	s2,s2,-254 # 80017ad0 <tickslock>
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
    80001bee:	19048493          	addi	s1,s1,400
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a8b5                	j	80001c74 <allocproc+0xba>
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
    80001c14:	c53d                	beqz	a0,80001c82 <allocproc+0xc8>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c93d                	beqz	a0,80001c9a <allocproc+0xe0>
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
  p->static_priority = 60;
    80001c5e:	03c00793          	li	a5,60
    80001c62:	16f4ac23          	sw	a5,376(s1)
  p->num_run = 0;
    80001c66:	1604ae23          	sw	zero,380(s1)
  p->run_last = 0;
    80001c6a:	1804a423          	sw	zero,392(s1)
  p->new_proc = 1;
    80001c6e:	4785                	li	a5,1
    80001c70:	18f4a623          	sw	a5,396(s1)
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    freeproc(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	ede080e7          	jalr	-290(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	00a080e7          	jalr	10(ra) # 80000c98 <release>
    return 0;
    80001c96:	84ca                	mv	s1,s2
    80001c98:	bff1                	j	80001c74 <allocproc+0xba>
    freeproc(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	ec6080e7          	jalr	-314(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	ff2080e7          	jalr	-14(ra) # 80000c98 <release>
    return 0;
    80001cae:	84ca                	mv	s1,s2
    80001cb0:	b7d1                	j	80001c74 <allocproc+0xba>

0000000080001cb2 <userinit>:
{
    80001cb2:	1101                	addi	sp,sp,-32
    80001cb4:	ec06                	sd	ra,24(sp)
    80001cb6:	e822                	sd	s0,16(sp)
    80001cb8:	e426                	sd	s1,8(sp)
    80001cba:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	efe080e7          	jalr	-258(ra) # 80001bba <allocproc>
    80001cc4:	84aa                	mv	s1,a0
  initproc = p;
    80001cc6:	00007797          	auipc	a5,0x7
    80001cca:	36a7b123          	sd	a0,866(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cce:	03400613          	li	a2,52
    80001cd2:	00007597          	auipc	a1,0x7
    80001cd6:	c2e58593          	addi	a1,a1,-978 # 80008900 <initcode>
    80001cda:	6928                	ld	a0,80(a0)
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	68c080e7          	jalr	1676(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001ce4:	6785                	lui	a5,0x1
    80001ce6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce8:	6cb8                	ld	a4,88(s1)
    80001cea:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cee:	6cb8                	ld	a4,88(s1)
    80001cf0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf2:	4641                	li	a2,16
    80001cf4:	00006597          	auipc	a1,0x6
    80001cf8:	50c58593          	addi	a1,a1,1292 # 80008200 <digits+0x1c0>
    80001cfc:	15848513          	addi	a0,s1,344
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	132080e7          	jalr	306(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d08:	00006517          	auipc	a0,0x6
    80001d0c:	50850513          	addi	a0,a0,1288 # 80008210 <digits+0x1d0>
    80001d10:	00002097          	auipc	ra,0x2
    80001d14:	568080e7          	jalr	1384(ra) # 80004278 <namei>
    80001d18:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1c:	478d                	li	a5,3
    80001d1e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f76080e7          	jalr	-138(ra) # 80000c98 <release>
}
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <growproc>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	e04a                	sd	s2,0(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	c6e080e7          	jalr	-914(ra) # 800019b0 <myproc>
    80001d4a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d4c:	652c                	ld	a1,72(a0)
    80001d4e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d52:	00904f63          	bgtz	s1,80001d70 <growproc+0x3c>
  } else if(n < 0){
    80001d56:	0204cc63          	bltz	s1,80001d8e <growproc+0x5a>
  p->sz = sz;
    80001d5a:	1602                	slli	a2,a2,0x20
    80001d5c:	9201                	srli	a2,a2,0x20
    80001d5e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d62:	4501                	li	a0,0
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6902                	ld	s2,0(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d70:	9e25                	addw	a2,a2,s1
    80001d72:	1602                	slli	a2,a2,0x20
    80001d74:	9201                	srli	a2,a2,0x20
    80001d76:	1582                	slli	a1,a1,0x20
    80001d78:	9181                	srli	a1,a1,0x20
    80001d7a:	6928                	ld	a0,80(a0)
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	6a6080e7          	jalr	1702(ra) # 80001422 <uvmalloc>
    80001d84:	0005061b          	sext.w	a2,a0
    80001d88:	fa69                	bnez	a2,80001d5a <growproc+0x26>
      return -1;
    80001d8a:	557d                	li	a0,-1
    80001d8c:	bfe1                	j	80001d64 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8e:	9e25                	addw	a2,a2,s1
    80001d90:	1602                	slli	a2,a2,0x20
    80001d92:	9201                	srli	a2,a2,0x20
    80001d94:	1582                	slli	a1,a1,0x20
    80001d96:	9181                	srli	a1,a1,0x20
    80001d98:	6928                	ld	a0,80(a0)
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	640080e7          	jalr	1600(ra) # 800013da <uvmdealloc>
    80001da2:	0005061b          	sext.w	a2,a0
    80001da6:	bf55                	j	80001d5a <growproc+0x26>

0000000080001da8 <fork>:
{
    80001da8:	7179                	addi	sp,sp,-48
    80001daa:	f406                	sd	ra,40(sp)
    80001dac:	f022                	sd	s0,32(sp)
    80001dae:	ec26                	sd	s1,24(sp)
    80001db0:	e84a                	sd	s2,16(sp)
    80001db2:	e44e                	sd	s3,8(sp)
    80001db4:	e052                	sd	s4,0(sp)
    80001db6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	bf8080e7          	jalr	-1032(ra) # 800019b0 <myproc>
    80001dc0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	df8080e7          	jalr	-520(ra) # 80001bba <allocproc>
    80001dca:	10050f63          	beqz	a0,80001ee8 <fork+0x140>
    80001dce:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd0:	04893603          	ld	a2,72(s2)
    80001dd4:	692c                	ld	a1,80(a0)
    80001dd6:	05093503          	ld	a0,80(s2)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	794080e7          	jalr	1940(ra) # 8000156e <uvmcopy>
    80001de2:	04054a63          	bltz	a0,80001e36 <fork+0x8e>
  np->trace_mask = p->trace_mask;
    80001de6:	16892783          	lw	a5,360(s2)
    80001dea:	16f9a423          	sw	a5,360(s3)
  np->sz = p->sz;
    80001dee:	04893783          	ld	a5,72(s2)
    80001df2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df6:	05893683          	ld	a3,88(s2)
    80001dfa:	87b6                	mv	a5,a3
    80001dfc:	0589b703          	ld	a4,88(s3)
    80001e00:	12068693          	addi	a3,a3,288
    80001e04:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e08:	6788                	ld	a0,8(a5)
    80001e0a:	6b8c                	ld	a1,16(a5)
    80001e0c:	6f90                	ld	a2,24(a5)
    80001e0e:	01073023          	sd	a6,0(a4)
    80001e12:	e708                	sd	a0,8(a4)
    80001e14:	eb0c                	sd	a1,16(a4)
    80001e16:	ef10                	sd	a2,24(a4)
    80001e18:	02078793          	addi	a5,a5,32
    80001e1c:	02070713          	addi	a4,a4,32
    80001e20:	fed792e3          	bne	a5,a3,80001e04 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e24:	0589b783          	ld	a5,88(s3)
    80001e28:	0607b823          	sd	zero,112(a5)
    80001e2c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e30:	15000a13          	li	s4,336
    80001e34:	a03d                	j	80001e62 <fork+0xba>
    freeproc(np);
    80001e36:	854e                	mv	a0,s3
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	d2a080e7          	jalr	-726(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e40:	854e                	mv	a0,s3
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>
    return -1;
    80001e4a:	5a7d                	li	s4,-1
    80001e4c:	a069                	j	80001ed6 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4e:	00003097          	auipc	ra,0x3
    80001e52:	ac0080e7          	jalr	-1344(ra) # 8000490e <filedup>
    80001e56:	009987b3          	add	a5,s3,s1
    80001e5a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e5c:	04a1                	addi	s1,s1,8
    80001e5e:	01448763          	beq	s1,s4,80001e6c <fork+0xc4>
    if(p->ofile[i])
    80001e62:	009907b3          	add	a5,s2,s1
    80001e66:	6388                	ld	a0,0(a5)
    80001e68:	f17d                	bnez	a0,80001e4e <fork+0xa6>
    80001e6a:	bfcd                	j	80001e5c <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e6c:	15093503          	ld	a0,336(s2)
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	c14080e7          	jalr	-1004(ra) # 80003a84 <idup>
    80001e78:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7c:	4641                	li	a2,16
    80001e7e:	15890593          	addi	a1,s2,344
    80001e82:	15898513          	addi	a0,s3,344
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	fac080e7          	jalr	-84(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e8e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e92:	854e                	mv	a0,s3
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e04080e7          	jalr	-508(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e9c:	0000f497          	auipc	s1,0xf
    80001ea0:	41c48493          	addi	s1,s1,1052 # 800112b8 <wait_lock>
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d3e080e7          	jalr	-706(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eae:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	de4080e7          	jalr	-540(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ebc:	854e                	mv	a0,s3
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d26080e7          	jalr	-730(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec6:	478d                	li	a5,3
    80001ec8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ecc:	854e                	mv	a0,s3
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dca080e7          	jalr	-566(ra) # 80000c98 <release>
}
    80001ed6:	8552                	mv	a0,s4
    80001ed8:	70a2                	ld	ra,40(sp)
    80001eda:	7402                	ld	s0,32(sp)
    80001edc:	64e2                	ld	s1,24(sp)
    80001ede:	6942                	ld	s2,16(sp)
    80001ee0:	69a2                	ld	s3,8(sp)
    80001ee2:	6a02                	ld	s4,0(sp)
    80001ee4:	6145                	addi	sp,sp,48
    80001ee6:	8082                	ret
    return -1;
    80001ee8:	5a7d                	li	s4,-1
    80001eea:	b7f5                	j	80001ed6 <fork+0x12e>

0000000080001eec <update_time>:
{
    80001eec:	7179                	addi	sp,sp,-48
    80001eee:	f406                	sd	ra,40(sp)
    80001ef0:	f022                	sd	s0,32(sp)
    80001ef2:	ec26                	sd	s1,24(sp)
    80001ef4:	e84a                	sd	s2,16(sp)
    80001ef6:	e44e                	sd	s3,8(sp)
    80001ef8:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	7d648493          	addi	s1,s1,2006 # 800116d0 <proc>
    if (p->state == RUNNING) {
    80001f02:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f04:	00016917          	auipc	s2,0x16
    80001f08:	bcc90913          	addi	s2,s2,-1076 # 80017ad0 <tickslock>
    80001f0c:	a811                	j	80001f20 <update_time+0x34>
    release(&p->lock); 
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	d88080e7          	jalr	-632(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f18:	19048493          	addi	s1,s1,400
    80001f1c:	03248563          	beq	s1,s2,80001f46 <update_time+0x5a>
    acquire(&p->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	cc2080e7          	jalr	-830(ra) # 80000be4 <acquire>
    if (p->state == RUNNING) {
    80001f2a:	4c9c                	lw	a5,24(s1)
    80001f2c:	ff3791e3          	bne	a5,s3,80001f0e <update_time+0x22>
      p->rtime++;
    80001f30:	16c4a783          	lw	a5,364(s1)
    80001f34:	2785                	addiw	a5,a5,1
    80001f36:	16f4a623          	sw	a5,364(s1)
      p->run_last++;
    80001f3a:	1884a783          	lw	a5,392(s1)
    80001f3e:	2785                	addiw	a5,a5,1
    80001f40:	18f4a423          	sw	a5,392(s1)
    80001f44:	b7e9                	j	80001f0e <update_time+0x22>
}
    80001f46:	70a2                	ld	ra,40(sp)
    80001f48:	7402                	ld	s0,32(sp)
    80001f4a:	64e2                	ld	s1,24(sp)
    80001f4c:	6942                	ld	s2,16(sp)
    80001f4e:	69a2                	ld	s3,8(sp)
    80001f50:	6145                	addi	sp,sp,48
    80001f52:	8082                	ret

0000000080001f54 <scheduler>:
{
    80001f54:	711d                	addi	sp,sp,-96
    80001f56:	ec86                	sd	ra,88(sp)
    80001f58:	e8a2                	sd	s0,80(sp)
    80001f5a:	e4a6                	sd	s1,72(sp)
    80001f5c:	e0ca                	sd	s2,64(sp)
    80001f5e:	fc4e                	sd	s3,56(sp)
    80001f60:	f852                	sd	s4,48(sp)
    80001f62:	f456                	sd	s5,40(sp)
    80001f64:	f05a                	sd	s6,32(sp)
    80001f66:	ec5e                	sd	s7,24(sp)
    80001f68:	e862                	sd	s8,16(sp)
    80001f6a:	e466                	sd	s9,8(sp)
    80001f6c:	1080                	addi	s0,sp,96
    80001f6e:	4981                	li	s3,0
    80001f70:	8792                	mv	a5,tp
  int id = r_tp();
    80001f72:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f74:	00779693          	slli	a3,a5,0x7
    80001f78:	0000f717          	auipc	a4,0xf
    80001f7c:	32870713          	addi	a4,a4,808 # 800112a0 <pid_lock>
    80001f80:	9736                	add	a4,a4,a3
    80001f82:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &minimum->context);
    80001f86:	0000f717          	auipc	a4,0xf
    80001f8a:	35270713          	addi	a4,a4,850 # 800112d8 <cpus+0x8>
    80001f8e:	00e68cb3          	add	s9,a3,a4
    int chosenFlag = 0;
    80001f92:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f94:	00016497          	auipc	s1,0x16
    80001f98:	b3c48493          	addi	s1,s1,-1220 # 80017ad0 <tickslock>
        chosenFlag = 1;
    80001f9c:	4a05                	li	s4,1
      minimum->sched_begin = ticks;
    80001f9e:	00007b97          	auipc	s7,0x7
    80001fa2:	092b8b93          	addi	s7,s7,146 # 80009030 <ticks>
      c->proc = minimum;
    80001fa6:	0000fb17          	auipc	s6,0xf
    80001faa:	2fab0b13          	addi	s6,s6,762 # 800112a0 <pid_lock>
    80001fae:	9b36                	add	s6,s6,a3
    80001fb0:	a87d                	j	8000206e <scheduler+0x11a>
          sleeptime = p->sched_end - p->sched_begin + p->run_last;
    80001fb2:	1887a683          	lw	a3,392(a5)
    80001fb6:	1847a703          	lw	a4,388(a5)
    80001fba:	1807a803          	lw	a6,384(a5)
    80001fbe:	4107073b          	subw	a4,a4,a6
    80001fc2:	9f35                	addw	a4,a4,a3
          niceness = (sleeptime/(p->run_last + sleeptime))*10;
    80001fc4:	9eb9                	addw	a3,a3,a4
    80001fc6:	02d7473b          	divw	a4,a4,a3
    80001fca:	0027169b          	slliw	a3,a4,0x2
    80001fce:	9f35                	addw	a4,a4,a3
    80001fd0:	0017169b          	slliw	a3,a4,0x1
          dp = p->static_priority - niceness + 5;
    80001fd4:	1787a703          	lw	a4,376(a5)
    80001fd8:	9f15                	subw	a4,a4,a3
    80001fda:	2715                	addiw	a4,a4,5
    80001fdc:	0007069b          	sext.w	a3,a4
    80001fe0:	fff6c693          	not	a3,a3
    80001fe4:	96fd                	srai	a3,a3,0x3f
    80001fe6:	8f75                	and	a4,a4,a3
    80001fe8:	0007069b          	sext.w	a3,a4
    80001fec:	00d5d363          	bge	a1,a3,80001ff2 <scheduler+0x9e>
    80001ff0:	872a                	mv	a4,a0
    80001ff2:	2701                	sext.w	a4,a4
    80001ff4:	a835                	j	80002030 <scheduler+0xdc>
          min_dp = dp;
    80001ff6:	89ba                	mv	s3,a4
    80001ff8:	893e                	mv	s2,a5
        chosenFlag = 1;
    80001ffa:	86d2                	mv	a3,s4
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ffc:	19078793          	addi	a5,a5,400
    80002000:	06978663          	beq	a5,s1,8000206c <scheduler+0x118>
      if(p->state == RUNNABLE)
    80002004:	4f98                	lw	a4,24(a5)
    80002006:	fec71be3          	bne	a4,a2,80001ffc <scheduler+0xa8>
        if(p->new_proc)
    8000200a:	18c7a703          	lw	a4,396(a5)
    8000200e:	d355                	beqz	a4,80001fb2 <scheduler+0x5e>
          p->new_proc = 0;
    80002010:	1807a623          	sw	zero,396(a5)
          if(dp > 100)
    80002014:	1787a703          	lw	a4,376(a5)
    80002018:	0007069b          	sext.w	a3,a4
    8000201c:	fff6c693          	not	a3,a3
    80002020:	96fd                	srai	a3,a3,0x3f
    80002022:	8f75                	and	a4,a4,a3
    80002024:	0007069b          	sext.w	a3,a4
    80002028:	00d5d363          	bge	a1,a3,8000202e <scheduler+0xda>
    8000202c:	872a                	mv	a4,a0
    8000202e:	2701                	sext.w	a4,a4
        if(minimum == 0)
    80002030:	fc0903e3          	beqz	s2,80001ff6 <scheduler+0xa2>
        chosenFlag = 1;
    80002034:	86d2                	mv	a3,s4
        else if(dp <= min_dp)
    80002036:	fce9c3e3          	blt	s3,a4,80001ffc <scheduler+0xa8>
          if(dp < min_dp)
    8000203a:	03374363          	blt	a4,s3,80002060 <scheduler+0x10c>
            if(p->num_run <= minimum->num_run)
    8000203e:	17c7a883          	lw	a7,380(a5)
    80002042:	17c92803          	lw	a6,380(s2)
    80002046:	fb184be3          	blt	a6,a7,80001ffc <scheduler+0xa8>
              if(p->num_run < minimum->num_run)
    8000204a:	0108ce63          	blt	a7,a6,80002066 <scheduler+0x112>
                if(p->ctime < minimum->ctime)
    8000204e:	1707a883          	lw	a7,368(a5)
    80002052:	17092803          	lw	a6,368(s2)
    80002056:	fb08f3e3          	bgeu	a7,a6,80001ffc <scheduler+0xa8>
                  min_dp = dp;
    8000205a:	89ba                	mv	s3,a4
                if(p->ctime < minimum->ctime)
    8000205c:	893e                	mv	s2,a5
    8000205e:	bf79                	j	80001ffc <scheduler+0xa8>
            min_dp = dp;
    80002060:	89ba                	mv	s3,a4
    80002062:	893e                	mv	s2,a5
    80002064:	bf61                	j	80001ffc <scheduler+0xa8>
                min_dp = dp;
    80002066:	89ba                	mv	s3,a4
    80002068:	893e                	mv	s2,a5
    8000206a:	bf49                	j	80001ffc <scheduler+0xa8>
    if(chosenFlag == 0)
    8000206c:	e29d                	bnez	a3,80002092 <scheduler+0x13e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002072:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002076:	10079073          	csrw	sstatus,a5
    int chosenFlag = 0;
    8000207a:	86d6                	mv	a3,s5
    struct proc *minimum = 0;
    8000207c:	8956                	mv	s2,s5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000207e:	0000f797          	auipc	a5,0xf
    80002082:	65278793          	addi	a5,a5,1618 # 800116d0 <proc>
      if(p->state == RUNNABLE)
    80002086:	460d                	li	a2,3
    80002088:	06400593          	li	a1,100
    8000208c:	06400513          	li	a0,100
    80002090:	bf95                	j	80002004 <scheduler+0xb0>
    acquire(&minimum->lock);
    80002092:	8c4a                	mv	s8,s2
    80002094:	854a                	mv	a0,s2
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b4e080e7          	jalr	-1202(ra) # 80000be4 <acquire>
    if(minimum->state == RUNNABLE)
    8000209e:	01892703          	lw	a4,24(s2)
    800020a2:	478d                	li	a5,3
    800020a4:	00f70863          	beq	a4,a5,800020b4 <scheduler+0x160>
    release(&minimum->lock);
    800020a8:	8562                	mv	a0,s8
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	bee080e7          	jalr	-1042(ra) # 80000c98 <release>
    800020b2:	bf75                	j	8000206e <scheduler+0x11a>
      minimum->sched_begin = ticks;
    800020b4:	000ba783          	lw	a5,0(s7)
    800020b8:	18f92023          	sw	a5,384(s2)
      minimum->num_run++;
    800020bc:	17c92783          	lw	a5,380(s2)
    800020c0:	2785                	addiw	a5,a5,1
    800020c2:	16f92e23          	sw	a5,380(s2)
      minimum->state = RUNNING;
    800020c6:	4791                	li	a5,4
    800020c8:	00f92c23          	sw	a5,24(s2)
      c->proc = minimum;
    800020cc:	032b3823          	sd	s2,48(s6)
      swtch(&c->context, &minimum->context);
    800020d0:	06090593          	addi	a1,s2,96
    800020d4:	8566                	mv	a0,s9
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	7c4080e7          	jalr	1988(ra) # 8000289a <swtch>
      c->proc = 0;
    800020de:	020b3823          	sd	zero,48(s6)
    800020e2:	b7d9                	j	800020a8 <scheduler+0x154>

00000000800020e4 <sched>:
{
    800020e4:	7179                	addi	sp,sp,-48
    800020e6:	f406                	sd	ra,40(sp)
    800020e8:	f022                	sd	s0,32(sp)
    800020ea:	ec26                	sd	s1,24(sp)
    800020ec:	e84a                	sd	s2,16(sp)
    800020ee:	e44e                	sd	s3,8(sp)
    800020f0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	8be080e7          	jalr	-1858(ra) # 800019b0 <myproc>
    800020fa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	a6e080e7          	jalr	-1426(ra) # 80000b6a <holding>
    80002104:	c93d                	beqz	a0,8000217a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002106:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002108:	2781                	sext.w	a5,a5
    8000210a:	079e                	slli	a5,a5,0x7
    8000210c:	0000f717          	auipc	a4,0xf
    80002110:	19470713          	addi	a4,a4,404 # 800112a0 <pid_lock>
    80002114:	97ba                	add	a5,a5,a4
    80002116:	0a87a703          	lw	a4,168(a5)
    8000211a:	4785                	li	a5,1
    8000211c:	06f71763          	bne	a4,a5,8000218a <sched+0xa6>
  if(p->state == RUNNING)
    80002120:	4c98                	lw	a4,24(s1)
    80002122:	4791                	li	a5,4
    80002124:	06f70b63          	beq	a4,a5,8000219a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002128:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000212c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000212e:	efb5                	bnez	a5,800021aa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002130:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002132:	0000f917          	auipc	s2,0xf
    80002136:	16e90913          	addi	s2,s2,366 # 800112a0 <pid_lock>
    8000213a:	2781                	sext.w	a5,a5
    8000213c:	079e                	slli	a5,a5,0x7
    8000213e:	97ca                	add	a5,a5,s2
    80002140:	0ac7a983          	lw	s3,172(a5)
    80002144:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002146:	2781                	sext.w	a5,a5
    80002148:	079e                	slli	a5,a5,0x7
    8000214a:	0000f597          	auipc	a1,0xf
    8000214e:	18e58593          	addi	a1,a1,398 # 800112d8 <cpus+0x8>
    80002152:	95be                	add	a1,a1,a5
    80002154:	06048513          	addi	a0,s1,96
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	742080e7          	jalr	1858(ra) # 8000289a <swtch>
    80002160:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002162:	2781                	sext.w	a5,a5
    80002164:	079e                	slli	a5,a5,0x7
    80002166:	97ca                	add	a5,a5,s2
    80002168:	0b37a623          	sw	s3,172(a5)
}
    8000216c:	70a2                	ld	ra,40(sp)
    8000216e:	7402                	ld	s0,32(sp)
    80002170:	64e2                	ld	s1,24(sp)
    80002172:	6942                	ld	s2,16(sp)
    80002174:	69a2                	ld	s3,8(sp)
    80002176:	6145                	addi	sp,sp,48
    80002178:	8082                	ret
    panic("sched p->lock");
    8000217a:	00006517          	auipc	a0,0x6
    8000217e:	09e50513          	addi	a0,a0,158 # 80008218 <digits+0x1d8>
    80002182:	ffffe097          	auipc	ra,0xffffe
    80002186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>
    panic("sched locks");
    8000218a:	00006517          	auipc	a0,0x6
    8000218e:	09e50513          	addi	a0,a0,158 # 80008228 <digits+0x1e8>
    80002192:	ffffe097          	auipc	ra,0xffffe
    80002196:	3ac080e7          	jalr	940(ra) # 8000053e <panic>
    panic("sched running");
    8000219a:	00006517          	auipc	a0,0x6
    8000219e:	09e50513          	addi	a0,a0,158 # 80008238 <digits+0x1f8>
    800021a2:	ffffe097          	auipc	ra,0xffffe
    800021a6:	39c080e7          	jalr	924(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021aa:	00006517          	auipc	a0,0x6
    800021ae:	09e50513          	addi	a0,a0,158 # 80008248 <digits+0x208>
    800021b2:	ffffe097          	auipc	ra,0xffffe
    800021b6:	38c080e7          	jalr	908(ra) # 8000053e <panic>

00000000800021ba <yield>:
{
    800021ba:	1101                	addi	sp,sp,-32
    800021bc:	ec06                	sd	ra,24(sp)
    800021be:	e822                	sd	s0,16(sp)
    800021c0:	e426                	sd	s1,8(sp)
    800021c2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800021cc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a16080e7          	jalr	-1514(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800021d6:	478d                	li	a5,3
    800021d8:	cc9c                	sw	a5,24(s1)
  p->sched_end = ticks;
    800021da:	00007797          	auipc	a5,0x7
    800021de:	e567a783          	lw	a5,-426(a5) # 80009030 <ticks>
    800021e2:	18f4a223          	sw	a5,388(s1)
  sched();
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	efe080e7          	jalr	-258(ra) # 800020e4 <sched>
  release(&p->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
}
    800021f8:	60e2                	ld	ra,24(sp)
    800021fa:	6442                	ld	s0,16(sp)
    800021fc:	64a2                	ld	s1,8(sp)
    800021fe:	6105                	addi	sp,sp,32
    80002200:	8082                	ret

0000000080002202 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002202:	7179                	addi	sp,sp,-48
    80002204:	f406                	sd	ra,40(sp)
    80002206:	f022                	sd	s0,32(sp)
    80002208:	ec26                	sd	s1,24(sp)
    8000220a:	e84a                	sd	s2,16(sp)
    8000220c:	e44e                	sd	s3,8(sp)
    8000220e:	1800                	addi	s0,sp,48
    80002210:	89aa                	mv	s3,a0
    80002212:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	79c080e7          	jalr	1948(ra) # 800019b0 <myproc>
    8000221c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
  release(lk);
    80002226:	854a                	mv	a0,s2
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a70080e7          	jalr	-1424(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002230:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002234:	4789                	li	a5,2
    80002236:	cc9c                	sw	a5,24(s1)

  sched();
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	eac080e7          	jalr	-340(ra) # 800020e4 <sched>

  // Tidy up.
  p->chan = 0;
    80002240:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a52080e7          	jalr	-1454(ra) # 80000c98 <release>
  acquire(lk);
    8000224e:	854a                	mv	a0,s2
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	994080e7          	jalr	-1644(ra) # 80000be4 <acquire>
}
    80002258:	70a2                	ld	ra,40(sp)
    8000225a:	7402                	ld	s0,32(sp)
    8000225c:	64e2                	ld	s1,24(sp)
    8000225e:	6942                	ld	s2,16(sp)
    80002260:	69a2                	ld	s3,8(sp)
    80002262:	6145                	addi	sp,sp,48
    80002264:	8082                	ret

0000000080002266 <wait>:
{
    80002266:	715d                	addi	sp,sp,-80
    80002268:	e486                	sd	ra,72(sp)
    8000226a:	e0a2                	sd	s0,64(sp)
    8000226c:	fc26                	sd	s1,56(sp)
    8000226e:	f84a                	sd	s2,48(sp)
    80002270:	f44e                	sd	s3,40(sp)
    80002272:	f052                	sd	s4,32(sp)
    80002274:	ec56                	sd	s5,24(sp)
    80002276:	e85a                	sd	s6,16(sp)
    80002278:	e45e                	sd	s7,8(sp)
    8000227a:	e062                	sd	s8,0(sp)
    8000227c:	0880                	addi	s0,sp,80
    8000227e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	730080e7          	jalr	1840(ra) # 800019b0 <myproc>
    80002288:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000228a:	0000f517          	auipc	a0,0xf
    8000228e:	02e50513          	addi	a0,a0,46 # 800112b8 <wait_lock>
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	952080e7          	jalr	-1710(ra) # 80000be4 <acquire>
    havekids = 0;
    8000229a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000229c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000229e:	00016997          	auipc	s3,0x16
    800022a2:	83298993          	addi	s3,s3,-1998 # 80017ad0 <tickslock>
        havekids = 1;
    800022a6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022a8:	0000fc17          	auipc	s8,0xf
    800022ac:	010c0c13          	addi	s8,s8,16 # 800112b8 <wait_lock>
    havekids = 0;
    800022b0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022b2:	0000f497          	auipc	s1,0xf
    800022b6:	41e48493          	addi	s1,s1,1054 # 800116d0 <proc>
    800022ba:	a0bd                	j	80002328 <wait+0xc2>
          pid = np->pid;
    800022bc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022c0:	000b0e63          	beqz	s6,800022dc <wait+0x76>
    800022c4:	4691                	li	a3,4
    800022c6:	02c48613          	addi	a2,s1,44
    800022ca:	85da                	mv	a1,s6
    800022cc:	05093503          	ld	a0,80(s2)
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	3a2080e7          	jalr	930(ra) # 80001672 <copyout>
    800022d8:	02054563          	bltz	a0,80002302 <wait+0x9c>
          freeproc(np);
    800022dc:	8526                	mv	a0,s1
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	884080e7          	jalr	-1916(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9b0080e7          	jalr	-1616(ra) # 80000c98 <release>
          release(&wait_lock);
    800022f0:	0000f517          	auipc	a0,0xf
    800022f4:	fc850513          	addi	a0,a0,-56 # 800112b8 <wait_lock>
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	9a0080e7          	jalr	-1632(ra) # 80000c98 <release>
          return pid;
    80002300:	a09d                	j	80002366 <wait+0x100>
            release(&np->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	994080e7          	jalr	-1644(ra) # 80000c98 <release>
            release(&wait_lock);
    8000230c:	0000f517          	auipc	a0,0xf
    80002310:	fac50513          	addi	a0,a0,-84 # 800112b8 <wait_lock>
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
            return -1;
    8000231c:	59fd                	li	s3,-1
    8000231e:	a0a1                	j	80002366 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002320:	19048493          	addi	s1,s1,400
    80002324:	03348463          	beq	s1,s3,8000234c <wait+0xe6>
      if(np->parent == p){
    80002328:	7c9c                	ld	a5,56(s1)
    8000232a:	ff279be3          	bne	a5,s2,80002320 <wait+0xba>
        acquire(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002338:	4c9c                	lw	a5,24(s1)
    8000233a:	f94781e3          	beq	a5,s4,800022bc <wait+0x56>
        release(&np->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
        havekids = 1;
    80002348:	8756                	mv	a4,s5
    8000234a:	bfd9                	j	80002320 <wait+0xba>
    if(!havekids || p->killed){
    8000234c:	c701                	beqz	a4,80002354 <wait+0xee>
    8000234e:	02892783          	lw	a5,40(s2)
    80002352:	c79d                	beqz	a5,80002380 <wait+0x11a>
      release(&wait_lock);
    80002354:	0000f517          	auipc	a0,0xf
    80002358:	f6450513          	addi	a0,a0,-156 # 800112b8 <wait_lock>
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	93c080e7          	jalr	-1732(ra) # 80000c98 <release>
      return -1;
    80002364:	59fd                	li	s3,-1
}
    80002366:	854e                	mv	a0,s3
    80002368:	60a6                	ld	ra,72(sp)
    8000236a:	6406                	ld	s0,64(sp)
    8000236c:	74e2                	ld	s1,56(sp)
    8000236e:	7942                	ld	s2,48(sp)
    80002370:	79a2                	ld	s3,40(sp)
    80002372:	7a02                	ld	s4,32(sp)
    80002374:	6ae2                	ld	s5,24(sp)
    80002376:	6b42                	ld	s6,16(sp)
    80002378:	6ba2                	ld	s7,8(sp)
    8000237a:	6c02                	ld	s8,0(sp)
    8000237c:	6161                	addi	sp,sp,80
    8000237e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002380:	85e2                	mv	a1,s8
    80002382:	854a                	mv	a0,s2
    80002384:	00000097          	auipc	ra,0x0
    80002388:	e7e080e7          	jalr	-386(ra) # 80002202 <sleep>
    havekids = 0;
    8000238c:	b715                	j	800022b0 <wait+0x4a>

000000008000238e <waitx>:
{
    8000238e:	711d                	addi	sp,sp,-96
    80002390:	ec86                	sd	ra,88(sp)
    80002392:	e8a2                	sd	s0,80(sp)
    80002394:	e4a6                	sd	s1,72(sp)
    80002396:	e0ca                	sd	s2,64(sp)
    80002398:	fc4e                	sd	s3,56(sp)
    8000239a:	f852                	sd	s4,48(sp)
    8000239c:	f456                	sd	s5,40(sp)
    8000239e:	f05a                	sd	s6,32(sp)
    800023a0:	ec5e                	sd	s7,24(sp)
    800023a2:	e862                	sd	s8,16(sp)
    800023a4:	e466                	sd	s9,8(sp)
    800023a6:	e06a                	sd	s10,0(sp)
    800023a8:	1080                	addi	s0,sp,96
    800023aa:	8b2a                	mv	s6,a0
    800023ac:	8c2e                	mv	s8,a1
    800023ae:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	600080e7          	jalr	1536(ra) # 800019b0 <myproc>
    800023b8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ba:	0000f517          	auipc	a0,0xf
    800023be:	efe50513          	addi	a0,a0,-258 # 800112b8 <wait_lock>
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
    havekids = 0;
    800023ca:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800023cc:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023ce:	00015997          	auipc	s3,0x15
    800023d2:	70298993          	addi	s3,s3,1794 # 80017ad0 <tickslock>
        havekids = 1;
    800023d6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023d8:	0000fd17          	auipc	s10,0xf
    800023dc:	ee0d0d13          	addi	s10,s10,-288 # 800112b8 <wait_lock>
    havekids = 0;
    800023e0:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800023e2:	0000f497          	auipc	s1,0xf
    800023e6:	2ee48493          	addi	s1,s1,750 # 800116d0 <proc>
    800023ea:	a059                	j	80002470 <waitx+0xe2>
          pid = np->pid;
    800023ec:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800023f0:	16c4a703          	lw	a4,364(s1)
    800023f4:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800023f8:	1704a783          	lw	a5,368(s1)
    800023fc:	9f3d                	addw	a4,a4,a5
    800023fe:	1744a783          	lw	a5,372(s1)
    80002402:	9f99                	subw	a5,a5,a4
    80002404:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002408:	000b0e63          	beqz	s6,80002424 <waitx+0x96>
    8000240c:	4691                	li	a3,4
    8000240e:	02c48613          	addi	a2,s1,44
    80002412:	85da                	mv	a1,s6
    80002414:	05093503          	ld	a0,80(s2)
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	25a080e7          	jalr	602(ra) # 80001672 <copyout>
    80002420:	02054563          	bltz	a0,8000244a <waitx+0xbc>
          freeproc(np);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	73c080e7          	jalr	1852(ra) # 80001b62 <freeproc>
          release(&np->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
          release(&wait_lock);
    80002438:	0000f517          	auipc	a0,0xf
    8000243c:	e8050513          	addi	a0,a0,-384 # 800112b8 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
          return pid;
    80002448:	a09d                	j	800024ae <waitx+0x120>
            release(&np->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
            release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	e6450513          	addi	a0,a0,-412 # 800112b8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	83c080e7          	jalr	-1988(ra) # 80000c98 <release>
            return -1;
    80002464:	59fd                	li	s3,-1
    80002466:	a0a1                	j	800024ae <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002468:	19048493          	addi	s1,s1,400
    8000246c:	03348463          	beq	s1,s3,80002494 <waitx+0x106>
      if(np->parent == p){
    80002470:	7c9c                	ld	a5,56(s1)
    80002472:	ff279be3          	bne	a5,s2,80002468 <waitx+0xda>
        acquire(&np->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	76c080e7          	jalr	1900(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	f74785e3          	beq	a5,s4,800023ec <waitx+0x5e>
        release(&np->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	810080e7          	jalr	-2032(ra) # 80000c98 <release>
        havekids = 1;
    80002490:	8756                	mv	a4,s5
    80002492:	bfd9                	j	80002468 <waitx+0xda>
    if(!havekids || p->killed){
    80002494:	c701                	beqz	a4,8000249c <waitx+0x10e>
    80002496:	02892783          	lw	a5,40(s2)
    8000249a:	cb8d                	beqz	a5,800024cc <waitx+0x13e>
      release(&wait_lock);
    8000249c:	0000f517          	auipc	a0,0xf
    800024a0:	e1c50513          	addi	a0,a0,-484 # 800112b8 <wait_lock>
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	7f4080e7          	jalr	2036(ra) # 80000c98 <release>
      return -1;
    800024ac:	59fd                	li	s3,-1
}
    800024ae:	854e                	mv	a0,s3
    800024b0:	60e6                	ld	ra,88(sp)
    800024b2:	6446                	ld	s0,80(sp)
    800024b4:	64a6                	ld	s1,72(sp)
    800024b6:	6906                	ld	s2,64(sp)
    800024b8:	79e2                	ld	s3,56(sp)
    800024ba:	7a42                	ld	s4,48(sp)
    800024bc:	7aa2                	ld	s5,40(sp)
    800024be:	7b02                	ld	s6,32(sp)
    800024c0:	6be2                	ld	s7,24(sp)
    800024c2:	6c42                	ld	s8,16(sp)
    800024c4:	6ca2                	ld	s9,8(sp)
    800024c6:	6d02                	ld	s10,0(sp)
    800024c8:	6125                	addi	sp,sp,96
    800024ca:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024cc:	85ea                	mv	a1,s10
    800024ce:	854a                	mv	a0,s2
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	d32080e7          	jalr	-718(ra) # 80002202 <sleep>
    havekids = 0;
    800024d8:	b721                	j	800023e0 <waitx+0x52>

00000000800024da <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800024da:	7139                	addi	sp,sp,-64
    800024dc:	fc06                	sd	ra,56(sp)
    800024de:	f822                	sd	s0,48(sp)
    800024e0:	f426                	sd	s1,40(sp)
    800024e2:	f04a                	sd	s2,32(sp)
    800024e4:	ec4e                	sd	s3,24(sp)
    800024e6:	e852                	sd	s4,16(sp)
    800024e8:	e456                	sd	s5,8(sp)
    800024ea:	e05a                	sd	s6,0(sp)
    800024ec:	0080                	addi	s0,sp,64
    800024ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024f0:	0000f497          	auipc	s1,0xf
    800024f4:	1e048493          	addi	s1,s1,480 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024f8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024fa:	4b0d                	li	s6,3
        #ifdef PBS
        p->sched_end = ticks;
    800024fc:	00007a97          	auipc	s5,0x7
    80002500:	b34a8a93          	addi	s5,s5,-1228 # 80009030 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002504:	00015917          	auipc	s2,0x15
    80002508:	5cc90913          	addi	s2,s2,1484 # 80017ad0 <tickslock>
    8000250c:	a005                	j	8000252c <wakeup+0x52>
        p->state = RUNNABLE;
    8000250e:	0164ac23          	sw	s6,24(s1)
        p->sched_end = ticks;
    80002512:	000aa783          	lw	a5,0(s5)
    80002516:	18f4a223          	sw	a5,388(s1)
        #endif
      }
      release(&p->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	77c080e7          	jalr	1916(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002524:	19048493          	addi	s1,s1,400
    80002528:	03248463          	beq	s1,s2,80002550 <wakeup+0x76>
    if(p != myproc()){
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	484080e7          	jalr	1156(ra) # 800019b0 <myproc>
    80002534:	fea488e3          	beq	s1,a0,80002524 <wakeup+0x4a>
      acquire(&p->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	6aa080e7          	jalr	1706(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002542:	4c9c                	lw	a5,24(s1)
    80002544:	fd379be3          	bne	a5,s3,8000251a <wakeup+0x40>
    80002548:	709c                	ld	a5,32(s1)
    8000254a:	fd4798e3          	bne	a5,s4,8000251a <wakeup+0x40>
    8000254e:	b7c1                	j	8000250e <wakeup+0x34>
    }
  }
}
    80002550:	70e2                	ld	ra,56(sp)
    80002552:	7442                	ld	s0,48(sp)
    80002554:	74a2                	ld	s1,40(sp)
    80002556:	7902                	ld	s2,32(sp)
    80002558:	69e2                	ld	s3,24(sp)
    8000255a:	6a42                	ld	s4,16(sp)
    8000255c:	6aa2                	ld	s5,8(sp)
    8000255e:	6b02                	ld	s6,0(sp)
    80002560:	6121                	addi	sp,sp,64
    80002562:	8082                	ret

0000000080002564 <reparent>:
{
    80002564:	7179                	addi	sp,sp,-48
    80002566:	f406                	sd	ra,40(sp)
    80002568:	f022                	sd	s0,32(sp)
    8000256a:	ec26                	sd	s1,24(sp)
    8000256c:	e84a                	sd	s2,16(sp)
    8000256e:	e44e                	sd	s3,8(sp)
    80002570:	e052                	sd	s4,0(sp)
    80002572:	1800                	addi	s0,sp,48
    80002574:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002576:	0000f497          	auipc	s1,0xf
    8000257a:	15a48493          	addi	s1,s1,346 # 800116d0 <proc>
      pp->parent = initproc;
    8000257e:	00007a17          	auipc	s4,0x7
    80002582:	aaaa0a13          	addi	s4,s4,-1366 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002586:	00015997          	auipc	s3,0x15
    8000258a:	54a98993          	addi	s3,s3,1354 # 80017ad0 <tickslock>
    8000258e:	a029                	j	80002598 <reparent+0x34>
    80002590:	19048493          	addi	s1,s1,400
    80002594:	01348d63          	beq	s1,s3,800025ae <reparent+0x4a>
    if(pp->parent == p){
    80002598:	7c9c                	ld	a5,56(s1)
    8000259a:	ff279be3          	bne	a5,s2,80002590 <reparent+0x2c>
      pp->parent = initproc;
    8000259e:	000a3503          	ld	a0,0(s4)
    800025a2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	f36080e7          	jalr	-202(ra) # 800024da <wakeup>
    800025ac:	b7d5                	j	80002590 <reparent+0x2c>
}
    800025ae:	70a2                	ld	ra,40(sp)
    800025b0:	7402                	ld	s0,32(sp)
    800025b2:	64e2                	ld	s1,24(sp)
    800025b4:	6942                	ld	s2,16(sp)
    800025b6:	69a2                	ld	s3,8(sp)
    800025b8:	6a02                	ld	s4,0(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret

00000000800025be <exit>:
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	3e0080e7          	jalr	992(ra) # 800019b0 <myproc>
    800025d8:	89aa                	mv	s3,a0
  if(p == initproc)
    800025da:	00007797          	auipc	a5,0x7
    800025de:	a4e7b783          	ld	a5,-1458(a5) # 80009028 <initproc>
    800025e2:	0d050493          	addi	s1,a0,208
    800025e6:	15050913          	addi	s2,a0,336
    800025ea:	02a79363          	bne	a5,a0,80002610 <exit+0x52>
    panic("init exiting");
    800025ee:	00006517          	auipc	a0,0x6
    800025f2:	c7250513          	addi	a0,a0,-910 # 80008260 <digits+0x220>
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      fileclose(f);
    800025fe:	00002097          	auipc	ra,0x2
    80002602:	362080e7          	jalr	866(ra) # 80004960 <fileclose>
      p->ofile[fd] = 0;
    80002606:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000260a:	04a1                	addi	s1,s1,8
    8000260c:	01248563          	beq	s1,s2,80002616 <exit+0x58>
    if(p->ofile[fd]){
    80002610:	6088                	ld	a0,0(s1)
    80002612:	f575                	bnez	a0,800025fe <exit+0x40>
    80002614:	bfdd                	j	8000260a <exit+0x4c>
  begin_op();
    80002616:	00002097          	auipc	ra,0x2
    8000261a:	e7e080e7          	jalr	-386(ra) # 80004494 <begin_op>
  iput(p->cwd);
    8000261e:	1509b503          	ld	a0,336(s3)
    80002622:	00001097          	auipc	ra,0x1
    80002626:	65a080e7          	jalr	1626(ra) # 80003c7c <iput>
  end_op();
    8000262a:	00002097          	auipc	ra,0x2
    8000262e:	eea080e7          	jalr	-278(ra) # 80004514 <end_op>
  p->cwd = 0;
    80002632:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002636:	0000f497          	auipc	s1,0xf
    8000263a:	c8248493          	addi	s1,s1,-894 # 800112b8 <wait_lock>
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	5a4080e7          	jalr	1444(ra) # 80000be4 <acquire>
  reparent(p);
    80002648:	854e                	mv	a0,s3
    8000264a:	00000097          	auipc	ra,0x0
    8000264e:	f1a080e7          	jalr	-230(ra) # 80002564 <reparent>
  wakeup(p->parent);
    80002652:	0389b503          	ld	a0,56(s3)
    80002656:	00000097          	auipc	ra,0x0
    8000265a:	e84080e7          	jalr	-380(ra) # 800024da <wakeup>
  acquire(&p->lock);
    8000265e:	854e                	mv	a0,s3
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	584080e7          	jalr	1412(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002668:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000266c:	4795                	li	a5,5
    8000266e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002672:	00007797          	auipc	a5,0x7
    80002676:	9be7a783          	lw	a5,-1602(a5) # 80009030 <ticks>
    8000267a:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    8000267e:	8526                	mv	a0,s1
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	618080e7          	jalr	1560(ra) # 80000c98 <release>
  sched();
    80002688:	00000097          	auipc	ra,0x0
    8000268c:	a5c080e7          	jalr	-1444(ra) # 800020e4 <sched>
  panic("zombie exit");
    80002690:	00006517          	auipc	a0,0x6
    80002694:	be050513          	addi	a0,a0,-1056 # 80008270 <digits+0x230>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>

00000000800026a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800026a0:	7179                	addi	sp,sp,-48
    800026a2:	f406                	sd	ra,40(sp)
    800026a4:	f022                	sd	s0,32(sp)
    800026a6:	ec26                	sd	s1,24(sp)
    800026a8:	e84a                	sd	s2,16(sp)
    800026aa:	e44e                	sd	s3,8(sp)
    800026ac:	1800                	addi	s0,sp,48
    800026ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800026b0:	0000f497          	auipc	s1,0xf
    800026b4:	02048493          	addi	s1,s1,32 # 800116d0 <proc>
    800026b8:	00015997          	auipc	s3,0x15
    800026bc:	41898993          	addi	s3,s3,1048 # 80017ad0 <tickslock>
    acquire(&p->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	522080e7          	jalr	1314(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800026ca:	589c                	lw	a5,48(s1)
    800026cc:	01278d63          	beq	a5,s2,800026e6 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026d0:	8526                	mv	a0,s1
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800026da:	19048493          	addi	s1,s1,400
    800026de:	ff3491e3          	bne	s1,s3,800026c0 <kill+0x20>
  }
  return -1;
    800026e2:	557d                	li	a0,-1
    800026e4:	a829                	j	800026fe <kill+0x5e>
      p->killed = 1;
    800026e6:	4785                	li	a5,1
    800026e8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800026ea:	4c98                	lw	a4,24(s1)
    800026ec:	4789                	li	a5,2
    800026ee:	00f70f63          	beq	a4,a5,8000270c <kill+0x6c>
      release(&p->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
      return 0;
    800026fc:	4501                	li	a0,0
}
    800026fe:	70a2                	ld	ra,40(sp)
    80002700:	7402                	ld	s0,32(sp)
    80002702:	64e2                	ld	s1,24(sp)
    80002704:	6942                	ld	s2,16(sp)
    80002706:	69a2                	ld	s3,8(sp)
    80002708:	6145                	addi	sp,sp,48
    8000270a:	8082                	ret
        p->state = RUNNABLE;
    8000270c:	478d                	li	a5,3
    8000270e:	cc9c                	sw	a5,24(s1)
        p->sched_end = ticks;
    80002710:	00007797          	auipc	a5,0x7
    80002714:	9207a783          	lw	a5,-1760(a5) # 80009030 <ticks>
    80002718:	18f4a223          	sw	a5,388(s1)
    8000271c:	bfd9                	j	800026f2 <kill+0x52>

000000008000271e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000271e:	7179                	addi	sp,sp,-48
    80002720:	f406                	sd	ra,40(sp)
    80002722:	f022                	sd	s0,32(sp)
    80002724:	ec26                	sd	s1,24(sp)
    80002726:	e84a                	sd	s2,16(sp)
    80002728:	e44e                	sd	s3,8(sp)
    8000272a:	e052                	sd	s4,0(sp)
    8000272c:	1800                	addi	s0,sp,48
    8000272e:	84aa                	mv	s1,a0
    80002730:	892e                	mv	s2,a1
    80002732:	89b2                	mv	s3,a2
    80002734:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002736:	fffff097          	auipc	ra,0xfffff
    8000273a:	27a080e7          	jalr	634(ra) # 800019b0 <myproc>
  if(user_dst){
    8000273e:	c08d                	beqz	s1,80002760 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002740:	86d2                	mv	a3,s4
    80002742:	864e                	mv	a2,s3
    80002744:	85ca                	mv	a1,s2
    80002746:	6928                	ld	a0,80(a0)
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	f2a080e7          	jalr	-214(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002750:	70a2                	ld	ra,40(sp)
    80002752:	7402                	ld	s0,32(sp)
    80002754:	64e2                	ld	s1,24(sp)
    80002756:	6942                	ld	s2,16(sp)
    80002758:	69a2                	ld	s3,8(sp)
    8000275a:	6a02                	ld	s4,0(sp)
    8000275c:	6145                	addi	sp,sp,48
    8000275e:	8082                	ret
    memmove((char *)dst, src, len);
    80002760:	000a061b          	sext.w	a2,s4
    80002764:	85ce                	mv	a1,s3
    80002766:	854a                	mv	a0,s2
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	5d8080e7          	jalr	1496(ra) # 80000d40 <memmove>
    return 0;
    80002770:	8526                	mv	a0,s1
    80002772:	bff9                	j	80002750 <either_copyout+0x32>

0000000080002774 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002774:	7179                	addi	sp,sp,-48
    80002776:	f406                	sd	ra,40(sp)
    80002778:	f022                	sd	s0,32(sp)
    8000277a:	ec26                	sd	s1,24(sp)
    8000277c:	e84a                	sd	s2,16(sp)
    8000277e:	e44e                	sd	s3,8(sp)
    80002780:	e052                	sd	s4,0(sp)
    80002782:	1800                	addi	s0,sp,48
    80002784:	892a                	mv	s2,a0
    80002786:	84ae                	mv	s1,a1
    80002788:	89b2                	mv	s3,a2
    8000278a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	224080e7          	jalr	548(ra) # 800019b0 <myproc>
  if(user_src){
    80002794:	c08d                	beqz	s1,800027b6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002796:	86d2                	mv	a3,s4
    80002798:	864e                	mv	a2,s3
    8000279a:	85ca                	mv	a1,s2
    8000279c:	6928                	ld	a0,80(a0)
    8000279e:	fffff097          	auipc	ra,0xfffff
    800027a2:	f60080e7          	jalr	-160(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027a6:	70a2                	ld	ra,40(sp)
    800027a8:	7402                	ld	s0,32(sp)
    800027aa:	64e2                	ld	s1,24(sp)
    800027ac:	6942                	ld	s2,16(sp)
    800027ae:	69a2                	ld	s3,8(sp)
    800027b0:	6a02                	ld	s4,0(sp)
    800027b2:	6145                	addi	sp,sp,48
    800027b4:	8082                	ret
    memmove(dst, (char*)src, len);
    800027b6:	000a061b          	sext.w	a2,s4
    800027ba:	85ce                	mv	a1,s3
    800027bc:	854a                	mv	a0,s2
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	582080e7          	jalr	1410(ra) # 80000d40 <memmove>
    return 0;
    800027c6:	8526                	mv	a0,s1
    800027c8:	bff9                	j	800027a6 <either_copyin+0x32>

00000000800027ca <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027ca:	715d                	addi	sp,sp,-80
    800027cc:	e486                	sd	ra,72(sp)
    800027ce:	e0a2                	sd	s0,64(sp)
    800027d0:	fc26                	sd	s1,56(sp)
    800027d2:	f84a                	sd	s2,48(sp)
    800027d4:	f44e                	sd	s3,40(sp)
    800027d6:	f052                	sd	s4,32(sp)
    800027d8:	ec56                	sd	s5,24(sp)
    800027da:	e85a                	sd	s6,16(sp)
    800027dc:	e45e                	sd	s7,8(sp)
    800027de:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027e0:	00006517          	auipc	a0,0x6
    800027e4:	c4050513          	addi	a0,a0,-960 # 80008420 <states.1753+0x160>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	da0080e7          	jalr	-608(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027f0:	0000f497          	auipc	s1,0xf
    800027f4:	03848493          	addi	s1,s1,56 # 80011828 <proc+0x158>
    800027f8:	00015917          	auipc	s2,0x15
    800027fc:	43090913          	addi	s2,s2,1072 # 80017c28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002800:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002802:	00006997          	auipc	s3,0x6
    80002806:	a7e98993          	addi	s3,s3,-1410 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000280a:	00006a97          	auipc	s5,0x6
    8000280e:	a7ea8a93          	addi	s5,s5,-1410 # 80008288 <digits+0x248>
    printf("\n");
    80002812:	00006a17          	auipc	s4,0x6
    80002816:	c0ea0a13          	addi	s4,s4,-1010 # 80008420 <states.1753+0x160>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281a:	00006b97          	auipc	s7,0x6
    8000281e:	aa6b8b93          	addi	s7,s7,-1370 # 800082c0 <states.1753>
    80002822:	a00d                	j	80002844 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002824:	ed86a583          	lw	a1,-296(a3)
    80002828:	8556                	mv	a0,s5
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d5e080e7          	jalr	-674(ra) # 80000588 <printf>
    printf("\n");
    80002832:	8552                	mv	a0,s4
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	d54080e7          	jalr	-684(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000283c:	19048493          	addi	s1,s1,400
    80002840:	03248163          	beq	s1,s2,80002862 <procdump+0x98>
    if(p->state == UNUSED)
    80002844:	86a6                	mv	a3,s1
    80002846:	ec04a783          	lw	a5,-320(s1)
    8000284a:	dbed                	beqz	a5,8000283c <procdump+0x72>
      state = "???";
    8000284c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000284e:	fcfb6be3          	bltu	s6,a5,80002824 <procdump+0x5a>
    80002852:	1782                	slli	a5,a5,0x20
    80002854:	9381                	srli	a5,a5,0x20
    80002856:	078e                	slli	a5,a5,0x3
    80002858:	97de                	add	a5,a5,s7
    8000285a:	6390                	ld	a2,0(a5)
    8000285c:	f661                	bnez	a2,80002824 <procdump+0x5a>
      state = "???";
    8000285e:	864e                	mv	a2,s3
    80002860:	b7d1                	j	80002824 <procdump+0x5a>
  }
}
    80002862:	60a6                	ld	ra,72(sp)
    80002864:	6406                	ld	s0,64(sp)
    80002866:	74e2                	ld	s1,56(sp)
    80002868:	7942                	ld	s2,48(sp)
    8000286a:	79a2                	ld	s3,40(sp)
    8000286c:	7a02                	ld	s4,32(sp)
    8000286e:	6ae2                	ld	s5,24(sp)
    80002870:	6b42                	ld	s6,16(sp)
    80002872:	6ba2                	ld	s7,8(sp)
    80002874:	6161                	addi	sp,sp,80
    80002876:	8082                	ret

0000000080002878 <trace>:

// enabling tracing for the current process
void
trace(int trace_mask)
{
    80002878:	1101                	addi	sp,sp,-32
    8000287a:	ec06                	sd	ra,24(sp)
    8000287c:	e822                	sd	s0,16(sp)
    8000287e:	e426                	sd	s1,8(sp)
    80002880:	1000                	addi	s0,sp,32
    80002882:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	12c080e7          	jalr	300(ra) # 800019b0 <myproc>
  p->trace_mask = trace_mask;
    8000288c:	16952423          	sw	s1,360(a0)
    80002890:	60e2                	ld	ra,24(sp)
    80002892:	6442                	ld	s0,16(sp)
    80002894:	64a2                	ld	s1,8(sp)
    80002896:	6105                	addi	sp,sp,32
    80002898:	8082                	ret

000000008000289a <swtch>:
    8000289a:	00153023          	sd	ra,0(a0)
    8000289e:	00253423          	sd	sp,8(a0)
    800028a2:	e900                	sd	s0,16(a0)
    800028a4:	ed04                	sd	s1,24(a0)
    800028a6:	03253023          	sd	s2,32(a0)
    800028aa:	03353423          	sd	s3,40(a0)
    800028ae:	03453823          	sd	s4,48(a0)
    800028b2:	03553c23          	sd	s5,56(a0)
    800028b6:	05653023          	sd	s6,64(a0)
    800028ba:	05753423          	sd	s7,72(a0)
    800028be:	05853823          	sd	s8,80(a0)
    800028c2:	05953c23          	sd	s9,88(a0)
    800028c6:	07a53023          	sd	s10,96(a0)
    800028ca:	07b53423          	sd	s11,104(a0)
    800028ce:	0005b083          	ld	ra,0(a1)
    800028d2:	0085b103          	ld	sp,8(a1)
    800028d6:	6980                	ld	s0,16(a1)
    800028d8:	6d84                	ld	s1,24(a1)
    800028da:	0205b903          	ld	s2,32(a1)
    800028de:	0285b983          	ld	s3,40(a1)
    800028e2:	0305ba03          	ld	s4,48(a1)
    800028e6:	0385ba83          	ld	s5,56(a1)
    800028ea:	0405bb03          	ld	s6,64(a1)
    800028ee:	0485bb83          	ld	s7,72(a1)
    800028f2:	0505bc03          	ld	s8,80(a1)
    800028f6:	0585bc83          	ld	s9,88(a1)
    800028fa:	0605bd03          	ld	s10,96(a1)
    800028fe:	0685bd83          	ld	s11,104(a1)
    80002902:	8082                	ret

0000000080002904 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002904:	1141                	addi	sp,sp,-16
    80002906:	e406                	sd	ra,8(sp)
    80002908:	e022                	sd	s0,0(sp)
    8000290a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000290c:	00006597          	auipc	a1,0x6
    80002910:	9e458593          	addi	a1,a1,-1564 # 800082f0 <states.1753+0x30>
    80002914:	00015517          	auipc	a0,0x15
    80002918:	1bc50513          	addi	a0,a0,444 # 80017ad0 <tickslock>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	238080e7          	jalr	568(ra) # 80000b54 <initlock>
}
    80002924:	60a2                	ld	ra,8(sp)
    80002926:	6402                	ld	s0,0(sp)
    80002928:	0141                	addi	sp,sp,16
    8000292a:	8082                	ret

000000008000292c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000292c:	1141                	addi	sp,sp,-16
    8000292e:	e422                	sd	s0,8(sp)
    80002930:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002932:	00003797          	auipc	a5,0x3
    80002936:	64e78793          	addi	a5,a5,1614 # 80005f80 <kernelvec>
    8000293a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000293e:	6422                	ld	s0,8(sp)
    80002940:	0141                	addi	sp,sp,16
    80002942:	8082                	ret

0000000080002944 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002944:	1141                	addi	sp,sp,-16
    80002946:	e406                	sd	ra,8(sp)
    80002948:	e022                	sd	s0,0(sp)
    8000294a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	064080e7          	jalr	100(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002958:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000295e:	00004617          	auipc	a2,0x4
    80002962:	6a260613          	addi	a2,a2,1698 # 80007000 <_trampoline>
    80002966:	00004697          	auipc	a3,0x4
    8000296a:	69a68693          	addi	a3,a3,1690 # 80007000 <_trampoline>
    8000296e:	8e91                	sub	a3,a3,a2
    80002970:	040007b7          	lui	a5,0x4000
    80002974:	17fd                	addi	a5,a5,-1
    80002976:	07b2                	slli	a5,a5,0xc
    80002978:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000297a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000297e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002980:	180026f3          	csrr	a3,satp
    80002984:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002986:	6d38                	ld	a4,88(a0)
    80002988:	6134                	ld	a3,64(a0)
    8000298a:	6585                	lui	a1,0x1
    8000298c:	96ae                	add	a3,a3,a1
    8000298e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002990:	6d38                	ld	a4,88(a0)
    80002992:	00000697          	auipc	a3,0x0
    80002996:	14668693          	addi	a3,a3,326 # 80002ad8 <usertrap>
    8000299a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000299c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000299e:	8692                	mv	a3,tp
    800029a0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029a6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029aa:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ae:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029b2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b4:	6f18                	ld	a4,24(a4)
    800029b6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ba:	692c                	ld	a1,80(a0)
    800029bc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029be:	00004717          	auipc	a4,0x4
    800029c2:	6d270713          	addi	a4,a4,1746 # 80007090 <userret>
    800029c6:	8f11                	sub	a4,a4,a2
    800029c8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ca:	577d                	li	a4,-1
    800029cc:	177e                	slli	a4,a4,0x3f
    800029ce:	8dd9                	or	a1,a1,a4
    800029d0:	02000537          	lui	a0,0x2000
    800029d4:	157d                	addi	a0,a0,-1
    800029d6:	0536                	slli	a0,a0,0xd
    800029d8:	9782                	jalr	a5
}
    800029da:	60a2                	ld	ra,8(sp)
    800029dc:	6402                	ld	s0,0(sp)
    800029de:	0141                	addi	sp,sp,16
    800029e0:	8082                	ret

00000000800029e2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e2:	1101                	addi	sp,sp,-32
    800029e4:	ec06                	sd	ra,24(sp)
    800029e6:	e822                	sd	s0,16(sp)
    800029e8:	e426                	sd	s1,8(sp)
    800029ea:	e04a                	sd	s2,0(sp)
    800029ec:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029ee:	00015917          	auipc	s2,0x15
    800029f2:	0e290913          	addi	s2,s2,226 # 80017ad0 <tickslock>
    800029f6:	854a                	mv	a0,s2
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	1ec080e7          	jalr	492(ra) # 80000be4 <acquire>
  ticks++;
    80002a00:	00006497          	auipc	s1,0x6
    80002a04:	63048493          	addi	s1,s1,1584 # 80009030 <ticks>
    80002a08:	409c                	lw	a5,0(s1)
    80002a0a:	2785                	addiw	a5,a5,1
    80002a0c:	c09c                	sw	a5,0(s1)
  update_time();
    80002a0e:	fffff097          	auipc	ra,0xfffff
    80002a12:	4de080e7          	jalr	1246(ra) # 80001eec <update_time>
  wakeup(&ticks);
    80002a16:	8526                	mv	a0,s1
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	ac2080e7          	jalr	-1342(ra) # 800024da <wakeup>
  release(&tickslock);
    80002a20:	854a                	mv	a0,s2
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	276080e7          	jalr	630(ra) # 80000c98 <release>
}
    80002a2a:	60e2                	ld	ra,24(sp)
    80002a2c:	6442                	ld	s0,16(sp)
    80002a2e:	64a2                	ld	s1,8(sp)
    80002a30:	6902                	ld	s2,0(sp)
    80002a32:	6105                	addi	sp,sp,32
    80002a34:	8082                	ret

0000000080002a36 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a36:	1101                	addi	sp,sp,-32
    80002a38:	ec06                	sd	ra,24(sp)
    80002a3a:	e822                	sd	s0,16(sp)
    80002a3c:	e426                	sd	s1,8(sp)
    80002a3e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a40:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a44:	00074d63          	bltz	a4,80002a5e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a48:	57fd                	li	a5,-1
    80002a4a:	17fe                	slli	a5,a5,0x3f
    80002a4c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a4e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a50:	06f70363          	beq	a4,a5,80002ab6 <devintr+0x80>
  }
}
    80002a54:	60e2                	ld	ra,24(sp)
    80002a56:	6442                	ld	s0,16(sp)
    80002a58:	64a2                	ld	s1,8(sp)
    80002a5a:	6105                	addi	sp,sp,32
    80002a5c:	8082                	ret
     (scause & 0xff) == 9){
    80002a5e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a62:	46a5                	li	a3,9
    80002a64:	fed792e3          	bne	a5,a3,80002a48 <devintr+0x12>
    int irq = plic_claim();
    80002a68:	00003097          	auipc	ra,0x3
    80002a6c:	620080e7          	jalr	1568(ra) # 80006088 <plic_claim>
    80002a70:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a72:	47a9                	li	a5,10
    80002a74:	02f50763          	beq	a0,a5,80002aa2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a78:	4785                	li	a5,1
    80002a7a:	02f50963          	beq	a0,a5,80002aac <devintr+0x76>
    return 1;
    80002a7e:	4505                	li	a0,1
    } else if(irq){
    80002a80:	d8f1                	beqz	s1,80002a54 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a82:	85a6                	mv	a1,s1
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	87450513          	addi	a0,a0,-1932 # 800082f8 <states.1753+0x38>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	afc080e7          	jalr	-1284(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a94:	8526                	mv	a0,s1
    80002a96:	00003097          	auipc	ra,0x3
    80002a9a:	616080e7          	jalr	1558(ra) # 800060ac <plic_complete>
    return 1;
    80002a9e:	4505                	li	a0,1
    80002aa0:	bf55                	j	80002a54 <devintr+0x1e>
      uartintr();
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	f06080e7          	jalr	-250(ra) # 800009a8 <uartintr>
    80002aaa:	b7ed                	j	80002a94 <devintr+0x5e>
      virtio_disk_intr();
    80002aac:	00004097          	auipc	ra,0x4
    80002ab0:	ae0080e7          	jalr	-1312(ra) # 8000658c <virtio_disk_intr>
    80002ab4:	b7c5                	j	80002a94 <devintr+0x5e>
    if(cpuid() == 0){
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	ece080e7          	jalr	-306(ra) # 80001984 <cpuid>
    80002abe:	c901                	beqz	a0,80002ace <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ac0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ac4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ac6:	14479073          	csrw	sip,a5
    return 2;
    80002aca:	4509                	li	a0,2
    80002acc:	b761                	j	80002a54 <devintr+0x1e>
      clockintr();
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	f14080e7          	jalr	-236(ra) # 800029e2 <clockintr>
    80002ad6:	b7ed                	j	80002ac0 <devintr+0x8a>

0000000080002ad8 <usertrap>:
{
    80002ad8:	1101                	addi	sp,sp,-32
    80002ada:	ec06                	sd	ra,24(sp)
    80002adc:	e822                	sd	s0,16(sp)
    80002ade:	e426                	sd	s1,8(sp)
    80002ae0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ae6:	1007f793          	andi	a5,a5,256
    80002aea:	e3a5                	bnez	a5,80002b4a <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aec:	00003797          	auipc	a5,0x3
    80002af0:	49478793          	addi	a5,a5,1172 # 80005f80 <kernelvec>
    80002af4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	eb8080e7          	jalr	-328(ra) # 800019b0 <myproc>
    80002b00:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b02:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b04:	14102773          	csrr	a4,sepc
    80002b08:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b0a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b0e:	47a1                	li	a5,8
    80002b10:	04f71b63          	bne	a4,a5,80002b66 <usertrap+0x8e>
    if(p->killed)
    80002b14:	551c                	lw	a5,40(a0)
    80002b16:	e3b1                	bnez	a5,80002b5a <usertrap+0x82>
    p->trapframe->epc += 4;
    80002b18:	6cb8                	ld	a4,88(s1)
    80002b1a:	6f1c                	ld	a5,24(a4)
    80002b1c:	0791                	addi	a5,a5,4
    80002b1e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b28:	10079073          	csrw	sstatus,a5
    syscall();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	29a080e7          	jalr	666(ra) # 80002dc6 <syscall>
  if(p->killed)
    80002b34:	549c                	lw	a5,40(s1)
    80002b36:	e7b5                	bnez	a5,80002ba2 <usertrap+0xca>
  usertrapret();
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	e0c080e7          	jalr	-500(ra) # 80002944 <usertrapret>
}
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret
    panic("usertrap: not from user mode");
    80002b4a:	00005517          	auipc	a0,0x5
    80002b4e:	7ce50513          	addi	a0,a0,1998 # 80008318 <states.1753+0x58>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
      exit(-1);
    80002b5a:	557d                	li	a0,-1
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	a62080e7          	jalr	-1438(ra) # 800025be <exit>
    80002b64:	bf55                	j	80002b18 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	ed0080e7          	jalr	-304(ra) # 80002a36 <devintr>
    80002b6e:	f179                	bnez	a0,80002b34 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b70:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b74:	5890                	lw	a2,48(s1)
    80002b76:	00005517          	auipc	a0,0x5
    80002b7a:	7c250513          	addi	a0,a0,1986 # 80008338 <states.1753+0x78>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a0a080e7          	jalr	-1526(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b86:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b8e:	00005517          	auipc	a0,0x5
    80002b92:	7da50513          	addi	a0,a0,2010 # 80008368 <states.1753+0xa8>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9f2080e7          	jalr	-1550(ra) # 80000588 <printf>
    p->killed = 1;
    80002b9e:	4785                	li	a5,1
    80002ba0:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ba2:	557d                	li	a0,-1
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	a1a080e7          	jalr	-1510(ra) # 800025be <exit>
    80002bac:	b771                	j	80002b38 <usertrap+0x60>

0000000080002bae <kerneltrap>:
{
    80002bae:	7179                	addi	sp,sp,-48
    80002bb0:	f406                	sd	ra,40(sp)
    80002bb2:	f022                	sd	s0,32(sp)
    80002bb4:	ec26                	sd	s1,24(sp)
    80002bb6:	e84a                	sd	s2,16(sp)
    80002bb8:	e44e                	sd	s3,8(sp)
    80002bba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bbc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bc4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bc8:	1004f793          	andi	a5,s1,256
    80002bcc:	c78d                	beqz	a5,80002bf6 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bd2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bd4:	eb8d                	bnez	a5,80002c06 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	e60080e7          	jalr	-416(ra) # 80002a36 <devintr>
    80002bde:	cd05                	beqz	a0,80002c16 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002be0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be4:	10049073          	csrw	sstatus,s1
}
    80002be8:	70a2                	ld	ra,40(sp)
    80002bea:	7402                	ld	s0,32(sp)
    80002bec:	64e2                	ld	s1,24(sp)
    80002bee:	6942                	ld	s2,16(sp)
    80002bf0:	69a2                	ld	s3,8(sp)
    80002bf2:	6145                	addi	sp,sp,48
    80002bf4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bf6:	00005517          	auipc	a0,0x5
    80002bfa:	79250513          	addi	a0,a0,1938 # 80008388 <states.1753+0xc8>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	940080e7          	jalr	-1728(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	7aa50513          	addi	a0,a0,1962 # 800083b0 <states.1753+0xf0>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	930080e7          	jalr	-1744(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c16:	85ce                	mv	a1,s3
    80002c18:	00005517          	auipc	a0,0x5
    80002c1c:	7b850513          	addi	a0,a0,1976 # 800083d0 <states.1753+0x110>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	968080e7          	jalr	-1688(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c28:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c2c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c30:	00005517          	auipc	a0,0x5
    80002c34:	7b050513          	addi	a0,a0,1968 # 800083e0 <states.1753+0x120>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	950080e7          	jalr	-1712(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c40:	00005517          	auipc	a0,0x5
    80002c44:	7b850513          	addi	a0,a0,1976 # 800083f8 <states.1753+0x138>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	8f6080e7          	jalr	-1802(ra) # 8000053e <panic>

0000000080002c50 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	1000                	addi	s0,sp,32
    80002c5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	d54080e7          	jalr	-684(ra) # 800019b0 <myproc>
  switch (n) {
    80002c64:	4795                	li	a5,5
    80002c66:	0497e163          	bltu	a5,s1,80002ca8 <argraw+0x58>
    80002c6a:	048a                	slli	s1,s1,0x2
    80002c6c:	00006717          	auipc	a4,0x6
    80002c70:	89c70713          	addi	a4,a4,-1892 # 80008508 <states.1753+0x248>
    80002c74:	94ba                	add	s1,s1,a4
    80002c76:	409c                	lw	a5,0(s1)
    80002c78:	97ba                	add	a5,a5,a4
    80002c7a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c7c:	6d3c                	ld	a5,88(a0)
    80002c7e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	64a2                	ld	s1,8(sp)
    80002c86:	6105                	addi	sp,sp,32
    80002c88:	8082                	ret
    return p->trapframe->a1;
    80002c8a:	6d3c                	ld	a5,88(a0)
    80002c8c:	7fa8                	ld	a0,120(a5)
    80002c8e:	bfcd                	j	80002c80 <argraw+0x30>
    return p->trapframe->a2;
    80002c90:	6d3c                	ld	a5,88(a0)
    80002c92:	63c8                	ld	a0,128(a5)
    80002c94:	b7f5                	j	80002c80 <argraw+0x30>
    return p->trapframe->a3;
    80002c96:	6d3c                	ld	a5,88(a0)
    80002c98:	67c8                	ld	a0,136(a5)
    80002c9a:	b7dd                	j	80002c80 <argraw+0x30>
    return p->trapframe->a4;
    80002c9c:	6d3c                	ld	a5,88(a0)
    80002c9e:	6bc8                	ld	a0,144(a5)
    80002ca0:	b7c5                	j	80002c80 <argraw+0x30>
    return p->trapframe->a5;
    80002ca2:	6d3c                	ld	a5,88(a0)
    80002ca4:	6fc8                	ld	a0,152(a5)
    80002ca6:	bfe9                	j	80002c80 <argraw+0x30>
  panic("argraw");
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	76050513          	addi	a0,a0,1888 # 80008408 <states.1753+0x148>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>

0000000080002cb8 <fetchaddr>:
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	e04a                	sd	s2,0(sp)
    80002cc2:	1000                	addi	s0,sp,32
    80002cc4:	84aa                	mv	s1,a0
    80002cc6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	ce8080e7          	jalr	-792(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cd0:	653c                	ld	a5,72(a0)
    80002cd2:	02f4f863          	bgeu	s1,a5,80002d02 <fetchaddr+0x4a>
    80002cd6:	00848713          	addi	a4,s1,8
    80002cda:	02e7e663          	bltu	a5,a4,80002d06 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cde:	46a1                	li	a3,8
    80002ce0:	8626                	mv	a2,s1
    80002ce2:	85ca                	mv	a1,s2
    80002ce4:	6928                	ld	a0,80(a0)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	a18080e7          	jalr	-1512(ra) # 800016fe <copyin>
    80002cee:	00a03533          	snez	a0,a0
    80002cf2:	40a00533          	neg	a0,a0
}
    80002cf6:	60e2                	ld	ra,24(sp)
    80002cf8:	6442                	ld	s0,16(sp)
    80002cfa:	64a2                	ld	s1,8(sp)
    80002cfc:	6902                	ld	s2,0(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret
    return -1;
    80002d02:	557d                	li	a0,-1
    80002d04:	bfcd                	j	80002cf6 <fetchaddr+0x3e>
    80002d06:	557d                	li	a0,-1
    80002d08:	b7fd                	j	80002cf6 <fetchaddr+0x3e>

0000000080002d0a <fetchstr>:
{
    80002d0a:	7179                	addi	sp,sp,-48
    80002d0c:	f406                	sd	ra,40(sp)
    80002d0e:	f022                	sd	s0,32(sp)
    80002d10:	ec26                	sd	s1,24(sp)
    80002d12:	e84a                	sd	s2,16(sp)
    80002d14:	e44e                	sd	s3,8(sp)
    80002d16:	1800                	addi	s0,sp,48
    80002d18:	892a                	mv	s2,a0
    80002d1a:	84ae                	mv	s1,a1
    80002d1c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	c92080e7          	jalr	-878(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d26:	86ce                	mv	a3,s3
    80002d28:	864a                	mv	a2,s2
    80002d2a:	85a6                	mv	a1,s1
    80002d2c:	6928                	ld	a0,80(a0)
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	a5c080e7          	jalr	-1444(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d36:	00054763          	bltz	a0,80002d44 <fetchstr+0x3a>
  return strlen(buf);
    80002d3a:	8526                	mv	a0,s1
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	128080e7          	jalr	296(ra) # 80000e64 <strlen>
}
    80002d44:	70a2                	ld	ra,40(sp)
    80002d46:	7402                	ld	s0,32(sp)
    80002d48:	64e2                	ld	s1,24(sp)
    80002d4a:	6942                	ld	s2,16(sp)
    80002d4c:	69a2                	ld	s3,8(sp)
    80002d4e:	6145                	addi	sp,sp,48
    80002d50:	8082                	ret

0000000080002d52 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	e426                	sd	s1,8(sp)
    80002d5a:	1000                	addi	s0,sp,32
    80002d5c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	ef2080e7          	jalr	-270(ra) # 80002c50 <argraw>
    80002d66:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d68:	4501                	li	a0,0
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6105                	addi	sp,sp,32
    80002d72:	8082                	ret

0000000080002d74 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d74:	1101                	addi	sp,sp,-32
    80002d76:	ec06                	sd	ra,24(sp)
    80002d78:	e822                	sd	s0,16(sp)
    80002d7a:	e426                	sd	s1,8(sp)
    80002d7c:	1000                	addi	s0,sp,32
    80002d7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	ed0080e7          	jalr	-304(ra) # 80002c50 <argraw>
    80002d88:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d8a:	4501                	li	a0,0
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret

0000000080002d96 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	e426                	sd	s1,8(sp)
    80002d9e:	e04a                	sd	s2,0(sp)
    80002da0:	1000                	addi	s0,sp,32
    80002da2:	84ae                	mv	s1,a1
    80002da4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	eaa080e7          	jalr	-342(ra) # 80002c50 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dae:	864a                	mv	a2,s2
    80002db0:	85a6                	mv	a1,s1
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	f58080e7          	jalr	-168(ra) # 80002d0a <fetchstr>
}
    80002dba:	60e2                	ld	ra,24(sp)
    80002dbc:	6442                	ld	s0,16(sp)
    80002dbe:	64a2                	ld	s1,8(sp)
    80002dc0:	6902                	ld	s2,0(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret

0000000080002dc6 <syscall>:
};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002dc6:	711d                	addi	sp,sp,-96
    80002dc8:	ec86                	sd	ra,88(sp)
    80002dca:	e8a2                	sd	s0,80(sp)
    80002dcc:	e4a6                	sd	s1,72(sp)
    80002dce:	e0ca                	sd	s2,64(sp)
    80002dd0:	fc4e                	sd	s3,56(sp)
    80002dd2:	f852                	sd	s4,48(sp)
    80002dd4:	f456                	sd	s5,40(sp)
    80002dd6:	f05a                	sd	s6,32(sp)
    80002dd8:	ec5e                	sd	s7,24(sp)
    80002dda:	e862                	sd	s8,16(sp)
    80002ddc:	e466                	sd	s9,8(sp)
    80002dde:	e06a                	sd	s10,0(sp)
    80002de0:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	bce080e7          	jalr	-1074(ra) # 800019b0 <myproc>
    80002dea:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002dec:	6d24                	ld	s1,88(a0)
    80002dee:	74dc                	ld	a5,168(s1)
    80002df0:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002df4:	37fd                	addiw	a5,a5,-1
    80002df6:	4759                	li	a4,22
    80002df8:	06f76f63          	bltu	a4,a5,80002e76 <syscall+0xb0>
    80002dfc:	003b1713          	slli	a4,s6,0x3
    80002e00:	00005797          	auipc	a5,0x5
    80002e04:	72078793          	addi	a5,a5,1824 # 80008520 <syscalls>
    80002e08:	97ba                	add	a5,a5,a4
    80002e0a:	0007bd03          	ld	s10,0(a5)
    80002e0e:	060d0463          	beqz	s10,80002e76 <syscall+0xb0>
    80002e12:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002e14:	fffb0c1b          	addiw	s8,s6,-1
    80002e18:	004c1713          	slli	a4,s8,0x4
    80002e1c:	00006797          	auipc	a5,0x6
    80002e20:	b1c78793          	addi	a5,a5,-1252 # 80008938 <syscall_arg_infos>
    80002e24:	97ba                	add	a5,a5,a4
    80002e26:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002e2a:	00299793          	slli	a5,s3,0x2
    80002e2e:	07bd                	addi	a5,a5,15
    80002e30:	9bc1                	andi	a5,a5,-16
    80002e32:	40f10133          	sub	sp,sp,a5
    80002e36:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002e38:	0f305363          	blez	s3,80002f1e <syscall+0x158>
    80002e3c:	8ade                	mv	s5,s7
    80002e3e:	895e                	mv	s2,s7
    80002e40:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002e42:	8526                	mv	a0,s1
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	e0c080e7          	jalr	-500(ra) # 80002c50 <argraw>
    80002e4c:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002e50:	2485                	addiw	s1,s1,1
    80002e52:	0911                	addi	s2,s2,4
    80002e54:	fe9997e3          	bne	s3,s1,80002e42 <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002e58:	058a3483          	ld	s1,88(s4)
    80002e5c:	9d02                	jalr	s10
    80002e5e:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002e60:	4785                	li	a5,1
    80002e62:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002e66:	168a2b03          	lw	s6,360(s4)
    80002e6a:	0167f7b3          	and	a5,a5,s6
    80002e6e:	2781                	sext.w	a5,a5
    80002e70:	e7a1                	bnez	a5,80002eb8 <syscall+0xf2>
    80002e72:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e74:	a015                	j	80002e98 <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e76:	86da                	mv	a3,s6
    80002e78:	158a0613          	addi	a2,s4,344
    80002e7c:	030a2583          	lw	a1,48(s4)
    80002e80:	00005517          	auipc	a0,0x5
    80002e84:	5a850513          	addi	a0,a0,1448 # 80008428 <states.1753+0x168>
    80002e88:	ffffd097          	auipc	ra,0xffffd
    80002e8c:	700080e7          	jalr	1792(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e90:	058a3783          	ld	a5,88(s4)
    80002e94:	577d                	li	a4,-1
    80002e96:	fbb8                	sd	a4,112(a5)
  }
}
    80002e98:	fa040113          	addi	sp,s0,-96
    80002e9c:	60e6                	ld	ra,88(sp)
    80002e9e:	6446                	ld	s0,80(sp)
    80002ea0:	64a6                	ld	s1,72(sp)
    80002ea2:	6906                	ld	s2,64(sp)
    80002ea4:	79e2                	ld	s3,56(sp)
    80002ea6:	7a42                	ld	s4,48(sp)
    80002ea8:	7aa2                	ld	s5,40(sp)
    80002eaa:	7b02                	ld	s6,32(sp)
    80002eac:	6be2                	ld	s7,24(sp)
    80002eae:	6c42                	ld	s8,16(sp)
    80002eb0:	6ca2                	ld	s9,8(sp)
    80002eb2:	6d02                	ld	s10,0(sp)
    80002eb4:	6125                	addi	sp,sp,96
    80002eb6:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002eb8:	0c12                	slli	s8,s8,0x4
    80002eba:	00006797          	auipc	a5,0x6
    80002ebe:	a7e78793          	addi	a5,a5,-1410 # 80008938 <syscall_arg_infos>
    80002ec2:	9c3e                	add	s8,s8,a5
    80002ec4:	008c3603          	ld	a2,8(s8)
    80002ec8:	030a2583          	lw	a1,48(s4)
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	57c50513          	addi	a0,a0,1404 # 80008448 <states.1753+0x188>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6b4080e7          	jalr	1716(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002edc:	fff9879b          	addiw	a5,s3,-1
    80002ee0:	1782                	slli	a5,a5,0x20
    80002ee2:	9381                	srli	a5,a5,0x20
    80002ee4:	0785                	addi	a5,a5,1
    80002ee6:	078a                	slli	a5,a5,0x2
    80002ee8:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80002eea:	00005497          	auipc	s1,0x5
    80002eee:	52648493          	addi	s1,s1,1318 # 80008410 <states.1753+0x150>
    80002ef2:	000aa583          	lw	a1,0(s5)
    80002ef6:	8526                	mv	a0,s1
    80002ef8:	ffffd097          	auipc	ra,0xffffd
    80002efc:	690080e7          	jalr	1680(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002f00:	0a91                	addi	s5,s5,4
    80002f02:	ff7a98e3          	bne	s5,s7,80002ef2 <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    80002f06:	058a3783          	ld	a5,88(s4)
    80002f0a:	7bac                	ld	a1,112(a5)
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	50c50513          	addi	a0,a0,1292 # 80008418 <states.1753+0x158>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    80002f1c:	bf99                	j	80002e72 <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002f1e:	9d02                	jalr	s10
    80002f20:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002f22:	4785                	li	a5,1
    80002f24:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002f28:	168a2703          	lw	a4,360(s4)
    80002f2c:	8ff9                	and	a5,a5,a4
    80002f2e:	2781                	sext.w	a5,a5
    80002f30:	d3a9                	beqz	a5,80002e72 <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002f32:	0c12                	slli	s8,s8,0x4
    80002f34:	00006797          	auipc	a5,0x6
    80002f38:	a0478793          	addi	a5,a5,-1532 # 80008938 <syscall_arg_infos>
    80002f3c:	97e2                	add	a5,a5,s8
    80002f3e:	6790                	ld	a2,8(a5)
    80002f40:	030a2583          	lw	a1,48(s4)
    80002f44:	00005517          	auipc	a0,0x5
    80002f48:	50450513          	addi	a0,a0,1284 # 80008448 <states.1753+0x188>
    80002f4c:	ffffd097          	auipc	ra,0xffffd
    80002f50:	63c080e7          	jalr	1596(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002f54:	bf4d                	j	80002f06 <syscall+0x140>

0000000080002f56 <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    80002f56:	1101                	addi	sp,sp,-32
    80002f58:	ec06                	sd	ra,24(sp)
    80002f5a:	e822                	sd	s0,16(sp)
    80002f5c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f5e:	fec40593          	addi	a1,s0,-20
    80002f62:	4501                	li	a0,0
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	dee080e7          	jalr	-530(ra) # 80002d52 <argint>
    return -1;
    80002f6c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f6e:	00054963          	bltz	a0,80002f80 <sys_exit+0x2a>
  exit(n);
    80002f72:	fec42503          	lw	a0,-20(s0)
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	648080e7          	jalr	1608(ra) # 800025be <exit>
  return 0;  // not reached
    80002f7e:	4781                	li	a5,0
}
    80002f80:	853e                	mv	a0,a5
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f8a:	1141                	addi	sp,sp,-16
    80002f8c:	e406                	sd	ra,8(sp)
    80002f8e:	e022                	sd	s0,0(sp)
    80002f90:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	a1e080e7          	jalr	-1506(ra) # 800019b0 <myproc>
}
    80002f9a:	5908                	lw	a0,48(a0)
    80002f9c:	60a2                	ld	ra,8(sp)
    80002f9e:	6402                	ld	s0,0(sp)
    80002fa0:	0141                	addi	sp,sp,16
    80002fa2:	8082                	ret

0000000080002fa4 <sys_fork>:

uint64
sys_fork(void)
{
    80002fa4:	1141                	addi	sp,sp,-16
    80002fa6:	e406                	sd	ra,8(sp)
    80002fa8:	e022                	sd	s0,0(sp)
    80002faa:	0800                	addi	s0,sp,16
  return fork();
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	dfc080e7          	jalr	-516(ra) # 80001da8 <fork>
}
    80002fb4:	60a2                	ld	ra,8(sp)
    80002fb6:	6402                	ld	s0,0(sp)
    80002fb8:	0141                	addi	sp,sp,16
    80002fba:	8082                	ret

0000000080002fbc <sys_wait>:

uint64
sys_wait(void)
{
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc4:	fe840593          	addi	a1,s0,-24
    80002fc8:	4501                	li	a0,0
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	daa080e7          	jalr	-598(ra) # 80002d74 <argaddr>
    80002fd2:	87aa                	mv	a5,a0
    return -1;
    80002fd4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fd6:	0007c863          	bltz	a5,80002fe6 <sys_wait+0x2a>
  return wait(p);
    80002fda:	fe843503          	ld	a0,-24(s0)
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	288080e7          	jalr	648(ra) # 80002266 <wait>
}
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	6105                	addi	sp,sp,32
    80002fec:	8082                	ret

0000000080002fee <sys_waitx>:

uint64
sys_waitx(void)
{
    80002fee:	7139                	addi	sp,sp,-64
    80002ff0:	fc06                	sd	ra,56(sp)
    80002ff2:	f822                	sd	s0,48(sp)
    80002ff4:	f426                	sd	s1,40(sp)
    80002ff6:	f04a                	sd	s2,32(sp)
    80002ff8:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002ffa:	fd840593          	addi	a1,s0,-40
    80002ffe:	4501                	li	a0,0
    80003000:	00000097          	auipc	ra,0x0
    80003004:	d74080e7          	jalr	-652(ra) # 80002d74 <argaddr>
    return -1;
    80003008:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    8000300a:	08054063          	bltz	a0,8000308a <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000300e:	fd040593          	addi	a1,s0,-48
    80003012:	4505                	li	a0,1
    80003014:	00000097          	auipc	ra,0x0
    80003018:	d60080e7          	jalr	-672(ra) # 80002d74 <argaddr>
    return -1;
    8000301c:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000301e:	06054663          	bltz	a0,8000308a <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003022:	fc840593          	addi	a1,s0,-56
    80003026:	4509                	li	a0,2
    80003028:	00000097          	auipc	ra,0x0
    8000302c:	d4c080e7          	jalr	-692(ra) # 80002d74 <argaddr>
    return -1;
    80003030:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80003032:	04054c63          	bltz	a0,8000308a <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003036:	fc040613          	addi	a2,s0,-64
    8000303a:	fc440593          	addi	a1,s0,-60
    8000303e:	fd843503          	ld	a0,-40(s0)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	34c080e7          	jalr	844(ra) # 8000238e <waitx>
    8000304a:	892a                	mv	s2,a0
  struct proc* p = myproc();
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	964080e7          	jalr	-1692(ra) # 800019b0 <myproc>
    80003054:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003056:	4691                	li	a3,4
    80003058:	fc440613          	addi	a2,s0,-60
    8000305c:	fd043583          	ld	a1,-48(s0)
    80003060:	6928                	ld	a0,80(a0)
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	610080e7          	jalr	1552(ra) # 80001672 <copyout>
    return -1;
    8000306a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000306c:	00054f63          	bltz	a0,8000308a <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003070:	4691                	li	a3,4
    80003072:	fc040613          	addi	a2,s0,-64
    80003076:	fc843583          	ld	a1,-56(s0)
    8000307a:	68a8                	ld	a0,80(s1)
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	5f6080e7          	jalr	1526(ra) # 80001672 <copyout>
    80003084:	00054a63          	bltz	a0,80003098 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003088:	87ca                	mv	a5,s2
}
    8000308a:	853e                	mv	a0,a5
    8000308c:	70e2                	ld	ra,56(sp)
    8000308e:	7442                	ld	s0,48(sp)
    80003090:	74a2                	ld	s1,40(sp)
    80003092:	7902                	ld	s2,32(sp)
    80003094:	6121                	addi	sp,sp,64
    80003096:	8082                	ret
    return -1;
    80003098:	57fd                	li	a5,-1
    8000309a:	bfc5                	j	8000308a <sys_waitx+0x9c>

000000008000309c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000309c:	7179                	addi	sp,sp,-48
    8000309e:	f406                	sd	ra,40(sp)
    800030a0:	f022                	sd	s0,32(sp)
    800030a2:	ec26                	sd	s1,24(sp)
    800030a4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800030a6:	fdc40593          	addi	a1,s0,-36
    800030aa:	4501                	li	a0,0
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	ca6080e7          	jalr	-858(ra) # 80002d52 <argint>
    800030b4:	87aa                	mv	a5,a0
    return -1;
    800030b6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030b8:	0207c063          	bltz	a5,800030d8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	8f4080e7          	jalr	-1804(ra) # 800019b0 <myproc>
    800030c4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800030c6:	fdc42503          	lw	a0,-36(s0)
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	c6a080e7          	jalr	-918(ra) # 80001d34 <growproc>
    800030d2:	00054863          	bltz	a0,800030e2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800030d6:	8526                	mv	a0,s1
}
    800030d8:	70a2                	ld	ra,40(sp)
    800030da:	7402                	ld	s0,32(sp)
    800030dc:	64e2                	ld	s1,24(sp)
    800030de:	6145                	addi	sp,sp,48
    800030e0:	8082                	ret
    return -1;
    800030e2:	557d                	li	a0,-1
    800030e4:	bfd5                	j	800030d8 <sys_sbrk+0x3c>

00000000800030e6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030e6:	7139                	addi	sp,sp,-64
    800030e8:	fc06                	sd	ra,56(sp)
    800030ea:	f822                	sd	s0,48(sp)
    800030ec:	f426                	sd	s1,40(sp)
    800030ee:	f04a                	sd	s2,32(sp)
    800030f0:	ec4e                	sd	s3,24(sp)
    800030f2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800030f4:	fcc40593          	addi	a1,s0,-52
    800030f8:	4501                	li	a0,0
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	c58080e7          	jalr	-936(ra) # 80002d52 <argint>
    return -1;
    80003102:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003104:	06054563          	bltz	a0,8000316e <sys_sleep+0x88>
  acquire(&tickslock);
    80003108:	00015517          	auipc	a0,0x15
    8000310c:	9c850513          	addi	a0,a0,-1592 # 80017ad0 <tickslock>
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	ad4080e7          	jalr	-1324(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003118:	00006917          	auipc	s2,0x6
    8000311c:	f1892903          	lw	s2,-232(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003120:	fcc42783          	lw	a5,-52(s0)
    80003124:	cf85                	beqz	a5,8000315c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003126:	00015997          	auipc	s3,0x15
    8000312a:	9aa98993          	addi	s3,s3,-1622 # 80017ad0 <tickslock>
    8000312e:	00006497          	auipc	s1,0x6
    80003132:	f0248493          	addi	s1,s1,-254 # 80009030 <ticks>
    if(myproc()->killed){
    80003136:	fffff097          	auipc	ra,0xfffff
    8000313a:	87a080e7          	jalr	-1926(ra) # 800019b0 <myproc>
    8000313e:	551c                	lw	a5,40(a0)
    80003140:	ef9d                	bnez	a5,8000317e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003142:	85ce                	mv	a1,s3
    80003144:	8526                	mv	a0,s1
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	0bc080e7          	jalr	188(ra) # 80002202 <sleep>
  while(ticks - ticks0 < n){
    8000314e:	409c                	lw	a5,0(s1)
    80003150:	412787bb          	subw	a5,a5,s2
    80003154:	fcc42703          	lw	a4,-52(s0)
    80003158:	fce7efe3          	bltu	a5,a4,80003136 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000315c:	00015517          	auipc	a0,0x15
    80003160:	97450513          	addi	a0,a0,-1676 # 80017ad0 <tickslock>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b34080e7          	jalr	-1228(ra) # 80000c98 <release>
  return 0;
    8000316c:	4781                	li	a5,0
}
    8000316e:	853e                	mv	a0,a5
    80003170:	70e2                	ld	ra,56(sp)
    80003172:	7442                	ld	s0,48(sp)
    80003174:	74a2                	ld	s1,40(sp)
    80003176:	7902                	ld	s2,32(sp)
    80003178:	69e2                	ld	s3,24(sp)
    8000317a:	6121                	addi	sp,sp,64
    8000317c:	8082                	ret
      release(&tickslock);
    8000317e:	00015517          	auipc	a0,0x15
    80003182:	95250513          	addi	a0,a0,-1710 # 80017ad0 <tickslock>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
      return -1;
    8000318e:	57fd                	li	a5,-1
    80003190:	bff9                	j	8000316e <sys_sleep+0x88>

0000000080003192 <sys_kill>:

uint64
sys_kill(void)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000319a:	fec40593          	addi	a1,s0,-20
    8000319e:	4501                	li	a0,0
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	bb2080e7          	jalr	-1102(ra) # 80002d52 <argint>
    800031a8:	87aa                	mv	a5,a0
    return -1;
    800031aa:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031ac:	0007c863          	bltz	a5,800031bc <sys_kill+0x2a>
  return kill(pid);
    800031b0:	fec42503          	lw	a0,-20(s0)
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	4ec080e7          	jalr	1260(ra) # 800026a0 <kill>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret

00000000800031c4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031c4:	1101                	addi	sp,sp,-32
    800031c6:	ec06                	sd	ra,24(sp)
    800031c8:	e822                	sd	s0,16(sp)
    800031ca:	e426                	sd	s1,8(sp)
    800031cc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031ce:	00015517          	auipc	a0,0x15
    800031d2:	90250513          	addi	a0,a0,-1790 # 80017ad0 <tickslock>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	a0e080e7          	jalr	-1522(ra) # 80000be4 <acquire>
  xticks = ticks;
    800031de:	00006497          	auipc	s1,0x6
    800031e2:	e524a483          	lw	s1,-430(s1) # 80009030 <ticks>
  release(&tickslock);
    800031e6:	00015517          	auipc	a0,0x15
    800031ea:	8ea50513          	addi	a0,a0,-1814 # 80017ad0 <tickslock>
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
  return xticks;
}
    800031f6:	02049513          	slli	a0,s1,0x20
    800031fa:	9101                	srli	a0,a0,0x20
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	64a2                	ld	s1,8(sp)
    80003202:	6105                	addi	sp,sp,32
    80003204:	8082                	ret

0000000080003206 <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    80003206:	1101                	addi	sp,sp,-32
    80003208:	ec06                	sd	ra,24(sp)
    8000320a:	e822                	sd	s0,16(sp)
    8000320c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    8000320e:	fec40593          	addi	a1,s0,-20
    80003212:	4501                	li	a0,0
    80003214:	00000097          	auipc	ra,0x0
    80003218:	b3e080e7          	jalr	-1218(ra) # 80002d52 <argint>
  trace(n);
    8000321c:	fec42503          	lw	a0,-20(s0)
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	658080e7          	jalr	1624(ra) # 80002878 <trace>
  return 0; // if the syscall is successful, return 0
}
    80003228:	4501                	li	a0,0
    8000322a:	60e2                	ld	ra,24(sp)
    8000322c:	6442                	ld	s0,16(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret

0000000080003232 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003232:	7179                	addi	sp,sp,-48
    80003234:	f406                	sd	ra,40(sp)
    80003236:	f022                	sd	s0,32(sp)
    80003238:	ec26                	sd	s1,24(sp)
    8000323a:	e84a                	sd	s2,16(sp)
    8000323c:	e44e                	sd	s3,8(sp)
    8000323e:	e052                	sd	s4,0(sp)
    80003240:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003242:	00005597          	auipc	a1,0x5
    80003246:	39e58593          	addi	a1,a1,926 # 800085e0 <syscalls+0xc0>
    8000324a:	00015517          	auipc	a0,0x15
    8000324e:	89e50513          	addi	a0,a0,-1890 # 80017ae8 <bcache>
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	902080e7          	jalr	-1790(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000325a:	0001d797          	auipc	a5,0x1d
    8000325e:	88e78793          	addi	a5,a5,-1906 # 8001fae8 <bcache+0x8000>
    80003262:	0001d717          	auipc	a4,0x1d
    80003266:	aee70713          	addi	a4,a4,-1298 # 8001fd50 <bcache+0x8268>
    8000326a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000326e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003272:	00015497          	auipc	s1,0x15
    80003276:	88e48493          	addi	s1,s1,-1906 # 80017b00 <bcache+0x18>
    b->next = bcache.head.next;
    8000327a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000327c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000327e:	00005a17          	auipc	s4,0x5
    80003282:	36aa0a13          	addi	s4,s4,874 # 800085e8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003286:	2b893783          	ld	a5,696(s2)
    8000328a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000328c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003290:	85d2                	mv	a1,s4
    80003292:	01048513          	addi	a0,s1,16
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	4bc080e7          	jalr	1212(ra) # 80004752 <initsleeplock>
    bcache.head.next->prev = b;
    8000329e:	2b893783          	ld	a5,696(s2)
    800032a2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032a4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032a8:	45848493          	addi	s1,s1,1112
    800032ac:	fd349de3          	bne	s1,s3,80003286 <binit+0x54>
  }
}
    800032b0:	70a2                	ld	ra,40(sp)
    800032b2:	7402                	ld	s0,32(sp)
    800032b4:	64e2                	ld	s1,24(sp)
    800032b6:	6942                	ld	s2,16(sp)
    800032b8:	69a2                	ld	s3,8(sp)
    800032ba:	6a02                	ld	s4,0(sp)
    800032bc:	6145                	addi	sp,sp,48
    800032be:	8082                	ret

00000000800032c0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032c0:	7179                	addi	sp,sp,-48
    800032c2:	f406                	sd	ra,40(sp)
    800032c4:	f022                	sd	s0,32(sp)
    800032c6:	ec26                	sd	s1,24(sp)
    800032c8:	e84a                	sd	s2,16(sp)
    800032ca:	e44e                	sd	s3,8(sp)
    800032cc:	1800                	addi	s0,sp,48
    800032ce:	89aa                	mv	s3,a0
    800032d0:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800032d2:	00015517          	auipc	a0,0x15
    800032d6:	81650513          	addi	a0,a0,-2026 # 80017ae8 <bcache>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	90a080e7          	jalr	-1782(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032e2:	0001d497          	auipc	s1,0x1d
    800032e6:	abe4b483          	ld	s1,-1346(s1) # 8001fda0 <bcache+0x82b8>
    800032ea:	0001d797          	auipc	a5,0x1d
    800032ee:	a6678793          	addi	a5,a5,-1434 # 8001fd50 <bcache+0x8268>
    800032f2:	02f48f63          	beq	s1,a5,80003330 <bread+0x70>
    800032f6:	873e                	mv	a4,a5
    800032f8:	a021                	j	80003300 <bread+0x40>
    800032fa:	68a4                	ld	s1,80(s1)
    800032fc:	02e48a63          	beq	s1,a4,80003330 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003300:	449c                	lw	a5,8(s1)
    80003302:	ff379ce3          	bne	a5,s3,800032fa <bread+0x3a>
    80003306:	44dc                	lw	a5,12(s1)
    80003308:	ff2799e3          	bne	a5,s2,800032fa <bread+0x3a>
      b->refcnt++;
    8000330c:	40bc                	lw	a5,64(s1)
    8000330e:	2785                	addiw	a5,a5,1
    80003310:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003312:	00014517          	auipc	a0,0x14
    80003316:	7d650513          	addi	a0,a0,2006 # 80017ae8 <bcache>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003322:	01048513          	addi	a0,s1,16
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	466080e7          	jalr	1126(ra) # 8000478c <acquiresleep>
      return b;
    8000332e:	a8b9                	j	8000338c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003330:	0001d497          	auipc	s1,0x1d
    80003334:	a684b483          	ld	s1,-1432(s1) # 8001fd98 <bcache+0x82b0>
    80003338:	0001d797          	auipc	a5,0x1d
    8000333c:	a1878793          	addi	a5,a5,-1512 # 8001fd50 <bcache+0x8268>
    80003340:	00f48863          	beq	s1,a5,80003350 <bread+0x90>
    80003344:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003346:	40bc                	lw	a5,64(s1)
    80003348:	cf81                	beqz	a5,80003360 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000334a:	64a4                	ld	s1,72(s1)
    8000334c:	fee49de3          	bne	s1,a4,80003346 <bread+0x86>
  panic("bget: no buffers");
    80003350:	00005517          	auipc	a0,0x5
    80003354:	2a050513          	addi	a0,a0,672 # 800085f0 <syscalls+0xd0>
    80003358:	ffffd097          	auipc	ra,0xffffd
    8000335c:	1e6080e7          	jalr	486(ra) # 8000053e <panic>
      b->dev = dev;
    80003360:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003364:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003368:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000336c:	4785                	li	a5,1
    8000336e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003370:	00014517          	auipc	a0,0x14
    80003374:	77850513          	addi	a0,a0,1912 # 80017ae8 <bcache>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003380:	01048513          	addi	a0,s1,16
    80003384:	00001097          	auipc	ra,0x1
    80003388:	408080e7          	jalr	1032(ra) # 8000478c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000338c:	409c                	lw	a5,0(s1)
    8000338e:	cb89                	beqz	a5,800033a0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003390:	8526                	mv	a0,s1
    80003392:	70a2                	ld	ra,40(sp)
    80003394:	7402                	ld	s0,32(sp)
    80003396:	64e2                	ld	s1,24(sp)
    80003398:	6942                	ld	s2,16(sp)
    8000339a:	69a2                	ld	s3,8(sp)
    8000339c:	6145                	addi	sp,sp,48
    8000339e:	8082                	ret
    virtio_disk_rw(b, 0);
    800033a0:	4581                	li	a1,0
    800033a2:	8526                	mv	a0,s1
    800033a4:	00003097          	auipc	ra,0x3
    800033a8:	f12080e7          	jalr	-238(ra) # 800062b6 <virtio_disk_rw>
    b->valid = 1;
    800033ac:	4785                	li	a5,1
    800033ae:	c09c                	sw	a5,0(s1)
  return b;
    800033b0:	b7c5                	j	80003390 <bread+0xd0>

00000000800033b2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033b2:	1101                	addi	sp,sp,-32
    800033b4:	ec06                	sd	ra,24(sp)
    800033b6:	e822                	sd	s0,16(sp)
    800033b8:	e426                	sd	s1,8(sp)
    800033ba:	1000                	addi	s0,sp,32
    800033bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033be:	0541                	addi	a0,a0,16
    800033c0:	00001097          	auipc	ra,0x1
    800033c4:	466080e7          	jalr	1126(ra) # 80004826 <holdingsleep>
    800033c8:	cd01                	beqz	a0,800033e0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033ca:	4585                	li	a1,1
    800033cc:	8526                	mv	a0,s1
    800033ce:	00003097          	auipc	ra,0x3
    800033d2:	ee8080e7          	jalr	-280(ra) # 800062b6 <virtio_disk_rw>
}
    800033d6:	60e2                	ld	ra,24(sp)
    800033d8:	6442                	ld	s0,16(sp)
    800033da:	64a2                	ld	s1,8(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret
    panic("bwrite");
    800033e0:	00005517          	auipc	a0,0x5
    800033e4:	22850513          	addi	a0,a0,552 # 80008608 <syscalls+0xe8>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	156080e7          	jalr	342(ra) # 8000053e <panic>

00000000800033f0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033f0:	1101                	addi	sp,sp,-32
    800033f2:	ec06                	sd	ra,24(sp)
    800033f4:	e822                	sd	s0,16(sp)
    800033f6:	e426                	sd	s1,8(sp)
    800033f8:	e04a                	sd	s2,0(sp)
    800033fa:	1000                	addi	s0,sp,32
    800033fc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033fe:	01050913          	addi	s2,a0,16
    80003402:	854a                	mv	a0,s2
    80003404:	00001097          	auipc	ra,0x1
    80003408:	422080e7          	jalr	1058(ra) # 80004826 <holdingsleep>
    8000340c:	c92d                	beqz	a0,8000347e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000340e:	854a                	mv	a0,s2
    80003410:	00001097          	auipc	ra,0x1
    80003414:	3d2080e7          	jalr	978(ra) # 800047e2 <releasesleep>

  acquire(&bcache.lock);
    80003418:	00014517          	auipc	a0,0x14
    8000341c:	6d050513          	addi	a0,a0,1744 # 80017ae8 <bcache>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003428:	40bc                	lw	a5,64(s1)
    8000342a:	37fd                	addiw	a5,a5,-1
    8000342c:	0007871b          	sext.w	a4,a5
    80003430:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003432:	eb05                	bnez	a4,80003462 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003434:	68bc                	ld	a5,80(s1)
    80003436:	64b8                	ld	a4,72(s1)
    80003438:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000343a:	64bc                	ld	a5,72(s1)
    8000343c:	68b8                	ld	a4,80(s1)
    8000343e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003440:	0001c797          	auipc	a5,0x1c
    80003444:	6a878793          	addi	a5,a5,1704 # 8001fae8 <bcache+0x8000>
    80003448:	2b87b703          	ld	a4,696(a5)
    8000344c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000344e:	0001d717          	auipc	a4,0x1d
    80003452:	90270713          	addi	a4,a4,-1790 # 8001fd50 <bcache+0x8268>
    80003456:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003458:	2b87b703          	ld	a4,696(a5)
    8000345c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000345e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003462:	00014517          	auipc	a0,0x14
    80003466:	68650513          	addi	a0,a0,1670 # 80017ae8 <bcache>
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	82e080e7          	jalr	-2002(ra) # 80000c98 <release>
}
    80003472:	60e2                	ld	ra,24(sp)
    80003474:	6442                	ld	s0,16(sp)
    80003476:	64a2                	ld	s1,8(sp)
    80003478:	6902                	ld	s2,0(sp)
    8000347a:	6105                	addi	sp,sp,32
    8000347c:	8082                	ret
    panic("brelse");
    8000347e:	00005517          	auipc	a0,0x5
    80003482:	19250513          	addi	a0,a0,402 # 80008610 <syscalls+0xf0>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	0b8080e7          	jalr	184(ra) # 8000053e <panic>

000000008000348e <bpin>:

void
bpin(struct buf *b) {
    8000348e:	1101                	addi	sp,sp,-32
    80003490:	ec06                	sd	ra,24(sp)
    80003492:	e822                	sd	s0,16(sp)
    80003494:	e426                	sd	s1,8(sp)
    80003496:	1000                	addi	s0,sp,32
    80003498:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000349a:	00014517          	auipc	a0,0x14
    8000349e:	64e50513          	addi	a0,a0,1614 # 80017ae8 <bcache>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	742080e7          	jalr	1858(ra) # 80000be4 <acquire>
  b->refcnt++;
    800034aa:	40bc                	lw	a5,64(s1)
    800034ac:	2785                	addiw	a5,a5,1
    800034ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034b0:	00014517          	auipc	a0,0x14
    800034b4:	63850513          	addi	a0,a0,1592 # 80017ae8 <bcache>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	7e0080e7          	jalr	2016(ra) # 80000c98 <release>
}
    800034c0:	60e2                	ld	ra,24(sp)
    800034c2:	6442                	ld	s0,16(sp)
    800034c4:	64a2                	ld	s1,8(sp)
    800034c6:	6105                	addi	sp,sp,32
    800034c8:	8082                	ret

00000000800034ca <bunpin>:

void
bunpin(struct buf *b) {
    800034ca:	1101                	addi	sp,sp,-32
    800034cc:	ec06                	sd	ra,24(sp)
    800034ce:	e822                	sd	s0,16(sp)
    800034d0:	e426                	sd	s1,8(sp)
    800034d2:	1000                	addi	s0,sp,32
    800034d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	61250513          	addi	a0,a0,1554 # 80017ae8 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	706080e7          	jalr	1798(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034e6:	40bc                	lw	a5,64(s1)
    800034e8:	37fd                	addiw	a5,a5,-1
    800034ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034ec:	00014517          	auipc	a0,0x14
    800034f0:	5fc50513          	addi	a0,a0,1532 # 80017ae8 <bcache>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>
}
    800034fc:	60e2                	ld	ra,24(sp)
    800034fe:	6442                	ld	s0,16(sp)
    80003500:	64a2                	ld	s1,8(sp)
    80003502:	6105                	addi	sp,sp,32
    80003504:	8082                	ret

0000000080003506 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003506:	1101                	addi	sp,sp,-32
    80003508:	ec06                	sd	ra,24(sp)
    8000350a:	e822                	sd	s0,16(sp)
    8000350c:	e426                	sd	s1,8(sp)
    8000350e:	e04a                	sd	s2,0(sp)
    80003510:	1000                	addi	s0,sp,32
    80003512:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003514:	00d5d59b          	srliw	a1,a1,0xd
    80003518:	0001d797          	auipc	a5,0x1d
    8000351c:	cac7a783          	lw	a5,-852(a5) # 800201c4 <sb+0x1c>
    80003520:	9dbd                	addw	a1,a1,a5
    80003522:	00000097          	auipc	ra,0x0
    80003526:	d9e080e7          	jalr	-610(ra) # 800032c0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000352a:	0074f713          	andi	a4,s1,7
    8000352e:	4785                	li	a5,1
    80003530:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003534:	14ce                	slli	s1,s1,0x33
    80003536:	90d9                	srli	s1,s1,0x36
    80003538:	00950733          	add	a4,a0,s1
    8000353c:	05874703          	lbu	a4,88(a4)
    80003540:	00e7f6b3          	and	a3,a5,a4
    80003544:	c69d                	beqz	a3,80003572 <bfree+0x6c>
    80003546:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003548:	94aa                	add	s1,s1,a0
    8000354a:	fff7c793          	not	a5,a5
    8000354e:	8ff9                	and	a5,a5,a4
    80003550:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003554:	00001097          	auipc	ra,0x1
    80003558:	118080e7          	jalr	280(ra) # 8000466c <log_write>
  brelse(bp);
    8000355c:	854a                	mv	a0,s2
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	e92080e7          	jalr	-366(ra) # 800033f0 <brelse>
}
    80003566:	60e2                	ld	ra,24(sp)
    80003568:	6442                	ld	s0,16(sp)
    8000356a:	64a2                	ld	s1,8(sp)
    8000356c:	6902                	ld	s2,0(sp)
    8000356e:	6105                	addi	sp,sp,32
    80003570:	8082                	ret
    panic("freeing free block");
    80003572:	00005517          	auipc	a0,0x5
    80003576:	0a650513          	addi	a0,a0,166 # 80008618 <syscalls+0xf8>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>

0000000080003582 <balloc>:
{
    80003582:	711d                	addi	sp,sp,-96
    80003584:	ec86                	sd	ra,88(sp)
    80003586:	e8a2                	sd	s0,80(sp)
    80003588:	e4a6                	sd	s1,72(sp)
    8000358a:	e0ca                	sd	s2,64(sp)
    8000358c:	fc4e                	sd	s3,56(sp)
    8000358e:	f852                	sd	s4,48(sp)
    80003590:	f456                	sd	s5,40(sp)
    80003592:	f05a                	sd	s6,32(sp)
    80003594:	ec5e                	sd	s7,24(sp)
    80003596:	e862                	sd	s8,16(sp)
    80003598:	e466                	sd	s9,8(sp)
    8000359a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000359c:	0001d797          	auipc	a5,0x1d
    800035a0:	c107a783          	lw	a5,-1008(a5) # 800201ac <sb+0x4>
    800035a4:	cbd1                	beqz	a5,80003638 <balloc+0xb6>
    800035a6:	8baa                	mv	s7,a0
    800035a8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035aa:	0001db17          	auipc	s6,0x1d
    800035ae:	bfeb0b13          	addi	s6,s6,-1026 # 800201a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035b4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035b8:	6c89                	lui	s9,0x2
    800035ba:	a831                	j	800035d6 <balloc+0x54>
    brelse(bp);
    800035bc:	854a                	mv	a0,s2
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	e32080e7          	jalr	-462(ra) # 800033f0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035c6:	015c87bb          	addw	a5,s9,s5
    800035ca:	00078a9b          	sext.w	s5,a5
    800035ce:	004b2703          	lw	a4,4(s6)
    800035d2:	06eaf363          	bgeu	s5,a4,80003638 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035d6:	41fad79b          	sraiw	a5,s5,0x1f
    800035da:	0137d79b          	srliw	a5,a5,0x13
    800035de:	015787bb          	addw	a5,a5,s5
    800035e2:	40d7d79b          	sraiw	a5,a5,0xd
    800035e6:	01cb2583          	lw	a1,28(s6)
    800035ea:	9dbd                	addw	a1,a1,a5
    800035ec:	855e                	mv	a0,s7
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	cd2080e7          	jalr	-814(ra) # 800032c0 <bread>
    800035f6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f8:	004b2503          	lw	a0,4(s6)
    800035fc:	000a849b          	sext.w	s1,s5
    80003600:	8662                	mv	a2,s8
    80003602:	faa4fde3          	bgeu	s1,a0,800035bc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003606:	41f6579b          	sraiw	a5,a2,0x1f
    8000360a:	01d7d69b          	srliw	a3,a5,0x1d
    8000360e:	00c6873b          	addw	a4,a3,a2
    80003612:	00777793          	andi	a5,a4,7
    80003616:	9f95                	subw	a5,a5,a3
    80003618:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000361c:	4037571b          	sraiw	a4,a4,0x3
    80003620:	00e906b3          	add	a3,s2,a4
    80003624:	0586c683          	lbu	a3,88(a3)
    80003628:	00d7f5b3          	and	a1,a5,a3
    8000362c:	cd91                	beqz	a1,80003648 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000362e:	2605                	addiw	a2,a2,1
    80003630:	2485                	addiw	s1,s1,1
    80003632:	fd4618e3          	bne	a2,s4,80003602 <balloc+0x80>
    80003636:	b759                	j	800035bc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	ff850513          	addi	a0,a0,-8 # 80008630 <syscalls+0x110>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	efe080e7          	jalr	-258(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003648:	974a                	add	a4,a4,s2
    8000364a:	8fd5                	or	a5,a5,a3
    8000364c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003650:	854a                	mv	a0,s2
    80003652:	00001097          	auipc	ra,0x1
    80003656:	01a080e7          	jalr	26(ra) # 8000466c <log_write>
        brelse(bp);
    8000365a:	854a                	mv	a0,s2
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	d94080e7          	jalr	-620(ra) # 800033f0 <brelse>
  bp = bread(dev, bno);
    80003664:	85a6                	mv	a1,s1
    80003666:	855e                	mv	a0,s7
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	c58080e7          	jalr	-936(ra) # 800032c0 <bread>
    80003670:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003672:	40000613          	li	a2,1024
    80003676:	4581                	li	a1,0
    80003678:	05850513          	addi	a0,a0,88
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	664080e7          	jalr	1636(ra) # 80000ce0 <memset>
  log_write(bp);
    80003684:	854a                	mv	a0,s2
    80003686:	00001097          	auipc	ra,0x1
    8000368a:	fe6080e7          	jalr	-26(ra) # 8000466c <log_write>
  brelse(bp);
    8000368e:	854a                	mv	a0,s2
    80003690:	00000097          	auipc	ra,0x0
    80003694:	d60080e7          	jalr	-672(ra) # 800033f0 <brelse>
}
    80003698:	8526                	mv	a0,s1
    8000369a:	60e6                	ld	ra,88(sp)
    8000369c:	6446                	ld	s0,80(sp)
    8000369e:	64a6                	ld	s1,72(sp)
    800036a0:	6906                	ld	s2,64(sp)
    800036a2:	79e2                	ld	s3,56(sp)
    800036a4:	7a42                	ld	s4,48(sp)
    800036a6:	7aa2                	ld	s5,40(sp)
    800036a8:	7b02                	ld	s6,32(sp)
    800036aa:	6be2                	ld	s7,24(sp)
    800036ac:	6c42                	ld	s8,16(sp)
    800036ae:	6ca2                	ld	s9,8(sp)
    800036b0:	6125                	addi	sp,sp,96
    800036b2:	8082                	ret

00000000800036b4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036b4:	7179                	addi	sp,sp,-48
    800036b6:	f406                	sd	ra,40(sp)
    800036b8:	f022                	sd	s0,32(sp)
    800036ba:	ec26                	sd	s1,24(sp)
    800036bc:	e84a                	sd	s2,16(sp)
    800036be:	e44e                	sd	s3,8(sp)
    800036c0:	e052                	sd	s4,0(sp)
    800036c2:	1800                	addi	s0,sp,48
    800036c4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036c6:	47ad                	li	a5,11
    800036c8:	04b7fe63          	bgeu	a5,a1,80003724 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036cc:	ff45849b          	addiw	s1,a1,-12
    800036d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036d4:	0ff00793          	li	a5,255
    800036d8:	0ae7e363          	bltu	a5,a4,8000377e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036dc:	08052583          	lw	a1,128(a0)
    800036e0:	c5ad                	beqz	a1,8000374a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036e2:	00092503          	lw	a0,0(s2)
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	bda080e7          	jalr	-1062(ra) # 800032c0 <bread>
    800036ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036f4:	02049593          	slli	a1,s1,0x20
    800036f8:	9181                	srli	a1,a1,0x20
    800036fa:	058a                	slli	a1,a1,0x2
    800036fc:	00b784b3          	add	s1,a5,a1
    80003700:	0004a983          	lw	s3,0(s1)
    80003704:	04098d63          	beqz	s3,8000375e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003708:	8552                	mv	a0,s4
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	ce6080e7          	jalr	-794(ra) # 800033f0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003712:	854e                	mv	a0,s3
    80003714:	70a2                	ld	ra,40(sp)
    80003716:	7402                	ld	s0,32(sp)
    80003718:	64e2                	ld	s1,24(sp)
    8000371a:	6942                	ld	s2,16(sp)
    8000371c:	69a2                	ld	s3,8(sp)
    8000371e:	6a02                	ld	s4,0(sp)
    80003720:	6145                	addi	sp,sp,48
    80003722:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003724:	02059493          	slli	s1,a1,0x20
    80003728:	9081                	srli	s1,s1,0x20
    8000372a:	048a                	slli	s1,s1,0x2
    8000372c:	94aa                	add	s1,s1,a0
    8000372e:	0504a983          	lw	s3,80(s1)
    80003732:	fe0990e3          	bnez	s3,80003712 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003736:	4108                	lw	a0,0(a0)
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	e4a080e7          	jalr	-438(ra) # 80003582 <balloc>
    80003740:	0005099b          	sext.w	s3,a0
    80003744:	0534a823          	sw	s3,80(s1)
    80003748:	b7e9                	j	80003712 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000374a:	4108                	lw	a0,0(a0)
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	e36080e7          	jalr	-458(ra) # 80003582 <balloc>
    80003754:	0005059b          	sext.w	a1,a0
    80003758:	08b92023          	sw	a1,128(s2)
    8000375c:	b759                	j	800036e2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000375e:	00092503          	lw	a0,0(s2)
    80003762:	00000097          	auipc	ra,0x0
    80003766:	e20080e7          	jalr	-480(ra) # 80003582 <balloc>
    8000376a:	0005099b          	sext.w	s3,a0
    8000376e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003772:	8552                	mv	a0,s4
    80003774:	00001097          	auipc	ra,0x1
    80003778:	ef8080e7          	jalr	-264(ra) # 8000466c <log_write>
    8000377c:	b771                	j	80003708 <bmap+0x54>
  panic("bmap: out of range");
    8000377e:	00005517          	auipc	a0,0x5
    80003782:	eca50513          	addi	a0,a0,-310 # 80008648 <syscalls+0x128>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	db8080e7          	jalr	-584(ra) # 8000053e <panic>

000000008000378e <iget>:
{
    8000378e:	7179                	addi	sp,sp,-48
    80003790:	f406                	sd	ra,40(sp)
    80003792:	f022                	sd	s0,32(sp)
    80003794:	ec26                	sd	s1,24(sp)
    80003796:	e84a                	sd	s2,16(sp)
    80003798:	e44e                	sd	s3,8(sp)
    8000379a:	e052                	sd	s4,0(sp)
    8000379c:	1800                	addi	s0,sp,48
    8000379e:	89aa                	mv	s3,a0
    800037a0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037a2:	0001d517          	auipc	a0,0x1d
    800037a6:	a2650513          	addi	a0,a0,-1498 # 800201c8 <itable>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	43a080e7          	jalr	1082(ra) # 80000be4 <acquire>
  empty = 0;
    800037b2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037b4:	0001d497          	auipc	s1,0x1d
    800037b8:	a2c48493          	addi	s1,s1,-1492 # 800201e0 <itable+0x18>
    800037bc:	0001e697          	auipc	a3,0x1e
    800037c0:	4b468693          	addi	a3,a3,1204 # 80021c70 <log>
    800037c4:	a039                	j	800037d2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037c6:	02090b63          	beqz	s2,800037fc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ca:	08848493          	addi	s1,s1,136
    800037ce:	02d48a63          	beq	s1,a3,80003802 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037d2:	449c                	lw	a5,8(s1)
    800037d4:	fef059e3          	blez	a5,800037c6 <iget+0x38>
    800037d8:	4098                	lw	a4,0(s1)
    800037da:	ff3716e3          	bne	a4,s3,800037c6 <iget+0x38>
    800037de:	40d8                	lw	a4,4(s1)
    800037e0:	ff4713e3          	bne	a4,s4,800037c6 <iget+0x38>
      ip->ref++;
    800037e4:	2785                	addiw	a5,a5,1
    800037e6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037e8:	0001d517          	auipc	a0,0x1d
    800037ec:	9e050513          	addi	a0,a0,-1568 # 800201c8 <itable>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	4a8080e7          	jalr	1192(ra) # 80000c98 <release>
      return ip;
    800037f8:	8926                	mv	s2,s1
    800037fa:	a03d                	j	80003828 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037fc:	f7f9                	bnez	a5,800037ca <iget+0x3c>
    800037fe:	8926                	mv	s2,s1
    80003800:	b7e9                	j	800037ca <iget+0x3c>
  if(empty == 0)
    80003802:	02090c63          	beqz	s2,8000383a <iget+0xac>
  ip->dev = dev;
    80003806:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000380a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000380e:	4785                	li	a5,1
    80003810:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003814:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003818:	0001d517          	auipc	a0,0x1d
    8000381c:	9b050513          	addi	a0,a0,-1616 # 800201c8 <itable>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	478080e7          	jalr	1144(ra) # 80000c98 <release>
}
    80003828:	854a                	mv	a0,s2
    8000382a:	70a2                	ld	ra,40(sp)
    8000382c:	7402                	ld	s0,32(sp)
    8000382e:	64e2                	ld	s1,24(sp)
    80003830:	6942                	ld	s2,16(sp)
    80003832:	69a2                	ld	s3,8(sp)
    80003834:	6a02                	ld	s4,0(sp)
    80003836:	6145                	addi	sp,sp,48
    80003838:	8082                	ret
    panic("iget: no inodes");
    8000383a:	00005517          	auipc	a0,0x5
    8000383e:	e2650513          	addi	a0,a0,-474 # 80008660 <syscalls+0x140>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	cfc080e7          	jalr	-772(ra) # 8000053e <panic>

000000008000384a <fsinit>:
fsinit(int dev) {
    8000384a:	7179                	addi	sp,sp,-48
    8000384c:	f406                	sd	ra,40(sp)
    8000384e:	f022                	sd	s0,32(sp)
    80003850:	ec26                	sd	s1,24(sp)
    80003852:	e84a                	sd	s2,16(sp)
    80003854:	e44e                	sd	s3,8(sp)
    80003856:	1800                	addi	s0,sp,48
    80003858:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000385a:	4585                	li	a1,1
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	a64080e7          	jalr	-1436(ra) # 800032c0 <bread>
    80003864:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003866:	0001d997          	auipc	s3,0x1d
    8000386a:	94298993          	addi	s3,s3,-1726 # 800201a8 <sb>
    8000386e:	02000613          	li	a2,32
    80003872:	05850593          	addi	a1,a0,88
    80003876:	854e                	mv	a0,s3
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	4c8080e7          	jalr	1224(ra) # 80000d40 <memmove>
  brelse(bp);
    80003880:	8526                	mv	a0,s1
    80003882:	00000097          	auipc	ra,0x0
    80003886:	b6e080e7          	jalr	-1170(ra) # 800033f0 <brelse>
  if(sb.magic != FSMAGIC)
    8000388a:	0009a703          	lw	a4,0(s3)
    8000388e:	102037b7          	lui	a5,0x10203
    80003892:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003896:	02f71263          	bne	a4,a5,800038ba <fsinit+0x70>
  initlog(dev, &sb);
    8000389a:	0001d597          	auipc	a1,0x1d
    8000389e:	90e58593          	addi	a1,a1,-1778 # 800201a8 <sb>
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	b4c080e7          	jalr	-1204(ra) # 800043f0 <initlog>
}
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6942                	ld	s2,16(sp)
    800038b4:	69a2                	ld	s3,8(sp)
    800038b6:	6145                	addi	sp,sp,48
    800038b8:	8082                	ret
    panic("invalid file system");
    800038ba:	00005517          	auipc	a0,0x5
    800038be:	db650513          	addi	a0,a0,-586 # 80008670 <syscalls+0x150>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c7c080e7          	jalr	-900(ra) # 8000053e <panic>

00000000800038ca <iinit>:
{
    800038ca:	7179                	addi	sp,sp,-48
    800038cc:	f406                	sd	ra,40(sp)
    800038ce:	f022                	sd	s0,32(sp)
    800038d0:	ec26                	sd	s1,24(sp)
    800038d2:	e84a                	sd	s2,16(sp)
    800038d4:	e44e                	sd	s3,8(sp)
    800038d6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038d8:	00005597          	auipc	a1,0x5
    800038dc:	db058593          	addi	a1,a1,-592 # 80008688 <syscalls+0x168>
    800038e0:	0001d517          	auipc	a0,0x1d
    800038e4:	8e850513          	addi	a0,a0,-1816 # 800201c8 <itable>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	26c080e7          	jalr	620(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038f0:	0001d497          	auipc	s1,0x1d
    800038f4:	90048493          	addi	s1,s1,-1792 # 800201f0 <itable+0x28>
    800038f8:	0001e997          	auipc	s3,0x1e
    800038fc:	38898993          	addi	s3,s3,904 # 80021c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003900:	00005917          	auipc	s2,0x5
    80003904:	d9090913          	addi	s2,s2,-624 # 80008690 <syscalls+0x170>
    80003908:	85ca                	mv	a1,s2
    8000390a:	8526                	mv	a0,s1
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	e46080e7          	jalr	-442(ra) # 80004752 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003914:	08848493          	addi	s1,s1,136
    80003918:	ff3498e3          	bne	s1,s3,80003908 <iinit+0x3e>
}
    8000391c:	70a2                	ld	ra,40(sp)
    8000391e:	7402                	ld	s0,32(sp)
    80003920:	64e2                	ld	s1,24(sp)
    80003922:	6942                	ld	s2,16(sp)
    80003924:	69a2                	ld	s3,8(sp)
    80003926:	6145                	addi	sp,sp,48
    80003928:	8082                	ret

000000008000392a <ialloc>:
{
    8000392a:	715d                	addi	sp,sp,-80
    8000392c:	e486                	sd	ra,72(sp)
    8000392e:	e0a2                	sd	s0,64(sp)
    80003930:	fc26                	sd	s1,56(sp)
    80003932:	f84a                	sd	s2,48(sp)
    80003934:	f44e                	sd	s3,40(sp)
    80003936:	f052                	sd	s4,32(sp)
    80003938:	ec56                	sd	s5,24(sp)
    8000393a:	e85a                	sd	s6,16(sp)
    8000393c:	e45e                	sd	s7,8(sp)
    8000393e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003940:	0001d717          	auipc	a4,0x1d
    80003944:	87472703          	lw	a4,-1932(a4) # 800201b4 <sb+0xc>
    80003948:	4785                	li	a5,1
    8000394a:	04e7fa63          	bgeu	a5,a4,8000399e <ialloc+0x74>
    8000394e:	8aaa                	mv	s5,a0
    80003950:	8bae                	mv	s7,a1
    80003952:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003954:	0001da17          	auipc	s4,0x1d
    80003958:	854a0a13          	addi	s4,s4,-1964 # 800201a8 <sb>
    8000395c:	00048b1b          	sext.w	s6,s1
    80003960:	0044d593          	srli	a1,s1,0x4
    80003964:	018a2783          	lw	a5,24(s4)
    80003968:	9dbd                	addw	a1,a1,a5
    8000396a:	8556                	mv	a0,s5
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	954080e7          	jalr	-1708(ra) # 800032c0 <bread>
    80003974:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003976:	05850993          	addi	s3,a0,88
    8000397a:	00f4f793          	andi	a5,s1,15
    8000397e:	079a                	slli	a5,a5,0x6
    80003980:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003982:	00099783          	lh	a5,0(s3)
    80003986:	c785                	beqz	a5,800039ae <ialloc+0x84>
    brelse(bp);
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	a68080e7          	jalr	-1432(ra) # 800033f0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003990:	0485                	addi	s1,s1,1
    80003992:	00ca2703          	lw	a4,12(s4)
    80003996:	0004879b          	sext.w	a5,s1
    8000399a:	fce7e1e3          	bltu	a5,a4,8000395c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000399e:	00005517          	auipc	a0,0x5
    800039a2:	cfa50513          	addi	a0,a0,-774 # 80008698 <syscalls+0x178>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	b98080e7          	jalr	-1128(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800039ae:	04000613          	li	a2,64
    800039b2:	4581                	li	a1,0
    800039b4:	854e                	mv	a0,s3
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	32a080e7          	jalr	810(ra) # 80000ce0 <memset>
      dip->type = type;
    800039be:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039c2:	854a                	mv	a0,s2
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	ca8080e7          	jalr	-856(ra) # 8000466c <log_write>
      brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	a22080e7          	jalr	-1502(ra) # 800033f0 <brelse>
      return iget(dev, inum);
    800039d6:	85da                	mv	a1,s6
    800039d8:	8556                	mv	a0,s5
    800039da:	00000097          	auipc	ra,0x0
    800039de:	db4080e7          	jalr	-588(ra) # 8000378e <iget>
}
    800039e2:	60a6                	ld	ra,72(sp)
    800039e4:	6406                	ld	s0,64(sp)
    800039e6:	74e2                	ld	s1,56(sp)
    800039e8:	7942                	ld	s2,48(sp)
    800039ea:	79a2                	ld	s3,40(sp)
    800039ec:	7a02                	ld	s4,32(sp)
    800039ee:	6ae2                	ld	s5,24(sp)
    800039f0:	6b42                	ld	s6,16(sp)
    800039f2:	6ba2                	ld	s7,8(sp)
    800039f4:	6161                	addi	sp,sp,80
    800039f6:	8082                	ret

00000000800039f8 <iupdate>:
{
    800039f8:	1101                	addi	sp,sp,-32
    800039fa:	ec06                	sd	ra,24(sp)
    800039fc:	e822                	sd	s0,16(sp)
    800039fe:	e426                	sd	s1,8(sp)
    80003a00:	e04a                	sd	s2,0(sp)
    80003a02:	1000                	addi	s0,sp,32
    80003a04:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a06:	415c                	lw	a5,4(a0)
    80003a08:	0047d79b          	srliw	a5,a5,0x4
    80003a0c:	0001c597          	auipc	a1,0x1c
    80003a10:	7b45a583          	lw	a1,1972(a1) # 800201c0 <sb+0x18>
    80003a14:	9dbd                	addw	a1,a1,a5
    80003a16:	4108                	lw	a0,0(a0)
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	8a8080e7          	jalr	-1880(ra) # 800032c0 <bread>
    80003a20:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a22:	05850793          	addi	a5,a0,88
    80003a26:	40c8                	lw	a0,4(s1)
    80003a28:	893d                	andi	a0,a0,15
    80003a2a:	051a                	slli	a0,a0,0x6
    80003a2c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a2e:	04449703          	lh	a4,68(s1)
    80003a32:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a36:	04649703          	lh	a4,70(s1)
    80003a3a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a3e:	04849703          	lh	a4,72(s1)
    80003a42:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a46:	04a49703          	lh	a4,74(s1)
    80003a4a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a4e:	44f8                	lw	a4,76(s1)
    80003a50:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a52:	03400613          	li	a2,52
    80003a56:	05048593          	addi	a1,s1,80
    80003a5a:	0531                	addi	a0,a0,12
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	2e4080e7          	jalr	740(ra) # 80000d40 <memmove>
  log_write(bp);
    80003a64:	854a                	mv	a0,s2
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	c06080e7          	jalr	-1018(ra) # 8000466c <log_write>
  brelse(bp);
    80003a6e:	854a                	mv	a0,s2
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	980080e7          	jalr	-1664(ra) # 800033f0 <brelse>
}
    80003a78:	60e2                	ld	ra,24(sp)
    80003a7a:	6442                	ld	s0,16(sp)
    80003a7c:	64a2                	ld	s1,8(sp)
    80003a7e:	6902                	ld	s2,0(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret

0000000080003a84 <idup>:
{
    80003a84:	1101                	addi	sp,sp,-32
    80003a86:	ec06                	sd	ra,24(sp)
    80003a88:	e822                	sd	s0,16(sp)
    80003a8a:	e426                	sd	s1,8(sp)
    80003a8c:	1000                	addi	s0,sp,32
    80003a8e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a90:	0001c517          	auipc	a0,0x1c
    80003a94:	73850513          	addi	a0,a0,1848 # 800201c8 <itable>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	14c080e7          	jalr	332(ra) # 80000be4 <acquire>
  ip->ref++;
    80003aa0:	449c                	lw	a5,8(s1)
    80003aa2:	2785                	addiw	a5,a5,1
    80003aa4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa6:	0001c517          	auipc	a0,0x1c
    80003aaa:	72250513          	addi	a0,a0,1826 # 800201c8 <itable>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	1ea080e7          	jalr	490(ra) # 80000c98 <release>
}
    80003ab6:	8526                	mv	a0,s1
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6105                	addi	sp,sp,32
    80003ac0:	8082                	ret

0000000080003ac2 <ilock>:
{
    80003ac2:	1101                	addi	sp,sp,-32
    80003ac4:	ec06                	sd	ra,24(sp)
    80003ac6:	e822                	sd	s0,16(sp)
    80003ac8:	e426                	sd	s1,8(sp)
    80003aca:	e04a                	sd	s2,0(sp)
    80003acc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ace:	c115                	beqz	a0,80003af2 <ilock+0x30>
    80003ad0:	84aa                	mv	s1,a0
    80003ad2:	451c                	lw	a5,8(a0)
    80003ad4:	00f05f63          	blez	a5,80003af2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ad8:	0541                	addi	a0,a0,16
    80003ada:	00001097          	auipc	ra,0x1
    80003ade:	cb2080e7          	jalr	-846(ra) # 8000478c <acquiresleep>
  if(ip->valid == 0){
    80003ae2:	40bc                	lw	a5,64(s1)
    80003ae4:	cf99                	beqz	a5,80003b02 <ilock+0x40>
}
    80003ae6:	60e2                	ld	ra,24(sp)
    80003ae8:	6442                	ld	s0,16(sp)
    80003aea:	64a2                	ld	s1,8(sp)
    80003aec:	6902                	ld	s2,0(sp)
    80003aee:	6105                	addi	sp,sp,32
    80003af0:	8082                	ret
    panic("ilock");
    80003af2:	00005517          	auipc	a0,0x5
    80003af6:	bbe50513          	addi	a0,a0,-1090 # 800086b0 <syscalls+0x190>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b02:	40dc                	lw	a5,4(s1)
    80003b04:	0047d79b          	srliw	a5,a5,0x4
    80003b08:	0001c597          	auipc	a1,0x1c
    80003b0c:	6b85a583          	lw	a1,1720(a1) # 800201c0 <sb+0x18>
    80003b10:	9dbd                	addw	a1,a1,a5
    80003b12:	4088                	lw	a0,0(s1)
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	7ac080e7          	jalr	1964(ra) # 800032c0 <bread>
    80003b1c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b1e:	05850593          	addi	a1,a0,88
    80003b22:	40dc                	lw	a5,4(s1)
    80003b24:	8bbd                	andi	a5,a5,15
    80003b26:	079a                	slli	a5,a5,0x6
    80003b28:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b2a:	00059783          	lh	a5,0(a1)
    80003b2e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b32:	00259783          	lh	a5,2(a1)
    80003b36:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b3a:	00459783          	lh	a5,4(a1)
    80003b3e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b42:	00659783          	lh	a5,6(a1)
    80003b46:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b4a:	459c                	lw	a5,8(a1)
    80003b4c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b4e:	03400613          	li	a2,52
    80003b52:	05b1                	addi	a1,a1,12
    80003b54:	05048513          	addi	a0,s1,80
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	1e8080e7          	jalr	488(ra) # 80000d40 <memmove>
    brelse(bp);
    80003b60:	854a                	mv	a0,s2
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	88e080e7          	jalr	-1906(ra) # 800033f0 <brelse>
    ip->valid = 1;
    80003b6a:	4785                	li	a5,1
    80003b6c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b6e:	04449783          	lh	a5,68(s1)
    80003b72:	fbb5                	bnez	a5,80003ae6 <ilock+0x24>
      panic("ilock: no type");
    80003b74:	00005517          	auipc	a0,0x5
    80003b78:	b4450513          	addi	a0,a0,-1212 # 800086b8 <syscalls+0x198>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	9c2080e7          	jalr	-1598(ra) # 8000053e <panic>

0000000080003b84 <iunlock>:
{
    80003b84:	1101                	addi	sp,sp,-32
    80003b86:	ec06                	sd	ra,24(sp)
    80003b88:	e822                	sd	s0,16(sp)
    80003b8a:	e426                	sd	s1,8(sp)
    80003b8c:	e04a                	sd	s2,0(sp)
    80003b8e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b90:	c905                	beqz	a0,80003bc0 <iunlock+0x3c>
    80003b92:	84aa                	mv	s1,a0
    80003b94:	01050913          	addi	s2,a0,16
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00001097          	auipc	ra,0x1
    80003b9e:	c8c080e7          	jalr	-884(ra) # 80004826 <holdingsleep>
    80003ba2:	cd19                	beqz	a0,80003bc0 <iunlock+0x3c>
    80003ba4:	449c                	lw	a5,8(s1)
    80003ba6:	00f05d63          	blez	a5,80003bc0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003baa:	854a                	mv	a0,s2
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	c36080e7          	jalr	-970(ra) # 800047e2 <releasesleep>
}
    80003bb4:	60e2                	ld	ra,24(sp)
    80003bb6:	6442                	ld	s0,16(sp)
    80003bb8:	64a2                	ld	s1,8(sp)
    80003bba:	6902                	ld	s2,0(sp)
    80003bbc:	6105                	addi	sp,sp,32
    80003bbe:	8082                	ret
    panic("iunlock");
    80003bc0:	00005517          	auipc	a0,0x5
    80003bc4:	b0850513          	addi	a0,a0,-1272 # 800086c8 <syscalls+0x1a8>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	976080e7          	jalr	-1674(ra) # 8000053e <panic>

0000000080003bd0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bd0:	7179                	addi	sp,sp,-48
    80003bd2:	f406                	sd	ra,40(sp)
    80003bd4:	f022                	sd	s0,32(sp)
    80003bd6:	ec26                	sd	s1,24(sp)
    80003bd8:	e84a                	sd	s2,16(sp)
    80003bda:	e44e                	sd	s3,8(sp)
    80003bdc:	e052                	sd	s4,0(sp)
    80003bde:	1800                	addi	s0,sp,48
    80003be0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003be2:	05050493          	addi	s1,a0,80
    80003be6:	08050913          	addi	s2,a0,128
    80003bea:	a021                	j	80003bf2 <itrunc+0x22>
    80003bec:	0491                	addi	s1,s1,4
    80003bee:	01248d63          	beq	s1,s2,80003c08 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bf2:	408c                	lw	a1,0(s1)
    80003bf4:	dde5                	beqz	a1,80003bec <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bf6:	0009a503          	lw	a0,0(s3)
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	90c080e7          	jalr	-1780(ra) # 80003506 <bfree>
      ip->addrs[i] = 0;
    80003c02:	0004a023          	sw	zero,0(s1)
    80003c06:	b7dd                	j	80003bec <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c08:	0809a583          	lw	a1,128(s3)
    80003c0c:	e185                	bnez	a1,80003c2c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c0e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c12:	854e                	mv	a0,s3
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	de4080e7          	jalr	-540(ra) # 800039f8 <iupdate>
}
    80003c1c:	70a2                	ld	ra,40(sp)
    80003c1e:	7402                	ld	s0,32(sp)
    80003c20:	64e2                	ld	s1,24(sp)
    80003c22:	6942                	ld	s2,16(sp)
    80003c24:	69a2                	ld	s3,8(sp)
    80003c26:	6a02                	ld	s4,0(sp)
    80003c28:	6145                	addi	sp,sp,48
    80003c2a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c2c:	0009a503          	lw	a0,0(s3)
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	690080e7          	jalr	1680(ra) # 800032c0 <bread>
    80003c38:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c3a:	05850493          	addi	s1,a0,88
    80003c3e:	45850913          	addi	s2,a0,1112
    80003c42:	a811                	j	80003c56 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c44:	0009a503          	lw	a0,0(s3)
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	8be080e7          	jalr	-1858(ra) # 80003506 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003c50:	0491                	addi	s1,s1,4
    80003c52:	01248563          	beq	s1,s2,80003c5c <itrunc+0x8c>
      if(a[j])
    80003c56:	408c                	lw	a1,0(s1)
    80003c58:	dde5                	beqz	a1,80003c50 <itrunc+0x80>
    80003c5a:	b7ed                	j	80003c44 <itrunc+0x74>
    brelse(bp);
    80003c5c:	8552                	mv	a0,s4
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	792080e7          	jalr	1938(ra) # 800033f0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c66:	0809a583          	lw	a1,128(s3)
    80003c6a:	0009a503          	lw	a0,0(s3)
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	898080e7          	jalr	-1896(ra) # 80003506 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c76:	0809a023          	sw	zero,128(s3)
    80003c7a:	bf51                	j	80003c0e <itrunc+0x3e>

0000000080003c7c <iput>:
{
    80003c7c:	1101                	addi	sp,sp,-32
    80003c7e:	ec06                	sd	ra,24(sp)
    80003c80:	e822                	sd	s0,16(sp)
    80003c82:	e426                	sd	s1,8(sp)
    80003c84:	e04a                	sd	s2,0(sp)
    80003c86:	1000                	addi	s0,sp,32
    80003c88:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c8a:	0001c517          	auipc	a0,0x1c
    80003c8e:	53e50513          	addi	a0,a0,1342 # 800201c8 <itable>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	f52080e7          	jalr	-174(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c9a:	4498                	lw	a4,8(s1)
    80003c9c:	4785                	li	a5,1
    80003c9e:	02f70363          	beq	a4,a5,80003cc4 <iput+0x48>
  ip->ref--;
    80003ca2:	449c                	lw	a5,8(s1)
    80003ca4:	37fd                	addiw	a5,a5,-1
    80003ca6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ca8:	0001c517          	auipc	a0,0x1c
    80003cac:	52050513          	addi	a0,a0,1312 # 800201c8 <itable>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	fe8080e7          	jalr	-24(ra) # 80000c98 <release>
}
    80003cb8:	60e2                	ld	ra,24(sp)
    80003cba:	6442                	ld	s0,16(sp)
    80003cbc:	64a2                	ld	s1,8(sp)
    80003cbe:	6902                	ld	s2,0(sp)
    80003cc0:	6105                	addi	sp,sp,32
    80003cc2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cc4:	40bc                	lw	a5,64(s1)
    80003cc6:	dff1                	beqz	a5,80003ca2 <iput+0x26>
    80003cc8:	04a49783          	lh	a5,74(s1)
    80003ccc:	fbf9                	bnez	a5,80003ca2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003cce:	01048913          	addi	s2,s1,16
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	00001097          	auipc	ra,0x1
    80003cd8:	ab8080e7          	jalr	-1352(ra) # 8000478c <acquiresleep>
    release(&itable.lock);
    80003cdc:	0001c517          	auipc	a0,0x1c
    80003ce0:	4ec50513          	addi	a0,a0,1260 # 800201c8 <itable>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	fb4080e7          	jalr	-76(ra) # 80000c98 <release>
    itrunc(ip);
    80003cec:	8526                	mv	a0,s1
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	ee2080e7          	jalr	-286(ra) # 80003bd0 <itrunc>
    ip->type = 0;
    80003cf6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cfa:	8526                	mv	a0,s1
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	cfc080e7          	jalr	-772(ra) # 800039f8 <iupdate>
    ip->valid = 0;
    80003d04:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d08:	854a                	mv	a0,s2
    80003d0a:	00001097          	auipc	ra,0x1
    80003d0e:	ad8080e7          	jalr	-1320(ra) # 800047e2 <releasesleep>
    acquire(&itable.lock);
    80003d12:	0001c517          	auipc	a0,0x1c
    80003d16:	4b650513          	addi	a0,a0,1206 # 800201c8 <itable>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	eca080e7          	jalr	-310(ra) # 80000be4 <acquire>
    80003d22:	b741                	j	80003ca2 <iput+0x26>

0000000080003d24 <iunlockput>:
{
    80003d24:	1101                	addi	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	1000                	addi	s0,sp,32
    80003d2e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	e54080e7          	jalr	-428(ra) # 80003b84 <iunlock>
  iput(ip);
    80003d38:	8526                	mv	a0,s1
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	f42080e7          	jalr	-190(ra) # 80003c7c <iput>
}
    80003d42:	60e2                	ld	ra,24(sp)
    80003d44:	6442                	ld	s0,16(sp)
    80003d46:	64a2                	ld	s1,8(sp)
    80003d48:	6105                	addi	sp,sp,32
    80003d4a:	8082                	ret

0000000080003d4c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d4c:	1141                	addi	sp,sp,-16
    80003d4e:	e422                	sd	s0,8(sp)
    80003d50:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d52:	411c                	lw	a5,0(a0)
    80003d54:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d56:	415c                	lw	a5,4(a0)
    80003d58:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d5a:	04451783          	lh	a5,68(a0)
    80003d5e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d62:	04a51783          	lh	a5,74(a0)
    80003d66:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d6a:	04c56783          	lwu	a5,76(a0)
    80003d6e:	e99c                	sd	a5,16(a1)
}
    80003d70:	6422                	ld	s0,8(sp)
    80003d72:	0141                	addi	sp,sp,16
    80003d74:	8082                	ret

0000000080003d76 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d76:	457c                	lw	a5,76(a0)
    80003d78:	0ed7e963          	bltu	a5,a3,80003e6a <readi+0xf4>
{
    80003d7c:	7159                	addi	sp,sp,-112
    80003d7e:	f486                	sd	ra,104(sp)
    80003d80:	f0a2                	sd	s0,96(sp)
    80003d82:	eca6                	sd	s1,88(sp)
    80003d84:	e8ca                	sd	s2,80(sp)
    80003d86:	e4ce                	sd	s3,72(sp)
    80003d88:	e0d2                	sd	s4,64(sp)
    80003d8a:	fc56                	sd	s5,56(sp)
    80003d8c:	f85a                	sd	s6,48(sp)
    80003d8e:	f45e                	sd	s7,40(sp)
    80003d90:	f062                	sd	s8,32(sp)
    80003d92:	ec66                	sd	s9,24(sp)
    80003d94:	e86a                	sd	s10,16(sp)
    80003d96:	e46e                	sd	s11,8(sp)
    80003d98:	1880                	addi	s0,sp,112
    80003d9a:	8baa                	mv	s7,a0
    80003d9c:	8c2e                	mv	s8,a1
    80003d9e:	8ab2                	mv	s5,a2
    80003da0:	84b6                	mv	s1,a3
    80003da2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003da4:	9f35                	addw	a4,a4,a3
    return 0;
    80003da6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003da8:	0ad76063          	bltu	a4,a3,80003e48 <readi+0xd2>
  if(off + n > ip->size)
    80003dac:	00e7f463          	bgeu	a5,a4,80003db4 <readi+0x3e>
    n = ip->size - off;
    80003db0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003db4:	0a0b0963          	beqz	s6,80003e66 <readi+0xf0>
    80003db8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dba:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dbe:	5cfd                	li	s9,-1
    80003dc0:	a82d                	j	80003dfa <readi+0x84>
    80003dc2:	020a1d93          	slli	s11,s4,0x20
    80003dc6:	020ddd93          	srli	s11,s11,0x20
    80003dca:	05890613          	addi	a2,s2,88
    80003dce:	86ee                	mv	a3,s11
    80003dd0:	963a                	add	a2,a2,a4
    80003dd2:	85d6                	mv	a1,s5
    80003dd4:	8562                	mv	a0,s8
    80003dd6:	fffff097          	auipc	ra,0xfffff
    80003dda:	948080e7          	jalr	-1720(ra) # 8000271e <either_copyout>
    80003dde:	05950d63          	beq	a0,s9,80003e38 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003de2:	854a                	mv	a0,s2
    80003de4:	fffff097          	auipc	ra,0xfffff
    80003de8:	60c080e7          	jalr	1548(ra) # 800033f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dec:	013a09bb          	addw	s3,s4,s3
    80003df0:	009a04bb          	addw	s1,s4,s1
    80003df4:	9aee                	add	s5,s5,s11
    80003df6:	0569f763          	bgeu	s3,s6,80003e44 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dfa:	000ba903          	lw	s2,0(s7)
    80003dfe:	00a4d59b          	srliw	a1,s1,0xa
    80003e02:	855e                	mv	a0,s7
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	8b0080e7          	jalr	-1872(ra) # 800036b4 <bmap>
    80003e0c:	0005059b          	sext.w	a1,a0
    80003e10:	854a                	mv	a0,s2
    80003e12:	fffff097          	auipc	ra,0xfffff
    80003e16:	4ae080e7          	jalr	1198(ra) # 800032c0 <bread>
    80003e1a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e1c:	3ff4f713          	andi	a4,s1,1023
    80003e20:	40ed07bb          	subw	a5,s10,a4
    80003e24:	413b06bb          	subw	a3,s6,s3
    80003e28:	8a3e                	mv	s4,a5
    80003e2a:	2781                	sext.w	a5,a5
    80003e2c:	0006861b          	sext.w	a2,a3
    80003e30:	f8f679e3          	bgeu	a2,a5,80003dc2 <readi+0x4c>
    80003e34:	8a36                	mv	s4,a3
    80003e36:	b771                	j	80003dc2 <readi+0x4c>
      brelse(bp);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	5b6080e7          	jalr	1462(ra) # 800033f0 <brelse>
      tot = -1;
    80003e42:	59fd                	li	s3,-1
  }
  return tot;
    80003e44:	0009851b          	sext.w	a0,s3
}
    80003e48:	70a6                	ld	ra,104(sp)
    80003e4a:	7406                	ld	s0,96(sp)
    80003e4c:	64e6                	ld	s1,88(sp)
    80003e4e:	6946                	ld	s2,80(sp)
    80003e50:	69a6                	ld	s3,72(sp)
    80003e52:	6a06                	ld	s4,64(sp)
    80003e54:	7ae2                	ld	s5,56(sp)
    80003e56:	7b42                	ld	s6,48(sp)
    80003e58:	7ba2                	ld	s7,40(sp)
    80003e5a:	7c02                	ld	s8,32(sp)
    80003e5c:	6ce2                	ld	s9,24(sp)
    80003e5e:	6d42                	ld	s10,16(sp)
    80003e60:	6da2                	ld	s11,8(sp)
    80003e62:	6165                	addi	sp,sp,112
    80003e64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e66:	89da                	mv	s3,s6
    80003e68:	bff1                	j	80003e44 <readi+0xce>
    return 0;
    80003e6a:	4501                	li	a0,0
}
    80003e6c:	8082                	ret

0000000080003e6e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e6e:	457c                	lw	a5,76(a0)
    80003e70:	10d7e863          	bltu	a5,a3,80003f80 <writei+0x112>
{
    80003e74:	7159                	addi	sp,sp,-112
    80003e76:	f486                	sd	ra,104(sp)
    80003e78:	f0a2                	sd	s0,96(sp)
    80003e7a:	eca6                	sd	s1,88(sp)
    80003e7c:	e8ca                	sd	s2,80(sp)
    80003e7e:	e4ce                	sd	s3,72(sp)
    80003e80:	e0d2                	sd	s4,64(sp)
    80003e82:	fc56                	sd	s5,56(sp)
    80003e84:	f85a                	sd	s6,48(sp)
    80003e86:	f45e                	sd	s7,40(sp)
    80003e88:	f062                	sd	s8,32(sp)
    80003e8a:	ec66                	sd	s9,24(sp)
    80003e8c:	e86a                	sd	s10,16(sp)
    80003e8e:	e46e                	sd	s11,8(sp)
    80003e90:	1880                	addi	s0,sp,112
    80003e92:	8b2a                	mv	s6,a0
    80003e94:	8c2e                	mv	s8,a1
    80003e96:	8ab2                	mv	s5,a2
    80003e98:	8936                	mv	s2,a3
    80003e9a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e9c:	00e687bb          	addw	a5,a3,a4
    80003ea0:	0ed7e263          	bltu	a5,a3,80003f84 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ea4:	00043737          	lui	a4,0x43
    80003ea8:	0ef76063          	bltu	a4,a5,80003f88 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eac:	0c0b8863          	beqz	s7,80003f7c <writei+0x10e>
    80003eb0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eb6:	5cfd                	li	s9,-1
    80003eb8:	a091                	j	80003efc <writei+0x8e>
    80003eba:	02099d93          	slli	s11,s3,0x20
    80003ebe:	020ddd93          	srli	s11,s11,0x20
    80003ec2:	05848513          	addi	a0,s1,88
    80003ec6:	86ee                	mv	a3,s11
    80003ec8:	8656                	mv	a2,s5
    80003eca:	85e2                	mv	a1,s8
    80003ecc:	953a                	add	a0,a0,a4
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	8a6080e7          	jalr	-1882(ra) # 80002774 <either_copyin>
    80003ed6:	07950263          	beq	a0,s9,80003f3a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003eda:	8526                	mv	a0,s1
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	790080e7          	jalr	1936(ra) # 8000466c <log_write>
    brelse(bp);
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	50a080e7          	jalr	1290(ra) # 800033f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eee:	01498a3b          	addw	s4,s3,s4
    80003ef2:	0129893b          	addw	s2,s3,s2
    80003ef6:	9aee                	add	s5,s5,s11
    80003ef8:	057a7663          	bgeu	s4,s7,80003f44 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003efc:	000b2483          	lw	s1,0(s6)
    80003f00:	00a9559b          	srliw	a1,s2,0xa
    80003f04:	855a                	mv	a0,s6
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	7ae080e7          	jalr	1966(ra) # 800036b4 <bmap>
    80003f0e:	0005059b          	sext.w	a1,a0
    80003f12:	8526                	mv	a0,s1
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	3ac080e7          	jalr	940(ra) # 800032c0 <bread>
    80003f1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f1e:	3ff97713          	andi	a4,s2,1023
    80003f22:	40ed07bb          	subw	a5,s10,a4
    80003f26:	414b86bb          	subw	a3,s7,s4
    80003f2a:	89be                	mv	s3,a5
    80003f2c:	2781                	sext.w	a5,a5
    80003f2e:	0006861b          	sext.w	a2,a3
    80003f32:	f8f674e3          	bgeu	a2,a5,80003eba <writei+0x4c>
    80003f36:	89b6                	mv	s3,a3
    80003f38:	b749                	j	80003eba <writei+0x4c>
      brelse(bp);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	4b4080e7          	jalr	1204(ra) # 800033f0 <brelse>
  }

  if(off > ip->size)
    80003f44:	04cb2783          	lw	a5,76(s6)
    80003f48:	0127f463          	bgeu	a5,s2,80003f50 <writei+0xe2>
    ip->size = off;
    80003f4c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f50:	855a                	mv	a0,s6
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	aa6080e7          	jalr	-1370(ra) # 800039f8 <iupdate>

  return tot;
    80003f5a:	000a051b          	sext.w	a0,s4
}
    80003f5e:	70a6                	ld	ra,104(sp)
    80003f60:	7406                	ld	s0,96(sp)
    80003f62:	64e6                	ld	s1,88(sp)
    80003f64:	6946                	ld	s2,80(sp)
    80003f66:	69a6                	ld	s3,72(sp)
    80003f68:	6a06                	ld	s4,64(sp)
    80003f6a:	7ae2                	ld	s5,56(sp)
    80003f6c:	7b42                	ld	s6,48(sp)
    80003f6e:	7ba2                	ld	s7,40(sp)
    80003f70:	7c02                	ld	s8,32(sp)
    80003f72:	6ce2                	ld	s9,24(sp)
    80003f74:	6d42                	ld	s10,16(sp)
    80003f76:	6da2                	ld	s11,8(sp)
    80003f78:	6165                	addi	sp,sp,112
    80003f7a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7c:	8a5e                	mv	s4,s7
    80003f7e:	bfc9                	j	80003f50 <writei+0xe2>
    return -1;
    80003f80:	557d                	li	a0,-1
}
    80003f82:	8082                	ret
    return -1;
    80003f84:	557d                	li	a0,-1
    80003f86:	bfe1                	j	80003f5e <writei+0xf0>
    return -1;
    80003f88:	557d                	li	a0,-1
    80003f8a:	bfd1                	j	80003f5e <writei+0xf0>

0000000080003f8c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f8c:	1141                	addi	sp,sp,-16
    80003f8e:	e406                	sd	ra,8(sp)
    80003f90:	e022                	sd	s0,0(sp)
    80003f92:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f94:	4639                	li	a2,14
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	e22080e7          	jalr	-478(ra) # 80000db8 <strncmp>
}
    80003f9e:	60a2                	ld	ra,8(sp)
    80003fa0:	6402                	ld	s0,0(sp)
    80003fa2:	0141                	addi	sp,sp,16
    80003fa4:	8082                	ret

0000000080003fa6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fa6:	7139                	addi	sp,sp,-64
    80003fa8:	fc06                	sd	ra,56(sp)
    80003faa:	f822                	sd	s0,48(sp)
    80003fac:	f426                	sd	s1,40(sp)
    80003fae:	f04a                	sd	s2,32(sp)
    80003fb0:	ec4e                	sd	s3,24(sp)
    80003fb2:	e852                	sd	s4,16(sp)
    80003fb4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fb6:	04451703          	lh	a4,68(a0)
    80003fba:	4785                	li	a5,1
    80003fbc:	00f71a63          	bne	a4,a5,80003fd0 <dirlookup+0x2a>
    80003fc0:	892a                	mv	s2,a0
    80003fc2:	89ae                	mv	s3,a1
    80003fc4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc6:	457c                	lw	a5,76(a0)
    80003fc8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fca:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fcc:	e79d                	bnez	a5,80003ffa <dirlookup+0x54>
    80003fce:	a8a5                	j	80004046 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fd0:	00004517          	auipc	a0,0x4
    80003fd4:	70050513          	addi	a0,a0,1792 # 800086d0 <syscalls+0x1b0>
    80003fd8:	ffffc097          	auipc	ra,0xffffc
    80003fdc:	566080e7          	jalr	1382(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003fe0:	00004517          	auipc	a0,0x4
    80003fe4:	70850513          	addi	a0,a0,1800 # 800086e8 <syscalls+0x1c8>
    80003fe8:	ffffc097          	auipc	ra,0xffffc
    80003fec:	556080e7          	jalr	1366(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff0:	24c1                	addiw	s1,s1,16
    80003ff2:	04c92783          	lw	a5,76(s2)
    80003ff6:	04f4f763          	bgeu	s1,a5,80004044 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffa:	4741                	li	a4,16
    80003ffc:	86a6                	mv	a3,s1
    80003ffe:	fc040613          	addi	a2,s0,-64
    80004002:	4581                	li	a1,0
    80004004:	854a                	mv	a0,s2
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	d70080e7          	jalr	-656(ra) # 80003d76 <readi>
    8000400e:	47c1                	li	a5,16
    80004010:	fcf518e3          	bne	a0,a5,80003fe0 <dirlookup+0x3a>
    if(de.inum == 0)
    80004014:	fc045783          	lhu	a5,-64(s0)
    80004018:	dfe1                	beqz	a5,80003ff0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000401a:	fc240593          	addi	a1,s0,-62
    8000401e:	854e                	mv	a0,s3
    80004020:	00000097          	auipc	ra,0x0
    80004024:	f6c080e7          	jalr	-148(ra) # 80003f8c <namecmp>
    80004028:	f561                	bnez	a0,80003ff0 <dirlookup+0x4a>
      if(poff)
    8000402a:	000a0463          	beqz	s4,80004032 <dirlookup+0x8c>
        *poff = off;
    8000402e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004032:	fc045583          	lhu	a1,-64(s0)
    80004036:	00092503          	lw	a0,0(s2)
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	754080e7          	jalr	1876(ra) # 8000378e <iget>
    80004042:	a011                	j	80004046 <dirlookup+0xa0>
  return 0;
    80004044:	4501                	li	a0,0
}
    80004046:	70e2                	ld	ra,56(sp)
    80004048:	7442                	ld	s0,48(sp)
    8000404a:	74a2                	ld	s1,40(sp)
    8000404c:	7902                	ld	s2,32(sp)
    8000404e:	69e2                	ld	s3,24(sp)
    80004050:	6a42                	ld	s4,16(sp)
    80004052:	6121                	addi	sp,sp,64
    80004054:	8082                	ret

0000000080004056 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004056:	711d                	addi	sp,sp,-96
    80004058:	ec86                	sd	ra,88(sp)
    8000405a:	e8a2                	sd	s0,80(sp)
    8000405c:	e4a6                	sd	s1,72(sp)
    8000405e:	e0ca                	sd	s2,64(sp)
    80004060:	fc4e                	sd	s3,56(sp)
    80004062:	f852                	sd	s4,48(sp)
    80004064:	f456                	sd	s5,40(sp)
    80004066:	f05a                	sd	s6,32(sp)
    80004068:	ec5e                	sd	s7,24(sp)
    8000406a:	e862                	sd	s8,16(sp)
    8000406c:	e466                	sd	s9,8(sp)
    8000406e:	1080                	addi	s0,sp,96
    80004070:	84aa                	mv	s1,a0
    80004072:	8b2e                	mv	s6,a1
    80004074:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004076:	00054703          	lbu	a4,0(a0)
    8000407a:	02f00793          	li	a5,47
    8000407e:	02f70363          	beq	a4,a5,800040a4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004082:	ffffe097          	auipc	ra,0xffffe
    80004086:	92e080e7          	jalr	-1746(ra) # 800019b0 <myproc>
    8000408a:	15053503          	ld	a0,336(a0)
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	9f6080e7          	jalr	-1546(ra) # 80003a84 <idup>
    80004096:	89aa                	mv	s3,a0
  while(*path == '/')
    80004098:	02f00913          	li	s2,47
  len = path - s;
    8000409c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000409e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040a0:	4c05                	li	s8,1
    800040a2:	a865                	j	8000415a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040a4:	4585                	li	a1,1
    800040a6:	4505                	li	a0,1
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	6e6080e7          	jalr	1766(ra) # 8000378e <iget>
    800040b0:	89aa                	mv	s3,a0
    800040b2:	b7dd                	j	80004098 <namex+0x42>
      iunlockput(ip);
    800040b4:	854e                	mv	a0,s3
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	c6e080e7          	jalr	-914(ra) # 80003d24 <iunlockput>
      return 0;
    800040be:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040c0:	854e                	mv	a0,s3
    800040c2:	60e6                	ld	ra,88(sp)
    800040c4:	6446                	ld	s0,80(sp)
    800040c6:	64a6                	ld	s1,72(sp)
    800040c8:	6906                	ld	s2,64(sp)
    800040ca:	79e2                	ld	s3,56(sp)
    800040cc:	7a42                	ld	s4,48(sp)
    800040ce:	7aa2                	ld	s5,40(sp)
    800040d0:	7b02                	ld	s6,32(sp)
    800040d2:	6be2                	ld	s7,24(sp)
    800040d4:	6c42                	ld	s8,16(sp)
    800040d6:	6ca2                	ld	s9,8(sp)
    800040d8:	6125                	addi	sp,sp,96
    800040da:	8082                	ret
      iunlock(ip);
    800040dc:	854e                	mv	a0,s3
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	aa6080e7          	jalr	-1370(ra) # 80003b84 <iunlock>
      return ip;
    800040e6:	bfe9                	j	800040c0 <namex+0x6a>
      iunlockput(ip);
    800040e8:	854e                	mv	a0,s3
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	c3a080e7          	jalr	-966(ra) # 80003d24 <iunlockput>
      return 0;
    800040f2:	89d2                	mv	s3,s4
    800040f4:	b7f1                	j	800040c0 <namex+0x6a>
  len = path - s;
    800040f6:	40b48633          	sub	a2,s1,a1
    800040fa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800040fe:	094cd463          	bge	s9,s4,80004186 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004102:	4639                	li	a2,14
    80004104:	8556                	mv	a0,s5
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	c3a080e7          	jalr	-966(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000410e:	0004c783          	lbu	a5,0(s1)
    80004112:	01279763          	bne	a5,s2,80004120 <namex+0xca>
    path++;
    80004116:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004118:	0004c783          	lbu	a5,0(s1)
    8000411c:	ff278de3          	beq	a5,s2,80004116 <namex+0xc0>
    ilock(ip);
    80004120:	854e                	mv	a0,s3
    80004122:	00000097          	auipc	ra,0x0
    80004126:	9a0080e7          	jalr	-1632(ra) # 80003ac2 <ilock>
    if(ip->type != T_DIR){
    8000412a:	04499783          	lh	a5,68(s3)
    8000412e:	f98793e3          	bne	a5,s8,800040b4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004132:	000b0563          	beqz	s6,8000413c <namex+0xe6>
    80004136:	0004c783          	lbu	a5,0(s1)
    8000413a:	d3cd                	beqz	a5,800040dc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000413c:	865e                	mv	a2,s7
    8000413e:	85d6                	mv	a1,s5
    80004140:	854e                	mv	a0,s3
    80004142:	00000097          	auipc	ra,0x0
    80004146:	e64080e7          	jalr	-412(ra) # 80003fa6 <dirlookup>
    8000414a:	8a2a                	mv	s4,a0
    8000414c:	dd51                	beqz	a0,800040e8 <namex+0x92>
    iunlockput(ip);
    8000414e:	854e                	mv	a0,s3
    80004150:	00000097          	auipc	ra,0x0
    80004154:	bd4080e7          	jalr	-1068(ra) # 80003d24 <iunlockput>
    ip = next;
    80004158:	89d2                	mv	s3,s4
  while(*path == '/')
    8000415a:	0004c783          	lbu	a5,0(s1)
    8000415e:	05279763          	bne	a5,s2,800041ac <namex+0x156>
    path++;
    80004162:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004164:	0004c783          	lbu	a5,0(s1)
    80004168:	ff278de3          	beq	a5,s2,80004162 <namex+0x10c>
  if(*path == 0)
    8000416c:	c79d                	beqz	a5,8000419a <namex+0x144>
    path++;
    8000416e:	85a6                	mv	a1,s1
  len = path - s;
    80004170:	8a5e                	mv	s4,s7
    80004172:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004174:	01278963          	beq	a5,s2,80004186 <namex+0x130>
    80004178:	dfbd                	beqz	a5,800040f6 <namex+0xa0>
    path++;
    8000417a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000417c:	0004c783          	lbu	a5,0(s1)
    80004180:	ff279ce3          	bne	a5,s2,80004178 <namex+0x122>
    80004184:	bf8d                	j	800040f6 <namex+0xa0>
    memmove(name, s, len);
    80004186:	2601                	sext.w	a2,a2
    80004188:	8556                	mv	a0,s5
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	bb6080e7          	jalr	-1098(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004192:	9a56                	add	s4,s4,s5
    80004194:	000a0023          	sb	zero,0(s4)
    80004198:	bf9d                	j	8000410e <namex+0xb8>
  if(nameiparent){
    8000419a:	f20b03e3          	beqz	s6,800040c0 <namex+0x6a>
    iput(ip);
    8000419e:	854e                	mv	a0,s3
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	adc080e7          	jalr	-1316(ra) # 80003c7c <iput>
    return 0;
    800041a8:	4981                	li	s3,0
    800041aa:	bf19                	j	800040c0 <namex+0x6a>
  if(*path == 0)
    800041ac:	d7fd                	beqz	a5,8000419a <namex+0x144>
  while(*path != '/' && *path != 0)
    800041ae:	0004c783          	lbu	a5,0(s1)
    800041b2:	85a6                	mv	a1,s1
    800041b4:	b7d1                	j	80004178 <namex+0x122>

00000000800041b6 <dirlink>:
{
    800041b6:	7139                	addi	sp,sp,-64
    800041b8:	fc06                	sd	ra,56(sp)
    800041ba:	f822                	sd	s0,48(sp)
    800041bc:	f426                	sd	s1,40(sp)
    800041be:	f04a                	sd	s2,32(sp)
    800041c0:	ec4e                	sd	s3,24(sp)
    800041c2:	e852                	sd	s4,16(sp)
    800041c4:	0080                	addi	s0,sp,64
    800041c6:	892a                	mv	s2,a0
    800041c8:	8a2e                	mv	s4,a1
    800041ca:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041cc:	4601                	li	a2,0
    800041ce:	00000097          	auipc	ra,0x0
    800041d2:	dd8080e7          	jalr	-552(ra) # 80003fa6 <dirlookup>
    800041d6:	e93d                	bnez	a0,8000424c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d8:	04c92483          	lw	s1,76(s2)
    800041dc:	c49d                	beqz	s1,8000420a <dirlink+0x54>
    800041de:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041e0:	4741                	li	a4,16
    800041e2:	86a6                	mv	a3,s1
    800041e4:	fc040613          	addi	a2,s0,-64
    800041e8:	4581                	li	a1,0
    800041ea:	854a                	mv	a0,s2
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	b8a080e7          	jalr	-1142(ra) # 80003d76 <readi>
    800041f4:	47c1                	li	a5,16
    800041f6:	06f51163          	bne	a0,a5,80004258 <dirlink+0xa2>
    if(de.inum == 0)
    800041fa:	fc045783          	lhu	a5,-64(s0)
    800041fe:	c791                	beqz	a5,8000420a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004200:	24c1                	addiw	s1,s1,16
    80004202:	04c92783          	lw	a5,76(s2)
    80004206:	fcf4ede3          	bltu	s1,a5,800041e0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000420a:	4639                	li	a2,14
    8000420c:	85d2                	mv	a1,s4
    8000420e:	fc240513          	addi	a0,s0,-62
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	be2080e7          	jalr	-1054(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000421a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000421e:	4741                	li	a4,16
    80004220:	86a6                	mv	a3,s1
    80004222:	fc040613          	addi	a2,s0,-64
    80004226:	4581                	li	a1,0
    80004228:	854a                	mv	a0,s2
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	c44080e7          	jalr	-956(ra) # 80003e6e <writei>
    80004232:	872a                	mv	a4,a0
    80004234:	47c1                	li	a5,16
  return 0;
    80004236:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004238:	02f71863          	bne	a4,a5,80004268 <dirlink+0xb2>
}
    8000423c:	70e2                	ld	ra,56(sp)
    8000423e:	7442                	ld	s0,48(sp)
    80004240:	74a2                	ld	s1,40(sp)
    80004242:	7902                	ld	s2,32(sp)
    80004244:	69e2                	ld	s3,24(sp)
    80004246:	6a42                	ld	s4,16(sp)
    80004248:	6121                	addi	sp,sp,64
    8000424a:	8082                	ret
    iput(ip);
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	a30080e7          	jalr	-1488(ra) # 80003c7c <iput>
    return -1;
    80004254:	557d                	li	a0,-1
    80004256:	b7dd                	j	8000423c <dirlink+0x86>
      panic("dirlink read");
    80004258:	00004517          	auipc	a0,0x4
    8000425c:	4a050513          	addi	a0,a0,1184 # 800086f8 <syscalls+0x1d8>
    80004260:	ffffc097          	auipc	ra,0xffffc
    80004264:	2de080e7          	jalr	734(ra) # 8000053e <panic>
    panic("dirlink");
    80004268:	00004517          	auipc	a0,0x4
    8000426c:	59850513          	addi	a0,a0,1432 # 80008800 <syscalls+0x2e0>
    80004270:	ffffc097          	auipc	ra,0xffffc
    80004274:	2ce080e7          	jalr	718(ra) # 8000053e <panic>

0000000080004278 <namei>:

struct inode*
namei(char *path)
{
    80004278:	1101                	addi	sp,sp,-32
    8000427a:	ec06                	sd	ra,24(sp)
    8000427c:	e822                	sd	s0,16(sp)
    8000427e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004280:	fe040613          	addi	a2,s0,-32
    80004284:	4581                	li	a1,0
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	dd0080e7          	jalr	-560(ra) # 80004056 <namex>
}
    8000428e:	60e2                	ld	ra,24(sp)
    80004290:	6442                	ld	s0,16(sp)
    80004292:	6105                	addi	sp,sp,32
    80004294:	8082                	ret

0000000080004296 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004296:	1141                	addi	sp,sp,-16
    80004298:	e406                	sd	ra,8(sp)
    8000429a:	e022                	sd	s0,0(sp)
    8000429c:	0800                	addi	s0,sp,16
    8000429e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042a0:	4585                	li	a1,1
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	db4080e7          	jalr	-588(ra) # 80004056 <namex>
}
    800042aa:	60a2                	ld	ra,8(sp)
    800042ac:	6402                	ld	s0,0(sp)
    800042ae:	0141                	addi	sp,sp,16
    800042b0:	8082                	ret

00000000800042b2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042b2:	1101                	addi	sp,sp,-32
    800042b4:	ec06                	sd	ra,24(sp)
    800042b6:	e822                	sd	s0,16(sp)
    800042b8:	e426                	sd	s1,8(sp)
    800042ba:	e04a                	sd	s2,0(sp)
    800042bc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042be:	0001e917          	auipc	s2,0x1e
    800042c2:	9b290913          	addi	s2,s2,-1614 # 80021c70 <log>
    800042c6:	01892583          	lw	a1,24(s2)
    800042ca:	02892503          	lw	a0,40(s2)
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	ff2080e7          	jalr	-14(ra) # 800032c0 <bread>
    800042d6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042d8:	02c92683          	lw	a3,44(s2)
    800042dc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042de:	02d05763          	blez	a3,8000430c <write_head+0x5a>
    800042e2:	0001e797          	auipc	a5,0x1e
    800042e6:	9be78793          	addi	a5,a5,-1602 # 80021ca0 <log+0x30>
    800042ea:	05c50713          	addi	a4,a0,92
    800042ee:	36fd                	addiw	a3,a3,-1
    800042f0:	1682                	slli	a3,a3,0x20
    800042f2:	9281                	srli	a3,a3,0x20
    800042f4:	068a                	slli	a3,a3,0x2
    800042f6:	0001e617          	auipc	a2,0x1e
    800042fa:	9ae60613          	addi	a2,a2,-1618 # 80021ca4 <log+0x34>
    800042fe:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004300:	4390                	lw	a2,0(a5)
    80004302:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004304:	0791                	addi	a5,a5,4
    80004306:	0711                	addi	a4,a4,4
    80004308:	fed79ce3          	bne	a5,a3,80004300 <write_head+0x4e>
  }
  bwrite(buf);
    8000430c:	8526                	mv	a0,s1
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	0a4080e7          	jalr	164(ra) # 800033b2 <bwrite>
  brelse(buf);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	0d8080e7          	jalr	216(ra) # 800033f0 <brelse>
}
    80004320:	60e2                	ld	ra,24(sp)
    80004322:	6442                	ld	s0,16(sp)
    80004324:	64a2                	ld	s1,8(sp)
    80004326:	6902                	ld	s2,0(sp)
    80004328:	6105                	addi	sp,sp,32
    8000432a:	8082                	ret

000000008000432c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432c:	0001e797          	auipc	a5,0x1e
    80004330:	9707a783          	lw	a5,-1680(a5) # 80021c9c <log+0x2c>
    80004334:	0af05d63          	blez	a5,800043ee <install_trans+0xc2>
{
    80004338:	7139                	addi	sp,sp,-64
    8000433a:	fc06                	sd	ra,56(sp)
    8000433c:	f822                	sd	s0,48(sp)
    8000433e:	f426                	sd	s1,40(sp)
    80004340:	f04a                	sd	s2,32(sp)
    80004342:	ec4e                	sd	s3,24(sp)
    80004344:	e852                	sd	s4,16(sp)
    80004346:	e456                	sd	s5,8(sp)
    80004348:	e05a                	sd	s6,0(sp)
    8000434a:	0080                	addi	s0,sp,64
    8000434c:	8b2a                	mv	s6,a0
    8000434e:	0001ea97          	auipc	s5,0x1e
    80004352:	952a8a93          	addi	s5,s5,-1710 # 80021ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004356:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004358:	0001e997          	auipc	s3,0x1e
    8000435c:	91898993          	addi	s3,s3,-1768 # 80021c70 <log>
    80004360:	a035                	j	8000438c <install_trans+0x60>
      bunpin(dbuf);
    80004362:	8526                	mv	a0,s1
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	166080e7          	jalr	358(ra) # 800034ca <bunpin>
    brelse(lbuf);
    8000436c:	854a                	mv	a0,s2
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	082080e7          	jalr	130(ra) # 800033f0 <brelse>
    brelse(dbuf);
    80004376:	8526                	mv	a0,s1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	078080e7          	jalr	120(ra) # 800033f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004380:	2a05                	addiw	s4,s4,1
    80004382:	0a91                	addi	s5,s5,4
    80004384:	02c9a783          	lw	a5,44(s3)
    80004388:	04fa5963          	bge	s4,a5,800043da <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438c:	0189a583          	lw	a1,24(s3)
    80004390:	014585bb          	addw	a1,a1,s4
    80004394:	2585                	addiw	a1,a1,1
    80004396:	0289a503          	lw	a0,40(s3)
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	f26080e7          	jalr	-218(ra) # 800032c0 <bread>
    800043a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043a4:	000aa583          	lw	a1,0(s5)
    800043a8:	0289a503          	lw	a0,40(s3)
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	f14080e7          	jalr	-236(ra) # 800032c0 <bread>
    800043b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043b6:	40000613          	li	a2,1024
    800043ba:	05890593          	addi	a1,s2,88
    800043be:	05850513          	addi	a0,a0,88
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	97e080e7          	jalr	-1666(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	fe6080e7          	jalr	-26(ra) # 800033b2 <bwrite>
    if(recovering == 0)
    800043d4:	f80b1ce3          	bnez	s6,8000436c <install_trans+0x40>
    800043d8:	b769                	j	80004362 <install_trans+0x36>
}
    800043da:	70e2                	ld	ra,56(sp)
    800043dc:	7442                	ld	s0,48(sp)
    800043de:	74a2                	ld	s1,40(sp)
    800043e0:	7902                	ld	s2,32(sp)
    800043e2:	69e2                	ld	s3,24(sp)
    800043e4:	6a42                	ld	s4,16(sp)
    800043e6:	6aa2                	ld	s5,8(sp)
    800043e8:	6b02                	ld	s6,0(sp)
    800043ea:	6121                	addi	sp,sp,64
    800043ec:	8082                	ret
    800043ee:	8082                	ret

00000000800043f0 <initlog>:
{
    800043f0:	7179                	addi	sp,sp,-48
    800043f2:	f406                	sd	ra,40(sp)
    800043f4:	f022                	sd	s0,32(sp)
    800043f6:	ec26                	sd	s1,24(sp)
    800043f8:	e84a                	sd	s2,16(sp)
    800043fa:	e44e                	sd	s3,8(sp)
    800043fc:	1800                	addi	s0,sp,48
    800043fe:	892a                	mv	s2,a0
    80004400:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004402:	0001e497          	auipc	s1,0x1e
    80004406:	86e48493          	addi	s1,s1,-1938 # 80021c70 <log>
    8000440a:	00004597          	auipc	a1,0x4
    8000440e:	2fe58593          	addi	a1,a1,766 # 80008708 <syscalls+0x1e8>
    80004412:	8526                	mv	a0,s1
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	740080e7          	jalr	1856(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000441c:	0149a583          	lw	a1,20(s3)
    80004420:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004422:	0109a783          	lw	a5,16(s3)
    80004426:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004428:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000442c:	854a                	mv	a0,s2
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	e92080e7          	jalr	-366(ra) # 800032c0 <bread>
  log.lh.n = lh->n;
    80004436:	4d3c                	lw	a5,88(a0)
    80004438:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000443a:	02f05563          	blez	a5,80004464 <initlog+0x74>
    8000443e:	05c50713          	addi	a4,a0,92
    80004442:	0001e697          	auipc	a3,0x1e
    80004446:	85e68693          	addi	a3,a3,-1954 # 80021ca0 <log+0x30>
    8000444a:	37fd                	addiw	a5,a5,-1
    8000444c:	1782                	slli	a5,a5,0x20
    8000444e:	9381                	srli	a5,a5,0x20
    80004450:	078a                	slli	a5,a5,0x2
    80004452:	06050613          	addi	a2,a0,96
    80004456:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004458:	4310                	lw	a2,0(a4)
    8000445a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000445c:	0711                	addi	a4,a4,4
    8000445e:	0691                	addi	a3,a3,4
    80004460:	fef71ce3          	bne	a4,a5,80004458 <initlog+0x68>
  brelse(buf);
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	f8c080e7          	jalr	-116(ra) # 800033f0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000446c:	4505                	li	a0,1
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	ebe080e7          	jalr	-322(ra) # 8000432c <install_trans>
  log.lh.n = 0;
    80004476:	0001e797          	auipc	a5,0x1e
    8000447a:	8207a323          	sw	zero,-2010(a5) # 80021c9c <log+0x2c>
  write_head(); // clear the log
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	e34080e7          	jalr	-460(ra) # 800042b2 <write_head>
}
    80004486:	70a2                	ld	ra,40(sp)
    80004488:	7402                	ld	s0,32(sp)
    8000448a:	64e2                	ld	s1,24(sp)
    8000448c:	6942                	ld	s2,16(sp)
    8000448e:	69a2                	ld	s3,8(sp)
    80004490:	6145                	addi	sp,sp,48
    80004492:	8082                	ret

0000000080004494 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004494:	1101                	addi	sp,sp,-32
    80004496:	ec06                	sd	ra,24(sp)
    80004498:	e822                	sd	s0,16(sp)
    8000449a:	e426                	sd	s1,8(sp)
    8000449c:	e04a                	sd	s2,0(sp)
    8000449e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044a0:	0001d517          	auipc	a0,0x1d
    800044a4:	7d050513          	addi	a0,a0,2000 # 80021c70 <log>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	73c080e7          	jalr	1852(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800044b0:	0001d497          	auipc	s1,0x1d
    800044b4:	7c048493          	addi	s1,s1,1984 # 80021c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044b8:	4979                	li	s2,30
    800044ba:	a039                	j	800044c8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044bc:	85a6                	mv	a1,s1
    800044be:	8526                	mv	a0,s1
    800044c0:	ffffe097          	auipc	ra,0xffffe
    800044c4:	d42080e7          	jalr	-702(ra) # 80002202 <sleep>
    if(log.committing){
    800044c8:	50dc                	lw	a5,36(s1)
    800044ca:	fbed                	bnez	a5,800044bc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044cc:	509c                	lw	a5,32(s1)
    800044ce:	0017871b          	addiw	a4,a5,1
    800044d2:	0007069b          	sext.w	a3,a4
    800044d6:	0027179b          	slliw	a5,a4,0x2
    800044da:	9fb9                	addw	a5,a5,a4
    800044dc:	0017979b          	slliw	a5,a5,0x1
    800044e0:	54d8                	lw	a4,44(s1)
    800044e2:	9fb9                	addw	a5,a5,a4
    800044e4:	00f95963          	bge	s2,a5,800044f6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044e8:	85a6                	mv	a1,s1
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffe097          	auipc	ra,0xffffe
    800044f0:	d16080e7          	jalr	-746(ra) # 80002202 <sleep>
    800044f4:	bfd1                	j	800044c8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044f6:	0001d517          	auipc	a0,0x1d
    800044fa:	77a50513          	addi	a0,a0,1914 # 80021c70 <log>
    800044fe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	798080e7          	jalr	1944(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004508:	60e2                	ld	ra,24(sp)
    8000450a:	6442                	ld	s0,16(sp)
    8000450c:	64a2                	ld	s1,8(sp)
    8000450e:	6902                	ld	s2,0(sp)
    80004510:	6105                	addi	sp,sp,32
    80004512:	8082                	ret

0000000080004514 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004514:	7139                	addi	sp,sp,-64
    80004516:	fc06                	sd	ra,56(sp)
    80004518:	f822                	sd	s0,48(sp)
    8000451a:	f426                	sd	s1,40(sp)
    8000451c:	f04a                	sd	s2,32(sp)
    8000451e:	ec4e                	sd	s3,24(sp)
    80004520:	e852                	sd	s4,16(sp)
    80004522:	e456                	sd	s5,8(sp)
    80004524:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004526:	0001d497          	auipc	s1,0x1d
    8000452a:	74a48493          	addi	s1,s1,1866 # 80021c70 <log>
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004538:	509c                	lw	a5,32(s1)
    8000453a:	37fd                	addiw	a5,a5,-1
    8000453c:	0007891b          	sext.w	s2,a5
    80004540:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004542:	50dc                	lw	a5,36(s1)
    80004544:	efb9                	bnez	a5,800045a2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004546:	06091663          	bnez	s2,800045b2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000454a:	0001d497          	auipc	s1,0x1d
    8000454e:	72648493          	addi	s1,s1,1830 # 80021c70 <log>
    80004552:	4785                	li	a5,1
    80004554:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004556:	8526                	mv	a0,s1
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	740080e7          	jalr	1856(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004560:	54dc                	lw	a5,44(s1)
    80004562:	06f04763          	bgtz	a5,800045d0 <end_op+0xbc>
    acquire(&log.lock);
    80004566:	0001d497          	auipc	s1,0x1d
    8000456a:	70a48493          	addi	s1,s1,1802 # 80021c70 <log>
    8000456e:	8526                	mv	a0,s1
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	674080e7          	jalr	1652(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004578:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffe097          	auipc	ra,0xffffe
    80004582:	f5c080e7          	jalr	-164(ra) # 800024da <wakeup>
    release(&log.lock);
    80004586:	8526                	mv	a0,s1
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
}
    80004590:	70e2                	ld	ra,56(sp)
    80004592:	7442                	ld	s0,48(sp)
    80004594:	74a2                	ld	s1,40(sp)
    80004596:	7902                	ld	s2,32(sp)
    80004598:	69e2                	ld	s3,24(sp)
    8000459a:	6a42                	ld	s4,16(sp)
    8000459c:	6aa2                	ld	s5,8(sp)
    8000459e:	6121                	addi	sp,sp,64
    800045a0:	8082                	ret
    panic("log.committing");
    800045a2:	00004517          	auipc	a0,0x4
    800045a6:	16e50513          	addi	a0,a0,366 # 80008710 <syscalls+0x1f0>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	f94080e7          	jalr	-108(ra) # 8000053e <panic>
    wakeup(&log);
    800045b2:	0001d497          	auipc	s1,0x1d
    800045b6:	6be48493          	addi	s1,s1,1726 # 80021c70 <log>
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffe097          	auipc	ra,0xffffe
    800045c0:	f1e080e7          	jalr	-226(ra) # 800024da <wakeup>
  release(&log.lock);
    800045c4:	8526                	mv	a0,s1
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
  if(do_commit){
    800045ce:	b7c9                	j	80004590 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d0:	0001da97          	auipc	s5,0x1d
    800045d4:	6d0a8a93          	addi	s5,s5,1744 # 80021ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045d8:	0001da17          	auipc	s4,0x1d
    800045dc:	698a0a13          	addi	s4,s4,1688 # 80021c70 <log>
    800045e0:	018a2583          	lw	a1,24(s4)
    800045e4:	012585bb          	addw	a1,a1,s2
    800045e8:	2585                	addiw	a1,a1,1
    800045ea:	028a2503          	lw	a0,40(s4)
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	cd2080e7          	jalr	-814(ra) # 800032c0 <bread>
    800045f6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045f8:	000aa583          	lw	a1,0(s5)
    800045fc:	028a2503          	lw	a0,40(s4)
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	cc0080e7          	jalr	-832(ra) # 800032c0 <bread>
    80004608:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000460a:	40000613          	li	a2,1024
    8000460e:	05850593          	addi	a1,a0,88
    80004612:	05848513          	addi	a0,s1,88
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	72a080e7          	jalr	1834(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000461e:	8526                	mv	a0,s1
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	d92080e7          	jalr	-622(ra) # 800033b2 <bwrite>
    brelse(from);
    80004628:	854e                	mv	a0,s3
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	dc6080e7          	jalr	-570(ra) # 800033f0 <brelse>
    brelse(to);
    80004632:	8526                	mv	a0,s1
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	dbc080e7          	jalr	-580(ra) # 800033f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000463c:	2905                	addiw	s2,s2,1
    8000463e:	0a91                	addi	s5,s5,4
    80004640:	02ca2783          	lw	a5,44(s4)
    80004644:	f8f94ee3          	blt	s2,a5,800045e0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	c6a080e7          	jalr	-918(ra) # 800042b2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004650:	4501                	li	a0,0
    80004652:	00000097          	auipc	ra,0x0
    80004656:	cda080e7          	jalr	-806(ra) # 8000432c <install_trans>
    log.lh.n = 0;
    8000465a:	0001d797          	auipc	a5,0x1d
    8000465e:	6407a123          	sw	zero,1602(a5) # 80021c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004662:	00000097          	auipc	ra,0x0
    80004666:	c50080e7          	jalr	-944(ra) # 800042b2 <write_head>
    8000466a:	bdf5                	j	80004566 <end_op+0x52>

000000008000466c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000466c:	1101                	addi	sp,sp,-32
    8000466e:	ec06                	sd	ra,24(sp)
    80004670:	e822                	sd	s0,16(sp)
    80004672:	e426                	sd	s1,8(sp)
    80004674:	e04a                	sd	s2,0(sp)
    80004676:	1000                	addi	s0,sp,32
    80004678:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000467a:	0001d917          	auipc	s2,0x1d
    8000467e:	5f690913          	addi	s2,s2,1526 # 80021c70 <log>
    80004682:	854a                	mv	a0,s2
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	560080e7          	jalr	1376(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000468c:	02c92603          	lw	a2,44(s2)
    80004690:	47f5                	li	a5,29
    80004692:	06c7c563          	blt	a5,a2,800046fc <log_write+0x90>
    80004696:	0001d797          	auipc	a5,0x1d
    8000469a:	5f67a783          	lw	a5,1526(a5) # 80021c8c <log+0x1c>
    8000469e:	37fd                	addiw	a5,a5,-1
    800046a0:	04f65e63          	bge	a2,a5,800046fc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046a4:	0001d797          	auipc	a5,0x1d
    800046a8:	5ec7a783          	lw	a5,1516(a5) # 80021c90 <log+0x20>
    800046ac:	06f05063          	blez	a5,8000470c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046b0:	4781                	li	a5,0
    800046b2:	06c05563          	blez	a2,8000471c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046b6:	44cc                	lw	a1,12(s1)
    800046b8:	0001d717          	auipc	a4,0x1d
    800046bc:	5e870713          	addi	a4,a4,1512 # 80021ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046c0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046c2:	4314                	lw	a3,0(a4)
    800046c4:	04b68c63          	beq	a3,a1,8000471c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046c8:	2785                	addiw	a5,a5,1
    800046ca:	0711                	addi	a4,a4,4
    800046cc:	fef61be3          	bne	a2,a5,800046c2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046d0:	0621                	addi	a2,a2,8
    800046d2:	060a                	slli	a2,a2,0x2
    800046d4:	0001d797          	auipc	a5,0x1d
    800046d8:	59c78793          	addi	a5,a5,1436 # 80021c70 <log>
    800046dc:	963e                	add	a2,a2,a5
    800046de:	44dc                	lw	a5,12(s1)
    800046e0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046e2:	8526                	mv	a0,s1
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	daa080e7          	jalr	-598(ra) # 8000348e <bpin>
    log.lh.n++;
    800046ec:	0001d717          	auipc	a4,0x1d
    800046f0:	58470713          	addi	a4,a4,1412 # 80021c70 <log>
    800046f4:	575c                	lw	a5,44(a4)
    800046f6:	2785                	addiw	a5,a5,1
    800046f8:	d75c                	sw	a5,44(a4)
    800046fa:	a835                	j	80004736 <log_write+0xca>
    panic("too big a transaction");
    800046fc:	00004517          	auipc	a0,0x4
    80004700:	02450513          	addi	a0,a0,36 # 80008720 <syscalls+0x200>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000470c:	00004517          	auipc	a0,0x4
    80004710:	02c50513          	addi	a0,a0,44 # 80008738 <syscalls+0x218>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	e2a080e7          	jalr	-470(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000471c:	00878713          	addi	a4,a5,8
    80004720:	00271693          	slli	a3,a4,0x2
    80004724:	0001d717          	auipc	a4,0x1d
    80004728:	54c70713          	addi	a4,a4,1356 # 80021c70 <log>
    8000472c:	9736                	add	a4,a4,a3
    8000472e:	44d4                	lw	a3,12(s1)
    80004730:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004732:	faf608e3          	beq	a2,a5,800046e2 <log_write+0x76>
  }
  release(&log.lock);
    80004736:	0001d517          	auipc	a0,0x1d
    8000473a:	53a50513          	addi	a0,a0,1338 # 80021c70 <log>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
}
    80004746:	60e2                	ld	ra,24(sp)
    80004748:	6442                	ld	s0,16(sp)
    8000474a:	64a2                	ld	s1,8(sp)
    8000474c:	6902                	ld	s2,0(sp)
    8000474e:	6105                	addi	sp,sp,32
    80004750:	8082                	ret

0000000080004752 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004752:	1101                	addi	sp,sp,-32
    80004754:	ec06                	sd	ra,24(sp)
    80004756:	e822                	sd	s0,16(sp)
    80004758:	e426                	sd	s1,8(sp)
    8000475a:	e04a                	sd	s2,0(sp)
    8000475c:	1000                	addi	s0,sp,32
    8000475e:	84aa                	mv	s1,a0
    80004760:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004762:	00004597          	auipc	a1,0x4
    80004766:	ff658593          	addi	a1,a1,-10 # 80008758 <syscalls+0x238>
    8000476a:	0521                	addi	a0,a0,8
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	3e8080e7          	jalr	1000(ra) # 80000b54 <initlock>
  lk->name = name;
    80004774:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004778:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000477c:	0204a423          	sw	zero,40(s1)
}
    80004780:	60e2                	ld	ra,24(sp)
    80004782:	6442                	ld	s0,16(sp)
    80004784:	64a2                	ld	s1,8(sp)
    80004786:	6902                	ld	s2,0(sp)
    80004788:	6105                	addi	sp,sp,32
    8000478a:	8082                	ret

000000008000478c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000478c:	1101                	addi	sp,sp,-32
    8000478e:	ec06                	sd	ra,24(sp)
    80004790:	e822                	sd	s0,16(sp)
    80004792:	e426                	sd	s1,8(sp)
    80004794:	e04a                	sd	s2,0(sp)
    80004796:	1000                	addi	s0,sp,32
    80004798:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000479a:	00850913          	addi	s2,a0,8
    8000479e:	854a                	mv	a0,s2
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	444080e7          	jalr	1092(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047a8:	409c                	lw	a5,0(s1)
    800047aa:	cb89                	beqz	a5,800047bc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047ac:	85ca                	mv	a1,s2
    800047ae:	8526                	mv	a0,s1
    800047b0:	ffffe097          	auipc	ra,0xffffe
    800047b4:	a52080e7          	jalr	-1454(ra) # 80002202 <sleep>
  while (lk->locked) {
    800047b8:	409c                	lw	a5,0(s1)
    800047ba:	fbed                	bnez	a5,800047ac <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047bc:	4785                	li	a5,1
    800047be:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047c0:	ffffd097          	auipc	ra,0xffffd
    800047c4:	1f0080e7          	jalr	496(ra) # 800019b0 <myproc>
    800047c8:	591c                	lw	a5,48(a0)
    800047ca:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047cc:	854a                	mv	a0,s2
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	4ca080e7          	jalr	1226(ra) # 80000c98 <release>
}
    800047d6:	60e2                	ld	ra,24(sp)
    800047d8:	6442                	ld	s0,16(sp)
    800047da:	64a2                	ld	s1,8(sp)
    800047dc:	6902                	ld	s2,0(sp)
    800047de:	6105                	addi	sp,sp,32
    800047e0:	8082                	ret

00000000800047e2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047e2:	1101                	addi	sp,sp,-32
    800047e4:	ec06                	sd	ra,24(sp)
    800047e6:	e822                	sd	s0,16(sp)
    800047e8:	e426                	sd	s1,8(sp)
    800047ea:	e04a                	sd	s2,0(sp)
    800047ec:	1000                	addi	s0,sp,32
    800047ee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047f0:	00850913          	addi	s2,a0,8
    800047f4:	854a                	mv	a0,s2
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	3ee080e7          	jalr	1006(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800047fe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004802:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004806:	8526                	mv	a0,s1
    80004808:	ffffe097          	auipc	ra,0xffffe
    8000480c:	cd2080e7          	jalr	-814(ra) # 800024da <wakeup>
  release(&lk->lk);
    80004810:	854a                	mv	a0,s2
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
}
    8000481a:	60e2                	ld	ra,24(sp)
    8000481c:	6442                	ld	s0,16(sp)
    8000481e:	64a2                	ld	s1,8(sp)
    80004820:	6902                	ld	s2,0(sp)
    80004822:	6105                	addi	sp,sp,32
    80004824:	8082                	ret

0000000080004826 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004826:	7179                	addi	sp,sp,-48
    80004828:	f406                	sd	ra,40(sp)
    8000482a:	f022                	sd	s0,32(sp)
    8000482c:	ec26                	sd	s1,24(sp)
    8000482e:	e84a                	sd	s2,16(sp)
    80004830:	e44e                	sd	s3,8(sp)
    80004832:	1800                	addi	s0,sp,48
    80004834:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004836:	00850913          	addi	s2,a0,8
    8000483a:	854a                	mv	a0,s2
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	3a8080e7          	jalr	936(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004844:	409c                	lw	a5,0(s1)
    80004846:	ef99                	bnez	a5,80004864 <holdingsleep+0x3e>
    80004848:	4481                	li	s1,0
  release(&lk->lk);
    8000484a:	854a                	mv	a0,s2
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	44c080e7          	jalr	1100(ra) # 80000c98 <release>
  return r;
}
    80004854:	8526                	mv	a0,s1
    80004856:	70a2                	ld	ra,40(sp)
    80004858:	7402                	ld	s0,32(sp)
    8000485a:	64e2                	ld	s1,24(sp)
    8000485c:	6942                	ld	s2,16(sp)
    8000485e:	69a2                	ld	s3,8(sp)
    80004860:	6145                	addi	sp,sp,48
    80004862:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004864:	0284a983          	lw	s3,40(s1)
    80004868:	ffffd097          	auipc	ra,0xffffd
    8000486c:	148080e7          	jalr	328(ra) # 800019b0 <myproc>
    80004870:	5904                	lw	s1,48(a0)
    80004872:	413484b3          	sub	s1,s1,s3
    80004876:	0014b493          	seqz	s1,s1
    8000487a:	bfc1                	j	8000484a <holdingsleep+0x24>

000000008000487c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000487c:	1141                	addi	sp,sp,-16
    8000487e:	e406                	sd	ra,8(sp)
    80004880:	e022                	sd	s0,0(sp)
    80004882:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004884:	00004597          	auipc	a1,0x4
    80004888:	ee458593          	addi	a1,a1,-284 # 80008768 <syscalls+0x248>
    8000488c:	0001d517          	auipc	a0,0x1d
    80004890:	52c50513          	addi	a0,a0,1324 # 80021db8 <ftable>
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	2c0080e7          	jalr	704(ra) # 80000b54 <initlock>
}
    8000489c:	60a2                	ld	ra,8(sp)
    8000489e:	6402                	ld	s0,0(sp)
    800048a0:	0141                	addi	sp,sp,16
    800048a2:	8082                	ret

00000000800048a4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048a4:	1101                	addi	sp,sp,-32
    800048a6:	ec06                	sd	ra,24(sp)
    800048a8:	e822                	sd	s0,16(sp)
    800048aa:	e426                	sd	s1,8(sp)
    800048ac:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048ae:	0001d517          	auipc	a0,0x1d
    800048b2:	50a50513          	addi	a0,a0,1290 # 80021db8 <ftable>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	32e080e7          	jalr	814(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048be:	0001d497          	auipc	s1,0x1d
    800048c2:	51248493          	addi	s1,s1,1298 # 80021dd0 <ftable+0x18>
    800048c6:	0001e717          	auipc	a4,0x1e
    800048ca:	4aa70713          	addi	a4,a4,1194 # 80022d70 <ftable+0xfb8>
    if(f->ref == 0){
    800048ce:	40dc                	lw	a5,4(s1)
    800048d0:	cf99                	beqz	a5,800048ee <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048d2:	02848493          	addi	s1,s1,40
    800048d6:	fee49ce3          	bne	s1,a4,800048ce <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048da:	0001d517          	auipc	a0,0x1d
    800048de:	4de50513          	addi	a0,a0,1246 # 80021db8 <ftable>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	3b6080e7          	jalr	950(ra) # 80000c98 <release>
  return 0;
    800048ea:	4481                	li	s1,0
    800048ec:	a819                	j	80004902 <filealloc+0x5e>
      f->ref = 1;
    800048ee:	4785                	li	a5,1
    800048f0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	4c650513          	addi	a0,a0,1222 # 80021db8 <ftable>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	39e080e7          	jalr	926(ra) # 80000c98 <release>
}
    80004902:	8526                	mv	a0,s1
    80004904:	60e2                	ld	ra,24(sp)
    80004906:	6442                	ld	s0,16(sp)
    80004908:	64a2                	ld	s1,8(sp)
    8000490a:	6105                	addi	sp,sp,32
    8000490c:	8082                	ret

000000008000490e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000490e:	1101                	addi	sp,sp,-32
    80004910:	ec06                	sd	ra,24(sp)
    80004912:	e822                	sd	s0,16(sp)
    80004914:	e426                	sd	s1,8(sp)
    80004916:	1000                	addi	s0,sp,32
    80004918:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000491a:	0001d517          	auipc	a0,0x1d
    8000491e:	49e50513          	addi	a0,a0,1182 # 80021db8 <ftable>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	2c2080e7          	jalr	706(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000492a:	40dc                	lw	a5,4(s1)
    8000492c:	02f05263          	blez	a5,80004950 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004930:	2785                	addiw	a5,a5,1
    80004932:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004934:	0001d517          	auipc	a0,0x1d
    80004938:	48450513          	addi	a0,a0,1156 # 80021db8 <ftable>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
  return f;
}
    80004944:	8526                	mv	a0,s1
    80004946:	60e2                	ld	ra,24(sp)
    80004948:	6442                	ld	s0,16(sp)
    8000494a:	64a2                	ld	s1,8(sp)
    8000494c:	6105                	addi	sp,sp,32
    8000494e:	8082                	ret
    panic("filedup");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	e2050513          	addi	a0,a0,-480 # 80008770 <syscalls+0x250>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	be6080e7          	jalr	-1050(ra) # 8000053e <panic>

0000000080004960 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004960:	7139                	addi	sp,sp,-64
    80004962:	fc06                	sd	ra,56(sp)
    80004964:	f822                	sd	s0,48(sp)
    80004966:	f426                	sd	s1,40(sp)
    80004968:	f04a                	sd	s2,32(sp)
    8000496a:	ec4e                	sd	s3,24(sp)
    8000496c:	e852                	sd	s4,16(sp)
    8000496e:	e456                	sd	s5,8(sp)
    80004970:	0080                	addi	s0,sp,64
    80004972:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004974:	0001d517          	auipc	a0,0x1d
    80004978:	44450513          	addi	a0,a0,1092 # 80021db8 <ftable>
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	268080e7          	jalr	616(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004984:	40dc                	lw	a5,4(s1)
    80004986:	06f05163          	blez	a5,800049e8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000498a:	37fd                	addiw	a5,a5,-1
    8000498c:	0007871b          	sext.w	a4,a5
    80004990:	c0dc                	sw	a5,4(s1)
    80004992:	06e04363          	bgtz	a4,800049f8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004996:	0004a903          	lw	s2,0(s1)
    8000499a:	0094ca83          	lbu	s5,9(s1)
    8000499e:	0104ba03          	ld	s4,16(s1)
    800049a2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049a6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049aa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049ae:	0001d517          	auipc	a0,0x1d
    800049b2:	40a50513          	addi	a0,a0,1034 # 80021db8 <ftable>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	2e2080e7          	jalr	738(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800049be:	4785                	li	a5,1
    800049c0:	04f90d63          	beq	s2,a5,80004a1a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049c4:	3979                	addiw	s2,s2,-2
    800049c6:	4785                	li	a5,1
    800049c8:	0527e063          	bltu	a5,s2,80004a08 <fileclose+0xa8>
    begin_op();
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	ac8080e7          	jalr	-1336(ra) # 80004494 <begin_op>
    iput(ff.ip);
    800049d4:	854e                	mv	a0,s3
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	2a6080e7          	jalr	678(ra) # 80003c7c <iput>
    end_op();
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	b36080e7          	jalr	-1226(ra) # 80004514 <end_op>
    800049e6:	a00d                	j	80004a08 <fileclose+0xa8>
    panic("fileclose");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	d9050513          	addi	a0,a0,-624 # 80008778 <syscalls+0x258>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>
    release(&ftable.lock);
    800049f8:	0001d517          	auipc	a0,0x1d
    800049fc:	3c050513          	addi	a0,a0,960 # 80021db8 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
  }
}
    80004a08:	70e2                	ld	ra,56(sp)
    80004a0a:	7442                	ld	s0,48(sp)
    80004a0c:	74a2                	ld	s1,40(sp)
    80004a0e:	7902                	ld	s2,32(sp)
    80004a10:	69e2                	ld	s3,24(sp)
    80004a12:	6a42                	ld	s4,16(sp)
    80004a14:	6aa2                	ld	s5,8(sp)
    80004a16:	6121                	addi	sp,sp,64
    80004a18:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a1a:	85d6                	mv	a1,s5
    80004a1c:	8552                	mv	a0,s4
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	34c080e7          	jalr	844(ra) # 80004d6a <pipeclose>
    80004a26:	b7cd                	j	80004a08 <fileclose+0xa8>

0000000080004a28 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a28:	715d                	addi	sp,sp,-80
    80004a2a:	e486                	sd	ra,72(sp)
    80004a2c:	e0a2                	sd	s0,64(sp)
    80004a2e:	fc26                	sd	s1,56(sp)
    80004a30:	f84a                	sd	s2,48(sp)
    80004a32:	f44e                	sd	s3,40(sp)
    80004a34:	0880                	addi	s0,sp,80
    80004a36:	84aa                	mv	s1,a0
    80004a38:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a3a:	ffffd097          	auipc	ra,0xffffd
    80004a3e:	f76080e7          	jalr	-138(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a42:	409c                	lw	a5,0(s1)
    80004a44:	37f9                	addiw	a5,a5,-2
    80004a46:	4705                	li	a4,1
    80004a48:	04f76763          	bltu	a4,a5,80004a96 <filestat+0x6e>
    80004a4c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a4e:	6c88                	ld	a0,24(s1)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	072080e7          	jalr	114(ra) # 80003ac2 <ilock>
    stati(f->ip, &st);
    80004a58:	fb840593          	addi	a1,s0,-72
    80004a5c:	6c88                	ld	a0,24(s1)
    80004a5e:	fffff097          	auipc	ra,0xfffff
    80004a62:	2ee080e7          	jalr	750(ra) # 80003d4c <stati>
    iunlock(f->ip);
    80004a66:	6c88                	ld	a0,24(s1)
    80004a68:	fffff097          	auipc	ra,0xfffff
    80004a6c:	11c080e7          	jalr	284(ra) # 80003b84 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a70:	46e1                	li	a3,24
    80004a72:	fb840613          	addi	a2,s0,-72
    80004a76:	85ce                	mv	a1,s3
    80004a78:	05093503          	ld	a0,80(s2)
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	bf6080e7          	jalr	-1034(ra) # 80001672 <copyout>
    80004a84:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a88:	60a6                	ld	ra,72(sp)
    80004a8a:	6406                	ld	s0,64(sp)
    80004a8c:	74e2                	ld	s1,56(sp)
    80004a8e:	7942                	ld	s2,48(sp)
    80004a90:	79a2                	ld	s3,40(sp)
    80004a92:	6161                	addi	sp,sp,80
    80004a94:	8082                	ret
  return -1;
    80004a96:	557d                	li	a0,-1
    80004a98:	bfc5                	j	80004a88 <filestat+0x60>

0000000080004a9a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a9a:	7179                	addi	sp,sp,-48
    80004a9c:	f406                	sd	ra,40(sp)
    80004a9e:	f022                	sd	s0,32(sp)
    80004aa0:	ec26                	sd	s1,24(sp)
    80004aa2:	e84a                	sd	s2,16(sp)
    80004aa4:	e44e                	sd	s3,8(sp)
    80004aa6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004aa8:	00854783          	lbu	a5,8(a0)
    80004aac:	c3d5                	beqz	a5,80004b50 <fileread+0xb6>
    80004aae:	84aa                	mv	s1,a0
    80004ab0:	89ae                	mv	s3,a1
    80004ab2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ab4:	411c                	lw	a5,0(a0)
    80004ab6:	4705                	li	a4,1
    80004ab8:	04e78963          	beq	a5,a4,80004b0a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004abc:	470d                	li	a4,3
    80004abe:	04e78d63          	beq	a5,a4,80004b18 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ac2:	4709                	li	a4,2
    80004ac4:	06e79e63          	bne	a5,a4,80004b40 <fileread+0xa6>
    ilock(f->ip);
    80004ac8:	6d08                	ld	a0,24(a0)
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	ff8080e7          	jalr	-8(ra) # 80003ac2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ad2:	874a                	mv	a4,s2
    80004ad4:	5094                	lw	a3,32(s1)
    80004ad6:	864e                	mv	a2,s3
    80004ad8:	4585                	li	a1,1
    80004ada:	6c88                	ld	a0,24(s1)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	29a080e7          	jalr	666(ra) # 80003d76 <readi>
    80004ae4:	892a                	mv	s2,a0
    80004ae6:	00a05563          	blez	a0,80004af0 <fileread+0x56>
      f->off += r;
    80004aea:	509c                	lw	a5,32(s1)
    80004aec:	9fa9                	addw	a5,a5,a0
    80004aee:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004af0:	6c88                	ld	a0,24(s1)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	092080e7          	jalr	146(ra) # 80003b84 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004afa:	854a                	mv	a0,s2
    80004afc:	70a2                	ld	ra,40(sp)
    80004afe:	7402                	ld	s0,32(sp)
    80004b00:	64e2                	ld	s1,24(sp)
    80004b02:	6942                	ld	s2,16(sp)
    80004b04:	69a2                	ld	s3,8(sp)
    80004b06:	6145                	addi	sp,sp,48
    80004b08:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b0a:	6908                	ld	a0,16(a0)
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	3c8080e7          	jalr	968(ra) # 80004ed4 <piperead>
    80004b14:	892a                	mv	s2,a0
    80004b16:	b7d5                	j	80004afa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b18:	02451783          	lh	a5,36(a0)
    80004b1c:	03079693          	slli	a3,a5,0x30
    80004b20:	92c1                	srli	a3,a3,0x30
    80004b22:	4725                	li	a4,9
    80004b24:	02d76863          	bltu	a4,a3,80004b54 <fileread+0xba>
    80004b28:	0792                	slli	a5,a5,0x4
    80004b2a:	0001d717          	auipc	a4,0x1d
    80004b2e:	1ee70713          	addi	a4,a4,494 # 80021d18 <devsw>
    80004b32:	97ba                	add	a5,a5,a4
    80004b34:	639c                	ld	a5,0(a5)
    80004b36:	c38d                	beqz	a5,80004b58 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b38:	4505                	li	a0,1
    80004b3a:	9782                	jalr	a5
    80004b3c:	892a                	mv	s2,a0
    80004b3e:	bf75                	j	80004afa <fileread+0x60>
    panic("fileread");
    80004b40:	00004517          	auipc	a0,0x4
    80004b44:	c4850513          	addi	a0,a0,-952 # 80008788 <syscalls+0x268>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
    return -1;
    80004b50:	597d                	li	s2,-1
    80004b52:	b765                	j	80004afa <fileread+0x60>
      return -1;
    80004b54:	597d                	li	s2,-1
    80004b56:	b755                	j	80004afa <fileread+0x60>
    80004b58:	597d                	li	s2,-1
    80004b5a:	b745                	j	80004afa <fileread+0x60>

0000000080004b5c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b5c:	715d                	addi	sp,sp,-80
    80004b5e:	e486                	sd	ra,72(sp)
    80004b60:	e0a2                	sd	s0,64(sp)
    80004b62:	fc26                	sd	s1,56(sp)
    80004b64:	f84a                	sd	s2,48(sp)
    80004b66:	f44e                	sd	s3,40(sp)
    80004b68:	f052                	sd	s4,32(sp)
    80004b6a:	ec56                	sd	s5,24(sp)
    80004b6c:	e85a                	sd	s6,16(sp)
    80004b6e:	e45e                	sd	s7,8(sp)
    80004b70:	e062                	sd	s8,0(sp)
    80004b72:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b74:	00954783          	lbu	a5,9(a0)
    80004b78:	10078663          	beqz	a5,80004c84 <filewrite+0x128>
    80004b7c:	892a                	mv	s2,a0
    80004b7e:	8aae                	mv	s5,a1
    80004b80:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b82:	411c                	lw	a5,0(a0)
    80004b84:	4705                	li	a4,1
    80004b86:	02e78263          	beq	a5,a4,80004baa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b8a:	470d                	li	a4,3
    80004b8c:	02e78663          	beq	a5,a4,80004bb8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b90:	4709                	li	a4,2
    80004b92:	0ee79163          	bne	a5,a4,80004c74 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b96:	0ac05d63          	blez	a2,80004c50 <filewrite+0xf4>
    int i = 0;
    80004b9a:	4981                	li	s3,0
    80004b9c:	6b05                	lui	s6,0x1
    80004b9e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ba2:	6b85                	lui	s7,0x1
    80004ba4:	c00b8b9b          	addiw	s7,s7,-1024
    80004ba8:	a861                	j	80004c40 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004baa:	6908                	ld	a0,16(a0)
    80004bac:	00000097          	auipc	ra,0x0
    80004bb0:	22e080e7          	jalr	558(ra) # 80004dda <pipewrite>
    80004bb4:	8a2a                	mv	s4,a0
    80004bb6:	a045                	j	80004c56 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bb8:	02451783          	lh	a5,36(a0)
    80004bbc:	03079693          	slli	a3,a5,0x30
    80004bc0:	92c1                	srli	a3,a3,0x30
    80004bc2:	4725                	li	a4,9
    80004bc4:	0cd76263          	bltu	a4,a3,80004c88 <filewrite+0x12c>
    80004bc8:	0792                	slli	a5,a5,0x4
    80004bca:	0001d717          	auipc	a4,0x1d
    80004bce:	14e70713          	addi	a4,a4,334 # 80021d18 <devsw>
    80004bd2:	97ba                	add	a5,a5,a4
    80004bd4:	679c                	ld	a5,8(a5)
    80004bd6:	cbdd                	beqz	a5,80004c8c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bd8:	4505                	li	a0,1
    80004bda:	9782                	jalr	a5
    80004bdc:	8a2a                	mv	s4,a0
    80004bde:	a8a5                	j	80004c56 <filewrite+0xfa>
    80004be0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004be4:	00000097          	auipc	ra,0x0
    80004be8:	8b0080e7          	jalr	-1872(ra) # 80004494 <begin_op>
      ilock(f->ip);
    80004bec:	01893503          	ld	a0,24(s2)
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	ed2080e7          	jalr	-302(ra) # 80003ac2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bf8:	8762                	mv	a4,s8
    80004bfa:	02092683          	lw	a3,32(s2)
    80004bfe:	01598633          	add	a2,s3,s5
    80004c02:	4585                	li	a1,1
    80004c04:	01893503          	ld	a0,24(s2)
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	266080e7          	jalr	614(ra) # 80003e6e <writei>
    80004c10:	84aa                	mv	s1,a0
    80004c12:	00a05763          	blez	a0,80004c20 <filewrite+0xc4>
        f->off += r;
    80004c16:	02092783          	lw	a5,32(s2)
    80004c1a:	9fa9                	addw	a5,a5,a0
    80004c1c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c20:	01893503          	ld	a0,24(s2)
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	f60080e7          	jalr	-160(ra) # 80003b84 <iunlock>
      end_op();
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	8e8080e7          	jalr	-1816(ra) # 80004514 <end_op>

      if(r != n1){
    80004c34:	009c1f63          	bne	s8,s1,80004c52 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c38:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c3c:	0149db63          	bge	s3,s4,80004c52 <filewrite+0xf6>
      int n1 = n - i;
    80004c40:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c44:	84be                	mv	s1,a5
    80004c46:	2781                	sext.w	a5,a5
    80004c48:	f8fb5ce3          	bge	s6,a5,80004be0 <filewrite+0x84>
    80004c4c:	84de                	mv	s1,s7
    80004c4e:	bf49                	j	80004be0 <filewrite+0x84>
    int i = 0;
    80004c50:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c52:	013a1f63          	bne	s4,s3,80004c70 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c56:	8552                	mv	a0,s4
    80004c58:	60a6                	ld	ra,72(sp)
    80004c5a:	6406                	ld	s0,64(sp)
    80004c5c:	74e2                	ld	s1,56(sp)
    80004c5e:	7942                	ld	s2,48(sp)
    80004c60:	79a2                	ld	s3,40(sp)
    80004c62:	7a02                	ld	s4,32(sp)
    80004c64:	6ae2                	ld	s5,24(sp)
    80004c66:	6b42                	ld	s6,16(sp)
    80004c68:	6ba2                	ld	s7,8(sp)
    80004c6a:	6c02                	ld	s8,0(sp)
    80004c6c:	6161                	addi	sp,sp,80
    80004c6e:	8082                	ret
    ret = (i == n ? n : -1);
    80004c70:	5a7d                	li	s4,-1
    80004c72:	b7d5                	j	80004c56 <filewrite+0xfa>
    panic("filewrite");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	b2450513          	addi	a0,a0,-1244 # 80008798 <syscalls+0x278>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8c2080e7          	jalr	-1854(ra) # 8000053e <panic>
    return -1;
    80004c84:	5a7d                	li	s4,-1
    80004c86:	bfc1                	j	80004c56 <filewrite+0xfa>
      return -1;
    80004c88:	5a7d                	li	s4,-1
    80004c8a:	b7f1                	j	80004c56 <filewrite+0xfa>
    80004c8c:	5a7d                	li	s4,-1
    80004c8e:	b7e1                	j	80004c56 <filewrite+0xfa>

0000000080004c90 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c90:	7179                	addi	sp,sp,-48
    80004c92:	f406                	sd	ra,40(sp)
    80004c94:	f022                	sd	s0,32(sp)
    80004c96:	ec26                	sd	s1,24(sp)
    80004c98:	e84a                	sd	s2,16(sp)
    80004c9a:	e44e                	sd	s3,8(sp)
    80004c9c:	e052                	sd	s4,0(sp)
    80004c9e:	1800                	addi	s0,sp,48
    80004ca0:	84aa                	mv	s1,a0
    80004ca2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ca4:	0005b023          	sd	zero,0(a1)
    80004ca8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cac:	00000097          	auipc	ra,0x0
    80004cb0:	bf8080e7          	jalr	-1032(ra) # 800048a4 <filealloc>
    80004cb4:	e088                	sd	a0,0(s1)
    80004cb6:	c551                	beqz	a0,80004d42 <pipealloc+0xb2>
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	bec080e7          	jalr	-1044(ra) # 800048a4 <filealloc>
    80004cc0:	00aa3023          	sd	a0,0(s4)
    80004cc4:	c92d                	beqz	a0,80004d36 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	e2e080e7          	jalr	-466(ra) # 80000af4 <kalloc>
    80004cce:	892a                	mv	s2,a0
    80004cd0:	c125                	beqz	a0,80004d30 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cd2:	4985                	li	s3,1
    80004cd4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cd8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cdc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ce0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ce4:	00003597          	auipc	a1,0x3
    80004ce8:	79458593          	addi	a1,a1,1940 # 80008478 <states.1753+0x1b8>
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	e68080e7          	jalr	-408(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004cf4:	609c                	ld	a5,0(s1)
    80004cf6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cfa:	609c                	ld	a5,0(s1)
    80004cfc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d00:	609c                	ld	a5,0(s1)
    80004d02:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d06:	609c                	ld	a5,0(s1)
    80004d08:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d0c:	000a3783          	ld	a5,0(s4)
    80004d10:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d14:	000a3783          	ld	a5,0(s4)
    80004d18:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d1c:	000a3783          	ld	a5,0(s4)
    80004d20:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d24:	000a3783          	ld	a5,0(s4)
    80004d28:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d2c:	4501                	li	a0,0
    80004d2e:	a025                	j	80004d56 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d30:	6088                	ld	a0,0(s1)
    80004d32:	e501                	bnez	a0,80004d3a <pipealloc+0xaa>
    80004d34:	a039                	j	80004d42 <pipealloc+0xb2>
    80004d36:	6088                	ld	a0,0(s1)
    80004d38:	c51d                	beqz	a0,80004d66 <pipealloc+0xd6>
    fileclose(*f0);
    80004d3a:	00000097          	auipc	ra,0x0
    80004d3e:	c26080e7          	jalr	-986(ra) # 80004960 <fileclose>
  if(*f1)
    80004d42:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d46:	557d                	li	a0,-1
  if(*f1)
    80004d48:	c799                	beqz	a5,80004d56 <pipealloc+0xc6>
    fileclose(*f1);
    80004d4a:	853e                	mv	a0,a5
    80004d4c:	00000097          	auipc	ra,0x0
    80004d50:	c14080e7          	jalr	-1004(ra) # 80004960 <fileclose>
  return -1;
    80004d54:	557d                	li	a0,-1
}
    80004d56:	70a2                	ld	ra,40(sp)
    80004d58:	7402                	ld	s0,32(sp)
    80004d5a:	64e2                	ld	s1,24(sp)
    80004d5c:	6942                	ld	s2,16(sp)
    80004d5e:	69a2                	ld	s3,8(sp)
    80004d60:	6a02                	ld	s4,0(sp)
    80004d62:	6145                	addi	sp,sp,48
    80004d64:	8082                	ret
  return -1;
    80004d66:	557d                	li	a0,-1
    80004d68:	b7fd                	j	80004d56 <pipealloc+0xc6>

0000000080004d6a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d6a:	1101                	addi	sp,sp,-32
    80004d6c:	ec06                	sd	ra,24(sp)
    80004d6e:	e822                	sd	s0,16(sp)
    80004d70:	e426                	sd	s1,8(sp)
    80004d72:	e04a                	sd	s2,0(sp)
    80004d74:	1000                	addi	s0,sp,32
    80004d76:	84aa                	mv	s1,a0
    80004d78:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	e6a080e7          	jalr	-406(ra) # 80000be4 <acquire>
  if(writable){
    80004d82:	02090d63          	beqz	s2,80004dbc <pipeclose+0x52>
    pi->writeopen = 0;
    80004d86:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d8a:	21848513          	addi	a0,s1,536
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	74c080e7          	jalr	1868(ra) # 800024da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d96:	2204b783          	ld	a5,544(s1)
    80004d9a:	eb95                	bnez	a5,80004dce <pipeclose+0x64>
    release(&pi->lock);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	efa080e7          	jalr	-262(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	c50080e7          	jalr	-944(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004db0:	60e2                	ld	ra,24(sp)
    80004db2:	6442                	ld	s0,16(sp)
    80004db4:	64a2                	ld	s1,8(sp)
    80004db6:	6902                	ld	s2,0(sp)
    80004db8:	6105                	addi	sp,sp,32
    80004dba:	8082                	ret
    pi->readopen = 0;
    80004dbc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dc0:	21c48513          	addi	a0,s1,540
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	716080e7          	jalr	1814(ra) # 800024da <wakeup>
    80004dcc:	b7e9                	j	80004d96 <pipeclose+0x2c>
    release(&pi->lock);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	ec8080e7          	jalr	-312(ra) # 80000c98 <release>
}
    80004dd8:	bfe1                	j	80004db0 <pipeclose+0x46>

0000000080004dda <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dda:	7159                	addi	sp,sp,-112
    80004ddc:	f486                	sd	ra,104(sp)
    80004dde:	f0a2                	sd	s0,96(sp)
    80004de0:	eca6                	sd	s1,88(sp)
    80004de2:	e8ca                	sd	s2,80(sp)
    80004de4:	e4ce                	sd	s3,72(sp)
    80004de6:	e0d2                	sd	s4,64(sp)
    80004de8:	fc56                	sd	s5,56(sp)
    80004dea:	f85a                	sd	s6,48(sp)
    80004dec:	f45e                	sd	s7,40(sp)
    80004dee:	f062                	sd	s8,32(sp)
    80004df0:	ec66                	sd	s9,24(sp)
    80004df2:	1880                	addi	s0,sp,112
    80004df4:	84aa                	mv	s1,a0
    80004df6:	8aae                	mv	s5,a1
    80004df8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	bb6080e7          	jalr	-1098(ra) # 800019b0 <myproc>
    80004e02:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e04:	8526                	mv	a0,s1
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	dde080e7          	jalr	-546(ra) # 80000be4 <acquire>
  while(i < n){
    80004e0e:	0d405163          	blez	s4,80004ed0 <pipewrite+0xf6>
    80004e12:	8ba6                	mv	s7,s1
  int i = 0;
    80004e14:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e16:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e18:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e1c:	21c48c13          	addi	s8,s1,540
    80004e20:	a08d                	j	80004e82 <pipewrite+0xa8>
      release(&pi->lock);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
      return -1;
    80004e2c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e2e:	854a                	mv	a0,s2
    80004e30:	70a6                	ld	ra,104(sp)
    80004e32:	7406                	ld	s0,96(sp)
    80004e34:	64e6                	ld	s1,88(sp)
    80004e36:	6946                	ld	s2,80(sp)
    80004e38:	69a6                	ld	s3,72(sp)
    80004e3a:	6a06                	ld	s4,64(sp)
    80004e3c:	7ae2                	ld	s5,56(sp)
    80004e3e:	7b42                	ld	s6,48(sp)
    80004e40:	7ba2                	ld	s7,40(sp)
    80004e42:	7c02                	ld	s8,32(sp)
    80004e44:	6ce2                	ld	s9,24(sp)
    80004e46:	6165                	addi	sp,sp,112
    80004e48:	8082                	ret
      wakeup(&pi->nread);
    80004e4a:	8566                	mv	a0,s9
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	68e080e7          	jalr	1678(ra) # 800024da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e54:	85de                	mv	a1,s7
    80004e56:	8562                	mv	a0,s8
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	3aa080e7          	jalr	938(ra) # 80002202 <sleep>
    80004e60:	a839                	j	80004e7e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e62:	21c4a783          	lw	a5,540(s1)
    80004e66:	0017871b          	addiw	a4,a5,1
    80004e6a:	20e4ae23          	sw	a4,540(s1)
    80004e6e:	1ff7f793          	andi	a5,a5,511
    80004e72:	97a6                	add	a5,a5,s1
    80004e74:	f9f44703          	lbu	a4,-97(s0)
    80004e78:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e7c:	2905                	addiw	s2,s2,1
  while(i < n){
    80004e7e:	03495d63          	bge	s2,s4,80004eb8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004e82:	2204a783          	lw	a5,544(s1)
    80004e86:	dfd1                	beqz	a5,80004e22 <pipewrite+0x48>
    80004e88:	0289a783          	lw	a5,40(s3)
    80004e8c:	fbd9                	bnez	a5,80004e22 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e8e:	2184a783          	lw	a5,536(s1)
    80004e92:	21c4a703          	lw	a4,540(s1)
    80004e96:	2007879b          	addiw	a5,a5,512
    80004e9a:	faf708e3          	beq	a4,a5,80004e4a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e9e:	4685                	li	a3,1
    80004ea0:	01590633          	add	a2,s2,s5
    80004ea4:	f9f40593          	addi	a1,s0,-97
    80004ea8:	0509b503          	ld	a0,80(s3)
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	852080e7          	jalr	-1966(ra) # 800016fe <copyin>
    80004eb4:	fb6517e3          	bne	a0,s6,80004e62 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004eb8:	21848513          	addi	a0,s1,536
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	61e080e7          	jalr	1566(ra) # 800024da <wakeup>
  release(&pi->lock);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	dd2080e7          	jalr	-558(ra) # 80000c98 <release>
  return i;
    80004ece:	b785                	j	80004e2e <pipewrite+0x54>
  int i = 0;
    80004ed0:	4901                	li	s2,0
    80004ed2:	b7dd                	j	80004eb8 <pipewrite+0xde>

0000000080004ed4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ed4:	715d                	addi	sp,sp,-80
    80004ed6:	e486                	sd	ra,72(sp)
    80004ed8:	e0a2                	sd	s0,64(sp)
    80004eda:	fc26                	sd	s1,56(sp)
    80004edc:	f84a                	sd	s2,48(sp)
    80004ede:	f44e                	sd	s3,40(sp)
    80004ee0:	f052                	sd	s4,32(sp)
    80004ee2:	ec56                	sd	s5,24(sp)
    80004ee4:	e85a                	sd	s6,16(sp)
    80004ee6:	0880                	addi	s0,sp,80
    80004ee8:	84aa                	mv	s1,a0
    80004eea:	892e                	mv	s2,a1
    80004eec:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	ac2080e7          	jalr	-1342(ra) # 800019b0 <myproc>
    80004ef6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ef8:	8b26                	mv	s6,s1
    80004efa:	8526                	mv	a0,s1
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	ce8080e7          	jalr	-792(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f04:	2184a703          	lw	a4,536(s1)
    80004f08:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f10:	02f71463          	bne	a4,a5,80004f38 <piperead+0x64>
    80004f14:	2244a783          	lw	a5,548(s1)
    80004f18:	c385                	beqz	a5,80004f38 <piperead+0x64>
    if(pr->killed){
    80004f1a:	028a2783          	lw	a5,40(s4)
    80004f1e:	ebc1                	bnez	a5,80004fae <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f20:	85da                	mv	a1,s6
    80004f22:	854e                	mv	a0,s3
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	2de080e7          	jalr	734(ra) # 80002202 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f2c:	2184a703          	lw	a4,536(s1)
    80004f30:	21c4a783          	lw	a5,540(s1)
    80004f34:	fef700e3          	beq	a4,a5,80004f14 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f38:	09505263          	blez	s5,80004fbc <piperead+0xe8>
    80004f3c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f3e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f40:	2184a783          	lw	a5,536(s1)
    80004f44:	21c4a703          	lw	a4,540(s1)
    80004f48:	02f70d63          	beq	a4,a5,80004f82 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f4c:	0017871b          	addiw	a4,a5,1
    80004f50:	20e4ac23          	sw	a4,536(s1)
    80004f54:	1ff7f793          	andi	a5,a5,511
    80004f58:	97a6                	add	a5,a5,s1
    80004f5a:	0187c783          	lbu	a5,24(a5)
    80004f5e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f62:	4685                	li	a3,1
    80004f64:	fbf40613          	addi	a2,s0,-65
    80004f68:	85ca                	mv	a1,s2
    80004f6a:	050a3503          	ld	a0,80(s4)
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	704080e7          	jalr	1796(ra) # 80001672 <copyout>
    80004f76:	01650663          	beq	a0,s6,80004f82 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f7a:	2985                	addiw	s3,s3,1
    80004f7c:	0905                	addi	s2,s2,1
    80004f7e:	fd3a91e3          	bne	s5,s3,80004f40 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f82:	21c48513          	addi	a0,s1,540
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	554080e7          	jalr	1364(ra) # 800024da <wakeup>
  release(&pi->lock);
    80004f8e:	8526                	mv	a0,s1
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	d08080e7          	jalr	-760(ra) # 80000c98 <release>
  return i;
}
    80004f98:	854e                	mv	a0,s3
    80004f9a:	60a6                	ld	ra,72(sp)
    80004f9c:	6406                	ld	s0,64(sp)
    80004f9e:	74e2                	ld	s1,56(sp)
    80004fa0:	7942                	ld	s2,48(sp)
    80004fa2:	79a2                	ld	s3,40(sp)
    80004fa4:	7a02                	ld	s4,32(sp)
    80004fa6:	6ae2                	ld	s5,24(sp)
    80004fa8:	6b42                	ld	s6,16(sp)
    80004faa:	6161                	addi	sp,sp,80
    80004fac:	8082                	ret
      release(&pi->lock);
    80004fae:	8526                	mv	a0,s1
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	ce8080e7          	jalr	-792(ra) # 80000c98 <release>
      return -1;
    80004fb8:	59fd                	li	s3,-1
    80004fba:	bff9                	j	80004f98 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fbc:	4981                	li	s3,0
    80004fbe:	b7d1                	j	80004f82 <piperead+0xae>

0000000080004fc0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fc0:	df010113          	addi	sp,sp,-528
    80004fc4:	20113423          	sd	ra,520(sp)
    80004fc8:	20813023          	sd	s0,512(sp)
    80004fcc:	ffa6                	sd	s1,504(sp)
    80004fce:	fbca                	sd	s2,496(sp)
    80004fd0:	f7ce                	sd	s3,488(sp)
    80004fd2:	f3d2                	sd	s4,480(sp)
    80004fd4:	efd6                	sd	s5,472(sp)
    80004fd6:	ebda                	sd	s6,464(sp)
    80004fd8:	e7de                	sd	s7,456(sp)
    80004fda:	e3e2                	sd	s8,448(sp)
    80004fdc:	ff66                	sd	s9,440(sp)
    80004fde:	fb6a                	sd	s10,432(sp)
    80004fe0:	f76e                	sd	s11,424(sp)
    80004fe2:	0c00                	addi	s0,sp,528
    80004fe4:	84aa                	mv	s1,a0
    80004fe6:	dea43c23          	sd	a0,-520(s0)
    80004fea:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	9c2080e7          	jalr	-1598(ra) # 800019b0 <myproc>
    80004ff6:	892a                	mv	s2,a0

  begin_op();
    80004ff8:	fffff097          	auipc	ra,0xfffff
    80004ffc:	49c080e7          	jalr	1180(ra) # 80004494 <begin_op>

  if((ip = namei(path)) == 0){
    80005000:	8526                	mv	a0,s1
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	276080e7          	jalr	630(ra) # 80004278 <namei>
    8000500a:	c92d                	beqz	a0,8000507c <exec+0xbc>
    8000500c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	ab4080e7          	jalr	-1356(ra) # 80003ac2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005016:	04000713          	li	a4,64
    8000501a:	4681                	li	a3,0
    8000501c:	e5040613          	addi	a2,s0,-432
    80005020:	4581                	li	a1,0
    80005022:	8526                	mv	a0,s1
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	d52080e7          	jalr	-686(ra) # 80003d76 <readi>
    8000502c:	04000793          	li	a5,64
    80005030:	00f51a63          	bne	a0,a5,80005044 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005034:	e5042703          	lw	a4,-432(s0)
    80005038:	464c47b7          	lui	a5,0x464c4
    8000503c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005040:	04f70463          	beq	a4,a5,80005088 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005044:	8526                	mv	a0,s1
    80005046:	fffff097          	auipc	ra,0xfffff
    8000504a:	cde080e7          	jalr	-802(ra) # 80003d24 <iunlockput>
    end_op();
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	4c6080e7          	jalr	1222(ra) # 80004514 <end_op>
  }
  return -1;
    80005056:	557d                	li	a0,-1
}
    80005058:	20813083          	ld	ra,520(sp)
    8000505c:	20013403          	ld	s0,512(sp)
    80005060:	74fe                	ld	s1,504(sp)
    80005062:	795e                	ld	s2,496(sp)
    80005064:	79be                	ld	s3,488(sp)
    80005066:	7a1e                	ld	s4,480(sp)
    80005068:	6afe                	ld	s5,472(sp)
    8000506a:	6b5e                	ld	s6,464(sp)
    8000506c:	6bbe                	ld	s7,456(sp)
    8000506e:	6c1e                	ld	s8,448(sp)
    80005070:	7cfa                	ld	s9,440(sp)
    80005072:	7d5a                	ld	s10,432(sp)
    80005074:	7dba                	ld	s11,424(sp)
    80005076:	21010113          	addi	sp,sp,528
    8000507a:	8082                	ret
    end_op();
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	498080e7          	jalr	1176(ra) # 80004514 <end_op>
    return -1;
    80005084:	557d                	li	a0,-1
    80005086:	bfc9                	j	80005058 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005088:	854a                	mv	a0,s2
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	9ea080e7          	jalr	-1558(ra) # 80001a74 <proc_pagetable>
    80005092:	8baa                	mv	s7,a0
    80005094:	d945                	beqz	a0,80005044 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005096:	e7042983          	lw	s3,-400(s0)
    8000509a:	e8845783          	lhu	a5,-376(s0)
    8000509e:	c7ad                	beqz	a5,80005108 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050a0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050a2:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050a4:	6c85                	lui	s9,0x1
    800050a6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050aa:	def43823          	sd	a5,-528(s0)
    800050ae:	a42d                	j	800052d8 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050b0:	00003517          	auipc	a0,0x3
    800050b4:	6f850513          	addi	a0,a0,1784 # 800087a8 <syscalls+0x288>
    800050b8:	ffffb097          	auipc	ra,0xffffb
    800050bc:	486080e7          	jalr	1158(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050c0:	8756                	mv	a4,s5
    800050c2:	012d86bb          	addw	a3,s11,s2
    800050c6:	4581                	li	a1,0
    800050c8:	8526                	mv	a0,s1
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	cac080e7          	jalr	-852(ra) # 80003d76 <readi>
    800050d2:	2501                	sext.w	a0,a0
    800050d4:	1aaa9963          	bne	s5,a0,80005286 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800050d8:	6785                	lui	a5,0x1
    800050da:	0127893b          	addw	s2,a5,s2
    800050de:	77fd                	lui	a5,0xfffff
    800050e0:	01478a3b          	addw	s4,a5,s4
    800050e4:	1f897163          	bgeu	s2,s8,800052c6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800050e8:	02091593          	slli	a1,s2,0x20
    800050ec:	9181                	srli	a1,a1,0x20
    800050ee:	95ea                	add	a1,a1,s10
    800050f0:	855e                	mv	a0,s7
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	f7c080e7          	jalr	-132(ra) # 8000106e <walkaddr>
    800050fa:	862a                	mv	a2,a0
    if(pa == 0)
    800050fc:	d955                	beqz	a0,800050b0 <exec+0xf0>
      n = PGSIZE;
    800050fe:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005100:	fd9a70e3          	bgeu	s4,s9,800050c0 <exec+0x100>
      n = sz - i;
    80005104:	8ad2                	mv	s5,s4
    80005106:	bf6d                	j	800050c0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005108:	4901                	li	s2,0
  iunlockput(ip);
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	c18080e7          	jalr	-1000(ra) # 80003d24 <iunlockput>
  end_op();
    80005114:	fffff097          	auipc	ra,0xfffff
    80005118:	400080e7          	jalr	1024(ra) # 80004514 <end_op>
  p = myproc();
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	894080e7          	jalr	-1900(ra) # 800019b0 <myproc>
    80005124:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005126:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000512a:	6785                	lui	a5,0x1
    8000512c:	17fd                	addi	a5,a5,-1
    8000512e:	993e                	add	s2,s2,a5
    80005130:	757d                	lui	a0,0xfffff
    80005132:	00a977b3          	and	a5,s2,a0
    80005136:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000513a:	6609                	lui	a2,0x2
    8000513c:	963e                	add	a2,a2,a5
    8000513e:	85be                	mv	a1,a5
    80005140:	855e                	mv	a0,s7
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	2e0080e7          	jalr	736(ra) # 80001422 <uvmalloc>
    8000514a:	8b2a                	mv	s6,a0
  ip = 0;
    8000514c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000514e:	12050c63          	beqz	a0,80005286 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005152:	75f9                	lui	a1,0xffffe
    80005154:	95aa                	add	a1,a1,a0
    80005156:	855e                	mv	a0,s7
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	4e8080e7          	jalr	1256(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005160:	7c7d                	lui	s8,0xfffff
    80005162:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005164:	e0043783          	ld	a5,-512(s0)
    80005168:	6388                	ld	a0,0(a5)
    8000516a:	c535                	beqz	a0,800051d6 <exec+0x216>
    8000516c:	e9040993          	addi	s3,s0,-368
    80005170:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005174:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005176:	ffffc097          	auipc	ra,0xffffc
    8000517a:	cee080e7          	jalr	-786(ra) # 80000e64 <strlen>
    8000517e:	2505                	addiw	a0,a0,1
    80005180:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005184:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005188:	13896363          	bltu	s2,s8,800052ae <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000518c:	e0043d83          	ld	s11,-512(s0)
    80005190:	000dba03          	ld	s4,0(s11)
    80005194:	8552                	mv	a0,s4
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	cce080e7          	jalr	-818(ra) # 80000e64 <strlen>
    8000519e:	0015069b          	addiw	a3,a0,1
    800051a2:	8652                	mv	a2,s4
    800051a4:	85ca                	mv	a1,s2
    800051a6:	855e                	mv	a0,s7
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	4ca080e7          	jalr	1226(ra) # 80001672 <copyout>
    800051b0:	10054363          	bltz	a0,800052b6 <exec+0x2f6>
    ustack[argc] = sp;
    800051b4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051b8:	0485                	addi	s1,s1,1
    800051ba:	008d8793          	addi	a5,s11,8
    800051be:	e0f43023          	sd	a5,-512(s0)
    800051c2:	008db503          	ld	a0,8(s11)
    800051c6:	c911                	beqz	a0,800051da <exec+0x21a>
    if(argc >= MAXARG)
    800051c8:	09a1                	addi	s3,s3,8
    800051ca:	fb3c96e3          	bne	s9,s3,80005176 <exec+0x1b6>
  sz = sz1;
    800051ce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051d2:	4481                	li	s1,0
    800051d4:	a84d                	j	80005286 <exec+0x2c6>
  sp = sz;
    800051d6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800051d8:	4481                	li	s1,0
  ustack[argc] = 0;
    800051da:	00349793          	slli	a5,s1,0x3
    800051de:	f9040713          	addi	a4,s0,-112
    800051e2:	97ba                	add	a5,a5,a4
    800051e4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800051e8:	00148693          	addi	a3,s1,1
    800051ec:	068e                	slli	a3,a3,0x3
    800051ee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051f2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051f6:	01897663          	bgeu	s2,s8,80005202 <exec+0x242>
  sz = sz1;
    800051fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051fe:	4481                	li	s1,0
    80005200:	a059                	j	80005286 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005202:	e9040613          	addi	a2,s0,-368
    80005206:	85ca                	mv	a1,s2
    80005208:	855e                	mv	a0,s7
    8000520a:	ffffc097          	auipc	ra,0xffffc
    8000520e:	468080e7          	jalr	1128(ra) # 80001672 <copyout>
    80005212:	0a054663          	bltz	a0,800052be <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005216:	058ab783          	ld	a5,88(s5)
    8000521a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000521e:	df843783          	ld	a5,-520(s0)
    80005222:	0007c703          	lbu	a4,0(a5)
    80005226:	cf11                	beqz	a4,80005242 <exec+0x282>
    80005228:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000522a:	02f00693          	li	a3,47
    8000522e:	a039                	j	8000523c <exec+0x27c>
      last = s+1;
    80005230:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005234:	0785                	addi	a5,a5,1
    80005236:	fff7c703          	lbu	a4,-1(a5)
    8000523a:	c701                	beqz	a4,80005242 <exec+0x282>
    if(*s == '/')
    8000523c:	fed71ce3          	bne	a4,a3,80005234 <exec+0x274>
    80005240:	bfc5                	j	80005230 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005242:	4641                	li	a2,16
    80005244:	df843583          	ld	a1,-520(s0)
    80005248:	158a8513          	addi	a0,s5,344
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	be6080e7          	jalr	-1050(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005254:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005258:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000525c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005260:	058ab783          	ld	a5,88(s5)
    80005264:	e6843703          	ld	a4,-408(s0)
    80005268:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000526a:	058ab783          	ld	a5,88(s5)
    8000526e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005272:	85ea                	mv	a1,s10
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	89c080e7          	jalr	-1892(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000527c:	0004851b          	sext.w	a0,s1
    80005280:	bbe1                	j	80005058 <exec+0x98>
    80005282:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005286:	e0843583          	ld	a1,-504(s0)
    8000528a:	855e                	mv	a0,s7
    8000528c:	ffffd097          	auipc	ra,0xffffd
    80005290:	884080e7          	jalr	-1916(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005294:	da0498e3          	bnez	s1,80005044 <exec+0x84>
  return -1;
    80005298:	557d                	li	a0,-1
    8000529a:	bb7d                	j	80005058 <exec+0x98>
    8000529c:	e1243423          	sd	s2,-504(s0)
    800052a0:	b7dd                	j	80005286 <exec+0x2c6>
    800052a2:	e1243423          	sd	s2,-504(s0)
    800052a6:	b7c5                	j	80005286 <exec+0x2c6>
    800052a8:	e1243423          	sd	s2,-504(s0)
    800052ac:	bfe9                	j	80005286 <exec+0x2c6>
  sz = sz1;
    800052ae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052b2:	4481                	li	s1,0
    800052b4:	bfc9                	j	80005286 <exec+0x2c6>
  sz = sz1;
    800052b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052ba:	4481                	li	s1,0
    800052bc:	b7e9                	j	80005286 <exec+0x2c6>
  sz = sz1;
    800052be:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052c2:	4481                	li	s1,0
    800052c4:	b7c9                	j	80005286 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052c6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ca:	2b05                	addiw	s6,s6,1
    800052cc:	0389899b          	addiw	s3,s3,56
    800052d0:	e8845783          	lhu	a5,-376(s0)
    800052d4:	e2fb5be3          	bge	s6,a5,8000510a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052d8:	2981                	sext.w	s3,s3
    800052da:	03800713          	li	a4,56
    800052de:	86ce                	mv	a3,s3
    800052e0:	e1840613          	addi	a2,s0,-488
    800052e4:	4581                	li	a1,0
    800052e6:	8526                	mv	a0,s1
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	a8e080e7          	jalr	-1394(ra) # 80003d76 <readi>
    800052f0:	03800793          	li	a5,56
    800052f4:	f8f517e3          	bne	a0,a5,80005282 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800052f8:	e1842783          	lw	a5,-488(s0)
    800052fc:	4705                	li	a4,1
    800052fe:	fce796e3          	bne	a5,a4,800052ca <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005302:	e4043603          	ld	a2,-448(s0)
    80005306:	e3843783          	ld	a5,-456(s0)
    8000530a:	f8f669e3          	bltu	a2,a5,8000529c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000530e:	e2843783          	ld	a5,-472(s0)
    80005312:	963e                	add	a2,a2,a5
    80005314:	f8f667e3          	bltu	a2,a5,800052a2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005318:	85ca                	mv	a1,s2
    8000531a:	855e                	mv	a0,s7
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	106080e7          	jalr	262(ra) # 80001422 <uvmalloc>
    80005324:	e0a43423          	sd	a0,-504(s0)
    80005328:	d141                	beqz	a0,800052a8 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000532a:	e2843d03          	ld	s10,-472(s0)
    8000532e:	df043783          	ld	a5,-528(s0)
    80005332:	00fd77b3          	and	a5,s10,a5
    80005336:	fba1                	bnez	a5,80005286 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005338:	e2042d83          	lw	s11,-480(s0)
    8000533c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005340:	f80c03e3          	beqz	s8,800052c6 <exec+0x306>
    80005344:	8a62                	mv	s4,s8
    80005346:	4901                	li	s2,0
    80005348:	b345                	j	800050e8 <exec+0x128>

000000008000534a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000534a:	7179                	addi	sp,sp,-48
    8000534c:	f406                	sd	ra,40(sp)
    8000534e:	f022                	sd	s0,32(sp)
    80005350:	ec26                	sd	s1,24(sp)
    80005352:	e84a                	sd	s2,16(sp)
    80005354:	1800                	addi	s0,sp,48
    80005356:	892e                	mv	s2,a1
    80005358:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000535a:	fdc40593          	addi	a1,s0,-36
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	9f4080e7          	jalr	-1548(ra) # 80002d52 <argint>
    80005366:	04054063          	bltz	a0,800053a6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000536a:	fdc42703          	lw	a4,-36(s0)
    8000536e:	47bd                	li	a5,15
    80005370:	02e7ed63          	bltu	a5,a4,800053aa <argfd+0x60>
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	63c080e7          	jalr	1596(ra) # 800019b0 <myproc>
    8000537c:	fdc42703          	lw	a4,-36(s0)
    80005380:	01a70793          	addi	a5,a4,26
    80005384:	078e                	slli	a5,a5,0x3
    80005386:	953e                	add	a0,a0,a5
    80005388:	611c                	ld	a5,0(a0)
    8000538a:	c395                	beqz	a5,800053ae <argfd+0x64>
    return -1;
  if(pfd)
    8000538c:	00090463          	beqz	s2,80005394 <argfd+0x4a>
    *pfd = fd;
    80005390:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005394:	4501                	li	a0,0
  if(pf)
    80005396:	c091                	beqz	s1,8000539a <argfd+0x50>
    *pf = f;
    80005398:	e09c                	sd	a5,0(s1)
}
    8000539a:	70a2                	ld	ra,40(sp)
    8000539c:	7402                	ld	s0,32(sp)
    8000539e:	64e2                	ld	s1,24(sp)
    800053a0:	6942                	ld	s2,16(sp)
    800053a2:	6145                	addi	sp,sp,48
    800053a4:	8082                	ret
    return -1;
    800053a6:	557d                	li	a0,-1
    800053a8:	bfcd                	j	8000539a <argfd+0x50>
    return -1;
    800053aa:	557d                	li	a0,-1
    800053ac:	b7fd                	j	8000539a <argfd+0x50>
    800053ae:	557d                	li	a0,-1
    800053b0:	b7ed                	j	8000539a <argfd+0x50>

00000000800053b2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053b2:	1101                	addi	sp,sp,-32
    800053b4:	ec06                	sd	ra,24(sp)
    800053b6:	e822                	sd	s0,16(sp)
    800053b8:	e426                	sd	s1,8(sp)
    800053ba:	1000                	addi	s0,sp,32
    800053bc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	5f2080e7          	jalr	1522(ra) # 800019b0 <myproc>
    800053c6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053c8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800053cc:	4501                	li	a0,0
    800053ce:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053d0:	6398                	ld	a4,0(a5)
    800053d2:	cb19                	beqz	a4,800053e8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053d4:	2505                	addiw	a0,a0,1
    800053d6:	07a1                	addi	a5,a5,8
    800053d8:	fed51ce3          	bne	a0,a3,800053d0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053dc:	557d                	li	a0,-1
}
    800053de:	60e2                	ld	ra,24(sp)
    800053e0:	6442                	ld	s0,16(sp)
    800053e2:	64a2                	ld	s1,8(sp)
    800053e4:	6105                	addi	sp,sp,32
    800053e6:	8082                	ret
      p->ofile[fd] = f;
    800053e8:	01a50793          	addi	a5,a0,26
    800053ec:	078e                	slli	a5,a5,0x3
    800053ee:	963e                	add	a2,a2,a5
    800053f0:	e204                	sd	s1,0(a2)
      return fd;
    800053f2:	b7f5                	j	800053de <fdalloc+0x2c>

00000000800053f4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053f4:	715d                	addi	sp,sp,-80
    800053f6:	e486                	sd	ra,72(sp)
    800053f8:	e0a2                	sd	s0,64(sp)
    800053fa:	fc26                	sd	s1,56(sp)
    800053fc:	f84a                	sd	s2,48(sp)
    800053fe:	f44e                	sd	s3,40(sp)
    80005400:	f052                	sd	s4,32(sp)
    80005402:	ec56                	sd	s5,24(sp)
    80005404:	0880                	addi	s0,sp,80
    80005406:	89ae                	mv	s3,a1
    80005408:	8ab2                	mv	s5,a2
    8000540a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000540c:	fb040593          	addi	a1,s0,-80
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	e86080e7          	jalr	-378(ra) # 80004296 <nameiparent>
    80005418:	892a                	mv	s2,a0
    8000541a:	12050f63          	beqz	a0,80005558 <create+0x164>
    return 0;

  ilock(dp);
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	6a4080e7          	jalr	1700(ra) # 80003ac2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005426:	4601                	li	a2,0
    80005428:	fb040593          	addi	a1,s0,-80
    8000542c:	854a                	mv	a0,s2
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	b78080e7          	jalr	-1160(ra) # 80003fa6 <dirlookup>
    80005436:	84aa                	mv	s1,a0
    80005438:	c921                	beqz	a0,80005488 <create+0x94>
    iunlockput(dp);
    8000543a:	854a                	mv	a0,s2
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	8e8080e7          	jalr	-1816(ra) # 80003d24 <iunlockput>
    ilock(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	67c080e7          	jalr	1660(ra) # 80003ac2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000544e:	2981                	sext.w	s3,s3
    80005450:	4789                	li	a5,2
    80005452:	02f99463          	bne	s3,a5,8000547a <create+0x86>
    80005456:	0444d783          	lhu	a5,68(s1)
    8000545a:	37f9                	addiw	a5,a5,-2
    8000545c:	17c2                	slli	a5,a5,0x30
    8000545e:	93c1                	srli	a5,a5,0x30
    80005460:	4705                	li	a4,1
    80005462:	00f76c63          	bltu	a4,a5,8000547a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005466:	8526                	mv	a0,s1
    80005468:	60a6                	ld	ra,72(sp)
    8000546a:	6406                	ld	s0,64(sp)
    8000546c:	74e2                	ld	s1,56(sp)
    8000546e:	7942                	ld	s2,48(sp)
    80005470:	79a2                	ld	s3,40(sp)
    80005472:	7a02                	ld	s4,32(sp)
    80005474:	6ae2                	ld	s5,24(sp)
    80005476:	6161                	addi	sp,sp,80
    80005478:	8082                	ret
    iunlockput(ip);
    8000547a:	8526                	mv	a0,s1
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	8a8080e7          	jalr	-1880(ra) # 80003d24 <iunlockput>
    return 0;
    80005484:	4481                	li	s1,0
    80005486:	b7c5                	j	80005466 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005488:	85ce                	mv	a1,s3
    8000548a:	00092503          	lw	a0,0(s2)
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	49c080e7          	jalr	1180(ra) # 8000392a <ialloc>
    80005496:	84aa                	mv	s1,a0
    80005498:	c529                	beqz	a0,800054e2 <create+0xee>
  ilock(ip);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	628080e7          	jalr	1576(ra) # 80003ac2 <ilock>
  ip->major = major;
    800054a2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054a6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054aa:	4785                	li	a5,1
    800054ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	546080e7          	jalr	1350(ra) # 800039f8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054ba:	2981                	sext.w	s3,s3
    800054bc:	4785                	li	a5,1
    800054be:	02f98a63          	beq	s3,a5,800054f2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054c2:	40d0                	lw	a2,4(s1)
    800054c4:	fb040593          	addi	a1,s0,-80
    800054c8:	854a                	mv	a0,s2
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	cec080e7          	jalr	-788(ra) # 800041b6 <dirlink>
    800054d2:	06054b63          	bltz	a0,80005548 <create+0x154>
  iunlockput(dp);
    800054d6:	854a                	mv	a0,s2
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	84c080e7          	jalr	-1972(ra) # 80003d24 <iunlockput>
  return ip;
    800054e0:	b759                	j	80005466 <create+0x72>
    panic("create: ialloc");
    800054e2:	00003517          	auipc	a0,0x3
    800054e6:	2e650513          	addi	a0,a0,742 # 800087c8 <syscalls+0x2a8>
    800054ea:	ffffb097          	auipc	ra,0xffffb
    800054ee:	054080e7          	jalr	84(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800054f2:	04a95783          	lhu	a5,74(s2)
    800054f6:	2785                	addiw	a5,a5,1
    800054f8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	4fa080e7          	jalr	1274(ra) # 800039f8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005506:	40d0                	lw	a2,4(s1)
    80005508:	00003597          	auipc	a1,0x3
    8000550c:	2d058593          	addi	a1,a1,720 # 800087d8 <syscalls+0x2b8>
    80005510:	8526                	mv	a0,s1
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	ca4080e7          	jalr	-860(ra) # 800041b6 <dirlink>
    8000551a:	00054f63          	bltz	a0,80005538 <create+0x144>
    8000551e:	00492603          	lw	a2,4(s2)
    80005522:	00003597          	auipc	a1,0x3
    80005526:	2be58593          	addi	a1,a1,702 # 800087e0 <syscalls+0x2c0>
    8000552a:	8526                	mv	a0,s1
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	c8a080e7          	jalr	-886(ra) # 800041b6 <dirlink>
    80005534:	f80557e3          	bgez	a0,800054c2 <create+0xce>
      panic("create dots");
    80005538:	00003517          	auipc	a0,0x3
    8000553c:	2b050513          	addi	a0,a0,688 # 800087e8 <syscalls+0x2c8>
    80005540:	ffffb097          	auipc	ra,0xffffb
    80005544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005548:	00003517          	auipc	a0,0x3
    8000554c:	2b050513          	addi	a0,a0,688 # 800087f8 <syscalls+0x2d8>
    80005550:	ffffb097          	auipc	ra,0xffffb
    80005554:	fee080e7          	jalr	-18(ra) # 8000053e <panic>
    return 0;
    80005558:	84aa                	mv	s1,a0
    8000555a:	b731                	j	80005466 <create+0x72>

000000008000555c <sys_dup>:
{
    8000555c:	7179                	addi	sp,sp,-48
    8000555e:	f406                	sd	ra,40(sp)
    80005560:	f022                	sd	s0,32(sp)
    80005562:	ec26                	sd	s1,24(sp)
    80005564:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005566:	fd840613          	addi	a2,s0,-40
    8000556a:	4581                	li	a1,0
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	ddc080e7          	jalr	-548(ra) # 8000534a <argfd>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005578:	02054363          	bltz	a0,8000559e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000557c:	fd843503          	ld	a0,-40(s0)
    80005580:	00000097          	auipc	ra,0x0
    80005584:	e32080e7          	jalr	-462(ra) # 800053b2 <fdalloc>
    80005588:	84aa                	mv	s1,a0
    return -1;
    8000558a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000558c:	00054963          	bltz	a0,8000559e <sys_dup+0x42>
  filedup(f);
    80005590:	fd843503          	ld	a0,-40(s0)
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	37a080e7          	jalr	890(ra) # 8000490e <filedup>
  return fd;
    8000559c:	87a6                	mv	a5,s1
}
    8000559e:	853e                	mv	a0,a5
    800055a0:	70a2                	ld	ra,40(sp)
    800055a2:	7402                	ld	s0,32(sp)
    800055a4:	64e2                	ld	s1,24(sp)
    800055a6:	6145                	addi	sp,sp,48
    800055a8:	8082                	ret

00000000800055aa <sys_read>:
{
    800055aa:	7179                	addi	sp,sp,-48
    800055ac:	f406                	sd	ra,40(sp)
    800055ae:	f022                	sd	s0,32(sp)
    800055b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b2:	fe840613          	addi	a2,s0,-24
    800055b6:	4581                	li	a1,0
    800055b8:	4501                	li	a0,0
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	d90080e7          	jalr	-624(ra) # 8000534a <argfd>
    return -1;
    800055c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c4:	04054163          	bltz	a0,80005606 <sys_read+0x5c>
    800055c8:	fe440593          	addi	a1,s0,-28
    800055cc:	4509                	li	a0,2
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	784080e7          	jalr	1924(ra) # 80002d52 <argint>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d8:	02054763          	bltz	a0,80005606 <sys_read+0x5c>
    800055dc:	fd840593          	addi	a1,s0,-40
    800055e0:	4505                	li	a0,1
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	792080e7          	jalr	1938(ra) # 80002d74 <argaddr>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ec:	00054d63          	bltz	a0,80005606 <sys_read+0x5c>
  return fileread(f, p, n);
    800055f0:	fe442603          	lw	a2,-28(s0)
    800055f4:	fd843583          	ld	a1,-40(s0)
    800055f8:	fe843503          	ld	a0,-24(s0)
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	49e080e7          	jalr	1182(ra) # 80004a9a <fileread>
    80005604:	87aa                	mv	a5,a0
}
    80005606:	853e                	mv	a0,a5
    80005608:	70a2                	ld	ra,40(sp)
    8000560a:	7402                	ld	s0,32(sp)
    8000560c:	6145                	addi	sp,sp,48
    8000560e:	8082                	ret

0000000080005610 <sys_write>:
{
    80005610:	7179                	addi	sp,sp,-48
    80005612:	f406                	sd	ra,40(sp)
    80005614:	f022                	sd	s0,32(sp)
    80005616:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005618:	fe840613          	addi	a2,s0,-24
    8000561c:	4581                	li	a1,0
    8000561e:	4501                	li	a0,0
    80005620:	00000097          	auipc	ra,0x0
    80005624:	d2a080e7          	jalr	-726(ra) # 8000534a <argfd>
    return -1;
    80005628:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562a:	04054163          	bltz	a0,8000566c <sys_write+0x5c>
    8000562e:	fe440593          	addi	a1,s0,-28
    80005632:	4509                	li	a0,2
    80005634:	ffffd097          	auipc	ra,0xffffd
    80005638:	71e080e7          	jalr	1822(ra) # 80002d52 <argint>
    return -1;
    8000563c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563e:	02054763          	bltz	a0,8000566c <sys_write+0x5c>
    80005642:	fd840593          	addi	a1,s0,-40
    80005646:	4505                	li	a0,1
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	72c080e7          	jalr	1836(ra) # 80002d74 <argaddr>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005652:	00054d63          	bltz	a0,8000566c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005656:	fe442603          	lw	a2,-28(s0)
    8000565a:	fd843583          	ld	a1,-40(s0)
    8000565e:	fe843503          	ld	a0,-24(s0)
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	4fa080e7          	jalr	1274(ra) # 80004b5c <filewrite>
    8000566a:	87aa                	mv	a5,a0
}
    8000566c:	853e                	mv	a0,a5
    8000566e:	70a2                	ld	ra,40(sp)
    80005670:	7402                	ld	s0,32(sp)
    80005672:	6145                	addi	sp,sp,48
    80005674:	8082                	ret

0000000080005676 <sys_close>:
{
    80005676:	1101                	addi	sp,sp,-32
    80005678:	ec06                	sd	ra,24(sp)
    8000567a:	e822                	sd	s0,16(sp)
    8000567c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000567e:	fe040613          	addi	a2,s0,-32
    80005682:	fec40593          	addi	a1,s0,-20
    80005686:	4501                	li	a0,0
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	cc2080e7          	jalr	-830(ra) # 8000534a <argfd>
    return -1;
    80005690:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005692:	02054463          	bltz	a0,800056ba <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	31a080e7          	jalr	794(ra) # 800019b0 <myproc>
    8000569e:	fec42783          	lw	a5,-20(s0)
    800056a2:	07e9                	addi	a5,a5,26
    800056a4:	078e                	slli	a5,a5,0x3
    800056a6:	97aa                	add	a5,a5,a0
    800056a8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056ac:	fe043503          	ld	a0,-32(s0)
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	2b0080e7          	jalr	688(ra) # 80004960 <fileclose>
  return 0;
    800056b8:	4781                	li	a5,0
}
    800056ba:	853e                	mv	a0,a5
    800056bc:	60e2                	ld	ra,24(sp)
    800056be:	6442                	ld	s0,16(sp)
    800056c0:	6105                	addi	sp,sp,32
    800056c2:	8082                	ret

00000000800056c4 <sys_fstat>:
{
    800056c4:	1101                	addi	sp,sp,-32
    800056c6:	ec06                	sd	ra,24(sp)
    800056c8:	e822                	sd	s0,16(sp)
    800056ca:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056cc:	fe840613          	addi	a2,s0,-24
    800056d0:	4581                	li	a1,0
    800056d2:	4501                	li	a0,0
    800056d4:	00000097          	auipc	ra,0x0
    800056d8:	c76080e7          	jalr	-906(ra) # 8000534a <argfd>
    return -1;
    800056dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056de:	02054563          	bltz	a0,80005708 <sys_fstat+0x44>
    800056e2:	fe040593          	addi	a1,s0,-32
    800056e6:	4505                	li	a0,1
    800056e8:	ffffd097          	auipc	ra,0xffffd
    800056ec:	68c080e7          	jalr	1676(ra) # 80002d74 <argaddr>
    return -1;
    800056f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056f2:	00054b63          	bltz	a0,80005708 <sys_fstat+0x44>
  return filestat(f, st);
    800056f6:	fe043583          	ld	a1,-32(s0)
    800056fa:	fe843503          	ld	a0,-24(s0)
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	32a080e7          	jalr	810(ra) # 80004a28 <filestat>
    80005706:	87aa                	mv	a5,a0
}
    80005708:	853e                	mv	a0,a5
    8000570a:	60e2                	ld	ra,24(sp)
    8000570c:	6442                	ld	s0,16(sp)
    8000570e:	6105                	addi	sp,sp,32
    80005710:	8082                	ret

0000000080005712 <sys_link>:
{
    80005712:	7169                	addi	sp,sp,-304
    80005714:	f606                	sd	ra,296(sp)
    80005716:	f222                	sd	s0,288(sp)
    80005718:	ee26                	sd	s1,280(sp)
    8000571a:	ea4a                	sd	s2,272(sp)
    8000571c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000571e:	08000613          	li	a2,128
    80005722:	ed040593          	addi	a1,s0,-304
    80005726:	4501                	li	a0,0
    80005728:	ffffd097          	auipc	ra,0xffffd
    8000572c:	66e080e7          	jalr	1646(ra) # 80002d96 <argstr>
    return -1;
    80005730:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005732:	10054e63          	bltz	a0,8000584e <sys_link+0x13c>
    80005736:	08000613          	li	a2,128
    8000573a:	f5040593          	addi	a1,s0,-176
    8000573e:	4505                	li	a0,1
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	656080e7          	jalr	1622(ra) # 80002d96 <argstr>
    return -1;
    80005748:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000574a:	10054263          	bltz	a0,8000584e <sys_link+0x13c>
  begin_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	d46080e7          	jalr	-698(ra) # 80004494 <begin_op>
  if((ip = namei(old)) == 0){
    80005756:	ed040513          	addi	a0,s0,-304
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	b1e080e7          	jalr	-1250(ra) # 80004278 <namei>
    80005762:	84aa                	mv	s1,a0
    80005764:	c551                	beqz	a0,800057f0 <sys_link+0xde>
  ilock(ip);
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	35c080e7          	jalr	860(ra) # 80003ac2 <ilock>
  if(ip->type == T_DIR){
    8000576e:	04449703          	lh	a4,68(s1)
    80005772:	4785                	li	a5,1
    80005774:	08f70463          	beq	a4,a5,800057fc <sys_link+0xea>
  ip->nlink++;
    80005778:	04a4d783          	lhu	a5,74(s1)
    8000577c:	2785                	addiw	a5,a5,1
    8000577e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	274080e7          	jalr	628(ra) # 800039f8 <iupdate>
  iunlock(ip);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	3f6080e7          	jalr	1014(ra) # 80003b84 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005796:	fd040593          	addi	a1,s0,-48
    8000579a:	f5040513          	addi	a0,s0,-176
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	af8080e7          	jalr	-1288(ra) # 80004296 <nameiparent>
    800057a6:	892a                	mv	s2,a0
    800057a8:	c935                	beqz	a0,8000581c <sys_link+0x10a>
  ilock(dp);
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	318080e7          	jalr	792(ra) # 80003ac2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057b2:	00092703          	lw	a4,0(s2)
    800057b6:	409c                	lw	a5,0(s1)
    800057b8:	04f71d63          	bne	a4,a5,80005812 <sys_link+0x100>
    800057bc:	40d0                	lw	a2,4(s1)
    800057be:	fd040593          	addi	a1,s0,-48
    800057c2:	854a                	mv	a0,s2
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	9f2080e7          	jalr	-1550(ra) # 800041b6 <dirlink>
    800057cc:	04054363          	bltz	a0,80005812 <sys_link+0x100>
  iunlockput(dp);
    800057d0:	854a                	mv	a0,s2
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	552080e7          	jalr	1362(ra) # 80003d24 <iunlockput>
  iput(ip);
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	4a0080e7          	jalr	1184(ra) # 80003c7c <iput>
  end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	d30080e7          	jalr	-720(ra) # 80004514 <end_op>
  return 0;
    800057ec:	4781                	li	a5,0
    800057ee:	a085                	j	8000584e <sys_link+0x13c>
    end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	d24080e7          	jalr	-732(ra) # 80004514 <end_op>
    return -1;
    800057f8:	57fd                	li	a5,-1
    800057fa:	a891                	j	8000584e <sys_link+0x13c>
    iunlockput(ip);
    800057fc:	8526                	mv	a0,s1
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	526080e7          	jalr	1318(ra) # 80003d24 <iunlockput>
    end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	d0e080e7          	jalr	-754(ra) # 80004514 <end_op>
    return -1;
    8000580e:	57fd                	li	a5,-1
    80005810:	a83d                	j	8000584e <sys_link+0x13c>
    iunlockput(dp);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	510080e7          	jalr	1296(ra) # 80003d24 <iunlockput>
  ilock(ip);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	2a4080e7          	jalr	676(ra) # 80003ac2 <ilock>
  ip->nlink--;
    80005826:	04a4d783          	lhu	a5,74(s1)
    8000582a:	37fd                	addiw	a5,a5,-1
    8000582c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	1c6080e7          	jalr	454(ra) # 800039f8 <iupdate>
  iunlockput(ip);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	4e8080e7          	jalr	1256(ra) # 80003d24 <iunlockput>
  end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	cd0080e7          	jalr	-816(ra) # 80004514 <end_op>
  return -1;
    8000584c:	57fd                	li	a5,-1
}
    8000584e:	853e                	mv	a0,a5
    80005850:	70b2                	ld	ra,296(sp)
    80005852:	7412                	ld	s0,288(sp)
    80005854:	64f2                	ld	s1,280(sp)
    80005856:	6952                	ld	s2,272(sp)
    80005858:	6155                	addi	sp,sp,304
    8000585a:	8082                	ret

000000008000585c <sys_unlink>:
{
    8000585c:	7151                	addi	sp,sp,-240
    8000585e:	f586                	sd	ra,232(sp)
    80005860:	f1a2                	sd	s0,224(sp)
    80005862:	eda6                	sd	s1,216(sp)
    80005864:	e9ca                	sd	s2,208(sp)
    80005866:	e5ce                	sd	s3,200(sp)
    80005868:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000586a:	08000613          	li	a2,128
    8000586e:	f3040593          	addi	a1,s0,-208
    80005872:	4501                	li	a0,0
    80005874:	ffffd097          	auipc	ra,0xffffd
    80005878:	522080e7          	jalr	1314(ra) # 80002d96 <argstr>
    8000587c:	18054163          	bltz	a0,800059fe <sys_unlink+0x1a2>
  begin_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	c14080e7          	jalr	-1004(ra) # 80004494 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005888:	fb040593          	addi	a1,s0,-80
    8000588c:	f3040513          	addi	a0,s0,-208
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	a06080e7          	jalr	-1530(ra) # 80004296 <nameiparent>
    80005898:	84aa                	mv	s1,a0
    8000589a:	c979                	beqz	a0,80005970 <sys_unlink+0x114>
  ilock(dp);
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	226080e7          	jalr	550(ra) # 80003ac2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058a4:	00003597          	auipc	a1,0x3
    800058a8:	f3458593          	addi	a1,a1,-204 # 800087d8 <syscalls+0x2b8>
    800058ac:	fb040513          	addi	a0,s0,-80
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	6dc080e7          	jalr	1756(ra) # 80003f8c <namecmp>
    800058b8:	14050a63          	beqz	a0,80005a0c <sys_unlink+0x1b0>
    800058bc:	00003597          	auipc	a1,0x3
    800058c0:	f2458593          	addi	a1,a1,-220 # 800087e0 <syscalls+0x2c0>
    800058c4:	fb040513          	addi	a0,s0,-80
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	6c4080e7          	jalr	1732(ra) # 80003f8c <namecmp>
    800058d0:	12050e63          	beqz	a0,80005a0c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058d4:	f2c40613          	addi	a2,s0,-212
    800058d8:	fb040593          	addi	a1,s0,-80
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	6c8080e7          	jalr	1736(ra) # 80003fa6 <dirlookup>
    800058e6:	892a                	mv	s2,a0
    800058e8:	12050263          	beqz	a0,80005a0c <sys_unlink+0x1b0>
  ilock(ip);
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	1d6080e7          	jalr	470(ra) # 80003ac2 <ilock>
  if(ip->nlink < 1)
    800058f4:	04a91783          	lh	a5,74(s2)
    800058f8:	08f05263          	blez	a5,8000597c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058fc:	04491703          	lh	a4,68(s2)
    80005900:	4785                	li	a5,1
    80005902:	08f70563          	beq	a4,a5,8000598c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005906:	4641                	li	a2,16
    80005908:	4581                	li	a1,0
    8000590a:	fc040513          	addi	a0,s0,-64
    8000590e:	ffffb097          	auipc	ra,0xffffb
    80005912:	3d2080e7          	jalr	978(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005916:	4741                	li	a4,16
    80005918:	f2c42683          	lw	a3,-212(s0)
    8000591c:	fc040613          	addi	a2,s0,-64
    80005920:	4581                	li	a1,0
    80005922:	8526                	mv	a0,s1
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	54a080e7          	jalr	1354(ra) # 80003e6e <writei>
    8000592c:	47c1                	li	a5,16
    8000592e:	0af51563          	bne	a0,a5,800059d8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005932:	04491703          	lh	a4,68(s2)
    80005936:	4785                	li	a5,1
    80005938:	0af70863          	beq	a4,a5,800059e8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	3e6080e7          	jalr	998(ra) # 80003d24 <iunlockput>
  ip->nlink--;
    80005946:	04a95783          	lhu	a5,74(s2)
    8000594a:	37fd                	addiw	a5,a5,-1
    8000594c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005950:	854a                	mv	a0,s2
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	0a6080e7          	jalr	166(ra) # 800039f8 <iupdate>
  iunlockput(ip);
    8000595a:	854a                	mv	a0,s2
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	3c8080e7          	jalr	968(ra) # 80003d24 <iunlockput>
  end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	bb0080e7          	jalr	-1104(ra) # 80004514 <end_op>
  return 0;
    8000596c:	4501                	li	a0,0
    8000596e:	a84d                	j	80005a20 <sys_unlink+0x1c4>
    end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	ba4080e7          	jalr	-1116(ra) # 80004514 <end_op>
    return -1;
    80005978:	557d                	li	a0,-1
    8000597a:	a05d                	j	80005a20 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000597c:	00003517          	auipc	a0,0x3
    80005980:	e8c50513          	addi	a0,a0,-372 # 80008808 <syscalls+0x2e8>
    80005984:	ffffb097          	auipc	ra,0xffffb
    80005988:	bba080e7          	jalr	-1094(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000598c:	04c92703          	lw	a4,76(s2)
    80005990:	02000793          	li	a5,32
    80005994:	f6e7f9e3          	bgeu	a5,a4,80005906 <sys_unlink+0xaa>
    80005998:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000599c:	4741                	li	a4,16
    8000599e:	86ce                	mv	a3,s3
    800059a0:	f1840613          	addi	a2,s0,-232
    800059a4:	4581                	li	a1,0
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	3ce080e7          	jalr	974(ra) # 80003d76 <readi>
    800059b0:	47c1                	li	a5,16
    800059b2:	00f51b63          	bne	a0,a5,800059c8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059b6:	f1845783          	lhu	a5,-232(s0)
    800059ba:	e7a1                	bnez	a5,80005a02 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059bc:	29c1                	addiw	s3,s3,16
    800059be:	04c92783          	lw	a5,76(s2)
    800059c2:	fcf9ede3          	bltu	s3,a5,8000599c <sys_unlink+0x140>
    800059c6:	b781                	j	80005906 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059c8:	00003517          	auipc	a0,0x3
    800059cc:	e5850513          	addi	a0,a0,-424 # 80008820 <syscalls+0x300>
    800059d0:	ffffb097          	auipc	ra,0xffffb
    800059d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>
    panic("unlink: writei");
    800059d8:	00003517          	auipc	a0,0x3
    800059dc:	e6050513          	addi	a0,a0,-416 # 80008838 <syscalls+0x318>
    800059e0:	ffffb097          	auipc	ra,0xffffb
    800059e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>
    dp->nlink--;
    800059e8:	04a4d783          	lhu	a5,74(s1)
    800059ec:	37fd                	addiw	a5,a5,-1
    800059ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	004080e7          	jalr	4(ra) # 800039f8 <iupdate>
    800059fc:	b781                	j	8000593c <sys_unlink+0xe0>
    return -1;
    800059fe:	557d                	li	a0,-1
    80005a00:	a005                	j	80005a20 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a02:	854a                	mv	a0,s2
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	320080e7          	jalr	800(ra) # 80003d24 <iunlockput>
  iunlockput(dp);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	316080e7          	jalr	790(ra) # 80003d24 <iunlockput>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	afe080e7          	jalr	-1282(ra) # 80004514 <end_op>
  return -1;
    80005a1e:	557d                	li	a0,-1
}
    80005a20:	70ae                	ld	ra,232(sp)
    80005a22:	740e                	ld	s0,224(sp)
    80005a24:	64ee                	ld	s1,216(sp)
    80005a26:	694e                	ld	s2,208(sp)
    80005a28:	69ae                	ld	s3,200(sp)
    80005a2a:	616d                	addi	sp,sp,240
    80005a2c:	8082                	ret

0000000080005a2e <sys_open>:

uint64
sys_open(void)
{
    80005a2e:	7131                	addi	sp,sp,-192
    80005a30:	fd06                	sd	ra,184(sp)
    80005a32:	f922                	sd	s0,176(sp)
    80005a34:	f526                	sd	s1,168(sp)
    80005a36:	f14a                	sd	s2,160(sp)
    80005a38:	ed4e                	sd	s3,152(sp)
    80005a3a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a3c:	08000613          	li	a2,128
    80005a40:	f5040593          	addi	a1,s0,-176
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	350080e7          	jalr	848(ra) # 80002d96 <argstr>
    return -1;
    80005a4e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a50:	0c054163          	bltz	a0,80005b12 <sys_open+0xe4>
    80005a54:	f4c40593          	addi	a1,s0,-180
    80005a58:	4505                	li	a0,1
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	2f8080e7          	jalr	760(ra) # 80002d52 <argint>
    80005a62:	0a054863          	bltz	a0,80005b12 <sys_open+0xe4>

  begin_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	a2e080e7          	jalr	-1490(ra) # 80004494 <begin_op>

  if(omode & O_CREATE){
    80005a6e:	f4c42783          	lw	a5,-180(s0)
    80005a72:	2007f793          	andi	a5,a5,512
    80005a76:	cbdd                	beqz	a5,80005b2c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a78:	4681                	li	a3,0
    80005a7a:	4601                	li	a2,0
    80005a7c:	4589                	li	a1,2
    80005a7e:	f5040513          	addi	a0,s0,-176
    80005a82:	00000097          	auipc	ra,0x0
    80005a86:	972080e7          	jalr	-1678(ra) # 800053f4 <create>
    80005a8a:	892a                	mv	s2,a0
    if(ip == 0){
    80005a8c:	c959                	beqz	a0,80005b22 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a8e:	04491703          	lh	a4,68(s2)
    80005a92:	478d                	li	a5,3
    80005a94:	00f71763          	bne	a4,a5,80005aa2 <sys_open+0x74>
    80005a98:	04695703          	lhu	a4,70(s2)
    80005a9c:	47a5                	li	a5,9
    80005a9e:	0ce7ec63          	bltu	a5,a4,80005b76 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	e02080e7          	jalr	-510(ra) # 800048a4 <filealloc>
    80005aaa:	89aa                	mv	s3,a0
    80005aac:	10050263          	beqz	a0,80005bb0 <sys_open+0x182>
    80005ab0:	00000097          	auipc	ra,0x0
    80005ab4:	902080e7          	jalr	-1790(ra) # 800053b2 <fdalloc>
    80005ab8:	84aa                	mv	s1,a0
    80005aba:	0e054663          	bltz	a0,80005ba6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005abe:	04491703          	lh	a4,68(s2)
    80005ac2:	478d                	li	a5,3
    80005ac4:	0cf70463          	beq	a4,a5,80005b8c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ac8:	4789                	li	a5,2
    80005aca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ace:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ad2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ad6:	f4c42783          	lw	a5,-180(s0)
    80005ada:	0017c713          	xori	a4,a5,1
    80005ade:	8b05                	andi	a4,a4,1
    80005ae0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ae4:	0037f713          	andi	a4,a5,3
    80005ae8:	00e03733          	snez	a4,a4
    80005aec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005af0:	4007f793          	andi	a5,a5,1024
    80005af4:	c791                	beqz	a5,80005b00 <sys_open+0xd2>
    80005af6:	04491703          	lh	a4,68(s2)
    80005afa:	4789                	li	a5,2
    80005afc:	08f70f63          	beq	a4,a5,80005b9a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b00:	854a                	mv	a0,s2
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	082080e7          	jalr	130(ra) # 80003b84 <iunlock>
  end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	a0a080e7          	jalr	-1526(ra) # 80004514 <end_op>

  return fd;
}
    80005b12:	8526                	mv	a0,s1
    80005b14:	70ea                	ld	ra,184(sp)
    80005b16:	744a                	ld	s0,176(sp)
    80005b18:	74aa                	ld	s1,168(sp)
    80005b1a:	790a                	ld	s2,160(sp)
    80005b1c:	69ea                	ld	s3,152(sp)
    80005b1e:	6129                	addi	sp,sp,192
    80005b20:	8082                	ret
      end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	9f2080e7          	jalr	-1550(ra) # 80004514 <end_op>
      return -1;
    80005b2a:	b7e5                	j	80005b12 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b2c:	f5040513          	addi	a0,s0,-176
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	748080e7          	jalr	1864(ra) # 80004278 <namei>
    80005b38:	892a                	mv	s2,a0
    80005b3a:	c905                	beqz	a0,80005b6a <sys_open+0x13c>
    ilock(ip);
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	f86080e7          	jalr	-122(ra) # 80003ac2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b44:	04491703          	lh	a4,68(s2)
    80005b48:	4785                	li	a5,1
    80005b4a:	f4f712e3          	bne	a4,a5,80005a8e <sys_open+0x60>
    80005b4e:	f4c42783          	lw	a5,-180(s0)
    80005b52:	dba1                	beqz	a5,80005aa2 <sys_open+0x74>
      iunlockput(ip);
    80005b54:	854a                	mv	a0,s2
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	1ce080e7          	jalr	462(ra) # 80003d24 <iunlockput>
      end_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	9b6080e7          	jalr	-1610(ra) # 80004514 <end_op>
      return -1;
    80005b66:	54fd                	li	s1,-1
    80005b68:	b76d                	j	80005b12 <sys_open+0xe4>
      end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	9aa080e7          	jalr	-1622(ra) # 80004514 <end_op>
      return -1;
    80005b72:	54fd                	li	s1,-1
    80005b74:	bf79                	j	80005b12 <sys_open+0xe4>
    iunlockput(ip);
    80005b76:	854a                	mv	a0,s2
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	1ac080e7          	jalr	428(ra) # 80003d24 <iunlockput>
    end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	994080e7          	jalr	-1644(ra) # 80004514 <end_op>
    return -1;
    80005b88:	54fd                	li	s1,-1
    80005b8a:	b761                	j	80005b12 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b8c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b90:	04691783          	lh	a5,70(s2)
    80005b94:	02f99223          	sh	a5,36(s3)
    80005b98:	bf2d                	j	80005ad2 <sys_open+0xa4>
    itrunc(ip);
    80005b9a:	854a                	mv	a0,s2
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	034080e7          	jalr	52(ra) # 80003bd0 <itrunc>
    80005ba4:	bfb1                	j	80005b00 <sys_open+0xd2>
      fileclose(f);
    80005ba6:	854e                	mv	a0,s3
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	db8080e7          	jalr	-584(ra) # 80004960 <fileclose>
    iunlockput(ip);
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	172080e7          	jalr	370(ra) # 80003d24 <iunlockput>
    end_op();
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	95a080e7          	jalr	-1702(ra) # 80004514 <end_op>
    return -1;
    80005bc2:	54fd                	li	s1,-1
    80005bc4:	b7b9                	j	80005b12 <sys_open+0xe4>

0000000080005bc6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bc6:	7175                	addi	sp,sp,-144
    80005bc8:	e506                	sd	ra,136(sp)
    80005bca:	e122                	sd	s0,128(sp)
    80005bcc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	8c6080e7          	jalr	-1850(ra) # 80004494 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bd6:	08000613          	li	a2,128
    80005bda:	f7040593          	addi	a1,s0,-144
    80005bde:	4501                	li	a0,0
    80005be0:	ffffd097          	auipc	ra,0xffffd
    80005be4:	1b6080e7          	jalr	438(ra) # 80002d96 <argstr>
    80005be8:	02054963          	bltz	a0,80005c1a <sys_mkdir+0x54>
    80005bec:	4681                	li	a3,0
    80005bee:	4601                	li	a2,0
    80005bf0:	4585                	li	a1,1
    80005bf2:	f7040513          	addi	a0,s0,-144
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	7fe080e7          	jalr	2046(ra) # 800053f4 <create>
    80005bfe:	cd11                	beqz	a0,80005c1a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	124080e7          	jalr	292(ra) # 80003d24 <iunlockput>
  end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	90c080e7          	jalr	-1780(ra) # 80004514 <end_op>
  return 0;
    80005c10:	4501                	li	a0,0
}
    80005c12:	60aa                	ld	ra,136(sp)
    80005c14:	640a                	ld	s0,128(sp)
    80005c16:	6149                	addi	sp,sp,144
    80005c18:	8082                	ret
    end_op();
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	8fa080e7          	jalr	-1798(ra) # 80004514 <end_op>
    return -1;
    80005c22:	557d                	li	a0,-1
    80005c24:	b7fd                	j	80005c12 <sys_mkdir+0x4c>

0000000080005c26 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c26:	7135                	addi	sp,sp,-160
    80005c28:	ed06                	sd	ra,152(sp)
    80005c2a:	e922                	sd	s0,144(sp)
    80005c2c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	866080e7          	jalr	-1946(ra) # 80004494 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c36:	08000613          	li	a2,128
    80005c3a:	f7040593          	addi	a1,s0,-144
    80005c3e:	4501                	li	a0,0
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	156080e7          	jalr	342(ra) # 80002d96 <argstr>
    80005c48:	04054a63          	bltz	a0,80005c9c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c4c:	f6c40593          	addi	a1,s0,-148
    80005c50:	4505                	li	a0,1
    80005c52:	ffffd097          	auipc	ra,0xffffd
    80005c56:	100080e7          	jalr	256(ra) # 80002d52 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c5a:	04054163          	bltz	a0,80005c9c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c5e:	f6840593          	addi	a1,s0,-152
    80005c62:	4509                	li	a0,2
    80005c64:	ffffd097          	auipc	ra,0xffffd
    80005c68:	0ee080e7          	jalr	238(ra) # 80002d52 <argint>
     argint(1, &major) < 0 ||
    80005c6c:	02054863          	bltz	a0,80005c9c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c70:	f6841683          	lh	a3,-152(s0)
    80005c74:	f6c41603          	lh	a2,-148(s0)
    80005c78:	458d                	li	a1,3
    80005c7a:	f7040513          	addi	a0,s0,-144
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	776080e7          	jalr	1910(ra) # 800053f4 <create>
     argint(2, &minor) < 0 ||
    80005c86:	c919                	beqz	a0,80005c9c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	09c080e7          	jalr	156(ra) # 80003d24 <iunlockput>
  end_op();
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	884080e7          	jalr	-1916(ra) # 80004514 <end_op>
  return 0;
    80005c98:	4501                	li	a0,0
    80005c9a:	a031                	j	80005ca6 <sys_mknod+0x80>
    end_op();
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	878080e7          	jalr	-1928(ra) # 80004514 <end_op>
    return -1;
    80005ca4:	557d                	li	a0,-1
}
    80005ca6:	60ea                	ld	ra,152(sp)
    80005ca8:	644a                	ld	s0,144(sp)
    80005caa:	610d                	addi	sp,sp,160
    80005cac:	8082                	ret

0000000080005cae <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cae:	7135                	addi	sp,sp,-160
    80005cb0:	ed06                	sd	ra,152(sp)
    80005cb2:	e922                	sd	s0,144(sp)
    80005cb4:	e526                	sd	s1,136(sp)
    80005cb6:	e14a                	sd	s2,128(sp)
    80005cb8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cba:	ffffc097          	auipc	ra,0xffffc
    80005cbe:	cf6080e7          	jalr	-778(ra) # 800019b0 <myproc>
    80005cc2:	892a                	mv	s2,a0
  
  begin_op();
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	7d0080e7          	jalr	2000(ra) # 80004494 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ccc:	08000613          	li	a2,128
    80005cd0:	f6040593          	addi	a1,s0,-160
    80005cd4:	4501                	li	a0,0
    80005cd6:	ffffd097          	auipc	ra,0xffffd
    80005cda:	0c0080e7          	jalr	192(ra) # 80002d96 <argstr>
    80005cde:	04054b63          	bltz	a0,80005d34 <sys_chdir+0x86>
    80005ce2:	f6040513          	addi	a0,s0,-160
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	592080e7          	jalr	1426(ra) # 80004278 <namei>
    80005cee:	84aa                	mv	s1,a0
    80005cf0:	c131                	beqz	a0,80005d34 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	dd0080e7          	jalr	-560(ra) # 80003ac2 <ilock>
  if(ip->type != T_DIR){
    80005cfa:	04449703          	lh	a4,68(s1)
    80005cfe:	4785                	li	a5,1
    80005d00:	04f71063          	bne	a4,a5,80005d40 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d04:	8526                	mv	a0,s1
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	e7e080e7          	jalr	-386(ra) # 80003b84 <iunlock>
  iput(p->cwd);
    80005d0e:	15093503          	ld	a0,336(s2)
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	f6a080e7          	jalr	-150(ra) # 80003c7c <iput>
  end_op();
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	7fa080e7          	jalr	2042(ra) # 80004514 <end_op>
  p->cwd = ip;
    80005d22:	14993823          	sd	s1,336(s2)
  return 0;
    80005d26:	4501                	li	a0,0
}
    80005d28:	60ea                	ld	ra,152(sp)
    80005d2a:	644a                	ld	s0,144(sp)
    80005d2c:	64aa                	ld	s1,136(sp)
    80005d2e:	690a                	ld	s2,128(sp)
    80005d30:	610d                	addi	sp,sp,160
    80005d32:	8082                	ret
    end_op();
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	7e0080e7          	jalr	2016(ra) # 80004514 <end_op>
    return -1;
    80005d3c:	557d                	li	a0,-1
    80005d3e:	b7ed                	j	80005d28 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d40:	8526                	mv	a0,s1
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	fe2080e7          	jalr	-30(ra) # 80003d24 <iunlockput>
    end_op();
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	7ca080e7          	jalr	1994(ra) # 80004514 <end_op>
    return -1;
    80005d52:	557d                	li	a0,-1
    80005d54:	bfd1                	j	80005d28 <sys_chdir+0x7a>

0000000080005d56 <sys_exec>:

uint64
sys_exec(void)
{
    80005d56:	7145                	addi	sp,sp,-464
    80005d58:	e786                	sd	ra,456(sp)
    80005d5a:	e3a2                	sd	s0,448(sp)
    80005d5c:	ff26                	sd	s1,440(sp)
    80005d5e:	fb4a                	sd	s2,432(sp)
    80005d60:	f74e                	sd	s3,424(sp)
    80005d62:	f352                	sd	s4,416(sp)
    80005d64:	ef56                	sd	s5,408(sp)
    80005d66:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d68:	08000613          	li	a2,128
    80005d6c:	f4040593          	addi	a1,s0,-192
    80005d70:	4501                	li	a0,0
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	024080e7          	jalr	36(ra) # 80002d96 <argstr>
    return -1;
    80005d7a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d7c:	0c054a63          	bltz	a0,80005e50 <sys_exec+0xfa>
    80005d80:	e3840593          	addi	a1,s0,-456
    80005d84:	4505                	li	a0,1
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	fee080e7          	jalr	-18(ra) # 80002d74 <argaddr>
    80005d8e:	0c054163          	bltz	a0,80005e50 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d92:	10000613          	li	a2,256
    80005d96:	4581                	li	a1,0
    80005d98:	e4040513          	addi	a0,s0,-448
    80005d9c:	ffffb097          	auipc	ra,0xffffb
    80005da0:	f44080e7          	jalr	-188(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005da4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005da8:	89a6                	mv	s3,s1
    80005daa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dac:	02000a13          	li	s4,32
    80005db0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005db4:	00391513          	slli	a0,s2,0x3
    80005db8:	e3040593          	addi	a1,s0,-464
    80005dbc:	e3843783          	ld	a5,-456(s0)
    80005dc0:	953e                	add	a0,a0,a5
    80005dc2:	ffffd097          	auipc	ra,0xffffd
    80005dc6:	ef6080e7          	jalr	-266(ra) # 80002cb8 <fetchaddr>
    80005dca:	02054a63          	bltz	a0,80005dfe <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005dce:	e3043783          	ld	a5,-464(s0)
    80005dd2:	c3b9                	beqz	a5,80005e18 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dd4:	ffffb097          	auipc	ra,0xffffb
    80005dd8:	d20080e7          	jalr	-736(ra) # 80000af4 <kalloc>
    80005ddc:	85aa                	mv	a1,a0
    80005dde:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005de2:	cd11                	beqz	a0,80005dfe <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005de4:	6605                	lui	a2,0x1
    80005de6:	e3043503          	ld	a0,-464(s0)
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	f20080e7          	jalr	-224(ra) # 80002d0a <fetchstr>
    80005df2:	00054663          	bltz	a0,80005dfe <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005df6:	0905                	addi	s2,s2,1
    80005df8:	09a1                	addi	s3,s3,8
    80005dfa:	fb491be3          	bne	s2,s4,80005db0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dfe:	10048913          	addi	s2,s1,256
    80005e02:	6088                	ld	a0,0(s1)
    80005e04:	c529                	beqz	a0,80005e4e <sys_exec+0xf8>
    kfree(argv[i]);
    80005e06:	ffffb097          	auipc	ra,0xffffb
    80005e0a:	bf2080e7          	jalr	-1038(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e0e:	04a1                	addi	s1,s1,8
    80005e10:	ff2499e3          	bne	s1,s2,80005e02 <sys_exec+0xac>
  return -1;
    80005e14:	597d                	li	s2,-1
    80005e16:	a82d                	j	80005e50 <sys_exec+0xfa>
      argv[i] = 0;
    80005e18:	0a8e                	slli	s5,s5,0x3
    80005e1a:	fc040793          	addi	a5,s0,-64
    80005e1e:	9abe                	add	s5,s5,a5
    80005e20:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e24:	e4040593          	addi	a1,s0,-448
    80005e28:	f4040513          	addi	a0,s0,-192
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	194080e7          	jalr	404(ra) # 80004fc0 <exec>
    80005e34:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e36:	10048993          	addi	s3,s1,256
    80005e3a:	6088                	ld	a0,0(s1)
    80005e3c:	c911                	beqz	a0,80005e50 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e3e:	ffffb097          	auipc	ra,0xffffb
    80005e42:	bba080e7          	jalr	-1094(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e46:	04a1                	addi	s1,s1,8
    80005e48:	ff3499e3          	bne	s1,s3,80005e3a <sys_exec+0xe4>
    80005e4c:	a011                	j	80005e50 <sys_exec+0xfa>
  return -1;
    80005e4e:	597d                	li	s2,-1
}
    80005e50:	854a                	mv	a0,s2
    80005e52:	60be                	ld	ra,456(sp)
    80005e54:	641e                	ld	s0,448(sp)
    80005e56:	74fa                	ld	s1,440(sp)
    80005e58:	795a                	ld	s2,432(sp)
    80005e5a:	79ba                	ld	s3,424(sp)
    80005e5c:	7a1a                	ld	s4,416(sp)
    80005e5e:	6afa                	ld	s5,408(sp)
    80005e60:	6179                	addi	sp,sp,464
    80005e62:	8082                	ret

0000000080005e64 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e64:	7139                	addi	sp,sp,-64
    80005e66:	fc06                	sd	ra,56(sp)
    80005e68:	f822                	sd	s0,48(sp)
    80005e6a:	f426                	sd	s1,40(sp)
    80005e6c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e6e:	ffffc097          	auipc	ra,0xffffc
    80005e72:	b42080e7          	jalr	-1214(ra) # 800019b0 <myproc>
    80005e76:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e78:	fd840593          	addi	a1,s0,-40
    80005e7c:	4501                	li	a0,0
    80005e7e:	ffffd097          	auipc	ra,0xffffd
    80005e82:	ef6080e7          	jalr	-266(ra) # 80002d74 <argaddr>
    return -1;
    80005e86:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e88:	0e054063          	bltz	a0,80005f68 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e8c:	fc840593          	addi	a1,s0,-56
    80005e90:	fd040513          	addi	a0,s0,-48
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	dfc080e7          	jalr	-516(ra) # 80004c90 <pipealloc>
    return -1;
    80005e9c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e9e:	0c054563          	bltz	a0,80005f68 <sys_pipe+0x104>
  fd0 = -1;
    80005ea2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ea6:	fd043503          	ld	a0,-48(s0)
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	508080e7          	jalr	1288(ra) # 800053b2 <fdalloc>
    80005eb2:	fca42223          	sw	a0,-60(s0)
    80005eb6:	08054c63          	bltz	a0,80005f4e <sys_pipe+0xea>
    80005eba:	fc843503          	ld	a0,-56(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	4f4080e7          	jalr	1268(ra) # 800053b2 <fdalloc>
    80005ec6:	fca42023          	sw	a0,-64(s0)
    80005eca:	06054863          	bltz	a0,80005f3a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ece:	4691                	li	a3,4
    80005ed0:	fc440613          	addi	a2,s0,-60
    80005ed4:	fd843583          	ld	a1,-40(s0)
    80005ed8:	68a8                	ld	a0,80(s1)
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	798080e7          	jalr	1944(ra) # 80001672 <copyout>
    80005ee2:	02054063          	bltz	a0,80005f02 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ee6:	4691                	li	a3,4
    80005ee8:	fc040613          	addi	a2,s0,-64
    80005eec:	fd843583          	ld	a1,-40(s0)
    80005ef0:	0591                	addi	a1,a1,4
    80005ef2:	68a8                	ld	a0,80(s1)
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	77e080e7          	jalr	1918(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005efc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005efe:	06055563          	bgez	a0,80005f68 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f02:	fc442783          	lw	a5,-60(s0)
    80005f06:	07e9                	addi	a5,a5,26
    80005f08:	078e                	slli	a5,a5,0x3
    80005f0a:	97a6                	add	a5,a5,s1
    80005f0c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f10:	fc042503          	lw	a0,-64(s0)
    80005f14:	0569                	addi	a0,a0,26
    80005f16:	050e                	slli	a0,a0,0x3
    80005f18:	9526                	add	a0,a0,s1
    80005f1a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f1e:	fd043503          	ld	a0,-48(s0)
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	a3e080e7          	jalr	-1474(ra) # 80004960 <fileclose>
    fileclose(wf);
    80005f2a:	fc843503          	ld	a0,-56(s0)
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	a32080e7          	jalr	-1486(ra) # 80004960 <fileclose>
    return -1;
    80005f36:	57fd                	li	a5,-1
    80005f38:	a805                	j	80005f68 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f3a:	fc442783          	lw	a5,-60(s0)
    80005f3e:	0007c863          	bltz	a5,80005f4e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f42:	01a78513          	addi	a0,a5,26
    80005f46:	050e                	slli	a0,a0,0x3
    80005f48:	9526                	add	a0,a0,s1
    80005f4a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f4e:	fd043503          	ld	a0,-48(s0)
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	a0e080e7          	jalr	-1522(ra) # 80004960 <fileclose>
    fileclose(wf);
    80005f5a:	fc843503          	ld	a0,-56(s0)
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	a02080e7          	jalr	-1534(ra) # 80004960 <fileclose>
    return -1;
    80005f66:	57fd                	li	a5,-1
}
    80005f68:	853e                	mv	a0,a5
    80005f6a:	70e2                	ld	ra,56(sp)
    80005f6c:	7442                	ld	s0,48(sp)
    80005f6e:	74a2                	ld	s1,40(sp)
    80005f70:	6121                	addi	sp,sp,64
    80005f72:	8082                	ret
	...

0000000080005f80 <kernelvec>:
    80005f80:	7111                	addi	sp,sp,-256
    80005f82:	e006                	sd	ra,0(sp)
    80005f84:	e40a                	sd	sp,8(sp)
    80005f86:	e80e                	sd	gp,16(sp)
    80005f88:	ec12                	sd	tp,24(sp)
    80005f8a:	f016                	sd	t0,32(sp)
    80005f8c:	f41a                	sd	t1,40(sp)
    80005f8e:	f81e                	sd	t2,48(sp)
    80005f90:	fc22                	sd	s0,56(sp)
    80005f92:	e0a6                	sd	s1,64(sp)
    80005f94:	e4aa                	sd	a0,72(sp)
    80005f96:	e8ae                	sd	a1,80(sp)
    80005f98:	ecb2                	sd	a2,88(sp)
    80005f9a:	f0b6                	sd	a3,96(sp)
    80005f9c:	f4ba                	sd	a4,104(sp)
    80005f9e:	f8be                	sd	a5,112(sp)
    80005fa0:	fcc2                	sd	a6,120(sp)
    80005fa2:	e146                	sd	a7,128(sp)
    80005fa4:	e54a                	sd	s2,136(sp)
    80005fa6:	e94e                	sd	s3,144(sp)
    80005fa8:	ed52                	sd	s4,152(sp)
    80005faa:	f156                	sd	s5,160(sp)
    80005fac:	f55a                	sd	s6,168(sp)
    80005fae:	f95e                	sd	s7,176(sp)
    80005fb0:	fd62                	sd	s8,184(sp)
    80005fb2:	e1e6                	sd	s9,192(sp)
    80005fb4:	e5ea                	sd	s10,200(sp)
    80005fb6:	e9ee                	sd	s11,208(sp)
    80005fb8:	edf2                	sd	t3,216(sp)
    80005fba:	f1f6                	sd	t4,224(sp)
    80005fbc:	f5fa                	sd	t5,232(sp)
    80005fbe:	f9fe                	sd	t6,240(sp)
    80005fc0:	beffc0ef          	jal	ra,80002bae <kerneltrap>
    80005fc4:	6082                	ld	ra,0(sp)
    80005fc6:	6122                	ld	sp,8(sp)
    80005fc8:	61c2                	ld	gp,16(sp)
    80005fca:	7282                	ld	t0,32(sp)
    80005fcc:	7322                	ld	t1,40(sp)
    80005fce:	73c2                	ld	t2,48(sp)
    80005fd0:	7462                	ld	s0,56(sp)
    80005fd2:	6486                	ld	s1,64(sp)
    80005fd4:	6526                	ld	a0,72(sp)
    80005fd6:	65c6                	ld	a1,80(sp)
    80005fd8:	6666                	ld	a2,88(sp)
    80005fda:	7686                	ld	a3,96(sp)
    80005fdc:	7726                	ld	a4,104(sp)
    80005fde:	77c6                	ld	a5,112(sp)
    80005fe0:	7866                	ld	a6,120(sp)
    80005fe2:	688a                	ld	a7,128(sp)
    80005fe4:	692a                	ld	s2,136(sp)
    80005fe6:	69ca                	ld	s3,144(sp)
    80005fe8:	6a6a                	ld	s4,152(sp)
    80005fea:	7a8a                	ld	s5,160(sp)
    80005fec:	7b2a                	ld	s6,168(sp)
    80005fee:	7bca                	ld	s7,176(sp)
    80005ff0:	7c6a                	ld	s8,184(sp)
    80005ff2:	6c8e                	ld	s9,192(sp)
    80005ff4:	6d2e                	ld	s10,200(sp)
    80005ff6:	6dce                	ld	s11,208(sp)
    80005ff8:	6e6e                	ld	t3,216(sp)
    80005ffa:	7e8e                	ld	t4,224(sp)
    80005ffc:	7f2e                	ld	t5,232(sp)
    80005ffe:	7fce                	ld	t6,240(sp)
    80006000:	6111                	addi	sp,sp,256
    80006002:	10200073          	sret
    80006006:	00000013          	nop
    8000600a:	00000013          	nop
    8000600e:	0001                	nop

0000000080006010 <timervec>:
    80006010:	34051573          	csrrw	a0,mscratch,a0
    80006014:	e10c                	sd	a1,0(a0)
    80006016:	e510                	sd	a2,8(a0)
    80006018:	e914                	sd	a3,16(a0)
    8000601a:	6d0c                	ld	a1,24(a0)
    8000601c:	7110                	ld	a2,32(a0)
    8000601e:	6194                	ld	a3,0(a1)
    80006020:	96b2                	add	a3,a3,a2
    80006022:	e194                	sd	a3,0(a1)
    80006024:	4589                	li	a1,2
    80006026:	14459073          	csrw	sip,a1
    8000602a:	6914                	ld	a3,16(a0)
    8000602c:	6510                	ld	a2,8(a0)
    8000602e:	610c                	ld	a1,0(a0)
    80006030:	34051573          	csrrw	a0,mscratch,a0
    80006034:	30200073          	mret
	...

000000008000603a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000603a:	1141                	addi	sp,sp,-16
    8000603c:	e422                	sd	s0,8(sp)
    8000603e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006040:	0c0007b7          	lui	a5,0xc000
    80006044:	4705                	li	a4,1
    80006046:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006048:	c3d8                	sw	a4,4(a5)
}
    8000604a:	6422                	ld	s0,8(sp)
    8000604c:	0141                	addi	sp,sp,16
    8000604e:	8082                	ret

0000000080006050 <plicinithart>:

void
plicinithart(void)
{
    80006050:	1141                	addi	sp,sp,-16
    80006052:	e406                	sd	ra,8(sp)
    80006054:	e022                	sd	s0,0(sp)
    80006056:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	92c080e7          	jalr	-1748(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006060:	0085171b          	slliw	a4,a0,0x8
    80006064:	0c0027b7          	lui	a5,0xc002
    80006068:	97ba                	add	a5,a5,a4
    8000606a:	40200713          	li	a4,1026
    8000606e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006072:	00d5151b          	slliw	a0,a0,0xd
    80006076:	0c2017b7          	lui	a5,0xc201
    8000607a:	953e                	add	a0,a0,a5
    8000607c:	00052023          	sw	zero,0(a0)
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret

0000000080006088 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006088:	1141                	addi	sp,sp,-16
    8000608a:	e406                	sd	ra,8(sp)
    8000608c:	e022                	sd	s0,0(sp)
    8000608e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006090:	ffffc097          	auipc	ra,0xffffc
    80006094:	8f4080e7          	jalr	-1804(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006098:	00d5179b          	slliw	a5,a0,0xd
    8000609c:	0c201537          	lui	a0,0xc201
    800060a0:	953e                	add	a0,a0,a5
  return irq;
}
    800060a2:	4148                	lw	a0,4(a0)
    800060a4:	60a2                	ld	ra,8(sp)
    800060a6:	6402                	ld	s0,0(sp)
    800060a8:	0141                	addi	sp,sp,16
    800060aa:	8082                	ret

00000000800060ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ac:	1101                	addi	sp,sp,-32
    800060ae:	ec06                	sd	ra,24(sp)
    800060b0:	e822                	sd	s0,16(sp)
    800060b2:	e426                	sd	s1,8(sp)
    800060b4:	1000                	addi	s0,sp,32
    800060b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	8cc080e7          	jalr	-1844(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060c0:	00d5151b          	slliw	a0,a0,0xd
    800060c4:	0c2017b7          	lui	a5,0xc201
    800060c8:	97aa                	add	a5,a5,a0
    800060ca:	c3c4                	sw	s1,4(a5)
}
    800060cc:	60e2                	ld	ra,24(sp)
    800060ce:	6442                	ld	s0,16(sp)
    800060d0:	64a2                	ld	s1,8(sp)
    800060d2:	6105                	addi	sp,sp,32
    800060d4:	8082                	ret

00000000800060d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060d6:	1141                	addi	sp,sp,-16
    800060d8:	e406                	sd	ra,8(sp)
    800060da:	e022                	sd	s0,0(sp)
    800060dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060de:	479d                	li	a5,7
    800060e0:	06a7c963          	blt	a5,a0,80006152 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060e4:	0001d797          	auipc	a5,0x1d
    800060e8:	f1c78793          	addi	a5,a5,-228 # 80023000 <disk>
    800060ec:	00a78733          	add	a4,a5,a0
    800060f0:	6789                	lui	a5,0x2
    800060f2:	97ba                	add	a5,a5,a4
    800060f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800060f8:	e7ad                	bnez	a5,80006162 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060fa:	00451793          	slli	a5,a0,0x4
    800060fe:	0001f717          	auipc	a4,0x1f
    80006102:	f0270713          	addi	a4,a4,-254 # 80025000 <disk+0x2000>
    80006106:	6314                	ld	a3,0(a4)
    80006108:	96be                	add	a3,a3,a5
    8000610a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000610e:	6314                	ld	a3,0(a4)
    80006110:	96be                	add	a3,a3,a5
    80006112:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006116:	6314                	ld	a3,0(a4)
    80006118:	96be                	add	a3,a3,a5
    8000611a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000611e:	6318                	ld	a4,0(a4)
    80006120:	97ba                	add	a5,a5,a4
    80006122:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006126:	0001d797          	auipc	a5,0x1d
    8000612a:	eda78793          	addi	a5,a5,-294 # 80023000 <disk>
    8000612e:	97aa                	add	a5,a5,a0
    80006130:	6509                	lui	a0,0x2
    80006132:	953e                	add	a0,a0,a5
    80006134:	4785                	li	a5,1
    80006136:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000613a:	0001f517          	auipc	a0,0x1f
    8000613e:	ede50513          	addi	a0,a0,-290 # 80025018 <disk+0x2018>
    80006142:	ffffc097          	auipc	ra,0xffffc
    80006146:	398080e7          	jalr	920(ra) # 800024da <wakeup>
}
    8000614a:	60a2                	ld	ra,8(sp)
    8000614c:	6402                	ld	s0,0(sp)
    8000614e:	0141                	addi	sp,sp,16
    80006150:	8082                	ret
    panic("free_desc 1");
    80006152:	00002517          	auipc	a0,0x2
    80006156:	6f650513          	addi	a0,a0,1782 # 80008848 <syscalls+0x328>
    8000615a:	ffffa097          	auipc	ra,0xffffa
    8000615e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	6f650513          	addi	a0,a0,1782 # 80008858 <syscalls+0x338>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>

0000000080006172 <virtio_disk_init>:
{
    80006172:	1101                	addi	sp,sp,-32
    80006174:	ec06                	sd	ra,24(sp)
    80006176:	e822                	sd	s0,16(sp)
    80006178:	e426                	sd	s1,8(sp)
    8000617a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000617c:	00002597          	auipc	a1,0x2
    80006180:	6ec58593          	addi	a1,a1,1772 # 80008868 <syscalls+0x348>
    80006184:	0001f517          	auipc	a0,0x1f
    80006188:	fa450513          	addi	a0,a0,-92 # 80025128 <disk+0x2128>
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	9c8080e7          	jalr	-1592(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006194:	100017b7          	lui	a5,0x10001
    80006198:	4398                	lw	a4,0(a5)
    8000619a:	2701                	sext.w	a4,a4
    8000619c:	747277b7          	lui	a5,0x74727
    800061a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061a4:	0ef71163          	bne	a4,a5,80006286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061a8:	100017b7          	lui	a5,0x10001
    800061ac:	43dc                	lw	a5,4(a5)
    800061ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061b0:	4705                	li	a4,1
    800061b2:	0ce79a63          	bne	a5,a4,80006286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061b6:	100017b7          	lui	a5,0x10001
    800061ba:	479c                	lw	a5,8(a5)
    800061bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061be:	4709                	li	a4,2
    800061c0:	0ce79363          	bne	a5,a4,80006286 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061c4:	100017b7          	lui	a5,0x10001
    800061c8:	47d8                	lw	a4,12(a5)
    800061ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061cc:	554d47b7          	lui	a5,0x554d4
    800061d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061d4:	0af71963          	bne	a4,a5,80006286 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d8:	100017b7          	lui	a5,0x10001
    800061dc:	4705                	li	a4,1
    800061de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e0:	470d                	li	a4,3
    800061e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061e6:	c7ffe737          	lui	a4,0xc7ffe
    800061ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800061ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061f0:	2701                	sext.w	a4,a4
    800061f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f4:	472d                	li	a4,11
    800061f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f8:	473d                	li	a4,15
    800061fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061fc:	6705                	lui	a4,0x1
    800061fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006200:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006204:	5bdc                	lw	a5,52(a5)
    80006206:	2781                	sext.w	a5,a5
  if(max == 0)
    80006208:	c7d9                	beqz	a5,80006296 <virtio_disk_init+0x124>
  if(max < NUM)
    8000620a:	471d                	li	a4,7
    8000620c:	08f77d63          	bgeu	a4,a5,800062a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006210:	100014b7          	lui	s1,0x10001
    80006214:	47a1                	li	a5,8
    80006216:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006218:	6609                	lui	a2,0x2
    8000621a:	4581                	li	a1,0
    8000621c:	0001d517          	auipc	a0,0x1d
    80006220:	de450513          	addi	a0,a0,-540 # 80023000 <disk>
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	abc080e7          	jalr	-1348(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000622c:	0001d717          	auipc	a4,0x1d
    80006230:	dd470713          	addi	a4,a4,-556 # 80023000 <disk>
    80006234:	00c75793          	srli	a5,a4,0xc
    80006238:	2781                	sext.w	a5,a5
    8000623a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000623c:	0001f797          	auipc	a5,0x1f
    80006240:	dc478793          	addi	a5,a5,-572 # 80025000 <disk+0x2000>
    80006244:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006246:	0001d717          	auipc	a4,0x1d
    8000624a:	e3a70713          	addi	a4,a4,-454 # 80023080 <disk+0x80>
    8000624e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006250:	0001e717          	auipc	a4,0x1e
    80006254:	db070713          	addi	a4,a4,-592 # 80024000 <disk+0x1000>
    80006258:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000625a:	4705                	li	a4,1
    8000625c:	00e78c23          	sb	a4,24(a5)
    80006260:	00e78ca3          	sb	a4,25(a5)
    80006264:	00e78d23          	sb	a4,26(a5)
    80006268:	00e78da3          	sb	a4,27(a5)
    8000626c:	00e78e23          	sb	a4,28(a5)
    80006270:	00e78ea3          	sb	a4,29(a5)
    80006274:	00e78f23          	sb	a4,30(a5)
    80006278:	00e78fa3          	sb	a4,31(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret
    panic("could not find virtio disk");
    80006286:	00002517          	auipc	a0,0x2
    8000628a:	5f250513          	addi	a0,a0,1522 # 80008878 <syscalls+0x358>
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	60250513          	addi	a0,a0,1538 # 80008898 <syscalls+0x378>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062a6:	00002517          	auipc	a0,0x2
    800062aa:	61250513          	addi	a0,a0,1554 # 800088b8 <syscalls+0x398>
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	290080e7          	jalr	656(ra) # 8000053e <panic>

00000000800062b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062b6:	7159                	addi	sp,sp,-112
    800062b8:	f486                	sd	ra,104(sp)
    800062ba:	f0a2                	sd	s0,96(sp)
    800062bc:	eca6                	sd	s1,88(sp)
    800062be:	e8ca                	sd	s2,80(sp)
    800062c0:	e4ce                	sd	s3,72(sp)
    800062c2:	e0d2                	sd	s4,64(sp)
    800062c4:	fc56                	sd	s5,56(sp)
    800062c6:	f85a                	sd	s6,48(sp)
    800062c8:	f45e                	sd	s7,40(sp)
    800062ca:	f062                	sd	s8,32(sp)
    800062cc:	ec66                	sd	s9,24(sp)
    800062ce:	e86a                	sd	s10,16(sp)
    800062d0:	1880                	addi	s0,sp,112
    800062d2:	892a                	mv	s2,a0
    800062d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062d6:	00c52c83          	lw	s9,12(a0)
    800062da:	001c9c9b          	slliw	s9,s9,0x1
    800062de:	1c82                	slli	s9,s9,0x20
    800062e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062e4:	0001f517          	auipc	a0,0x1f
    800062e8:	e4450513          	addi	a0,a0,-444 # 80025128 <disk+0x2128>
    800062ec:	ffffb097          	auipc	ra,0xffffb
    800062f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800062f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800062f8:	0001db97          	auipc	s7,0x1d
    800062fc:	d08b8b93          	addi	s7,s7,-760 # 80023000 <disk>
    80006300:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006302:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006304:	8a4e                	mv	s4,s3
    80006306:	a051                	j	8000638a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006308:	00fb86b3          	add	a3,s7,a5
    8000630c:	96da                	add	a3,a3,s6
    8000630e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006312:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006314:	0207c563          	bltz	a5,8000633e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006318:	2485                	addiw	s1,s1,1
    8000631a:	0711                	addi	a4,a4,4
    8000631c:	25548063          	beq	s1,s5,8000655c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006320:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006322:	0001f697          	auipc	a3,0x1f
    80006326:	cf668693          	addi	a3,a3,-778 # 80025018 <disk+0x2018>
    8000632a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000632c:	0006c583          	lbu	a1,0(a3)
    80006330:	fde1                	bnez	a1,80006308 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006332:	2785                	addiw	a5,a5,1
    80006334:	0685                	addi	a3,a3,1
    80006336:	ff879be3          	bne	a5,s8,8000632c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000633a:	57fd                	li	a5,-1
    8000633c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000633e:	02905a63          	blez	s1,80006372 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006342:	f9042503          	lw	a0,-112(s0)
    80006346:	00000097          	auipc	ra,0x0
    8000634a:	d90080e7          	jalr	-624(ra) # 800060d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000634e:	4785                	li	a5,1
    80006350:	0297d163          	bge	a5,s1,80006372 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006354:	f9442503          	lw	a0,-108(s0)
    80006358:	00000097          	auipc	ra,0x0
    8000635c:	d7e080e7          	jalr	-642(ra) # 800060d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006360:	4789                	li	a5,2
    80006362:	0097d863          	bge	a5,s1,80006372 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006366:	f9842503          	lw	a0,-104(s0)
    8000636a:	00000097          	auipc	ra,0x0
    8000636e:	d6c080e7          	jalr	-660(ra) # 800060d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006372:	0001f597          	auipc	a1,0x1f
    80006376:	db658593          	addi	a1,a1,-586 # 80025128 <disk+0x2128>
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	c9e50513          	addi	a0,a0,-866 # 80025018 <disk+0x2018>
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	e80080e7          	jalr	-384(ra) # 80002202 <sleep>
  for(int i = 0; i < 3; i++){
    8000638a:	f9040713          	addi	a4,s0,-112
    8000638e:	84ce                	mv	s1,s3
    80006390:	bf41                	j	80006320 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006392:	20058713          	addi	a4,a1,512
    80006396:	00471693          	slli	a3,a4,0x4
    8000639a:	0001d717          	auipc	a4,0x1d
    8000639e:	c6670713          	addi	a4,a4,-922 # 80023000 <disk>
    800063a2:	9736                	add	a4,a4,a3
    800063a4:	4685                	li	a3,1
    800063a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063aa:	20058713          	addi	a4,a1,512
    800063ae:	00471693          	slli	a3,a4,0x4
    800063b2:	0001d717          	auipc	a4,0x1d
    800063b6:	c4e70713          	addi	a4,a4,-946 # 80023000 <disk>
    800063ba:	9736                	add	a4,a4,a3
    800063bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063c4:	7679                	lui	a2,0xffffe
    800063c6:	963e                	add	a2,a2,a5
    800063c8:	0001f697          	auipc	a3,0x1f
    800063cc:	c3868693          	addi	a3,a3,-968 # 80025000 <disk+0x2000>
    800063d0:	6298                	ld	a4,0(a3)
    800063d2:	9732                	add	a4,a4,a2
    800063d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063d6:	6298                	ld	a4,0(a3)
    800063d8:	9732                	add	a4,a4,a2
    800063da:	4541                	li	a0,16
    800063dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063de:	6298                	ld	a4,0(a3)
    800063e0:	9732                	add	a4,a4,a2
    800063e2:	4505                	li	a0,1
    800063e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063e8:	f9442703          	lw	a4,-108(s0)
    800063ec:	6288                	ld	a0,0(a3)
    800063ee:	962a                	add	a2,a2,a0
    800063f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063f4:	0712                	slli	a4,a4,0x4
    800063f6:	6290                	ld	a2,0(a3)
    800063f8:	963a                	add	a2,a2,a4
    800063fa:	05890513          	addi	a0,s2,88
    800063fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006400:	6294                	ld	a3,0(a3)
    80006402:	96ba                	add	a3,a3,a4
    80006404:	40000613          	li	a2,1024
    80006408:	c690                	sw	a2,8(a3)
  if(write)
    8000640a:	140d0063          	beqz	s10,8000654a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000640e:	0001f697          	auipc	a3,0x1f
    80006412:	bf26b683          	ld	a3,-1038(a3) # 80025000 <disk+0x2000>
    80006416:	96ba                	add	a3,a3,a4
    80006418:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000641c:	0001d817          	auipc	a6,0x1d
    80006420:	be480813          	addi	a6,a6,-1052 # 80023000 <disk>
    80006424:	0001f517          	auipc	a0,0x1f
    80006428:	bdc50513          	addi	a0,a0,-1060 # 80025000 <disk+0x2000>
    8000642c:	6114                	ld	a3,0(a0)
    8000642e:	96ba                	add	a3,a3,a4
    80006430:	00c6d603          	lhu	a2,12(a3)
    80006434:	00166613          	ori	a2,a2,1
    80006438:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000643c:	f9842683          	lw	a3,-104(s0)
    80006440:	6110                	ld	a2,0(a0)
    80006442:	9732                	add	a4,a4,a2
    80006444:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006448:	20058613          	addi	a2,a1,512
    8000644c:	0612                	slli	a2,a2,0x4
    8000644e:	9642                	add	a2,a2,a6
    80006450:	577d                	li	a4,-1
    80006452:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006456:	00469713          	slli	a4,a3,0x4
    8000645a:	6114                	ld	a3,0(a0)
    8000645c:	96ba                	add	a3,a3,a4
    8000645e:	03078793          	addi	a5,a5,48
    80006462:	97c2                	add	a5,a5,a6
    80006464:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006466:	611c                	ld	a5,0(a0)
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	4685                	li	a3,1
    8000646c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000646e:	611c                	ld	a5,0(a0)
    80006470:	97ba                	add	a5,a5,a4
    80006472:	4809                	li	a6,2
    80006474:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006478:	611c                	ld	a5,0(a0)
    8000647a:	973e                	add	a4,a4,a5
    8000647c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006480:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006484:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006488:	6518                	ld	a4,8(a0)
    8000648a:	00275783          	lhu	a5,2(a4)
    8000648e:	8b9d                	andi	a5,a5,7
    80006490:	0786                	slli	a5,a5,0x1
    80006492:	97ba                	add	a5,a5,a4
    80006494:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006498:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000649c:	6518                	ld	a4,8(a0)
    8000649e:	00275783          	lhu	a5,2(a4)
    800064a2:	2785                	addiw	a5,a5,1
    800064a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064ac:	100017b7          	lui	a5,0x10001
    800064b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064b4:	00492703          	lw	a4,4(s2)
    800064b8:	4785                	li	a5,1
    800064ba:	02f71163          	bne	a4,a5,800064dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800064be:	0001f997          	auipc	s3,0x1f
    800064c2:	c6a98993          	addi	s3,s3,-918 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800064c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064c8:	85ce                	mv	a1,s3
    800064ca:	854a                	mv	a0,s2
    800064cc:	ffffc097          	auipc	ra,0xffffc
    800064d0:	d36080e7          	jalr	-714(ra) # 80002202 <sleep>
  while(b->disk == 1) {
    800064d4:	00492783          	lw	a5,4(s2)
    800064d8:	fe9788e3          	beq	a5,s1,800064c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800064dc:	f9042903          	lw	s2,-112(s0)
    800064e0:	20090793          	addi	a5,s2,512
    800064e4:	00479713          	slli	a4,a5,0x4
    800064e8:	0001d797          	auipc	a5,0x1d
    800064ec:	b1878793          	addi	a5,a5,-1256 # 80023000 <disk>
    800064f0:	97ba                	add	a5,a5,a4
    800064f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064f6:	0001f997          	auipc	s3,0x1f
    800064fa:	b0a98993          	addi	s3,s3,-1270 # 80025000 <disk+0x2000>
    800064fe:	00491713          	slli	a4,s2,0x4
    80006502:	0009b783          	ld	a5,0(s3)
    80006506:	97ba                	add	a5,a5,a4
    80006508:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000650c:	854a                	mv	a0,s2
    8000650e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006512:	00000097          	auipc	ra,0x0
    80006516:	bc4080e7          	jalr	-1084(ra) # 800060d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000651a:	8885                	andi	s1,s1,1
    8000651c:	f0ed                	bnez	s1,800064fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000651e:	0001f517          	auipc	a0,0x1f
    80006522:	c0a50513          	addi	a0,a0,-1014 # 80025128 <disk+0x2128>
    80006526:	ffffa097          	auipc	ra,0xffffa
    8000652a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
}
    8000652e:	70a6                	ld	ra,104(sp)
    80006530:	7406                	ld	s0,96(sp)
    80006532:	64e6                	ld	s1,88(sp)
    80006534:	6946                	ld	s2,80(sp)
    80006536:	69a6                	ld	s3,72(sp)
    80006538:	6a06                	ld	s4,64(sp)
    8000653a:	7ae2                	ld	s5,56(sp)
    8000653c:	7b42                	ld	s6,48(sp)
    8000653e:	7ba2                	ld	s7,40(sp)
    80006540:	7c02                	ld	s8,32(sp)
    80006542:	6ce2                	ld	s9,24(sp)
    80006544:	6d42                	ld	s10,16(sp)
    80006546:	6165                	addi	sp,sp,112
    80006548:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000654a:	0001f697          	auipc	a3,0x1f
    8000654e:	ab66b683          	ld	a3,-1354(a3) # 80025000 <disk+0x2000>
    80006552:	96ba                	add	a3,a3,a4
    80006554:	4609                	li	a2,2
    80006556:	00c69623          	sh	a2,12(a3)
    8000655a:	b5c9                	j	8000641c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000655c:	f9042583          	lw	a1,-112(s0)
    80006560:	20058793          	addi	a5,a1,512
    80006564:	0792                	slli	a5,a5,0x4
    80006566:	0001d517          	auipc	a0,0x1d
    8000656a:	b4250513          	addi	a0,a0,-1214 # 800230a8 <disk+0xa8>
    8000656e:	953e                	add	a0,a0,a5
  if(write)
    80006570:	e20d11e3          	bnez	s10,80006392 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006574:	20058713          	addi	a4,a1,512
    80006578:	00471693          	slli	a3,a4,0x4
    8000657c:	0001d717          	auipc	a4,0x1d
    80006580:	a8470713          	addi	a4,a4,-1404 # 80023000 <disk>
    80006584:	9736                	add	a4,a4,a3
    80006586:	0a072423          	sw	zero,168(a4)
    8000658a:	b505                	j	800063aa <virtio_disk_rw+0xf4>

000000008000658c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000658c:	1101                	addi	sp,sp,-32
    8000658e:	ec06                	sd	ra,24(sp)
    80006590:	e822                	sd	s0,16(sp)
    80006592:	e426                	sd	s1,8(sp)
    80006594:	e04a                	sd	s2,0(sp)
    80006596:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006598:	0001f517          	auipc	a0,0x1f
    8000659c:	b9050513          	addi	a0,a0,-1136 # 80025128 <disk+0x2128>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065a8:	10001737          	lui	a4,0x10001
    800065ac:	533c                	lw	a5,96(a4)
    800065ae:	8b8d                	andi	a5,a5,3
    800065b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065b6:	0001f797          	auipc	a5,0x1f
    800065ba:	a4a78793          	addi	a5,a5,-1462 # 80025000 <disk+0x2000>
    800065be:	6b94                	ld	a3,16(a5)
    800065c0:	0207d703          	lhu	a4,32(a5)
    800065c4:	0026d783          	lhu	a5,2(a3)
    800065c8:	06f70163          	beq	a4,a5,8000662a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065cc:	0001d917          	auipc	s2,0x1d
    800065d0:	a3490913          	addi	s2,s2,-1484 # 80023000 <disk>
    800065d4:	0001f497          	auipc	s1,0x1f
    800065d8:	a2c48493          	addi	s1,s1,-1492 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800065dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065e0:	6898                	ld	a4,16(s1)
    800065e2:	0204d783          	lhu	a5,32(s1)
    800065e6:	8b9d                	andi	a5,a5,7
    800065e8:	078e                	slli	a5,a5,0x3
    800065ea:	97ba                	add	a5,a5,a4
    800065ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065ee:	20078713          	addi	a4,a5,512
    800065f2:	0712                	slli	a4,a4,0x4
    800065f4:	974a                	add	a4,a4,s2
    800065f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065fa:	e731                	bnez	a4,80006646 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065fc:	20078793          	addi	a5,a5,512
    80006600:	0792                	slli	a5,a5,0x4
    80006602:	97ca                	add	a5,a5,s2
    80006604:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006606:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000660a:	ffffc097          	auipc	ra,0xffffc
    8000660e:	ed0080e7          	jalr	-304(ra) # 800024da <wakeup>

    disk.used_idx += 1;
    80006612:	0204d783          	lhu	a5,32(s1)
    80006616:	2785                	addiw	a5,a5,1
    80006618:	17c2                	slli	a5,a5,0x30
    8000661a:	93c1                	srli	a5,a5,0x30
    8000661c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006620:	6898                	ld	a4,16(s1)
    80006622:	00275703          	lhu	a4,2(a4)
    80006626:	faf71be3          	bne	a4,a5,800065dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000662a:	0001f517          	auipc	a0,0x1f
    8000662e:	afe50513          	addi	a0,a0,-1282 # 80025128 <disk+0x2128>
    80006632:	ffffa097          	auipc	ra,0xffffa
    80006636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
}
    8000663a:	60e2                	ld	ra,24(sp)
    8000663c:	6442                	ld	s0,16(sp)
    8000663e:	64a2                	ld	s1,8(sp)
    80006640:	6902                	ld	s2,0(sp)
    80006642:	6105                	addi	sp,sp,32
    80006644:	8082                	ret
      panic("virtio_disk_intr status");
    80006646:	00002517          	auipc	a0,0x2
    8000664a:	29250513          	addi	a0,a0,658 # 800088d8 <syscalls+0x3b8>
    8000664e:	ffffa097          	auipc	ra,0xffffa
    80006652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
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
