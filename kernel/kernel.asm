
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae013103          	ld	sp,-1312(sp) # 80008ae0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	16c78793          	addi	a5,a5,364 # 800061d0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67ff>
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
    80000130:	6f0080e7          	jalr	1776(ra) # 8000281c <either_copyin>
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
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	912080e7          	jalr	-1774(ra) # 80001ad6 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	0f6080e7          	jalr	246(ra) # 800022ca <sleep>
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
    80000214:	5b6080e7          	jalr	1462(ra) # 800027c6 <either_copyout>
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
    800002f6:	580080e7          	jalr	1408(ra) # 80002872 <procdump>
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
    8000044a:	15c080e7          	jalr	348(ra) # 800025a2 <wakeup>
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
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	d1878793          	addi	a5,a5,-744 # 80023190 <devsw>
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
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1811+0x160>
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
    800008a4:	d02080e7          	jalr	-766(ra) # 800025a2 <wakeup>
    
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
    80000930:	99e080e7          	jalr	-1634(ra) # 800022ca <sleep>
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
    80000a0c:	00027797          	auipc	a5,0x27
    80000a10:	5f478793          	addi	a5,a5,1524 # 80028000 <end>
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
    80000adc:	00027517          	auipc	a0,0x27
    80000ae0:	52450513          	addi	a0,a0,1316 # 80028000 <end>
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
    80000b82:	f3c080e7          	jalr	-196(ra) # 80001aba <mycpu>
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
    80000bb4:	f0a080e7          	jalr	-246(ra) # 80001aba <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	efe080e7          	jalr	-258(ra) # 80001aba <mycpu>
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
    80000bd8:	ee6080e7          	jalr	-282(ra) # 80001aba <mycpu>
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
    80000c18:	ea6080e7          	jalr	-346(ra) # 80001aba <mycpu>
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
    80000c44:	e7a080e7          	jalr	-390(ra) # 80001aba <mycpu>
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
    80000e9a:	c14080e7          	jalr	-1004(ra) # 80001aaa <cpuid>
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
    80000eb6:	bf8080e7          	jalr	-1032(ra) # 80001aaa <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	b84080e7          	jalr	-1148(ra) # 80002a58 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	334080e7          	jalr	820(ra) # 80006210 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	234080e7          	jalr	564(ra) # 80002118 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1811+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1811+0x160>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	32a080e7          	jalr	810(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	070080e7          	jalr	112(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	ab6080e7          	jalr	-1354(ra) # 800019fa <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	ae4080e7          	jalr	-1308(ra) # 80002a30 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	b04080e7          	jalr	-1276(ra) # 80002a58 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	29e080e7          	jalr	670(ra) # 800061fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	2ac080e7          	jalr	684(ra) # 80006210 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	486080e7          	jalr	1158(ra) # 800033f2 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	b16080e7          	jalr	-1258(ra) # 80003a8a <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	ac0080e7          	jalr	-1344(ra) # 80004a3c <fileinit>
    pinit();         // process table for mlfq
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	9b0080e7          	jalr	-1616(ra) # 80001934 <pinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	3a6080e7          	jalr	934(ra) # 80006332 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e42080e7          	jalr	-446(ra) # 80001dd6 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	71c080e7          	jalr	1820(ra) # 80001964 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <push>:
struct spinlock wait_lock;

struct Queue mlfq_queue[5];

void push(struct Queue *list, struct proc *element)
{
    80001846:	1141                	addi	sp,sp,-16
    80001848:	e422                	sd	s0,8(sp)
    8000184a:	0800                	addi	s0,sp,16
  list->array[list->tail] = element;
    8000184c:	415c                	lw	a5,4(a0)
    8000184e:	00379713          	slli	a4,a5,0x3
    80001852:	972a                	add	a4,a4,a0
    80001854:	e70c                	sd	a1,8(a4)
  list->tail++;
    80001856:	2785                	addiw	a5,a5,1
    80001858:	0007869b          	sext.w	a3,a5
  if (list->tail == NPROC + 1)
    8000185c:	04100713          	li	a4,65
    80001860:	00e68b63          	beq	a3,a4,80001876 <push+0x30>
  list->tail++;
    80001864:	c15c                	sw	a5,4(a0)
  {
    list->tail = 0;
  }
  list->size++;
    80001866:	21052783          	lw	a5,528(a0)
    8000186a:	2785                	addiw	a5,a5,1
    8000186c:	20f52823          	sw	a5,528(a0)
}
    80001870:	6422                	ld	s0,8(sp)
    80001872:	0141                	addi	sp,sp,16
    80001874:	8082                	ret
    list->tail = 0;
    80001876:	00052223          	sw	zero,4(a0)
    8000187a:	b7f5                	j	80001866 <push+0x20>

000000008000187c <pop>:

void pop(struct Queue *list)
{
    8000187c:	1141                	addi	sp,sp,-16
    8000187e:	e422                	sd	s0,8(sp)
    80001880:	0800                	addi	s0,sp,16
  list->head++;
    80001882:	411c                	lw	a5,0(a0)
    80001884:	2785                	addiw	a5,a5,1
    80001886:	0007869b          	sext.w	a3,a5
  if (list->head == NPROC + 1)
    8000188a:	04100713          	li	a4,65
    8000188e:	00e68b63          	beq	a3,a4,800018a4 <pop+0x28>
  list->head++;
    80001892:	c11c                	sw	a5,0(a0)
  {
    list->head = 0;
  }

  list->size--;
    80001894:	21052783          	lw	a5,528(a0)
    80001898:	37fd                	addiw	a5,a5,-1
    8000189a:	20f52823          	sw	a5,528(a0)
}
    8000189e:	6422                	ld	s0,8(sp)
    800018a0:	0141                	addi	sp,sp,16
    800018a2:	8082                	ret
    list->head = 0;
    800018a4:	00052023          	sw	zero,0(a0)
    800018a8:	b7f5                	j	80001894 <pop+0x18>

00000000800018aa <front>:

struct proc *
front(struct Queue *list)
{
    800018aa:	1141                	addi	sp,sp,-16
    800018ac:	e422                	sd	s0,8(sp)
    800018ae:	0800                	addi	s0,sp,16
  if (list->head == list->tail)
    800018b0:	411c                	lw	a5,0(a0)
    800018b2:	4158                	lw	a4,4(a0)
    800018b4:	00f70863          	beq	a4,a5,800018c4 <front+0x1a>
  {
    return 0;
  }
  return list->array[list->head];
    800018b8:	078e                	slli	a5,a5,0x3
    800018ba:	953e                	add	a0,a0,a5
    800018bc:	6508                	ld	a0,8(a0)
}
    800018be:	6422                	ld	s0,8(sp)
    800018c0:	0141                	addi	sp,sp,16
    800018c2:	8082                	ret
    return 0;
    800018c4:	4501                	li	a0,0
    800018c6:	bfe5                	j	800018be <front+0x14>

00000000800018c8 <qerase>:

void qerase(struct Queue *list, int pid)
{
    800018c8:	1141                	addi	sp,sp,-16
    800018ca:	e422                	sd	s0,8(sp)
    800018cc:	0800                	addi	s0,sp,16
  for (int curr = list->head; curr != list->tail; curr = (curr + 1) % (NPROC + 1))
    800018ce:	411c                	lw	a5,0(a0)
    800018d0:	00452803          	lw	a6,4(a0)
    800018d4:	03078d63          	beq	a5,a6,8000190e <qerase+0x46>
  {
    if (list->array[curr]->pid == pid)
    {
      struct proc *temp = list->array[curr];
      list->array[curr] = list->array[(curr + 1) % (NPROC + 1)];
    800018d8:	04100893          	li	a7,65
    800018dc:	a031                	j	800018e8 <qerase+0x20>
  for (int curr = list->head; curr != list->tail; curr = (curr + 1) % (NPROC + 1))
    800018de:	2785                	addiw	a5,a5,1
    800018e0:	0317e7bb          	remw	a5,a5,a7
    800018e4:	03078563          	beq	a5,a6,8000190e <qerase+0x46>
    if (list->array[curr]->pid == pid)
    800018e8:	00379713          	slli	a4,a5,0x3
    800018ec:	972a                	add	a4,a4,a0
    800018ee:	6710                	ld	a2,8(a4)
    800018f0:	5a14                	lw	a3,48(a2)
    800018f2:	feb696e3          	bne	a3,a1,800018de <qerase+0x16>
      list->array[curr] = list->array[(curr + 1) % (NPROC + 1)];
    800018f6:	0017869b          	addiw	a3,a5,1
    800018fa:	0316e6bb          	remw	a3,a3,a7
    800018fe:	068e                	slli	a3,a3,0x3
    80001900:	96aa                	add	a3,a3,a0
    80001902:	0086b303          	ld	t1,8(a3) # 1008 <_entry-0x7fffeff8>
    80001906:	00673423          	sd	t1,8(a4)
      list->array[(curr + 1) % (NPROC + 1)] = temp;
    8000190a:	e690                	sd	a2,8(a3)
    8000190c:	bfc9                	j	800018de <qerase+0x16>
    }
  }
  list->tail--;
    8000190e:	387d                	addiw	a6,a6,-1
    80001910:	01052223          	sw	a6,4(a0)
  list->size--;
    80001914:	21052783          	lw	a5,528(a0)
    80001918:	37fd                	addiw	a5,a5,-1
    8000191a:	20f52823          	sw	a5,528(a0)
  if (list->tail < 0)
    8000191e:	02081793          	slli	a5,a6,0x20
    80001922:	0007c563          	bltz	a5,8000192c <qerase+0x64>
  {
    list->tail = NPROC;
  }
}
    80001926:	6422                	ld	s0,8(sp)
    80001928:	0141                	addi	sp,sp,16
    8000192a:	8082                	ret
    list->tail = NPROC;
    8000192c:	04000793          	li	a5,64
    80001930:	c15c                	sw	a5,4(a0)
}
    80001932:	bfd5                	j	80001926 <qerase+0x5e>

0000000080001934 <pinit>:

void pinit(void)
{
    80001934:	1141                	addi	sp,sp,-16
    80001936:	e422                	sd	s0,8(sp)
    80001938:	0800                	addi	s0,sp,16
  for (int i = 0; i < 5; i++)
    8000193a:	00010797          	auipc	a5,0x10
    8000193e:	d9678793          	addi	a5,a5,-618 # 800116d0 <mlfq_queue>
    80001942:	00011717          	auipc	a4,0x11
    80001946:	80670713          	addi	a4,a4,-2042 # 80012148 <proc>
  {
    mlfq_queue[i].size = 0;
    8000194a:	2007a823          	sw	zero,528(a5)
    mlfq_queue[i].head = 0;
    8000194e:	0007a023          	sw	zero,0(a5)
    mlfq_queue[i].tail = 0;
    80001952:	0007a223          	sw	zero,4(a5)
  for (int i = 0; i < 5; i++)
    80001956:	21878793          	addi	a5,a5,536
    8000195a:	fee798e3          	bne	a5,a4,8000194a <pinit+0x16>
  }
}
    8000195e:	6422                	ld	s0,8(sp)
    80001960:	0141                	addi	sp,sp,16
    80001962:	8082                	ret

0000000080001964 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001964:	7139                	addi	sp,sp,-64
    80001966:	fc06                	sd	ra,56(sp)
    80001968:	f822                	sd	s0,48(sp)
    8000196a:	f426                	sd	s1,40(sp)
    8000196c:	f04a                	sd	s2,32(sp)
    8000196e:	ec4e                	sd	s3,24(sp)
    80001970:	e852                	sd	s4,16(sp)
    80001972:	e456                	sd	s5,8(sp)
    80001974:	e05a                	sd	s6,0(sp)
    80001976:	0080                	addi	s0,sp,64
    80001978:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000197a:	00010497          	auipc	s1,0x10
    8000197e:	7ce48493          	addi	s1,s1,1998 # 80012148 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001982:	8b26                	mv	s6,s1
    80001984:	00006a97          	auipc	s5,0x6
    80001988:	67ca8a93          	addi	s5,s5,1660 # 80008000 <etext>
    8000198c:	04000937          	lui	s2,0x4000
    80001990:	197d                	addi	s2,s2,-1
    80001992:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001994:	00017a17          	auipc	s4,0x17
    80001998:	5b4a0a13          	addi	s4,s4,1460 # 80018f48 <tickslock>
    char *pa = kalloc();
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	158080e7          	jalr	344(ra) # 80000af4 <kalloc>
    800019a4:	862a                	mv	a2,a0
    if (pa == 0)
    800019a6:	c131                	beqz	a0,800019ea <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800019a8:	416485b3          	sub	a1,s1,s6
    800019ac:	858d                	srai	a1,a1,0x3
    800019ae:	000ab783          	ld	a5,0(s5)
    800019b2:	02f585b3          	mul	a1,a1,a5
    800019b6:	2585                	addiw	a1,a1,1
    800019b8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019bc:	4719                	li	a4,6
    800019be:	6685                	lui	a3,0x1
    800019c0:	40b905b3          	sub	a1,s2,a1
    800019c4:	854e                	mv	a0,s3
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	792080e7          	jalr	1938(ra) # 80001158 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800019ce:	1b848493          	addi	s1,s1,440
    800019d2:	fd4495e3          	bne	s1,s4,8000199c <proc_mapstacks+0x38>
  }
}
    800019d6:	70e2                	ld	ra,56(sp)
    800019d8:	7442                	ld	s0,48(sp)
    800019da:	74a2                	ld	s1,40(sp)
    800019dc:	7902                	ld	s2,32(sp)
    800019de:	69e2                	ld	s3,24(sp)
    800019e0:	6a42                	ld	s4,16(sp)
    800019e2:	6aa2                	ld	s5,8(sp)
    800019e4:	6b02                	ld	s6,0(sp)
    800019e6:	6121                	addi	sp,sp,64
    800019e8:	8082                	ret
      panic("kalloc");
    800019ea:	00006517          	auipc	a0,0x6
    800019ee:	7ee50513          	addi	a0,a0,2030 # 800081d8 <digits+0x198>
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>

00000000800019fa <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800019fa:	7139                	addi	sp,sp,-64
    800019fc:	fc06                	sd	ra,56(sp)
    800019fe:	f822                	sd	s0,48(sp)
    80001a00:	f426                	sd	s1,40(sp)
    80001a02:	f04a                	sd	s2,32(sp)
    80001a04:	ec4e                	sd	s3,24(sp)
    80001a06:	e852                	sd	s4,16(sp)
    80001a08:	e456                	sd	s5,8(sp)
    80001a0a:	e05a                	sd	s6,0(sp)
    80001a0c:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a0e:	00006597          	auipc	a1,0x6
    80001a12:	7d258593          	addi	a1,a1,2002 # 800081e0 <digits+0x1a0>
    80001a16:	00010517          	auipc	a0,0x10
    80001a1a:	88a50513          	addi	a0,a0,-1910 # 800112a0 <pid_lock>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	136080e7          	jalr	310(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a26:	00006597          	auipc	a1,0x6
    80001a2a:	7c258593          	addi	a1,a1,1986 # 800081e8 <digits+0x1a8>
    80001a2e:	00010517          	auipc	a0,0x10
    80001a32:	88a50513          	addi	a0,a0,-1910 # 800112b8 <wait_lock>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	11e080e7          	jalr	286(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a3e:	00010497          	auipc	s1,0x10
    80001a42:	70a48493          	addi	s1,s1,1802 # 80012148 <proc>
  {
    initlock(&p->lock, "proc");
    80001a46:	00006b17          	auipc	s6,0x6
    80001a4a:	7b2b0b13          	addi	s6,s6,1970 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001a4e:	8aa6                	mv	s5,s1
    80001a50:	00006a17          	auipc	s4,0x6
    80001a54:	5b0a0a13          	addi	s4,s4,1456 # 80008000 <etext>
    80001a58:	04000937          	lui	s2,0x4000
    80001a5c:	197d                	addi	s2,s2,-1
    80001a5e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a60:	00017997          	auipc	s3,0x17
    80001a64:	4e898993          	addi	s3,s3,1256 # 80018f48 <tickslock>
    initlock(&p->lock, "proc");
    80001a68:	85da                	mv	a1,s6
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	0e8080e7          	jalr	232(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001a74:	415487b3          	sub	a5,s1,s5
    80001a78:	878d                	srai	a5,a5,0x3
    80001a7a:	000a3703          	ld	a4,0(s4)
    80001a7e:	02e787b3          	mul	a5,a5,a4
    80001a82:	2785                	addiw	a5,a5,1
    80001a84:	00d7979b          	slliw	a5,a5,0xd
    80001a88:	40f907b3          	sub	a5,s2,a5
    80001a8c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8e:	1b848493          	addi	s1,s1,440
    80001a92:	fd349be3          	bne	s1,s3,80001a68 <procinit+0x6e>
  }
}
    80001a96:	70e2                	ld	ra,56(sp)
    80001a98:	7442                	ld	s0,48(sp)
    80001a9a:	74a2                	ld	s1,40(sp)
    80001a9c:	7902                	ld	s2,32(sp)
    80001a9e:	69e2                	ld	s3,24(sp)
    80001aa0:	6a42                	ld	s4,16(sp)
    80001aa2:	6aa2                	ld	s5,8(sp)
    80001aa4:	6b02                	ld	s6,0(sp)
    80001aa6:	6121                	addi	sp,sp,64
    80001aa8:	8082                	ret

0000000080001aaa <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001aaa:	1141                	addi	sp,sp,-16
    80001aac:	e422                	sd	s0,8(sp)
    80001aae:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ab0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ab2:	2501                	sext.w	a0,a0
    80001ab4:	6422                	ld	s0,8(sp)
    80001ab6:	0141                	addi	sp,sp,16
    80001ab8:	8082                	ret

0000000080001aba <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001aba:	1141                	addi	sp,sp,-16
    80001abc:	e422                	sd	s0,8(sp)
    80001abe:	0800                	addi	s0,sp,16
    80001ac0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ac2:	2781                	sext.w	a5,a5
    80001ac4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ac6:	00010517          	auipc	a0,0x10
    80001aca:	80a50513          	addi	a0,a0,-2038 # 800112d0 <cpus>
    80001ace:	953e                	add	a0,a0,a5
    80001ad0:	6422                	ld	s0,8(sp)
    80001ad2:	0141                	addi	sp,sp,16
    80001ad4:	8082                	ret

0000000080001ad6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001ad6:	1101                	addi	sp,sp,-32
    80001ad8:	ec06                	sd	ra,24(sp)
    80001ada:	e822                	sd	s0,16(sp)
    80001adc:	e426                	sd	s1,8(sp)
    80001ade:	1000                	addi	s0,sp,32
  push_off();
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	0b8080e7          	jalr	184(ra) # 80000b98 <push_off>
    80001ae8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aea:	2781                	sext.w	a5,a5
    80001aec:	079e                	slli	a5,a5,0x7
    80001aee:	0000f717          	auipc	a4,0xf
    80001af2:	7b270713          	addi	a4,a4,1970 # 800112a0 <pid_lock>
    80001af6:	97ba                	add	a5,a5,a4
    80001af8:	7b84                	ld	s1,48(a5)
  pop_off();
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	13e080e7          	jalr	318(ra) # 80000c38 <pop_off>
  return p;
}
    80001b02:	8526                	mv	a0,s1
    80001b04:	60e2                	ld	ra,24(sp)
    80001b06:	6442                	ld	s0,16(sp)
    80001b08:	64a2                	ld	s1,8(sp)
    80001b0a:	6105                	addi	sp,sp,32
    80001b0c:	8082                	ret

0000000080001b0e <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b0e:	1141                	addi	sp,sp,-16
    80001b10:	e406                	sd	ra,8(sp)
    80001b12:	e022                	sd	s0,0(sp)
    80001b14:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b16:	00000097          	auipc	ra,0x0
    80001b1a:	fc0080e7          	jalr	-64(ra) # 80001ad6 <myproc>
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	17a080e7          	jalr	378(ra) # 80000c98 <release>

  if (first)
    80001b26:	00007797          	auipc	a5,0x7
    80001b2a:	dea7a783          	lw	a5,-534(a5) # 80008910 <first.1774>
    80001b2e:	eb89                	bnez	a5,80001b40 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b30:	00001097          	auipc	ra,0x1
    80001b34:	f40080e7          	jalr	-192(ra) # 80002a70 <usertrapret>
}
    80001b38:	60a2                	ld	ra,8(sp)
    80001b3a:	6402                	ld	s0,0(sp)
    80001b3c:	0141                	addi	sp,sp,16
    80001b3e:	8082                	ret
    first = 0;
    80001b40:	00007797          	auipc	a5,0x7
    80001b44:	dc07a823          	sw	zero,-560(a5) # 80008910 <first.1774>
    fsinit(ROOTDEV);
    80001b48:	4505                	li	a0,1
    80001b4a:	00002097          	auipc	ra,0x2
    80001b4e:	ec0080e7          	jalr	-320(ra) # 80003a0a <fsinit>
    80001b52:	bff9                	j	80001b30 <forkret+0x22>

0000000080001b54 <allocpid>:
{
    80001b54:	1101                	addi	sp,sp,-32
    80001b56:	ec06                	sd	ra,24(sp)
    80001b58:	e822                	sd	s0,16(sp)
    80001b5a:	e426                	sd	s1,8(sp)
    80001b5c:	e04a                	sd	s2,0(sp)
    80001b5e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b60:	0000f917          	auipc	s2,0xf
    80001b64:	74090913          	addi	s2,s2,1856 # 800112a0 <pid_lock>
    80001b68:	854a                	mv	a0,s2
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b72:	00007797          	auipc	a5,0x7
    80001b76:	da278793          	addi	a5,a5,-606 # 80008914 <nextpid>
    80001b7a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7c:	0014871b          	addiw	a4,s1,1
    80001b80:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b82:	854a                	mv	a0,s2
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	114080e7          	jalr	276(ra) # 80000c98 <release>
}
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	60e2                	ld	ra,24(sp)
    80001b90:	6442                	ld	s0,16(sp)
    80001b92:	64a2                	ld	s1,8(sp)
    80001b94:	6902                	ld	s2,0(sp)
    80001b96:	6105                	addi	sp,sp,32
    80001b98:	8082                	ret

0000000080001b9a <proc_pagetable>:
{
    80001b9a:	1101                	addi	sp,sp,-32
    80001b9c:	ec06                	sd	ra,24(sp)
    80001b9e:	e822                	sd	s0,16(sp)
    80001ba0:	e426                	sd	s1,8(sp)
    80001ba2:	e04a                	sd	s2,0(sp)
    80001ba4:	1000                	addi	s0,sp,32
    80001ba6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	79a080e7          	jalr	1946(ra) # 80001342 <uvmcreate>
    80001bb0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bb2:	c121                	beqz	a0,80001bf2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb4:	4729                	li	a4,10
    80001bb6:	00005697          	auipc	a3,0x5
    80001bba:	44a68693          	addi	a3,a3,1098 # 80007000 <_trampoline>
    80001bbe:	6605                	lui	a2,0x1
    80001bc0:	040005b7          	lui	a1,0x4000
    80001bc4:	15fd                	addi	a1,a1,-1
    80001bc6:	05b2                	slli	a1,a1,0xc
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	4f0080e7          	jalr	1264(ra) # 800010b8 <mappages>
    80001bd0:	02054863          	bltz	a0,80001c00 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd4:	4719                	li	a4,6
    80001bd6:	05893683          	ld	a3,88(s2)
    80001bda:	6605                	lui	a2,0x1
    80001bdc:	020005b7          	lui	a1,0x2000
    80001be0:	15fd                	addi	a1,a1,-1
    80001be2:	05b6                	slli	a1,a1,0xd
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	4d2080e7          	jalr	1234(ra) # 800010b8 <mappages>
    80001bee:	02054163          	bltz	a0,80001c10 <proc_pagetable+0x76>
}
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6902                	ld	s2,0(sp)
    80001bfc:	6105                	addi	sp,sp,32
    80001bfe:	8082                	ret
    uvmfree(pagetable, 0);
    80001c00:	4581                	li	a1,0
    80001c02:	8526                	mv	a0,s1
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	93a080e7          	jalr	-1734(ra) # 8000153e <uvmfree>
    return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	b7d5                	j	80001bf2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c10:	4681                	li	a3,0
    80001c12:	4605                	li	a2,1
    80001c14:	040005b7          	lui	a1,0x4000
    80001c18:	15fd                	addi	a1,a1,-1
    80001c1a:	05b2                	slli	a1,a1,0xc
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	660080e7          	jalr	1632(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001c26:	4581                	li	a1,0
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	914080e7          	jalr	-1772(ra) # 8000153e <uvmfree>
    return 0;
    80001c32:	4481                	li	s1,0
    80001c34:	bf7d                	j	80001bf2 <proc_pagetable+0x58>

0000000080001c36 <proc_freepagetable>:
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	e04a                	sd	s2,0(sp)
    80001c40:	1000                	addi	s0,sp,32
    80001c42:	84aa                	mv	s1,a0
    80001c44:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	4605                	li	a2,1
    80001c4a:	040005b7          	lui	a1,0x4000
    80001c4e:	15fd                	addi	a1,a1,-1
    80001c50:	05b2                	slli	a1,a1,0xc
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	62c080e7          	jalr	1580(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c5a:	4681                	li	a3,0
    80001c5c:	4605                	li	a2,1
    80001c5e:	020005b7          	lui	a1,0x2000
    80001c62:	15fd                	addi	a1,a1,-1
    80001c64:	05b6                	slli	a1,a1,0xd
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	616080e7          	jalr	1558(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c70:	85ca                	mv	a1,s2
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	8ca080e7          	jalr	-1846(ra) # 8000153e <uvmfree>
}
    80001c7c:	60e2                	ld	ra,24(sp)
    80001c7e:	6442                	ld	s0,16(sp)
    80001c80:	64a2                	ld	s1,8(sp)
    80001c82:	6902                	ld	s2,0(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret

0000000080001c88 <freeproc>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
    80001c92:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c94:	6d28                	ld	a0,88(a0)
    80001c96:	c509                	beqz	a0,80001ca0 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	d60080e7          	jalr	-672(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ca0:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ca4:	68a8                	ld	a0,80(s1)
    80001ca6:	c511                	beqz	a0,80001cb2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ca8:	64ac                	ld	a1,72(s1)
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	f8c080e7          	jalr	-116(ra) # 80001c36 <proc_freepagetable>
  p->pagetable = 0;
    80001cb2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cb6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cba:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cbe:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cc2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cc6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cca:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cce:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cd2:	0004ac23          	sw	zero,24(s1)
}
    80001cd6:	60e2                	ld	ra,24(sp)
    80001cd8:	6442                	ld	s0,16(sp)
    80001cda:	64a2                	ld	s1,8(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret

0000000080001ce0 <allocproc>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	e04a                	sd	s2,0(sp)
    80001cea:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001cec:	00010497          	auipc	s1,0x10
    80001cf0:	45c48493          	addi	s1,s1,1116 # 80012148 <proc>
    80001cf4:	00017917          	auipc	s2,0x17
    80001cf8:	25490913          	addi	s2,s2,596 # 80018f48 <tickslock>
    acquire(&p->lock);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	ee6080e7          	jalr	-282(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001d06:	4c9c                	lw	a5,24(s1)
    80001d08:	cf81                	beqz	a5,80001d20 <allocproc+0x40>
      release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d14:	1b848493          	addi	s1,s1,440
    80001d18:	ff2492e3          	bne	s1,s2,80001cfc <allocproc+0x1c>
  return 0;
    80001d1c:	4481                	li	s1,0
    80001d1e:	a8ad                	j	80001d98 <allocproc+0xb8>
  p->pid = allocpid();
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	e34080e7          	jalr	-460(ra) # 80001b54 <allocpid>
    80001d28:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d2a:	4785                	li	a5,1
    80001d2c:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	dc6080e7          	jalr	-570(ra) # 80000af4 <kalloc>
    80001d36:	892a                	mv	s2,a0
    80001d38:	eca8                	sd	a0,88(s1)
    80001d3a:	c535                	beqz	a0,80001da6 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	e5c080e7          	jalr	-420(ra) # 80001b9a <proc_pagetable>
    80001d46:	892a                	mv	s2,a0
    80001d48:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d4a:	c935                	beqz	a0,80001dbe <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001d4c:	07000613          	li	a2,112
    80001d50:	4581                	li	a1,0
    80001d52:	06048513          	addi	a0,s1,96
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f8a080e7          	jalr	-118(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d5e:	00000797          	auipc	a5,0x0
    80001d62:	db078793          	addi	a5,a5,-592 # 80001b0e <forkret>
    80001d66:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d68:	60bc                	ld	a5,64(s1)
    80001d6a:	6705                	lui	a4,0x1
    80001d6c:	97ba                	add	a5,a5,a4
    80001d6e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001d70:	1604a623          	sw	zero,364(s1)
  p->etime = 0;
    80001d74:	1604aa23          	sw	zero,372(s1)
  p->ctime = ticks;
    80001d78:	00007797          	auipc	a5,0x7
    80001d7c:	2b87a783          	lw	a5,696(a5) # 80009030 <ticks>
    80001d80:	16f4a823          	sw	a5,368(s1)
    p->queue[i] = 0;
    80001d84:	1a04a023          	sw	zero,416(s1)
    80001d88:	1a04a223          	sw	zero,420(s1)
    80001d8c:	1a04a423          	sw	zero,424(s1)
    80001d90:	1a04a623          	sw	zero,428(s1)
    80001d94:	1a04a823          	sw	zero,432(s1)
}
    80001d98:	8526                	mv	a0,s1
    80001d9a:	60e2                	ld	ra,24(sp)
    80001d9c:	6442                	ld	s0,16(sp)
    80001d9e:	64a2                	ld	s1,8(sp)
    80001da0:	6902                	ld	s2,0(sp)
    80001da2:	6105                	addi	sp,sp,32
    80001da4:	8082                	ret
    freeproc(p);
    80001da6:	8526                	mv	a0,s1
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	ee0080e7          	jalr	-288(ra) # 80001c88 <freeproc>
    release(&p->lock);
    80001db0:	8526                	mv	a0,s1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	ee6080e7          	jalr	-282(ra) # 80000c98 <release>
    return 0;
    80001dba:	84ca                	mv	s1,s2
    80001dbc:	bff1                	j	80001d98 <allocproc+0xb8>
    freeproc(p);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	ec8080e7          	jalr	-312(ra) # 80001c88 <freeproc>
    release(&p->lock);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	ece080e7          	jalr	-306(ra) # 80000c98 <release>
    return 0;
    80001dd2:	84ca                	mv	s1,s2
    80001dd4:	b7d1                	j	80001d98 <allocproc+0xb8>

0000000080001dd6 <userinit>:
{
    80001dd6:	1101                	addi	sp,sp,-32
    80001dd8:	ec06                	sd	ra,24(sp)
    80001dda:	e822                	sd	s0,16(sp)
    80001ddc:	e426                	sd	s1,8(sp)
    80001dde:	1000                	addi	s0,sp,32
  p = allocproc();
    80001de0:	00000097          	auipc	ra,0x0
    80001de4:	f00080e7          	jalr	-256(ra) # 80001ce0 <allocproc>
    80001de8:	84aa                	mv	s1,a0
  initproc = p;
    80001dea:	00007797          	auipc	a5,0x7
    80001dee:	22a7bf23          	sd	a0,574(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001df2:	03400613          	li	a2,52
    80001df6:	00007597          	auipc	a1,0x7
    80001dfa:	b2a58593          	addi	a1,a1,-1238 # 80008920 <initcode>
    80001dfe:	6928                	ld	a0,80(a0)
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	570080e7          	jalr	1392(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001e08:	6785                	lui	a5,0x1
    80001e0a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e0c:	6cb8                	ld	a4,88(s1)
    80001e0e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e12:	6cb8                	ld	a4,88(s1)
    80001e14:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e16:	4641                	li	a2,16
    80001e18:	00006597          	auipc	a1,0x6
    80001e1c:	3e858593          	addi	a1,a1,1000 # 80008200 <digits+0x1c0>
    80001e20:	15848513          	addi	a0,s1,344
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	00e080e7          	jalr	14(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e2c:	00006517          	auipc	a0,0x6
    80001e30:	3e450513          	addi	a0,a0,996 # 80008210 <digits+0x1d0>
    80001e34:	00002097          	auipc	ra,0x2
    80001e38:	604080e7          	jalr	1540(ra) # 80004438 <namei>
    80001e3c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e40:	478d                	li	a5,3
    80001e42:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e44:	8526                	mv	a0,s1
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e52080e7          	jalr	-430(ra) # 80000c98 <release>
}
    80001e4e:	60e2                	ld	ra,24(sp)
    80001e50:	6442                	ld	s0,16(sp)
    80001e52:	64a2                	ld	s1,8(sp)
    80001e54:	6105                	addi	sp,sp,32
    80001e56:	8082                	ret

0000000080001e58 <growproc>:
{
    80001e58:	1101                	addi	sp,sp,-32
    80001e5a:	ec06                	sd	ra,24(sp)
    80001e5c:	e822                	sd	s0,16(sp)
    80001e5e:	e426                	sd	s1,8(sp)
    80001e60:	e04a                	sd	s2,0(sp)
    80001e62:	1000                	addi	s0,sp,32
    80001e64:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	c70080e7          	jalr	-912(ra) # 80001ad6 <myproc>
    80001e6e:	892a                	mv	s2,a0
  sz = p->sz;
    80001e70:	652c                	ld	a1,72(a0)
    80001e72:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001e76:	00904f63          	bgtz	s1,80001e94 <growproc+0x3c>
  else if (n < 0)
    80001e7a:	0204cc63          	bltz	s1,80001eb2 <growproc+0x5a>
  p->sz = sz;
    80001e7e:	1602                	slli	a2,a2,0x20
    80001e80:	9201                	srli	a2,a2,0x20
    80001e82:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e86:	4501                	li	a0,0
}
    80001e88:	60e2                	ld	ra,24(sp)
    80001e8a:	6442                	ld	s0,16(sp)
    80001e8c:	64a2                	ld	s1,8(sp)
    80001e8e:	6902                	ld	s2,0(sp)
    80001e90:	6105                	addi	sp,sp,32
    80001e92:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001e94:	9e25                	addw	a2,a2,s1
    80001e96:	1602                	slli	a2,a2,0x20
    80001e98:	9201                	srli	a2,a2,0x20
    80001e9a:	1582                	slli	a1,a1,0x20
    80001e9c:	9181                	srli	a1,a1,0x20
    80001e9e:	6928                	ld	a0,80(a0)
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	58a080e7          	jalr	1418(ra) # 8000142a <uvmalloc>
    80001ea8:	0005061b          	sext.w	a2,a0
    80001eac:	fa69                	bnez	a2,80001e7e <growproc+0x26>
      return -1;
    80001eae:	557d                	li	a0,-1
    80001eb0:	bfe1                	j	80001e88 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eb2:	9e25                	addw	a2,a2,s1
    80001eb4:	1602                	slli	a2,a2,0x20
    80001eb6:	9201                	srli	a2,a2,0x20
    80001eb8:	1582                	slli	a1,a1,0x20
    80001eba:	9181                	srli	a1,a1,0x20
    80001ebc:	6928                	ld	a0,80(a0)
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	524080e7          	jalr	1316(ra) # 800013e2 <uvmdealloc>
    80001ec6:	0005061b          	sext.w	a2,a0
    80001eca:	bf55                	j	80001e7e <growproc+0x26>

0000000080001ecc <fork>:
{
    80001ecc:	7179                	addi	sp,sp,-48
    80001ece:	f406                	sd	ra,40(sp)
    80001ed0:	f022                	sd	s0,32(sp)
    80001ed2:	ec26                	sd	s1,24(sp)
    80001ed4:	e84a                	sd	s2,16(sp)
    80001ed6:	e44e                	sd	s3,8(sp)
    80001ed8:	e052                	sd	s4,0(sp)
    80001eda:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001edc:	00000097          	auipc	ra,0x0
    80001ee0:	bfa080e7          	jalr	-1030(ra) # 80001ad6 <myproc>
    80001ee4:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	dfa080e7          	jalr	-518(ra) # 80001ce0 <allocproc>
    80001eee:	10050f63          	beqz	a0,8000200c <fork+0x140>
    80001ef2:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ef4:	04893603          	ld	a2,72(s2)
    80001ef8:	692c                	ld	a1,80(a0)
    80001efa:	05093503          	ld	a0,80(s2)
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	678080e7          	jalr	1656(ra) # 80001576 <uvmcopy>
    80001f06:	04054a63          	bltz	a0,80001f5a <fork+0x8e>
  np->trace_mask = p->trace_mask;
    80001f0a:	16892783          	lw	a5,360(s2)
    80001f0e:	16f9a423          	sw	a5,360(s3)
  np->sz = p->sz;
    80001f12:	04893783          	ld	a5,72(s2)
    80001f16:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f1a:	05893683          	ld	a3,88(s2)
    80001f1e:	87b6                	mv	a5,a3
    80001f20:	0589b703          	ld	a4,88(s3)
    80001f24:	12068693          	addi	a3,a3,288
    80001f28:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f2c:	6788                	ld	a0,8(a5)
    80001f2e:	6b8c                	ld	a1,16(a5)
    80001f30:	6f90                	ld	a2,24(a5)
    80001f32:	01073023          	sd	a6,0(a4)
    80001f36:	e708                	sd	a0,8(a4)
    80001f38:	eb0c                	sd	a1,16(a4)
    80001f3a:	ef10                	sd	a2,24(a4)
    80001f3c:	02078793          	addi	a5,a5,32
    80001f40:	02070713          	addi	a4,a4,32
    80001f44:	fed792e3          	bne	a5,a3,80001f28 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001f48:	0589b783          	ld	a5,88(s3)
    80001f4c:	0607b823          	sd	zero,112(a5)
    80001f50:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001f54:	15000a13          	li	s4,336
    80001f58:	a03d                	j	80001f86 <fork+0xba>
    freeproc(np);
    80001f5a:	854e                	mv	a0,s3
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	d2c080e7          	jalr	-724(ra) # 80001c88 <freeproc>
    release(&np->lock);
    80001f64:	854e                	mv	a0,s3
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d32080e7          	jalr	-718(ra) # 80000c98 <release>
    return -1;
    80001f6e:	5a7d                	li	s4,-1
    80001f70:	a069                	j	80001ffa <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f72:	00003097          	auipc	ra,0x3
    80001f76:	b5c080e7          	jalr	-1188(ra) # 80004ace <filedup>
    80001f7a:	009987b3          	add	a5,s3,s1
    80001f7e:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001f80:	04a1                	addi	s1,s1,8
    80001f82:	01448763          	beq	s1,s4,80001f90 <fork+0xc4>
    if (p->ofile[i])
    80001f86:	009907b3          	add	a5,s2,s1
    80001f8a:	6388                	ld	a0,0(a5)
    80001f8c:	f17d                	bnez	a0,80001f72 <fork+0xa6>
    80001f8e:	bfcd                	j	80001f80 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001f90:	15093503          	ld	a0,336(s2)
    80001f94:	00002097          	auipc	ra,0x2
    80001f98:	cb0080e7          	jalr	-848(ra) # 80003c44 <idup>
    80001f9c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fa0:	4641                	li	a2,16
    80001fa2:	15890593          	addi	a1,s2,344
    80001fa6:	15898513          	addi	a0,s3,344
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	e88080e7          	jalr	-376(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001fb2:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001fb6:	854e                	mv	a0,s3
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001fc0:	0000f497          	auipc	s1,0xf
    80001fc4:	2f848493          	addi	s1,s1,760 # 800112b8 <wait_lock>
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c1a080e7          	jalr	-998(ra) # 80000be4 <acquire>
  np->parent = p;
    80001fd2:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001fe0:	854e                	mv	a0,s3
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	c02080e7          	jalr	-1022(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fea:	478d                	li	a5,3
    80001fec:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ff0:	854e                	mv	a0,s3
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
}
    80001ffa:	8552                	mv	a0,s4
    80001ffc:	70a2                	ld	ra,40(sp)
    80001ffe:	7402                	ld	s0,32(sp)
    80002000:	64e2                	ld	s1,24(sp)
    80002002:	6942                	ld	s2,16(sp)
    80002004:	69a2                	ld	s3,8(sp)
    80002006:	6a02                	ld	s4,0(sp)
    80002008:	6145                	addi	sp,sp,48
    8000200a:	8082                	ret
    return -1;
    8000200c:	5a7d                	li	s4,-1
    8000200e:	b7f5                	j	80001ffa <fork+0x12e>

0000000080002010 <update_time>:
{
    80002010:	7179                	addi	sp,sp,-48
    80002012:	f406                	sd	ra,40(sp)
    80002014:	f022                	sd	s0,32(sp)
    80002016:	ec26                	sd	s1,24(sp)
    80002018:	e84a                	sd	s2,16(sp)
    8000201a:	e44e                	sd	s3,8(sp)
    8000201c:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    8000201e:	00010497          	auipc	s1,0x10
    80002022:	12a48493          	addi	s1,s1,298 # 80012148 <proc>
    if (p->state == RUNNING)
    80002026:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002028:	00017917          	auipc	s2,0x17
    8000202c:	f2090913          	addi	s2,s2,-224 # 80018f48 <tickslock>
    80002030:	a811                	j	80002044 <update_time+0x34>
    release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000203c:	1b848493          	addi	s1,s1,440
    80002040:	03248063          	beq	s1,s2,80002060 <update_time+0x50>
    acquire(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	b9e080e7          	jalr	-1122(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    8000204e:	4c9c                	lw	a5,24(s1)
    80002050:	ff3791e3          	bne	a5,s3,80002032 <update_time+0x22>
      p->rtime++;
    80002054:	16c4a783          	lw	a5,364(s1)
    80002058:	2785                	addiw	a5,a5,1
    8000205a:	16f4a623          	sw	a5,364(s1)
    8000205e:	bfd1                	j	80002032 <update_time+0x22>
}
    80002060:	70a2                	ld	ra,40(sp)
    80002062:	7402                	ld	s0,32(sp)
    80002064:	64e2                	ld	s1,24(sp)
    80002066:	6942                	ld	s2,16(sp)
    80002068:	69a2                	ld	s3,8(sp)
    8000206a:	6145                	addi	sp,sp,48
    8000206c:	8082                	ret

000000008000206e <ageing>:
{
    8000206e:	715d                	addi	sp,sp,-80
    80002070:	e486                	sd	ra,72(sp)
    80002072:	e0a2                	sd	s0,64(sp)
    80002074:	fc26                	sd	s1,56(sp)
    80002076:	f84a                	sd	s2,48(sp)
    80002078:	f44e                	sd	s3,40(sp)
    8000207a:	f052                	sd	s4,32(sp)
    8000207c:	ec56                	sd	s5,24(sp)
    8000207e:	e85a                	sd	s6,16(sp)
    80002080:	e45e                	sd	s7,8(sp)
    80002082:	0880                	addi	s0,sp,80
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002084:	00010497          	auipc	s1,0x10
    80002088:	0c448493          	addi	s1,s1,196 # 80012148 <proc>
    if (p->state == RUNNABLE && ticks - p->queue_enter_time >= 128)
    8000208c:	498d                	li	s3,3
    8000208e:	00007a17          	auipc	s4,0x7
    80002092:	fa2a0a13          	addi	s4,s4,-94 # 80009030 <ticks>
    80002096:	07f00a93          	li	s5,127
        qerase(&mlfq_queue[p->level], p->pid);
    8000209a:	21800b93          	li	s7,536
    8000209e:	0000fb17          	auipc	s6,0xf
    800020a2:	632b0b13          	addi	s6,s6,1586 # 800116d0 <mlfq_queue>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800020a6:	00017917          	auipc	s2,0x17
    800020aa:	ea290913          	addi	s2,s2,-350 # 80018f48 <tickslock>
    800020ae:	a035                	j	800020da <ageing+0x6c>
        qerase(&mlfq_queue[p->level], p->pid);
    800020b0:	1904a503          	lw	a0,400(s1)
    800020b4:	03750533          	mul	a0,a0,s7
    800020b8:	588c                	lw	a1,48(s1)
    800020ba:	955a                	add	a0,a0,s6
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	80c080e7          	jalr	-2036(ra) # 800018c8 <qerase>
        p->in_queue = 0;
    800020c4:	1804aa23          	sw	zero,404(s1)
    800020c8:	a035                	j	800020f4 <ageing+0x86>
      p->queue_enter_time = ticks;
    800020ca:	000a2783          	lw	a5,0(s4)
    800020ce:	18f4ae23          	sw	a5,412(s1)
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800020d2:	1b848493          	addi	s1,s1,440
    800020d6:	03248663          	beq	s1,s2,80002102 <ageing+0x94>
    if (p->state == RUNNABLE && ticks - p->queue_enter_time >= 128)
    800020da:	4c9c                	lw	a5,24(s1)
    800020dc:	ff379be3          	bne	a5,s3,800020d2 <ageing+0x64>
    800020e0:	000a2783          	lw	a5,0(s4)
    800020e4:	19c4a703          	lw	a4,412(s1)
    800020e8:	9f99                	subw	a5,a5,a4
    800020ea:	fefaf4e3          	bgeu	s5,a5,800020d2 <ageing+0x64>
      if (p->in_queue)
    800020ee:	1944a783          	lw	a5,404(s1)
    800020f2:	ffdd                	bnez	a5,800020b0 <ageing+0x42>
      if (p->level != 0)
    800020f4:	1904a783          	lw	a5,400(s1)
    800020f8:	dbe9                	beqz	a5,800020ca <ageing+0x5c>
        p->level--;
    800020fa:	37fd                	addiw	a5,a5,-1
    800020fc:	18f4a823          	sw	a5,400(s1)
    80002100:	b7e9                	j	800020ca <ageing+0x5c>
}
    80002102:	60a6                	ld	ra,72(sp)
    80002104:	6406                	ld	s0,64(sp)
    80002106:	74e2                	ld	s1,56(sp)
    80002108:	7942                	ld	s2,48(sp)
    8000210a:	79a2                	ld	s3,40(sp)
    8000210c:	7a02                	ld	s4,32(sp)
    8000210e:	6ae2                	ld	s5,24(sp)
    80002110:	6b42                	ld	s6,16(sp)
    80002112:	6ba2                	ld	s7,8(sp)
    80002114:	6161                	addi	sp,sp,80
    80002116:	8082                	ret

0000000080002118 <scheduler>:
{
    80002118:	7139                	addi	sp,sp,-64
    8000211a:	fc06                	sd	ra,56(sp)
    8000211c:	f822                	sd	s0,48(sp)
    8000211e:	f426                	sd	s1,40(sp)
    80002120:	f04a                	sd	s2,32(sp)
    80002122:	ec4e                	sd	s3,24(sp)
    80002124:	e852                	sd	s4,16(sp)
    80002126:	e456                	sd	s5,8(sp)
    80002128:	e05a                	sd	s6,0(sp)
    8000212a:	0080                	addi	s0,sp,64
    8000212c:	8792                	mv	a5,tp
  int id = r_tp();
    8000212e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002130:	00779a93          	slli	s5,a5,0x7
    80002134:	0000f717          	auipc	a4,0xf
    80002138:	16c70713          	addi	a4,a4,364 # 800112a0 <pid_lock>
    8000213c:	9756                	add	a4,a4,s5
    8000213e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002142:	0000f717          	auipc	a4,0xf
    80002146:	19670713          	addi	a4,a4,406 # 800112d8 <cpus+0x8>
    8000214a:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000214c:	498d                	li	s3,3
        p->state = RUNNING;
    8000214e:	4b11                	li	s6,4
        c->proc = p;
    80002150:	079e                	slli	a5,a5,0x7
    80002152:	0000fa17          	auipc	s4,0xf
    80002156:	14ea0a13          	addi	s4,s4,334 # 800112a0 <pid_lock>
    8000215a:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000215c:	00017917          	auipc	s2,0x17
    80002160:	dec90913          	addi	s2,s2,-532 # 80018f48 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002164:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002168:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000216c:	10079073          	csrw	sstatus,a5
    80002170:	00010497          	auipc	s1,0x10
    80002174:	fd848493          	addi	s1,s1,-40 # 80012148 <proc>
    80002178:	a03d                	j	800021a6 <scheduler+0x8e>
        p->state = RUNNING;
    8000217a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000217e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002182:	06048593          	addi	a1,s1,96
    80002186:	8556                	mv	a0,s5
    80002188:	00001097          	auipc	ra,0x1
    8000218c:	83e080e7          	jalr	-1986(ra) # 800029c6 <swtch>
        c->proc = 0;
    80002190:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000219e:	1b848493          	addi	s1,s1,440
    800021a2:	fd2481e3          	beq	s1,s2,80002164 <scheduler+0x4c>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a3c080e7          	jalr	-1476(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	ff3791e3          	bne	a5,s3,80002194 <scheduler+0x7c>
    800021b6:	b7d1                	j	8000217a <scheduler+0x62>

00000000800021b8 <sched>:
{
    800021b8:	7179                	addi	sp,sp,-48
    800021ba:	f406                	sd	ra,40(sp)
    800021bc:	f022                	sd	s0,32(sp)
    800021be:	ec26                	sd	s1,24(sp)
    800021c0:	e84a                	sd	s2,16(sp)
    800021c2:	e44e                	sd	s3,8(sp)
    800021c4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	910080e7          	jalr	-1776(ra) # 80001ad6 <myproc>
    800021ce:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	99a080e7          	jalr	-1638(ra) # 80000b6a <holding>
    800021d8:	c93d                	beqz	a0,8000224e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021da:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021dc:	2781                	sext.w	a5,a5
    800021de:	079e                	slli	a5,a5,0x7
    800021e0:	0000f717          	auipc	a4,0xf
    800021e4:	0c070713          	addi	a4,a4,192 # 800112a0 <pid_lock>
    800021e8:	97ba                	add	a5,a5,a4
    800021ea:	0a87a703          	lw	a4,168(a5)
    800021ee:	4785                	li	a5,1
    800021f0:	06f71763          	bne	a4,a5,8000225e <sched+0xa6>
  if (p->state == RUNNING)
    800021f4:	4c98                	lw	a4,24(s1)
    800021f6:	4791                	li	a5,4
    800021f8:	06f70b63          	beq	a4,a5,8000226e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021fc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002200:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002202:	efb5                	bnez	a5,8000227e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002204:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002206:	0000f917          	auipc	s2,0xf
    8000220a:	09a90913          	addi	s2,s2,154 # 800112a0 <pid_lock>
    8000220e:	2781                	sext.w	a5,a5
    80002210:	079e                	slli	a5,a5,0x7
    80002212:	97ca                	add	a5,a5,s2
    80002214:	0ac7a983          	lw	s3,172(a5)
    80002218:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000221a:	2781                	sext.w	a5,a5
    8000221c:	079e                	slli	a5,a5,0x7
    8000221e:	0000f597          	auipc	a1,0xf
    80002222:	0ba58593          	addi	a1,a1,186 # 800112d8 <cpus+0x8>
    80002226:	95be                	add	a1,a1,a5
    80002228:	06048513          	addi	a0,s1,96
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	79a080e7          	jalr	1946(ra) # 800029c6 <swtch>
    80002234:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002236:	2781                	sext.w	a5,a5
    80002238:	079e                	slli	a5,a5,0x7
    8000223a:	97ca                	add	a5,a5,s2
    8000223c:	0b37a623          	sw	s3,172(a5)
}
    80002240:	70a2                	ld	ra,40(sp)
    80002242:	7402                	ld	s0,32(sp)
    80002244:	64e2                	ld	s1,24(sp)
    80002246:	6942                	ld	s2,16(sp)
    80002248:	69a2                	ld	s3,8(sp)
    8000224a:	6145                	addi	sp,sp,48
    8000224c:	8082                	ret
    panic("sched p->lock");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	fca50513          	addi	a0,a0,-54 # 80008218 <digits+0x1d8>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>
    panic("sched locks");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	fca50513          	addi	a0,a0,-54 # 80008228 <digits+0x1e8>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2d8080e7          	jalr	728(ra) # 8000053e <panic>
    panic("sched running");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	fca50513          	addi	a0,a0,-54 # 80008238 <digits+0x1f8>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000227e:	00006517          	auipc	a0,0x6
    80002282:	fca50513          	addi	a0,a0,-54 # 80008248 <digits+0x208>
    80002286:	ffffe097          	auipc	ra,0xffffe
    8000228a:	2b8080e7          	jalr	696(ra) # 8000053e <panic>

000000008000228e <yield>:
{
    8000228e:	1101                	addi	sp,sp,-32
    80002290:	ec06                	sd	ra,24(sp)
    80002292:	e822                	sd	s0,16(sp)
    80002294:	e426                	sd	s1,8(sp)
    80002296:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	83e080e7          	jalr	-1986(ra) # 80001ad6 <myproc>
    800022a0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022aa:	478d                	li	a5,3
    800022ac:	cc9c                	sw	a5,24(s1)
  sched();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	f0a080e7          	jalr	-246(ra) # 800021b8 <sched>
  release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
}
    800022c0:	60e2                	ld	ra,24(sp)
    800022c2:	6442                	ld	s0,16(sp)
    800022c4:	64a2                	ld	s1,8(sp)
    800022c6:	6105                	addi	sp,sp,32
    800022c8:	8082                	ret

00000000800022ca <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	89aa                	mv	s3,a0
    800022da:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	7fa080e7          	jalr	2042(ra) # 80001ad6 <myproc>
    800022e4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	8fe080e7          	jalr	-1794(ra) # 80000be4 <acquire>
  release(lk);
    800022ee:	854a                	mv	a0,s2
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	9a8080e7          	jalr	-1624(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800022f8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022fc:	4789                	li	a5,2
    800022fe:	cc9c                	sw	a5,24(s1)

  sched();
    80002300:	00000097          	auipc	ra,0x0
    80002304:	eb8080e7          	jalr	-328(ra) # 800021b8 <sched>

  // Tidy up.
  p->chan = 0;
    80002308:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
  acquire(lk);
    80002316:	854a                	mv	a0,s2
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8cc080e7          	jalr	-1844(ra) # 80000be4 <acquire>
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	addi	sp,sp,48
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	78e080e7          	jalr	1934(ra) # 80001ad6 <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	f6650513          	addi	a0,a0,-154 # 800112b8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	88a080e7          	jalr	-1910(ra) # 80000be4 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002364:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002366:	00017997          	auipc	s3,0x17
    8000236a:	be298993          	addi	s3,s3,-1054 # 80018f48 <tickslock>
        havekids = 1;
    8000236e:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	f48c0c13          	addi	s8,s8,-184 # 800112b8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000237a:	00010497          	auipc	s1,0x10
    8000237e:	dce48493          	addi	s1,s1,-562 # 80012148 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = np->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2e2080e7          	jalr	738(ra) # 8000167a <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(np);
    800023a4:	8526                	mv	a0,s1
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	8e2080e7          	jalr	-1822(ra) # 80001c88 <freeproc>
          release(&np->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8e8080e7          	jalr	-1816(ra) # 80000c98 <release>
          release(&wait_lock);
    800023b8:	0000f517          	auipc	a0,0xf
    800023bc:	f0050513          	addi	a0,a0,-256 # 800112b8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
          return pid;
    800023c8:	a09d                	j	8000242e <wait+0x100>
            release(&np->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8cc080e7          	jalr	-1844(ra) # 80000c98 <release>
            release(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	ee450513          	addi	a0,a0,-284 # 800112b8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8bc080e7          	jalr	-1860(ra) # 80000c98 <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0a1                	j	8000242e <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800023e8:	1b848493          	addi	s1,s1,440
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if (np->parent == p)
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&np->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7ec080e7          	jalr	2028(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&np->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	890080e7          	jalr	-1904(ra) # 80000c98 <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if (!havekids || p->killed)
    80002414:	c701                	beqz	a4,8000241c <wait+0xee>
    80002416:	02892783          	lw	a5,40(s2)
    8000241a:	c79d                	beqz	a5,80002448 <wait+0x11a>
      release(&wait_lock);
    8000241c:	0000f517          	auipc	a0,0xf
    80002420:	e9c50513          	addi	a0,a0,-356 # 800112b8 <wait_lock>
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
      return -1;
    8000242c:	59fd                	li	s3,-1
}
    8000242e:	854e                	mv	a0,s3
    80002430:	60a6                	ld	ra,72(sp)
    80002432:	6406                	ld	s0,64(sp)
    80002434:	74e2                	ld	s1,56(sp)
    80002436:	7942                	ld	s2,48(sp)
    80002438:	79a2                	ld	s3,40(sp)
    8000243a:	7a02                	ld	s4,32(sp)
    8000243c:	6ae2                	ld	s5,24(sp)
    8000243e:	6b42                	ld	s6,16(sp)
    80002440:	6ba2                	ld	s7,8(sp)
    80002442:	6c02                	ld	s8,0(sp)
    80002444:	6161                	addi	sp,sp,80
    80002446:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002448:	85e2                	mv	a1,s8
    8000244a:	854a                	mv	a0,s2
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	e7e080e7          	jalr	-386(ra) # 800022ca <sleep>
    havekids = 0;
    80002454:	b715                	j	80002378 <wait+0x4a>

0000000080002456 <waitx>:
{
    80002456:	711d                	addi	sp,sp,-96
    80002458:	ec86                	sd	ra,88(sp)
    8000245a:	e8a2                	sd	s0,80(sp)
    8000245c:	e4a6                	sd	s1,72(sp)
    8000245e:	e0ca                	sd	s2,64(sp)
    80002460:	fc4e                	sd	s3,56(sp)
    80002462:	f852                	sd	s4,48(sp)
    80002464:	f456                	sd	s5,40(sp)
    80002466:	f05a                	sd	s6,32(sp)
    80002468:	ec5e                	sd	s7,24(sp)
    8000246a:	e862                	sd	s8,16(sp)
    8000246c:	e466                	sd	s9,8(sp)
    8000246e:	e06a                	sd	s10,0(sp)
    80002470:	1080                	addi	s0,sp,96
    80002472:	8b2a                	mv	s6,a0
    80002474:	8c2e                	mv	s8,a1
    80002476:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	65e080e7          	jalr	1630(ra) # 80001ad6 <myproc>
    80002480:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002482:	0000f517          	auipc	a0,0xf
    80002486:	e3650513          	addi	a0,a0,-458 # 800112b8 <wait_lock>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	75a080e7          	jalr	1882(ra) # 80000be4 <acquire>
    havekids = 0;
    80002492:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    80002494:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002496:	00017997          	auipc	s3,0x17
    8000249a:	ab298993          	addi	s3,s3,-1358 # 80018f48 <tickslock>
        havekids = 1;
    8000249e:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024a0:	0000fd17          	auipc	s10,0xf
    800024a4:	e18d0d13          	addi	s10,s10,-488 # 800112b8 <wait_lock>
    havekids = 0;
    800024a8:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800024aa:	00010497          	auipc	s1,0x10
    800024ae:	c9e48493          	addi	s1,s1,-866 # 80012148 <proc>
    800024b2:	a059                	j	80002538 <waitx+0xe2>
          pid = np->pid;
    800024b4:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800024b8:	16c4a703          	lw	a4,364(s1)
    800024bc:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800024c0:	1704a783          	lw	a5,368(s1)
    800024c4:	9f3d                	addw	a4,a4,a5
    800024c6:	1744a783          	lw	a5,372(s1)
    800024ca:	9f99                	subw	a5,a5,a4
    800024cc:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024d0:	000b0e63          	beqz	s6,800024ec <waitx+0x96>
    800024d4:	4691                	li	a3,4
    800024d6:	02c48613          	addi	a2,s1,44
    800024da:	85da                	mv	a1,s6
    800024dc:	05093503          	ld	a0,80(s2)
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	19a080e7          	jalr	410(ra) # 8000167a <copyout>
    800024e8:	02054563          	bltz	a0,80002512 <waitx+0xbc>
          freeproc(np);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	79a080e7          	jalr	1946(ra) # 80001c88 <freeproc>
          release(&np->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	7a0080e7          	jalr	1952(ra) # 80000c98 <release>
          release(&wait_lock);
    80002500:	0000f517          	auipc	a0,0xf
    80002504:	db850513          	addi	a0,a0,-584 # 800112b8 <wait_lock>
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	790080e7          	jalr	1936(ra) # 80000c98 <release>
          return pid;
    80002510:	a09d                	j	80002576 <waitx+0x120>
            release(&np->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
            release(&wait_lock);
    8000251c:	0000f517          	auipc	a0,0xf
    80002520:	d9c50513          	addi	a0,a0,-612 # 800112b8 <wait_lock>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
            return -1;
    8000252c:	59fd                	li	s3,-1
    8000252e:	a0a1                	j	80002576 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002530:	1b848493          	addi	s1,s1,440
    80002534:	03348463          	beq	s1,s3,8000255c <waitx+0x106>
      if (np->parent == p)
    80002538:	7c9c                	ld	a5,56(s1)
    8000253a:	ff279be3          	bne	a5,s2,80002530 <waitx+0xda>
        acquire(&np->lock);
    8000253e:	8526                	mv	a0,s1
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	6a4080e7          	jalr	1700(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002548:	4c9c                	lw	a5,24(s1)
    8000254a:	f74785e3          	beq	a5,s4,800024b4 <waitx+0x5e>
        release(&np->lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	748080e7          	jalr	1864(ra) # 80000c98 <release>
        havekids = 1;
    80002558:	8756                	mv	a4,s5
    8000255a:	bfd9                	j	80002530 <waitx+0xda>
    if (!havekids || p->killed)
    8000255c:	c701                	beqz	a4,80002564 <waitx+0x10e>
    8000255e:	02892783          	lw	a5,40(s2)
    80002562:	cb8d                	beqz	a5,80002594 <waitx+0x13e>
      release(&wait_lock);
    80002564:	0000f517          	auipc	a0,0xf
    80002568:	d5450513          	addi	a0,a0,-684 # 800112b8 <wait_lock>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	72c080e7          	jalr	1836(ra) # 80000c98 <release>
      return -1;
    80002574:	59fd                	li	s3,-1
}
    80002576:	854e                	mv	a0,s3
    80002578:	60e6                	ld	ra,88(sp)
    8000257a:	6446                	ld	s0,80(sp)
    8000257c:	64a6                	ld	s1,72(sp)
    8000257e:	6906                	ld	s2,64(sp)
    80002580:	79e2                	ld	s3,56(sp)
    80002582:	7a42                	ld	s4,48(sp)
    80002584:	7aa2                	ld	s5,40(sp)
    80002586:	7b02                	ld	s6,32(sp)
    80002588:	6be2                	ld	s7,24(sp)
    8000258a:	6c42                	ld	s8,16(sp)
    8000258c:	6ca2                	ld	s9,8(sp)
    8000258e:	6d02                	ld	s10,0(sp)
    80002590:	6125                	addi	sp,sp,96
    80002592:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002594:	85ea                	mv	a1,s10
    80002596:	854a                	mv	a0,s2
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	d32080e7          	jalr	-718(ra) # 800022ca <sleep>
    havekids = 0;
    800025a0:	b721                	j	800024a8 <waitx+0x52>

00000000800025a2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800025a2:	7139                	addi	sp,sp,-64
    800025a4:	fc06                	sd	ra,56(sp)
    800025a6:	f822                	sd	s0,48(sp)
    800025a8:	f426                	sd	s1,40(sp)
    800025aa:	f04a                	sd	s2,32(sp)
    800025ac:	ec4e                	sd	s3,24(sp)
    800025ae:	e852                	sd	s4,16(sp)
    800025b0:	e456                	sd	s5,8(sp)
    800025b2:	0080                	addi	s0,sp,64
    800025b4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025b6:	00010497          	auipc	s1,0x10
    800025ba:	b9248493          	addi	s1,s1,-1134 # 80012148 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800025be:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800025c0:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800025c2:	00017917          	auipc	s2,0x17
    800025c6:	98690913          	addi	s2,s2,-1658 # 80018f48 <tickslock>
    800025ca:	a821                	j	800025e2 <wakeup+0x40>
        p->state = RUNNABLE;
    800025cc:	0154ac23          	sw	s5,24(s1)
#ifdef PBS
        p->sched_end = ticks;
#endif
      }
      release(&p->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6c6080e7          	jalr	1734(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025da:	1b848493          	addi	s1,s1,440
    800025de:	03248463          	beq	s1,s2,80002606 <wakeup+0x64>
    if (p != myproc())
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	4f4080e7          	jalr	1268(ra) # 80001ad6 <myproc>
    800025ea:	fea488e3          	beq	s1,a0,800025da <wakeup+0x38>
      acquire(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	5f4080e7          	jalr	1524(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800025f8:	4c9c                	lw	a5,24(s1)
    800025fa:	fd379be3          	bne	a5,s3,800025d0 <wakeup+0x2e>
    800025fe:	709c                	ld	a5,32(s1)
    80002600:	fd4798e3          	bne	a5,s4,800025d0 <wakeup+0x2e>
    80002604:	b7e1                	j	800025cc <wakeup+0x2a>
    }
  }
}
    80002606:	70e2                	ld	ra,56(sp)
    80002608:	7442                	ld	s0,48(sp)
    8000260a:	74a2                	ld	s1,40(sp)
    8000260c:	7902                	ld	s2,32(sp)
    8000260e:	69e2                	ld	s3,24(sp)
    80002610:	6a42                	ld	s4,16(sp)
    80002612:	6aa2                	ld	s5,8(sp)
    80002614:	6121                	addi	sp,sp,64
    80002616:	8082                	ret

0000000080002618 <reparent>:
{
    80002618:	7179                	addi	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	e052                	sd	s4,0(sp)
    80002626:	1800                	addi	s0,sp,48
    80002628:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000262a:	00010497          	auipc	s1,0x10
    8000262e:	b1e48493          	addi	s1,s1,-1250 # 80012148 <proc>
      pp->parent = initproc;
    80002632:	00007a17          	auipc	s4,0x7
    80002636:	9f6a0a13          	addi	s4,s4,-1546 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000263a:	00017997          	auipc	s3,0x17
    8000263e:	90e98993          	addi	s3,s3,-1778 # 80018f48 <tickslock>
    80002642:	a029                	j	8000264c <reparent+0x34>
    80002644:	1b848493          	addi	s1,s1,440
    80002648:	01348d63          	beq	s1,s3,80002662 <reparent+0x4a>
    if (pp->parent == p)
    8000264c:	7c9c                	ld	a5,56(s1)
    8000264e:	ff279be3          	bne	a5,s2,80002644 <reparent+0x2c>
      pp->parent = initproc;
    80002652:	000a3503          	ld	a0,0(s4)
    80002656:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002658:	00000097          	auipc	ra,0x0
    8000265c:	f4a080e7          	jalr	-182(ra) # 800025a2 <wakeup>
    80002660:	b7d5                	j	80002644 <reparent+0x2c>
}
    80002662:	70a2                	ld	ra,40(sp)
    80002664:	7402                	ld	s0,32(sp)
    80002666:	64e2                	ld	s1,24(sp)
    80002668:	6942                	ld	s2,16(sp)
    8000266a:	69a2                	ld	s3,8(sp)
    8000266c:	6a02                	ld	s4,0(sp)
    8000266e:	6145                	addi	sp,sp,48
    80002670:	8082                	ret

0000000080002672 <exit>:
{
    80002672:	7179                	addi	sp,sp,-48
    80002674:	f406                	sd	ra,40(sp)
    80002676:	f022                	sd	s0,32(sp)
    80002678:	ec26                	sd	s1,24(sp)
    8000267a:	e84a                	sd	s2,16(sp)
    8000267c:	e44e                	sd	s3,8(sp)
    8000267e:	e052                	sd	s4,0(sp)
    80002680:	1800                	addi	s0,sp,48
    80002682:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	452080e7          	jalr	1106(ra) # 80001ad6 <myproc>
    8000268c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000268e:	00007797          	auipc	a5,0x7
    80002692:	99a7b783          	ld	a5,-1638(a5) # 80009028 <initproc>
    80002696:	0d050493          	addi	s1,a0,208
    8000269a:	15050913          	addi	s2,a0,336
    8000269e:	02a79363          	bne	a5,a0,800026c4 <exit+0x52>
    panic("init exiting");
    800026a2:	00006517          	auipc	a0,0x6
    800026a6:	bbe50513          	addi	a0,a0,-1090 # 80008260 <digits+0x220>
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>
      fileclose(f);
    800026b2:	00002097          	auipc	ra,0x2
    800026b6:	46e080e7          	jalr	1134(ra) # 80004b20 <fileclose>
      p->ofile[fd] = 0;
    800026ba:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800026be:	04a1                	addi	s1,s1,8
    800026c0:	01248563          	beq	s1,s2,800026ca <exit+0x58>
    if (p->ofile[fd])
    800026c4:	6088                	ld	a0,0(s1)
    800026c6:	f575                	bnez	a0,800026b2 <exit+0x40>
    800026c8:	bfdd                	j	800026be <exit+0x4c>
  begin_op();
    800026ca:	00002097          	auipc	ra,0x2
    800026ce:	f8a080e7          	jalr	-118(ra) # 80004654 <begin_op>
  iput(p->cwd);
    800026d2:	1509b503          	ld	a0,336(s3)
    800026d6:	00001097          	auipc	ra,0x1
    800026da:	766080e7          	jalr	1894(ra) # 80003e3c <iput>
  end_op();
    800026de:	00002097          	auipc	ra,0x2
    800026e2:	ff6080e7          	jalr	-10(ra) # 800046d4 <end_op>
  p->cwd = 0;
    800026e6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026ea:	0000f497          	auipc	s1,0xf
    800026ee:	bce48493          	addi	s1,s1,-1074 # 800112b8 <wait_lock>
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>
  reparent(p);
    800026fc:	854e                	mv	a0,s3
    800026fe:	00000097          	auipc	ra,0x0
    80002702:	f1a080e7          	jalr	-230(ra) # 80002618 <reparent>
  wakeup(p->parent);
    80002706:	0389b503          	ld	a0,56(s3)
    8000270a:	00000097          	auipc	ra,0x0
    8000270e:	e98080e7          	jalr	-360(ra) # 800025a2 <wakeup>
  acquire(&p->lock);
    80002712:	854e                	mv	a0,s3
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	4d0080e7          	jalr	1232(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000271c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002720:	4795                	li	a5,5
    80002722:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002726:	00007797          	auipc	a5,0x7
    8000272a:	90a7a783          	lw	a5,-1782(a5) # 80009030 <ticks>
    8000272e:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	564080e7          	jalr	1380(ra) # 80000c98 <release>
  sched();
    8000273c:	00000097          	auipc	ra,0x0
    80002740:	a7c080e7          	jalr	-1412(ra) # 800021b8 <sched>
  panic("zombie exit");
    80002744:	00006517          	auipc	a0,0x6
    80002748:	b2c50513          	addi	a0,a0,-1236 # 80008270 <digits+0x230>
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>

0000000080002754 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002754:	7179                	addi	sp,sp,-48
    80002756:	f406                	sd	ra,40(sp)
    80002758:	f022                	sd	s0,32(sp)
    8000275a:	ec26                	sd	s1,24(sp)
    8000275c:	e84a                	sd	s2,16(sp)
    8000275e:	e44e                	sd	s3,8(sp)
    80002760:	1800                	addi	s0,sp,48
    80002762:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002764:	00010497          	auipc	s1,0x10
    80002768:	9e448493          	addi	s1,s1,-1564 # 80012148 <proc>
    8000276c:	00016997          	auipc	s3,0x16
    80002770:	7dc98993          	addi	s3,s3,2012 # 80018f48 <tickslock>
  {
    acquire(&p->lock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	46e080e7          	jalr	1134(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000277e:	589c                	lw	a5,48(s1)
    80002780:	01278d63          	beq	a5,s2,8000279a <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000278e:	1b848493          	addi	s1,s1,440
    80002792:	ff3491e3          	bne	s1,s3,80002774 <kill+0x20>
  }
  return -1;
    80002796:	557d                	li	a0,-1
    80002798:	a829                	j	800027b2 <kill+0x5e>
      p->killed = 1;
    8000279a:	4785                	li	a5,1
    8000279c:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000279e:	4c98                	lw	a4,24(s1)
    800027a0:	4789                	li	a5,2
    800027a2:	00f70f63          	beq	a4,a5,800027c0 <kill+0x6c>
      release(&p->lock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	4f0080e7          	jalr	1264(ra) # 80000c98 <release>
      return 0;
    800027b0:	4501                	li	a0,0
}
    800027b2:	70a2                	ld	ra,40(sp)
    800027b4:	7402                	ld	s0,32(sp)
    800027b6:	64e2                	ld	s1,24(sp)
    800027b8:	6942                	ld	s2,16(sp)
    800027ba:	69a2                	ld	s3,8(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret
        p->state = RUNNABLE;
    800027c0:	478d                	li	a5,3
    800027c2:	cc9c                	sw	a5,24(s1)
    800027c4:	b7cd                	j	800027a6 <kill+0x52>

00000000800027c6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027c6:	7179                	addi	sp,sp,-48
    800027c8:	f406                	sd	ra,40(sp)
    800027ca:	f022                	sd	s0,32(sp)
    800027cc:	ec26                	sd	s1,24(sp)
    800027ce:	e84a                	sd	s2,16(sp)
    800027d0:	e44e                	sd	s3,8(sp)
    800027d2:	e052                	sd	s4,0(sp)
    800027d4:	1800                	addi	s0,sp,48
    800027d6:	84aa                	mv	s1,a0
    800027d8:	892e                	mv	s2,a1
    800027da:	89b2                	mv	s3,a2
    800027dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	2f8080e7          	jalr	760(ra) # 80001ad6 <myproc>
  if (user_dst)
    800027e6:	c08d                	beqz	s1,80002808 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027e8:	86d2                	mv	a3,s4
    800027ea:	864e                	mv	a2,s3
    800027ec:	85ca                	mv	a1,s2
    800027ee:	6928                	ld	a0,80(a0)
    800027f0:	fffff097          	auipc	ra,0xfffff
    800027f4:	e8a080e7          	jalr	-374(ra) # 8000167a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027f8:	70a2                	ld	ra,40(sp)
    800027fa:	7402                	ld	s0,32(sp)
    800027fc:	64e2                	ld	s1,24(sp)
    800027fe:	6942                	ld	s2,16(sp)
    80002800:	69a2                	ld	s3,8(sp)
    80002802:	6a02                	ld	s4,0(sp)
    80002804:	6145                	addi	sp,sp,48
    80002806:	8082                	ret
    memmove((char *)dst, src, len);
    80002808:	000a061b          	sext.w	a2,s4
    8000280c:	85ce                	mv	a1,s3
    8000280e:	854a                	mv	a0,s2
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	530080e7          	jalr	1328(ra) # 80000d40 <memmove>
    return 0;
    80002818:	8526                	mv	a0,s1
    8000281a:	bff9                	j	800027f8 <either_copyout+0x32>

000000008000281c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	addi	s0,sp,48
    8000282c:	892a                	mv	s2,a0
    8000282e:	84ae                	mv	s1,a1
    80002830:	89b2                	mv	s3,a2
    80002832:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	2a2080e7          	jalr	674(ra) # 80001ad6 <myproc>
  if (user_src)
    8000283c:	c08d                	beqz	s1,8000285e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000283e:	86d2                	mv	a3,s4
    80002840:	864e                	mv	a2,s3
    80002842:	85ca                	mv	a1,s2
    80002844:	6928                	ld	a0,80(a0)
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	ec0080e7          	jalr	-320(ra) # 80001706 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6a02                	ld	s4,0(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000285e:	000a061b          	sext.w	a2,s4
    80002862:	85ce                	mv	a1,s3
    80002864:	854a                	mv	a0,s2
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	4da080e7          	jalr	1242(ra) # 80000d40 <memmove>
    return 0;
    8000286e:	8526                	mv	a0,s1
    80002870:	bff9                	j	8000284e <either_copyin+0x32>

0000000080002872 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002872:	715d                	addi	sp,sp,-80
    80002874:	e486                	sd	ra,72(sp)
    80002876:	e0a2                	sd	s0,64(sp)
    80002878:	fc26                	sd	s1,56(sp)
    8000287a:	f84a                	sd	s2,48(sp)
    8000287c:	f44e                	sd	s3,40(sp)
    8000287e:	f052                	sd	s4,32(sp)
    80002880:	ec56                	sd	s5,24(sp)
    80002882:	e85a                	sd	s6,16(sp)
    80002884:	e45e                	sd	s7,8(sp)
    80002886:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	b9850513          	addi	a0,a0,-1128 # 80008420 <states.1811+0x160>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cf8080e7          	jalr	-776(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002898:	00010497          	auipc	s1,0x10
    8000289c:	a0848493          	addi	s1,s1,-1528 # 800122a0 <proc+0x158>
    800028a0:	00017917          	auipc	s2,0x17
    800028a4:	80090913          	addi	s2,s2,-2048 # 800190a0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028aa:	00006997          	auipc	s3,0x6
    800028ae:	9d698993          	addi	s3,s3,-1578 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800028b2:	00006a97          	auipc	s5,0x6
    800028b6:	9d6a8a93          	addi	s5,s5,-1578 # 80008288 <digits+0x248>
    printf("\n");
    800028ba:	00006a17          	auipc	s4,0x6
    800028be:	b66a0a13          	addi	s4,s4,-1178 # 80008420 <states.1811+0x160>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c2:	00006b97          	auipc	s7,0x6
    800028c6:	9feb8b93          	addi	s7,s7,-1538 # 800082c0 <states.1811>
    800028ca:	a00d                	j	800028ec <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028cc:	ed86a583          	lw	a1,-296(a3)
    800028d0:	8556                	mv	a0,s5
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	cb6080e7          	jalr	-842(ra) # 80000588 <printf>
    printf("\n");
    800028da:	8552                	mv	a0,s4
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	cac080e7          	jalr	-852(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028e4:	1b848493          	addi	s1,s1,440
    800028e8:	03248163          	beq	s1,s2,8000290a <procdump+0x98>
    if (p->state == UNUSED)
    800028ec:	86a6                	mv	a3,s1
    800028ee:	ec04a783          	lw	a5,-320(s1)
    800028f2:	dbed                	beqz	a5,800028e4 <procdump+0x72>
      state = "???";
    800028f4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f6:	fcfb6be3          	bltu	s6,a5,800028cc <procdump+0x5a>
    800028fa:	1782                	slli	a5,a5,0x20
    800028fc:	9381                	srli	a5,a5,0x20
    800028fe:	078e                	slli	a5,a5,0x3
    80002900:	97de                	add	a5,a5,s7
    80002902:	6390                	ld	a2,0(a5)
    80002904:	f661                	bnez	a2,800028cc <procdump+0x5a>
      state = "???";
    80002906:	864e                	mv	a2,s3
    80002908:	b7d1                	j	800028cc <procdump+0x5a>
  }
}
    8000290a:	60a6                	ld	ra,72(sp)
    8000290c:	6406                	ld	s0,64(sp)
    8000290e:	74e2                	ld	s1,56(sp)
    80002910:	7942                	ld	s2,48(sp)
    80002912:	79a2                	ld	s3,40(sp)
    80002914:	7a02                	ld	s4,32(sp)
    80002916:	6ae2                	ld	s5,24(sp)
    80002918:	6b42                	ld	s6,16(sp)
    8000291a:	6ba2                	ld	s7,8(sp)
    8000291c:	6161                	addi	sp,sp,80
    8000291e:	8082                	ret

0000000080002920 <trace>:

// enabling tracing for the current process
void trace(int trace_mask)
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	1000                	addi	s0,sp,32
    8000292a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	1aa080e7          	jalr	426(ra) # 80001ad6 <myproc>
  p->trace_mask = trace_mask;
    80002934:	16952423          	sw	s1,360(a0)
}
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6105                	addi	sp,sp,32
    80002940:	8082                	ret

0000000080002942 <set_priority>:

// Change the priority of the given process with pid to new_priority
int set_priority(int new_priority, int pid)
{
    80002942:	7179                	addi	sp,sp,-48
    80002944:	f406                	sd	ra,40(sp)
    80002946:	f022                	sd	s0,32(sp)
    80002948:	ec26                	sd	s1,24(sp)
    8000294a:	e84a                	sd	s2,16(sp)
    8000294c:	e44e                	sd	s3,8(sp)
    8000294e:	e052                	sd	s4,0(sp)
    80002950:	1800                	addi	s0,sp,48
    80002952:	8a2a                	mv	s4,a0
    80002954:	892e                	mv	s2,a1
  struct proc *p;
  int old_priority = 0;
  for (p = proc; p < &proc[NPROC]; p++)
    80002956:	0000f497          	auipc	s1,0xf
    8000295a:	7f248493          	addi	s1,s1,2034 # 80012148 <proc>
    8000295e:	00016997          	auipc	s3,0x16
    80002962:	5ea98993          	addi	s3,s3,1514 # 80018f48 <tickslock>
  {
    acquire(&p->lock);
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002970:	589c                	lw	a5,48(s1)
    80002972:	03278163          	beq	a5,s2,80002994 <set_priority+0x52>
      p->new_proc = 1;
      release(&p->lock);
      yield();
      return old_priority;
    }
    release(&p->lock);
    80002976:	8526                	mv	a0,s1
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	320080e7          	jalr	800(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002980:	1b848493          	addi	s1,s1,440
    80002984:	ff3491e3          	bne	s1,s3,80002966 <set_priority+0x24>
  }
  yield();
    80002988:	00000097          	auipc	ra,0x0
    8000298c:	906080e7          	jalr	-1786(ra) # 8000228e <yield>
  return old_priority;
    80002990:	4901                	li	s2,0
    80002992:	a00d                	j	800029b4 <set_priority+0x72>
      old_priority = p->static_priority;
    80002994:	1784a903          	lw	s2,376(s1)
      p->static_priority = new_priority;
    80002998:	1744ac23          	sw	s4,376(s1)
      p->new_proc = 1;
    8000299c:	4785                	li	a5,1
    8000299e:	18f4a623          	sw	a5,396(s1)
      release(&p->lock);
    800029a2:	8526                	mv	a0,s1
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	2f4080e7          	jalr	756(ra) # 80000c98 <release>
      yield();
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	8e2080e7          	jalr	-1822(ra) # 8000228e <yield>
}
    800029b4:	854a                	mv	a0,s2
    800029b6:	70a2                	ld	ra,40(sp)
    800029b8:	7402                	ld	s0,32(sp)
    800029ba:	64e2                	ld	s1,24(sp)
    800029bc:	6942                	ld	s2,16(sp)
    800029be:	69a2                	ld	s3,8(sp)
    800029c0:	6a02                	ld	s4,0(sp)
    800029c2:	6145                	addi	sp,sp,48
    800029c4:	8082                	ret

00000000800029c6 <swtch>:
    800029c6:	00153023          	sd	ra,0(a0)
    800029ca:	00253423          	sd	sp,8(a0)
    800029ce:	e900                	sd	s0,16(a0)
    800029d0:	ed04                	sd	s1,24(a0)
    800029d2:	03253023          	sd	s2,32(a0)
    800029d6:	03353423          	sd	s3,40(a0)
    800029da:	03453823          	sd	s4,48(a0)
    800029de:	03553c23          	sd	s5,56(a0)
    800029e2:	05653023          	sd	s6,64(a0)
    800029e6:	05753423          	sd	s7,72(a0)
    800029ea:	05853823          	sd	s8,80(a0)
    800029ee:	05953c23          	sd	s9,88(a0)
    800029f2:	07a53023          	sd	s10,96(a0)
    800029f6:	07b53423          	sd	s11,104(a0)
    800029fa:	0005b083          	ld	ra,0(a1)
    800029fe:	0085b103          	ld	sp,8(a1)
    80002a02:	6980                	ld	s0,16(a1)
    80002a04:	6d84                	ld	s1,24(a1)
    80002a06:	0205b903          	ld	s2,32(a1)
    80002a0a:	0285b983          	ld	s3,40(a1)
    80002a0e:	0305ba03          	ld	s4,48(a1)
    80002a12:	0385ba83          	ld	s5,56(a1)
    80002a16:	0405bb03          	ld	s6,64(a1)
    80002a1a:	0485bb83          	ld	s7,72(a1)
    80002a1e:	0505bc03          	ld	s8,80(a1)
    80002a22:	0585bc83          	ld	s9,88(a1)
    80002a26:	0605bd03          	ld	s10,96(a1)
    80002a2a:	0685bd83          	ld	s11,104(a1)
    80002a2e:	8082                	ret

0000000080002a30 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a30:	1141                	addi	sp,sp,-16
    80002a32:	e406                	sd	ra,8(sp)
    80002a34:	e022                	sd	s0,0(sp)
    80002a36:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a38:	00006597          	auipc	a1,0x6
    80002a3c:	8b858593          	addi	a1,a1,-1864 # 800082f0 <states.1811+0x30>
    80002a40:	00016517          	auipc	a0,0x16
    80002a44:	50850513          	addi	a0,a0,1288 # 80018f48 <tickslock>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	10c080e7          	jalr	268(ra) # 80000b54 <initlock>
}
    80002a50:	60a2                	ld	ra,8(sp)
    80002a52:	6402                	ld	s0,0(sp)
    80002a54:	0141                	addi	sp,sp,16
    80002a56:	8082                	ret

0000000080002a58 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a58:	1141                	addi	sp,sp,-16
    80002a5a:	e422                	sd	s0,8(sp)
    80002a5c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a5e:	00003797          	auipc	a5,0x3
    80002a62:	6e278793          	addi	a5,a5,1762 # 80006140 <kernelvec>
    80002a66:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a6a:	6422                	ld	s0,8(sp)
    80002a6c:	0141                	addi	sp,sp,16
    80002a6e:	8082                	ret

0000000080002a70 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a70:	1141                	addi	sp,sp,-16
    80002a72:	e406                	sd	ra,8(sp)
    80002a74:	e022                	sd	s0,0(sp)
    80002a76:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	05e080e7          	jalr	94(ra) # 80001ad6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a84:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a86:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a8a:	00004617          	auipc	a2,0x4
    80002a8e:	57660613          	addi	a2,a2,1398 # 80007000 <_trampoline>
    80002a92:	00004697          	auipc	a3,0x4
    80002a96:	56e68693          	addi	a3,a3,1390 # 80007000 <_trampoline>
    80002a9a:	8e91                	sub	a3,a3,a2
    80002a9c:	040007b7          	lui	a5,0x4000
    80002aa0:	17fd                	addi	a5,a5,-1
    80002aa2:	07b2                	slli	a5,a5,0xc
    80002aa4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aa6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002aaa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002aac:	180026f3          	csrr	a3,satp
    80002ab0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ab2:	6d38                	ld	a4,88(a0)
    80002ab4:	6134                	ld	a3,64(a0)
    80002ab6:	6585                	lui	a1,0x1
    80002ab8:	96ae                	add	a3,a3,a1
    80002aba:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002abc:	6d38                	ld	a4,88(a0)
    80002abe:	00000697          	auipc	a3,0x0
    80002ac2:	14668693          	addi	a3,a3,326 # 80002c04 <usertrap>
    80002ac6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ac8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002aca:	8692                	mv	a3,tp
    80002acc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ace:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ad2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ad6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ada:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ade:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae0:	6f18                	ld	a4,24(a4)
    80002ae2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ae6:	692c                	ld	a1,80(a0)
    80002ae8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002aea:	00004717          	auipc	a4,0x4
    80002aee:	5a670713          	addi	a4,a4,1446 # 80007090 <userret>
    80002af2:	8f11                	sub	a4,a4,a2
    80002af4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002af6:	577d                	li	a4,-1
    80002af8:	177e                	slli	a4,a4,0x3f
    80002afa:	8dd9                	or	a1,a1,a4
    80002afc:	02000537          	lui	a0,0x2000
    80002b00:	157d                	addi	a0,a0,-1
    80002b02:	0536                	slli	a0,a0,0xd
    80002b04:	9782                	jalr	a5
}
    80002b06:	60a2                	ld	ra,8(sp)
    80002b08:	6402                	ld	s0,0(sp)
    80002b0a:	0141                	addi	sp,sp,16
    80002b0c:	8082                	ret

0000000080002b0e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	e426                	sd	s1,8(sp)
    80002b16:	e04a                	sd	s2,0(sp)
    80002b18:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b1a:	00016917          	auipc	s2,0x16
    80002b1e:	42e90913          	addi	s2,s2,1070 # 80018f48 <tickslock>
    80002b22:	854a                	mv	a0,s2
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	0c0080e7          	jalr	192(ra) # 80000be4 <acquire>
  ticks++;
    80002b2c:	00006497          	auipc	s1,0x6
    80002b30:	50448493          	addi	s1,s1,1284 # 80009030 <ticks>
    80002b34:	409c                	lw	a5,0(s1)
    80002b36:	2785                	addiw	a5,a5,1
    80002b38:	c09c                	sw	a5,0(s1)
  update_time();
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	4d6080e7          	jalr	1238(ra) # 80002010 <update_time>
  wakeup(&ticks);
    80002b42:	8526                	mv	a0,s1
    80002b44:	00000097          	auipc	ra,0x0
    80002b48:	a5e080e7          	jalr	-1442(ra) # 800025a2 <wakeup>
  release(&tickslock);
    80002b4c:	854a                	mv	a0,s2
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	14a080e7          	jalr	330(ra) # 80000c98 <release>
}
    80002b56:	60e2                	ld	ra,24(sp)
    80002b58:	6442                	ld	s0,16(sp)
    80002b5a:	64a2                	ld	s1,8(sp)
    80002b5c:	6902                	ld	s2,0(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b70:	00074d63          	bltz	a4,80002b8a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b74:	57fd                	li	a5,-1
    80002b76:	17fe                	slli	a5,a5,0x3f
    80002b78:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b7a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b7c:	06f70363          	beq	a4,a5,80002be2 <devintr+0x80>
  }
}
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	64a2                	ld	s1,8(sp)
    80002b86:	6105                	addi	sp,sp,32
    80002b88:	8082                	ret
     (scause & 0xff) == 9){
    80002b8a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b8e:	46a5                	li	a3,9
    80002b90:	fed792e3          	bne	a5,a3,80002b74 <devintr+0x12>
    int irq = plic_claim();
    80002b94:	00003097          	auipc	ra,0x3
    80002b98:	6b4080e7          	jalr	1716(ra) # 80006248 <plic_claim>
    80002b9c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b9e:	47a9                	li	a5,10
    80002ba0:	02f50763          	beq	a0,a5,80002bce <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ba4:	4785                	li	a5,1
    80002ba6:	02f50963          	beq	a0,a5,80002bd8 <devintr+0x76>
    return 1;
    80002baa:	4505                	li	a0,1
    } else if(irq){
    80002bac:	d8f1                	beqz	s1,80002b80 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bae:	85a6                	mv	a1,s1
    80002bb0:	00005517          	auipc	a0,0x5
    80002bb4:	74850513          	addi	a0,a0,1864 # 800082f8 <states.1811+0x38>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9d0080e7          	jalr	-1584(ra) # 80000588 <printf>
      plic_complete(irq);
    80002bc0:	8526                	mv	a0,s1
    80002bc2:	00003097          	auipc	ra,0x3
    80002bc6:	6aa080e7          	jalr	1706(ra) # 8000626c <plic_complete>
    return 1;
    80002bca:	4505                	li	a0,1
    80002bcc:	bf55                	j	80002b80 <devintr+0x1e>
      uartintr();
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	dda080e7          	jalr	-550(ra) # 800009a8 <uartintr>
    80002bd6:	b7ed                	j	80002bc0 <devintr+0x5e>
      virtio_disk_intr();
    80002bd8:	00004097          	auipc	ra,0x4
    80002bdc:	b74080e7          	jalr	-1164(ra) # 8000674c <virtio_disk_intr>
    80002be0:	b7c5                	j	80002bc0 <devintr+0x5e>
    if(cpuid() == 0){
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	ec8080e7          	jalr	-312(ra) # 80001aaa <cpuid>
    80002bea:	c901                	beqz	a0,80002bfa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bec:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bf2:	14479073          	csrw	sip,a5
    return 2;
    80002bf6:	4509                	li	a0,2
    80002bf8:	b761                	j	80002b80 <devintr+0x1e>
      clockintr();
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	f14080e7          	jalr	-236(ra) # 80002b0e <clockintr>
    80002c02:	b7ed                	j	80002bec <devintr+0x8a>

0000000080002c04 <usertrap>:
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	e04a                	sd	s2,0(sp)
    80002c0e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c10:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c14:	1007f793          	andi	a5,a5,256
    80002c18:	e3ad                	bnez	a5,80002c7a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c1a:	00003797          	auipc	a5,0x3
    80002c1e:	52678793          	addi	a5,a5,1318 # 80006140 <kernelvec>
    80002c22:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	eb0080e7          	jalr	-336(ra) # 80001ad6 <myproc>
    80002c2e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c30:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c32:	14102773          	csrr	a4,sepc
    80002c36:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c38:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c3c:	47a1                	li	a5,8
    80002c3e:	04f71c63          	bne	a4,a5,80002c96 <usertrap+0x92>
    if(p->killed)
    80002c42:	551c                	lw	a5,40(a0)
    80002c44:	e3b9                	bnez	a5,80002c8a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c46:	6cb8                	ld	a4,88(s1)
    80002c48:	6f1c                	ld	a5,24(a4)
    80002c4a:	0791                	addi	a5,a5,4
    80002c4c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c52:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c56:	10079073          	csrw	sstatus,a5
    syscall();
    80002c5a:	00000097          	auipc	ra,0x0
    80002c5e:	2e0080e7          	jalr	736(ra) # 80002f3a <syscall>
  if(p->killed)
    80002c62:	549c                	lw	a5,40(s1)
    80002c64:	ebc1                	bnez	a5,80002cf4 <usertrap+0xf0>
  usertrapret();
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	e0a080e7          	jalr	-502(ra) # 80002a70 <usertrapret>
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6902                	ld	s2,0(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret
    panic("usertrap: not from user mode");
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	69e50513          	addi	a0,a0,1694 # 80008318 <states.1811+0x58>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>
      exit(-1);
    80002c8a:	557d                	li	a0,-1
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	9e6080e7          	jalr	-1562(ra) # 80002672 <exit>
    80002c94:	bf4d                	j	80002c46 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	ecc080e7          	jalr	-308(ra) # 80002b62 <devintr>
    80002c9e:	892a                	mv	s2,a0
    80002ca0:	c501                	beqz	a0,80002ca8 <usertrap+0xa4>
  if(p->killed)
    80002ca2:	549c                	lw	a5,40(s1)
    80002ca4:	c3a1                	beqz	a5,80002ce4 <usertrap+0xe0>
    80002ca6:	a815                	j	80002cda <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cac:	5890                	lw	a2,48(s1)
    80002cae:	00005517          	auipc	a0,0x5
    80002cb2:	68a50513          	addi	a0,a0,1674 # 80008338 <states.1811+0x78>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	8d2080e7          	jalr	-1838(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cbe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cc2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	6a250513          	addi	a0,a0,1698 # 80008368 <states.1811+0xa8>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8ba080e7          	jalr	-1862(ra) # 80000588 <printf>
    p->killed = 1;
    80002cd6:	4785                	li	a5,1
    80002cd8:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002cda:	557d                	li	a0,-1
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	996080e7          	jalr	-1642(ra) # 80002672 <exit>
  if(which_dev == 2)
    80002ce4:	4789                	li	a5,2
    80002ce6:	f8f910e3          	bne	s2,a5,80002c66 <usertrap+0x62>
    yield();
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	5a4080e7          	jalr	1444(ra) # 8000228e <yield>
    80002cf2:	bf95                	j	80002c66 <usertrap+0x62>
  int which_dev = 0;
    80002cf4:	4901                	li	s2,0
    80002cf6:	b7d5                	j	80002cda <usertrap+0xd6>

0000000080002cf8 <kerneltrap>:
{
    80002cf8:	7179                	addi	sp,sp,-48
    80002cfa:	f406                	sd	ra,40(sp)
    80002cfc:	f022                	sd	s0,32(sp)
    80002cfe:	ec26                	sd	s1,24(sp)
    80002d00:	e84a                	sd	s2,16(sp)
    80002d02:	e44e                	sd	s3,8(sp)
    80002d04:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d06:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d0e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d12:	1004f793          	andi	a5,s1,256
    80002d16:	cb85                	beqz	a5,80002d46 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d18:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d1c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d1e:	ef85                	bnez	a5,80002d56 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	e42080e7          	jalr	-446(ra) # 80002b62 <devintr>
    80002d28:	cd1d                	beqz	a0,80002d66 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d2a:	4789                	li	a5,2
    80002d2c:	06f50a63          	beq	a0,a5,80002da0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d30:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d34:	10049073          	csrw	sstatus,s1
}
    80002d38:	70a2                	ld	ra,40(sp)
    80002d3a:	7402                	ld	s0,32(sp)
    80002d3c:	64e2                	ld	s1,24(sp)
    80002d3e:	6942                	ld	s2,16(sp)
    80002d40:	69a2                	ld	s3,8(sp)
    80002d42:	6145                	addi	sp,sp,48
    80002d44:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	64250513          	addi	a0,a0,1602 # 80008388 <states.1811+0xc8>
    80002d4e:	ffffd097          	auipc	ra,0xffffd
    80002d52:	7f0080e7          	jalr	2032(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	65a50513          	addi	a0,a0,1626 # 800083b0 <states.1811+0xf0>
    80002d5e:	ffffd097          	auipc	ra,0xffffd
    80002d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002d66:	85ce                	mv	a1,s3
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	66850513          	addi	a0,a0,1640 # 800083d0 <states.1811+0x110>
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	818080e7          	jalr	-2024(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d78:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d7c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	66050513          	addi	a0,a0,1632 # 800083e0 <states.1811+0x120>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	800080e7          	jalr	-2048(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	66850513          	addi	a0,a0,1640 # 800083f8 <states.1811+0x138>
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	7a6080e7          	jalr	1958(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	d36080e7          	jalr	-714(ra) # 80001ad6 <myproc>
    80002da8:	d541                	beqz	a0,80002d30 <kerneltrap+0x38>
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	d2c080e7          	jalr	-724(ra) # 80001ad6 <myproc>
    80002db2:	4d18                	lw	a4,24(a0)
    80002db4:	4791                	li	a5,4
    80002db6:	f6f71de3          	bne	a4,a5,80002d30 <kerneltrap+0x38>
    yield();
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	4d4080e7          	jalr	1236(ra) # 8000228e <yield>
    80002dc2:	b7bd                	j	80002d30 <kerneltrap+0x38>

0000000080002dc4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	e426                	sd	s1,8(sp)
    80002dcc:	1000                	addi	s0,sp,32
    80002dce:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	d06080e7          	jalr	-762(ra) # 80001ad6 <myproc>
  switch (n) {
    80002dd8:	4795                	li	a5,5
    80002dda:	0497e163          	bltu	a5,s1,80002e1c <argraw+0x58>
    80002dde:	048a                	slli	s1,s1,0x2
    80002de0:	00005717          	auipc	a4,0x5
    80002de4:	74070713          	addi	a4,a4,1856 # 80008520 <states.1811+0x260>
    80002de8:	94ba                	add	s1,s1,a4
    80002dea:	409c                	lw	a5,0(s1)
    80002dec:	97ba                	add	a5,a5,a4
    80002dee:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002df0:	6d3c                	ld	a5,88(a0)
    80002df2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002df4:	60e2                	ld	ra,24(sp)
    80002df6:	6442                	ld	s0,16(sp)
    80002df8:	64a2                	ld	s1,8(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret
    return p->trapframe->a1;
    80002dfe:	6d3c                	ld	a5,88(a0)
    80002e00:	7fa8                	ld	a0,120(a5)
    80002e02:	bfcd                	j	80002df4 <argraw+0x30>
    return p->trapframe->a2;
    80002e04:	6d3c                	ld	a5,88(a0)
    80002e06:	63c8                	ld	a0,128(a5)
    80002e08:	b7f5                	j	80002df4 <argraw+0x30>
    return p->trapframe->a3;
    80002e0a:	6d3c                	ld	a5,88(a0)
    80002e0c:	67c8                	ld	a0,136(a5)
    80002e0e:	b7dd                	j	80002df4 <argraw+0x30>
    return p->trapframe->a4;
    80002e10:	6d3c                	ld	a5,88(a0)
    80002e12:	6bc8                	ld	a0,144(a5)
    80002e14:	b7c5                	j	80002df4 <argraw+0x30>
    return p->trapframe->a5;
    80002e16:	6d3c                	ld	a5,88(a0)
    80002e18:	6fc8                	ld	a0,152(a5)
    80002e1a:	bfe9                	j	80002df4 <argraw+0x30>
  panic("argraw");
    80002e1c:	00005517          	auipc	a0,0x5
    80002e20:	5ec50513          	addi	a0,a0,1516 # 80008408 <states.1811+0x148>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	71a080e7          	jalr	1818(ra) # 8000053e <panic>

0000000080002e2c <fetchaddr>:
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	e426                	sd	s1,8(sp)
    80002e34:	e04a                	sd	s2,0(sp)
    80002e36:	1000                	addi	s0,sp,32
    80002e38:	84aa                	mv	s1,a0
    80002e3a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	c9a080e7          	jalr	-870(ra) # 80001ad6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e44:	653c                	ld	a5,72(a0)
    80002e46:	02f4f863          	bgeu	s1,a5,80002e76 <fetchaddr+0x4a>
    80002e4a:	00848713          	addi	a4,s1,8
    80002e4e:	02e7e663          	bltu	a5,a4,80002e7a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e52:	46a1                	li	a3,8
    80002e54:	8626                	mv	a2,s1
    80002e56:	85ca                	mv	a1,s2
    80002e58:	6928                	ld	a0,80(a0)
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	8ac080e7          	jalr	-1876(ra) # 80001706 <copyin>
    80002e62:	00a03533          	snez	a0,a0
    80002e66:	40a00533          	neg	a0,a0
}
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	64a2                	ld	s1,8(sp)
    80002e70:	6902                	ld	s2,0(sp)
    80002e72:	6105                	addi	sp,sp,32
    80002e74:	8082                	ret
    return -1;
    80002e76:	557d                	li	a0,-1
    80002e78:	bfcd                	j	80002e6a <fetchaddr+0x3e>
    80002e7a:	557d                	li	a0,-1
    80002e7c:	b7fd                	j	80002e6a <fetchaddr+0x3e>

0000000080002e7e <fetchstr>:
{
    80002e7e:	7179                	addi	sp,sp,-48
    80002e80:	f406                	sd	ra,40(sp)
    80002e82:	f022                	sd	s0,32(sp)
    80002e84:	ec26                	sd	s1,24(sp)
    80002e86:	e84a                	sd	s2,16(sp)
    80002e88:	e44e                	sd	s3,8(sp)
    80002e8a:	1800                	addi	s0,sp,48
    80002e8c:	892a                	mv	s2,a0
    80002e8e:	84ae                	mv	s1,a1
    80002e90:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	c44080e7          	jalr	-956(ra) # 80001ad6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e9a:	86ce                	mv	a3,s3
    80002e9c:	864a                	mv	a2,s2
    80002e9e:	85a6                	mv	a1,s1
    80002ea0:	6928                	ld	a0,80(a0)
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	8f0080e7          	jalr	-1808(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002eaa:	00054763          	bltz	a0,80002eb8 <fetchstr+0x3a>
  return strlen(buf);
    80002eae:	8526                	mv	a0,s1
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	fb4080e7          	jalr	-76(ra) # 80000e64 <strlen>
}
    80002eb8:	70a2                	ld	ra,40(sp)
    80002eba:	7402                	ld	s0,32(sp)
    80002ebc:	64e2                	ld	s1,24(sp)
    80002ebe:	6942                	ld	s2,16(sp)
    80002ec0:	69a2                	ld	s3,8(sp)
    80002ec2:	6145                	addi	sp,sp,48
    80002ec4:	8082                	ret

0000000080002ec6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ec6:	1101                	addi	sp,sp,-32
    80002ec8:	ec06                	sd	ra,24(sp)
    80002eca:	e822                	sd	s0,16(sp)
    80002ecc:	e426                	sd	s1,8(sp)
    80002ece:	1000                	addi	s0,sp,32
    80002ed0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	ef2080e7          	jalr	-270(ra) # 80002dc4 <argraw>
    80002eda:	c088                	sw	a0,0(s1)
  return 0;
}
    80002edc:	4501                	li	a0,0
    80002ede:	60e2                	ld	ra,24(sp)
    80002ee0:	6442                	ld	s0,16(sp)
    80002ee2:	64a2                	ld	s1,8(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret

0000000080002ee8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ee8:	1101                	addi	sp,sp,-32
    80002eea:	ec06                	sd	ra,24(sp)
    80002eec:	e822                	sd	s0,16(sp)
    80002eee:	e426                	sd	s1,8(sp)
    80002ef0:	1000                	addi	s0,sp,32
    80002ef2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	ed0080e7          	jalr	-304(ra) # 80002dc4 <argraw>
    80002efc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002efe:	4501                	li	a0,0
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret

0000000080002f0a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	e426                	sd	s1,8(sp)
    80002f12:	e04a                	sd	s2,0(sp)
    80002f14:	1000                	addi	s0,sp,32
    80002f16:	84ae                	mv	s1,a1
    80002f18:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	eaa080e7          	jalr	-342(ra) # 80002dc4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f22:	864a                	mv	a2,s2
    80002f24:	85a6                	mv	a1,s1
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	f58080e7          	jalr	-168(ra) # 80002e7e <fetchstr>
}
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	64a2                	ld	s1,8(sp)
    80002f34:	6902                	ld	s2,0(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <syscall>:
struct syscall_arg_info syscall_arg_infos[] = {{ 0, "fork" },{ 1, "exit" },{ 1, "wait" },{ 0, "pipe" },{ 3, "read" },{ 2, "kill" },{ 2, "exec" },{ 1, "fstat" },{ 1, "chdir" },{ 1, "dup" },{ 0, "getpid" },{ 1, "sbrk" },{ 1, "sleep" },{ 0, "uptime" },{ 2, "open" },{ 3, "write" },{ 3, "mknod" },{ 1, "unlink" },{ 2, "link" },{ 1, "mkdir" },{ 1, "close" },{ 1, "trace" },{ 3, "waitx" }, {2, "set_priority"},};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002f3a:	711d                	addi	sp,sp,-96
    80002f3c:	ec86                	sd	ra,88(sp)
    80002f3e:	e8a2                	sd	s0,80(sp)
    80002f40:	e4a6                	sd	s1,72(sp)
    80002f42:	e0ca                	sd	s2,64(sp)
    80002f44:	fc4e                	sd	s3,56(sp)
    80002f46:	f852                	sd	s4,48(sp)
    80002f48:	f456                	sd	s5,40(sp)
    80002f4a:	f05a                	sd	s6,32(sp)
    80002f4c:	ec5e                	sd	s7,24(sp)
    80002f4e:	e862                	sd	s8,16(sp)
    80002f50:	e466                	sd	s9,8(sp)
    80002f52:	e06a                	sd	s10,0(sp)
    80002f54:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	b80080e7          	jalr	-1152(ra) # 80001ad6 <myproc>
    80002f5e:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002f60:	6d24                	ld	s1,88(a0)
    80002f62:	74dc                	ld	a5,168(s1)
    80002f64:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f68:	37fd                	addiw	a5,a5,-1
    80002f6a:	475d                	li	a4,23
    80002f6c:	06f76f63          	bltu	a4,a5,80002fea <syscall+0xb0>
    80002f70:	003b1713          	slli	a4,s6,0x3
    80002f74:	00005797          	auipc	a5,0x5
    80002f78:	5c478793          	addi	a5,a5,1476 # 80008538 <syscalls>
    80002f7c:	97ba                	add	a5,a5,a4
    80002f7e:	0007bd03          	ld	s10,0(a5)
    80002f82:	060d0463          	beqz	s10,80002fea <syscall+0xb0>
    80002f86:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002f88:	fffb0c1b          	addiw	s8,s6,-1
    80002f8c:	004c1713          	slli	a4,s8,0x4
    80002f90:	00006797          	auipc	a5,0x6
    80002f94:	9c878793          	addi	a5,a5,-1592 # 80008958 <syscall_arg_infos>
    80002f98:	97ba                	add	a5,a5,a4
    80002f9a:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002f9e:	00299793          	slli	a5,s3,0x2
    80002fa2:	07bd                	addi	a5,a5,15
    80002fa4:	9bc1                	andi	a5,a5,-16
    80002fa6:	40f10133          	sub	sp,sp,a5
    80002faa:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002fac:	0f305363          	blez	s3,80003092 <syscall+0x158>
    80002fb0:	8ade                	mv	s5,s7
    80002fb2:	895e                	mv	s2,s7
    80002fb4:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	e0c080e7          	jalr	-500(ra) # 80002dc4 <argraw>
    80002fc0:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002fc4:	2485                	addiw	s1,s1,1
    80002fc6:	0911                	addi	s2,s2,4
    80002fc8:	fe9997e3          	bne	s3,s1,80002fb6 <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002fcc:	058a3483          	ld	s1,88(s4)
    80002fd0:	9d02                	jalr	s10
    80002fd2:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002fd4:	4785                	li	a5,1
    80002fd6:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002fda:	168a2b03          	lw	s6,360(s4)
    80002fde:	0167f7b3          	and	a5,a5,s6
    80002fe2:	2781                	sext.w	a5,a5
    80002fe4:	e7a1                	bnez	a5,8000302c <syscall+0xf2>
    80002fe6:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fe8:	a015                	j	8000300c <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fea:	86da                	mv	a3,s6
    80002fec:	158a0613          	addi	a2,s4,344
    80002ff0:	030a2583          	lw	a1,48(s4)
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	43450513          	addi	a0,a0,1076 # 80008428 <states.1811+0x168>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	58c080e7          	jalr	1420(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003004:	058a3783          	ld	a5,88(s4)
    80003008:	577d                	li	a4,-1
    8000300a:	fbb8                	sd	a4,112(a5)
  }
}
    8000300c:	fa040113          	addi	sp,s0,-96
    80003010:	60e6                	ld	ra,88(sp)
    80003012:	6446                	ld	s0,80(sp)
    80003014:	64a6                	ld	s1,72(sp)
    80003016:	6906                	ld	s2,64(sp)
    80003018:	79e2                	ld	s3,56(sp)
    8000301a:	7a42                	ld	s4,48(sp)
    8000301c:	7aa2                	ld	s5,40(sp)
    8000301e:	7b02                	ld	s6,32(sp)
    80003020:	6be2                	ld	s7,24(sp)
    80003022:	6c42                	ld	s8,16(sp)
    80003024:	6ca2                	ld	s9,8(sp)
    80003026:	6d02                	ld	s10,0(sp)
    80003028:	6125                	addi	sp,sp,96
    8000302a:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    8000302c:	0c12                	slli	s8,s8,0x4
    8000302e:	00006797          	auipc	a5,0x6
    80003032:	92a78793          	addi	a5,a5,-1750 # 80008958 <syscall_arg_infos>
    80003036:	9c3e                	add	s8,s8,a5
    80003038:	008c3603          	ld	a2,8(s8)
    8000303c:	030a2583          	lw	a1,48(s4)
    80003040:	00005517          	auipc	a0,0x5
    80003044:	40850513          	addi	a0,a0,1032 # 80008448 <states.1811+0x188>
    80003048:	ffffd097          	auipc	ra,0xffffd
    8000304c:	540080e7          	jalr	1344(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80003050:	fff9879b          	addiw	a5,s3,-1
    80003054:	1782                	slli	a5,a5,0x20
    80003056:	9381                	srli	a5,a5,0x20
    80003058:	0785                	addi	a5,a5,1
    8000305a:	078a                	slli	a5,a5,0x2
    8000305c:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    8000305e:	00005497          	auipc	s1,0x5
    80003062:	3b248493          	addi	s1,s1,946 # 80008410 <states.1811+0x150>
    80003066:	000aa583          	lw	a1,0(s5)
    8000306a:	8526                	mv	a0,s1
    8000306c:	ffffd097          	auipc	ra,0xffffd
    80003070:	51c080e7          	jalr	1308(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80003074:	0a91                	addi	s5,s5,4
    80003076:	ff7a98e3          	bne	s5,s7,80003066 <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    8000307a:	058a3783          	ld	a5,88(s4)
    8000307e:	7bac                	ld	a1,112(a5)
    80003080:	00005517          	auipc	a0,0x5
    80003084:	39850513          	addi	a0,a0,920 # 80008418 <states.1811+0x158>
    80003088:	ffffd097          	auipc	ra,0xffffd
    8000308c:	500080e7          	jalr	1280(ra) # 80000588 <printf>
    80003090:	bf99                	j	80002fe6 <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80003092:	9d02                	jalr	s10
    80003094:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80003096:	4785                	li	a5,1
    80003098:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    8000309c:	168a2703          	lw	a4,360(s4)
    800030a0:	8ff9                	and	a5,a5,a4
    800030a2:	2781                	sext.w	a5,a5
    800030a4:	d3a9                	beqz	a5,80002fe6 <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    800030a6:	0c12                	slli	s8,s8,0x4
    800030a8:	00006797          	auipc	a5,0x6
    800030ac:	8b078793          	addi	a5,a5,-1872 # 80008958 <syscall_arg_infos>
    800030b0:	97e2                	add	a5,a5,s8
    800030b2:	6790                	ld	a2,8(a5)
    800030b4:	030a2583          	lw	a1,48(s4)
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	39050513          	addi	a0,a0,912 # 80008448 <states.1811+0x188>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	4c8080e7          	jalr	1224(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    800030c8:	bf4d                	j	8000307a <syscall+0x140>

00000000800030ca <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030d2:	fec40593          	addi	a1,s0,-20
    800030d6:	4501                	li	a0,0
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	dee080e7          	jalr	-530(ra) # 80002ec6 <argint>
    return -1;
    800030e0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030e2:	00054963          	bltz	a0,800030f4 <sys_exit+0x2a>
  exit(n);
    800030e6:	fec42503          	lw	a0,-20(s0)
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	588080e7          	jalr	1416(ra) # 80002672 <exit>
  return 0;  // not reached
    800030f2:	4781                	li	a5,0
}
    800030f4:	853e                	mv	a0,a5
    800030f6:	60e2                	ld	ra,24(sp)
    800030f8:	6442                	ld	s0,16(sp)
    800030fa:	6105                	addi	sp,sp,32
    800030fc:	8082                	ret

00000000800030fe <sys_getpid>:

uint64
sys_getpid(void)
{
    800030fe:	1141                	addi	sp,sp,-16
    80003100:	e406                	sd	ra,8(sp)
    80003102:	e022                	sd	s0,0(sp)
    80003104:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	9d0080e7          	jalr	-1584(ra) # 80001ad6 <myproc>
}
    8000310e:	5908                	lw	a0,48(a0)
    80003110:	60a2                	ld	ra,8(sp)
    80003112:	6402                	ld	s0,0(sp)
    80003114:	0141                	addi	sp,sp,16
    80003116:	8082                	ret

0000000080003118 <sys_fork>:

uint64
sys_fork(void)
{
    80003118:	1141                	addi	sp,sp,-16
    8000311a:	e406                	sd	ra,8(sp)
    8000311c:	e022                	sd	s0,0(sp)
    8000311e:	0800                	addi	s0,sp,16
  return fork();
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	dac080e7          	jalr	-596(ra) # 80001ecc <fork>
}
    80003128:	60a2                	ld	ra,8(sp)
    8000312a:	6402                	ld	s0,0(sp)
    8000312c:	0141                	addi	sp,sp,16
    8000312e:	8082                	ret

0000000080003130 <sys_wait>:

uint64
sys_wait(void)
{
    80003130:	1101                	addi	sp,sp,-32
    80003132:	ec06                	sd	ra,24(sp)
    80003134:	e822                	sd	s0,16(sp)
    80003136:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003138:	fe840593          	addi	a1,s0,-24
    8000313c:	4501                	li	a0,0
    8000313e:	00000097          	auipc	ra,0x0
    80003142:	daa080e7          	jalr	-598(ra) # 80002ee8 <argaddr>
    80003146:	87aa                	mv	a5,a0
    return -1;
    80003148:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000314a:	0007c863          	bltz	a5,8000315a <sys_wait+0x2a>
  return wait(p);
    8000314e:	fe843503          	ld	a0,-24(s0)
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	1dc080e7          	jalr	476(ra) # 8000232e <wait>
}
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret

0000000080003162 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003162:	7139                	addi	sp,sp,-64
    80003164:	fc06                	sd	ra,56(sp)
    80003166:	f822                	sd	s0,48(sp)
    80003168:	f426                	sd	s1,40(sp)
    8000316a:	f04a                	sd	s2,32(sp)
    8000316c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    8000316e:	fd840593          	addi	a1,s0,-40
    80003172:	4501                	li	a0,0
    80003174:	00000097          	auipc	ra,0x0
    80003178:	d74080e7          	jalr	-652(ra) # 80002ee8 <argaddr>
    return -1;
    8000317c:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    8000317e:	08054063          	bltz	a0,800031fe <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003182:	fd040593          	addi	a1,s0,-48
    80003186:	4505                	li	a0,1
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	d60080e7          	jalr	-672(ra) # 80002ee8 <argaddr>
    return -1;
    80003190:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003192:	06054663          	bltz	a0,800031fe <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003196:	fc840593          	addi	a1,s0,-56
    8000319a:	4509                	li	a0,2
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	d4c080e7          	jalr	-692(ra) # 80002ee8 <argaddr>
    return -1;
    800031a4:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800031a6:	04054c63          	bltz	a0,800031fe <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800031aa:	fc040613          	addi	a2,s0,-64
    800031ae:	fc440593          	addi	a1,s0,-60
    800031b2:	fd843503          	ld	a0,-40(s0)
    800031b6:	fffff097          	auipc	ra,0xfffff
    800031ba:	2a0080e7          	jalr	672(ra) # 80002456 <waitx>
    800031be:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800031c0:	fffff097          	auipc	ra,0xfffff
    800031c4:	916080e7          	jalr	-1770(ra) # 80001ad6 <myproc>
    800031c8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800031ca:	4691                	li	a3,4
    800031cc:	fc440613          	addi	a2,s0,-60
    800031d0:	fd043583          	ld	a1,-48(s0)
    800031d4:	6928                	ld	a0,80(a0)
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	4a4080e7          	jalr	1188(ra) # 8000167a <copyout>
    return -1;
    800031de:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800031e0:	00054f63          	bltz	a0,800031fe <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800031e4:	4691                	li	a3,4
    800031e6:	fc040613          	addi	a2,s0,-64
    800031ea:	fc843583          	ld	a1,-56(s0)
    800031ee:	68a8                	ld	a0,80(s1)
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	48a080e7          	jalr	1162(ra) # 8000167a <copyout>
    800031f8:	00054a63          	bltz	a0,8000320c <sys_waitx+0xaa>
    return -1;
  return ret;
    800031fc:	87ca                	mv	a5,s2
}
    800031fe:	853e                	mv	a0,a5
    80003200:	70e2                	ld	ra,56(sp)
    80003202:	7442                	ld	s0,48(sp)
    80003204:	74a2                	ld	s1,40(sp)
    80003206:	7902                	ld	s2,32(sp)
    80003208:	6121                	addi	sp,sp,64
    8000320a:	8082                	ret
    return -1;
    8000320c:	57fd                	li	a5,-1
    8000320e:	bfc5                	j	800031fe <sys_waitx+0x9c>

0000000080003210 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003210:	7179                	addi	sp,sp,-48
    80003212:	f406                	sd	ra,40(sp)
    80003214:	f022                	sd	s0,32(sp)
    80003216:	ec26                	sd	s1,24(sp)
    80003218:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000321a:	fdc40593          	addi	a1,s0,-36
    8000321e:	4501                	li	a0,0
    80003220:	00000097          	auipc	ra,0x0
    80003224:	ca6080e7          	jalr	-858(ra) # 80002ec6 <argint>
    80003228:	87aa                	mv	a5,a0
    return -1;
    8000322a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000322c:	0207c063          	bltz	a5,8000324c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003230:	fffff097          	auipc	ra,0xfffff
    80003234:	8a6080e7          	jalr	-1882(ra) # 80001ad6 <myproc>
    80003238:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000323a:	fdc42503          	lw	a0,-36(s0)
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	c1a080e7          	jalr	-998(ra) # 80001e58 <growproc>
    80003246:	00054863          	bltz	a0,80003256 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000324a:	8526                	mv	a0,s1
}
    8000324c:	70a2                	ld	ra,40(sp)
    8000324e:	7402                	ld	s0,32(sp)
    80003250:	64e2                	ld	s1,24(sp)
    80003252:	6145                	addi	sp,sp,48
    80003254:	8082                	ret
    return -1;
    80003256:	557d                	li	a0,-1
    80003258:	bfd5                	j	8000324c <sys_sbrk+0x3c>

000000008000325a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000325a:	7139                	addi	sp,sp,-64
    8000325c:	fc06                	sd	ra,56(sp)
    8000325e:	f822                	sd	s0,48(sp)
    80003260:	f426                	sd	s1,40(sp)
    80003262:	f04a                	sd	s2,32(sp)
    80003264:	ec4e                	sd	s3,24(sp)
    80003266:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003268:	fcc40593          	addi	a1,s0,-52
    8000326c:	4501                	li	a0,0
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	c58080e7          	jalr	-936(ra) # 80002ec6 <argint>
    return -1;
    80003276:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003278:	06054563          	bltz	a0,800032e2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000327c:	00016517          	auipc	a0,0x16
    80003280:	ccc50513          	addi	a0,a0,-820 # 80018f48 <tickslock>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	960080e7          	jalr	-1696(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000328c:	00006917          	auipc	s2,0x6
    80003290:	da492903          	lw	s2,-604(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003294:	fcc42783          	lw	a5,-52(s0)
    80003298:	cf85                	beqz	a5,800032d0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000329a:	00016997          	auipc	s3,0x16
    8000329e:	cae98993          	addi	s3,s3,-850 # 80018f48 <tickslock>
    800032a2:	00006497          	auipc	s1,0x6
    800032a6:	d8e48493          	addi	s1,s1,-626 # 80009030 <ticks>
    if(myproc()->killed){
    800032aa:	fffff097          	auipc	ra,0xfffff
    800032ae:	82c080e7          	jalr	-2004(ra) # 80001ad6 <myproc>
    800032b2:	551c                	lw	a5,40(a0)
    800032b4:	ef9d                	bnez	a5,800032f2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032b6:	85ce                	mv	a1,s3
    800032b8:	8526                	mv	a0,s1
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	010080e7          	jalr	16(ra) # 800022ca <sleep>
  while(ticks - ticks0 < n){
    800032c2:	409c                	lw	a5,0(s1)
    800032c4:	412787bb          	subw	a5,a5,s2
    800032c8:	fcc42703          	lw	a4,-52(s0)
    800032cc:	fce7efe3          	bltu	a5,a4,800032aa <sys_sleep+0x50>
  }
  release(&tickslock);
    800032d0:	00016517          	auipc	a0,0x16
    800032d4:	c7850513          	addi	a0,a0,-904 # 80018f48 <tickslock>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
  return 0;
    800032e0:	4781                	li	a5,0
}
    800032e2:	853e                	mv	a0,a5
    800032e4:	70e2                	ld	ra,56(sp)
    800032e6:	7442                	ld	s0,48(sp)
    800032e8:	74a2                	ld	s1,40(sp)
    800032ea:	7902                	ld	s2,32(sp)
    800032ec:	69e2                	ld	s3,24(sp)
    800032ee:	6121                	addi	sp,sp,64
    800032f0:	8082                	ret
      release(&tickslock);
    800032f2:	00016517          	auipc	a0,0x16
    800032f6:	c5650513          	addi	a0,a0,-938 # 80018f48 <tickslock>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	99e080e7          	jalr	-1634(ra) # 80000c98 <release>
      return -1;
    80003302:	57fd                	li	a5,-1
    80003304:	bff9                	j	800032e2 <sys_sleep+0x88>

0000000080003306 <sys_kill>:

uint64
sys_kill(void)
{
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000330e:	fec40593          	addi	a1,s0,-20
    80003312:	4501                	li	a0,0
    80003314:	00000097          	auipc	ra,0x0
    80003318:	bb2080e7          	jalr	-1102(ra) # 80002ec6 <argint>
    8000331c:	87aa                	mv	a5,a0
    return -1;
    8000331e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003320:	0007c863          	bltz	a5,80003330 <sys_kill+0x2a>
  return kill(pid);
    80003324:	fec42503          	lw	a0,-20(s0)
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	42c080e7          	jalr	1068(ra) # 80002754 <kill>
}
    80003330:	60e2                	ld	ra,24(sp)
    80003332:	6442                	ld	s0,16(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret

0000000080003338 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	e426                	sd	s1,8(sp)
    80003340:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003342:	00016517          	auipc	a0,0x16
    80003346:	c0650513          	addi	a0,a0,-1018 # 80018f48 <tickslock>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	89a080e7          	jalr	-1894(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003352:	00006497          	auipc	s1,0x6
    80003356:	cde4a483          	lw	s1,-802(s1) # 80009030 <ticks>
  release(&tickslock);
    8000335a:	00016517          	auipc	a0,0x16
    8000335e:	bee50513          	addi	a0,a0,-1042 # 80018f48 <tickslock>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
  return xticks;
}
    8000336a:	02049513          	slli	a0,s1,0x20
    8000336e:	9101                	srli	a0,a0,0x20
    80003370:	60e2                	ld	ra,24(sp)
    80003372:	6442                	ld	s0,16(sp)
    80003374:	64a2                	ld	s1,8(sp)
    80003376:	6105                	addi	sp,sp,32
    80003378:	8082                	ret

000000008000337a <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    80003382:	fec40593          	addi	a1,s0,-20
    80003386:	4501                	li	a0,0
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	b3e080e7          	jalr	-1218(ra) # 80002ec6 <argint>
  trace(n);
    80003390:	fec42503          	lw	a0,-20(s0)
    80003394:	fffff097          	auipc	ra,0xfffff
    80003398:	58c080e7          	jalr	1420(ra) # 80002920 <trace>
  return 0; // if the syscall is successful, return 0
}
    8000339c:	4501                	li	a0,0
    8000339e:	60e2                	ld	ra,24(sp)
    800033a0:	6442                	ld	s0,16(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret

00000000800033a6 <sys_set_priority>:

// to change the static priority of a process with given pid
uint64
sys_set_priority(void)
{
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	1000                	addi	s0,sp,32
  int pid, new_priority;
  if(argint(0, &new_priority) < 0)
    800033ae:	fe840593          	addi	a1,s0,-24
    800033b2:	4501                	li	a0,0
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	b12080e7          	jalr	-1262(ra) # 80002ec6 <argint>
    return -1;
    800033bc:	57fd                	li	a5,-1
  if(argint(0, &new_priority) < 0)
    800033be:	02054563          	bltz	a0,800033e8 <sys_set_priority+0x42>
  if(argint(1, &pid) < 0)
    800033c2:	fec40593          	addi	a1,s0,-20
    800033c6:	4505                	li	a0,1
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	afe080e7          	jalr	-1282(ra) # 80002ec6 <argint>
    return -1;
    800033d0:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    800033d2:	00054b63          	bltz	a0,800033e8 <sys_set_priority+0x42>
  return set_priority(new_priority, pid);
    800033d6:	fec42583          	lw	a1,-20(s0)
    800033da:	fe842503          	lw	a0,-24(s0)
    800033de:	fffff097          	auipc	ra,0xfffff
    800033e2:	564080e7          	jalr	1380(ra) # 80002942 <set_priority>
    800033e6:	87aa                	mv	a5,a0
    800033e8:	853e                	mv	a0,a5
    800033ea:	60e2                	ld	ra,24(sp)
    800033ec:	6442                	ld	s0,16(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033f2:	7179                	addi	sp,sp,-48
    800033f4:	f406                	sd	ra,40(sp)
    800033f6:	f022                	sd	s0,32(sp)
    800033f8:	ec26                	sd	s1,24(sp)
    800033fa:	e84a                	sd	s2,16(sp)
    800033fc:	e44e                	sd	s3,8(sp)
    800033fe:	e052                	sd	s4,0(sp)
    80003400:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003402:	00005597          	auipc	a1,0x5
    80003406:	1fe58593          	addi	a1,a1,510 # 80008600 <syscalls+0xc8>
    8000340a:	00016517          	auipc	a0,0x16
    8000340e:	b5650513          	addi	a0,a0,-1194 # 80018f60 <bcache>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	742080e7          	jalr	1858(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000341a:	0001e797          	auipc	a5,0x1e
    8000341e:	b4678793          	addi	a5,a5,-1210 # 80020f60 <bcache+0x8000>
    80003422:	0001e717          	auipc	a4,0x1e
    80003426:	da670713          	addi	a4,a4,-602 # 800211c8 <bcache+0x8268>
    8000342a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000342e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003432:	00016497          	auipc	s1,0x16
    80003436:	b4648493          	addi	s1,s1,-1210 # 80018f78 <bcache+0x18>
    b->next = bcache.head.next;
    8000343a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000343c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000343e:	00005a17          	auipc	s4,0x5
    80003442:	1caa0a13          	addi	s4,s4,458 # 80008608 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003446:	2b893783          	ld	a5,696(s2)
    8000344a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000344c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003450:	85d2                	mv	a1,s4
    80003452:	01048513          	addi	a0,s1,16
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	4bc080e7          	jalr	1212(ra) # 80004912 <initsleeplock>
    bcache.head.next->prev = b;
    8000345e:	2b893783          	ld	a5,696(s2)
    80003462:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003464:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003468:	45848493          	addi	s1,s1,1112
    8000346c:	fd349de3          	bne	s1,s3,80003446 <binit+0x54>
  }
}
    80003470:	70a2                	ld	ra,40(sp)
    80003472:	7402                	ld	s0,32(sp)
    80003474:	64e2                	ld	s1,24(sp)
    80003476:	6942                	ld	s2,16(sp)
    80003478:	69a2                	ld	s3,8(sp)
    8000347a:	6a02                	ld	s4,0(sp)
    8000347c:	6145                	addi	sp,sp,48
    8000347e:	8082                	ret

0000000080003480 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003480:	7179                	addi	sp,sp,-48
    80003482:	f406                	sd	ra,40(sp)
    80003484:	f022                	sd	s0,32(sp)
    80003486:	ec26                	sd	s1,24(sp)
    80003488:	e84a                	sd	s2,16(sp)
    8000348a:	e44e                	sd	s3,8(sp)
    8000348c:	1800                	addi	s0,sp,48
    8000348e:	89aa                	mv	s3,a0
    80003490:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003492:	00016517          	auipc	a0,0x16
    80003496:	ace50513          	addi	a0,a0,-1330 # 80018f60 <bcache>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	74a080e7          	jalr	1866(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034a2:	0001e497          	auipc	s1,0x1e
    800034a6:	d764b483          	ld	s1,-650(s1) # 80021218 <bcache+0x82b8>
    800034aa:	0001e797          	auipc	a5,0x1e
    800034ae:	d1e78793          	addi	a5,a5,-738 # 800211c8 <bcache+0x8268>
    800034b2:	02f48f63          	beq	s1,a5,800034f0 <bread+0x70>
    800034b6:	873e                	mv	a4,a5
    800034b8:	a021                	j	800034c0 <bread+0x40>
    800034ba:	68a4                	ld	s1,80(s1)
    800034bc:	02e48a63          	beq	s1,a4,800034f0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034c0:	449c                	lw	a5,8(s1)
    800034c2:	ff379ce3          	bne	a5,s3,800034ba <bread+0x3a>
    800034c6:	44dc                	lw	a5,12(s1)
    800034c8:	ff2799e3          	bne	a5,s2,800034ba <bread+0x3a>
      b->refcnt++;
    800034cc:	40bc                	lw	a5,64(s1)
    800034ce:	2785                	addiw	a5,a5,1
    800034d0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034d2:	00016517          	auipc	a0,0x16
    800034d6:	a8e50513          	addi	a0,a0,-1394 # 80018f60 <bcache>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	7be080e7          	jalr	1982(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034e2:	01048513          	addi	a0,s1,16
    800034e6:	00001097          	auipc	ra,0x1
    800034ea:	466080e7          	jalr	1126(ra) # 8000494c <acquiresleep>
      return b;
    800034ee:	a8b9                	j	8000354c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034f0:	0001e497          	auipc	s1,0x1e
    800034f4:	d204b483          	ld	s1,-736(s1) # 80021210 <bcache+0x82b0>
    800034f8:	0001e797          	auipc	a5,0x1e
    800034fc:	cd078793          	addi	a5,a5,-816 # 800211c8 <bcache+0x8268>
    80003500:	00f48863          	beq	s1,a5,80003510 <bread+0x90>
    80003504:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003506:	40bc                	lw	a5,64(s1)
    80003508:	cf81                	beqz	a5,80003520 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000350a:	64a4                	ld	s1,72(s1)
    8000350c:	fee49de3          	bne	s1,a4,80003506 <bread+0x86>
  panic("bget: no buffers");
    80003510:	00005517          	auipc	a0,0x5
    80003514:	10050513          	addi	a0,a0,256 # 80008610 <syscalls+0xd8>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	026080e7          	jalr	38(ra) # 8000053e <panic>
      b->dev = dev;
    80003520:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003524:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003528:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000352c:	4785                	li	a5,1
    8000352e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003530:	00016517          	auipc	a0,0x16
    80003534:	a3050513          	addi	a0,a0,-1488 # 80018f60 <bcache>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	760080e7          	jalr	1888(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003540:	01048513          	addi	a0,s1,16
    80003544:	00001097          	auipc	ra,0x1
    80003548:	408080e7          	jalr	1032(ra) # 8000494c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000354c:	409c                	lw	a5,0(s1)
    8000354e:	cb89                	beqz	a5,80003560 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003550:	8526                	mv	a0,s1
    80003552:	70a2                	ld	ra,40(sp)
    80003554:	7402                	ld	s0,32(sp)
    80003556:	64e2                	ld	s1,24(sp)
    80003558:	6942                	ld	s2,16(sp)
    8000355a:	69a2                	ld	s3,8(sp)
    8000355c:	6145                	addi	sp,sp,48
    8000355e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003560:	4581                	li	a1,0
    80003562:	8526                	mv	a0,s1
    80003564:	00003097          	auipc	ra,0x3
    80003568:	f12080e7          	jalr	-238(ra) # 80006476 <virtio_disk_rw>
    b->valid = 1;
    8000356c:	4785                	li	a5,1
    8000356e:	c09c                	sw	a5,0(s1)
  return b;
    80003570:	b7c5                	j	80003550 <bread+0xd0>

0000000080003572 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	e426                	sd	s1,8(sp)
    8000357a:	1000                	addi	s0,sp,32
    8000357c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000357e:	0541                	addi	a0,a0,16
    80003580:	00001097          	auipc	ra,0x1
    80003584:	466080e7          	jalr	1126(ra) # 800049e6 <holdingsleep>
    80003588:	cd01                	beqz	a0,800035a0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000358a:	4585                	li	a1,1
    8000358c:	8526                	mv	a0,s1
    8000358e:	00003097          	auipc	ra,0x3
    80003592:	ee8080e7          	jalr	-280(ra) # 80006476 <virtio_disk_rw>
}
    80003596:	60e2                	ld	ra,24(sp)
    80003598:	6442                	ld	s0,16(sp)
    8000359a:	64a2                	ld	s1,8(sp)
    8000359c:	6105                	addi	sp,sp,32
    8000359e:	8082                	ret
    panic("bwrite");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	08850513          	addi	a0,a0,136 # 80008628 <syscalls+0xf0>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f96080e7          	jalr	-106(ra) # 8000053e <panic>

00000000800035b0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035b0:	1101                	addi	sp,sp,-32
    800035b2:	ec06                	sd	ra,24(sp)
    800035b4:	e822                	sd	s0,16(sp)
    800035b6:	e426                	sd	s1,8(sp)
    800035b8:	e04a                	sd	s2,0(sp)
    800035ba:	1000                	addi	s0,sp,32
    800035bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035be:	01050913          	addi	s2,a0,16
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	422080e7          	jalr	1058(ra) # 800049e6 <holdingsleep>
    800035cc:	c92d                	beqz	a0,8000363e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035ce:	854a                	mv	a0,s2
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	3d2080e7          	jalr	978(ra) # 800049a2 <releasesleep>

  acquire(&bcache.lock);
    800035d8:	00016517          	auipc	a0,0x16
    800035dc:	98850513          	addi	a0,a0,-1656 # 80018f60 <bcache>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	604080e7          	jalr	1540(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035e8:	40bc                	lw	a5,64(s1)
    800035ea:	37fd                	addiw	a5,a5,-1
    800035ec:	0007871b          	sext.w	a4,a5
    800035f0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035f2:	eb05                	bnez	a4,80003622 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035f4:	68bc                	ld	a5,80(s1)
    800035f6:	64b8                	ld	a4,72(s1)
    800035f8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035fa:	64bc                	ld	a5,72(s1)
    800035fc:	68b8                	ld	a4,80(s1)
    800035fe:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003600:	0001e797          	auipc	a5,0x1e
    80003604:	96078793          	addi	a5,a5,-1696 # 80020f60 <bcache+0x8000>
    80003608:	2b87b703          	ld	a4,696(a5)
    8000360c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000360e:	0001e717          	auipc	a4,0x1e
    80003612:	bba70713          	addi	a4,a4,-1094 # 800211c8 <bcache+0x8268>
    80003616:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003618:	2b87b703          	ld	a4,696(a5)
    8000361c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000361e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003622:	00016517          	auipc	a0,0x16
    80003626:	93e50513          	addi	a0,a0,-1730 # 80018f60 <bcache>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	66e080e7          	jalr	1646(ra) # 80000c98 <release>
}
    80003632:	60e2                	ld	ra,24(sp)
    80003634:	6442                	ld	s0,16(sp)
    80003636:	64a2                	ld	s1,8(sp)
    80003638:	6902                	ld	s2,0(sp)
    8000363a:	6105                	addi	sp,sp,32
    8000363c:	8082                	ret
    panic("brelse");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	ff250513          	addi	a0,a0,-14 # 80008630 <syscalls+0xf8>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	ef8080e7          	jalr	-264(ra) # 8000053e <panic>

000000008000364e <bpin>:

void
bpin(struct buf *b) {
    8000364e:	1101                	addi	sp,sp,-32
    80003650:	ec06                	sd	ra,24(sp)
    80003652:	e822                	sd	s0,16(sp)
    80003654:	e426                	sd	s1,8(sp)
    80003656:	1000                	addi	s0,sp,32
    80003658:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000365a:	00016517          	auipc	a0,0x16
    8000365e:	90650513          	addi	a0,a0,-1786 # 80018f60 <bcache>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	582080e7          	jalr	1410(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000366a:	40bc                	lw	a5,64(s1)
    8000366c:	2785                	addiw	a5,a5,1
    8000366e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003670:	00016517          	auipc	a0,0x16
    80003674:	8f050513          	addi	a0,a0,-1808 # 80018f60 <bcache>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	620080e7          	jalr	1568(ra) # 80000c98 <release>
}
    80003680:	60e2                	ld	ra,24(sp)
    80003682:	6442                	ld	s0,16(sp)
    80003684:	64a2                	ld	s1,8(sp)
    80003686:	6105                	addi	sp,sp,32
    80003688:	8082                	ret

000000008000368a <bunpin>:

void
bunpin(struct buf *b) {
    8000368a:	1101                	addi	sp,sp,-32
    8000368c:	ec06                	sd	ra,24(sp)
    8000368e:	e822                	sd	s0,16(sp)
    80003690:	e426                	sd	s1,8(sp)
    80003692:	1000                	addi	s0,sp,32
    80003694:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003696:	00016517          	auipc	a0,0x16
    8000369a:	8ca50513          	addi	a0,a0,-1846 # 80018f60 <bcache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	546080e7          	jalr	1350(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036a6:	40bc                	lw	a5,64(s1)
    800036a8:	37fd                	addiw	a5,a5,-1
    800036aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ac:	00016517          	auipc	a0,0x16
    800036b0:	8b450513          	addi	a0,a0,-1868 # 80018f60 <bcache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	5e4080e7          	jalr	1508(ra) # 80000c98 <release>
}
    800036bc:	60e2                	ld	ra,24(sp)
    800036be:	6442                	ld	s0,16(sp)
    800036c0:	64a2                	ld	s1,8(sp)
    800036c2:	6105                	addi	sp,sp,32
    800036c4:	8082                	ret

00000000800036c6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036c6:	1101                	addi	sp,sp,-32
    800036c8:	ec06                	sd	ra,24(sp)
    800036ca:	e822                	sd	s0,16(sp)
    800036cc:	e426                	sd	s1,8(sp)
    800036ce:	e04a                	sd	s2,0(sp)
    800036d0:	1000                	addi	s0,sp,32
    800036d2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036d4:	00d5d59b          	srliw	a1,a1,0xd
    800036d8:	0001e797          	auipc	a5,0x1e
    800036dc:	f647a783          	lw	a5,-156(a5) # 8002163c <sb+0x1c>
    800036e0:	9dbd                	addw	a1,a1,a5
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	d9e080e7          	jalr	-610(ra) # 80003480 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036ea:	0074f713          	andi	a4,s1,7
    800036ee:	4785                	li	a5,1
    800036f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036f4:	14ce                	slli	s1,s1,0x33
    800036f6:	90d9                	srli	s1,s1,0x36
    800036f8:	00950733          	add	a4,a0,s1
    800036fc:	05874703          	lbu	a4,88(a4)
    80003700:	00e7f6b3          	and	a3,a5,a4
    80003704:	c69d                	beqz	a3,80003732 <bfree+0x6c>
    80003706:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003708:	94aa                	add	s1,s1,a0
    8000370a:	fff7c793          	not	a5,a5
    8000370e:	8ff9                	and	a5,a5,a4
    80003710:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003714:	00001097          	auipc	ra,0x1
    80003718:	118080e7          	jalr	280(ra) # 8000482c <log_write>
  brelse(bp);
    8000371c:	854a                	mv	a0,s2
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	e92080e7          	jalr	-366(ra) # 800035b0 <brelse>
}
    80003726:	60e2                	ld	ra,24(sp)
    80003728:	6442                	ld	s0,16(sp)
    8000372a:	64a2                	ld	s1,8(sp)
    8000372c:	6902                	ld	s2,0(sp)
    8000372e:	6105                	addi	sp,sp,32
    80003730:	8082                	ret
    panic("freeing free block");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	f0650513          	addi	a0,a0,-250 # 80008638 <syscalls+0x100>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e04080e7          	jalr	-508(ra) # 8000053e <panic>

0000000080003742 <balloc>:
{
    80003742:	711d                	addi	sp,sp,-96
    80003744:	ec86                	sd	ra,88(sp)
    80003746:	e8a2                	sd	s0,80(sp)
    80003748:	e4a6                	sd	s1,72(sp)
    8000374a:	e0ca                	sd	s2,64(sp)
    8000374c:	fc4e                	sd	s3,56(sp)
    8000374e:	f852                	sd	s4,48(sp)
    80003750:	f456                	sd	s5,40(sp)
    80003752:	f05a                	sd	s6,32(sp)
    80003754:	ec5e                	sd	s7,24(sp)
    80003756:	e862                	sd	s8,16(sp)
    80003758:	e466                	sd	s9,8(sp)
    8000375a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000375c:	0001e797          	auipc	a5,0x1e
    80003760:	ec87a783          	lw	a5,-312(a5) # 80021624 <sb+0x4>
    80003764:	cbd1                	beqz	a5,800037f8 <balloc+0xb6>
    80003766:	8baa                	mv	s7,a0
    80003768:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000376a:	0001eb17          	auipc	s6,0x1e
    8000376e:	eb6b0b13          	addi	s6,s6,-330 # 80021620 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003772:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003774:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003776:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003778:	6c89                	lui	s9,0x2
    8000377a:	a831                	j	80003796 <balloc+0x54>
    brelse(bp);
    8000377c:	854a                	mv	a0,s2
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	e32080e7          	jalr	-462(ra) # 800035b0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003786:	015c87bb          	addw	a5,s9,s5
    8000378a:	00078a9b          	sext.w	s5,a5
    8000378e:	004b2703          	lw	a4,4(s6)
    80003792:	06eaf363          	bgeu	s5,a4,800037f8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003796:	41fad79b          	sraiw	a5,s5,0x1f
    8000379a:	0137d79b          	srliw	a5,a5,0x13
    8000379e:	015787bb          	addw	a5,a5,s5
    800037a2:	40d7d79b          	sraiw	a5,a5,0xd
    800037a6:	01cb2583          	lw	a1,28(s6)
    800037aa:	9dbd                	addw	a1,a1,a5
    800037ac:	855e                	mv	a0,s7
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	cd2080e7          	jalr	-814(ra) # 80003480 <bread>
    800037b6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037b8:	004b2503          	lw	a0,4(s6)
    800037bc:	000a849b          	sext.w	s1,s5
    800037c0:	8662                	mv	a2,s8
    800037c2:	faa4fde3          	bgeu	s1,a0,8000377c <balloc+0x3a>
      m = 1 << (bi % 8);
    800037c6:	41f6579b          	sraiw	a5,a2,0x1f
    800037ca:	01d7d69b          	srliw	a3,a5,0x1d
    800037ce:	00c6873b          	addw	a4,a3,a2
    800037d2:	00777793          	andi	a5,a4,7
    800037d6:	9f95                	subw	a5,a5,a3
    800037d8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037dc:	4037571b          	sraiw	a4,a4,0x3
    800037e0:	00e906b3          	add	a3,s2,a4
    800037e4:	0586c683          	lbu	a3,88(a3)
    800037e8:	00d7f5b3          	and	a1,a5,a3
    800037ec:	cd91                	beqz	a1,80003808 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ee:	2605                	addiw	a2,a2,1
    800037f0:	2485                	addiw	s1,s1,1
    800037f2:	fd4618e3          	bne	a2,s4,800037c2 <balloc+0x80>
    800037f6:	b759                	j	8000377c <balloc+0x3a>
  panic("balloc: out of blocks");
    800037f8:	00005517          	auipc	a0,0x5
    800037fc:	e5850513          	addi	a0,a0,-424 # 80008650 <syscalls+0x118>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	d3e080e7          	jalr	-706(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003808:	974a                	add	a4,a4,s2
    8000380a:	8fd5                	or	a5,a5,a3
    8000380c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	01a080e7          	jalr	26(ra) # 8000482c <log_write>
        brelse(bp);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	d94080e7          	jalr	-620(ra) # 800035b0 <brelse>
  bp = bread(dev, bno);
    80003824:	85a6                	mv	a1,s1
    80003826:	855e                	mv	a0,s7
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	c58080e7          	jalr	-936(ra) # 80003480 <bread>
    80003830:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003832:	40000613          	li	a2,1024
    80003836:	4581                	li	a1,0
    80003838:	05850513          	addi	a0,a0,88
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	4a4080e7          	jalr	1188(ra) # 80000ce0 <memset>
  log_write(bp);
    80003844:	854a                	mv	a0,s2
    80003846:	00001097          	auipc	ra,0x1
    8000384a:	fe6080e7          	jalr	-26(ra) # 8000482c <log_write>
  brelse(bp);
    8000384e:	854a                	mv	a0,s2
    80003850:	00000097          	auipc	ra,0x0
    80003854:	d60080e7          	jalr	-672(ra) # 800035b0 <brelse>
}
    80003858:	8526                	mv	a0,s1
    8000385a:	60e6                	ld	ra,88(sp)
    8000385c:	6446                	ld	s0,80(sp)
    8000385e:	64a6                	ld	s1,72(sp)
    80003860:	6906                	ld	s2,64(sp)
    80003862:	79e2                	ld	s3,56(sp)
    80003864:	7a42                	ld	s4,48(sp)
    80003866:	7aa2                	ld	s5,40(sp)
    80003868:	7b02                	ld	s6,32(sp)
    8000386a:	6be2                	ld	s7,24(sp)
    8000386c:	6c42                	ld	s8,16(sp)
    8000386e:	6ca2                	ld	s9,8(sp)
    80003870:	6125                	addi	sp,sp,96
    80003872:	8082                	ret

0000000080003874 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003874:	7179                	addi	sp,sp,-48
    80003876:	f406                	sd	ra,40(sp)
    80003878:	f022                	sd	s0,32(sp)
    8000387a:	ec26                	sd	s1,24(sp)
    8000387c:	e84a                	sd	s2,16(sp)
    8000387e:	e44e                	sd	s3,8(sp)
    80003880:	e052                	sd	s4,0(sp)
    80003882:	1800                	addi	s0,sp,48
    80003884:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003886:	47ad                	li	a5,11
    80003888:	04b7fe63          	bgeu	a5,a1,800038e4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000388c:	ff45849b          	addiw	s1,a1,-12
    80003890:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003894:	0ff00793          	li	a5,255
    80003898:	0ae7e363          	bltu	a5,a4,8000393e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000389c:	08052583          	lw	a1,128(a0)
    800038a0:	c5ad                	beqz	a1,8000390a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038a2:	00092503          	lw	a0,0(s2)
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	bda080e7          	jalr	-1062(ra) # 80003480 <bread>
    800038ae:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038b0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038b4:	02049593          	slli	a1,s1,0x20
    800038b8:	9181                	srli	a1,a1,0x20
    800038ba:	058a                	slli	a1,a1,0x2
    800038bc:	00b784b3          	add	s1,a5,a1
    800038c0:	0004a983          	lw	s3,0(s1)
    800038c4:	04098d63          	beqz	s3,8000391e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038c8:	8552                	mv	a0,s4
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	ce6080e7          	jalr	-794(ra) # 800035b0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038d2:	854e                	mv	a0,s3
    800038d4:	70a2                	ld	ra,40(sp)
    800038d6:	7402                	ld	s0,32(sp)
    800038d8:	64e2                	ld	s1,24(sp)
    800038da:	6942                	ld	s2,16(sp)
    800038dc:	69a2                	ld	s3,8(sp)
    800038de:	6a02                	ld	s4,0(sp)
    800038e0:	6145                	addi	sp,sp,48
    800038e2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038e4:	02059493          	slli	s1,a1,0x20
    800038e8:	9081                	srli	s1,s1,0x20
    800038ea:	048a                	slli	s1,s1,0x2
    800038ec:	94aa                	add	s1,s1,a0
    800038ee:	0504a983          	lw	s3,80(s1)
    800038f2:	fe0990e3          	bnez	s3,800038d2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038f6:	4108                	lw	a0,0(a0)
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	e4a080e7          	jalr	-438(ra) # 80003742 <balloc>
    80003900:	0005099b          	sext.w	s3,a0
    80003904:	0534a823          	sw	s3,80(s1)
    80003908:	b7e9                	j	800038d2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000390a:	4108                	lw	a0,0(a0)
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	e36080e7          	jalr	-458(ra) # 80003742 <balloc>
    80003914:	0005059b          	sext.w	a1,a0
    80003918:	08b92023          	sw	a1,128(s2)
    8000391c:	b759                	j	800038a2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000391e:	00092503          	lw	a0,0(s2)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e20080e7          	jalr	-480(ra) # 80003742 <balloc>
    8000392a:	0005099b          	sext.w	s3,a0
    8000392e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003932:	8552                	mv	a0,s4
    80003934:	00001097          	auipc	ra,0x1
    80003938:	ef8080e7          	jalr	-264(ra) # 8000482c <log_write>
    8000393c:	b771                	j	800038c8 <bmap+0x54>
  panic("bmap: out of range");
    8000393e:	00005517          	auipc	a0,0x5
    80003942:	d2a50513          	addi	a0,a0,-726 # 80008668 <syscalls+0x130>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	bf8080e7          	jalr	-1032(ra) # 8000053e <panic>

000000008000394e <iget>:
{
    8000394e:	7179                	addi	sp,sp,-48
    80003950:	f406                	sd	ra,40(sp)
    80003952:	f022                	sd	s0,32(sp)
    80003954:	ec26                	sd	s1,24(sp)
    80003956:	e84a                	sd	s2,16(sp)
    80003958:	e44e                	sd	s3,8(sp)
    8000395a:	e052                	sd	s4,0(sp)
    8000395c:	1800                	addi	s0,sp,48
    8000395e:	89aa                	mv	s3,a0
    80003960:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003962:	0001e517          	auipc	a0,0x1e
    80003966:	cde50513          	addi	a0,a0,-802 # 80021640 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	27a080e7          	jalr	634(ra) # 80000be4 <acquire>
  empty = 0;
    80003972:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003974:	0001e497          	auipc	s1,0x1e
    80003978:	ce448493          	addi	s1,s1,-796 # 80021658 <itable+0x18>
    8000397c:	0001f697          	auipc	a3,0x1f
    80003980:	76c68693          	addi	a3,a3,1900 # 800230e8 <log>
    80003984:	a039                	j	80003992 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003986:	02090b63          	beqz	s2,800039bc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000398a:	08848493          	addi	s1,s1,136
    8000398e:	02d48a63          	beq	s1,a3,800039c2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003992:	449c                	lw	a5,8(s1)
    80003994:	fef059e3          	blez	a5,80003986 <iget+0x38>
    80003998:	4098                	lw	a4,0(s1)
    8000399a:	ff3716e3          	bne	a4,s3,80003986 <iget+0x38>
    8000399e:	40d8                	lw	a4,4(s1)
    800039a0:	ff4713e3          	bne	a4,s4,80003986 <iget+0x38>
      ip->ref++;
    800039a4:	2785                	addiw	a5,a5,1
    800039a6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039a8:	0001e517          	auipc	a0,0x1e
    800039ac:	c9850513          	addi	a0,a0,-872 # 80021640 <itable>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	2e8080e7          	jalr	744(ra) # 80000c98 <release>
      return ip;
    800039b8:	8926                	mv	s2,s1
    800039ba:	a03d                	j	800039e8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039bc:	f7f9                	bnez	a5,8000398a <iget+0x3c>
    800039be:	8926                	mv	s2,s1
    800039c0:	b7e9                	j	8000398a <iget+0x3c>
  if(empty == 0)
    800039c2:	02090c63          	beqz	s2,800039fa <iget+0xac>
  ip->dev = dev;
    800039c6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039ca:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039ce:	4785                	li	a5,1
    800039d0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039d4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039d8:	0001e517          	auipc	a0,0x1e
    800039dc:	c6850513          	addi	a0,a0,-920 # 80021640 <itable>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	2b8080e7          	jalr	696(ra) # 80000c98 <release>
}
    800039e8:	854a                	mv	a0,s2
    800039ea:	70a2                	ld	ra,40(sp)
    800039ec:	7402                	ld	s0,32(sp)
    800039ee:	64e2                	ld	s1,24(sp)
    800039f0:	6942                	ld	s2,16(sp)
    800039f2:	69a2                	ld	s3,8(sp)
    800039f4:	6a02                	ld	s4,0(sp)
    800039f6:	6145                	addi	sp,sp,48
    800039f8:	8082                	ret
    panic("iget: no inodes");
    800039fa:	00005517          	auipc	a0,0x5
    800039fe:	c8650513          	addi	a0,a0,-890 # 80008680 <syscalls+0x148>
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>

0000000080003a0a <fsinit>:
fsinit(int dev) {
    80003a0a:	7179                	addi	sp,sp,-48
    80003a0c:	f406                	sd	ra,40(sp)
    80003a0e:	f022                	sd	s0,32(sp)
    80003a10:	ec26                	sd	s1,24(sp)
    80003a12:	e84a                	sd	s2,16(sp)
    80003a14:	e44e                	sd	s3,8(sp)
    80003a16:	1800                	addi	s0,sp,48
    80003a18:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a1a:	4585                	li	a1,1
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	a64080e7          	jalr	-1436(ra) # 80003480 <bread>
    80003a24:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a26:	0001e997          	auipc	s3,0x1e
    80003a2a:	bfa98993          	addi	s3,s3,-1030 # 80021620 <sb>
    80003a2e:	02000613          	li	a2,32
    80003a32:	05850593          	addi	a1,a0,88
    80003a36:	854e                	mv	a0,s3
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	308080e7          	jalr	776(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a40:	8526                	mv	a0,s1
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	b6e080e7          	jalr	-1170(ra) # 800035b0 <brelse>
  if(sb.magic != FSMAGIC)
    80003a4a:	0009a703          	lw	a4,0(s3)
    80003a4e:	102037b7          	lui	a5,0x10203
    80003a52:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a56:	02f71263          	bne	a4,a5,80003a7a <fsinit+0x70>
  initlog(dev, &sb);
    80003a5a:	0001e597          	auipc	a1,0x1e
    80003a5e:	bc658593          	addi	a1,a1,-1082 # 80021620 <sb>
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	b4c080e7          	jalr	-1204(ra) # 800045b0 <initlog>
}
    80003a6c:	70a2                	ld	ra,40(sp)
    80003a6e:	7402                	ld	s0,32(sp)
    80003a70:	64e2                	ld	s1,24(sp)
    80003a72:	6942                	ld	s2,16(sp)
    80003a74:	69a2                	ld	s3,8(sp)
    80003a76:	6145                	addi	sp,sp,48
    80003a78:	8082                	ret
    panic("invalid file system");
    80003a7a:	00005517          	auipc	a0,0x5
    80003a7e:	c1650513          	addi	a0,a0,-1002 # 80008690 <syscalls+0x158>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	abc080e7          	jalr	-1348(ra) # 8000053e <panic>

0000000080003a8a <iinit>:
{
    80003a8a:	7179                	addi	sp,sp,-48
    80003a8c:	f406                	sd	ra,40(sp)
    80003a8e:	f022                	sd	s0,32(sp)
    80003a90:	ec26                	sd	s1,24(sp)
    80003a92:	e84a                	sd	s2,16(sp)
    80003a94:	e44e                	sd	s3,8(sp)
    80003a96:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a98:	00005597          	auipc	a1,0x5
    80003a9c:	c1058593          	addi	a1,a1,-1008 # 800086a8 <syscalls+0x170>
    80003aa0:	0001e517          	auipc	a0,0x1e
    80003aa4:	ba050513          	addi	a0,a0,-1120 # 80021640 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	0ac080e7          	jalr	172(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ab0:	0001e497          	auipc	s1,0x1e
    80003ab4:	bb848493          	addi	s1,s1,-1096 # 80021668 <itable+0x28>
    80003ab8:	0001f997          	auipc	s3,0x1f
    80003abc:	64098993          	addi	s3,s3,1600 # 800230f8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ac0:	00005917          	auipc	s2,0x5
    80003ac4:	bf090913          	addi	s2,s2,-1040 # 800086b0 <syscalls+0x178>
    80003ac8:	85ca                	mv	a1,s2
    80003aca:	8526                	mv	a0,s1
    80003acc:	00001097          	auipc	ra,0x1
    80003ad0:	e46080e7          	jalr	-442(ra) # 80004912 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ad4:	08848493          	addi	s1,s1,136
    80003ad8:	ff3498e3          	bne	s1,s3,80003ac8 <iinit+0x3e>
}
    80003adc:	70a2                	ld	ra,40(sp)
    80003ade:	7402                	ld	s0,32(sp)
    80003ae0:	64e2                	ld	s1,24(sp)
    80003ae2:	6942                	ld	s2,16(sp)
    80003ae4:	69a2                	ld	s3,8(sp)
    80003ae6:	6145                	addi	sp,sp,48
    80003ae8:	8082                	ret

0000000080003aea <ialloc>:
{
    80003aea:	715d                	addi	sp,sp,-80
    80003aec:	e486                	sd	ra,72(sp)
    80003aee:	e0a2                	sd	s0,64(sp)
    80003af0:	fc26                	sd	s1,56(sp)
    80003af2:	f84a                	sd	s2,48(sp)
    80003af4:	f44e                	sd	s3,40(sp)
    80003af6:	f052                	sd	s4,32(sp)
    80003af8:	ec56                	sd	s5,24(sp)
    80003afa:	e85a                	sd	s6,16(sp)
    80003afc:	e45e                	sd	s7,8(sp)
    80003afe:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b00:	0001e717          	auipc	a4,0x1e
    80003b04:	b2c72703          	lw	a4,-1236(a4) # 8002162c <sb+0xc>
    80003b08:	4785                	li	a5,1
    80003b0a:	04e7fa63          	bgeu	a5,a4,80003b5e <ialloc+0x74>
    80003b0e:	8aaa                	mv	s5,a0
    80003b10:	8bae                	mv	s7,a1
    80003b12:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b14:	0001ea17          	auipc	s4,0x1e
    80003b18:	b0ca0a13          	addi	s4,s4,-1268 # 80021620 <sb>
    80003b1c:	00048b1b          	sext.w	s6,s1
    80003b20:	0044d593          	srli	a1,s1,0x4
    80003b24:	018a2783          	lw	a5,24(s4)
    80003b28:	9dbd                	addw	a1,a1,a5
    80003b2a:	8556                	mv	a0,s5
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	954080e7          	jalr	-1708(ra) # 80003480 <bread>
    80003b34:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b36:	05850993          	addi	s3,a0,88
    80003b3a:	00f4f793          	andi	a5,s1,15
    80003b3e:	079a                	slli	a5,a5,0x6
    80003b40:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b42:	00099783          	lh	a5,0(s3)
    80003b46:	c785                	beqz	a5,80003b6e <ialloc+0x84>
    brelse(bp);
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	a68080e7          	jalr	-1432(ra) # 800035b0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b50:	0485                	addi	s1,s1,1
    80003b52:	00ca2703          	lw	a4,12(s4)
    80003b56:	0004879b          	sext.w	a5,s1
    80003b5a:	fce7e1e3          	bltu	a5,a4,80003b1c <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b5e:	00005517          	auipc	a0,0x5
    80003b62:	b5a50513          	addi	a0,a0,-1190 # 800086b8 <syscalls+0x180>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b6e:	04000613          	li	a2,64
    80003b72:	4581                	li	a1,0
    80003b74:	854e                	mv	a0,s3
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	16a080e7          	jalr	362(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b7e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b82:	854a                	mv	a0,s2
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	ca8080e7          	jalr	-856(ra) # 8000482c <log_write>
      brelse(bp);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	a22080e7          	jalr	-1502(ra) # 800035b0 <brelse>
      return iget(dev, inum);
    80003b96:	85da                	mv	a1,s6
    80003b98:	8556                	mv	a0,s5
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	db4080e7          	jalr	-588(ra) # 8000394e <iget>
}
    80003ba2:	60a6                	ld	ra,72(sp)
    80003ba4:	6406                	ld	s0,64(sp)
    80003ba6:	74e2                	ld	s1,56(sp)
    80003ba8:	7942                	ld	s2,48(sp)
    80003baa:	79a2                	ld	s3,40(sp)
    80003bac:	7a02                	ld	s4,32(sp)
    80003bae:	6ae2                	ld	s5,24(sp)
    80003bb0:	6b42                	ld	s6,16(sp)
    80003bb2:	6ba2                	ld	s7,8(sp)
    80003bb4:	6161                	addi	sp,sp,80
    80003bb6:	8082                	ret

0000000080003bb8 <iupdate>:
{
    80003bb8:	1101                	addi	sp,sp,-32
    80003bba:	ec06                	sd	ra,24(sp)
    80003bbc:	e822                	sd	s0,16(sp)
    80003bbe:	e426                	sd	s1,8(sp)
    80003bc0:	e04a                	sd	s2,0(sp)
    80003bc2:	1000                	addi	s0,sp,32
    80003bc4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bc6:	415c                	lw	a5,4(a0)
    80003bc8:	0047d79b          	srliw	a5,a5,0x4
    80003bcc:	0001e597          	auipc	a1,0x1e
    80003bd0:	a6c5a583          	lw	a1,-1428(a1) # 80021638 <sb+0x18>
    80003bd4:	9dbd                	addw	a1,a1,a5
    80003bd6:	4108                	lw	a0,0(a0)
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	8a8080e7          	jalr	-1880(ra) # 80003480 <bread>
    80003be0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003be2:	05850793          	addi	a5,a0,88
    80003be6:	40c8                	lw	a0,4(s1)
    80003be8:	893d                	andi	a0,a0,15
    80003bea:	051a                	slli	a0,a0,0x6
    80003bec:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bee:	04449703          	lh	a4,68(s1)
    80003bf2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bf6:	04649703          	lh	a4,70(s1)
    80003bfa:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bfe:	04849703          	lh	a4,72(s1)
    80003c02:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c06:	04a49703          	lh	a4,74(s1)
    80003c0a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c0e:	44f8                	lw	a4,76(s1)
    80003c10:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c12:	03400613          	li	a2,52
    80003c16:	05048593          	addi	a1,s1,80
    80003c1a:	0531                	addi	a0,a0,12
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	124080e7          	jalr	292(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c24:	854a                	mv	a0,s2
    80003c26:	00001097          	auipc	ra,0x1
    80003c2a:	c06080e7          	jalr	-1018(ra) # 8000482c <log_write>
  brelse(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	980080e7          	jalr	-1664(ra) # 800035b0 <brelse>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6902                	ld	s2,0(sp)
    80003c40:	6105                	addi	sp,sp,32
    80003c42:	8082                	ret

0000000080003c44 <idup>:
{
    80003c44:	1101                	addi	sp,sp,-32
    80003c46:	ec06                	sd	ra,24(sp)
    80003c48:	e822                	sd	s0,16(sp)
    80003c4a:	e426                	sd	s1,8(sp)
    80003c4c:	1000                	addi	s0,sp,32
    80003c4e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c50:	0001e517          	auipc	a0,0x1e
    80003c54:	9f050513          	addi	a0,a0,-1552 # 80021640 <itable>
    80003c58:	ffffd097          	auipc	ra,0xffffd
    80003c5c:	f8c080e7          	jalr	-116(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c60:	449c                	lw	a5,8(s1)
    80003c62:	2785                	addiw	a5,a5,1
    80003c64:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c66:	0001e517          	auipc	a0,0x1e
    80003c6a:	9da50513          	addi	a0,a0,-1574 # 80021640 <itable>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
}
    80003c76:	8526                	mv	a0,s1
    80003c78:	60e2                	ld	ra,24(sp)
    80003c7a:	6442                	ld	s0,16(sp)
    80003c7c:	64a2                	ld	s1,8(sp)
    80003c7e:	6105                	addi	sp,sp,32
    80003c80:	8082                	ret

0000000080003c82 <ilock>:
{
    80003c82:	1101                	addi	sp,sp,-32
    80003c84:	ec06                	sd	ra,24(sp)
    80003c86:	e822                	sd	s0,16(sp)
    80003c88:	e426                	sd	s1,8(sp)
    80003c8a:	e04a                	sd	s2,0(sp)
    80003c8c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c8e:	c115                	beqz	a0,80003cb2 <ilock+0x30>
    80003c90:	84aa                	mv	s1,a0
    80003c92:	451c                	lw	a5,8(a0)
    80003c94:	00f05f63          	blez	a5,80003cb2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c98:	0541                	addi	a0,a0,16
    80003c9a:	00001097          	auipc	ra,0x1
    80003c9e:	cb2080e7          	jalr	-846(ra) # 8000494c <acquiresleep>
  if(ip->valid == 0){
    80003ca2:	40bc                	lw	a5,64(s1)
    80003ca4:	cf99                	beqz	a5,80003cc2 <ilock+0x40>
}
    80003ca6:	60e2                	ld	ra,24(sp)
    80003ca8:	6442                	ld	s0,16(sp)
    80003caa:	64a2                	ld	s1,8(sp)
    80003cac:	6902                	ld	s2,0(sp)
    80003cae:	6105                	addi	sp,sp,32
    80003cb0:	8082                	ret
    panic("ilock");
    80003cb2:	00005517          	auipc	a0,0x5
    80003cb6:	a1e50513          	addi	a0,a0,-1506 # 800086d0 <syscalls+0x198>
    80003cba:	ffffd097          	auipc	ra,0xffffd
    80003cbe:	884080e7          	jalr	-1916(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cc2:	40dc                	lw	a5,4(s1)
    80003cc4:	0047d79b          	srliw	a5,a5,0x4
    80003cc8:	0001e597          	auipc	a1,0x1e
    80003ccc:	9705a583          	lw	a1,-1680(a1) # 80021638 <sb+0x18>
    80003cd0:	9dbd                	addw	a1,a1,a5
    80003cd2:	4088                	lw	a0,0(s1)
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	7ac080e7          	jalr	1964(ra) # 80003480 <bread>
    80003cdc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cde:	05850593          	addi	a1,a0,88
    80003ce2:	40dc                	lw	a5,4(s1)
    80003ce4:	8bbd                	andi	a5,a5,15
    80003ce6:	079a                	slli	a5,a5,0x6
    80003ce8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cea:	00059783          	lh	a5,0(a1)
    80003cee:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cf2:	00259783          	lh	a5,2(a1)
    80003cf6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cfa:	00459783          	lh	a5,4(a1)
    80003cfe:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d02:	00659783          	lh	a5,6(a1)
    80003d06:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d0a:	459c                	lw	a5,8(a1)
    80003d0c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d0e:	03400613          	li	a2,52
    80003d12:	05b1                	addi	a1,a1,12
    80003d14:	05048513          	addi	a0,s1,80
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	028080e7          	jalr	40(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d20:	854a                	mv	a0,s2
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	88e080e7          	jalr	-1906(ra) # 800035b0 <brelse>
    ip->valid = 1;
    80003d2a:	4785                	li	a5,1
    80003d2c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d2e:	04449783          	lh	a5,68(s1)
    80003d32:	fbb5                	bnez	a5,80003ca6 <ilock+0x24>
      panic("ilock: no type");
    80003d34:	00005517          	auipc	a0,0x5
    80003d38:	9a450513          	addi	a0,a0,-1628 # 800086d8 <syscalls+0x1a0>
    80003d3c:	ffffd097          	auipc	ra,0xffffd
    80003d40:	802080e7          	jalr	-2046(ra) # 8000053e <panic>

0000000080003d44 <iunlock>:
{
    80003d44:	1101                	addi	sp,sp,-32
    80003d46:	ec06                	sd	ra,24(sp)
    80003d48:	e822                	sd	s0,16(sp)
    80003d4a:	e426                	sd	s1,8(sp)
    80003d4c:	e04a                	sd	s2,0(sp)
    80003d4e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d50:	c905                	beqz	a0,80003d80 <iunlock+0x3c>
    80003d52:	84aa                	mv	s1,a0
    80003d54:	01050913          	addi	s2,a0,16
    80003d58:	854a                	mv	a0,s2
    80003d5a:	00001097          	auipc	ra,0x1
    80003d5e:	c8c080e7          	jalr	-884(ra) # 800049e6 <holdingsleep>
    80003d62:	cd19                	beqz	a0,80003d80 <iunlock+0x3c>
    80003d64:	449c                	lw	a5,8(s1)
    80003d66:	00f05d63          	blez	a5,80003d80 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d6a:	854a                	mv	a0,s2
    80003d6c:	00001097          	auipc	ra,0x1
    80003d70:	c36080e7          	jalr	-970(ra) # 800049a2 <releasesleep>
}
    80003d74:	60e2                	ld	ra,24(sp)
    80003d76:	6442                	ld	s0,16(sp)
    80003d78:	64a2                	ld	s1,8(sp)
    80003d7a:	6902                	ld	s2,0(sp)
    80003d7c:	6105                	addi	sp,sp,32
    80003d7e:	8082                	ret
    panic("iunlock");
    80003d80:	00005517          	auipc	a0,0x5
    80003d84:	96850513          	addi	a0,a0,-1688 # 800086e8 <syscalls+0x1b0>
    80003d88:	ffffc097          	auipc	ra,0xffffc
    80003d8c:	7b6080e7          	jalr	1974(ra) # 8000053e <panic>

0000000080003d90 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d90:	7179                	addi	sp,sp,-48
    80003d92:	f406                	sd	ra,40(sp)
    80003d94:	f022                	sd	s0,32(sp)
    80003d96:	ec26                	sd	s1,24(sp)
    80003d98:	e84a                	sd	s2,16(sp)
    80003d9a:	e44e                	sd	s3,8(sp)
    80003d9c:	e052                	sd	s4,0(sp)
    80003d9e:	1800                	addi	s0,sp,48
    80003da0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003da2:	05050493          	addi	s1,a0,80
    80003da6:	08050913          	addi	s2,a0,128
    80003daa:	a021                	j	80003db2 <itrunc+0x22>
    80003dac:	0491                	addi	s1,s1,4
    80003dae:	01248d63          	beq	s1,s2,80003dc8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003db2:	408c                	lw	a1,0(s1)
    80003db4:	dde5                	beqz	a1,80003dac <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003db6:	0009a503          	lw	a0,0(s3)
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	90c080e7          	jalr	-1780(ra) # 800036c6 <bfree>
      ip->addrs[i] = 0;
    80003dc2:	0004a023          	sw	zero,0(s1)
    80003dc6:	b7dd                	j	80003dac <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dc8:	0809a583          	lw	a1,128(s3)
    80003dcc:	e185                	bnez	a1,80003dec <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dce:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dd2:	854e                	mv	a0,s3
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	de4080e7          	jalr	-540(ra) # 80003bb8 <iupdate>
}
    80003ddc:	70a2                	ld	ra,40(sp)
    80003dde:	7402                	ld	s0,32(sp)
    80003de0:	64e2                	ld	s1,24(sp)
    80003de2:	6942                	ld	s2,16(sp)
    80003de4:	69a2                	ld	s3,8(sp)
    80003de6:	6a02                	ld	s4,0(sp)
    80003de8:	6145                	addi	sp,sp,48
    80003dea:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dec:	0009a503          	lw	a0,0(s3)
    80003df0:	fffff097          	auipc	ra,0xfffff
    80003df4:	690080e7          	jalr	1680(ra) # 80003480 <bread>
    80003df8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dfa:	05850493          	addi	s1,a0,88
    80003dfe:	45850913          	addi	s2,a0,1112
    80003e02:	a811                	j	80003e16 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e04:	0009a503          	lw	a0,0(s3)
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	8be080e7          	jalr	-1858(ra) # 800036c6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e10:	0491                	addi	s1,s1,4
    80003e12:	01248563          	beq	s1,s2,80003e1c <itrunc+0x8c>
      if(a[j])
    80003e16:	408c                	lw	a1,0(s1)
    80003e18:	dde5                	beqz	a1,80003e10 <itrunc+0x80>
    80003e1a:	b7ed                	j	80003e04 <itrunc+0x74>
    brelse(bp);
    80003e1c:	8552                	mv	a0,s4
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	792080e7          	jalr	1938(ra) # 800035b0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e26:	0809a583          	lw	a1,128(s3)
    80003e2a:	0009a503          	lw	a0,0(s3)
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	898080e7          	jalr	-1896(ra) # 800036c6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e36:	0809a023          	sw	zero,128(s3)
    80003e3a:	bf51                	j	80003dce <itrunc+0x3e>

0000000080003e3c <iput>:
{
    80003e3c:	1101                	addi	sp,sp,-32
    80003e3e:	ec06                	sd	ra,24(sp)
    80003e40:	e822                	sd	s0,16(sp)
    80003e42:	e426                	sd	s1,8(sp)
    80003e44:	e04a                	sd	s2,0(sp)
    80003e46:	1000                	addi	s0,sp,32
    80003e48:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e4a:	0001d517          	auipc	a0,0x1d
    80003e4e:	7f650513          	addi	a0,a0,2038 # 80021640 <itable>
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	d92080e7          	jalr	-622(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e5a:	4498                	lw	a4,8(s1)
    80003e5c:	4785                	li	a5,1
    80003e5e:	02f70363          	beq	a4,a5,80003e84 <iput+0x48>
  ip->ref--;
    80003e62:	449c                	lw	a5,8(s1)
    80003e64:	37fd                	addiw	a5,a5,-1
    80003e66:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e68:	0001d517          	auipc	a0,0x1d
    80003e6c:	7d850513          	addi	a0,a0,2008 # 80021640 <itable>
    80003e70:	ffffd097          	auipc	ra,0xffffd
    80003e74:	e28080e7          	jalr	-472(ra) # 80000c98 <release>
}
    80003e78:	60e2                	ld	ra,24(sp)
    80003e7a:	6442                	ld	s0,16(sp)
    80003e7c:	64a2                	ld	s1,8(sp)
    80003e7e:	6902                	ld	s2,0(sp)
    80003e80:	6105                	addi	sp,sp,32
    80003e82:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e84:	40bc                	lw	a5,64(s1)
    80003e86:	dff1                	beqz	a5,80003e62 <iput+0x26>
    80003e88:	04a49783          	lh	a5,74(s1)
    80003e8c:	fbf9                	bnez	a5,80003e62 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e8e:	01048913          	addi	s2,s1,16
    80003e92:	854a                	mv	a0,s2
    80003e94:	00001097          	auipc	ra,0x1
    80003e98:	ab8080e7          	jalr	-1352(ra) # 8000494c <acquiresleep>
    release(&itable.lock);
    80003e9c:	0001d517          	auipc	a0,0x1d
    80003ea0:	7a450513          	addi	a0,a0,1956 # 80021640 <itable>
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	df4080e7          	jalr	-524(ra) # 80000c98 <release>
    itrunc(ip);
    80003eac:	8526                	mv	a0,s1
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	ee2080e7          	jalr	-286(ra) # 80003d90 <itrunc>
    ip->type = 0;
    80003eb6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003eba:	8526                	mv	a0,s1
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	cfc080e7          	jalr	-772(ra) # 80003bb8 <iupdate>
    ip->valid = 0;
    80003ec4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00001097          	auipc	ra,0x1
    80003ece:	ad8080e7          	jalr	-1320(ra) # 800049a2 <releasesleep>
    acquire(&itable.lock);
    80003ed2:	0001d517          	auipc	a0,0x1d
    80003ed6:	76e50513          	addi	a0,a0,1902 # 80021640 <itable>
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	d0a080e7          	jalr	-758(ra) # 80000be4 <acquire>
    80003ee2:	b741                	j	80003e62 <iput+0x26>

0000000080003ee4 <iunlockput>:
{
    80003ee4:	1101                	addi	sp,sp,-32
    80003ee6:	ec06                	sd	ra,24(sp)
    80003ee8:	e822                	sd	s0,16(sp)
    80003eea:	e426                	sd	s1,8(sp)
    80003eec:	1000                	addi	s0,sp,32
    80003eee:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	e54080e7          	jalr	-428(ra) # 80003d44 <iunlock>
  iput(ip);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	f42080e7          	jalr	-190(ra) # 80003e3c <iput>
}
    80003f02:	60e2                	ld	ra,24(sp)
    80003f04:	6442                	ld	s0,16(sp)
    80003f06:	64a2                	ld	s1,8(sp)
    80003f08:	6105                	addi	sp,sp,32
    80003f0a:	8082                	ret

0000000080003f0c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f0c:	1141                	addi	sp,sp,-16
    80003f0e:	e422                	sd	s0,8(sp)
    80003f10:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f12:	411c                	lw	a5,0(a0)
    80003f14:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f16:	415c                	lw	a5,4(a0)
    80003f18:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f1a:	04451783          	lh	a5,68(a0)
    80003f1e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f22:	04a51783          	lh	a5,74(a0)
    80003f26:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f2a:	04c56783          	lwu	a5,76(a0)
    80003f2e:	e99c                	sd	a5,16(a1)
}
    80003f30:	6422                	ld	s0,8(sp)
    80003f32:	0141                	addi	sp,sp,16
    80003f34:	8082                	ret

0000000080003f36 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f36:	457c                	lw	a5,76(a0)
    80003f38:	0ed7e963          	bltu	a5,a3,8000402a <readi+0xf4>
{
    80003f3c:	7159                	addi	sp,sp,-112
    80003f3e:	f486                	sd	ra,104(sp)
    80003f40:	f0a2                	sd	s0,96(sp)
    80003f42:	eca6                	sd	s1,88(sp)
    80003f44:	e8ca                	sd	s2,80(sp)
    80003f46:	e4ce                	sd	s3,72(sp)
    80003f48:	e0d2                	sd	s4,64(sp)
    80003f4a:	fc56                	sd	s5,56(sp)
    80003f4c:	f85a                	sd	s6,48(sp)
    80003f4e:	f45e                	sd	s7,40(sp)
    80003f50:	f062                	sd	s8,32(sp)
    80003f52:	ec66                	sd	s9,24(sp)
    80003f54:	e86a                	sd	s10,16(sp)
    80003f56:	e46e                	sd	s11,8(sp)
    80003f58:	1880                	addi	s0,sp,112
    80003f5a:	8baa                	mv	s7,a0
    80003f5c:	8c2e                	mv	s8,a1
    80003f5e:	8ab2                	mv	s5,a2
    80003f60:	84b6                	mv	s1,a3
    80003f62:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f64:	9f35                	addw	a4,a4,a3
    return 0;
    80003f66:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f68:	0ad76063          	bltu	a4,a3,80004008 <readi+0xd2>
  if(off + n > ip->size)
    80003f6c:	00e7f463          	bgeu	a5,a4,80003f74 <readi+0x3e>
    n = ip->size - off;
    80003f70:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f74:	0a0b0963          	beqz	s6,80004026 <readi+0xf0>
    80003f78:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f7a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f7e:	5cfd                	li	s9,-1
    80003f80:	a82d                	j	80003fba <readi+0x84>
    80003f82:	020a1d93          	slli	s11,s4,0x20
    80003f86:	020ddd93          	srli	s11,s11,0x20
    80003f8a:	05890613          	addi	a2,s2,88
    80003f8e:	86ee                	mv	a3,s11
    80003f90:	963a                	add	a2,a2,a4
    80003f92:	85d6                	mv	a1,s5
    80003f94:	8562                	mv	a0,s8
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	830080e7          	jalr	-2000(ra) # 800027c6 <either_copyout>
    80003f9e:	05950d63          	beq	a0,s9,80003ff8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fa2:	854a                	mv	a0,s2
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	60c080e7          	jalr	1548(ra) # 800035b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fac:	013a09bb          	addw	s3,s4,s3
    80003fb0:	009a04bb          	addw	s1,s4,s1
    80003fb4:	9aee                	add	s5,s5,s11
    80003fb6:	0569f763          	bgeu	s3,s6,80004004 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fba:	000ba903          	lw	s2,0(s7)
    80003fbe:	00a4d59b          	srliw	a1,s1,0xa
    80003fc2:	855e                	mv	a0,s7
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	8b0080e7          	jalr	-1872(ra) # 80003874 <bmap>
    80003fcc:	0005059b          	sext.w	a1,a0
    80003fd0:	854a                	mv	a0,s2
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	4ae080e7          	jalr	1198(ra) # 80003480 <bread>
    80003fda:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fdc:	3ff4f713          	andi	a4,s1,1023
    80003fe0:	40ed07bb          	subw	a5,s10,a4
    80003fe4:	413b06bb          	subw	a3,s6,s3
    80003fe8:	8a3e                	mv	s4,a5
    80003fea:	2781                	sext.w	a5,a5
    80003fec:	0006861b          	sext.w	a2,a3
    80003ff0:	f8f679e3          	bgeu	a2,a5,80003f82 <readi+0x4c>
    80003ff4:	8a36                	mv	s4,a3
    80003ff6:	b771                	j	80003f82 <readi+0x4c>
      brelse(bp);
    80003ff8:	854a                	mv	a0,s2
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	5b6080e7          	jalr	1462(ra) # 800035b0 <brelse>
      tot = -1;
    80004002:	59fd                	li	s3,-1
  }
  return tot;
    80004004:	0009851b          	sext.w	a0,s3
}
    80004008:	70a6                	ld	ra,104(sp)
    8000400a:	7406                	ld	s0,96(sp)
    8000400c:	64e6                	ld	s1,88(sp)
    8000400e:	6946                	ld	s2,80(sp)
    80004010:	69a6                	ld	s3,72(sp)
    80004012:	6a06                	ld	s4,64(sp)
    80004014:	7ae2                	ld	s5,56(sp)
    80004016:	7b42                	ld	s6,48(sp)
    80004018:	7ba2                	ld	s7,40(sp)
    8000401a:	7c02                	ld	s8,32(sp)
    8000401c:	6ce2                	ld	s9,24(sp)
    8000401e:	6d42                	ld	s10,16(sp)
    80004020:	6da2                	ld	s11,8(sp)
    80004022:	6165                	addi	sp,sp,112
    80004024:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004026:	89da                	mv	s3,s6
    80004028:	bff1                	j	80004004 <readi+0xce>
    return 0;
    8000402a:	4501                	li	a0,0
}
    8000402c:	8082                	ret

000000008000402e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000402e:	457c                	lw	a5,76(a0)
    80004030:	10d7e863          	bltu	a5,a3,80004140 <writei+0x112>
{
    80004034:	7159                	addi	sp,sp,-112
    80004036:	f486                	sd	ra,104(sp)
    80004038:	f0a2                	sd	s0,96(sp)
    8000403a:	eca6                	sd	s1,88(sp)
    8000403c:	e8ca                	sd	s2,80(sp)
    8000403e:	e4ce                	sd	s3,72(sp)
    80004040:	e0d2                	sd	s4,64(sp)
    80004042:	fc56                	sd	s5,56(sp)
    80004044:	f85a                	sd	s6,48(sp)
    80004046:	f45e                	sd	s7,40(sp)
    80004048:	f062                	sd	s8,32(sp)
    8000404a:	ec66                	sd	s9,24(sp)
    8000404c:	e86a                	sd	s10,16(sp)
    8000404e:	e46e                	sd	s11,8(sp)
    80004050:	1880                	addi	s0,sp,112
    80004052:	8b2a                	mv	s6,a0
    80004054:	8c2e                	mv	s8,a1
    80004056:	8ab2                	mv	s5,a2
    80004058:	8936                	mv	s2,a3
    8000405a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000405c:	00e687bb          	addw	a5,a3,a4
    80004060:	0ed7e263          	bltu	a5,a3,80004144 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004064:	00043737          	lui	a4,0x43
    80004068:	0ef76063          	bltu	a4,a5,80004148 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000406c:	0c0b8863          	beqz	s7,8000413c <writei+0x10e>
    80004070:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004072:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004076:	5cfd                	li	s9,-1
    80004078:	a091                	j	800040bc <writei+0x8e>
    8000407a:	02099d93          	slli	s11,s3,0x20
    8000407e:	020ddd93          	srli	s11,s11,0x20
    80004082:	05848513          	addi	a0,s1,88
    80004086:	86ee                	mv	a3,s11
    80004088:	8656                	mv	a2,s5
    8000408a:	85e2                	mv	a1,s8
    8000408c:	953a                	add	a0,a0,a4
    8000408e:	ffffe097          	auipc	ra,0xffffe
    80004092:	78e080e7          	jalr	1934(ra) # 8000281c <either_copyin>
    80004096:	07950263          	beq	a0,s9,800040fa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000409a:	8526                	mv	a0,s1
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	790080e7          	jalr	1936(ra) # 8000482c <log_write>
    brelse(bp);
    800040a4:	8526                	mv	a0,s1
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	50a080e7          	jalr	1290(ra) # 800035b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ae:	01498a3b          	addw	s4,s3,s4
    800040b2:	0129893b          	addw	s2,s3,s2
    800040b6:	9aee                	add	s5,s5,s11
    800040b8:	057a7663          	bgeu	s4,s7,80004104 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040bc:	000b2483          	lw	s1,0(s6)
    800040c0:	00a9559b          	srliw	a1,s2,0xa
    800040c4:	855a                	mv	a0,s6
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	7ae080e7          	jalr	1966(ra) # 80003874 <bmap>
    800040ce:	0005059b          	sext.w	a1,a0
    800040d2:	8526                	mv	a0,s1
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	3ac080e7          	jalr	940(ra) # 80003480 <bread>
    800040dc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040de:	3ff97713          	andi	a4,s2,1023
    800040e2:	40ed07bb          	subw	a5,s10,a4
    800040e6:	414b86bb          	subw	a3,s7,s4
    800040ea:	89be                	mv	s3,a5
    800040ec:	2781                	sext.w	a5,a5
    800040ee:	0006861b          	sext.w	a2,a3
    800040f2:	f8f674e3          	bgeu	a2,a5,8000407a <writei+0x4c>
    800040f6:	89b6                	mv	s3,a3
    800040f8:	b749                	j	8000407a <writei+0x4c>
      brelse(bp);
    800040fa:	8526                	mv	a0,s1
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	4b4080e7          	jalr	1204(ra) # 800035b0 <brelse>
  }

  if(off > ip->size)
    80004104:	04cb2783          	lw	a5,76(s6)
    80004108:	0127f463          	bgeu	a5,s2,80004110 <writei+0xe2>
    ip->size = off;
    8000410c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004110:	855a                	mv	a0,s6
    80004112:	00000097          	auipc	ra,0x0
    80004116:	aa6080e7          	jalr	-1370(ra) # 80003bb8 <iupdate>

  return tot;
    8000411a:	000a051b          	sext.w	a0,s4
}
    8000411e:	70a6                	ld	ra,104(sp)
    80004120:	7406                	ld	s0,96(sp)
    80004122:	64e6                	ld	s1,88(sp)
    80004124:	6946                	ld	s2,80(sp)
    80004126:	69a6                	ld	s3,72(sp)
    80004128:	6a06                	ld	s4,64(sp)
    8000412a:	7ae2                	ld	s5,56(sp)
    8000412c:	7b42                	ld	s6,48(sp)
    8000412e:	7ba2                	ld	s7,40(sp)
    80004130:	7c02                	ld	s8,32(sp)
    80004132:	6ce2                	ld	s9,24(sp)
    80004134:	6d42                	ld	s10,16(sp)
    80004136:	6da2                	ld	s11,8(sp)
    80004138:	6165                	addi	sp,sp,112
    8000413a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000413c:	8a5e                	mv	s4,s7
    8000413e:	bfc9                	j	80004110 <writei+0xe2>
    return -1;
    80004140:	557d                	li	a0,-1
}
    80004142:	8082                	ret
    return -1;
    80004144:	557d                	li	a0,-1
    80004146:	bfe1                	j	8000411e <writei+0xf0>
    return -1;
    80004148:	557d                	li	a0,-1
    8000414a:	bfd1                	j	8000411e <writei+0xf0>

000000008000414c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000414c:	1141                	addi	sp,sp,-16
    8000414e:	e406                	sd	ra,8(sp)
    80004150:	e022                	sd	s0,0(sp)
    80004152:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004154:	4639                	li	a2,14
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	c62080e7          	jalr	-926(ra) # 80000db8 <strncmp>
}
    8000415e:	60a2                	ld	ra,8(sp)
    80004160:	6402                	ld	s0,0(sp)
    80004162:	0141                	addi	sp,sp,16
    80004164:	8082                	ret

0000000080004166 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004166:	7139                	addi	sp,sp,-64
    80004168:	fc06                	sd	ra,56(sp)
    8000416a:	f822                	sd	s0,48(sp)
    8000416c:	f426                	sd	s1,40(sp)
    8000416e:	f04a                	sd	s2,32(sp)
    80004170:	ec4e                	sd	s3,24(sp)
    80004172:	e852                	sd	s4,16(sp)
    80004174:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004176:	04451703          	lh	a4,68(a0)
    8000417a:	4785                	li	a5,1
    8000417c:	00f71a63          	bne	a4,a5,80004190 <dirlookup+0x2a>
    80004180:	892a                	mv	s2,a0
    80004182:	89ae                	mv	s3,a1
    80004184:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004186:	457c                	lw	a5,76(a0)
    80004188:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000418a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418c:	e79d                	bnez	a5,800041ba <dirlookup+0x54>
    8000418e:	a8a5                	j	80004206 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004190:	00004517          	auipc	a0,0x4
    80004194:	56050513          	addi	a0,a0,1376 # 800086f0 <syscalls+0x1b8>
    80004198:	ffffc097          	auipc	ra,0xffffc
    8000419c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
      panic("dirlookup read");
    800041a0:	00004517          	auipc	a0,0x4
    800041a4:	56850513          	addi	a0,a0,1384 # 80008708 <syscalls+0x1d0>
    800041a8:	ffffc097          	auipc	ra,0xffffc
    800041ac:	396080e7          	jalr	918(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b0:	24c1                	addiw	s1,s1,16
    800041b2:	04c92783          	lw	a5,76(s2)
    800041b6:	04f4f763          	bgeu	s1,a5,80004204 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ba:	4741                	li	a4,16
    800041bc:	86a6                	mv	a3,s1
    800041be:	fc040613          	addi	a2,s0,-64
    800041c2:	4581                	li	a1,0
    800041c4:	854a                	mv	a0,s2
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	d70080e7          	jalr	-656(ra) # 80003f36 <readi>
    800041ce:	47c1                	li	a5,16
    800041d0:	fcf518e3          	bne	a0,a5,800041a0 <dirlookup+0x3a>
    if(de.inum == 0)
    800041d4:	fc045783          	lhu	a5,-64(s0)
    800041d8:	dfe1                	beqz	a5,800041b0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041da:	fc240593          	addi	a1,s0,-62
    800041de:	854e                	mv	a0,s3
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	f6c080e7          	jalr	-148(ra) # 8000414c <namecmp>
    800041e8:	f561                	bnez	a0,800041b0 <dirlookup+0x4a>
      if(poff)
    800041ea:	000a0463          	beqz	s4,800041f2 <dirlookup+0x8c>
        *poff = off;
    800041ee:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041f2:	fc045583          	lhu	a1,-64(s0)
    800041f6:	00092503          	lw	a0,0(s2)
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	754080e7          	jalr	1876(ra) # 8000394e <iget>
    80004202:	a011                	j	80004206 <dirlookup+0xa0>
  return 0;
    80004204:	4501                	li	a0,0
}
    80004206:	70e2                	ld	ra,56(sp)
    80004208:	7442                	ld	s0,48(sp)
    8000420a:	74a2                	ld	s1,40(sp)
    8000420c:	7902                	ld	s2,32(sp)
    8000420e:	69e2                	ld	s3,24(sp)
    80004210:	6a42                	ld	s4,16(sp)
    80004212:	6121                	addi	sp,sp,64
    80004214:	8082                	ret

0000000080004216 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004216:	711d                	addi	sp,sp,-96
    80004218:	ec86                	sd	ra,88(sp)
    8000421a:	e8a2                	sd	s0,80(sp)
    8000421c:	e4a6                	sd	s1,72(sp)
    8000421e:	e0ca                	sd	s2,64(sp)
    80004220:	fc4e                	sd	s3,56(sp)
    80004222:	f852                	sd	s4,48(sp)
    80004224:	f456                	sd	s5,40(sp)
    80004226:	f05a                	sd	s6,32(sp)
    80004228:	ec5e                	sd	s7,24(sp)
    8000422a:	e862                	sd	s8,16(sp)
    8000422c:	e466                	sd	s9,8(sp)
    8000422e:	1080                	addi	s0,sp,96
    80004230:	84aa                	mv	s1,a0
    80004232:	8b2e                	mv	s6,a1
    80004234:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004236:	00054703          	lbu	a4,0(a0)
    8000423a:	02f00793          	li	a5,47
    8000423e:	02f70363          	beq	a4,a5,80004264 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004242:	ffffe097          	auipc	ra,0xffffe
    80004246:	894080e7          	jalr	-1900(ra) # 80001ad6 <myproc>
    8000424a:	15053503          	ld	a0,336(a0)
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	9f6080e7          	jalr	-1546(ra) # 80003c44 <idup>
    80004256:	89aa                	mv	s3,a0
  while(*path == '/')
    80004258:	02f00913          	li	s2,47
  len = path - s;
    8000425c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000425e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004260:	4c05                	li	s8,1
    80004262:	a865                	j	8000431a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004264:	4585                	li	a1,1
    80004266:	4505                	li	a0,1
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	6e6080e7          	jalr	1766(ra) # 8000394e <iget>
    80004270:	89aa                	mv	s3,a0
    80004272:	b7dd                	j	80004258 <namex+0x42>
      iunlockput(ip);
    80004274:	854e                	mv	a0,s3
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	c6e080e7          	jalr	-914(ra) # 80003ee4 <iunlockput>
      return 0;
    8000427e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004280:	854e                	mv	a0,s3
    80004282:	60e6                	ld	ra,88(sp)
    80004284:	6446                	ld	s0,80(sp)
    80004286:	64a6                	ld	s1,72(sp)
    80004288:	6906                	ld	s2,64(sp)
    8000428a:	79e2                	ld	s3,56(sp)
    8000428c:	7a42                	ld	s4,48(sp)
    8000428e:	7aa2                	ld	s5,40(sp)
    80004290:	7b02                	ld	s6,32(sp)
    80004292:	6be2                	ld	s7,24(sp)
    80004294:	6c42                	ld	s8,16(sp)
    80004296:	6ca2                	ld	s9,8(sp)
    80004298:	6125                	addi	sp,sp,96
    8000429a:	8082                	ret
      iunlock(ip);
    8000429c:	854e                	mv	a0,s3
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	aa6080e7          	jalr	-1370(ra) # 80003d44 <iunlock>
      return ip;
    800042a6:	bfe9                	j	80004280 <namex+0x6a>
      iunlockput(ip);
    800042a8:	854e                	mv	a0,s3
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	c3a080e7          	jalr	-966(ra) # 80003ee4 <iunlockput>
      return 0;
    800042b2:	89d2                	mv	s3,s4
    800042b4:	b7f1                	j	80004280 <namex+0x6a>
  len = path - s;
    800042b6:	40b48633          	sub	a2,s1,a1
    800042ba:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042be:	094cd463          	bge	s9,s4,80004346 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042c2:	4639                	li	a2,14
    800042c4:	8556                	mv	a0,s5
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	a7a080e7          	jalr	-1414(ra) # 80000d40 <memmove>
  while(*path == '/')
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	01279763          	bne	a5,s2,800042e0 <namex+0xca>
    path++;
    800042d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042d8:	0004c783          	lbu	a5,0(s1)
    800042dc:	ff278de3          	beq	a5,s2,800042d6 <namex+0xc0>
    ilock(ip);
    800042e0:	854e                	mv	a0,s3
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	9a0080e7          	jalr	-1632(ra) # 80003c82 <ilock>
    if(ip->type != T_DIR){
    800042ea:	04499783          	lh	a5,68(s3)
    800042ee:	f98793e3          	bne	a5,s8,80004274 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042f2:	000b0563          	beqz	s6,800042fc <namex+0xe6>
    800042f6:	0004c783          	lbu	a5,0(s1)
    800042fa:	d3cd                	beqz	a5,8000429c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042fc:	865e                	mv	a2,s7
    800042fe:	85d6                	mv	a1,s5
    80004300:	854e                	mv	a0,s3
    80004302:	00000097          	auipc	ra,0x0
    80004306:	e64080e7          	jalr	-412(ra) # 80004166 <dirlookup>
    8000430a:	8a2a                	mv	s4,a0
    8000430c:	dd51                	beqz	a0,800042a8 <namex+0x92>
    iunlockput(ip);
    8000430e:	854e                	mv	a0,s3
    80004310:	00000097          	auipc	ra,0x0
    80004314:	bd4080e7          	jalr	-1068(ra) # 80003ee4 <iunlockput>
    ip = next;
    80004318:	89d2                	mv	s3,s4
  while(*path == '/')
    8000431a:	0004c783          	lbu	a5,0(s1)
    8000431e:	05279763          	bne	a5,s2,8000436c <namex+0x156>
    path++;
    80004322:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004324:	0004c783          	lbu	a5,0(s1)
    80004328:	ff278de3          	beq	a5,s2,80004322 <namex+0x10c>
  if(*path == 0)
    8000432c:	c79d                	beqz	a5,8000435a <namex+0x144>
    path++;
    8000432e:	85a6                	mv	a1,s1
  len = path - s;
    80004330:	8a5e                	mv	s4,s7
    80004332:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004334:	01278963          	beq	a5,s2,80004346 <namex+0x130>
    80004338:	dfbd                	beqz	a5,800042b6 <namex+0xa0>
    path++;
    8000433a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000433c:	0004c783          	lbu	a5,0(s1)
    80004340:	ff279ce3          	bne	a5,s2,80004338 <namex+0x122>
    80004344:	bf8d                	j	800042b6 <namex+0xa0>
    memmove(name, s, len);
    80004346:	2601                	sext.w	a2,a2
    80004348:	8556                	mv	a0,s5
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	9f6080e7          	jalr	-1546(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004352:	9a56                	add	s4,s4,s5
    80004354:	000a0023          	sb	zero,0(s4)
    80004358:	bf9d                	j	800042ce <namex+0xb8>
  if(nameiparent){
    8000435a:	f20b03e3          	beqz	s6,80004280 <namex+0x6a>
    iput(ip);
    8000435e:	854e                	mv	a0,s3
    80004360:	00000097          	auipc	ra,0x0
    80004364:	adc080e7          	jalr	-1316(ra) # 80003e3c <iput>
    return 0;
    80004368:	4981                	li	s3,0
    8000436a:	bf19                	j	80004280 <namex+0x6a>
  if(*path == 0)
    8000436c:	d7fd                	beqz	a5,8000435a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000436e:	0004c783          	lbu	a5,0(s1)
    80004372:	85a6                	mv	a1,s1
    80004374:	b7d1                	j	80004338 <namex+0x122>

0000000080004376 <dirlink>:
{
    80004376:	7139                	addi	sp,sp,-64
    80004378:	fc06                	sd	ra,56(sp)
    8000437a:	f822                	sd	s0,48(sp)
    8000437c:	f426                	sd	s1,40(sp)
    8000437e:	f04a                	sd	s2,32(sp)
    80004380:	ec4e                	sd	s3,24(sp)
    80004382:	e852                	sd	s4,16(sp)
    80004384:	0080                	addi	s0,sp,64
    80004386:	892a                	mv	s2,a0
    80004388:	8a2e                	mv	s4,a1
    8000438a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000438c:	4601                	li	a2,0
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	dd8080e7          	jalr	-552(ra) # 80004166 <dirlookup>
    80004396:	e93d                	bnez	a0,8000440c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004398:	04c92483          	lw	s1,76(s2)
    8000439c:	c49d                	beqz	s1,800043ca <dirlink+0x54>
    8000439e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043a0:	4741                	li	a4,16
    800043a2:	86a6                	mv	a3,s1
    800043a4:	fc040613          	addi	a2,s0,-64
    800043a8:	4581                	li	a1,0
    800043aa:	854a                	mv	a0,s2
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	b8a080e7          	jalr	-1142(ra) # 80003f36 <readi>
    800043b4:	47c1                	li	a5,16
    800043b6:	06f51163          	bne	a0,a5,80004418 <dirlink+0xa2>
    if(de.inum == 0)
    800043ba:	fc045783          	lhu	a5,-64(s0)
    800043be:	c791                	beqz	a5,800043ca <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c0:	24c1                	addiw	s1,s1,16
    800043c2:	04c92783          	lw	a5,76(s2)
    800043c6:	fcf4ede3          	bltu	s1,a5,800043a0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043ca:	4639                	li	a2,14
    800043cc:	85d2                	mv	a1,s4
    800043ce:	fc240513          	addi	a0,s0,-62
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	a22080e7          	jalr	-1502(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800043da:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043de:	4741                	li	a4,16
    800043e0:	86a6                	mv	a3,s1
    800043e2:	fc040613          	addi	a2,s0,-64
    800043e6:	4581                	li	a1,0
    800043e8:	854a                	mv	a0,s2
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	c44080e7          	jalr	-956(ra) # 8000402e <writei>
    800043f2:	872a                	mv	a4,a0
    800043f4:	47c1                	li	a5,16
  return 0;
    800043f6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043f8:	02f71863          	bne	a4,a5,80004428 <dirlink+0xb2>
}
    800043fc:	70e2                	ld	ra,56(sp)
    800043fe:	7442                	ld	s0,48(sp)
    80004400:	74a2                	ld	s1,40(sp)
    80004402:	7902                	ld	s2,32(sp)
    80004404:	69e2                	ld	s3,24(sp)
    80004406:	6a42                	ld	s4,16(sp)
    80004408:	6121                	addi	sp,sp,64
    8000440a:	8082                	ret
    iput(ip);
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	a30080e7          	jalr	-1488(ra) # 80003e3c <iput>
    return -1;
    80004414:	557d                	li	a0,-1
    80004416:	b7dd                	j	800043fc <dirlink+0x86>
      panic("dirlink read");
    80004418:	00004517          	auipc	a0,0x4
    8000441c:	30050513          	addi	a0,a0,768 # 80008718 <syscalls+0x1e0>
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	11e080e7          	jalr	286(ra) # 8000053e <panic>
    panic("dirlink");
    80004428:	00004517          	auipc	a0,0x4
    8000442c:	3f850513          	addi	a0,a0,1016 # 80008820 <syscalls+0x2e8>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	10e080e7          	jalr	270(ra) # 8000053e <panic>

0000000080004438 <namei>:

struct inode*
namei(char *path)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004440:	fe040613          	addi	a2,s0,-32
    80004444:	4581                	li	a1,0
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	dd0080e7          	jalr	-560(ra) # 80004216 <namex>
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	6105                	addi	sp,sp,32
    80004454:	8082                	ret

0000000080004456 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004456:	1141                	addi	sp,sp,-16
    80004458:	e406                	sd	ra,8(sp)
    8000445a:	e022                	sd	s0,0(sp)
    8000445c:	0800                	addi	s0,sp,16
    8000445e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004460:	4585                	li	a1,1
    80004462:	00000097          	auipc	ra,0x0
    80004466:	db4080e7          	jalr	-588(ra) # 80004216 <namex>
}
    8000446a:	60a2                	ld	ra,8(sp)
    8000446c:	6402                	ld	s0,0(sp)
    8000446e:	0141                	addi	sp,sp,16
    80004470:	8082                	ret

0000000080004472 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004472:	1101                	addi	sp,sp,-32
    80004474:	ec06                	sd	ra,24(sp)
    80004476:	e822                	sd	s0,16(sp)
    80004478:	e426                	sd	s1,8(sp)
    8000447a:	e04a                	sd	s2,0(sp)
    8000447c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000447e:	0001f917          	auipc	s2,0x1f
    80004482:	c6a90913          	addi	s2,s2,-918 # 800230e8 <log>
    80004486:	01892583          	lw	a1,24(s2)
    8000448a:	02892503          	lw	a0,40(s2)
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	ff2080e7          	jalr	-14(ra) # 80003480 <bread>
    80004496:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004498:	02c92683          	lw	a3,44(s2)
    8000449c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000449e:	02d05763          	blez	a3,800044cc <write_head+0x5a>
    800044a2:	0001f797          	auipc	a5,0x1f
    800044a6:	c7678793          	addi	a5,a5,-906 # 80023118 <log+0x30>
    800044aa:	05c50713          	addi	a4,a0,92
    800044ae:	36fd                	addiw	a3,a3,-1
    800044b0:	1682                	slli	a3,a3,0x20
    800044b2:	9281                	srli	a3,a3,0x20
    800044b4:	068a                	slli	a3,a3,0x2
    800044b6:	0001f617          	auipc	a2,0x1f
    800044ba:	c6660613          	addi	a2,a2,-922 # 8002311c <log+0x34>
    800044be:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044c0:	4390                	lw	a2,0(a5)
    800044c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044c4:	0791                	addi	a5,a5,4
    800044c6:	0711                	addi	a4,a4,4
    800044c8:	fed79ce3          	bne	a5,a3,800044c0 <write_head+0x4e>
  }
  bwrite(buf);
    800044cc:	8526                	mv	a0,s1
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	0a4080e7          	jalr	164(ra) # 80003572 <bwrite>
  brelse(buf);
    800044d6:	8526                	mv	a0,s1
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	0d8080e7          	jalr	216(ra) # 800035b0 <brelse>
}
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	64a2                	ld	s1,8(sp)
    800044e6:	6902                	ld	s2,0(sp)
    800044e8:	6105                	addi	sp,sp,32
    800044ea:	8082                	ret

00000000800044ec <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ec:	0001f797          	auipc	a5,0x1f
    800044f0:	c287a783          	lw	a5,-984(a5) # 80023114 <log+0x2c>
    800044f4:	0af05d63          	blez	a5,800045ae <install_trans+0xc2>
{
    800044f8:	7139                	addi	sp,sp,-64
    800044fa:	fc06                	sd	ra,56(sp)
    800044fc:	f822                	sd	s0,48(sp)
    800044fe:	f426                	sd	s1,40(sp)
    80004500:	f04a                	sd	s2,32(sp)
    80004502:	ec4e                	sd	s3,24(sp)
    80004504:	e852                	sd	s4,16(sp)
    80004506:	e456                	sd	s5,8(sp)
    80004508:	e05a                	sd	s6,0(sp)
    8000450a:	0080                	addi	s0,sp,64
    8000450c:	8b2a                	mv	s6,a0
    8000450e:	0001fa97          	auipc	s5,0x1f
    80004512:	c0aa8a93          	addi	s5,s5,-1014 # 80023118 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004516:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004518:	0001f997          	auipc	s3,0x1f
    8000451c:	bd098993          	addi	s3,s3,-1072 # 800230e8 <log>
    80004520:	a035                	j	8000454c <install_trans+0x60>
      bunpin(dbuf);
    80004522:	8526                	mv	a0,s1
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	166080e7          	jalr	358(ra) # 8000368a <bunpin>
    brelse(lbuf);
    8000452c:	854a                	mv	a0,s2
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	082080e7          	jalr	130(ra) # 800035b0 <brelse>
    brelse(dbuf);
    80004536:	8526                	mv	a0,s1
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	078080e7          	jalr	120(ra) # 800035b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004540:	2a05                	addiw	s4,s4,1
    80004542:	0a91                	addi	s5,s5,4
    80004544:	02c9a783          	lw	a5,44(s3)
    80004548:	04fa5963          	bge	s4,a5,8000459a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000454c:	0189a583          	lw	a1,24(s3)
    80004550:	014585bb          	addw	a1,a1,s4
    80004554:	2585                	addiw	a1,a1,1
    80004556:	0289a503          	lw	a0,40(s3)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	f26080e7          	jalr	-218(ra) # 80003480 <bread>
    80004562:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004564:	000aa583          	lw	a1,0(s5)
    80004568:	0289a503          	lw	a0,40(s3)
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	f14080e7          	jalr	-236(ra) # 80003480 <bread>
    80004574:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004576:	40000613          	li	a2,1024
    8000457a:	05890593          	addi	a1,s2,88
    8000457e:	05850513          	addi	a0,a0,88
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	7be080e7          	jalr	1982(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000458a:	8526                	mv	a0,s1
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	fe6080e7          	jalr	-26(ra) # 80003572 <bwrite>
    if(recovering == 0)
    80004594:	f80b1ce3          	bnez	s6,8000452c <install_trans+0x40>
    80004598:	b769                	j	80004522 <install_trans+0x36>
}
    8000459a:	70e2                	ld	ra,56(sp)
    8000459c:	7442                	ld	s0,48(sp)
    8000459e:	74a2                	ld	s1,40(sp)
    800045a0:	7902                	ld	s2,32(sp)
    800045a2:	69e2                	ld	s3,24(sp)
    800045a4:	6a42                	ld	s4,16(sp)
    800045a6:	6aa2                	ld	s5,8(sp)
    800045a8:	6b02                	ld	s6,0(sp)
    800045aa:	6121                	addi	sp,sp,64
    800045ac:	8082                	ret
    800045ae:	8082                	ret

00000000800045b0 <initlog>:
{
    800045b0:	7179                	addi	sp,sp,-48
    800045b2:	f406                	sd	ra,40(sp)
    800045b4:	f022                	sd	s0,32(sp)
    800045b6:	ec26                	sd	s1,24(sp)
    800045b8:	e84a                	sd	s2,16(sp)
    800045ba:	e44e                	sd	s3,8(sp)
    800045bc:	1800                	addi	s0,sp,48
    800045be:	892a                	mv	s2,a0
    800045c0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045c2:	0001f497          	auipc	s1,0x1f
    800045c6:	b2648493          	addi	s1,s1,-1242 # 800230e8 <log>
    800045ca:	00004597          	auipc	a1,0x4
    800045ce:	15e58593          	addi	a1,a1,350 # 80008728 <syscalls+0x1f0>
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	580080e7          	jalr	1408(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800045dc:	0149a583          	lw	a1,20(s3)
    800045e0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045e2:	0109a783          	lw	a5,16(s3)
    800045e6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045e8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045ec:	854a                	mv	a0,s2
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	e92080e7          	jalr	-366(ra) # 80003480 <bread>
  log.lh.n = lh->n;
    800045f6:	4d3c                	lw	a5,88(a0)
    800045f8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045fa:	02f05563          	blez	a5,80004624 <initlog+0x74>
    800045fe:	05c50713          	addi	a4,a0,92
    80004602:	0001f697          	auipc	a3,0x1f
    80004606:	b1668693          	addi	a3,a3,-1258 # 80023118 <log+0x30>
    8000460a:	37fd                	addiw	a5,a5,-1
    8000460c:	1782                	slli	a5,a5,0x20
    8000460e:	9381                	srli	a5,a5,0x20
    80004610:	078a                	slli	a5,a5,0x2
    80004612:	06050613          	addi	a2,a0,96
    80004616:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004618:	4310                	lw	a2,0(a4)
    8000461a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000461c:	0711                	addi	a4,a4,4
    8000461e:	0691                	addi	a3,a3,4
    80004620:	fef71ce3          	bne	a4,a5,80004618 <initlog+0x68>
  brelse(buf);
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	f8c080e7          	jalr	-116(ra) # 800035b0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000462c:	4505                	li	a0,1
    8000462e:	00000097          	auipc	ra,0x0
    80004632:	ebe080e7          	jalr	-322(ra) # 800044ec <install_trans>
  log.lh.n = 0;
    80004636:	0001f797          	auipc	a5,0x1f
    8000463a:	ac07af23          	sw	zero,-1314(a5) # 80023114 <log+0x2c>
  write_head(); // clear the log
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	e34080e7          	jalr	-460(ra) # 80004472 <write_head>
}
    80004646:	70a2                	ld	ra,40(sp)
    80004648:	7402                	ld	s0,32(sp)
    8000464a:	64e2                	ld	s1,24(sp)
    8000464c:	6942                	ld	s2,16(sp)
    8000464e:	69a2                	ld	s3,8(sp)
    80004650:	6145                	addi	sp,sp,48
    80004652:	8082                	ret

0000000080004654 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004654:	1101                	addi	sp,sp,-32
    80004656:	ec06                	sd	ra,24(sp)
    80004658:	e822                	sd	s0,16(sp)
    8000465a:	e426                	sd	s1,8(sp)
    8000465c:	e04a                	sd	s2,0(sp)
    8000465e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004660:	0001f517          	auipc	a0,0x1f
    80004664:	a8850513          	addi	a0,a0,-1400 # 800230e8 <log>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	57c080e7          	jalr	1404(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004670:	0001f497          	auipc	s1,0x1f
    80004674:	a7848493          	addi	s1,s1,-1416 # 800230e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004678:	4979                	li	s2,30
    8000467a:	a039                	j	80004688 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000467c:	85a6                	mv	a1,s1
    8000467e:	8526                	mv	a0,s1
    80004680:	ffffe097          	auipc	ra,0xffffe
    80004684:	c4a080e7          	jalr	-950(ra) # 800022ca <sleep>
    if(log.committing){
    80004688:	50dc                	lw	a5,36(s1)
    8000468a:	fbed                	bnez	a5,8000467c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000468c:	509c                	lw	a5,32(s1)
    8000468e:	0017871b          	addiw	a4,a5,1
    80004692:	0007069b          	sext.w	a3,a4
    80004696:	0027179b          	slliw	a5,a4,0x2
    8000469a:	9fb9                	addw	a5,a5,a4
    8000469c:	0017979b          	slliw	a5,a5,0x1
    800046a0:	54d8                	lw	a4,44(s1)
    800046a2:	9fb9                	addw	a5,a5,a4
    800046a4:	00f95963          	bge	s2,a5,800046b6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046a8:	85a6                	mv	a1,s1
    800046aa:	8526                	mv	a0,s1
    800046ac:	ffffe097          	auipc	ra,0xffffe
    800046b0:	c1e080e7          	jalr	-994(ra) # 800022ca <sleep>
    800046b4:	bfd1                	j	80004688 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046b6:	0001f517          	auipc	a0,0x1f
    800046ba:	a3250513          	addi	a0,a0,-1486 # 800230e8 <log>
    800046be:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
      break;
    }
  }
}
    800046c8:	60e2                	ld	ra,24(sp)
    800046ca:	6442                	ld	s0,16(sp)
    800046cc:	64a2                	ld	s1,8(sp)
    800046ce:	6902                	ld	s2,0(sp)
    800046d0:	6105                	addi	sp,sp,32
    800046d2:	8082                	ret

00000000800046d4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046d4:	7139                	addi	sp,sp,-64
    800046d6:	fc06                	sd	ra,56(sp)
    800046d8:	f822                	sd	s0,48(sp)
    800046da:	f426                	sd	s1,40(sp)
    800046dc:	f04a                	sd	s2,32(sp)
    800046de:	ec4e                	sd	s3,24(sp)
    800046e0:	e852                	sd	s4,16(sp)
    800046e2:	e456                	sd	s5,8(sp)
    800046e4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046e6:	0001f497          	auipc	s1,0x1f
    800046ea:	a0248493          	addi	s1,s1,-1534 # 800230e8 <log>
    800046ee:	8526                	mv	a0,s1
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800046f8:	509c                	lw	a5,32(s1)
    800046fa:	37fd                	addiw	a5,a5,-1
    800046fc:	0007891b          	sext.w	s2,a5
    80004700:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004702:	50dc                	lw	a5,36(s1)
    80004704:	efb9                	bnez	a5,80004762 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004706:	06091663          	bnez	s2,80004772 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000470a:	0001f497          	auipc	s1,0x1f
    8000470e:	9de48493          	addi	s1,s1,-1570 # 800230e8 <log>
    80004712:	4785                	li	a5,1
    80004714:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004716:	8526                	mv	a0,s1
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	580080e7          	jalr	1408(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004720:	54dc                	lw	a5,44(s1)
    80004722:	06f04763          	bgtz	a5,80004790 <end_op+0xbc>
    acquire(&log.lock);
    80004726:	0001f497          	auipc	s1,0x1f
    8000472a:	9c248493          	addi	s1,s1,-1598 # 800230e8 <log>
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4b4080e7          	jalr	1204(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004738:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000473c:	8526                	mv	a0,s1
    8000473e:	ffffe097          	auipc	ra,0xffffe
    80004742:	e64080e7          	jalr	-412(ra) # 800025a2 <wakeup>
    release(&log.lock);
    80004746:	8526                	mv	a0,s1
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	550080e7          	jalr	1360(ra) # 80000c98 <release>
}
    80004750:	70e2                	ld	ra,56(sp)
    80004752:	7442                	ld	s0,48(sp)
    80004754:	74a2                	ld	s1,40(sp)
    80004756:	7902                	ld	s2,32(sp)
    80004758:	69e2                	ld	s3,24(sp)
    8000475a:	6a42                	ld	s4,16(sp)
    8000475c:	6aa2                	ld	s5,8(sp)
    8000475e:	6121                	addi	sp,sp,64
    80004760:	8082                	ret
    panic("log.committing");
    80004762:	00004517          	auipc	a0,0x4
    80004766:	fce50513          	addi	a0,a0,-50 # 80008730 <syscalls+0x1f8>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>
    wakeup(&log);
    80004772:	0001f497          	auipc	s1,0x1f
    80004776:	97648493          	addi	s1,s1,-1674 # 800230e8 <log>
    8000477a:	8526                	mv	a0,s1
    8000477c:	ffffe097          	auipc	ra,0xffffe
    80004780:	e26080e7          	jalr	-474(ra) # 800025a2 <wakeup>
  release(&log.lock);
    80004784:	8526                	mv	a0,s1
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
  if(do_commit){
    8000478e:	b7c9                	j	80004750 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004790:	0001fa97          	auipc	s5,0x1f
    80004794:	988a8a93          	addi	s5,s5,-1656 # 80023118 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004798:	0001fa17          	auipc	s4,0x1f
    8000479c:	950a0a13          	addi	s4,s4,-1712 # 800230e8 <log>
    800047a0:	018a2583          	lw	a1,24(s4)
    800047a4:	012585bb          	addw	a1,a1,s2
    800047a8:	2585                	addiw	a1,a1,1
    800047aa:	028a2503          	lw	a0,40(s4)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	cd2080e7          	jalr	-814(ra) # 80003480 <bread>
    800047b6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047b8:	000aa583          	lw	a1,0(s5)
    800047bc:	028a2503          	lw	a0,40(s4)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	cc0080e7          	jalr	-832(ra) # 80003480 <bread>
    800047c8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047ca:	40000613          	li	a2,1024
    800047ce:	05850593          	addi	a1,a0,88
    800047d2:	05848513          	addi	a0,s1,88
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	56a080e7          	jalr	1386(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800047de:	8526                	mv	a0,s1
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	d92080e7          	jalr	-622(ra) # 80003572 <bwrite>
    brelse(from);
    800047e8:	854e                	mv	a0,s3
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	dc6080e7          	jalr	-570(ra) # 800035b0 <brelse>
    brelse(to);
    800047f2:	8526                	mv	a0,s1
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	dbc080e7          	jalr	-580(ra) # 800035b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047fc:	2905                	addiw	s2,s2,1
    800047fe:	0a91                	addi	s5,s5,4
    80004800:	02ca2783          	lw	a5,44(s4)
    80004804:	f8f94ee3          	blt	s2,a5,800047a0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	c6a080e7          	jalr	-918(ra) # 80004472 <write_head>
    install_trans(0); // Now install writes to home locations
    80004810:	4501                	li	a0,0
    80004812:	00000097          	auipc	ra,0x0
    80004816:	cda080e7          	jalr	-806(ra) # 800044ec <install_trans>
    log.lh.n = 0;
    8000481a:	0001f797          	auipc	a5,0x1f
    8000481e:	8e07ad23          	sw	zero,-1798(a5) # 80023114 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004822:	00000097          	auipc	ra,0x0
    80004826:	c50080e7          	jalr	-944(ra) # 80004472 <write_head>
    8000482a:	bdf5                	j	80004726 <end_op+0x52>

000000008000482c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	e04a                	sd	s2,0(sp)
    80004836:	1000                	addi	s0,sp,32
    80004838:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000483a:	0001f917          	auipc	s2,0x1f
    8000483e:	8ae90913          	addi	s2,s2,-1874 # 800230e8 <log>
    80004842:	854a                	mv	a0,s2
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	3a0080e7          	jalr	928(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000484c:	02c92603          	lw	a2,44(s2)
    80004850:	47f5                	li	a5,29
    80004852:	06c7c563          	blt	a5,a2,800048bc <log_write+0x90>
    80004856:	0001f797          	auipc	a5,0x1f
    8000485a:	8ae7a783          	lw	a5,-1874(a5) # 80023104 <log+0x1c>
    8000485e:	37fd                	addiw	a5,a5,-1
    80004860:	04f65e63          	bge	a2,a5,800048bc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004864:	0001f797          	auipc	a5,0x1f
    80004868:	8a47a783          	lw	a5,-1884(a5) # 80023108 <log+0x20>
    8000486c:	06f05063          	blez	a5,800048cc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004870:	4781                	li	a5,0
    80004872:	06c05563          	blez	a2,800048dc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004876:	44cc                	lw	a1,12(s1)
    80004878:	0001f717          	auipc	a4,0x1f
    8000487c:	8a070713          	addi	a4,a4,-1888 # 80023118 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004880:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004882:	4314                	lw	a3,0(a4)
    80004884:	04b68c63          	beq	a3,a1,800048dc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004888:	2785                	addiw	a5,a5,1
    8000488a:	0711                	addi	a4,a4,4
    8000488c:	fef61be3          	bne	a2,a5,80004882 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004890:	0621                	addi	a2,a2,8
    80004892:	060a                	slli	a2,a2,0x2
    80004894:	0001f797          	auipc	a5,0x1f
    80004898:	85478793          	addi	a5,a5,-1964 # 800230e8 <log>
    8000489c:	963e                	add	a2,a2,a5
    8000489e:	44dc                	lw	a5,12(s1)
    800048a0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048a2:	8526                	mv	a0,s1
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	daa080e7          	jalr	-598(ra) # 8000364e <bpin>
    log.lh.n++;
    800048ac:	0001f717          	auipc	a4,0x1f
    800048b0:	83c70713          	addi	a4,a4,-1988 # 800230e8 <log>
    800048b4:	575c                	lw	a5,44(a4)
    800048b6:	2785                	addiw	a5,a5,1
    800048b8:	d75c                	sw	a5,44(a4)
    800048ba:	a835                	j	800048f6 <log_write+0xca>
    panic("too big a transaction");
    800048bc:	00004517          	auipc	a0,0x4
    800048c0:	e8450513          	addi	a0,a0,-380 # 80008740 <syscalls+0x208>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048cc:	00004517          	auipc	a0,0x4
    800048d0:	e8c50513          	addi	a0,a0,-372 # 80008758 <syscalls+0x220>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800048dc:	00878713          	addi	a4,a5,8
    800048e0:	00271693          	slli	a3,a4,0x2
    800048e4:	0001f717          	auipc	a4,0x1f
    800048e8:	80470713          	addi	a4,a4,-2044 # 800230e8 <log>
    800048ec:	9736                	add	a4,a4,a3
    800048ee:	44d4                	lw	a3,12(s1)
    800048f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048f2:	faf608e3          	beq	a2,a5,800048a2 <log_write+0x76>
  }
  release(&log.lock);
    800048f6:	0001e517          	auipc	a0,0x1e
    800048fa:	7f250513          	addi	a0,a0,2034 # 800230e8 <log>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	39a080e7          	jalr	922(ra) # 80000c98 <release>
}
    80004906:	60e2                	ld	ra,24(sp)
    80004908:	6442                	ld	s0,16(sp)
    8000490a:	64a2                	ld	s1,8(sp)
    8000490c:	6902                	ld	s2,0(sp)
    8000490e:	6105                	addi	sp,sp,32
    80004910:	8082                	ret

0000000080004912 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004912:	1101                	addi	sp,sp,-32
    80004914:	ec06                	sd	ra,24(sp)
    80004916:	e822                	sd	s0,16(sp)
    80004918:	e426                	sd	s1,8(sp)
    8000491a:	e04a                	sd	s2,0(sp)
    8000491c:	1000                	addi	s0,sp,32
    8000491e:	84aa                	mv	s1,a0
    80004920:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004922:	00004597          	auipc	a1,0x4
    80004926:	e5658593          	addi	a1,a1,-426 # 80008778 <syscalls+0x240>
    8000492a:	0521                	addi	a0,a0,8
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	228080e7          	jalr	552(ra) # 80000b54 <initlock>
  lk->name = name;
    80004934:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004938:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000493c:	0204a423          	sw	zero,40(s1)
}
    80004940:	60e2                	ld	ra,24(sp)
    80004942:	6442                	ld	s0,16(sp)
    80004944:	64a2                	ld	s1,8(sp)
    80004946:	6902                	ld	s2,0(sp)
    80004948:	6105                	addi	sp,sp,32
    8000494a:	8082                	ret

000000008000494c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000494c:	1101                	addi	sp,sp,-32
    8000494e:	ec06                	sd	ra,24(sp)
    80004950:	e822                	sd	s0,16(sp)
    80004952:	e426                	sd	s1,8(sp)
    80004954:	e04a                	sd	s2,0(sp)
    80004956:	1000                	addi	s0,sp,32
    80004958:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000495a:	00850913          	addi	s2,a0,8
    8000495e:	854a                	mv	a0,s2
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	284080e7          	jalr	644(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004968:	409c                	lw	a5,0(s1)
    8000496a:	cb89                	beqz	a5,8000497c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000496c:	85ca                	mv	a1,s2
    8000496e:	8526                	mv	a0,s1
    80004970:	ffffe097          	auipc	ra,0xffffe
    80004974:	95a080e7          	jalr	-1702(ra) # 800022ca <sleep>
  while (lk->locked) {
    80004978:	409c                	lw	a5,0(s1)
    8000497a:	fbed                	bnez	a5,8000496c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000497c:	4785                	li	a5,1
    8000497e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004980:	ffffd097          	auipc	ra,0xffffd
    80004984:	156080e7          	jalr	342(ra) # 80001ad6 <myproc>
    80004988:	591c                	lw	a5,48(a0)
    8000498a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000498c:	854a                	mv	a0,s2
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	30a080e7          	jalr	778(ra) # 80000c98 <release>
}
    80004996:	60e2                	ld	ra,24(sp)
    80004998:	6442                	ld	s0,16(sp)
    8000499a:	64a2                	ld	s1,8(sp)
    8000499c:	6902                	ld	s2,0(sp)
    8000499e:	6105                	addi	sp,sp,32
    800049a0:	8082                	ret

00000000800049a2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049a2:	1101                	addi	sp,sp,-32
    800049a4:	ec06                	sd	ra,24(sp)
    800049a6:	e822                	sd	s0,16(sp)
    800049a8:	e426                	sd	s1,8(sp)
    800049aa:	e04a                	sd	s2,0(sp)
    800049ac:	1000                	addi	s0,sp,32
    800049ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049b0:	00850913          	addi	s2,a0,8
    800049b4:	854a                	mv	a0,s2
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	22e080e7          	jalr	558(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049c6:	8526                	mv	a0,s1
    800049c8:	ffffe097          	auipc	ra,0xffffe
    800049cc:	bda080e7          	jalr	-1062(ra) # 800025a2 <wakeup>
  release(&lk->lk);
    800049d0:	854a                	mv	a0,s2
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	2c6080e7          	jalr	710(ra) # 80000c98 <release>
}
    800049da:	60e2                	ld	ra,24(sp)
    800049dc:	6442                	ld	s0,16(sp)
    800049de:	64a2                	ld	s1,8(sp)
    800049e0:	6902                	ld	s2,0(sp)
    800049e2:	6105                	addi	sp,sp,32
    800049e4:	8082                	ret

00000000800049e6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049e6:	7179                	addi	sp,sp,-48
    800049e8:	f406                	sd	ra,40(sp)
    800049ea:	f022                	sd	s0,32(sp)
    800049ec:	ec26                	sd	s1,24(sp)
    800049ee:	e84a                	sd	s2,16(sp)
    800049f0:	e44e                	sd	s3,8(sp)
    800049f2:	1800                	addi	s0,sp,48
    800049f4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049f6:	00850913          	addi	s2,a0,8
    800049fa:	854a                	mv	a0,s2
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	1e8080e7          	jalr	488(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a04:	409c                	lw	a5,0(s1)
    80004a06:	ef99                	bnez	a5,80004a24 <holdingsleep+0x3e>
    80004a08:	4481                	li	s1,0
  release(&lk->lk);
    80004a0a:	854a                	mv	a0,s2
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	28c080e7          	jalr	652(ra) # 80000c98 <release>
  return r;
}
    80004a14:	8526                	mv	a0,s1
    80004a16:	70a2                	ld	ra,40(sp)
    80004a18:	7402                	ld	s0,32(sp)
    80004a1a:	64e2                	ld	s1,24(sp)
    80004a1c:	6942                	ld	s2,16(sp)
    80004a1e:	69a2                	ld	s3,8(sp)
    80004a20:	6145                	addi	sp,sp,48
    80004a22:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a24:	0284a983          	lw	s3,40(s1)
    80004a28:	ffffd097          	auipc	ra,0xffffd
    80004a2c:	0ae080e7          	jalr	174(ra) # 80001ad6 <myproc>
    80004a30:	5904                	lw	s1,48(a0)
    80004a32:	413484b3          	sub	s1,s1,s3
    80004a36:	0014b493          	seqz	s1,s1
    80004a3a:	bfc1                	j	80004a0a <holdingsleep+0x24>

0000000080004a3c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a3c:	1141                	addi	sp,sp,-16
    80004a3e:	e406                	sd	ra,8(sp)
    80004a40:	e022                	sd	s0,0(sp)
    80004a42:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a44:	00004597          	auipc	a1,0x4
    80004a48:	d4458593          	addi	a1,a1,-700 # 80008788 <syscalls+0x250>
    80004a4c:	0001e517          	auipc	a0,0x1e
    80004a50:	7e450513          	addi	a0,a0,2020 # 80023230 <ftable>
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	100080e7          	jalr	256(ra) # 80000b54 <initlock>
}
    80004a5c:	60a2                	ld	ra,8(sp)
    80004a5e:	6402                	ld	s0,0(sp)
    80004a60:	0141                	addi	sp,sp,16
    80004a62:	8082                	ret

0000000080004a64 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a64:	1101                	addi	sp,sp,-32
    80004a66:	ec06                	sd	ra,24(sp)
    80004a68:	e822                	sd	s0,16(sp)
    80004a6a:	e426                	sd	s1,8(sp)
    80004a6c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a6e:	0001e517          	auipc	a0,0x1e
    80004a72:	7c250513          	addi	a0,a0,1986 # 80023230 <ftable>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	16e080e7          	jalr	366(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a7e:	0001e497          	auipc	s1,0x1e
    80004a82:	7ca48493          	addi	s1,s1,1994 # 80023248 <ftable+0x18>
    80004a86:	0001f717          	auipc	a4,0x1f
    80004a8a:	76270713          	addi	a4,a4,1890 # 800241e8 <ftable+0xfb8>
    if(f->ref == 0){
    80004a8e:	40dc                	lw	a5,4(s1)
    80004a90:	cf99                	beqz	a5,80004aae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a92:	02848493          	addi	s1,s1,40
    80004a96:	fee49ce3          	bne	s1,a4,80004a8e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a9a:	0001e517          	auipc	a0,0x1e
    80004a9e:	79650513          	addi	a0,a0,1942 # 80023230 <ftable>
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	1f6080e7          	jalr	502(ra) # 80000c98 <release>
  return 0;
    80004aaa:	4481                	li	s1,0
    80004aac:	a819                	j	80004ac2 <filealloc+0x5e>
      f->ref = 1;
    80004aae:	4785                	li	a5,1
    80004ab0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ab2:	0001e517          	auipc	a0,0x1e
    80004ab6:	77e50513          	addi	a0,a0,1918 # 80023230 <ftable>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>
}
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	60e2                	ld	ra,24(sp)
    80004ac6:	6442                	ld	s0,16(sp)
    80004ac8:	64a2                	ld	s1,8(sp)
    80004aca:	6105                	addi	sp,sp,32
    80004acc:	8082                	ret

0000000080004ace <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ace:	1101                	addi	sp,sp,-32
    80004ad0:	ec06                	sd	ra,24(sp)
    80004ad2:	e822                	sd	s0,16(sp)
    80004ad4:	e426                	sd	s1,8(sp)
    80004ad6:	1000                	addi	s0,sp,32
    80004ad8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ada:	0001e517          	auipc	a0,0x1e
    80004ade:	75650513          	addi	a0,a0,1878 # 80023230 <ftable>
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	102080e7          	jalr	258(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004aea:	40dc                	lw	a5,4(s1)
    80004aec:	02f05263          	blez	a5,80004b10 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004af0:	2785                	addiw	a5,a5,1
    80004af2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004af4:	0001e517          	auipc	a0,0x1e
    80004af8:	73c50513          	addi	a0,a0,1852 # 80023230 <ftable>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	19c080e7          	jalr	412(ra) # 80000c98 <release>
  return f;
}
    80004b04:	8526                	mv	a0,s1
    80004b06:	60e2                	ld	ra,24(sp)
    80004b08:	6442                	ld	s0,16(sp)
    80004b0a:	64a2                	ld	s1,8(sp)
    80004b0c:	6105                	addi	sp,sp,32
    80004b0e:	8082                	ret
    panic("filedup");
    80004b10:	00004517          	auipc	a0,0x4
    80004b14:	c8050513          	addi	a0,a0,-896 # 80008790 <syscalls+0x258>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	a26080e7          	jalr	-1498(ra) # 8000053e <panic>

0000000080004b20 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b20:	7139                	addi	sp,sp,-64
    80004b22:	fc06                	sd	ra,56(sp)
    80004b24:	f822                	sd	s0,48(sp)
    80004b26:	f426                	sd	s1,40(sp)
    80004b28:	f04a                	sd	s2,32(sp)
    80004b2a:	ec4e                	sd	s3,24(sp)
    80004b2c:	e852                	sd	s4,16(sp)
    80004b2e:	e456                	sd	s5,8(sp)
    80004b30:	0080                	addi	s0,sp,64
    80004b32:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b34:	0001e517          	auipc	a0,0x1e
    80004b38:	6fc50513          	addi	a0,a0,1788 # 80023230 <ftable>
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	0a8080e7          	jalr	168(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b44:	40dc                	lw	a5,4(s1)
    80004b46:	06f05163          	blez	a5,80004ba8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b4a:	37fd                	addiw	a5,a5,-1
    80004b4c:	0007871b          	sext.w	a4,a5
    80004b50:	c0dc                	sw	a5,4(s1)
    80004b52:	06e04363          	bgtz	a4,80004bb8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b56:	0004a903          	lw	s2,0(s1)
    80004b5a:	0094ca83          	lbu	s5,9(s1)
    80004b5e:	0104ba03          	ld	s4,16(s1)
    80004b62:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b66:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b6a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b6e:	0001e517          	auipc	a0,0x1e
    80004b72:	6c250513          	addi	a0,a0,1730 # 80023230 <ftable>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b7e:	4785                	li	a5,1
    80004b80:	04f90d63          	beq	s2,a5,80004bda <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b84:	3979                	addiw	s2,s2,-2
    80004b86:	4785                	li	a5,1
    80004b88:	0527e063          	bltu	a5,s2,80004bc8 <fileclose+0xa8>
    begin_op();
    80004b8c:	00000097          	auipc	ra,0x0
    80004b90:	ac8080e7          	jalr	-1336(ra) # 80004654 <begin_op>
    iput(ff.ip);
    80004b94:	854e                	mv	a0,s3
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	2a6080e7          	jalr	678(ra) # 80003e3c <iput>
    end_op();
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	b36080e7          	jalr	-1226(ra) # 800046d4 <end_op>
    80004ba6:	a00d                	j	80004bc8 <fileclose+0xa8>
    panic("fileclose");
    80004ba8:	00004517          	auipc	a0,0x4
    80004bac:	bf050513          	addi	a0,a0,-1040 # 80008798 <syscalls+0x260>
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004bb8:	0001e517          	auipc	a0,0x1e
    80004bbc:	67850513          	addi	a0,a0,1656 # 80023230 <ftable>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	0d8080e7          	jalr	216(ra) # 80000c98 <release>
  }
}
    80004bc8:	70e2                	ld	ra,56(sp)
    80004bca:	7442                	ld	s0,48(sp)
    80004bcc:	74a2                	ld	s1,40(sp)
    80004bce:	7902                	ld	s2,32(sp)
    80004bd0:	69e2                	ld	s3,24(sp)
    80004bd2:	6a42                	ld	s4,16(sp)
    80004bd4:	6aa2                	ld	s5,8(sp)
    80004bd6:	6121                	addi	sp,sp,64
    80004bd8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bda:	85d6                	mv	a1,s5
    80004bdc:	8552                	mv	a0,s4
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	34c080e7          	jalr	844(ra) # 80004f2a <pipeclose>
    80004be6:	b7cd                	j	80004bc8 <fileclose+0xa8>

0000000080004be8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004be8:	715d                	addi	sp,sp,-80
    80004bea:	e486                	sd	ra,72(sp)
    80004bec:	e0a2                	sd	s0,64(sp)
    80004bee:	fc26                	sd	s1,56(sp)
    80004bf0:	f84a                	sd	s2,48(sp)
    80004bf2:	f44e                	sd	s3,40(sp)
    80004bf4:	0880                	addi	s0,sp,80
    80004bf6:	84aa                	mv	s1,a0
    80004bf8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	edc080e7          	jalr	-292(ra) # 80001ad6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c02:	409c                	lw	a5,0(s1)
    80004c04:	37f9                	addiw	a5,a5,-2
    80004c06:	4705                	li	a4,1
    80004c08:	04f76763          	bltu	a4,a5,80004c56 <filestat+0x6e>
    80004c0c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c0e:	6c88                	ld	a0,24(s1)
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	072080e7          	jalr	114(ra) # 80003c82 <ilock>
    stati(f->ip, &st);
    80004c18:	fb840593          	addi	a1,s0,-72
    80004c1c:	6c88                	ld	a0,24(s1)
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	2ee080e7          	jalr	750(ra) # 80003f0c <stati>
    iunlock(f->ip);
    80004c26:	6c88                	ld	a0,24(s1)
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	11c080e7          	jalr	284(ra) # 80003d44 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c30:	46e1                	li	a3,24
    80004c32:	fb840613          	addi	a2,s0,-72
    80004c36:	85ce                	mv	a1,s3
    80004c38:	05093503          	ld	a0,80(s2)
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	a3e080e7          	jalr	-1474(ra) # 8000167a <copyout>
    80004c44:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c48:	60a6                	ld	ra,72(sp)
    80004c4a:	6406                	ld	s0,64(sp)
    80004c4c:	74e2                	ld	s1,56(sp)
    80004c4e:	7942                	ld	s2,48(sp)
    80004c50:	79a2                	ld	s3,40(sp)
    80004c52:	6161                	addi	sp,sp,80
    80004c54:	8082                	ret
  return -1;
    80004c56:	557d                	li	a0,-1
    80004c58:	bfc5                	j	80004c48 <filestat+0x60>

0000000080004c5a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c5a:	7179                	addi	sp,sp,-48
    80004c5c:	f406                	sd	ra,40(sp)
    80004c5e:	f022                	sd	s0,32(sp)
    80004c60:	ec26                	sd	s1,24(sp)
    80004c62:	e84a                	sd	s2,16(sp)
    80004c64:	e44e                	sd	s3,8(sp)
    80004c66:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c68:	00854783          	lbu	a5,8(a0)
    80004c6c:	c3d5                	beqz	a5,80004d10 <fileread+0xb6>
    80004c6e:	84aa                	mv	s1,a0
    80004c70:	89ae                	mv	s3,a1
    80004c72:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c74:	411c                	lw	a5,0(a0)
    80004c76:	4705                	li	a4,1
    80004c78:	04e78963          	beq	a5,a4,80004cca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c7c:	470d                	li	a4,3
    80004c7e:	04e78d63          	beq	a5,a4,80004cd8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c82:	4709                	li	a4,2
    80004c84:	06e79e63          	bne	a5,a4,80004d00 <fileread+0xa6>
    ilock(f->ip);
    80004c88:	6d08                	ld	a0,24(a0)
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	ff8080e7          	jalr	-8(ra) # 80003c82 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c92:	874a                	mv	a4,s2
    80004c94:	5094                	lw	a3,32(s1)
    80004c96:	864e                	mv	a2,s3
    80004c98:	4585                	li	a1,1
    80004c9a:	6c88                	ld	a0,24(s1)
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	29a080e7          	jalr	666(ra) # 80003f36 <readi>
    80004ca4:	892a                	mv	s2,a0
    80004ca6:	00a05563          	blez	a0,80004cb0 <fileread+0x56>
      f->off += r;
    80004caa:	509c                	lw	a5,32(s1)
    80004cac:	9fa9                	addw	a5,a5,a0
    80004cae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cb0:	6c88                	ld	a0,24(s1)
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	092080e7          	jalr	146(ra) # 80003d44 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cba:	854a                	mv	a0,s2
    80004cbc:	70a2                	ld	ra,40(sp)
    80004cbe:	7402                	ld	s0,32(sp)
    80004cc0:	64e2                	ld	s1,24(sp)
    80004cc2:	6942                	ld	s2,16(sp)
    80004cc4:	69a2                	ld	s3,8(sp)
    80004cc6:	6145                	addi	sp,sp,48
    80004cc8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cca:	6908                	ld	a0,16(a0)
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	3c8080e7          	jalr	968(ra) # 80005094 <piperead>
    80004cd4:	892a                	mv	s2,a0
    80004cd6:	b7d5                	j	80004cba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cd8:	02451783          	lh	a5,36(a0)
    80004cdc:	03079693          	slli	a3,a5,0x30
    80004ce0:	92c1                	srli	a3,a3,0x30
    80004ce2:	4725                	li	a4,9
    80004ce4:	02d76863          	bltu	a4,a3,80004d14 <fileread+0xba>
    80004ce8:	0792                	slli	a5,a5,0x4
    80004cea:	0001e717          	auipc	a4,0x1e
    80004cee:	4a670713          	addi	a4,a4,1190 # 80023190 <devsw>
    80004cf2:	97ba                	add	a5,a5,a4
    80004cf4:	639c                	ld	a5,0(a5)
    80004cf6:	c38d                	beqz	a5,80004d18 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cf8:	4505                	li	a0,1
    80004cfa:	9782                	jalr	a5
    80004cfc:	892a                	mv	s2,a0
    80004cfe:	bf75                	j	80004cba <fileread+0x60>
    panic("fileread");
    80004d00:	00004517          	auipc	a0,0x4
    80004d04:	aa850513          	addi	a0,a0,-1368 # 800087a8 <syscalls+0x270>
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	836080e7          	jalr	-1994(ra) # 8000053e <panic>
    return -1;
    80004d10:	597d                	li	s2,-1
    80004d12:	b765                	j	80004cba <fileread+0x60>
      return -1;
    80004d14:	597d                	li	s2,-1
    80004d16:	b755                	j	80004cba <fileread+0x60>
    80004d18:	597d                	li	s2,-1
    80004d1a:	b745                	j	80004cba <fileread+0x60>

0000000080004d1c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d1c:	715d                	addi	sp,sp,-80
    80004d1e:	e486                	sd	ra,72(sp)
    80004d20:	e0a2                	sd	s0,64(sp)
    80004d22:	fc26                	sd	s1,56(sp)
    80004d24:	f84a                	sd	s2,48(sp)
    80004d26:	f44e                	sd	s3,40(sp)
    80004d28:	f052                	sd	s4,32(sp)
    80004d2a:	ec56                	sd	s5,24(sp)
    80004d2c:	e85a                	sd	s6,16(sp)
    80004d2e:	e45e                	sd	s7,8(sp)
    80004d30:	e062                	sd	s8,0(sp)
    80004d32:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d34:	00954783          	lbu	a5,9(a0)
    80004d38:	10078663          	beqz	a5,80004e44 <filewrite+0x128>
    80004d3c:	892a                	mv	s2,a0
    80004d3e:	8aae                	mv	s5,a1
    80004d40:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d42:	411c                	lw	a5,0(a0)
    80004d44:	4705                	li	a4,1
    80004d46:	02e78263          	beq	a5,a4,80004d6a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d4a:	470d                	li	a4,3
    80004d4c:	02e78663          	beq	a5,a4,80004d78 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d50:	4709                	li	a4,2
    80004d52:	0ee79163          	bne	a5,a4,80004e34 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d56:	0ac05d63          	blez	a2,80004e10 <filewrite+0xf4>
    int i = 0;
    80004d5a:	4981                	li	s3,0
    80004d5c:	6b05                	lui	s6,0x1
    80004d5e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d62:	6b85                	lui	s7,0x1
    80004d64:	c00b8b9b          	addiw	s7,s7,-1024
    80004d68:	a861                	j	80004e00 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d6a:	6908                	ld	a0,16(a0)
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	22e080e7          	jalr	558(ra) # 80004f9a <pipewrite>
    80004d74:	8a2a                	mv	s4,a0
    80004d76:	a045                	j	80004e16 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d78:	02451783          	lh	a5,36(a0)
    80004d7c:	03079693          	slli	a3,a5,0x30
    80004d80:	92c1                	srli	a3,a3,0x30
    80004d82:	4725                	li	a4,9
    80004d84:	0cd76263          	bltu	a4,a3,80004e48 <filewrite+0x12c>
    80004d88:	0792                	slli	a5,a5,0x4
    80004d8a:	0001e717          	auipc	a4,0x1e
    80004d8e:	40670713          	addi	a4,a4,1030 # 80023190 <devsw>
    80004d92:	97ba                	add	a5,a5,a4
    80004d94:	679c                	ld	a5,8(a5)
    80004d96:	cbdd                	beqz	a5,80004e4c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d98:	4505                	li	a0,1
    80004d9a:	9782                	jalr	a5
    80004d9c:	8a2a                	mv	s4,a0
    80004d9e:	a8a5                	j	80004e16 <filewrite+0xfa>
    80004da0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004da4:	00000097          	auipc	ra,0x0
    80004da8:	8b0080e7          	jalr	-1872(ra) # 80004654 <begin_op>
      ilock(f->ip);
    80004dac:	01893503          	ld	a0,24(s2)
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	ed2080e7          	jalr	-302(ra) # 80003c82 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004db8:	8762                	mv	a4,s8
    80004dba:	02092683          	lw	a3,32(s2)
    80004dbe:	01598633          	add	a2,s3,s5
    80004dc2:	4585                	li	a1,1
    80004dc4:	01893503          	ld	a0,24(s2)
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	266080e7          	jalr	614(ra) # 8000402e <writei>
    80004dd0:	84aa                	mv	s1,a0
    80004dd2:	00a05763          	blez	a0,80004de0 <filewrite+0xc4>
        f->off += r;
    80004dd6:	02092783          	lw	a5,32(s2)
    80004dda:	9fa9                	addw	a5,a5,a0
    80004ddc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004de0:	01893503          	ld	a0,24(s2)
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	f60080e7          	jalr	-160(ra) # 80003d44 <iunlock>
      end_op();
    80004dec:	00000097          	auipc	ra,0x0
    80004df0:	8e8080e7          	jalr	-1816(ra) # 800046d4 <end_op>

      if(r != n1){
    80004df4:	009c1f63          	bne	s8,s1,80004e12 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004df8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004dfc:	0149db63          	bge	s3,s4,80004e12 <filewrite+0xf6>
      int n1 = n - i;
    80004e00:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e04:	84be                	mv	s1,a5
    80004e06:	2781                	sext.w	a5,a5
    80004e08:	f8fb5ce3          	bge	s6,a5,80004da0 <filewrite+0x84>
    80004e0c:	84de                	mv	s1,s7
    80004e0e:	bf49                	j	80004da0 <filewrite+0x84>
    int i = 0;
    80004e10:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e12:	013a1f63          	bne	s4,s3,80004e30 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e16:	8552                	mv	a0,s4
    80004e18:	60a6                	ld	ra,72(sp)
    80004e1a:	6406                	ld	s0,64(sp)
    80004e1c:	74e2                	ld	s1,56(sp)
    80004e1e:	7942                	ld	s2,48(sp)
    80004e20:	79a2                	ld	s3,40(sp)
    80004e22:	7a02                	ld	s4,32(sp)
    80004e24:	6ae2                	ld	s5,24(sp)
    80004e26:	6b42                	ld	s6,16(sp)
    80004e28:	6ba2                	ld	s7,8(sp)
    80004e2a:	6c02                	ld	s8,0(sp)
    80004e2c:	6161                	addi	sp,sp,80
    80004e2e:	8082                	ret
    ret = (i == n ? n : -1);
    80004e30:	5a7d                	li	s4,-1
    80004e32:	b7d5                	j	80004e16 <filewrite+0xfa>
    panic("filewrite");
    80004e34:	00004517          	auipc	a0,0x4
    80004e38:	98450513          	addi	a0,a0,-1660 # 800087b8 <syscalls+0x280>
    80004e3c:	ffffb097          	auipc	ra,0xffffb
    80004e40:	702080e7          	jalr	1794(ra) # 8000053e <panic>
    return -1;
    80004e44:	5a7d                	li	s4,-1
    80004e46:	bfc1                	j	80004e16 <filewrite+0xfa>
      return -1;
    80004e48:	5a7d                	li	s4,-1
    80004e4a:	b7f1                	j	80004e16 <filewrite+0xfa>
    80004e4c:	5a7d                	li	s4,-1
    80004e4e:	b7e1                	j	80004e16 <filewrite+0xfa>

0000000080004e50 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e50:	7179                	addi	sp,sp,-48
    80004e52:	f406                	sd	ra,40(sp)
    80004e54:	f022                	sd	s0,32(sp)
    80004e56:	ec26                	sd	s1,24(sp)
    80004e58:	e84a                	sd	s2,16(sp)
    80004e5a:	e44e                	sd	s3,8(sp)
    80004e5c:	e052                	sd	s4,0(sp)
    80004e5e:	1800                	addi	s0,sp,48
    80004e60:	84aa                	mv	s1,a0
    80004e62:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e64:	0005b023          	sd	zero,0(a1)
    80004e68:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e6c:	00000097          	auipc	ra,0x0
    80004e70:	bf8080e7          	jalr	-1032(ra) # 80004a64 <filealloc>
    80004e74:	e088                	sd	a0,0(s1)
    80004e76:	c551                	beqz	a0,80004f02 <pipealloc+0xb2>
    80004e78:	00000097          	auipc	ra,0x0
    80004e7c:	bec080e7          	jalr	-1044(ra) # 80004a64 <filealloc>
    80004e80:	00aa3023          	sd	a0,0(s4)
    80004e84:	c92d                	beqz	a0,80004ef6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	c6e080e7          	jalr	-914(ra) # 80000af4 <kalloc>
    80004e8e:	892a                	mv	s2,a0
    80004e90:	c125                	beqz	a0,80004ef0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e92:	4985                	li	s3,1
    80004e94:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e98:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e9c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ea0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ea4:	00003597          	auipc	a1,0x3
    80004ea8:	5d458593          	addi	a1,a1,1492 # 80008478 <states.1811+0x1b8>
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	ca8080e7          	jalr	-856(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004eb4:	609c                	ld	a5,0(s1)
    80004eb6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004eba:	609c                	ld	a5,0(s1)
    80004ebc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ec0:	609c                	ld	a5,0(s1)
    80004ec2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ec6:	609c                	ld	a5,0(s1)
    80004ec8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ecc:	000a3783          	ld	a5,0(s4)
    80004ed0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ed4:	000a3783          	ld	a5,0(s4)
    80004ed8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004edc:	000a3783          	ld	a5,0(s4)
    80004ee0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ee4:	000a3783          	ld	a5,0(s4)
    80004ee8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004eec:	4501                	li	a0,0
    80004eee:	a025                	j	80004f16 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ef0:	6088                	ld	a0,0(s1)
    80004ef2:	e501                	bnez	a0,80004efa <pipealloc+0xaa>
    80004ef4:	a039                	j	80004f02 <pipealloc+0xb2>
    80004ef6:	6088                	ld	a0,0(s1)
    80004ef8:	c51d                	beqz	a0,80004f26 <pipealloc+0xd6>
    fileclose(*f0);
    80004efa:	00000097          	auipc	ra,0x0
    80004efe:	c26080e7          	jalr	-986(ra) # 80004b20 <fileclose>
  if(*f1)
    80004f02:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f06:	557d                	li	a0,-1
  if(*f1)
    80004f08:	c799                	beqz	a5,80004f16 <pipealloc+0xc6>
    fileclose(*f1);
    80004f0a:	853e                	mv	a0,a5
    80004f0c:	00000097          	auipc	ra,0x0
    80004f10:	c14080e7          	jalr	-1004(ra) # 80004b20 <fileclose>
  return -1;
    80004f14:	557d                	li	a0,-1
}
    80004f16:	70a2                	ld	ra,40(sp)
    80004f18:	7402                	ld	s0,32(sp)
    80004f1a:	64e2                	ld	s1,24(sp)
    80004f1c:	6942                	ld	s2,16(sp)
    80004f1e:	69a2                	ld	s3,8(sp)
    80004f20:	6a02                	ld	s4,0(sp)
    80004f22:	6145                	addi	sp,sp,48
    80004f24:	8082                	ret
  return -1;
    80004f26:	557d                	li	a0,-1
    80004f28:	b7fd                	j	80004f16 <pipealloc+0xc6>

0000000080004f2a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f2a:	1101                	addi	sp,sp,-32
    80004f2c:	ec06                	sd	ra,24(sp)
    80004f2e:	e822                	sd	s0,16(sp)
    80004f30:	e426                	sd	s1,8(sp)
    80004f32:	e04a                	sd	s2,0(sp)
    80004f34:	1000                	addi	s0,sp,32
    80004f36:	84aa                	mv	s1,a0
    80004f38:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	caa080e7          	jalr	-854(ra) # 80000be4 <acquire>
  if(writable){
    80004f42:	02090d63          	beqz	s2,80004f7c <pipeclose+0x52>
    pi->writeopen = 0;
    80004f46:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f4a:	21848513          	addi	a0,s1,536
    80004f4e:	ffffd097          	auipc	ra,0xffffd
    80004f52:	654080e7          	jalr	1620(ra) # 800025a2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f56:	2204b783          	ld	a5,544(s1)
    80004f5a:	eb95                	bnez	a5,80004f8e <pipeclose+0x64>
    release(&pi->lock);
    80004f5c:	8526                	mv	a0,s1
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	d3a080e7          	jalr	-710(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f66:	8526                	mv	a0,s1
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	a90080e7          	jalr	-1392(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f70:	60e2                	ld	ra,24(sp)
    80004f72:	6442                	ld	s0,16(sp)
    80004f74:	64a2                	ld	s1,8(sp)
    80004f76:	6902                	ld	s2,0(sp)
    80004f78:	6105                	addi	sp,sp,32
    80004f7a:	8082                	ret
    pi->readopen = 0;
    80004f7c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f80:	21c48513          	addi	a0,s1,540
    80004f84:	ffffd097          	auipc	ra,0xffffd
    80004f88:	61e080e7          	jalr	1566(ra) # 800025a2 <wakeup>
    80004f8c:	b7e9                	j	80004f56 <pipeclose+0x2c>
    release(&pi->lock);
    80004f8e:	8526                	mv	a0,s1
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	d08080e7          	jalr	-760(ra) # 80000c98 <release>
}
    80004f98:	bfe1                	j	80004f70 <pipeclose+0x46>

0000000080004f9a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f9a:	7159                	addi	sp,sp,-112
    80004f9c:	f486                	sd	ra,104(sp)
    80004f9e:	f0a2                	sd	s0,96(sp)
    80004fa0:	eca6                	sd	s1,88(sp)
    80004fa2:	e8ca                	sd	s2,80(sp)
    80004fa4:	e4ce                	sd	s3,72(sp)
    80004fa6:	e0d2                	sd	s4,64(sp)
    80004fa8:	fc56                	sd	s5,56(sp)
    80004faa:	f85a                	sd	s6,48(sp)
    80004fac:	f45e                	sd	s7,40(sp)
    80004fae:	f062                	sd	s8,32(sp)
    80004fb0:	ec66                	sd	s9,24(sp)
    80004fb2:	1880                	addi	s0,sp,112
    80004fb4:	84aa                	mv	s1,a0
    80004fb6:	8aae                	mv	s5,a1
    80004fb8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	b1c080e7          	jalr	-1252(ra) # 80001ad6 <myproc>
    80004fc2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
  while(i < n){
    80004fce:	0d405163          	blez	s4,80005090 <pipewrite+0xf6>
    80004fd2:	8ba6                	mv	s7,s1
  int i = 0;
    80004fd4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fd6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fd8:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fdc:	21c48c13          	addi	s8,s1,540
    80004fe0:	a08d                	j	80005042 <pipewrite+0xa8>
      release(&pi->lock);
    80004fe2:	8526                	mv	a0,s1
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	cb4080e7          	jalr	-844(ra) # 80000c98 <release>
      return -1;
    80004fec:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fee:	854a                	mv	a0,s2
    80004ff0:	70a6                	ld	ra,104(sp)
    80004ff2:	7406                	ld	s0,96(sp)
    80004ff4:	64e6                	ld	s1,88(sp)
    80004ff6:	6946                	ld	s2,80(sp)
    80004ff8:	69a6                	ld	s3,72(sp)
    80004ffa:	6a06                	ld	s4,64(sp)
    80004ffc:	7ae2                	ld	s5,56(sp)
    80004ffe:	7b42                	ld	s6,48(sp)
    80005000:	7ba2                	ld	s7,40(sp)
    80005002:	7c02                	ld	s8,32(sp)
    80005004:	6ce2                	ld	s9,24(sp)
    80005006:	6165                	addi	sp,sp,112
    80005008:	8082                	ret
      wakeup(&pi->nread);
    8000500a:	8566                	mv	a0,s9
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	596080e7          	jalr	1430(ra) # 800025a2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005014:	85de                	mv	a1,s7
    80005016:	8562                	mv	a0,s8
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	2b2080e7          	jalr	690(ra) # 800022ca <sleep>
    80005020:	a839                	j	8000503e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005022:	21c4a783          	lw	a5,540(s1)
    80005026:	0017871b          	addiw	a4,a5,1
    8000502a:	20e4ae23          	sw	a4,540(s1)
    8000502e:	1ff7f793          	andi	a5,a5,511
    80005032:	97a6                	add	a5,a5,s1
    80005034:	f9f44703          	lbu	a4,-97(s0)
    80005038:	00e78c23          	sb	a4,24(a5)
      i++;
    8000503c:	2905                	addiw	s2,s2,1
  while(i < n){
    8000503e:	03495d63          	bge	s2,s4,80005078 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005042:	2204a783          	lw	a5,544(s1)
    80005046:	dfd1                	beqz	a5,80004fe2 <pipewrite+0x48>
    80005048:	0289a783          	lw	a5,40(s3)
    8000504c:	fbd9                	bnez	a5,80004fe2 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000504e:	2184a783          	lw	a5,536(s1)
    80005052:	21c4a703          	lw	a4,540(s1)
    80005056:	2007879b          	addiw	a5,a5,512
    8000505a:	faf708e3          	beq	a4,a5,8000500a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000505e:	4685                	li	a3,1
    80005060:	01590633          	add	a2,s2,s5
    80005064:	f9f40593          	addi	a1,s0,-97
    80005068:	0509b503          	ld	a0,80(s3)
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	69a080e7          	jalr	1690(ra) # 80001706 <copyin>
    80005074:	fb6517e3          	bne	a0,s6,80005022 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005078:	21848513          	addi	a0,s1,536
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	526080e7          	jalr	1318(ra) # 800025a2 <wakeup>
  release(&pi->lock);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
  return i;
    8000508e:	b785                	j	80004fee <pipewrite+0x54>
  int i = 0;
    80005090:	4901                	li	s2,0
    80005092:	b7dd                	j	80005078 <pipewrite+0xde>

0000000080005094 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005094:	715d                	addi	sp,sp,-80
    80005096:	e486                	sd	ra,72(sp)
    80005098:	e0a2                	sd	s0,64(sp)
    8000509a:	fc26                	sd	s1,56(sp)
    8000509c:	f84a                	sd	s2,48(sp)
    8000509e:	f44e                	sd	s3,40(sp)
    800050a0:	f052                	sd	s4,32(sp)
    800050a2:	ec56                	sd	s5,24(sp)
    800050a4:	e85a                	sd	s6,16(sp)
    800050a6:	0880                	addi	s0,sp,80
    800050a8:	84aa                	mv	s1,a0
    800050aa:	892e                	mv	s2,a1
    800050ac:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	a28080e7          	jalr	-1496(ra) # 80001ad6 <myproc>
    800050b6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050b8:	8b26                	mv	s6,s1
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	b28080e7          	jalr	-1240(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050c4:	2184a703          	lw	a4,536(s1)
    800050c8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050cc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050d0:	02f71463          	bne	a4,a5,800050f8 <piperead+0x64>
    800050d4:	2244a783          	lw	a5,548(s1)
    800050d8:	c385                	beqz	a5,800050f8 <piperead+0x64>
    if(pr->killed){
    800050da:	028a2783          	lw	a5,40(s4)
    800050de:	ebc1                	bnez	a5,8000516e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050e0:	85da                	mv	a1,s6
    800050e2:	854e                	mv	a0,s3
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	1e6080e7          	jalr	486(ra) # 800022ca <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ec:	2184a703          	lw	a4,536(s1)
    800050f0:	21c4a783          	lw	a5,540(s1)
    800050f4:	fef700e3          	beq	a4,a5,800050d4 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f8:	09505263          	blez	s5,8000517c <piperead+0xe8>
    800050fc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050fe:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005100:	2184a783          	lw	a5,536(s1)
    80005104:	21c4a703          	lw	a4,540(s1)
    80005108:	02f70d63          	beq	a4,a5,80005142 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000510c:	0017871b          	addiw	a4,a5,1
    80005110:	20e4ac23          	sw	a4,536(s1)
    80005114:	1ff7f793          	andi	a5,a5,511
    80005118:	97a6                	add	a5,a5,s1
    8000511a:	0187c783          	lbu	a5,24(a5)
    8000511e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005122:	4685                	li	a3,1
    80005124:	fbf40613          	addi	a2,s0,-65
    80005128:	85ca                	mv	a1,s2
    8000512a:	050a3503          	ld	a0,80(s4)
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	54c080e7          	jalr	1356(ra) # 8000167a <copyout>
    80005136:	01650663          	beq	a0,s6,80005142 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000513a:	2985                	addiw	s3,s3,1
    8000513c:	0905                	addi	s2,s2,1
    8000513e:	fd3a91e3          	bne	s5,s3,80005100 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005142:	21c48513          	addi	a0,s1,540
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	45c080e7          	jalr	1116(ra) # 800025a2 <wakeup>
  release(&pi->lock);
    8000514e:	8526                	mv	a0,s1
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	b48080e7          	jalr	-1208(ra) # 80000c98 <release>
  return i;
}
    80005158:	854e                	mv	a0,s3
    8000515a:	60a6                	ld	ra,72(sp)
    8000515c:	6406                	ld	s0,64(sp)
    8000515e:	74e2                	ld	s1,56(sp)
    80005160:	7942                	ld	s2,48(sp)
    80005162:	79a2                	ld	s3,40(sp)
    80005164:	7a02                	ld	s4,32(sp)
    80005166:	6ae2                	ld	s5,24(sp)
    80005168:	6b42                	ld	s6,16(sp)
    8000516a:	6161                	addi	sp,sp,80
    8000516c:	8082                	ret
      release(&pi->lock);
    8000516e:	8526                	mv	a0,s1
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	b28080e7          	jalr	-1240(ra) # 80000c98 <release>
      return -1;
    80005178:	59fd                	li	s3,-1
    8000517a:	bff9                	j	80005158 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000517c:	4981                	li	s3,0
    8000517e:	b7d1                	j	80005142 <piperead+0xae>

0000000080005180 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005180:	df010113          	addi	sp,sp,-528
    80005184:	20113423          	sd	ra,520(sp)
    80005188:	20813023          	sd	s0,512(sp)
    8000518c:	ffa6                	sd	s1,504(sp)
    8000518e:	fbca                	sd	s2,496(sp)
    80005190:	f7ce                	sd	s3,488(sp)
    80005192:	f3d2                	sd	s4,480(sp)
    80005194:	efd6                	sd	s5,472(sp)
    80005196:	ebda                	sd	s6,464(sp)
    80005198:	e7de                	sd	s7,456(sp)
    8000519a:	e3e2                	sd	s8,448(sp)
    8000519c:	ff66                	sd	s9,440(sp)
    8000519e:	fb6a                	sd	s10,432(sp)
    800051a0:	f76e                	sd	s11,424(sp)
    800051a2:	0c00                	addi	s0,sp,528
    800051a4:	84aa                	mv	s1,a0
    800051a6:	dea43c23          	sd	a0,-520(s0)
    800051aa:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	928080e7          	jalr	-1752(ra) # 80001ad6 <myproc>
    800051b6:	892a                	mv	s2,a0

  begin_op();
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	49c080e7          	jalr	1180(ra) # 80004654 <begin_op>

  if((ip = namei(path)) == 0){
    800051c0:	8526                	mv	a0,s1
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	276080e7          	jalr	630(ra) # 80004438 <namei>
    800051ca:	c92d                	beqz	a0,8000523c <exec+0xbc>
    800051cc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	ab4080e7          	jalr	-1356(ra) # 80003c82 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051d6:	04000713          	li	a4,64
    800051da:	4681                	li	a3,0
    800051dc:	e5040613          	addi	a2,s0,-432
    800051e0:	4581                	li	a1,0
    800051e2:	8526                	mv	a0,s1
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	d52080e7          	jalr	-686(ra) # 80003f36 <readi>
    800051ec:	04000793          	li	a5,64
    800051f0:	00f51a63          	bne	a0,a5,80005204 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051f4:	e5042703          	lw	a4,-432(s0)
    800051f8:	464c47b7          	lui	a5,0x464c4
    800051fc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005200:	04f70463          	beq	a4,a5,80005248 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	cde080e7          	jalr	-802(ra) # 80003ee4 <iunlockput>
    end_op();
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	4c6080e7          	jalr	1222(ra) # 800046d4 <end_op>
  }
  return -1;
    80005216:	557d                	li	a0,-1
}
    80005218:	20813083          	ld	ra,520(sp)
    8000521c:	20013403          	ld	s0,512(sp)
    80005220:	74fe                	ld	s1,504(sp)
    80005222:	795e                	ld	s2,496(sp)
    80005224:	79be                	ld	s3,488(sp)
    80005226:	7a1e                	ld	s4,480(sp)
    80005228:	6afe                	ld	s5,472(sp)
    8000522a:	6b5e                	ld	s6,464(sp)
    8000522c:	6bbe                	ld	s7,456(sp)
    8000522e:	6c1e                	ld	s8,448(sp)
    80005230:	7cfa                	ld	s9,440(sp)
    80005232:	7d5a                	ld	s10,432(sp)
    80005234:	7dba                	ld	s11,424(sp)
    80005236:	21010113          	addi	sp,sp,528
    8000523a:	8082                	ret
    end_op();
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	498080e7          	jalr	1176(ra) # 800046d4 <end_op>
    return -1;
    80005244:	557d                	li	a0,-1
    80005246:	bfc9                	j	80005218 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005248:	854a                	mv	a0,s2
    8000524a:	ffffd097          	auipc	ra,0xffffd
    8000524e:	950080e7          	jalr	-1712(ra) # 80001b9a <proc_pagetable>
    80005252:	8baa                	mv	s7,a0
    80005254:	d945                	beqz	a0,80005204 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005256:	e7042983          	lw	s3,-400(s0)
    8000525a:	e8845783          	lhu	a5,-376(s0)
    8000525e:	c7ad                	beqz	a5,800052c8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005260:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005262:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005264:	6c85                	lui	s9,0x1
    80005266:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000526a:	def43823          	sd	a5,-528(s0)
    8000526e:	a42d                	j	80005498 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005270:	00003517          	auipc	a0,0x3
    80005274:	55850513          	addi	a0,a0,1368 # 800087c8 <syscalls+0x290>
    80005278:	ffffb097          	auipc	ra,0xffffb
    8000527c:	2c6080e7          	jalr	710(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005280:	8756                	mv	a4,s5
    80005282:	012d86bb          	addw	a3,s11,s2
    80005286:	4581                	li	a1,0
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	cac080e7          	jalr	-852(ra) # 80003f36 <readi>
    80005292:	2501                	sext.w	a0,a0
    80005294:	1aaa9963          	bne	s5,a0,80005446 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005298:	6785                	lui	a5,0x1
    8000529a:	0127893b          	addw	s2,a5,s2
    8000529e:	77fd                	lui	a5,0xfffff
    800052a0:	01478a3b          	addw	s4,a5,s4
    800052a4:	1f897163          	bgeu	s2,s8,80005486 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052a8:	02091593          	slli	a1,s2,0x20
    800052ac:	9181                	srli	a1,a1,0x20
    800052ae:	95ea                	add	a1,a1,s10
    800052b0:	855e                	mv	a0,s7
    800052b2:	ffffc097          	auipc	ra,0xffffc
    800052b6:	dc4080e7          	jalr	-572(ra) # 80001076 <walkaddr>
    800052ba:	862a                	mv	a2,a0
    if(pa == 0)
    800052bc:	d955                	beqz	a0,80005270 <exec+0xf0>
      n = PGSIZE;
    800052be:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052c0:	fd9a70e3          	bgeu	s4,s9,80005280 <exec+0x100>
      n = sz - i;
    800052c4:	8ad2                	mv	s5,s4
    800052c6:	bf6d                	j	80005280 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052c8:	4901                	li	s2,0
  iunlockput(ip);
    800052ca:	8526                	mv	a0,s1
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	c18080e7          	jalr	-1000(ra) # 80003ee4 <iunlockput>
  end_op();
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	400080e7          	jalr	1024(ra) # 800046d4 <end_op>
  p = myproc();
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	7fa080e7          	jalr	2042(ra) # 80001ad6 <myproc>
    800052e4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052e6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052ea:	6785                	lui	a5,0x1
    800052ec:	17fd                	addi	a5,a5,-1
    800052ee:	993e                	add	s2,s2,a5
    800052f0:	757d                	lui	a0,0xfffff
    800052f2:	00a977b3          	and	a5,s2,a0
    800052f6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052fa:	6609                	lui	a2,0x2
    800052fc:	963e                	add	a2,a2,a5
    800052fe:	85be                	mv	a1,a5
    80005300:	855e                	mv	a0,s7
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	128080e7          	jalr	296(ra) # 8000142a <uvmalloc>
    8000530a:	8b2a                	mv	s6,a0
  ip = 0;
    8000530c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000530e:	12050c63          	beqz	a0,80005446 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005312:	75f9                	lui	a1,0xffffe
    80005314:	95aa                	add	a1,a1,a0
    80005316:	855e                	mv	a0,s7
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	330080e7          	jalr	816(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005320:	7c7d                	lui	s8,0xfffff
    80005322:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005324:	e0043783          	ld	a5,-512(s0)
    80005328:	6388                	ld	a0,0(a5)
    8000532a:	c535                	beqz	a0,80005396 <exec+0x216>
    8000532c:	e9040993          	addi	s3,s0,-368
    80005330:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005334:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	b2e080e7          	jalr	-1234(ra) # 80000e64 <strlen>
    8000533e:	2505                	addiw	a0,a0,1
    80005340:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005344:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005348:	13896363          	bltu	s2,s8,8000546e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000534c:	e0043d83          	ld	s11,-512(s0)
    80005350:	000dba03          	ld	s4,0(s11)
    80005354:	8552                	mv	a0,s4
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	b0e080e7          	jalr	-1266(ra) # 80000e64 <strlen>
    8000535e:	0015069b          	addiw	a3,a0,1
    80005362:	8652                	mv	a2,s4
    80005364:	85ca                	mv	a1,s2
    80005366:	855e                	mv	a0,s7
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	312080e7          	jalr	786(ra) # 8000167a <copyout>
    80005370:	10054363          	bltz	a0,80005476 <exec+0x2f6>
    ustack[argc] = sp;
    80005374:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005378:	0485                	addi	s1,s1,1
    8000537a:	008d8793          	addi	a5,s11,8
    8000537e:	e0f43023          	sd	a5,-512(s0)
    80005382:	008db503          	ld	a0,8(s11)
    80005386:	c911                	beqz	a0,8000539a <exec+0x21a>
    if(argc >= MAXARG)
    80005388:	09a1                	addi	s3,s3,8
    8000538a:	fb3c96e3          	bne	s9,s3,80005336 <exec+0x1b6>
  sz = sz1;
    8000538e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005392:	4481                	li	s1,0
    80005394:	a84d                	j	80005446 <exec+0x2c6>
  sp = sz;
    80005396:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005398:	4481                	li	s1,0
  ustack[argc] = 0;
    8000539a:	00349793          	slli	a5,s1,0x3
    8000539e:	f9040713          	addi	a4,s0,-112
    800053a2:	97ba                	add	a5,a5,a4
    800053a4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053a8:	00148693          	addi	a3,s1,1
    800053ac:	068e                	slli	a3,a3,0x3
    800053ae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053b2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053b6:	01897663          	bgeu	s2,s8,800053c2 <exec+0x242>
  sz = sz1;
    800053ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053be:	4481                	li	s1,0
    800053c0:	a059                	j	80005446 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053c2:	e9040613          	addi	a2,s0,-368
    800053c6:	85ca                	mv	a1,s2
    800053c8:	855e                	mv	a0,s7
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	2b0080e7          	jalr	688(ra) # 8000167a <copyout>
    800053d2:	0a054663          	bltz	a0,8000547e <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053d6:	058ab783          	ld	a5,88(s5)
    800053da:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053de:	df843783          	ld	a5,-520(s0)
    800053e2:	0007c703          	lbu	a4,0(a5)
    800053e6:	cf11                	beqz	a4,80005402 <exec+0x282>
    800053e8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053ea:	02f00693          	li	a3,47
    800053ee:	a039                	j	800053fc <exec+0x27c>
      last = s+1;
    800053f0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053f4:	0785                	addi	a5,a5,1
    800053f6:	fff7c703          	lbu	a4,-1(a5)
    800053fa:	c701                	beqz	a4,80005402 <exec+0x282>
    if(*s == '/')
    800053fc:	fed71ce3          	bne	a4,a3,800053f4 <exec+0x274>
    80005400:	bfc5                	j	800053f0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005402:	4641                	li	a2,16
    80005404:	df843583          	ld	a1,-520(s0)
    80005408:	158a8513          	addi	a0,s5,344
    8000540c:	ffffc097          	auipc	ra,0xffffc
    80005410:	a26080e7          	jalr	-1498(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005414:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005418:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000541c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005420:	058ab783          	ld	a5,88(s5)
    80005424:	e6843703          	ld	a4,-408(s0)
    80005428:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000542a:	058ab783          	ld	a5,88(s5)
    8000542e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005432:	85ea                	mv	a1,s10
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	802080e7          	jalr	-2046(ra) # 80001c36 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000543c:	0004851b          	sext.w	a0,s1
    80005440:	bbe1                	j	80005218 <exec+0x98>
    80005442:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005446:	e0843583          	ld	a1,-504(s0)
    8000544a:	855e                	mv	a0,s7
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	7ea080e7          	jalr	2026(ra) # 80001c36 <proc_freepagetable>
  if(ip){
    80005454:	da0498e3          	bnez	s1,80005204 <exec+0x84>
  return -1;
    80005458:	557d                	li	a0,-1
    8000545a:	bb7d                	j	80005218 <exec+0x98>
    8000545c:	e1243423          	sd	s2,-504(s0)
    80005460:	b7dd                	j	80005446 <exec+0x2c6>
    80005462:	e1243423          	sd	s2,-504(s0)
    80005466:	b7c5                	j	80005446 <exec+0x2c6>
    80005468:	e1243423          	sd	s2,-504(s0)
    8000546c:	bfe9                	j	80005446 <exec+0x2c6>
  sz = sz1;
    8000546e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005472:	4481                	li	s1,0
    80005474:	bfc9                	j	80005446 <exec+0x2c6>
  sz = sz1;
    80005476:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000547a:	4481                	li	s1,0
    8000547c:	b7e9                	j	80005446 <exec+0x2c6>
  sz = sz1;
    8000547e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005482:	4481                	li	s1,0
    80005484:	b7c9                	j	80005446 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005486:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000548a:	2b05                	addiw	s6,s6,1
    8000548c:	0389899b          	addiw	s3,s3,56
    80005490:	e8845783          	lhu	a5,-376(s0)
    80005494:	e2fb5be3          	bge	s6,a5,800052ca <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005498:	2981                	sext.w	s3,s3
    8000549a:	03800713          	li	a4,56
    8000549e:	86ce                	mv	a3,s3
    800054a0:	e1840613          	addi	a2,s0,-488
    800054a4:	4581                	li	a1,0
    800054a6:	8526                	mv	a0,s1
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	a8e080e7          	jalr	-1394(ra) # 80003f36 <readi>
    800054b0:	03800793          	li	a5,56
    800054b4:	f8f517e3          	bne	a0,a5,80005442 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054b8:	e1842783          	lw	a5,-488(s0)
    800054bc:	4705                	li	a4,1
    800054be:	fce796e3          	bne	a5,a4,8000548a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054c2:	e4043603          	ld	a2,-448(s0)
    800054c6:	e3843783          	ld	a5,-456(s0)
    800054ca:	f8f669e3          	bltu	a2,a5,8000545c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054ce:	e2843783          	ld	a5,-472(s0)
    800054d2:	963e                	add	a2,a2,a5
    800054d4:	f8f667e3          	bltu	a2,a5,80005462 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054d8:	85ca                	mv	a1,s2
    800054da:	855e                	mv	a0,s7
    800054dc:	ffffc097          	auipc	ra,0xffffc
    800054e0:	f4e080e7          	jalr	-178(ra) # 8000142a <uvmalloc>
    800054e4:	e0a43423          	sd	a0,-504(s0)
    800054e8:	d141                	beqz	a0,80005468 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800054ea:	e2843d03          	ld	s10,-472(s0)
    800054ee:	df043783          	ld	a5,-528(s0)
    800054f2:	00fd77b3          	and	a5,s10,a5
    800054f6:	fba1                	bnez	a5,80005446 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054f8:	e2042d83          	lw	s11,-480(s0)
    800054fc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005500:	f80c03e3          	beqz	s8,80005486 <exec+0x306>
    80005504:	8a62                	mv	s4,s8
    80005506:	4901                	li	s2,0
    80005508:	b345                	j	800052a8 <exec+0x128>

000000008000550a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000550a:	7179                	addi	sp,sp,-48
    8000550c:	f406                	sd	ra,40(sp)
    8000550e:	f022                	sd	s0,32(sp)
    80005510:	ec26                	sd	s1,24(sp)
    80005512:	e84a                	sd	s2,16(sp)
    80005514:	1800                	addi	s0,sp,48
    80005516:	892e                	mv	s2,a1
    80005518:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000551a:	fdc40593          	addi	a1,s0,-36
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	9a8080e7          	jalr	-1624(ra) # 80002ec6 <argint>
    80005526:	04054063          	bltz	a0,80005566 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000552a:	fdc42703          	lw	a4,-36(s0)
    8000552e:	47bd                	li	a5,15
    80005530:	02e7ed63          	bltu	a5,a4,8000556a <argfd+0x60>
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	5a2080e7          	jalr	1442(ra) # 80001ad6 <myproc>
    8000553c:	fdc42703          	lw	a4,-36(s0)
    80005540:	01a70793          	addi	a5,a4,26
    80005544:	078e                	slli	a5,a5,0x3
    80005546:	953e                	add	a0,a0,a5
    80005548:	611c                	ld	a5,0(a0)
    8000554a:	c395                	beqz	a5,8000556e <argfd+0x64>
    return -1;
  if(pfd)
    8000554c:	00090463          	beqz	s2,80005554 <argfd+0x4a>
    *pfd = fd;
    80005550:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005554:	4501                	li	a0,0
  if(pf)
    80005556:	c091                	beqz	s1,8000555a <argfd+0x50>
    *pf = f;
    80005558:	e09c                	sd	a5,0(s1)
}
    8000555a:	70a2                	ld	ra,40(sp)
    8000555c:	7402                	ld	s0,32(sp)
    8000555e:	64e2                	ld	s1,24(sp)
    80005560:	6942                	ld	s2,16(sp)
    80005562:	6145                	addi	sp,sp,48
    80005564:	8082                	ret
    return -1;
    80005566:	557d                	li	a0,-1
    80005568:	bfcd                	j	8000555a <argfd+0x50>
    return -1;
    8000556a:	557d                	li	a0,-1
    8000556c:	b7fd                	j	8000555a <argfd+0x50>
    8000556e:	557d                	li	a0,-1
    80005570:	b7ed                	j	8000555a <argfd+0x50>

0000000080005572 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005572:	1101                	addi	sp,sp,-32
    80005574:	ec06                	sd	ra,24(sp)
    80005576:	e822                	sd	s0,16(sp)
    80005578:	e426                	sd	s1,8(sp)
    8000557a:	1000                	addi	s0,sp,32
    8000557c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	558080e7          	jalr	1368(ra) # 80001ad6 <myproc>
    80005586:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005588:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd70d0>
    8000558c:	4501                	li	a0,0
    8000558e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005590:	6398                	ld	a4,0(a5)
    80005592:	cb19                	beqz	a4,800055a8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005594:	2505                	addiw	a0,a0,1
    80005596:	07a1                	addi	a5,a5,8
    80005598:	fed51ce3          	bne	a0,a3,80005590 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000559c:	557d                	li	a0,-1
}
    8000559e:	60e2                	ld	ra,24(sp)
    800055a0:	6442                	ld	s0,16(sp)
    800055a2:	64a2                	ld	s1,8(sp)
    800055a4:	6105                	addi	sp,sp,32
    800055a6:	8082                	ret
      p->ofile[fd] = f;
    800055a8:	01a50793          	addi	a5,a0,26
    800055ac:	078e                	slli	a5,a5,0x3
    800055ae:	963e                	add	a2,a2,a5
    800055b0:	e204                	sd	s1,0(a2)
      return fd;
    800055b2:	b7f5                	j	8000559e <fdalloc+0x2c>

00000000800055b4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055b4:	715d                	addi	sp,sp,-80
    800055b6:	e486                	sd	ra,72(sp)
    800055b8:	e0a2                	sd	s0,64(sp)
    800055ba:	fc26                	sd	s1,56(sp)
    800055bc:	f84a                	sd	s2,48(sp)
    800055be:	f44e                	sd	s3,40(sp)
    800055c0:	f052                	sd	s4,32(sp)
    800055c2:	ec56                	sd	s5,24(sp)
    800055c4:	0880                	addi	s0,sp,80
    800055c6:	89ae                	mv	s3,a1
    800055c8:	8ab2                	mv	s5,a2
    800055ca:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055cc:	fb040593          	addi	a1,s0,-80
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	e86080e7          	jalr	-378(ra) # 80004456 <nameiparent>
    800055d8:	892a                	mv	s2,a0
    800055da:	12050f63          	beqz	a0,80005718 <create+0x164>
    return 0;

  ilock(dp);
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	6a4080e7          	jalr	1700(ra) # 80003c82 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055e6:	4601                	li	a2,0
    800055e8:	fb040593          	addi	a1,s0,-80
    800055ec:	854a                	mv	a0,s2
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	b78080e7          	jalr	-1160(ra) # 80004166 <dirlookup>
    800055f6:	84aa                	mv	s1,a0
    800055f8:	c921                	beqz	a0,80005648 <create+0x94>
    iunlockput(dp);
    800055fa:	854a                	mv	a0,s2
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	8e8080e7          	jalr	-1816(ra) # 80003ee4 <iunlockput>
    ilock(ip);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	67c080e7          	jalr	1660(ra) # 80003c82 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000560e:	2981                	sext.w	s3,s3
    80005610:	4789                	li	a5,2
    80005612:	02f99463          	bne	s3,a5,8000563a <create+0x86>
    80005616:	0444d783          	lhu	a5,68(s1)
    8000561a:	37f9                	addiw	a5,a5,-2
    8000561c:	17c2                	slli	a5,a5,0x30
    8000561e:	93c1                	srli	a5,a5,0x30
    80005620:	4705                	li	a4,1
    80005622:	00f76c63          	bltu	a4,a5,8000563a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005626:	8526                	mv	a0,s1
    80005628:	60a6                	ld	ra,72(sp)
    8000562a:	6406                	ld	s0,64(sp)
    8000562c:	74e2                	ld	s1,56(sp)
    8000562e:	7942                	ld	s2,48(sp)
    80005630:	79a2                	ld	s3,40(sp)
    80005632:	7a02                	ld	s4,32(sp)
    80005634:	6ae2                	ld	s5,24(sp)
    80005636:	6161                	addi	sp,sp,80
    80005638:	8082                	ret
    iunlockput(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	8a8080e7          	jalr	-1880(ra) # 80003ee4 <iunlockput>
    return 0;
    80005644:	4481                	li	s1,0
    80005646:	b7c5                	j	80005626 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005648:	85ce                	mv	a1,s3
    8000564a:	00092503          	lw	a0,0(s2)
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	49c080e7          	jalr	1180(ra) # 80003aea <ialloc>
    80005656:	84aa                	mv	s1,a0
    80005658:	c529                	beqz	a0,800056a2 <create+0xee>
  ilock(ip);
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	628080e7          	jalr	1576(ra) # 80003c82 <ilock>
  ip->major = major;
    80005662:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005666:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000566a:	4785                	li	a5,1
    8000566c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	546080e7          	jalr	1350(ra) # 80003bb8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000567a:	2981                	sext.w	s3,s3
    8000567c:	4785                	li	a5,1
    8000567e:	02f98a63          	beq	s3,a5,800056b2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005682:	40d0                	lw	a2,4(s1)
    80005684:	fb040593          	addi	a1,s0,-80
    80005688:	854a                	mv	a0,s2
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	cec080e7          	jalr	-788(ra) # 80004376 <dirlink>
    80005692:	06054b63          	bltz	a0,80005708 <create+0x154>
  iunlockput(dp);
    80005696:	854a                	mv	a0,s2
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	84c080e7          	jalr	-1972(ra) # 80003ee4 <iunlockput>
  return ip;
    800056a0:	b759                	j	80005626 <create+0x72>
    panic("create: ialloc");
    800056a2:	00003517          	auipc	a0,0x3
    800056a6:	14650513          	addi	a0,a0,326 # 800087e8 <syscalls+0x2b0>
    800056aa:	ffffb097          	auipc	ra,0xffffb
    800056ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056b2:	04a95783          	lhu	a5,74(s2)
    800056b6:	2785                	addiw	a5,a5,1
    800056b8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056bc:	854a                	mv	a0,s2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	4fa080e7          	jalr	1274(ra) # 80003bb8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056c6:	40d0                	lw	a2,4(s1)
    800056c8:	00003597          	auipc	a1,0x3
    800056cc:	13058593          	addi	a1,a1,304 # 800087f8 <syscalls+0x2c0>
    800056d0:	8526                	mv	a0,s1
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	ca4080e7          	jalr	-860(ra) # 80004376 <dirlink>
    800056da:	00054f63          	bltz	a0,800056f8 <create+0x144>
    800056de:	00492603          	lw	a2,4(s2)
    800056e2:	00003597          	auipc	a1,0x3
    800056e6:	11e58593          	addi	a1,a1,286 # 80008800 <syscalls+0x2c8>
    800056ea:	8526                	mv	a0,s1
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	c8a080e7          	jalr	-886(ra) # 80004376 <dirlink>
    800056f4:	f80557e3          	bgez	a0,80005682 <create+0xce>
      panic("create dots");
    800056f8:	00003517          	auipc	a0,0x3
    800056fc:	11050513          	addi	a0,a0,272 # 80008808 <syscalls+0x2d0>
    80005700:	ffffb097          	auipc	ra,0xffffb
    80005704:	e3e080e7          	jalr	-450(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005708:	00003517          	auipc	a0,0x3
    8000570c:	11050513          	addi	a0,a0,272 # 80008818 <syscalls+0x2e0>
    80005710:	ffffb097          	auipc	ra,0xffffb
    80005714:	e2e080e7          	jalr	-466(ra) # 8000053e <panic>
    return 0;
    80005718:	84aa                	mv	s1,a0
    8000571a:	b731                	j	80005626 <create+0x72>

000000008000571c <sys_dup>:
{
    8000571c:	7179                	addi	sp,sp,-48
    8000571e:	f406                	sd	ra,40(sp)
    80005720:	f022                	sd	s0,32(sp)
    80005722:	ec26                	sd	s1,24(sp)
    80005724:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005726:	fd840613          	addi	a2,s0,-40
    8000572a:	4581                	li	a1,0
    8000572c:	4501                	li	a0,0
    8000572e:	00000097          	auipc	ra,0x0
    80005732:	ddc080e7          	jalr	-548(ra) # 8000550a <argfd>
    return -1;
    80005736:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005738:	02054363          	bltz	a0,8000575e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000573c:	fd843503          	ld	a0,-40(s0)
    80005740:	00000097          	auipc	ra,0x0
    80005744:	e32080e7          	jalr	-462(ra) # 80005572 <fdalloc>
    80005748:	84aa                	mv	s1,a0
    return -1;
    8000574a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000574c:	00054963          	bltz	a0,8000575e <sys_dup+0x42>
  filedup(f);
    80005750:	fd843503          	ld	a0,-40(s0)
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	37a080e7          	jalr	890(ra) # 80004ace <filedup>
  return fd;
    8000575c:	87a6                	mv	a5,s1
}
    8000575e:	853e                	mv	a0,a5
    80005760:	70a2                	ld	ra,40(sp)
    80005762:	7402                	ld	s0,32(sp)
    80005764:	64e2                	ld	s1,24(sp)
    80005766:	6145                	addi	sp,sp,48
    80005768:	8082                	ret

000000008000576a <sys_read>:
{
    8000576a:	7179                	addi	sp,sp,-48
    8000576c:	f406                	sd	ra,40(sp)
    8000576e:	f022                	sd	s0,32(sp)
    80005770:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005772:	fe840613          	addi	a2,s0,-24
    80005776:	4581                	li	a1,0
    80005778:	4501                	li	a0,0
    8000577a:	00000097          	auipc	ra,0x0
    8000577e:	d90080e7          	jalr	-624(ra) # 8000550a <argfd>
    return -1;
    80005782:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005784:	04054163          	bltz	a0,800057c6 <sys_read+0x5c>
    80005788:	fe440593          	addi	a1,s0,-28
    8000578c:	4509                	li	a0,2
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	738080e7          	jalr	1848(ra) # 80002ec6 <argint>
    return -1;
    80005796:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005798:	02054763          	bltz	a0,800057c6 <sys_read+0x5c>
    8000579c:	fd840593          	addi	a1,s0,-40
    800057a0:	4505                	li	a0,1
    800057a2:	ffffd097          	auipc	ra,0xffffd
    800057a6:	746080e7          	jalr	1862(ra) # 80002ee8 <argaddr>
    return -1;
    800057aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ac:	00054d63          	bltz	a0,800057c6 <sys_read+0x5c>
  return fileread(f, p, n);
    800057b0:	fe442603          	lw	a2,-28(s0)
    800057b4:	fd843583          	ld	a1,-40(s0)
    800057b8:	fe843503          	ld	a0,-24(s0)
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	49e080e7          	jalr	1182(ra) # 80004c5a <fileread>
    800057c4:	87aa                	mv	a5,a0
}
    800057c6:	853e                	mv	a0,a5
    800057c8:	70a2                	ld	ra,40(sp)
    800057ca:	7402                	ld	s0,32(sp)
    800057cc:	6145                	addi	sp,sp,48
    800057ce:	8082                	ret

00000000800057d0 <sys_write>:
{
    800057d0:	7179                	addi	sp,sp,-48
    800057d2:	f406                	sd	ra,40(sp)
    800057d4:	f022                	sd	s0,32(sp)
    800057d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057d8:	fe840613          	addi	a2,s0,-24
    800057dc:	4581                	li	a1,0
    800057de:	4501                	li	a0,0
    800057e0:	00000097          	auipc	ra,0x0
    800057e4:	d2a080e7          	jalr	-726(ra) # 8000550a <argfd>
    return -1;
    800057e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ea:	04054163          	bltz	a0,8000582c <sys_write+0x5c>
    800057ee:	fe440593          	addi	a1,s0,-28
    800057f2:	4509                	li	a0,2
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	6d2080e7          	jalr	1746(ra) # 80002ec6 <argint>
    return -1;
    800057fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fe:	02054763          	bltz	a0,8000582c <sys_write+0x5c>
    80005802:	fd840593          	addi	a1,s0,-40
    80005806:	4505                	li	a0,1
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	6e0080e7          	jalr	1760(ra) # 80002ee8 <argaddr>
    return -1;
    80005810:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005812:	00054d63          	bltz	a0,8000582c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005816:	fe442603          	lw	a2,-28(s0)
    8000581a:	fd843583          	ld	a1,-40(s0)
    8000581e:	fe843503          	ld	a0,-24(s0)
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	4fa080e7          	jalr	1274(ra) # 80004d1c <filewrite>
    8000582a:	87aa                	mv	a5,a0
}
    8000582c:	853e                	mv	a0,a5
    8000582e:	70a2                	ld	ra,40(sp)
    80005830:	7402                	ld	s0,32(sp)
    80005832:	6145                	addi	sp,sp,48
    80005834:	8082                	ret

0000000080005836 <sys_close>:
{
    80005836:	1101                	addi	sp,sp,-32
    80005838:	ec06                	sd	ra,24(sp)
    8000583a:	e822                	sd	s0,16(sp)
    8000583c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000583e:	fe040613          	addi	a2,s0,-32
    80005842:	fec40593          	addi	a1,s0,-20
    80005846:	4501                	li	a0,0
    80005848:	00000097          	auipc	ra,0x0
    8000584c:	cc2080e7          	jalr	-830(ra) # 8000550a <argfd>
    return -1;
    80005850:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005852:	02054463          	bltz	a0,8000587a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005856:	ffffc097          	auipc	ra,0xffffc
    8000585a:	280080e7          	jalr	640(ra) # 80001ad6 <myproc>
    8000585e:	fec42783          	lw	a5,-20(s0)
    80005862:	07e9                	addi	a5,a5,26
    80005864:	078e                	slli	a5,a5,0x3
    80005866:	97aa                	add	a5,a5,a0
    80005868:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000586c:	fe043503          	ld	a0,-32(s0)
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	2b0080e7          	jalr	688(ra) # 80004b20 <fileclose>
  return 0;
    80005878:	4781                	li	a5,0
}
    8000587a:	853e                	mv	a0,a5
    8000587c:	60e2                	ld	ra,24(sp)
    8000587e:	6442                	ld	s0,16(sp)
    80005880:	6105                	addi	sp,sp,32
    80005882:	8082                	ret

0000000080005884 <sys_fstat>:
{
    80005884:	1101                	addi	sp,sp,-32
    80005886:	ec06                	sd	ra,24(sp)
    80005888:	e822                	sd	s0,16(sp)
    8000588a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000588c:	fe840613          	addi	a2,s0,-24
    80005890:	4581                	li	a1,0
    80005892:	4501                	li	a0,0
    80005894:	00000097          	auipc	ra,0x0
    80005898:	c76080e7          	jalr	-906(ra) # 8000550a <argfd>
    return -1;
    8000589c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000589e:	02054563          	bltz	a0,800058c8 <sys_fstat+0x44>
    800058a2:	fe040593          	addi	a1,s0,-32
    800058a6:	4505                	li	a0,1
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	640080e7          	jalr	1600(ra) # 80002ee8 <argaddr>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058b2:	00054b63          	bltz	a0,800058c8 <sys_fstat+0x44>
  return filestat(f, st);
    800058b6:	fe043583          	ld	a1,-32(s0)
    800058ba:	fe843503          	ld	a0,-24(s0)
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	32a080e7          	jalr	810(ra) # 80004be8 <filestat>
    800058c6:	87aa                	mv	a5,a0
}
    800058c8:	853e                	mv	a0,a5
    800058ca:	60e2                	ld	ra,24(sp)
    800058cc:	6442                	ld	s0,16(sp)
    800058ce:	6105                	addi	sp,sp,32
    800058d0:	8082                	ret

00000000800058d2 <sys_link>:
{
    800058d2:	7169                	addi	sp,sp,-304
    800058d4:	f606                	sd	ra,296(sp)
    800058d6:	f222                	sd	s0,288(sp)
    800058d8:	ee26                	sd	s1,280(sp)
    800058da:	ea4a                	sd	s2,272(sp)
    800058dc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058de:	08000613          	li	a2,128
    800058e2:	ed040593          	addi	a1,s0,-304
    800058e6:	4501                	li	a0,0
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	622080e7          	jalr	1570(ra) # 80002f0a <argstr>
    return -1;
    800058f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058f2:	10054e63          	bltz	a0,80005a0e <sys_link+0x13c>
    800058f6:	08000613          	li	a2,128
    800058fa:	f5040593          	addi	a1,s0,-176
    800058fe:	4505                	li	a0,1
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	60a080e7          	jalr	1546(ra) # 80002f0a <argstr>
    return -1;
    80005908:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000590a:	10054263          	bltz	a0,80005a0e <sys_link+0x13c>
  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	d46080e7          	jalr	-698(ra) # 80004654 <begin_op>
  if((ip = namei(old)) == 0){
    80005916:	ed040513          	addi	a0,s0,-304
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	b1e080e7          	jalr	-1250(ra) # 80004438 <namei>
    80005922:	84aa                	mv	s1,a0
    80005924:	c551                	beqz	a0,800059b0 <sys_link+0xde>
  ilock(ip);
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	35c080e7          	jalr	860(ra) # 80003c82 <ilock>
  if(ip->type == T_DIR){
    8000592e:	04449703          	lh	a4,68(s1)
    80005932:	4785                	li	a5,1
    80005934:	08f70463          	beq	a4,a5,800059bc <sys_link+0xea>
  ip->nlink++;
    80005938:	04a4d783          	lhu	a5,74(s1)
    8000593c:	2785                	addiw	a5,a5,1
    8000593e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	274080e7          	jalr	628(ra) # 80003bb8 <iupdate>
  iunlock(ip);
    8000594c:	8526                	mv	a0,s1
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	3f6080e7          	jalr	1014(ra) # 80003d44 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005956:	fd040593          	addi	a1,s0,-48
    8000595a:	f5040513          	addi	a0,s0,-176
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	af8080e7          	jalr	-1288(ra) # 80004456 <nameiparent>
    80005966:	892a                	mv	s2,a0
    80005968:	c935                	beqz	a0,800059dc <sys_link+0x10a>
  ilock(dp);
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	318080e7          	jalr	792(ra) # 80003c82 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005972:	00092703          	lw	a4,0(s2)
    80005976:	409c                	lw	a5,0(s1)
    80005978:	04f71d63          	bne	a4,a5,800059d2 <sys_link+0x100>
    8000597c:	40d0                	lw	a2,4(s1)
    8000597e:	fd040593          	addi	a1,s0,-48
    80005982:	854a                	mv	a0,s2
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	9f2080e7          	jalr	-1550(ra) # 80004376 <dirlink>
    8000598c:	04054363          	bltz	a0,800059d2 <sys_link+0x100>
  iunlockput(dp);
    80005990:	854a                	mv	a0,s2
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	552080e7          	jalr	1362(ra) # 80003ee4 <iunlockput>
  iput(ip);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	4a0080e7          	jalr	1184(ra) # 80003e3c <iput>
  end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	d30080e7          	jalr	-720(ra) # 800046d4 <end_op>
  return 0;
    800059ac:	4781                	li	a5,0
    800059ae:	a085                	j	80005a0e <sys_link+0x13c>
    end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	d24080e7          	jalr	-732(ra) # 800046d4 <end_op>
    return -1;
    800059b8:	57fd                	li	a5,-1
    800059ba:	a891                	j	80005a0e <sys_link+0x13c>
    iunlockput(ip);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	526080e7          	jalr	1318(ra) # 80003ee4 <iunlockput>
    end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	d0e080e7          	jalr	-754(ra) # 800046d4 <end_op>
    return -1;
    800059ce:	57fd                	li	a5,-1
    800059d0:	a83d                	j	80005a0e <sys_link+0x13c>
    iunlockput(dp);
    800059d2:	854a                	mv	a0,s2
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	510080e7          	jalr	1296(ra) # 80003ee4 <iunlockput>
  ilock(ip);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	2a4080e7          	jalr	676(ra) # 80003c82 <ilock>
  ip->nlink--;
    800059e6:	04a4d783          	lhu	a5,74(s1)
    800059ea:	37fd                	addiw	a5,a5,-1
    800059ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	1c6080e7          	jalr	454(ra) # 80003bb8 <iupdate>
  iunlockput(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	4e8080e7          	jalr	1256(ra) # 80003ee4 <iunlockput>
  end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	cd0080e7          	jalr	-816(ra) # 800046d4 <end_op>
  return -1;
    80005a0c:	57fd                	li	a5,-1
}
    80005a0e:	853e                	mv	a0,a5
    80005a10:	70b2                	ld	ra,296(sp)
    80005a12:	7412                	ld	s0,288(sp)
    80005a14:	64f2                	ld	s1,280(sp)
    80005a16:	6952                	ld	s2,272(sp)
    80005a18:	6155                	addi	sp,sp,304
    80005a1a:	8082                	ret

0000000080005a1c <sys_unlink>:
{
    80005a1c:	7151                	addi	sp,sp,-240
    80005a1e:	f586                	sd	ra,232(sp)
    80005a20:	f1a2                	sd	s0,224(sp)
    80005a22:	eda6                	sd	s1,216(sp)
    80005a24:	e9ca                	sd	s2,208(sp)
    80005a26:	e5ce                	sd	s3,200(sp)
    80005a28:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a2a:	08000613          	li	a2,128
    80005a2e:	f3040593          	addi	a1,s0,-208
    80005a32:	4501                	li	a0,0
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	4d6080e7          	jalr	1238(ra) # 80002f0a <argstr>
    80005a3c:	18054163          	bltz	a0,80005bbe <sys_unlink+0x1a2>
  begin_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	c14080e7          	jalr	-1004(ra) # 80004654 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a48:	fb040593          	addi	a1,s0,-80
    80005a4c:	f3040513          	addi	a0,s0,-208
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	a06080e7          	jalr	-1530(ra) # 80004456 <nameiparent>
    80005a58:	84aa                	mv	s1,a0
    80005a5a:	c979                	beqz	a0,80005b30 <sys_unlink+0x114>
  ilock(dp);
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	226080e7          	jalr	550(ra) # 80003c82 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a64:	00003597          	auipc	a1,0x3
    80005a68:	d9458593          	addi	a1,a1,-620 # 800087f8 <syscalls+0x2c0>
    80005a6c:	fb040513          	addi	a0,s0,-80
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	6dc080e7          	jalr	1756(ra) # 8000414c <namecmp>
    80005a78:	14050a63          	beqz	a0,80005bcc <sys_unlink+0x1b0>
    80005a7c:	00003597          	auipc	a1,0x3
    80005a80:	d8458593          	addi	a1,a1,-636 # 80008800 <syscalls+0x2c8>
    80005a84:	fb040513          	addi	a0,s0,-80
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	6c4080e7          	jalr	1732(ra) # 8000414c <namecmp>
    80005a90:	12050e63          	beqz	a0,80005bcc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a94:	f2c40613          	addi	a2,s0,-212
    80005a98:	fb040593          	addi	a1,s0,-80
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	6c8080e7          	jalr	1736(ra) # 80004166 <dirlookup>
    80005aa6:	892a                	mv	s2,a0
    80005aa8:	12050263          	beqz	a0,80005bcc <sys_unlink+0x1b0>
  ilock(ip);
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	1d6080e7          	jalr	470(ra) # 80003c82 <ilock>
  if(ip->nlink < 1)
    80005ab4:	04a91783          	lh	a5,74(s2)
    80005ab8:	08f05263          	blez	a5,80005b3c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005abc:	04491703          	lh	a4,68(s2)
    80005ac0:	4785                	li	a5,1
    80005ac2:	08f70563          	beq	a4,a5,80005b4c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ac6:	4641                	li	a2,16
    80005ac8:	4581                	li	a1,0
    80005aca:	fc040513          	addi	a0,s0,-64
    80005ace:	ffffb097          	auipc	ra,0xffffb
    80005ad2:	212080e7          	jalr	530(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ad6:	4741                	li	a4,16
    80005ad8:	f2c42683          	lw	a3,-212(s0)
    80005adc:	fc040613          	addi	a2,s0,-64
    80005ae0:	4581                	li	a1,0
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	54a080e7          	jalr	1354(ra) # 8000402e <writei>
    80005aec:	47c1                	li	a5,16
    80005aee:	0af51563          	bne	a0,a5,80005b98 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005af2:	04491703          	lh	a4,68(s2)
    80005af6:	4785                	li	a5,1
    80005af8:	0af70863          	beq	a4,a5,80005ba8 <sys_unlink+0x18c>
  iunlockput(dp);
    80005afc:	8526                	mv	a0,s1
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	3e6080e7          	jalr	998(ra) # 80003ee4 <iunlockput>
  ip->nlink--;
    80005b06:	04a95783          	lhu	a5,74(s2)
    80005b0a:	37fd                	addiw	a5,a5,-1
    80005b0c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b10:	854a                	mv	a0,s2
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	0a6080e7          	jalr	166(ra) # 80003bb8 <iupdate>
  iunlockput(ip);
    80005b1a:	854a                	mv	a0,s2
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	3c8080e7          	jalr	968(ra) # 80003ee4 <iunlockput>
  end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	bb0080e7          	jalr	-1104(ra) # 800046d4 <end_op>
  return 0;
    80005b2c:	4501                	li	a0,0
    80005b2e:	a84d                	j	80005be0 <sys_unlink+0x1c4>
    end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	ba4080e7          	jalr	-1116(ra) # 800046d4 <end_op>
    return -1;
    80005b38:	557d                	li	a0,-1
    80005b3a:	a05d                	j	80005be0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b3c:	00003517          	auipc	a0,0x3
    80005b40:	cec50513          	addi	a0,a0,-788 # 80008828 <syscalls+0x2f0>
    80005b44:	ffffb097          	auipc	ra,0xffffb
    80005b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b4c:	04c92703          	lw	a4,76(s2)
    80005b50:	02000793          	li	a5,32
    80005b54:	f6e7f9e3          	bgeu	a5,a4,80005ac6 <sys_unlink+0xaa>
    80005b58:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b5c:	4741                	li	a4,16
    80005b5e:	86ce                	mv	a3,s3
    80005b60:	f1840613          	addi	a2,s0,-232
    80005b64:	4581                	li	a1,0
    80005b66:	854a                	mv	a0,s2
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	3ce080e7          	jalr	974(ra) # 80003f36 <readi>
    80005b70:	47c1                	li	a5,16
    80005b72:	00f51b63          	bne	a0,a5,80005b88 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b76:	f1845783          	lhu	a5,-232(s0)
    80005b7a:	e7a1                	bnez	a5,80005bc2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b7c:	29c1                	addiw	s3,s3,16
    80005b7e:	04c92783          	lw	a5,76(s2)
    80005b82:	fcf9ede3          	bltu	s3,a5,80005b5c <sys_unlink+0x140>
    80005b86:	b781                	j	80005ac6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b88:	00003517          	auipc	a0,0x3
    80005b8c:	cb850513          	addi	a0,a0,-840 # 80008840 <syscalls+0x308>
    80005b90:	ffffb097          	auipc	ra,0xffffb
    80005b94:	9ae080e7          	jalr	-1618(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b98:	00003517          	auipc	a0,0x3
    80005b9c:	cc050513          	addi	a0,a0,-832 # 80008858 <syscalls+0x320>
    80005ba0:	ffffb097          	auipc	ra,0xffffb
    80005ba4:	99e080e7          	jalr	-1634(ra) # 8000053e <panic>
    dp->nlink--;
    80005ba8:	04a4d783          	lhu	a5,74(s1)
    80005bac:	37fd                	addiw	a5,a5,-1
    80005bae:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bb2:	8526                	mv	a0,s1
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	004080e7          	jalr	4(ra) # 80003bb8 <iupdate>
    80005bbc:	b781                	j	80005afc <sys_unlink+0xe0>
    return -1;
    80005bbe:	557d                	li	a0,-1
    80005bc0:	a005                	j	80005be0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bc2:	854a                	mv	a0,s2
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	320080e7          	jalr	800(ra) # 80003ee4 <iunlockput>
  iunlockput(dp);
    80005bcc:	8526                	mv	a0,s1
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	316080e7          	jalr	790(ra) # 80003ee4 <iunlockput>
  end_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	afe080e7          	jalr	-1282(ra) # 800046d4 <end_op>
  return -1;
    80005bde:	557d                	li	a0,-1
}
    80005be0:	70ae                	ld	ra,232(sp)
    80005be2:	740e                	ld	s0,224(sp)
    80005be4:	64ee                	ld	s1,216(sp)
    80005be6:	694e                	ld	s2,208(sp)
    80005be8:	69ae                	ld	s3,200(sp)
    80005bea:	616d                	addi	sp,sp,240
    80005bec:	8082                	ret

0000000080005bee <sys_open>:

uint64
sys_open(void)
{
    80005bee:	7131                	addi	sp,sp,-192
    80005bf0:	fd06                	sd	ra,184(sp)
    80005bf2:	f922                	sd	s0,176(sp)
    80005bf4:	f526                	sd	s1,168(sp)
    80005bf6:	f14a                	sd	s2,160(sp)
    80005bf8:	ed4e                	sd	s3,152(sp)
    80005bfa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bfc:	08000613          	li	a2,128
    80005c00:	f5040593          	addi	a1,s0,-176
    80005c04:	4501                	li	a0,0
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	304080e7          	jalr	772(ra) # 80002f0a <argstr>
    return -1;
    80005c0e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c10:	0c054163          	bltz	a0,80005cd2 <sys_open+0xe4>
    80005c14:	f4c40593          	addi	a1,s0,-180
    80005c18:	4505                	li	a0,1
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	2ac080e7          	jalr	684(ra) # 80002ec6 <argint>
    80005c22:	0a054863          	bltz	a0,80005cd2 <sys_open+0xe4>

  begin_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	a2e080e7          	jalr	-1490(ra) # 80004654 <begin_op>

  if(omode & O_CREATE){
    80005c2e:	f4c42783          	lw	a5,-180(s0)
    80005c32:	2007f793          	andi	a5,a5,512
    80005c36:	cbdd                	beqz	a5,80005cec <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c38:	4681                	li	a3,0
    80005c3a:	4601                	li	a2,0
    80005c3c:	4589                	li	a1,2
    80005c3e:	f5040513          	addi	a0,s0,-176
    80005c42:	00000097          	auipc	ra,0x0
    80005c46:	972080e7          	jalr	-1678(ra) # 800055b4 <create>
    80005c4a:	892a                	mv	s2,a0
    if(ip == 0){
    80005c4c:	c959                	beqz	a0,80005ce2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c4e:	04491703          	lh	a4,68(s2)
    80005c52:	478d                	li	a5,3
    80005c54:	00f71763          	bne	a4,a5,80005c62 <sys_open+0x74>
    80005c58:	04695703          	lhu	a4,70(s2)
    80005c5c:	47a5                	li	a5,9
    80005c5e:	0ce7ec63          	bltu	a5,a4,80005d36 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	e02080e7          	jalr	-510(ra) # 80004a64 <filealloc>
    80005c6a:	89aa                	mv	s3,a0
    80005c6c:	10050263          	beqz	a0,80005d70 <sys_open+0x182>
    80005c70:	00000097          	auipc	ra,0x0
    80005c74:	902080e7          	jalr	-1790(ra) # 80005572 <fdalloc>
    80005c78:	84aa                	mv	s1,a0
    80005c7a:	0e054663          	bltz	a0,80005d66 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c7e:	04491703          	lh	a4,68(s2)
    80005c82:	478d                	li	a5,3
    80005c84:	0cf70463          	beq	a4,a5,80005d4c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c88:	4789                	li	a5,2
    80005c8a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c8e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c92:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c96:	f4c42783          	lw	a5,-180(s0)
    80005c9a:	0017c713          	xori	a4,a5,1
    80005c9e:	8b05                	andi	a4,a4,1
    80005ca0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ca4:	0037f713          	andi	a4,a5,3
    80005ca8:	00e03733          	snez	a4,a4
    80005cac:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cb0:	4007f793          	andi	a5,a5,1024
    80005cb4:	c791                	beqz	a5,80005cc0 <sys_open+0xd2>
    80005cb6:	04491703          	lh	a4,68(s2)
    80005cba:	4789                	li	a5,2
    80005cbc:	08f70f63          	beq	a4,a5,80005d5a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cc0:	854a                	mv	a0,s2
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	082080e7          	jalr	130(ra) # 80003d44 <iunlock>
  end_op();
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	a0a080e7          	jalr	-1526(ra) # 800046d4 <end_op>

  return fd;
}
    80005cd2:	8526                	mv	a0,s1
    80005cd4:	70ea                	ld	ra,184(sp)
    80005cd6:	744a                	ld	s0,176(sp)
    80005cd8:	74aa                	ld	s1,168(sp)
    80005cda:	790a                	ld	s2,160(sp)
    80005cdc:	69ea                	ld	s3,152(sp)
    80005cde:	6129                	addi	sp,sp,192
    80005ce0:	8082                	ret
      end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	9f2080e7          	jalr	-1550(ra) # 800046d4 <end_op>
      return -1;
    80005cea:	b7e5                	j	80005cd2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cec:	f5040513          	addi	a0,s0,-176
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	748080e7          	jalr	1864(ra) # 80004438 <namei>
    80005cf8:	892a                	mv	s2,a0
    80005cfa:	c905                	beqz	a0,80005d2a <sys_open+0x13c>
    ilock(ip);
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	f86080e7          	jalr	-122(ra) # 80003c82 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d04:	04491703          	lh	a4,68(s2)
    80005d08:	4785                	li	a5,1
    80005d0a:	f4f712e3          	bne	a4,a5,80005c4e <sys_open+0x60>
    80005d0e:	f4c42783          	lw	a5,-180(s0)
    80005d12:	dba1                	beqz	a5,80005c62 <sys_open+0x74>
      iunlockput(ip);
    80005d14:	854a                	mv	a0,s2
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	1ce080e7          	jalr	462(ra) # 80003ee4 <iunlockput>
      end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	9b6080e7          	jalr	-1610(ra) # 800046d4 <end_op>
      return -1;
    80005d26:	54fd                	li	s1,-1
    80005d28:	b76d                	j	80005cd2 <sys_open+0xe4>
      end_op();
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	9aa080e7          	jalr	-1622(ra) # 800046d4 <end_op>
      return -1;
    80005d32:	54fd                	li	s1,-1
    80005d34:	bf79                	j	80005cd2 <sys_open+0xe4>
    iunlockput(ip);
    80005d36:	854a                	mv	a0,s2
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	1ac080e7          	jalr	428(ra) # 80003ee4 <iunlockput>
    end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	994080e7          	jalr	-1644(ra) # 800046d4 <end_op>
    return -1;
    80005d48:	54fd                	li	s1,-1
    80005d4a:	b761                	j	80005cd2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d4c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d50:	04691783          	lh	a5,70(s2)
    80005d54:	02f99223          	sh	a5,36(s3)
    80005d58:	bf2d                	j	80005c92 <sys_open+0xa4>
    itrunc(ip);
    80005d5a:	854a                	mv	a0,s2
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	034080e7          	jalr	52(ra) # 80003d90 <itrunc>
    80005d64:	bfb1                	j	80005cc0 <sys_open+0xd2>
      fileclose(f);
    80005d66:	854e                	mv	a0,s3
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	db8080e7          	jalr	-584(ra) # 80004b20 <fileclose>
    iunlockput(ip);
    80005d70:	854a                	mv	a0,s2
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	172080e7          	jalr	370(ra) # 80003ee4 <iunlockput>
    end_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	95a080e7          	jalr	-1702(ra) # 800046d4 <end_op>
    return -1;
    80005d82:	54fd                	li	s1,-1
    80005d84:	b7b9                	j	80005cd2 <sys_open+0xe4>

0000000080005d86 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d86:	7175                	addi	sp,sp,-144
    80005d88:	e506                	sd	ra,136(sp)
    80005d8a:	e122                	sd	s0,128(sp)
    80005d8c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	8c6080e7          	jalr	-1850(ra) # 80004654 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d96:	08000613          	li	a2,128
    80005d9a:	f7040593          	addi	a1,s0,-144
    80005d9e:	4501                	li	a0,0
    80005da0:	ffffd097          	auipc	ra,0xffffd
    80005da4:	16a080e7          	jalr	362(ra) # 80002f0a <argstr>
    80005da8:	02054963          	bltz	a0,80005dda <sys_mkdir+0x54>
    80005dac:	4681                	li	a3,0
    80005dae:	4601                	li	a2,0
    80005db0:	4585                	li	a1,1
    80005db2:	f7040513          	addi	a0,s0,-144
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	7fe080e7          	jalr	2046(ra) # 800055b4 <create>
    80005dbe:	cd11                	beqz	a0,80005dda <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	124080e7          	jalr	292(ra) # 80003ee4 <iunlockput>
  end_op();
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	90c080e7          	jalr	-1780(ra) # 800046d4 <end_op>
  return 0;
    80005dd0:	4501                	li	a0,0
}
    80005dd2:	60aa                	ld	ra,136(sp)
    80005dd4:	640a                	ld	s0,128(sp)
    80005dd6:	6149                	addi	sp,sp,144
    80005dd8:	8082                	ret
    end_op();
    80005dda:	fffff097          	auipc	ra,0xfffff
    80005dde:	8fa080e7          	jalr	-1798(ra) # 800046d4 <end_op>
    return -1;
    80005de2:	557d                	li	a0,-1
    80005de4:	b7fd                	j	80005dd2 <sys_mkdir+0x4c>

0000000080005de6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005de6:	7135                	addi	sp,sp,-160
    80005de8:	ed06                	sd	ra,152(sp)
    80005dea:	e922                	sd	s0,144(sp)
    80005dec:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	866080e7          	jalr	-1946(ra) # 80004654 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005df6:	08000613          	li	a2,128
    80005dfa:	f7040593          	addi	a1,s0,-144
    80005dfe:	4501                	li	a0,0
    80005e00:	ffffd097          	auipc	ra,0xffffd
    80005e04:	10a080e7          	jalr	266(ra) # 80002f0a <argstr>
    80005e08:	04054a63          	bltz	a0,80005e5c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e0c:	f6c40593          	addi	a1,s0,-148
    80005e10:	4505                	li	a0,1
    80005e12:	ffffd097          	auipc	ra,0xffffd
    80005e16:	0b4080e7          	jalr	180(ra) # 80002ec6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e1a:	04054163          	bltz	a0,80005e5c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e1e:	f6840593          	addi	a1,s0,-152
    80005e22:	4509                	li	a0,2
    80005e24:	ffffd097          	auipc	ra,0xffffd
    80005e28:	0a2080e7          	jalr	162(ra) # 80002ec6 <argint>
     argint(1, &major) < 0 ||
    80005e2c:	02054863          	bltz	a0,80005e5c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e30:	f6841683          	lh	a3,-152(s0)
    80005e34:	f6c41603          	lh	a2,-148(s0)
    80005e38:	458d                	li	a1,3
    80005e3a:	f7040513          	addi	a0,s0,-144
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	776080e7          	jalr	1910(ra) # 800055b4 <create>
     argint(2, &minor) < 0 ||
    80005e46:	c919                	beqz	a0,80005e5c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	09c080e7          	jalr	156(ra) # 80003ee4 <iunlockput>
  end_op();
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	884080e7          	jalr	-1916(ra) # 800046d4 <end_op>
  return 0;
    80005e58:	4501                	li	a0,0
    80005e5a:	a031                	j	80005e66 <sys_mknod+0x80>
    end_op();
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	878080e7          	jalr	-1928(ra) # 800046d4 <end_op>
    return -1;
    80005e64:	557d                	li	a0,-1
}
    80005e66:	60ea                	ld	ra,152(sp)
    80005e68:	644a                	ld	s0,144(sp)
    80005e6a:	610d                	addi	sp,sp,160
    80005e6c:	8082                	ret

0000000080005e6e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e6e:	7135                	addi	sp,sp,-160
    80005e70:	ed06                	sd	ra,152(sp)
    80005e72:	e922                	sd	s0,144(sp)
    80005e74:	e526                	sd	s1,136(sp)
    80005e76:	e14a                	sd	s2,128(sp)
    80005e78:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e7a:	ffffc097          	auipc	ra,0xffffc
    80005e7e:	c5c080e7          	jalr	-932(ra) # 80001ad6 <myproc>
    80005e82:	892a                	mv	s2,a0
  
  begin_op();
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	7d0080e7          	jalr	2000(ra) # 80004654 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e8c:	08000613          	li	a2,128
    80005e90:	f6040593          	addi	a1,s0,-160
    80005e94:	4501                	li	a0,0
    80005e96:	ffffd097          	auipc	ra,0xffffd
    80005e9a:	074080e7          	jalr	116(ra) # 80002f0a <argstr>
    80005e9e:	04054b63          	bltz	a0,80005ef4 <sys_chdir+0x86>
    80005ea2:	f6040513          	addi	a0,s0,-160
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	592080e7          	jalr	1426(ra) # 80004438 <namei>
    80005eae:	84aa                	mv	s1,a0
    80005eb0:	c131                	beqz	a0,80005ef4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005eb2:	ffffe097          	auipc	ra,0xffffe
    80005eb6:	dd0080e7          	jalr	-560(ra) # 80003c82 <ilock>
  if(ip->type != T_DIR){
    80005eba:	04449703          	lh	a4,68(s1)
    80005ebe:	4785                	li	a5,1
    80005ec0:	04f71063          	bne	a4,a5,80005f00 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ec4:	8526                	mv	a0,s1
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	e7e080e7          	jalr	-386(ra) # 80003d44 <iunlock>
  iput(p->cwd);
    80005ece:	15093503          	ld	a0,336(s2)
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	f6a080e7          	jalr	-150(ra) # 80003e3c <iput>
  end_op();
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	7fa080e7          	jalr	2042(ra) # 800046d4 <end_op>
  p->cwd = ip;
    80005ee2:	14993823          	sd	s1,336(s2)
  return 0;
    80005ee6:	4501                	li	a0,0
}
    80005ee8:	60ea                	ld	ra,152(sp)
    80005eea:	644a                	ld	s0,144(sp)
    80005eec:	64aa                	ld	s1,136(sp)
    80005eee:	690a                	ld	s2,128(sp)
    80005ef0:	610d                	addi	sp,sp,160
    80005ef2:	8082                	ret
    end_op();
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	7e0080e7          	jalr	2016(ra) # 800046d4 <end_op>
    return -1;
    80005efc:	557d                	li	a0,-1
    80005efe:	b7ed                	j	80005ee8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f00:	8526                	mv	a0,s1
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	fe2080e7          	jalr	-30(ra) # 80003ee4 <iunlockput>
    end_op();
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	7ca080e7          	jalr	1994(ra) # 800046d4 <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
    80005f14:	bfd1                	j	80005ee8 <sys_chdir+0x7a>

0000000080005f16 <sys_exec>:

uint64
sys_exec(void)
{
    80005f16:	7145                	addi	sp,sp,-464
    80005f18:	e786                	sd	ra,456(sp)
    80005f1a:	e3a2                	sd	s0,448(sp)
    80005f1c:	ff26                	sd	s1,440(sp)
    80005f1e:	fb4a                	sd	s2,432(sp)
    80005f20:	f74e                	sd	s3,424(sp)
    80005f22:	f352                	sd	s4,416(sp)
    80005f24:	ef56                	sd	s5,408(sp)
    80005f26:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f28:	08000613          	li	a2,128
    80005f2c:	f4040593          	addi	a1,s0,-192
    80005f30:	4501                	li	a0,0
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	fd8080e7          	jalr	-40(ra) # 80002f0a <argstr>
    return -1;
    80005f3a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f3c:	0c054a63          	bltz	a0,80006010 <sys_exec+0xfa>
    80005f40:	e3840593          	addi	a1,s0,-456
    80005f44:	4505                	li	a0,1
    80005f46:	ffffd097          	auipc	ra,0xffffd
    80005f4a:	fa2080e7          	jalr	-94(ra) # 80002ee8 <argaddr>
    80005f4e:	0c054163          	bltz	a0,80006010 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f52:	10000613          	li	a2,256
    80005f56:	4581                	li	a1,0
    80005f58:	e4040513          	addi	a0,s0,-448
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	d84080e7          	jalr	-636(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f64:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f68:	89a6                	mv	s3,s1
    80005f6a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f6c:	02000a13          	li	s4,32
    80005f70:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f74:	00391513          	slli	a0,s2,0x3
    80005f78:	e3040593          	addi	a1,s0,-464
    80005f7c:	e3843783          	ld	a5,-456(s0)
    80005f80:	953e                	add	a0,a0,a5
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	eaa080e7          	jalr	-342(ra) # 80002e2c <fetchaddr>
    80005f8a:	02054a63          	bltz	a0,80005fbe <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f8e:	e3043783          	ld	a5,-464(s0)
    80005f92:	c3b9                	beqz	a5,80005fd8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f94:	ffffb097          	auipc	ra,0xffffb
    80005f98:	b60080e7          	jalr	-1184(ra) # 80000af4 <kalloc>
    80005f9c:	85aa                	mv	a1,a0
    80005f9e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fa2:	cd11                	beqz	a0,80005fbe <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fa4:	6605                	lui	a2,0x1
    80005fa6:	e3043503          	ld	a0,-464(s0)
    80005faa:	ffffd097          	auipc	ra,0xffffd
    80005fae:	ed4080e7          	jalr	-300(ra) # 80002e7e <fetchstr>
    80005fb2:	00054663          	bltz	a0,80005fbe <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fb6:	0905                	addi	s2,s2,1
    80005fb8:	09a1                	addi	s3,s3,8
    80005fba:	fb491be3          	bne	s2,s4,80005f70 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fbe:	10048913          	addi	s2,s1,256
    80005fc2:	6088                	ld	a0,0(s1)
    80005fc4:	c529                	beqz	a0,8000600e <sys_exec+0xf8>
    kfree(argv[i]);
    80005fc6:	ffffb097          	auipc	ra,0xffffb
    80005fca:	a32080e7          	jalr	-1486(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fce:	04a1                	addi	s1,s1,8
    80005fd0:	ff2499e3          	bne	s1,s2,80005fc2 <sys_exec+0xac>
  return -1;
    80005fd4:	597d                	li	s2,-1
    80005fd6:	a82d                	j	80006010 <sys_exec+0xfa>
      argv[i] = 0;
    80005fd8:	0a8e                	slli	s5,s5,0x3
    80005fda:	fc040793          	addi	a5,s0,-64
    80005fde:	9abe                	add	s5,s5,a5
    80005fe0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fe4:	e4040593          	addi	a1,s0,-448
    80005fe8:	f4040513          	addi	a0,s0,-192
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	194080e7          	jalr	404(ra) # 80005180 <exec>
    80005ff4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ff6:	10048993          	addi	s3,s1,256
    80005ffa:	6088                	ld	a0,0(s1)
    80005ffc:	c911                	beqz	a0,80006010 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ffe:	ffffb097          	auipc	ra,0xffffb
    80006002:	9fa080e7          	jalr	-1542(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006006:	04a1                	addi	s1,s1,8
    80006008:	ff3499e3          	bne	s1,s3,80005ffa <sys_exec+0xe4>
    8000600c:	a011                	j	80006010 <sys_exec+0xfa>
  return -1;
    8000600e:	597d                	li	s2,-1
}
    80006010:	854a                	mv	a0,s2
    80006012:	60be                	ld	ra,456(sp)
    80006014:	641e                	ld	s0,448(sp)
    80006016:	74fa                	ld	s1,440(sp)
    80006018:	795a                	ld	s2,432(sp)
    8000601a:	79ba                	ld	s3,424(sp)
    8000601c:	7a1a                	ld	s4,416(sp)
    8000601e:	6afa                	ld	s5,408(sp)
    80006020:	6179                	addi	sp,sp,464
    80006022:	8082                	ret

0000000080006024 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006024:	7139                	addi	sp,sp,-64
    80006026:	fc06                	sd	ra,56(sp)
    80006028:	f822                	sd	s0,48(sp)
    8000602a:	f426                	sd	s1,40(sp)
    8000602c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000602e:	ffffc097          	auipc	ra,0xffffc
    80006032:	aa8080e7          	jalr	-1368(ra) # 80001ad6 <myproc>
    80006036:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006038:	fd840593          	addi	a1,s0,-40
    8000603c:	4501                	li	a0,0
    8000603e:	ffffd097          	auipc	ra,0xffffd
    80006042:	eaa080e7          	jalr	-342(ra) # 80002ee8 <argaddr>
    return -1;
    80006046:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006048:	0e054063          	bltz	a0,80006128 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000604c:	fc840593          	addi	a1,s0,-56
    80006050:	fd040513          	addi	a0,s0,-48
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	dfc080e7          	jalr	-516(ra) # 80004e50 <pipealloc>
    return -1;
    8000605c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000605e:	0c054563          	bltz	a0,80006128 <sys_pipe+0x104>
  fd0 = -1;
    80006062:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006066:	fd043503          	ld	a0,-48(s0)
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	508080e7          	jalr	1288(ra) # 80005572 <fdalloc>
    80006072:	fca42223          	sw	a0,-60(s0)
    80006076:	08054c63          	bltz	a0,8000610e <sys_pipe+0xea>
    8000607a:	fc843503          	ld	a0,-56(s0)
    8000607e:	fffff097          	auipc	ra,0xfffff
    80006082:	4f4080e7          	jalr	1268(ra) # 80005572 <fdalloc>
    80006086:	fca42023          	sw	a0,-64(s0)
    8000608a:	06054863          	bltz	a0,800060fa <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000608e:	4691                	li	a3,4
    80006090:	fc440613          	addi	a2,s0,-60
    80006094:	fd843583          	ld	a1,-40(s0)
    80006098:	68a8                	ld	a0,80(s1)
    8000609a:	ffffb097          	auipc	ra,0xffffb
    8000609e:	5e0080e7          	jalr	1504(ra) # 8000167a <copyout>
    800060a2:	02054063          	bltz	a0,800060c2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060a6:	4691                	li	a3,4
    800060a8:	fc040613          	addi	a2,s0,-64
    800060ac:	fd843583          	ld	a1,-40(s0)
    800060b0:	0591                	addi	a1,a1,4
    800060b2:	68a8                	ld	a0,80(s1)
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	5c6080e7          	jalr	1478(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060bc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060be:	06055563          	bgez	a0,80006128 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060c2:	fc442783          	lw	a5,-60(s0)
    800060c6:	07e9                	addi	a5,a5,26
    800060c8:	078e                	slli	a5,a5,0x3
    800060ca:	97a6                	add	a5,a5,s1
    800060cc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060d0:	fc042503          	lw	a0,-64(s0)
    800060d4:	0569                	addi	a0,a0,26
    800060d6:	050e                	slli	a0,a0,0x3
    800060d8:	9526                	add	a0,a0,s1
    800060da:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060de:	fd043503          	ld	a0,-48(s0)
    800060e2:	fffff097          	auipc	ra,0xfffff
    800060e6:	a3e080e7          	jalr	-1474(ra) # 80004b20 <fileclose>
    fileclose(wf);
    800060ea:	fc843503          	ld	a0,-56(s0)
    800060ee:	fffff097          	auipc	ra,0xfffff
    800060f2:	a32080e7          	jalr	-1486(ra) # 80004b20 <fileclose>
    return -1;
    800060f6:	57fd                	li	a5,-1
    800060f8:	a805                	j	80006128 <sys_pipe+0x104>
    if(fd0 >= 0)
    800060fa:	fc442783          	lw	a5,-60(s0)
    800060fe:	0007c863          	bltz	a5,8000610e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006102:	01a78513          	addi	a0,a5,26
    80006106:	050e                	slli	a0,a0,0x3
    80006108:	9526                	add	a0,a0,s1
    8000610a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000610e:	fd043503          	ld	a0,-48(s0)
    80006112:	fffff097          	auipc	ra,0xfffff
    80006116:	a0e080e7          	jalr	-1522(ra) # 80004b20 <fileclose>
    fileclose(wf);
    8000611a:	fc843503          	ld	a0,-56(s0)
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	a02080e7          	jalr	-1534(ra) # 80004b20 <fileclose>
    return -1;
    80006126:	57fd                	li	a5,-1
}
    80006128:	853e                	mv	a0,a5
    8000612a:	70e2                	ld	ra,56(sp)
    8000612c:	7442                	ld	s0,48(sp)
    8000612e:	74a2                	ld	s1,40(sp)
    80006130:	6121                	addi	sp,sp,64
    80006132:	8082                	ret
	...

0000000080006140 <kernelvec>:
    80006140:	7111                	addi	sp,sp,-256
    80006142:	e006                	sd	ra,0(sp)
    80006144:	e40a                	sd	sp,8(sp)
    80006146:	e80e                	sd	gp,16(sp)
    80006148:	ec12                	sd	tp,24(sp)
    8000614a:	f016                	sd	t0,32(sp)
    8000614c:	f41a                	sd	t1,40(sp)
    8000614e:	f81e                	sd	t2,48(sp)
    80006150:	fc22                	sd	s0,56(sp)
    80006152:	e0a6                	sd	s1,64(sp)
    80006154:	e4aa                	sd	a0,72(sp)
    80006156:	e8ae                	sd	a1,80(sp)
    80006158:	ecb2                	sd	a2,88(sp)
    8000615a:	f0b6                	sd	a3,96(sp)
    8000615c:	f4ba                	sd	a4,104(sp)
    8000615e:	f8be                	sd	a5,112(sp)
    80006160:	fcc2                	sd	a6,120(sp)
    80006162:	e146                	sd	a7,128(sp)
    80006164:	e54a                	sd	s2,136(sp)
    80006166:	e94e                	sd	s3,144(sp)
    80006168:	ed52                	sd	s4,152(sp)
    8000616a:	f156                	sd	s5,160(sp)
    8000616c:	f55a                	sd	s6,168(sp)
    8000616e:	f95e                	sd	s7,176(sp)
    80006170:	fd62                	sd	s8,184(sp)
    80006172:	e1e6                	sd	s9,192(sp)
    80006174:	e5ea                	sd	s10,200(sp)
    80006176:	e9ee                	sd	s11,208(sp)
    80006178:	edf2                	sd	t3,216(sp)
    8000617a:	f1f6                	sd	t4,224(sp)
    8000617c:	f5fa                	sd	t5,232(sp)
    8000617e:	f9fe                	sd	t6,240(sp)
    80006180:	b79fc0ef          	jal	ra,80002cf8 <kerneltrap>
    80006184:	6082                	ld	ra,0(sp)
    80006186:	6122                	ld	sp,8(sp)
    80006188:	61c2                	ld	gp,16(sp)
    8000618a:	7282                	ld	t0,32(sp)
    8000618c:	7322                	ld	t1,40(sp)
    8000618e:	73c2                	ld	t2,48(sp)
    80006190:	7462                	ld	s0,56(sp)
    80006192:	6486                	ld	s1,64(sp)
    80006194:	6526                	ld	a0,72(sp)
    80006196:	65c6                	ld	a1,80(sp)
    80006198:	6666                	ld	a2,88(sp)
    8000619a:	7686                	ld	a3,96(sp)
    8000619c:	7726                	ld	a4,104(sp)
    8000619e:	77c6                	ld	a5,112(sp)
    800061a0:	7866                	ld	a6,120(sp)
    800061a2:	688a                	ld	a7,128(sp)
    800061a4:	692a                	ld	s2,136(sp)
    800061a6:	69ca                	ld	s3,144(sp)
    800061a8:	6a6a                	ld	s4,152(sp)
    800061aa:	7a8a                	ld	s5,160(sp)
    800061ac:	7b2a                	ld	s6,168(sp)
    800061ae:	7bca                	ld	s7,176(sp)
    800061b0:	7c6a                	ld	s8,184(sp)
    800061b2:	6c8e                	ld	s9,192(sp)
    800061b4:	6d2e                	ld	s10,200(sp)
    800061b6:	6dce                	ld	s11,208(sp)
    800061b8:	6e6e                	ld	t3,216(sp)
    800061ba:	7e8e                	ld	t4,224(sp)
    800061bc:	7f2e                	ld	t5,232(sp)
    800061be:	7fce                	ld	t6,240(sp)
    800061c0:	6111                	addi	sp,sp,256
    800061c2:	10200073          	sret
    800061c6:	00000013          	nop
    800061ca:	00000013          	nop
    800061ce:	0001                	nop

00000000800061d0 <timervec>:
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	e10c                	sd	a1,0(a0)
    800061d6:	e510                	sd	a2,8(a0)
    800061d8:	e914                	sd	a3,16(a0)
    800061da:	6d0c                	ld	a1,24(a0)
    800061dc:	7110                	ld	a2,32(a0)
    800061de:	6194                	ld	a3,0(a1)
    800061e0:	96b2                	add	a3,a3,a2
    800061e2:	e194                	sd	a3,0(a1)
    800061e4:	4589                	li	a1,2
    800061e6:	14459073          	csrw	sip,a1
    800061ea:	6914                	ld	a3,16(a0)
    800061ec:	6510                	ld	a2,8(a0)
    800061ee:	610c                	ld	a1,0(a0)
    800061f0:	34051573          	csrrw	a0,mscratch,a0
    800061f4:	30200073          	mret
	...

00000000800061fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061fa:	1141                	addi	sp,sp,-16
    800061fc:	e422                	sd	s0,8(sp)
    800061fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006200:	0c0007b7          	lui	a5,0xc000
    80006204:	4705                	li	a4,1
    80006206:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006208:	c3d8                	sw	a4,4(a5)
}
    8000620a:	6422                	ld	s0,8(sp)
    8000620c:	0141                	addi	sp,sp,16
    8000620e:	8082                	ret

0000000080006210 <plicinithart>:

void
plicinithart(void)
{
    80006210:	1141                	addi	sp,sp,-16
    80006212:	e406                	sd	ra,8(sp)
    80006214:	e022                	sd	s0,0(sp)
    80006216:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	892080e7          	jalr	-1902(ra) # 80001aaa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006220:	0085171b          	slliw	a4,a0,0x8
    80006224:	0c0027b7          	lui	a5,0xc002
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	40200713          	li	a4,1026
    8000622e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006232:	00d5151b          	slliw	a0,a0,0xd
    80006236:	0c2017b7          	lui	a5,0xc201
    8000623a:	953e                	add	a0,a0,a5
    8000623c:	00052023          	sw	zero,0(a0)
}
    80006240:	60a2                	ld	ra,8(sp)
    80006242:	6402                	ld	s0,0(sp)
    80006244:	0141                	addi	sp,sp,16
    80006246:	8082                	ret

0000000080006248 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006248:	1141                	addi	sp,sp,-16
    8000624a:	e406                	sd	ra,8(sp)
    8000624c:	e022                	sd	s0,0(sp)
    8000624e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006250:	ffffc097          	auipc	ra,0xffffc
    80006254:	85a080e7          	jalr	-1958(ra) # 80001aaa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006258:	00d5179b          	slliw	a5,a0,0xd
    8000625c:	0c201537          	lui	a0,0xc201
    80006260:	953e                	add	a0,a0,a5
  return irq;
}
    80006262:	4148                	lw	a0,4(a0)
    80006264:	60a2                	ld	ra,8(sp)
    80006266:	6402                	ld	s0,0(sp)
    80006268:	0141                	addi	sp,sp,16
    8000626a:	8082                	ret

000000008000626c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	1000                	addi	s0,sp,32
    80006276:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	832080e7          	jalr	-1998(ra) # 80001aaa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006280:	00d5151b          	slliw	a0,a0,0xd
    80006284:	0c2017b7          	lui	a5,0xc201
    80006288:	97aa                	add	a5,a5,a0
    8000628a:	c3c4                	sw	s1,4(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret

0000000080006296 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006296:	1141                	addi	sp,sp,-16
    80006298:	e406                	sd	ra,8(sp)
    8000629a:	e022                	sd	s0,0(sp)
    8000629c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000629e:	479d                	li	a5,7
    800062a0:	06a7c963          	blt	a5,a0,80006312 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062a4:	0001f797          	auipc	a5,0x1f
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80025000 <disk>
    800062ac:	00a78733          	add	a4,a5,a0
    800062b0:	6789                	lui	a5,0x2
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062b8:	e7ad                	bnez	a5,80006322 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ba:	00451793          	slli	a5,a0,0x4
    800062be:	00021717          	auipc	a4,0x21
    800062c2:	d4270713          	addi	a4,a4,-702 # 80027000 <disk+0x2000>
    800062c6:	6314                	ld	a3,0(a4)
    800062c8:	96be                	add	a3,a3,a5
    800062ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062ce:	6314                	ld	a3,0(a4)
    800062d0:	96be                	add	a3,a3,a5
    800062d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062d6:	6314                	ld	a3,0(a4)
    800062d8:	96be                	add	a3,a3,a5
    800062da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062de:	6318                	ld	a4,0(a4)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062e6:	0001f797          	auipc	a5,0x1f
    800062ea:	d1a78793          	addi	a5,a5,-742 # 80025000 <disk>
    800062ee:	97aa                	add	a5,a5,a0
    800062f0:	6509                	lui	a0,0x2
    800062f2:	953e                	add	a0,a0,a5
    800062f4:	4785                	li	a5,1
    800062f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062fa:	00021517          	auipc	a0,0x21
    800062fe:	d1e50513          	addi	a0,a0,-738 # 80027018 <disk+0x2018>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	2a0080e7          	jalr	672(ra) # 800025a2 <wakeup>
}
    8000630a:	60a2                	ld	ra,8(sp)
    8000630c:	6402                	ld	s0,0(sp)
    8000630e:	0141                	addi	sp,sp,16
    80006310:	8082                	ret
    panic("free_desc 1");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	55650513          	addi	a0,a0,1366 # 80008868 <syscalls+0x330>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	224080e7          	jalr	548(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	55650513          	addi	a0,a0,1366 # 80008878 <syscalls+0x340>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	214080e7          	jalr	532(ra) # 8000053e <panic>

0000000080006332 <virtio_disk_init>:
{
    80006332:	1101                	addi	sp,sp,-32
    80006334:	ec06                	sd	ra,24(sp)
    80006336:	e822                	sd	s0,16(sp)
    80006338:	e426                	sd	s1,8(sp)
    8000633a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000633c:	00002597          	auipc	a1,0x2
    80006340:	54c58593          	addi	a1,a1,1356 # 80008888 <syscalls+0x350>
    80006344:	00021517          	auipc	a0,0x21
    80006348:	de450513          	addi	a0,a0,-540 # 80027128 <disk+0x2128>
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	808080e7          	jalr	-2040(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006354:	100017b7          	lui	a5,0x10001
    80006358:	4398                	lw	a4,0(a5)
    8000635a:	2701                	sext.w	a4,a4
    8000635c:	747277b7          	lui	a5,0x74727
    80006360:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006364:	0ef71163          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	43dc                	lw	a5,4(a5)
    8000636e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006370:	4705                	li	a4,1
    80006372:	0ce79a63          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006376:	100017b7          	lui	a5,0x10001
    8000637a:	479c                	lw	a5,8(a5)
    8000637c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000637e:	4709                	li	a4,2
    80006380:	0ce79363          	bne	a5,a4,80006446 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006384:	100017b7          	lui	a5,0x10001
    80006388:	47d8                	lw	a4,12(a5)
    8000638a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000638c:	554d47b7          	lui	a5,0x554d4
    80006390:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006394:	0af71963          	bne	a4,a5,80006446 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	4705                	li	a4,1
    8000639e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a0:	470d                	li	a4,3
    800063a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063a6:	c7ffe737          	lui	a4,0xc7ffe
    800063aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    800063ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063b0:	2701                	sext.w	a4,a4
    800063b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b4:	472d                	li	a4,11
    800063b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b8:	473d                	li	a4,15
    800063ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063bc:	6705                	lui	a4,0x1
    800063be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063c4:	5bdc                	lw	a5,52(a5)
    800063c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063c8:	c7d9                	beqz	a5,80006456 <virtio_disk_init+0x124>
  if(max < NUM)
    800063ca:	471d                	li	a4,7
    800063cc:	08f77d63          	bgeu	a4,a5,80006466 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063d0:	100014b7          	lui	s1,0x10001
    800063d4:	47a1                	li	a5,8
    800063d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063d8:	6609                	lui	a2,0x2
    800063da:	4581                	li	a1,0
    800063dc:	0001f517          	auipc	a0,0x1f
    800063e0:	c2450513          	addi	a0,a0,-988 # 80025000 <disk>
    800063e4:	ffffb097          	auipc	ra,0xffffb
    800063e8:	8fc080e7          	jalr	-1796(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063ec:	0001f717          	auipc	a4,0x1f
    800063f0:	c1470713          	addi	a4,a4,-1004 # 80025000 <disk>
    800063f4:	00c75793          	srli	a5,a4,0xc
    800063f8:	2781                	sext.w	a5,a5
    800063fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063fc:	00021797          	auipc	a5,0x21
    80006400:	c0478793          	addi	a5,a5,-1020 # 80027000 <disk+0x2000>
    80006404:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006406:	0001f717          	auipc	a4,0x1f
    8000640a:	c7a70713          	addi	a4,a4,-902 # 80025080 <disk+0x80>
    8000640e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006410:	00020717          	auipc	a4,0x20
    80006414:	bf070713          	addi	a4,a4,-1040 # 80026000 <disk+0x1000>
    80006418:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000641a:	4705                	li	a4,1
    8000641c:	00e78c23          	sb	a4,24(a5)
    80006420:	00e78ca3          	sb	a4,25(a5)
    80006424:	00e78d23          	sb	a4,26(a5)
    80006428:	00e78da3          	sb	a4,27(a5)
    8000642c:	00e78e23          	sb	a4,28(a5)
    80006430:	00e78ea3          	sb	a4,29(a5)
    80006434:	00e78f23          	sb	a4,30(a5)
    80006438:	00e78fa3          	sb	a4,31(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret
    panic("could not find virtio disk");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	45250513          	addi	a0,a0,1106 # 80008898 <syscalls+0x360>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	46250513          	addi	a0,a0,1122 # 800088b8 <syscalls+0x380>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	47250513          	addi	a0,a0,1138 # 800088d8 <syscalls+0x3a0>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>

0000000080006476 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006476:	7159                	addi	sp,sp,-112
    80006478:	f486                	sd	ra,104(sp)
    8000647a:	f0a2                	sd	s0,96(sp)
    8000647c:	eca6                	sd	s1,88(sp)
    8000647e:	e8ca                	sd	s2,80(sp)
    80006480:	e4ce                	sd	s3,72(sp)
    80006482:	e0d2                	sd	s4,64(sp)
    80006484:	fc56                	sd	s5,56(sp)
    80006486:	f85a                	sd	s6,48(sp)
    80006488:	f45e                	sd	s7,40(sp)
    8000648a:	f062                	sd	s8,32(sp)
    8000648c:	ec66                	sd	s9,24(sp)
    8000648e:	e86a                	sd	s10,16(sp)
    80006490:	1880                	addi	s0,sp,112
    80006492:	892a                	mv	s2,a0
    80006494:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006496:	00c52c83          	lw	s9,12(a0)
    8000649a:	001c9c9b          	slliw	s9,s9,0x1
    8000649e:	1c82                	slli	s9,s9,0x20
    800064a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064a4:	00021517          	auipc	a0,0x21
    800064a8:	c8450513          	addi	a0,a0,-892 # 80027128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	738080e7          	jalr	1848(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064b8:	0001fb97          	auipc	s7,0x1f
    800064bc:	b48b8b93          	addi	s7,s7,-1208 # 80025000 <disk>
    800064c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064c4:	8a4e                	mv	s4,s3
    800064c6:	a051                	j	8000654a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064c8:	00fb86b3          	add	a3,s7,a5
    800064cc:	96da                	add	a3,a3,s6
    800064ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064d4:	0207c563          	bltz	a5,800064fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064d8:	2485                	addiw	s1,s1,1
    800064da:	0711                	addi	a4,a4,4
    800064dc:	25548063          	beq	s1,s5,8000671c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064e2:	00021697          	auipc	a3,0x21
    800064e6:	b3668693          	addi	a3,a3,-1226 # 80027018 <disk+0x2018>
    800064ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064ec:	0006c583          	lbu	a1,0(a3)
    800064f0:	fde1                	bnez	a1,800064c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	0685                	addi	a3,a3,1
    800064f6:	ff879be3          	bne	a5,s8,800064ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064fa:	57fd                	li	a5,-1
    800064fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064fe:	02905a63          	blez	s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006502:	f9042503          	lw	a0,-112(s0)
    80006506:	00000097          	auipc	ra,0x0
    8000650a:	d90080e7          	jalr	-624(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    8000650e:	4785                	li	a5,1
    80006510:	0297d163          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006514:	f9442503          	lw	a0,-108(s0)
    80006518:	00000097          	auipc	ra,0x0
    8000651c:	d7e080e7          	jalr	-642(ra) # 80006296 <free_desc>
      for(int j = 0; j < i; j++)
    80006520:	4789                	li	a5,2
    80006522:	0097d863          	bge	a5,s1,80006532 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006526:	f9842503          	lw	a0,-104(s0)
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	d6c080e7          	jalr	-660(ra) # 80006296 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006532:	00021597          	auipc	a1,0x21
    80006536:	bf658593          	addi	a1,a1,-1034 # 80027128 <disk+0x2128>
    8000653a:	00021517          	auipc	a0,0x21
    8000653e:	ade50513          	addi	a0,a0,-1314 # 80027018 <disk+0x2018>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	d88080e7          	jalr	-632(ra) # 800022ca <sleep>
  for(int i = 0; i < 3; i++){
    8000654a:	f9040713          	addi	a4,s0,-112
    8000654e:	84ce                	mv	s1,s3
    80006550:	bf41                	j	800064e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006552:	20058713          	addi	a4,a1,512
    80006556:	00471693          	slli	a3,a4,0x4
    8000655a:	0001f717          	auipc	a4,0x1f
    8000655e:	aa670713          	addi	a4,a4,-1370 # 80025000 <disk>
    80006562:	9736                	add	a4,a4,a3
    80006564:	4685                	li	a3,1
    80006566:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000656a:	20058713          	addi	a4,a1,512
    8000656e:	00471693          	slli	a3,a4,0x4
    80006572:	0001f717          	auipc	a4,0x1f
    80006576:	a8e70713          	addi	a4,a4,-1394 # 80025000 <disk>
    8000657a:	9736                	add	a4,a4,a3
    8000657c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006580:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006584:	7679                	lui	a2,0xffffe
    80006586:	963e                	add	a2,a2,a5
    80006588:	00021697          	auipc	a3,0x21
    8000658c:	a7868693          	addi	a3,a3,-1416 # 80027000 <disk+0x2000>
    80006590:	6298                	ld	a4,0(a3)
    80006592:	9732                	add	a4,a4,a2
    80006594:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006596:	6298                	ld	a4,0(a3)
    80006598:	9732                	add	a4,a4,a2
    8000659a:	4541                	li	a0,16
    8000659c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000659e:	6298                	ld	a4,0(a3)
    800065a0:	9732                	add	a4,a4,a2
    800065a2:	4505                	li	a0,1
    800065a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065a8:	f9442703          	lw	a4,-108(s0)
    800065ac:	6288                	ld	a0,0(a3)
    800065ae:	962a                	add	a2,a2,a0
    800065b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065b4:	0712                	slli	a4,a4,0x4
    800065b6:	6290                	ld	a2,0(a3)
    800065b8:	963a                	add	a2,a2,a4
    800065ba:	05890513          	addi	a0,s2,88
    800065be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065c0:	6294                	ld	a3,0(a3)
    800065c2:	96ba                	add	a3,a3,a4
    800065c4:	40000613          	li	a2,1024
    800065c8:	c690                	sw	a2,8(a3)
  if(write)
    800065ca:	140d0063          	beqz	s10,8000670a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ce:	00021697          	auipc	a3,0x21
    800065d2:	a326b683          	ld	a3,-1486(a3) # 80027000 <disk+0x2000>
    800065d6:	96ba                	add	a3,a3,a4
    800065d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065dc:	0001f817          	auipc	a6,0x1f
    800065e0:	a2480813          	addi	a6,a6,-1500 # 80025000 <disk>
    800065e4:	00021517          	auipc	a0,0x21
    800065e8:	a1c50513          	addi	a0,a0,-1508 # 80027000 <disk+0x2000>
    800065ec:	6114                	ld	a3,0(a0)
    800065ee:	96ba                	add	a3,a3,a4
    800065f0:	00c6d603          	lhu	a2,12(a3)
    800065f4:	00166613          	ori	a2,a2,1
    800065f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065fc:	f9842683          	lw	a3,-104(s0)
    80006600:	6110                	ld	a2,0(a0)
    80006602:	9732                	add	a4,a4,a2
    80006604:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006608:	20058613          	addi	a2,a1,512
    8000660c:	0612                	slli	a2,a2,0x4
    8000660e:	9642                	add	a2,a2,a6
    80006610:	577d                	li	a4,-1
    80006612:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006616:	00469713          	slli	a4,a3,0x4
    8000661a:	6114                	ld	a3,0(a0)
    8000661c:	96ba                	add	a3,a3,a4
    8000661e:	03078793          	addi	a5,a5,48
    80006622:	97c2                	add	a5,a5,a6
    80006624:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006626:	611c                	ld	a5,0(a0)
    80006628:	97ba                	add	a5,a5,a4
    8000662a:	4685                	li	a3,1
    8000662c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000662e:	611c                	ld	a5,0(a0)
    80006630:	97ba                	add	a5,a5,a4
    80006632:	4809                	li	a6,2
    80006634:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006638:	611c                	ld	a5,0(a0)
    8000663a:	973e                	add	a4,a4,a5
    8000663c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006640:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006644:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006648:	6518                	ld	a4,8(a0)
    8000664a:	00275783          	lhu	a5,2(a4)
    8000664e:	8b9d                	andi	a5,a5,7
    80006650:	0786                	slli	a5,a5,0x1
    80006652:	97ba                	add	a5,a5,a4
    80006654:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006658:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000665c:	6518                	ld	a4,8(a0)
    8000665e:	00275783          	lhu	a5,2(a4)
    80006662:	2785                	addiw	a5,a5,1
    80006664:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006668:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000666c:	100017b7          	lui	a5,0x10001
    80006670:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006674:	00492703          	lw	a4,4(s2)
    80006678:	4785                	li	a5,1
    8000667a:	02f71163          	bne	a4,a5,8000669c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000667e:	00021997          	auipc	s3,0x21
    80006682:	aaa98993          	addi	s3,s3,-1366 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    80006686:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006688:	85ce                	mv	a1,s3
    8000668a:	854a                	mv	a0,s2
    8000668c:	ffffc097          	auipc	ra,0xffffc
    80006690:	c3e080e7          	jalr	-962(ra) # 800022ca <sleep>
  while(b->disk == 1) {
    80006694:	00492783          	lw	a5,4(s2)
    80006698:	fe9788e3          	beq	a5,s1,80006688 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000669c:	f9042903          	lw	s2,-112(s0)
    800066a0:	20090793          	addi	a5,s2,512
    800066a4:	00479713          	slli	a4,a5,0x4
    800066a8:	0001f797          	auipc	a5,0x1f
    800066ac:	95878793          	addi	a5,a5,-1704 # 80025000 <disk>
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066b6:	00021997          	auipc	s3,0x21
    800066ba:	94a98993          	addi	s3,s3,-1718 # 80027000 <disk+0x2000>
    800066be:	00491713          	slli	a4,s2,0x4
    800066c2:	0009b783          	ld	a5,0(s3)
    800066c6:	97ba                	add	a5,a5,a4
    800066c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066cc:	854a                	mv	a0,s2
    800066ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066d2:	00000097          	auipc	ra,0x0
    800066d6:	bc4080e7          	jalr	-1084(ra) # 80006296 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066da:	8885                	andi	s1,s1,1
    800066dc:	f0ed                	bnez	s1,800066be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066de:	00021517          	auipc	a0,0x21
    800066e2:	a4a50513          	addi	a0,a0,-1462 # 80027128 <disk+0x2128>
    800066e6:	ffffa097          	auipc	ra,0xffffa
    800066ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
}
    800066ee:	70a6                	ld	ra,104(sp)
    800066f0:	7406                	ld	s0,96(sp)
    800066f2:	64e6                	ld	s1,88(sp)
    800066f4:	6946                	ld	s2,80(sp)
    800066f6:	69a6                	ld	s3,72(sp)
    800066f8:	6a06                	ld	s4,64(sp)
    800066fa:	7ae2                	ld	s5,56(sp)
    800066fc:	7b42                	ld	s6,48(sp)
    800066fe:	7ba2                	ld	s7,40(sp)
    80006700:	7c02                	ld	s8,32(sp)
    80006702:	6ce2                	ld	s9,24(sp)
    80006704:	6d42                	ld	s10,16(sp)
    80006706:	6165                	addi	sp,sp,112
    80006708:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000670a:	00021697          	auipc	a3,0x21
    8000670e:	8f66b683          	ld	a3,-1802(a3) # 80027000 <disk+0x2000>
    80006712:	96ba                	add	a3,a3,a4
    80006714:	4609                	li	a2,2
    80006716:	00c69623          	sh	a2,12(a3)
    8000671a:	b5c9                	j	800065dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000671c:	f9042583          	lw	a1,-112(s0)
    80006720:	20058793          	addi	a5,a1,512
    80006724:	0792                	slli	a5,a5,0x4
    80006726:	0001f517          	auipc	a0,0x1f
    8000672a:	98250513          	addi	a0,a0,-1662 # 800250a8 <disk+0xa8>
    8000672e:	953e                	add	a0,a0,a5
  if(write)
    80006730:	e20d11e3          	bnez	s10,80006552 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006734:	20058713          	addi	a4,a1,512
    80006738:	00471693          	slli	a3,a4,0x4
    8000673c:	0001f717          	auipc	a4,0x1f
    80006740:	8c470713          	addi	a4,a4,-1852 # 80025000 <disk>
    80006744:	9736                	add	a4,a4,a3
    80006746:	0a072423          	sw	zero,168(a4)
    8000674a:	b505                	j	8000656a <virtio_disk_rw+0xf4>

000000008000674c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000674c:	1101                	addi	sp,sp,-32
    8000674e:	ec06                	sd	ra,24(sp)
    80006750:	e822                	sd	s0,16(sp)
    80006752:	e426                	sd	s1,8(sp)
    80006754:	e04a                	sd	s2,0(sp)
    80006756:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006758:	00021517          	auipc	a0,0x21
    8000675c:	9d050513          	addi	a0,a0,-1584 # 80027128 <disk+0x2128>
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	484080e7          	jalr	1156(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006768:	10001737          	lui	a4,0x10001
    8000676c:	533c                	lw	a5,96(a4)
    8000676e:	8b8d                	andi	a5,a5,3
    80006770:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006772:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006776:	00021797          	auipc	a5,0x21
    8000677a:	88a78793          	addi	a5,a5,-1910 # 80027000 <disk+0x2000>
    8000677e:	6b94                	ld	a3,16(a5)
    80006780:	0207d703          	lhu	a4,32(a5)
    80006784:	0026d783          	lhu	a5,2(a3)
    80006788:	06f70163          	beq	a4,a5,800067ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000678c:	0001f917          	auipc	s2,0x1f
    80006790:	87490913          	addi	s2,s2,-1932 # 80025000 <disk>
    80006794:	00021497          	auipc	s1,0x21
    80006798:	86c48493          	addi	s1,s1,-1940 # 80027000 <disk+0x2000>
    __sync_synchronize();
    8000679c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067a0:	6898                	ld	a4,16(s1)
    800067a2:	0204d783          	lhu	a5,32(s1)
    800067a6:	8b9d                	andi	a5,a5,7
    800067a8:	078e                	slli	a5,a5,0x3
    800067aa:	97ba                	add	a5,a5,a4
    800067ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ae:	20078713          	addi	a4,a5,512
    800067b2:	0712                	slli	a4,a4,0x4
    800067b4:	974a                	add	a4,a4,s2
    800067b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ba:	e731                	bnez	a4,80006806 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067bc:	20078793          	addi	a5,a5,512
    800067c0:	0792                	slli	a5,a5,0x4
    800067c2:	97ca                	add	a5,a5,s2
    800067c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ca:	ffffc097          	auipc	ra,0xffffc
    800067ce:	dd8080e7          	jalr	-552(ra) # 800025a2 <wakeup>

    disk.used_idx += 1;
    800067d2:	0204d783          	lhu	a5,32(s1)
    800067d6:	2785                	addiw	a5,a5,1
    800067d8:	17c2                	slli	a5,a5,0x30
    800067da:	93c1                	srli	a5,a5,0x30
    800067dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067e0:	6898                	ld	a4,16(s1)
    800067e2:	00275703          	lhu	a4,2(a4)
    800067e6:	faf71be3          	bne	a4,a5,8000679c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ea:	00021517          	auipc	a0,0x21
    800067ee:	93e50513          	addi	a0,a0,-1730 # 80027128 <disk+0x2128>
    800067f2:	ffffa097          	auipc	ra,0xffffa
    800067f6:	4a6080e7          	jalr	1190(ra) # 80000c98 <release>
}
    800067fa:	60e2                	ld	ra,24(sp)
    800067fc:	6442                	ld	s0,16(sp)
    800067fe:	64a2                	ld	s1,8(sp)
    80006800:	6902                	ld	s2,0(sp)
    80006802:	6105                	addi	sp,sp,32
    80006804:	8082                	ret
      panic("virtio_disk_intr status");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	0f250513          	addi	a0,a0,242 # 800088f8 <syscalls+0x3c0>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
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
