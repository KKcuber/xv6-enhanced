
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
    80000068:	0dc78793          	addi	a5,a5,220 # 80006140 <timervec>
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
    80000130:	6a8080e7          	jalr	1704(ra) # 800027d4 <either_copyin>
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
    800001d8:	0ae080e7          	jalr	174(ra) # 80002282 <sleep>
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
    80000214:	56e080e7          	jalr	1390(ra) # 8000277e <either_copyout>
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
    800002f6:	538080e7          	jalr	1336(ra) # 8000282a <procdump>
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
    8000044a:	114080e7          	jalr	276(ra) # 8000255a <wakeup>
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
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1807+0x160>
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
    800008a4:	cba080e7          	jalr	-838(ra) # 8000255a <wakeup>
    
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
    80000930:	956080e7          	jalr	-1706(ra) # 80002282 <sleep>
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
    80000ed8:	b3c080e7          	jalr	-1220(ra) # 80002a10 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2a4080e7          	jalr	676(ra) # 80006180 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	1ae080e7          	jalr	430(ra) # 80002092 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1807+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1807+0x160>
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
    80000f50:	a9c080e7          	jalr	-1380(ra) # 800029e8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	abc080e7          	jalr	-1348(ra) # 80002a10 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	20e080e7          	jalr	526(ra) # 8000616a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	21c080e7          	jalr	540(ra) # 80006180 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	3f6080e7          	jalr	1014(ra) # 80003362 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a86080e7          	jalr	-1402(ra) # 800039fa <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a30080e7          	jalr	-1488(ra) # 800049ac <fileinit>
    pinit();         // process table for mlfq
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	9b0080e7          	jalr	-1616(ra) # 80001934 <pinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	316080e7          	jalr	790(ra) # 800062a2 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e66080e7          	jalr	-410(ra) # 80001dfa <userinit>
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
    80001b2a:	dea7a783          	lw	a5,-534(a5) # 80008910 <first.1770>
    80001b2e:	eb89                	bnez	a5,80001b40 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b30:	00001097          	auipc	ra,0x1
    80001b34:	ef8080e7          	jalr	-264(ra) # 80002a28 <usertrapret>
}
    80001b38:	60a2                	ld	ra,8(sp)
    80001b3a:	6402                	ld	s0,0(sp)
    80001b3c:	0141                	addi	sp,sp,16
    80001b3e:	8082                	ret
    first = 0;
    80001b40:	00007797          	auipc	a5,0x7
    80001b44:	dc07a823          	sw	zero,-560(a5) # 80008910 <first.1770>
    fsinit(ROOTDEV);
    80001b48:	4505                	li	a0,1
    80001b4a:	00002097          	auipc	ra,0x2
    80001b4e:	e30080e7          	jalr	-464(ra) # 8000397a <fsinit>
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
    80001d1e:	a879                	j	80001dbc <allocproc+0xdc>
  p->pid = allocpid();
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	e34080e7          	jalr	-460(ra) # 80001b54 <allocpid>
    80001d28:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d2a:	4785                	li	a5,1
    80001d2c:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001d2e:	00007717          	auipc	a4,0x7
    80001d32:	30272703          	lw	a4,770(a4) # 80009030 <ticks>
    80001d36:	16e4a823          	sw	a4,368(s1)
  p->rtime = 0;
    80001d3a:	1604a623          	sw	zero,364(s1)
  p->etime = 0;
    80001d3e:	1604aa23          	sw	zero,372(s1)
  p->static_priority = 60;
    80001d42:	03c00693          	li	a3,60
    80001d46:	16d4ac23          	sw	a3,376(s1)
  p->num_run = 0;
    80001d4a:	1604ae23          	sw	zero,380(s1)
  p->run_last = 0;
    80001d4e:	1804a423          	sw	zero,392(s1)
  p->new_proc = 1;
    80001d52:	18f4a623          	sw	a5,396(s1)
  p->level = 0;
    80001d56:	1804a823          	sw	zero,400(s1)
  p->change_queue = 1 << p->level;
    80001d5a:	18f4ac23          	sw	a5,408(s1)
  p->in_queue = 0;
    80001d5e:	1804aa23          	sw	zero,404(s1)
  p->queue_enter_time = ticks;
    80001d62:	18e4ae23          	sw	a4,412(s1)
    p->queue[i] = 0;
    80001d66:	1a04a023          	sw	zero,416(s1)
    80001d6a:	1a04a223          	sw	zero,420(s1)
    80001d6e:	1a04a423          	sw	zero,424(s1)
    80001d72:	1a04a623          	sw	zero,428(s1)
    80001d76:	1a04a823          	sw	zero,432(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	d7a080e7          	jalr	-646(ra) # 80000af4 <kalloc>
    80001d82:	892a                	mv	s2,a0
    80001d84:	eca8                	sd	a0,88(s1)
    80001d86:	c131                	beqz	a0,80001dca <allocproc+0xea>
  p->pagetable = proc_pagetable(p);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	e10080e7          	jalr	-496(ra) # 80001b9a <proc_pagetable>
    80001d92:	892a                	mv	s2,a0
    80001d94:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d96:	c531                	beqz	a0,80001de2 <allocproc+0x102>
  memset(&p->context, 0, sizeof(p->context));
    80001d98:	07000613          	li	a2,112
    80001d9c:	4581                	li	a1,0
    80001d9e:	06048513          	addi	a0,s1,96
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	f3e080e7          	jalr	-194(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001daa:	00000797          	auipc	a5,0x0
    80001dae:	d6478793          	addi	a5,a5,-668 # 80001b0e <forkret>
    80001db2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001db4:	60bc                	ld	a5,64(s1)
    80001db6:	6705                	lui	a4,0x1
    80001db8:	97ba                	add	a5,a5,a4
    80001dba:	f4bc                	sd	a5,104(s1)
}
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	60e2                	ld	ra,24(sp)
    80001dc0:	6442                	ld	s0,16(sp)
    80001dc2:	64a2                	ld	s1,8(sp)
    80001dc4:	6902                	ld	s2,0(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret
    freeproc(p);
    80001dca:	8526                	mv	a0,s1
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	ebc080e7          	jalr	-324(ra) # 80001c88 <freeproc>
    release(&p->lock);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	ec2080e7          	jalr	-318(ra) # 80000c98 <release>
    return 0;
    80001dde:	84ca                	mv	s1,s2
    80001de0:	bff1                	j	80001dbc <allocproc+0xdc>
    freeproc(p);
    80001de2:	8526                	mv	a0,s1
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	ea4080e7          	jalr	-348(ra) # 80001c88 <freeproc>
    release(&p->lock);
    80001dec:	8526                	mv	a0,s1
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	eaa080e7          	jalr	-342(ra) # 80000c98 <release>
    return 0;
    80001df6:	84ca                	mv	s1,s2
    80001df8:	b7d1                	j	80001dbc <allocproc+0xdc>

0000000080001dfa <userinit>:
{
    80001dfa:	1101                	addi	sp,sp,-32
    80001dfc:	ec06                	sd	ra,24(sp)
    80001dfe:	e822                	sd	s0,16(sp)
    80001e00:	e426                	sd	s1,8(sp)
    80001e02:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	edc080e7          	jalr	-292(ra) # 80001ce0 <allocproc>
    80001e0c:	84aa                	mv	s1,a0
  initproc = p;
    80001e0e:	00007797          	auipc	a5,0x7
    80001e12:	20a7bd23          	sd	a0,538(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e16:	03400613          	li	a2,52
    80001e1a:	00007597          	auipc	a1,0x7
    80001e1e:	b0658593          	addi	a1,a1,-1274 # 80008920 <initcode>
    80001e22:	6928                	ld	a0,80(a0)
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	54c080e7          	jalr	1356(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001e2c:	6785                	lui	a5,0x1
    80001e2e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e30:	6cb8                	ld	a4,88(s1)
    80001e32:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e36:	6cb8                	ld	a4,88(s1)
    80001e38:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e3a:	4641                	li	a2,16
    80001e3c:	00006597          	auipc	a1,0x6
    80001e40:	3c458593          	addi	a1,a1,964 # 80008200 <digits+0x1c0>
    80001e44:	15848513          	addi	a0,s1,344
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	fea080e7          	jalr	-22(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e50:	00006517          	auipc	a0,0x6
    80001e54:	3c050513          	addi	a0,a0,960 # 80008210 <digits+0x1d0>
    80001e58:	00002097          	auipc	ra,0x2
    80001e5c:	550080e7          	jalr	1360(ra) # 800043a8 <namei>
    80001e60:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e64:	478d                	li	a5,3
    80001e66:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
}
    80001e72:	60e2                	ld	ra,24(sp)
    80001e74:	6442                	ld	s0,16(sp)
    80001e76:	64a2                	ld	s1,8(sp)
    80001e78:	6105                	addi	sp,sp,32
    80001e7a:	8082                	ret

0000000080001e7c <growproc>:
{
    80001e7c:	1101                	addi	sp,sp,-32
    80001e7e:	ec06                	sd	ra,24(sp)
    80001e80:	e822                	sd	s0,16(sp)
    80001e82:	e426                	sd	s1,8(sp)
    80001e84:	e04a                	sd	s2,0(sp)
    80001e86:	1000                	addi	s0,sp,32
    80001e88:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e8a:	00000097          	auipc	ra,0x0
    80001e8e:	c4c080e7          	jalr	-948(ra) # 80001ad6 <myproc>
    80001e92:	892a                	mv	s2,a0
  sz = p->sz;
    80001e94:	652c                	ld	a1,72(a0)
    80001e96:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001e9a:	00904f63          	bgtz	s1,80001eb8 <growproc+0x3c>
  else if (n < 0)
    80001e9e:	0204cc63          	bltz	s1,80001ed6 <growproc+0x5a>
  p->sz = sz;
    80001ea2:	1602                	slli	a2,a2,0x20
    80001ea4:	9201                	srli	a2,a2,0x20
    80001ea6:	04c93423          	sd	a2,72(s2)
  return 0;
    80001eaa:	4501                	li	a0,0
}
    80001eac:	60e2                	ld	ra,24(sp)
    80001eae:	6442                	ld	s0,16(sp)
    80001eb0:	64a2                	ld	s1,8(sp)
    80001eb2:	6902                	ld	s2,0(sp)
    80001eb4:	6105                	addi	sp,sp,32
    80001eb6:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001eb8:	9e25                	addw	a2,a2,s1
    80001eba:	1602                	slli	a2,a2,0x20
    80001ebc:	9201                	srli	a2,a2,0x20
    80001ebe:	1582                	slli	a1,a1,0x20
    80001ec0:	9181                	srli	a1,a1,0x20
    80001ec2:	6928                	ld	a0,80(a0)
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	566080e7          	jalr	1382(ra) # 8000142a <uvmalloc>
    80001ecc:	0005061b          	sext.w	a2,a0
    80001ed0:	fa69                	bnez	a2,80001ea2 <growproc+0x26>
      return -1;
    80001ed2:	557d                	li	a0,-1
    80001ed4:	bfe1                	j	80001eac <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ed6:	9e25                	addw	a2,a2,s1
    80001ed8:	1602                	slli	a2,a2,0x20
    80001eda:	9201                	srli	a2,a2,0x20
    80001edc:	1582                	slli	a1,a1,0x20
    80001ede:	9181                	srli	a1,a1,0x20
    80001ee0:	6928                	ld	a0,80(a0)
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	500080e7          	jalr	1280(ra) # 800013e2 <uvmdealloc>
    80001eea:	0005061b          	sext.w	a2,a0
    80001eee:	bf55                	j	80001ea2 <growproc+0x26>

0000000080001ef0 <fork>:
{
    80001ef0:	7179                	addi	sp,sp,-48
    80001ef2:	f406                	sd	ra,40(sp)
    80001ef4:	f022                	sd	s0,32(sp)
    80001ef6:	ec26                	sd	s1,24(sp)
    80001ef8:	e84a                	sd	s2,16(sp)
    80001efa:	e44e                	sd	s3,8(sp)
    80001efc:	e052                	sd	s4,0(sp)
    80001efe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f00:	00000097          	auipc	ra,0x0
    80001f04:	bd6080e7          	jalr	-1066(ra) # 80001ad6 <myproc>
    80001f08:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	dd6080e7          	jalr	-554(ra) # 80001ce0 <allocproc>
    80001f12:	10050f63          	beqz	a0,80002030 <fork+0x140>
    80001f16:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f18:	04893603          	ld	a2,72(s2)
    80001f1c:	692c                	ld	a1,80(a0)
    80001f1e:	05093503          	ld	a0,80(s2)
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	654080e7          	jalr	1620(ra) # 80001576 <uvmcopy>
    80001f2a:	04054a63          	bltz	a0,80001f7e <fork+0x8e>
  np->trace_mask = p->trace_mask;
    80001f2e:	16892783          	lw	a5,360(s2)
    80001f32:	16f9a423          	sw	a5,360(s3)
  np->sz = p->sz;
    80001f36:	04893783          	ld	a5,72(s2)
    80001f3a:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f3e:	05893683          	ld	a3,88(s2)
    80001f42:	87b6                	mv	a5,a3
    80001f44:	0589b703          	ld	a4,88(s3)
    80001f48:	12068693          	addi	a3,a3,288
    80001f4c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f50:	6788                	ld	a0,8(a5)
    80001f52:	6b8c                	ld	a1,16(a5)
    80001f54:	6f90                	ld	a2,24(a5)
    80001f56:	01073023          	sd	a6,0(a4)
    80001f5a:	e708                	sd	a0,8(a4)
    80001f5c:	eb0c                	sd	a1,16(a4)
    80001f5e:	ef10                	sd	a2,24(a4)
    80001f60:	02078793          	addi	a5,a5,32
    80001f64:	02070713          	addi	a4,a4,32
    80001f68:	fed792e3          	bne	a5,a3,80001f4c <fork+0x5c>
  np->trapframe->a0 = 0;
    80001f6c:	0589b783          	ld	a5,88(s3)
    80001f70:	0607b823          	sd	zero,112(a5)
    80001f74:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001f78:	15000a13          	li	s4,336
    80001f7c:	a03d                	j	80001faa <fork+0xba>
    freeproc(np);
    80001f7e:	854e                	mv	a0,s3
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	d08080e7          	jalr	-760(ra) # 80001c88 <freeproc>
    release(&np->lock);
    80001f88:	854e                	mv	a0,s3
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d0e080e7          	jalr	-754(ra) # 80000c98 <release>
    return -1;
    80001f92:	5a7d                	li	s4,-1
    80001f94:	a069                	j	8000201e <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f96:	00003097          	auipc	ra,0x3
    80001f9a:	aa8080e7          	jalr	-1368(ra) # 80004a3e <filedup>
    80001f9e:	009987b3          	add	a5,s3,s1
    80001fa2:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001fa4:	04a1                	addi	s1,s1,8
    80001fa6:	01448763          	beq	s1,s4,80001fb4 <fork+0xc4>
    if (p->ofile[i])
    80001faa:	009907b3          	add	a5,s2,s1
    80001fae:	6388                	ld	a0,0(a5)
    80001fb0:	f17d                	bnez	a0,80001f96 <fork+0xa6>
    80001fb2:	bfcd                	j	80001fa4 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001fb4:	15093503          	ld	a0,336(s2)
    80001fb8:	00002097          	auipc	ra,0x2
    80001fbc:	bfc080e7          	jalr	-1028(ra) # 80003bb4 <idup>
    80001fc0:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fc4:	4641                	li	a2,16
    80001fc6:	15890593          	addi	a1,s2,344
    80001fca:	15898513          	addi	a0,s3,344
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	e64080e7          	jalr	-412(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001fd6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001fda:	854e                	mv	a0,s3
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	cbc080e7          	jalr	-836(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001fe4:	0000f497          	auipc	s1,0xf
    80001fe8:	2d448493          	addi	s1,s1,724 # 800112b8 <wait_lock>
    80001fec:	8526                	mv	a0,s1
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	bf6080e7          	jalr	-1034(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ff6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ffa:	8526                	mv	a0,s1
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	c9c080e7          	jalr	-868(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002004:	854e                	mv	a0,s3
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	bde080e7          	jalr	-1058(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000200e:	478d                	li	a5,3
    80002010:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002014:	854e                	mv	a0,s3
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	c82080e7          	jalr	-894(ra) # 80000c98 <release>
}
    8000201e:	8552                	mv	a0,s4
    80002020:	70a2                	ld	ra,40(sp)
    80002022:	7402                	ld	s0,32(sp)
    80002024:	64e2                	ld	s1,24(sp)
    80002026:	6942                	ld	s2,16(sp)
    80002028:	69a2                	ld	s3,8(sp)
    8000202a:	6a02                	ld	s4,0(sp)
    8000202c:	6145                	addi	sp,sp,48
    8000202e:	8082                	ret
    return -1;
    80002030:	5a7d                	li	s4,-1
    80002032:	b7f5                	j	8000201e <fork+0x12e>

0000000080002034 <update_time>:
{
    80002034:	7179                	addi	sp,sp,-48
    80002036:	f406                	sd	ra,40(sp)
    80002038:	f022                	sd	s0,32(sp)
    8000203a:	ec26                	sd	s1,24(sp)
    8000203c:	e84a                	sd	s2,16(sp)
    8000203e:	e44e                	sd	s3,8(sp)
    80002040:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002042:	00010497          	auipc	s1,0x10
    80002046:	10648493          	addi	s1,s1,262 # 80012148 <proc>
    if (p->state == RUNNING)
    8000204a:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000204c:	00017917          	auipc	s2,0x17
    80002050:	efc90913          	addi	s2,s2,-260 # 80018f48 <tickslock>
    80002054:	a811                	j	80002068 <update_time+0x34>
    release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c40080e7          	jalr	-960(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002060:	1b848493          	addi	s1,s1,440
    80002064:	03248063          	beq	s1,s2,80002084 <update_time+0x50>
    acquire(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b7a080e7          	jalr	-1158(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80002072:	4c9c                	lw	a5,24(s1)
    80002074:	ff3791e3          	bne	a5,s3,80002056 <update_time+0x22>
      p->rtime++;
    80002078:	16c4a783          	lw	a5,364(s1)
    8000207c:	2785                	addiw	a5,a5,1
    8000207e:	16f4a623          	sw	a5,364(s1)
    80002082:	bfd1                	j	80002056 <update_time+0x22>
}
    80002084:	70a2                	ld	ra,40(sp)
    80002086:	7402                	ld	s0,32(sp)
    80002088:	64e2                	ld	s1,24(sp)
    8000208a:	6942                	ld	s2,16(sp)
    8000208c:	69a2                	ld	s3,8(sp)
    8000208e:	6145                	addi	sp,sp,48
    80002090:	8082                	ret

0000000080002092 <scheduler>:
{
    80002092:	7139                	addi	sp,sp,-64
    80002094:	fc06                	sd	ra,56(sp)
    80002096:	f822                	sd	s0,48(sp)
    80002098:	f426                	sd	s1,40(sp)
    8000209a:	f04a                	sd	s2,32(sp)
    8000209c:	ec4e                	sd	s3,24(sp)
    8000209e:	e852                	sd	s4,16(sp)
    800020a0:	e456                	sd	s5,8(sp)
    800020a2:	e05a                	sd	s6,0(sp)
    800020a4:	0080                	addi	s0,sp,64
    800020a6:	8792                	mv	a5,tp
  int id = r_tp();
    800020a8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020aa:	00779693          	slli	a3,a5,0x7
    800020ae:	0000f717          	auipc	a4,0xf
    800020b2:	1f270713          	addi	a4,a4,498 # 800112a0 <pid_lock>
    800020b6:	9736                	add	a4,a4,a3
    800020b8:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &minimum->context);
    800020bc:	0000f717          	auipc	a4,0xf
    800020c0:	21c70713          	addi	a4,a4,540 # 800112d8 <cpus+0x8>
    800020c4:	00e68b33          	add	s6,a3,a4
    for (p = proc; p < &proc[NPROC]; p++)
    800020c8:	00017497          	auipc	s1,0x17
    800020cc:	e8048493          	addi	s1,s1,-384 # 80018f48 <tickslock>
    int chosenFlag = 0;
    800020d0:	4981                	li	s3,0
      c->proc = minimum;
    800020d2:	0000fa17          	auipc	s4,0xf
    800020d6:	1cea0a13          	addi	s4,s4,462 # 800112a0 <pid_lock>
    800020da:	9a36                	add	s4,s4,a3
    800020dc:	a0b5                	j	80002148 <scheduler+0xb6>
        if (minimum == 0)
    800020de:	08090763          	beqz	s2,8000216c <scheduler+0xda>
        else if (p->ctime < minimum->ctime)
    800020e2:	fb87a503          	lw	a0,-72(a5)
    800020e6:	17092683          	lw	a3,368(s2)
    800020ea:	00d57363          	bgeu	a0,a3,800020f0 <scheduler+0x5e>
    800020ee:	8932                	mv	s2,a2
    for (p = proc; p < &proc[NPROC]; p++)
    800020f0:	02977c63          	bgeu	a4,s1,80002128 <scheduler+0x96>
    800020f4:	8542                	mv	a0,a6
    800020f6:	1b878793          	addi	a5,a5,440
    800020fa:	e4878613          	addi	a2,a5,-440
      if (p->state == RUNNABLE)
    800020fe:	873e                	mv	a4,a5
    80002100:	e607a683          	lw	a3,-416(a5)
    80002104:	fcb68de3          	beq	a3,a1,800020de <scheduler+0x4c>
    for (p = proc; p < &proc[NPROC]; p++)
    80002108:	fe97e7e3          	bltu	a5,s1,800020f6 <scheduler+0x64>
    if (chosenFlag == 0)
    8000210c:	ed11                	bnez	a0,80002128 <scheduler+0x96>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000210e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002112:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002116:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000211a:	00010797          	auipc	a5,0x10
    8000211e:	1e678793          	addi	a5,a5,486 # 80012300 <proc+0x1b8>
    int chosenFlag = 0;
    80002122:	854e                	mv	a0,s3
    struct proc *minimum = 0;
    80002124:	894e                	mv	s2,s3
    80002126:	bfd1                	j	800020fa <scheduler+0x68>
    acquire(&minimum->lock);
    80002128:	8aca                	mv	s5,s2
    8000212a:	854a                	mv	a0,s2
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	ab8080e7          	jalr	-1352(ra) # 80000be4 <acquire>
    if (minimum->state == RUNNABLE)
    80002134:	01892703          	lw	a4,24(s2)
    80002138:	478d                	li	a5,3
    8000213a:	00f70a63          	beq	a4,a5,8000214e <scheduler+0xbc>
    release(&minimum->lock);
    8000213e:	8556                	mv	a0,s5
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b58080e7          	jalr	-1192(ra) # 80000c98 <release>
      if (p->state == RUNNABLE)
    80002148:	458d                	li	a1,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000214a:	4805                	li	a6,1
    8000214c:	b7c9                	j	8000210e <scheduler+0x7c>
      minimum->state = RUNNING;
    8000214e:	4791                	li	a5,4
    80002150:	00f92c23          	sw	a5,24(s2)
      c->proc = minimum;
    80002154:	032a3823          	sd	s2,48(s4)
      swtch(&c->context, &minimum->context);
    80002158:	06090593          	addi	a1,s2,96
    8000215c:	855a                	mv	a0,s6
    8000215e:	00001097          	auipc	ra,0x1
    80002162:	820080e7          	jalr	-2016(ra) # 8000297e <swtch>
      c->proc = 0;
    80002166:	020a3823          	sd	zero,48(s4)
    8000216a:	bfd1                	j	8000213e <scheduler+0xac>
    8000216c:	8932                	mv	s2,a2
    8000216e:	b749                	j	800020f0 <scheduler+0x5e>

0000000080002170 <sched>:
{
    80002170:	7179                	addi	sp,sp,-48
    80002172:	f406                	sd	ra,40(sp)
    80002174:	f022                	sd	s0,32(sp)
    80002176:	ec26                	sd	s1,24(sp)
    80002178:	e84a                	sd	s2,16(sp)
    8000217a:	e44e                	sd	s3,8(sp)
    8000217c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	958080e7          	jalr	-1704(ra) # 80001ad6 <myproc>
    80002186:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	9e2080e7          	jalr	-1566(ra) # 80000b6a <holding>
    80002190:	c93d                	beqz	a0,80002206 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002192:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002194:	2781                	sext.w	a5,a5
    80002196:	079e                	slli	a5,a5,0x7
    80002198:	0000f717          	auipc	a4,0xf
    8000219c:	10870713          	addi	a4,a4,264 # 800112a0 <pid_lock>
    800021a0:	97ba                	add	a5,a5,a4
    800021a2:	0a87a703          	lw	a4,168(a5)
    800021a6:	4785                	li	a5,1
    800021a8:	06f71763          	bne	a4,a5,80002216 <sched+0xa6>
  if (p->state == RUNNING)
    800021ac:	4c98                	lw	a4,24(s1)
    800021ae:	4791                	li	a5,4
    800021b0:	06f70b63          	beq	a4,a5,80002226 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021b8:	8b89                	andi	a5,a5,2
  if (intr_get())
    800021ba:	efb5                	bnez	a5,80002236 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021bc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021be:	0000f917          	auipc	s2,0xf
    800021c2:	0e290913          	addi	s2,s2,226 # 800112a0 <pid_lock>
    800021c6:	2781                	sext.w	a5,a5
    800021c8:	079e                	slli	a5,a5,0x7
    800021ca:	97ca                	add	a5,a5,s2
    800021cc:	0ac7a983          	lw	s3,172(a5)
    800021d0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021d2:	2781                	sext.w	a5,a5
    800021d4:	079e                	slli	a5,a5,0x7
    800021d6:	0000f597          	auipc	a1,0xf
    800021da:	10258593          	addi	a1,a1,258 # 800112d8 <cpus+0x8>
    800021de:	95be                	add	a1,a1,a5
    800021e0:	06048513          	addi	a0,s1,96
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	79a080e7          	jalr	1946(ra) # 8000297e <swtch>
    800021ec:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ee:	2781                	sext.w	a5,a5
    800021f0:	079e                	slli	a5,a5,0x7
    800021f2:	97ca                	add	a5,a5,s2
    800021f4:	0b37a623          	sw	s3,172(a5)
}
    800021f8:	70a2                	ld	ra,40(sp)
    800021fa:	7402                	ld	s0,32(sp)
    800021fc:	64e2                	ld	s1,24(sp)
    800021fe:	6942                	ld	s2,16(sp)
    80002200:	69a2                	ld	s3,8(sp)
    80002202:	6145                	addi	sp,sp,48
    80002204:	8082                	ret
    panic("sched p->lock");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	01250513          	addi	a0,a0,18 # 80008218 <digits+0x1d8>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	330080e7          	jalr	816(ra) # 8000053e <panic>
    panic("sched locks");
    80002216:	00006517          	auipc	a0,0x6
    8000221a:	01250513          	addi	a0,a0,18 # 80008228 <digits+0x1e8>
    8000221e:	ffffe097          	auipc	ra,0xffffe
    80002222:	320080e7          	jalr	800(ra) # 8000053e <panic>
    panic("sched running");
    80002226:	00006517          	auipc	a0,0x6
    8000222a:	01250513          	addi	a0,a0,18 # 80008238 <digits+0x1f8>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	01250513          	addi	a0,a0,18 # 80008248 <digits+0x208>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	300080e7          	jalr	768(ra) # 8000053e <panic>

0000000080002246 <yield>:
{
    80002246:	1101                	addi	sp,sp,-32
    80002248:	ec06                	sd	ra,24(sp)
    8000224a:	e822                	sd	s0,16(sp)
    8000224c:	e426                	sd	s1,8(sp)
    8000224e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002250:	00000097          	auipc	ra,0x0
    80002254:	886080e7          	jalr	-1914(ra) # 80001ad6 <myproc>
    80002258:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002262:	478d                	li	a5,3
    80002264:	cc9c                	sw	a5,24(s1)
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	f0a080e7          	jalr	-246(ra) # 80002170 <sched>
  release(&p->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
}
    80002278:	60e2                	ld	ra,24(sp)
    8000227a:	6442                	ld	s0,16(sp)
    8000227c:	64a2                	ld	s1,8(sp)
    8000227e:	6105                	addi	sp,sp,32
    80002280:	8082                	ret

0000000080002282 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002282:	7179                	addi	sp,sp,-48
    80002284:	f406                	sd	ra,40(sp)
    80002286:	f022                	sd	s0,32(sp)
    80002288:	ec26                	sd	s1,24(sp)
    8000228a:	e84a                	sd	s2,16(sp)
    8000228c:	e44e                	sd	s3,8(sp)
    8000228e:	1800                	addi	s0,sp,48
    80002290:	89aa                	mv	s3,a0
    80002292:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	842080e7          	jalr	-1982(ra) # 80001ad6 <myproc>
    8000229c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	946080e7          	jalr	-1722(ra) # 80000be4 <acquire>
  release(lk);
    800022a6:	854a                	mv	a0,s2
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800022b0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022b4:	4789                	li	a5,2
    800022b6:	cc9c                	sw	a5,24(s1)

  sched();
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	eb8080e7          	jalr	-328(ra) # 80002170 <sched>

  // Tidy up.
  p->chan = 0;
    800022c0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
  acquire(lk);
    800022ce:	854a                	mv	a0,s2
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	914080e7          	jalr	-1772(ra) # 80000be4 <acquire>
}
    800022d8:	70a2                	ld	ra,40(sp)
    800022da:	7402                	ld	s0,32(sp)
    800022dc:	64e2                	ld	s1,24(sp)
    800022de:	6942                	ld	s2,16(sp)
    800022e0:	69a2                	ld	s3,8(sp)
    800022e2:	6145                	addi	sp,sp,48
    800022e4:	8082                	ret

00000000800022e6 <wait>:
{
    800022e6:	715d                	addi	sp,sp,-80
    800022e8:	e486                	sd	ra,72(sp)
    800022ea:	e0a2                	sd	s0,64(sp)
    800022ec:	fc26                	sd	s1,56(sp)
    800022ee:	f84a                	sd	s2,48(sp)
    800022f0:	f44e                	sd	s3,40(sp)
    800022f2:	f052                	sd	s4,32(sp)
    800022f4:	ec56                	sd	s5,24(sp)
    800022f6:	e85a                	sd	s6,16(sp)
    800022f8:	e45e                	sd	s7,8(sp)
    800022fa:	e062                	sd	s8,0(sp)
    800022fc:	0880                	addi	s0,sp,80
    800022fe:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	7d6080e7          	jalr	2006(ra) # 80001ad6 <myproc>
    80002308:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000230a:	0000f517          	auipc	a0,0xf
    8000230e:	fae50513          	addi	a0,a0,-82 # 800112b8 <wait_lock>
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8d2080e7          	jalr	-1838(ra) # 80000be4 <acquire>
    havekids = 0;
    8000231a:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000231c:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000231e:	00017997          	auipc	s3,0x17
    80002322:	c2a98993          	addi	s3,s3,-982 # 80018f48 <tickslock>
        havekids = 1;
    80002326:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002328:	0000fc17          	auipc	s8,0xf
    8000232c:	f90c0c13          	addi	s8,s8,-112 # 800112b8 <wait_lock>
    havekids = 0;
    80002330:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002332:	00010497          	auipc	s1,0x10
    80002336:	e1648493          	addi	s1,s1,-490 # 80012148 <proc>
    8000233a:	a0bd                	j	800023a8 <wait+0xc2>
          pid = np->pid;
    8000233c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002340:	000b0e63          	beqz	s6,8000235c <wait+0x76>
    80002344:	4691                	li	a3,4
    80002346:	02c48613          	addi	a2,s1,44
    8000234a:	85da                	mv	a1,s6
    8000234c:	05093503          	ld	a0,80(s2)
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	32a080e7          	jalr	810(ra) # 8000167a <copyout>
    80002358:	02054563          	bltz	a0,80002382 <wait+0x9c>
          freeproc(np);
    8000235c:	8526                	mv	a0,s1
    8000235e:	00000097          	auipc	ra,0x0
    80002362:	92a080e7          	jalr	-1750(ra) # 80001c88 <freeproc>
          release(&np->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	930080e7          	jalr	-1744(ra) # 80000c98 <release>
          release(&wait_lock);
    80002370:	0000f517          	auipc	a0,0xf
    80002374:	f4850513          	addi	a0,a0,-184 # 800112b8 <wait_lock>
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
          return pid;
    80002380:	a09d                	j	800023e6 <wait+0x100>
            release(&np->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	914080e7          	jalr	-1772(ra) # 80000c98 <release>
            release(&wait_lock);
    8000238c:	0000f517          	auipc	a0,0xf
    80002390:	f2c50513          	addi	a0,a0,-212 # 800112b8 <wait_lock>
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	904080e7          	jalr	-1788(ra) # 80000c98 <release>
            return -1;
    8000239c:	59fd                	li	s3,-1
    8000239e:	a0a1                	j	800023e6 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800023a0:	1b848493          	addi	s1,s1,440
    800023a4:	03348463          	beq	s1,s3,800023cc <wait+0xe6>
      if (np->parent == p)
    800023a8:	7c9c                	ld	a5,56(s1)
    800023aa:	ff279be3          	bne	a5,s2,800023a0 <wait+0xba>
        acquire(&np->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800023b8:	4c9c                	lw	a5,24(s1)
    800023ba:	f94781e3          	beq	a5,s4,8000233c <wait+0x56>
        release(&np->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
        havekids = 1;
    800023c8:	8756                	mv	a4,s5
    800023ca:	bfd9                	j	800023a0 <wait+0xba>
    if (!havekids || p->killed)
    800023cc:	c701                	beqz	a4,800023d4 <wait+0xee>
    800023ce:	02892783          	lw	a5,40(s2)
    800023d2:	c79d                	beqz	a5,80002400 <wait+0x11a>
      release(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	ee450513          	addi	a0,a0,-284 # 800112b8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8bc080e7          	jalr	-1860(ra) # 80000c98 <release>
      return -1;
    800023e4:	59fd                	li	s3,-1
}
    800023e6:	854e                	mv	a0,s3
    800023e8:	60a6                	ld	ra,72(sp)
    800023ea:	6406                	ld	s0,64(sp)
    800023ec:	74e2                	ld	s1,56(sp)
    800023ee:	7942                	ld	s2,48(sp)
    800023f0:	79a2                	ld	s3,40(sp)
    800023f2:	7a02                	ld	s4,32(sp)
    800023f4:	6ae2                	ld	s5,24(sp)
    800023f6:	6b42                	ld	s6,16(sp)
    800023f8:	6ba2                	ld	s7,8(sp)
    800023fa:	6c02                	ld	s8,0(sp)
    800023fc:	6161                	addi	sp,sp,80
    800023fe:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002400:	85e2                	mv	a1,s8
    80002402:	854a                	mv	a0,s2
    80002404:	00000097          	auipc	ra,0x0
    80002408:	e7e080e7          	jalr	-386(ra) # 80002282 <sleep>
    havekids = 0;
    8000240c:	b715                	j	80002330 <wait+0x4a>

000000008000240e <waitx>:
{
    8000240e:	711d                	addi	sp,sp,-96
    80002410:	ec86                	sd	ra,88(sp)
    80002412:	e8a2                	sd	s0,80(sp)
    80002414:	e4a6                	sd	s1,72(sp)
    80002416:	e0ca                	sd	s2,64(sp)
    80002418:	fc4e                	sd	s3,56(sp)
    8000241a:	f852                	sd	s4,48(sp)
    8000241c:	f456                	sd	s5,40(sp)
    8000241e:	f05a                	sd	s6,32(sp)
    80002420:	ec5e                	sd	s7,24(sp)
    80002422:	e862                	sd	s8,16(sp)
    80002424:	e466                	sd	s9,8(sp)
    80002426:	e06a                	sd	s10,0(sp)
    80002428:	1080                	addi	s0,sp,96
    8000242a:	8b2a                	mv	s6,a0
    8000242c:	8c2e                	mv	s8,a1
    8000242e:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	6a6080e7          	jalr	1702(ra) # 80001ad6 <myproc>
    80002438:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000243a:	0000f517          	auipc	a0,0xf
    8000243e:	e7e50513          	addi	a0,a0,-386 # 800112b8 <wait_lock>
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	7a2080e7          	jalr	1954(ra) # 80000be4 <acquire>
    havekids = 0;
    8000244a:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000244c:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000244e:	00017997          	auipc	s3,0x17
    80002452:	afa98993          	addi	s3,s3,-1286 # 80018f48 <tickslock>
        havekids = 1;
    80002456:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002458:	0000fd17          	auipc	s10,0xf
    8000245c:	e60d0d13          	addi	s10,s10,-416 # 800112b8 <wait_lock>
    havekids = 0;
    80002460:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002462:	00010497          	auipc	s1,0x10
    80002466:	ce648493          	addi	s1,s1,-794 # 80012148 <proc>
    8000246a:	a059                	j	800024f0 <waitx+0xe2>
          pid = np->pid;
    8000246c:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002470:	16c4a703          	lw	a4,364(s1)
    80002474:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002478:	1704a783          	lw	a5,368(s1)
    8000247c:	9f3d                	addw	a4,a4,a5
    8000247e:	1744a783          	lw	a5,372(s1)
    80002482:	9f99                	subw	a5,a5,a4
    80002484:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002488:	000b0e63          	beqz	s6,800024a4 <waitx+0x96>
    8000248c:	4691                	li	a3,4
    8000248e:	02c48613          	addi	a2,s1,44
    80002492:	85da                	mv	a1,s6
    80002494:	05093503          	ld	a0,80(s2)
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	1e2080e7          	jalr	482(ra) # 8000167a <copyout>
    800024a0:	02054563          	bltz	a0,800024ca <waitx+0xbc>
          freeproc(np);
    800024a4:	8526                	mv	a0,s1
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	7e2080e7          	jalr	2018(ra) # 80001c88 <freeproc>
          release(&np->lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7e8080e7          	jalr	2024(ra) # 80000c98 <release>
          release(&wait_lock);
    800024b8:	0000f517          	auipc	a0,0xf
    800024bc:	e0050513          	addi	a0,a0,-512 # 800112b8 <wait_lock>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	7d8080e7          	jalr	2008(ra) # 80000c98 <release>
          return pid;
    800024c8:	a09d                	j	8000252e <waitx+0x120>
            release(&np->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
            release(&wait_lock);
    800024d4:	0000f517          	auipc	a0,0xf
    800024d8:	de450513          	addi	a0,a0,-540 # 800112b8 <wait_lock>
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	7bc080e7          	jalr	1980(ra) # 80000c98 <release>
            return -1;
    800024e4:	59fd                	li	s3,-1
    800024e6:	a0a1                	j	8000252e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800024e8:	1b848493          	addi	s1,s1,440
    800024ec:	03348463          	beq	s1,s3,80002514 <waitx+0x106>
      if (np->parent == p)
    800024f0:	7c9c                	ld	a5,56(s1)
    800024f2:	ff279be3          	bne	a5,s2,800024e8 <waitx+0xda>
        acquire(&np->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	6ec080e7          	jalr	1772(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002500:	4c9c                	lw	a5,24(s1)
    80002502:	f74785e3          	beq	a5,s4,8000246c <waitx+0x5e>
        release(&np->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	790080e7          	jalr	1936(ra) # 80000c98 <release>
        havekids = 1;
    80002510:	8756                	mv	a4,s5
    80002512:	bfd9                	j	800024e8 <waitx+0xda>
    if (!havekids || p->killed)
    80002514:	c701                	beqz	a4,8000251c <waitx+0x10e>
    80002516:	02892783          	lw	a5,40(s2)
    8000251a:	cb8d                	beqz	a5,8000254c <waitx+0x13e>
      release(&wait_lock);
    8000251c:	0000f517          	auipc	a0,0xf
    80002520:	d9c50513          	addi	a0,a0,-612 # 800112b8 <wait_lock>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
      return -1;
    8000252c:	59fd                	li	s3,-1
}
    8000252e:	854e                	mv	a0,s3
    80002530:	60e6                	ld	ra,88(sp)
    80002532:	6446                	ld	s0,80(sp)
    80002534:	64a6                	ld	s1,72(sp)
    80002536:	6906                	ld	s2,64(sp)
    80002538:	79e2                	ld	s3,56(sp)
    8000253a:	7a42                	ld	s4,48(sp)
    8000253c:	7aa2                	ld	s5,40(sp)
    8000253e:	7b02                	ld	s6,32(sp)
    80002540:	6be2                	ld	s7,24(sp)
    80002542:	6c42                	ld	s8,16(sp)
    80002544:	6ca2                	ld	s9,8(sp)
    80002546:	6d02                	ld	s10,0(sp)
    80002548:	6125                	addi	sp,sp,96
    8000254a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000254c:	85ea                	mv	a1,s10
    8000254e:	854a                	mv	a0,s2
    80002550:	00000097          	auipc	ra,0x0
    80002554:	d32080e7          	jalr	-718(ra) # 80002282 <sleep>
    havekids = 0;
    80002558:	b721                	j	80002460 <waitx+0x52>

000000008000255a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000255a:	7139                	addi	sp,sp,-64
    8000255c:	fc06                	sd	ra,56(sp)
    8000255e:	f822                	sd	s0,48(sp)
    80002560:	f426                	sd	s1,40(sp)
    80002562:	f04a                	sd	s2,32(sp)
    80002564:	ec4e                	sd	s3,24(sp)
    80002566:	e852                	sd	s4,16(sp)
    80002568:	e456                	sd	s5,8(sp)
    8000256a:	0080                	addi	s0,sp,64
    8000256c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000256e:	00010497          	auipc	s1,0x10
    80002572:	bda48493          	addi	s1,s1,-1062 # 80012148 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002576:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002578:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	00017917          	auipc	s2,0x17
    8000257e:	9ce90913          	addi	s2,s2,-1586 # 80018f48 <tickslock>
    80002582:	a821                	j	8000259a <wakeup+0x40>
        p->state = RUNNABLE;
    80002584:	0154ac23          	sw	s5,24(s1)
#ifdef PBS
        p->sched_end = ticks;
#endif
      }
      release(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	70e080e7          	jalr	1806(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002592:	1b848493          	addi	s1,s1,440
    80002596:	03248463          	beq	s1,s2,800025be <wakeup+0x64>
    if (p != myproc())
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	53c080e7          	jalr	1340(ra) # 80001ad6 <myproc>
    800025a2:	fea488e3          	beq	s1,a0,80002592 <wakeup+0x38>
      acquire(&p->lock);
    800025a6:	8526                	mv	a0,s1
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	63c080e7          	jalr	1596(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800025b0:	4c9c                	lw	a5,24(s1)
    800025b2:	fd379be3          	bne	a5,s3,80002588 <wakeup+0x2e>
    800025b6:	709c                	ld	a5,32(s1)
    800025b8:	fd4798e3          	bne	a5,s4,80002588 <wakeup+0x2e>
    800025bc:	b7e1                	j	80002584 <wakeup+0x2a>
    }
  }
}
    800025be:	70e2                	ld	ra,56(sp)
    800025c0:	7442                	ld	s0,48(sp)
    800025c2:	74a2                	ld	s1,40(sp)
    800025c4:	7902                	ld	s2,32(sp)
    800025c6:	69e2                	ld	s3,24(sp)
    800025c8:	6a42                	ld	s4,16(sp)
    800025ca:	6aa2                	ld	s5,8(sp)
    800025cc:	6121                	addi	sp,sp,64
    800025ce:	8082                	ret

00000000800025d0 <reparent>:
{
    800025d0:	7179                	addi	sp,sp,-48
    800025d2:	f406                	sd	ra,40(sp)
    800025d4:	f022                	sd	s0,32(sp)
    800025d6:	ec26                	sd	s1,24(sp)
    800025d8:	e84a                	sd	s2,16(sp)
    800025da:	e44e                	sd	s3,8(sp)
    800025dc:	e052                	sd	s4,0(sp)
    800025de:	1800                	addi	s0,sp,48
    800025e0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e2:	00010497          	auipc	s1,0x10
    800025e6:	b6648493          	addi	s1,s1,-1178 # 80012148 <proc>
      pp->parent = initproc;
    800025ea:	00007a17          	auipc	s4,0x7
    800025ee:	a3ea0a13          	addi	s4,s4,-1474 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025f2:	00017997          	auipc	s3,0x17
    800025f6:	95698993          	addi	s3,s3,-1706 # 80018f48 <tickslock>
    800025fa:	a029                	j	80002604 <reparent+0x34>
    800025fc:	1b848493          	addi	s1,s1,440
    80002600:	01348d63          	beq	s1,s3,8000261a <reparent+0x4a>
    if (pp->parent == p)
    80002604:	7c9c                	ld	a5,56(s1)
    80002606:	ff279be3          	bne	a5,s2,800025fc <reparent+0x2c>
      pp->parent = initproc;
    8000260a:	000a3503          	ld	a0,0(s4)
    8000260e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002610:	00000097          	auipc	ra,0x0
    80002614:	f4a080e7          	jalr	-182(ra) # 8000255a <wakeup>
    80002618:	b7d5                	j	800025fc <reparent+0x2c>
}
    8000261a:	70a2                	ld	ra,40(sp)
    8000261c:	7402                	ld	s0,32(sp)
    8000261e:	64e2                	ld	s1,24(sp)
    80002620:	6942                	ld	s2,16(sp)
    80002622:	69a2                	ld	s3,8(sp)
    80002624:	6a02                	ld	s4,0(sp)
    80002626:	6145                	addi	sp,sp,48
    80002628:	8082                	ret

000000008000262a <exit>:
{
    8000262a:	7179                	addi	sp,sp,-48
    8000262c:	f406                	sd	ra,40(sp)
    8000262e:	f022                	sd	s0,32(sp)
    80002630:	ec26                	sd	s1,24(sp)
    80002632:	e84a                	sd	s2,16(sp)
    80002634:	e44e                	sd	s3,8(sp)
    80002636:	e052                	sd	s4,0(sp)
    80002638:	1800                	addi	s0,sp,48
    8000263a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	49a080e7          	jalr	1178(ra) # 80001ad6 <myproc>
    80002644:	89aa                	mv	s3,a0
  if (p == initproc)
    80002646:	00007797          	auipc	a5,0x7
    8000264a:	9e27b783          	ld	a5,-1566(a5) # 80009028 <initproc>
    8000264e:	0d050493          	addi	s1,a0,208
    80002652:	15050913          	addi	s2,a0,336
    80002656:	02a79363          	bne	a5,a0,8000267c <exit+0x52>
    panic("init exiting");
    8000265a:	00006517          	auipc	a0,0x6
    8000265e:	c0650513          	addi	a0,a0,-1018 # 80008260 <digits+0x220>
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	edc080e7          	jalr	-292(ra) # 8000053e <panic>
      fileclose(f);
    8000266a:	00002097          	auipc	ra,0x2
    8000266e:	426080e7          	jalr	1062(ra) # 80004a90 <fileclose>
      p->ofile[fd] = 0;
    80002672:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002676:	04a1                	addi	s1,s1,8
    80002678:	01248563          	beq	s1,s2,80002682 <exit+0x58>
    if (p->ofile[fd])
    8000267c:	6088                	ld	a0,0(s1)
    8000267e:	f575                	bnez	a0,8000266a <exit+0x40>
    80002680:	bfdd                	j	80002676 <exit+0x4c>
  begin_op();
    80002682:	00002097          	auipc	ra,0x2
    80002686:	f42080e7          	jalr	-190(ra) # 800045c4 <begin_op>
  iput(p->cwd);
    8000268a:	1509b503          	ld	a0,336(s3)
    8000268e:	00001097          	auipc	ra,0x1
    80002692:	71e080e7          	jalr	1822(ra) # 80003dac <iput>
  end_op();
    80002696:	00002097          	auipc	ra,0x2
    8000269a:	fae080e7          	jalr	-82(ra) # 80004644 <end_op>
  p->cwd = 0;
    8000269e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026a2:	0000f497          	auipc	s1,0xf
    800026a6:	c1648493          	addi	s1,s1,-1002 # 800112b8 <wait_lock>
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  reparent(p);
    800026b4:	854e                	mv	a0,s3
    800026b6:	00000097          	auipc	ra,0x0
    800026ba:	f1a080e7          	jalr	-230(ra) # 800025d0 <reparent>
  wakeup(p->parent);
    800026be:	0389b503          	ld	a0,56(s3)
    800026c2:	00000097          	auipc	ra,0x0
    800026c6:	e98080e7          	jalr	-360(ra) # 8000255a <wakeup>
  acquire(&p->lock);
    800026ca:	854e                	mv	a0,s3
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	518080e7          	jalr	1304(ra) # 80000be4 <acquire>
  p->xstate = status;
    800026d4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026d8:	4795                	li	a5,5
    800026da:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800026de:	00007797          	auipc	a5,0x7
    800026e2:	9527a783          	lw	a5,-1710(a5) # 80009030 <ticks>
    800026e6:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
  sched();
    800026f4:	00000097          	auipc	ra,0x0
    800026f8:	a7c080e7          	jalr	-1412(ra) # 80002170 <sched>
  panic("zombie exit");
    800026fc:	00006517          	auipc	a0,0x6
    80002700:	b7450513          	addi	a0,a0,-1164 # 80008270 <digits+0x230>
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>

000000008000270c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000270c:	7179                	addi	sp,sp,-48
    8000270e:	f406                	sd	ra,40(sp)
    80002710:	f022                	sd	s0,32(sp)
    80002712:	ec26                	sd	s1,24(sp)
    80002714:	e84a                	sd	s2,16(sp)
    80002716:	e44e                	sd	s3,8(sp)
    80002718:	1800                	addi	s0,sp,48
    8000271a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000271c:	00010497          	auipc	s1,0x10
    80002720:	a2c48493          	addi	s1,s1,-1492 # 80012148 <proc>
    80002724:	00017997          	auipc	s3,0x17
    80002728:	82498993          	addi	s3,s3,-2012 # 80018f48 <tickslock>
  {
    acquire(&p->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	4b6080e7          	jalr	1206(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002736:	589c                	lw	a5,48(s1)
    80002738:	01278d63          	beq	a5,s2,80002752 <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002746:	1b848493          	addi	s1,s1,440
    8000274a:	ff3491e3          	bne	s1,s3,8000272c <kill+0x20>
  }
  return -1;
    8000274e:	557d                	li	a0,-1
    80002750:	a829                	j	8000276a <kill+0x5e>
      p->killed = 1;
    80002752:	4785                	li	a5,1
    80002754:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002756:	4c98                	lw	a4,24(s1)
    80002758:	4789                	li	a5,2
    8000275a:	00f70f63          	beq	a4,a5,80002778 <kill+0x6c>
      release(&p->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	538080e7          	jalr	1336(ra) # 80000c98 <release>
      return 0;
    80002768:	4501                	li	a0,0
}
    8000276a:	70a2                	ld	ra,40(sp)
    8000276c:	7402                	ld	s0,32(sp)
    8000276e:	64e2                	ld	s1,24(sp)
    80002770:	6942                	ld	s2,16(sp)
    80002772:	69a2                	ld	s3,8(sp)
    80002774:	6145                	addi	sp,sp,48
    80002776:	8082                	ret
        p->state = RUNNABLE;
    80002778:	478d                	li	a5,3
    8000277a:	cc9c                	sw	a5,24(s1)
    8000277c:	b7cd                	j	8000275e <kill+0x52>

000000008000277e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000277e:	7179                	addi	sp,sp,-48
    80002780:	f406                	sd	ra,40(sp)
    80002782:	f022                	sd	s0,32(sp)
    80002784:	ec26                	sd	s1,24(sp)
    80002786:	e84a                	sd	s2,16(sp)
    80002788:	e44e                	sd	s3,8(sp)
    8000278a:	e052                	sd	s4,0(sp)
    8000278c:	1800                	addi	s0,sp,48
    8000278e:	84aa                	mv	s1,a0
    80002790:	892e                	mv	s2,a1
    80002792:	89b2                	mv	s3,a2
    80002794:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	340080e7          	jalr	832(ra) # 80001ad6 <myproc>
  if (user_dst)
    8000279e:	c08d                	beqz	s1,800027c0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027a0:	86d2                	mv	a3,s4
    800027a2:	864e                	mv	a2,s3
    800027a4:	85ca                	mv	a1,s2
    800027a6:	6928                	ld	a0,80(a0)
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	ed2080e7          	jalr	-302(ra) # 8000167a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6a02                	ld	s4,0(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret
    memmove((char *)dst, src, len);
    800027c0:	000a061b          	sext.w	a2,s4
    800027c4:	85ce                	mv	a1,s3
    800027c6:	854a                	mv	a0,s2
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	578080e7          	jalr	1400(ra) # 80000d40 <memmove>
    return 0;
    800027d0:	8526                	mv	a0,s1
    800027d2:	bff9                	j	800027b0 <either_copyout+0x32>

00000000800027d4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d4:	7179                	addi	sp,sp,-48
    800027d6:	f406                	sd	ra,40(sp)
    800027d8:	f022                	sd	s0,32(sp)
    800027da:	ec26                	sd	s1,24(sp)
    800027dc:	e84a                	sd	s2,16(sp)
    800027de:	e44e                	sd	s3,8(sp)
    800027e0:	e052                	sd	s4,0(sp)
    800027e2:	1800                	addi	s0,sp,48
    800027e4:	892a                	mv	s2,a0
    800027e6:	84ae                	mv	s1,a1
    800027e8:	89b2                	mv	s3,a2
    800027ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	2ea080e7          	jalr	746(ra) # 80001ad6 <myproc>
  if (user_src)
    800027f4:	c08d                	beqz	s1,80002816 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027f6:	86d2                	mv	a3,s4
    800027f8:	864e                	mv	a2,s3
    800027fa:	85ca                	mv	a1,s2
    800027fc:	6928                	ld	a0,80(a0)
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	f08080e7          	jalr	-248(ra) # 80001706 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002806:	70a2                	ld	ra,40(sp)
    80002808:	7402                	ld	s0,32(sp)
    8000280a:	64e2                	ld	s1,24(sp)
    8000280c:	6942                	ld	s2,16(sp)
    8000280e:	69a2                	ld	s3,8(sp)
    80002810:	6a02                	ld	s4,0(sp)
    80002812:	6145                	addi	sp,sp,48
    80002814:	8082                	ret
    memmove(dst, (char *)src, len);
    80002816:	000a061b          	sext.w	a2,s4
    8000281a:	85ce                	mv	a1,s3
    8000281c:	854a                	mv	a0,s2
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	522080e7          	jalr	1314(ra) # 80000d40 <memmove>
    return 0;
    80002826:	8526                	mv	a0,s1
    80002828:	bff9                	j	80002806 <either_copyin+0x32>

000000008000282a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000282a:	715d                	addi	sp,sp,-80
    8000282c:	e486                	sd	ra,72(sp)
    8000282e:	e0a2                	sd	s0,64(sp)
    80002830:	fc26                	sd	s1,56(sp)
    80002832:	f84a                	sd	s2,48(sp)
    80002834:	f44e                	sd	s3,40(sp)
    80002836:	f052                	sd	s4,32(sp)
    80002838:	ec56                	sd	s5,24(sp)
    8000283a:	e85a                	sd	s6,16(sp)
    8000283c:	e45e                	sd	s7,8(sp)
    8000283e:	0880                	addi	s0,sp,80
  printf("PID Priority State rtime wtime nrun\n");
  #endif
  #ifdef MLFQ
  printf("PID Priority State rtime wtime nrun q0 q1 q2 q3 q4\n");
  #endif
  printf("\n");
    80002840:	00006517          	auipc	a0,0x6
    80002844:	be050513          	addi	a0,a0,-1056 # 80008420 <states.1807+0x160>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d40080e7          	jalr	-704(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002850:	00010497          	auipc	s1,0x10
    80002854:	a5048493          	addi	s1,s1,-1456 # 800122a0 <proc+0x158>
    80002858:	00017917          	auipc	s2,0x17
    8000285c:	84890913          	addi	s2,s2,-1976 # 800190a0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002860:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002862:	00006997          	auipc	s3,0x6
    80002866:	a1e98993          	addi	s3,s3,-1506 # 80008280 <digits+0x240>
    #ifdef DEFAULT
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
    #endif
    #ifdef FCFS
    printf("%d %s %s", p->pid, state, p->name);
    8000286a:	00006a97          	auipc	s5,0x6
    8000286e:	a1ea8a93          	addi	s5,s5,-1506 # 80008288 <digits+0x248>
    printf("\n");
    80002872:	00006a17          	auipc	s4,0x6
    80002876:	baea0a13          	addi	s4,s4,-1106 # 80008420 <states.1807+0x160>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287a:	00006b97          	auipc	s7,0x6
    8000287e:	a46b8b93          	addi	s7,s7,-1466 # 800082c0 <states.1807>
    80002882:	a00d                	j	800028a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002884:	ed86a583          	lw	a1,-296(a3)
    80002888:	8556                	mv	a0,s5
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cfe080e7          	jalr	-770(ra) # 80000588 <printf>
    printf("\n");
    80002892:	8552                	mv	a0,s4
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	cf4080e7          	jalr	-780(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000289c:	1b848493          	addi	s1,s1,440
    800028a0:	03248163          	beq	s1,s2,800028c2 <procdump+0x98>
    if (p->state == UNUSED)
    800028a4:	86a6                	mv	a3,s1
    800028a6:	ec04a783          	lw	a5,-320(s1)
    800028aa:	dbed                	beqz	a5,8000289c <procdump+0x72>
      state = "???";
    800028ac:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	fcfb6be3          	bltu	s6,a5,80002884 <procdump+0x5a>
    800028b2:	1782                	slli	a5,a5,0x20
    800028b4:	9381                	srli	a5,a5,0x20
    800028b6:	078e                	slli	a5,a5,0x3
    800028b8:	97de                	add	a5,a5,s7
    800028ba:	6390                	ld	a2,0(a5)
    800028bc:	f661                	bnez	a2,80002884 <procdump+0x5a>
      state = "???";
    800028be:	864e                	mv	a2,s3
    800028c0:	b7d1                	j	80002884 <procdump+0x5a>
    #endif
    #ifdef MLFQ
    printf("%d %d %s %d %d %d %d %d %d %d %d\n", p->pid, (p->level >= 0) ? p->level : -1, state, p->rtime, ticks - p->queue_enter_time, p->num_run, p->queue[0], p->queue[1], p->queue[2], p->queue[3], p->queue[4]);
    #endif
  }
}
    800028c2:	60a6                	ld	ra,72(sp)
    800028c4:	6406                	ld	s0,64(sp)
    800028c6:	74e2                	ld	s1,56(sp)
    800028c8:	7942                	ld	s2,48(sp)
    800028ca:	79a2                	ld	s3,40(sp)
    800028cc:	7a02                	ld	s4,32(sp)
    800028ce:	6ae2                	ld	s5,24(sp)
    800028d0:	6b42                	ld	s6,16(sp)
    800028d2:	6ba2                	ld	s7,8(sp)
    800028d4:	6161                	addi	sp,sp,80
    800028d6:	8082                	ret

00000000800028d8 <trace>:

// enabling tracing for the current process
void trace(int trace_mask)
{
    800028d8:	1101                	addi	sp,sp,-32
    800028da:	ec06                	sd	ra,24(sp)
    800028dc:	e822                	sd	s0,16(sp)
    800028de:	e426                	sd	s1,8(sp)
    800028e0:	1000                	addi	s0,sp,32
    800028e2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	1f2080e7          	jalr	498(ra) # 80001ad6 <myproc>
  p->trace_mask = trace_mask;
    800028ec:	16952423          	sw	s1,360(a0)
}
    800028f0:	60e2                	ld	ra,24(sp)
    800028f2:	6442                	ld	s0,16(sp)
    800028f4:	64a2                	ld	s1,8(sp)
    800028f6:	6105                	addi	sp,sp,32
    800028f8:	8082                	ret

00000000800028fa <set_priority>:

// Change the priority of the given process with pid to new_priority
int set_priority(int new_priority, int pid)
{
    800028fa:	7179                	addi	sp,sp,-48
    800028fc:	f406                	sd	ra,40(sp)
    800028fe:	f022                	sd	s0,32(sp)
    80002900:	ec26                	sd	s1,24(sp)
    80002902:	e84a                	sd	s2,16(sp)
    80002904:	e44e                	sd	s3,8(sp)
    80002906:	e052                	sd	s4,0(sp)
    80002908:	1800                	addi	s0,sp,48
    8000290a:	8a2a                	mv	s4,a0
    8000290c:	892e                	mv	s2,a1
  struct proc *p;
  int old_priority = 0;
  for (p = proc; p < &proc[NPROC]; p++)
    8000290e:	00010497          	auipc	s1,0x10
    80002912:	83a48493          	addi	s1,s1,-1990 # 80012148 <proc>
    80002916:	00016997          	auipc	s3,0x16
    8000291a:	63298993          	addi	s3,s3,1586 # 80018f48 <tickslock>
  {
    acquire(&p->lock);
    8000291e:	8526                	mv	a0,s1
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	2c4080e7          	jalr	708(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002928:	589c                	lw	a5,48(s1)
    8000292a:	03278163          	beq	a5,s2,8000294c <set_priority+0x52>
      p->new_proc = 1;
      release(&p->lock);
      yield();
      return old_priority;
    }
    release(&p->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	368080e7          	jalr	872(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002938:	1b848493          	addi	s1,s1,440
    8000293c:	ff3491e3          	bne	s1,s3,8000291e <set_priority+0x24>
  }
  yield();
    80002940:	00000097          	auipc	ra,0x0
    80002944:	906080e7          	jalr	-1786(ra) # 80002246 <yield>
  return old_priority;
    80002948:	4901                	li	s2,0
    8000294a:	a00d                	j	8000296c <set_priority+0x72>
      old_priority = p->static_priority;
    8000294c:	1784a903          	lw	s2,376(s1)
      p->static_priority = new_priority;
    80002950:	1744ac23          	sw	s4,376(s1)
      p->new_proc = 1;
    80002954:	4785                	li	a5,1
    80002956:	18f4a623          	sw	a5,396(s1)
      release(&p->lock);
    8000295a:	8526                	mv	a0,s1
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	33c080e7          	jalr	828(ra) # 80000c98 <release>
      yield();
    80002964:	00000097          	auipc	ra,0x0
    80002968:	8e2080e7          	jalr	-1822(ra) # 80002246 <yield>
}
    8000296c:	854a                	mv	a0,s2
    8000296e:	70a2                	ld	ra,40(sp)
    80002970:	7402                	ld	s0,32(sp)
    80002972:	64e2                	ld	s1,24(sp)
    80002974:	6942                	ld	s2,16(sp)
    80002976:	69a2                	ld	s3,8(sp)
    80002978:	6a02                	ld	s4,0(sp)
    8000297a:	6145                	addi	sp,sp,48
    8000297c:	8082                	ret

000000008000297e <swtch>:
    8000297e:	00153023          	sd	ra,0(a0)
    80002982:	00253423          	sd	sp,8(a0)
    80002986:	e900                	sd	s0,16(a0)
    80002988:	ed04                	sd	s1,24(a0)
    8000298a:	03253023          	sd	s2,32(a0)
    8000298e:	03353423          	sd	s3,40(a0)
    80002992:	03453823          	sd	s4,48(a0)
    80002996:	03553c23          	sd	s5,56(a0)
    8000299a:	05653023          	sd	s6,64(a0)
    8000299e:	05753423          	sd	s7,72(a0)
    800029a2:	05853823          	sd	s8,80(a0)
    800029a6:	05953c23          	sd	s9,88(a0)
    800029aa:	07a53023          	sd	s10,96(a0)
    800029ae:	07b53423          	sd	s11,104(a0)
    800029b2:	0005b083          	ld	ra,0(a1)
    800029b6:	0085b103          	ld	sp,8(a1)
    800029ba:	6980                	ld	s0,16(a1)
    800029bc:	6d84                	ld	s1,24(a1)
    800029be:	0205b903          	ld	s2,32(a1)
    800029c2:	0285b983          	ld	s3,40(a1)
    800029c6:	0305ba03          	ld	s4,48(a1)
    800029ca:	0385ba83          	ld	s5,56(a1)
    800029ce:	0405bb03          	ld	s6,64(a1)
    800029d2:	0485bb83          	ld	s7,72(a1)
    800029d6:	0505bc03          	ld	s8,80(a1)
    800029da:	0585bc83          	ld	s9,88(a1)
    800029de:	0605bd03          	ld	s10,96(a1)
    800029e2:	0685bd83          	ld	s11,104(a1)
    800029e6:	8082                	ret

00000000800029e8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029e8:	1141                	addi	sp,sp,-16
    800029ea:	e406                	sd	ra,8(sp)
    800029ec:	e022                	sd	s0,0(sp)
    800029ee:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029f0:	00006597          	auipc	a1,0x6
    800029f4:	90058593          	addi	a1,a1,-1792 # 800082f0 <states.1807+0x30>
    800029f8:	00016517          	auipc	a0,0x16
    800029fc:	55050513          	addi	a0,a0,1360 # 80018f48 <tickslock>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	154080e7          	jalr	340(ra) # 80000b54 <initlock>
}
    80002a08:	60a2                	ld	ra,8(sp)
    80002a0a:	6402                	ld	s0,0(sp)
    80002a0c:	0141                	addi	sp,sp,16
    80002a0e:	8082                	ret

0000000080002a10 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a10:	1141                	addi	sp,sp,-16
    80002a12:	e422                	sd	s0,8(sp)
    80002a14:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a16:	00003797          	auipc	a5,0x3
    80002a1a:	69a78793          	addi	a5,a5,1690 # 800060b0 <kernelvec>
    80002a1e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a22:	6422                	ld	s0,8(sp)
    80002a24:	0141                	addi	sp,sp,16
    80002a26:	8082                	ret

0000000080002a28 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a28:	1141                	addi	sp,sp,-16
    80002a2a:	e406                	sd	ra,8(sp)
    80002a2c:	e022                	sd	s0,0(sp)
    80002a2e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	0a6080e7          	jalr	166(ra) # 80001ad6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a38:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a3c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a3e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a42:	00004617          	auipc	a2,0x4
    80002a46:	5be60613          	addi	a2,a2,1470 # 80007000 <_trampoline>
    80002a4a:	00004697          	auipc	a3,0x4
    80002a4e:	5b668693          	addi	a3,a3,1462 # 80007000 <_trampoline>
    80002a52:	8e91                	sub	a3,a3,a2
    80002a54:	040007b7          	lui	a5,0x4000
    80002a58:	17fd                	addi	a5,a5,-1
    80002a5a:	07b2                	slli	a5,a5,0xc
    80002a5c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a5e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a62:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a64:	180026f3          	csrr	a3,satp
    80002a68:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a6a:	6d38                	ld	a4,88(a0)
    80002a6c:	6134                	ld	a3,64(a0)
    80002a6e:	6585                	lui	a1,0x1
    80002a70:	96ae                	add	a3,a3,a1
    80002a72:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a74:	6d38                	ld	a4,88(a0)
    80002a76:	00000697          	auipc	a3,0x0
    80002a7a:	14668693          	addi	a3,a3,326 # 80002bbc <usertrap>
    80002a7e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a80:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a82:	8692                	mv	a3,tp
    80002a84:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a86:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a8a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a8e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a92:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a96:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a98:	6f18                	ld	a4,24(a4)
    80002a9a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a9e:	692c                	ld	a1,80(a0)
    80002aa0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002aa2:	00004717          	auipc	a4,0x4
    80002aa6:	5ee70713          	addi	a4,a4,1518 # 80007090 <userret>
    80002aaa:	8f11                	sub	a4,a4,a2
    80002aac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002aae:	577d                	li	a4,-1
    80002ab0:	177e                	slli	a4,a4,0x3f
    80002ab2:	8dd9                	or	a1,a1,a4
    80002ab4:	02000537          	lui	a0,0x2000
    80002ab8:	157d                	addi	a0,a0,-1
    80002aba:	0536                	slli	a0,a0,0xd
    80002abc:	9782                	jalr	a5
}
    80002abe:	60a2                	ld	ra,8(sp)
    80002ac0:	6402                	ld	s0,0(sp)
    80002ac2:	0141                	addi	sp,sp,16
    80002ac4:	8082                	ret

0000000080002ac6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	e04a                	sd	s2,0(sp)
    80002ad0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ad2:	00016917          	auipc	s2,0x16
    80002ad6:	47690913          	addi	s2,s2,1142 # 80018f48 <tickslock>
    80002ada:	854a                	mv	a0,s2
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
  ticks++;
    80002ae4:	00006497          	auipc	s1,0x6
    80002ae8:	54c48493          	addi	s1,s1,1356 # 80009030 <ticks>
    80002aec:	409c                	lw	a5,0(s1)
    80002aee:	2785                	addiw	a5,a5,1
    80002af0:	c09c                	sw	a5,0(s1)
  update_time();
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	542080e7          	jalr	1346(ra) # 80002034 <update_time>
  wakeup(&ticks);
    80002afa:	8526                	mv	a0,s1
    80002afc:	00000097          	auipc	ra,0x0
    80002b00:	a5e080e7          	jalr	-1442(ra) # 8000255a <wakeup>
  release(&tickslock);
    80002b04:	854a                	mv	a0,s2
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	192080e7          	jalr	402(ra) # 80000c98 <release>
}
    80002b0e:	60e2                	ld	ra,24(sp)
    80002b10:	6442                	ld	s0,16(sp)
    80002b12:	64a2                	ld	s1,8(sp)
    80002b14:	6902                	ld	s2,0(sp)
    80002b16:	6105                	addi	sp,sp,32
    80002b18:	8082                	ret

0000000080002b1a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b24:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b28:	00074d63          	bltz	a4,80002b42 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b2c:	57fd                	li	a5,-1
    80002b2e:	17fe                	slli	a5,a5,0x3f
    80002b30:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b32:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b34:	06f70363          	beq	a4,a5,80002b9a <devintr+0x80>
  }
}
    80002b38:	60e2                	ld	ra,24(sp)
    80002b3a:	6442                	ld	s0,16(sp)
    80002b3c:	64a2                	ld	s1,8(sp)
    80002b3e:	6105                	addi	sp,sp,32
    80002b40:	8082                	ret
     (scause & 0xff) == 9){
    80002b42:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b46:	46a5                	li	a3,9
    80002b48:	fed792e3          	bne	a5,a3,80002b2c <devintr+0x12>
    int irq = plic_claim();
    80002b4c:	00003097          	auipc	ra,0x3
    80002b50:	66c080e7          	jalr	1644(ra) # 800061b8 <plic_claim>
    80002b54:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b56:	47a9                	li	a5,10
    80002b58:	02f50763          	beq	a0,a5,80002b86 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b5c:	4785                	li	a5,1
    80002b5e:	02f50963          	beq	a0,a5,80002b90 <devintr+0x76>
    return 1;
    80002b62:	4505                	li	a0,1
    } else if(irq){
    80002b64:	d8f1                	beqz	s1,80002b38 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b66:	85a6                	mv	a1,s1
    80002b68:	00005517          	auipc	a0,0x5
    80002b6c:	79050513          	addi	a0,a0,1936 # 800082f8 <states.1807+0x38>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	a18080e7          	jalr	-1512(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b78:	8526                	mv	a0,s1
    80002b7a:	00003097          	auipc	ra,0x3
    80002b7e:	662080e7          	jalr	1634(ra) # 800061dc <plic_complete>
    return 1;
    80002b82:	4505                	li	a0,1
    80002b84:	bf55                	j	80002b38 <devintr+0x1e>
      uartintr();
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	e22080e7          	jalr	-478(ra) # 800009a8 <uartintr>
    80002b8e:	b7ed                	j	80002b78 <devintr+0x5e>
      virtio_disk_intr();
    80002b90:	00004097          	auipc	ra,0x4
    80002b94:	b2c080e7          	jalr	-1236(ra) # 800066bc <virtio_disk_intr>
    80002b98:	b7c5                	j	80002b78 <devintr+0x5e>
    if(cpuid() == 0){
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	f10080e7          	jalr	-240(ra) # 80001aaa <cpuid>
    80002ba2:	c901                	beqz	a0,80002bb2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ba4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ba8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002baa:	14479073          	csrw	sip,a5
    return 2;
    80002bae:	4509                	li	a0,2
    80002bb0:	b761                	j	80002b38 <devintr+0x1e>
      clockintr();
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	f14080e7          	jalr	-236(ra) # 80002ac6 <clockintr>
    80002bba:	b7ed                	j	80002ba4 <devintr+0x8a>

0000000080002bbc <usertrap>:
{
    80002bbc:	1101                	addi	sp,sp,-32
    80002bbe:	ec06                	sd	ra,24(sp)
    80002bc0:	e822                	sd	s0,16(sp)
    80002bc2:	e426                	sd	s1,8(sp)
    80002bc4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bca:	1007f793          	andi	a5,a5,256
    80002bce:	e3a5                	bnez	a5,80002c2e <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bd0:	00003797          	auipc	a5,0x3
    80002bd4:	4e078793          	addi	a5,a5,1248 # 800060b0 <kernelvec>
    80002bd8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	efa080e7          	jalr	-262(ra) # 80001ad6 <myproc>
    80002be4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002be6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be8:	14102773          	csrr	a4,sepc
    80002bec:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bee:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bf2:	47a1                	li	a5,8
    80002bf4:	04f71b63          	bne	a4,a5,80002c4a <usertrap+0x8e>
    if(p->killed)
    80002bf8:	551c                	lw	a5,40(a0)
    80002bfa:	e3b1                	bnez	a5,80002c3e <usertrap+0x82>
    p->trapframe->epc += 4;
    80002bfc:	6cb8                	ld	a4,88(s1)
    80002bfe:	6f1c                	ld	a5,24(a4)
    80002c00:	0791                	addi	a5,a5,4
    80002c02:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0c:	10079073          	csrw	sstatus,a5
    syscall();
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	29a080e7          	jalr	666(ra) # 80002eaa <syscall>
  if(p->killed)
    80002c18:	549c                	lw	a5,40(s1)
    80002c1a:	e7b5                	bnez	a5,80002c86 <usertrap+0xca>
  usertrapret();
    80002c1c:	00000097          	auipc	ra,0x0
    80002c20:	e0c080e7          	jalr	-500(ra) # 80002a28 <usertrapret>
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret
    panic("usertrap: not from user mode");
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	6ea50513          	addi	a0,a0,1770 # 80008318 <states.1807+0x58>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	908080e7          	jalr	-1784(ra) # 8000053e <panic>
      exit(-1);
    80002c3e:	557d                	li	a0,-1
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	9ea080e7          	jalr	-1558(ra) # 8000262a <exit>
    80002c48:	bf55                	j	80002bfc <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002c4a:	00000097          	auipc	ra,0x0
    80002c4e:	ed0080e7          	jalr	-304(ra) # 80002b1a <devintr>
    80002c52:	f179                	bnez	a0,80002c18 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c58:	5890                	lw	a2,48(s1)
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	6de50513          	addi	a0,a0,1758 # 80008338 <states.1807+0x78>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	926080e7          	jalr	-1754(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	6f650513          	addi	a0,a0,1782 # 80008368 <states.1807+0xa8>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	90e080e7          	jalr	-1778(ra) # 80000588 <printf>
    p->killed = 1;
    80002c82:	4785                	li	a5,1
    80002c84:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c86:	557d                	li	a0,-1
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	9a2080e7          	jalr	-1630(ra) # 8000262a <exit>
    80002c90:	b771                	j	80002c1c <usertrap+0x60>

0000000080002c92 <kerneltrap>:
{
    80002c92:	7179                	addi	sp,sp,-48
    80002c94:	f406                	sd	ra,40(sp)
    80002c96:	f022                	sd	s0,32(sp)
    80002c98:	ec26                	sd	s1,24(sp)
    80002c9a:	e84a                	sd	s2,16(sp)
    80002c9c:	e44e                	sd	s3,8(sp)
    80002c9e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cac:	1004f793          	andi	a5,s1,256
    80002cb0:	c78d                	beqz	a5,80002cda <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cb6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cb8:	eb8d                	bnez	a5,80002cea <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	e60080e7          	jalr	-416(ra) # 80002b1a <devintr>
    80002cc2:	cd05                	beqz	a0,80002cfa <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cc4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc8:	10049073          	csrw	sstatus,s1
}
    80002ccc:	70a2                	ld	ra,40(sp)
    80002cce:	7402                	ld	s0,32(sp)
    80002cd0:	64e2                	ld	s1,24(sp)
    80002cd2:	6942                	ld	s2,16(sp)
    80002cd4:	69a2                	ld	s3,8(sp)
    80002cd6:	6145                	addi	sp,sp,48
    80002cd8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cda:	00005517          	auipc	a0,0x5
    80002cde:	6ae50513          	addi	a0,a0,1710 # 80008388 <states.1807+0xc8>
    80002ce2:	ffffe097          	auipc	ra,0xffffe
    80002ce6:	85c080e7          	jalr	-1956(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	6c650513          	addi	a0,a0,1734 # 800083b0 <states.1807+0xf0>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002cfa:	85ce                	mv	a1,s3
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	6d450513          	addi	a0,a0,1748 # 800083d0 <states.1807+0x110>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	884080e7          	jalr	-1916(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d10:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	6cc50513          	addi	a0,a0,1740 # 800083e0 <states.1807+0x120>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	86c080e7          	jalr	-1940(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d24:	00005517          	auipc	a0,0x5
    80002d28:	6d450513          	addi	a0,a0,1748 # 800083f8 <states.1807+0x138>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	812080e7          	jalr	-2030(ra) # 8000053e <panic>

0000000080002d34 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d34:	1101                	addi	sp,sp,-32
    80002d36:	ec06                	sd	ra,24(sp)
    80002d38:	e822                	sd	s0,16(sp)
    80002d3a:	e426                	sd	s1,8(sp)
    80002d3c:	1000                	addi	s0,sp,32
    80002d3e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	d96080e7          	jalr	-618(ra) # 80001ad6 <myproc>
  switch (n) {
    80002d48:	4795                	li	a5,5
    80002d4a:	0497e163          	bltu	a5,s1,80002d8c <argraw+0x58>
    80002d4e:	048a                	slli	s1,s1,0x2
    80002d50:	00005717          	auipc	a4,0x5
    80002d54:	7d070713          	addi	a4,a4,2000 # 80008520 <states.1807+0x260>
    80002d58:	94ba                	add	s1,s1,a4
    80002d5a:	409c                	lw	a5,0(s1)
    80002d5c:	97ba                	add	a5,a5,a4
    80002d5e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d60:	6d3c                	ld	a5,88(a0)
    80002d62:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	64a2                	ld	s1,8(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret
    return p->trapframe->a1;
    80002d6e:	6d3c                	ld	a5,88(a0)
    80002d70:	7fa8                	ld	a0,120(a5)
    80002d72:	bfcd                	j	80002d64 <argraw+0x30>
    return p->trapframe->a2;
    80002d74:	6d3c                	ld	a5,88(a0)
    80002d76:	63c8                	ld	a0,128(a5)
    80002d78:	b7f5                	j	80002d64 <argraw+0x30>
    return p->trapframe->a3;
    80002d7a:	6d3c                	ld	a5,88(a0)
    80002d7c:	67c8                	ld	a0,136(a5)
    80002d7e:	b7dd                	j	80002d64 <argraw+0x30>
    return p->trapframe->a4;
    80002d80:	6d3c                	ld	a5,88(a0)
    80002d82:	6bc8                	ld	a0,144(a5)
    80002d84:	b7c5                	j	80002d64 <argraw+0x30>
    return p->trapframe->a5;
    80002d86:	6d3c                	ld	a5,88(a0)
    80002d88:	6fc8                	ld	a0,152(a5)
    80002d8a:	bfe9                	j	80002d64 <argraw+0x30>
  panic("argraw");
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	67c50513          	addi	a0,a0,1660 # 80008408 <states.1807+0x148>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7aa080e7          	jalr	1962(ra) # 8000053e <panic>

0000000080002d9c <fetchaddr>:
{
    80002d9c:	1101                	addi	sp,sp,-32
    80002d9e:	ec06                	sd	ra,24(sp)
    80002da0:	e822                	sd	s0,16(sp)
    80002da2:	e426                	sd	s1,8(sp)
    80002da4:	e04a                	sd	s2,0(sp)
    80002da6:	1000                	addi	s0,sp,32
    80002da8:	84aa                	mv	s1,a0
    80002daa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	d2a080e7          	jalr	-726(ra) # 80001ad6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002db4:	653c                	ld	a5,72(a0)
    80002db6:	02f4f863          	bgeu	s1,a5,80002de6 <fetchaddr+0x4a>
    80002dba:	00848713          	addi	a4,s1,8
    80002dbe:	02e7e663          	bltu	a5,a4,80002dea <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dc2:	46a1                	li	a3,8
    80002dc4:	8626                	mv	a2,s1
    80002dc6:	85ca                	mv	a1,s2
    80002dc8:	6928                	ld	a0,80(a0)
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	93c080e7          	jalr	-1732(ra) # 80001706 <copyin>
    80002dd2:	00a03533          	snez	a0,a0
    80002dd6:	40a00533          	neg	a0,a0
}
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6902                	ld	s2,0(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret
    return -1;
    80002de6:	557d                	li	a0,-1
    80002de8:	bfcd                	j	80002dda <fetchaddr+0x3e>
    80002dea:	557d                	li	a0,-1
    80002dec:	b7fd                	j	80002dda <fetchaddr+0x3e>

0000000080002dee <fetchstr>:
{
    80002dee:	7179                	addi	sp,sp,-48
    80002df0:	f406                	sd	ra,40(sp)
    80002df2:	f022                	sd	s0,32(sp)
    80002df4:	ec26                	sd	s1,24(sp)
    80002df6:	e84a                	sd	s2,16(sp)
    80002df8:	e44e                	sd	s3,8(sp)
    80002dfa:	1800                	addi	s0,sp,48
    80002dfc:	892a                	mv	s2,a0
    80002dfe:	84ae                	mv	s1,a1
    80002e00:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	cd4080e7          	jalr	-812(ra) # 80001ad6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e0a:	86ce                	mv	a3,s3
    80002e0c:	864a                	mv	a2,s2
    80002e0e:	85a6                	mv	a1,s1
    80002e10:	6928                	ld	a0,80(a0)
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	980080e7          	jalr	-1664(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002e1a:	00054763          	bltz	a0,80002e28 <fetchstr+0x3a>
  return strlen(buf);
    80002e1e:	8526                	mv	a0,s1
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	044080e7          	jalr	68(ra) # 80000e64 <strlen>
}
    80002e28:	70a2                	ld	ra,40(sp)
    80002e2a:	7402                	ld	s0,32(sp)
    80002e2c:	64e2                	ld	s1,24(sp)
    80002e2e:	6942                	ld	s2,16(sp)
    80002e30:	69a2                	ld	s3,8(sp)
    80002e32:	6145                	addi	sp,sp,48
    80002e34:	8082                	ret

0000000080002e36 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	e426                	sd	s1,8(sp)
    80002e3e:	1000                	addi	s0,sp,32
    80002e40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	ef2080e7          	jalr	-270(ra) # 80002d34 <argraw>
    80002e4a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e4c:	4501                	li	a0,0
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	64a2                	ld	s1,8(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	e426                	sd	s1,8(sp)
    80002e60:	1000                	addi	s0,sp,32
    80002e62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	ed0080e7          	jalr	-304(ra) # 80002d34 <argraw>
    80002e6c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e6e:	4501                	li	a0,0
    80002e70:	60e2                	ld	ra,24(sp)
    80002e72:	6442                	ld	s0,16(sp)
    80002e74:	64a2                	ld	s1,8(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	e04a                	sd	s2,0(sp)
    80002e84:	1000                	addi	s0,sp,32
    80002e86:	84ae                	mv	s1,a1
    80002e88:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	eaa080e7          	jalr	-342(ra) # 80002d34 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e92:	864a                	mv	a2,s2
    80002e94:	85a6                	mv	a1,s1
    80002e96:	00000097          	auipc	ra,0x0
    80002e9a:	f58080e7          	jalr	-168(ra) # 80002dee <fetchstr>
}
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	64a2                	ld	s1,8(sp)
    80002ea4:	6902                	ld	s2,0(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <syscall>:
struct syscall_arg_info syscall_arg_infos[] = {{ 0, "fork" },{ 1, "exit" },{ 1, "wait" },{ 0, "pipe" },{ 3, "read" },{ 2, "kill" },{ 2, "exec" },{ 1, "fstat" },{ 1, "chdir" },{ 1, "dup" },{ 0, "getpid" },{ 1, "sbrk" },{ 1, "sleep" },{ 0, "uptime" },{ 2, "open" },{ 3, "write" },{ 3, "mknod" },{ 1, "unlink" },{ 2, "link" },{ 1, "mkdir" },{ 1, "close" },{ 1, "trace" },{ 3, "waitx" }, {2, "set_priority"},};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002eaa:	711d                	addi	sp,sp,-96
    80002eac:	ec86                	sd	ra,88(sp)
    80002eae:	e8a2                	sd	s0,80(sp)
    80002eb0:	e4a6                	sd	s1,72(sp)
    80002eb2:	e0ca                	sd	s2,64(sp)
    80002eb4:	fc4e                	sd	s3,56(sp)
    80002eb6:	f852                	sd	s4,48(sp)
    80002eb8:	f456                	sd	s5,40(sp)
    80002eba:	f05a                	sd	s6,32(sp)
    80002ebc:	ec5e                	sd	s7,24(sp)
    80002ebe:	e862                	sd	s8,16(sp)
    80002ec0:	e466                	sd	s9,8(sp)
    80002ec2:	e06a                	sd	s10,0(sp)
    80002ec4:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	c10080e7          	jalr	-1008(ra) # 80001ad6 <myproc>
    80002ece:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002ed0:	6d24                	ld	s1,88(a0)
    80002ed2:	74dc                	ld	a5,168(s1)
    80002ed4:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ed8:	37fd                	addiw	a5,a5,-1
    80002eda:	475d                	li	a4,23
    80002edc:	06f76f63          	bltu	a4,a5,80002f5a <syscall+0xb0>
    80002ee0:	003b1713          	slli	a4,s6,0x3
    80002ee4:	00005797          	auipc	a5,0x5
    80002ee8:	65478793          	addi	a5,a5,1620 # 80008538 <syscalls>
    80002eec:	97ba                	add	a5,a5,a4
    80002eee:	0007bd03          	ld	s10,0(a5)
    80002ef2:	060d0463          	beqz	s10,80002f5a <syscall+0xb0>
    80002ef6:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002ef8:	fffb0c1b          	addiw	s8,s6,-1
    80002efc:	004c1713          	slli	a4,s8,0x4
    80002f00:	00006797          	auipc	a5,0x6
    80002f04:	a5878793          	addi	a5,a5,-1448 # 80008958 <syscall_arg_infos>
    80002f08:	97ba                	add	a5,a5,a4
    80002f0a:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002f0e:	00299793          	slli	a5,s3,0x2
    80002f12:	07bd                	addi	a5,a5,15
    80002f14:	9bc1                	andi	a5,a5,-16
    80002f16:	40f10133          	sub	sp,sp,a5
    80002f1a:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002f1c:	0f305363          	blez	s3,80003002 <syscall+0x158>
    80002f20:	8ade                	mv	s5,s7
    80002f22:	895e                	mv	s2,s7
    80002f24:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002f26:	8526                	mv	a0,s1
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	e0c080e7          	jalr	-500(ra) # 80002d34 <argraw>
    80002f30:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002f34:	2485                	addiw	s1,s1,1
    80002f36:	0911                	addi	s2,s2,4
    80002f38:	fe9997e3          	bne	s3,s1,80002f26 <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002f3c:	058a3483          	ld	s1,88(s4)
    80002f40:	9d02                	jalr	s10
    80002f42:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002f44:	4785                	li	a5,1
    80002f46:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002f4a:	168a2b03          	lw	s6,360(s4)
    80002f4e:	0167f7b3          	and	a5,a5,s6
    80002f52:	2781                	sext.w	a5,a5
    80002f54:	e7a1                	bnez	a5,80002f9c <syscall+0xf2>
    80002f56:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f58:	a015                	j	80002f7c <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f5a:	86da                	mv	a3,s6
    80002f5c:	158a0613          	addi	a2,s4,344
    80002f60:	030a2583          	lw	a1,48(s4)
    80002f64:	00005517          	auipc	a0,0x5
    80002f68:	4c450513          	addi	a0,a0,1220 # 80008428 <states.1807+0x168>
    80002f6c:	ffffd097          	auipc	ra,0xffffd
    80002f70:	61c080e7          	jalr	1564(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f74:	058a3783          	ld	a5,88(s4)
    80002f78:	577d                	li	a4,-1
    80002f7a:	fbb8                	sd	a4,112(a5)
  }
}
    80002f7c:	fa040113          	addi	sp,s0,-96
    80002f80:	60e6                	ld	ra,88(sp)
    80002f82:	6446                	ld	s0,80(sp)
    80002f84:	64a6                	ld	s1,72(sp)
    80002f86:	6906                	ld	s2,64(sp)
    80002f88:	79e2                	ld	s3,56(sp)
    80002f8a:	7a42                	ld	s4,48(sp)
    80002f8c:	7aa2                	ld	s5,40(sp)
    80002f8e:	7b02                	ld	s6,32(sp)
    80002f90:	6be2                	ld	s7,24(sp)
    80002f92:	6c42                	ld	s8,16(sp)
    80002f94:	6ca2                	ld	s9,8(sp)
    80002f96:	6d02                	ld	s10,0(sp)
    80002f98:	6125                	addi	sp,sp,96
    80002f9a:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002f9c:	0c12                	slli	s8,s8,0x4
    80002f9e:	00006797          	auipc	a5,0x6
    80002fa2:	9ba78793          	addi	a5,a5,-1606 # 80008958 <syscall_arg_infos>
    80002fa6:	9c3e                	add	s8,s8,a5
    80002fa8:	008c3603          	ld	a2,8(s8)
    80002fac:	030a2583          	lw	a1,48(s4)
    80002fb0:	00005517          	auipc	a0,0x5
    80002fb4:	49850513          	addi	a0,a0,1176 # 80008448 <states.1807+0x188>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	5d0080e7          	jalr	1488(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002fc0:	fff9879b          	addiw	a5,s3,-1
    80002fc4:	1782                	slli	a5,a5,0x20
    80002fc6:	9381                	srli	a5,a5,0x20
    80002fc8:	0785                	addi	a5,a5,1
    80002fca:	078a                	slli	a5,a5,0x2
    80002fcc:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80002fce:	00005497          	auipc	s1,0x5
    80002fd2:	44248493          	addi	s1,s1,1090 # 80008410 <states.1807+0x150>
    80002fd6:	000aa583          	lw	a1,0(s5)
    80002fda:	8526                	mv	a0,s1
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5ac080e7          	jalr	1452(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002fe4:	0a91                	addi	s5,s5,4
    80002fe6:	ff7a98e3          	bne	s5,s7,80002fd6 <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    80002fea:	058a3783          	ld	a5,88(s4)
    80002fee:	7bac                	ld	a1,112(a5)
    80002ff0:	00005517          	auipc	a0,0x5
    80002ff4:	42850513          	addi	a0,a0,1064 # 80008418 <states.1807+0x158>
    80002ff8:	ffffd097          	auipc	ra,0xffffd
    80002ffc:	590080e7          	jalr	1424(ra) # 80000588 <printf>
    80003000:	bf99                	j	80002f56 <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80003002:	9d02                	jalr	s10
    80003004:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80003006:	4785                	li	a5,1
    80003008:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    8000300c:	168a2703          	lw	a4,360(s4)
    80003010:	8ff9                	and	a5,a5,a4
    80003012:	2781                	sext.w	a5,a5
    80003014:	d3a9                	beqz	a5,80002f56 <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80003016:	0c12                	slli	s8,s8,0x4
    80003018:	00006797          	auipc	a5,0x6
    8000301c:	94078793          	addi	a5,a5,-1728 # 80008958 <syscall_arg_infos>
    80003020:	97e2                	add	a5,a5,s8
    80003022:	6790                	ld	a2,8(a5)
    80003024:	030a2583          	lw	a1,48(s4)
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	42050513          	addi	a0,a0,1056 # 80008448 <states.1807+0x188>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	558080e7          	jalr	1368(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80003038:	bf4d                	j	80002fea <syscall+0x140>

000000008000303a <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    8000303a:	1101                	addi	sp,sp,-32
    8000303c:	ec06                	sd	ra,24(sp)
    8000303e:	e822                	sd	s0,16(sp)
    80003040:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003042:	fec40593          	addi	a1,s0,-20
    80003046:	4501                	li	a0,0
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	dee080e7          	jalr	-530(ra) # 80002e36 <argint>
    return -1;
    80003050:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003052:	00054963          	bltz	a0,80003064 <sys_exit+0x2a>
  exit(n);
    80003056:	fec42503          	lw	a0,-20(s0)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	5d0080e7          	jalr	1488(ra) # 8000262a <exit>
  return 0;  // not reached
    80003062:	4781                	li	a5,0
}
    80003064:	853e                	mv	a0,a5
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	6105                	addi	sp,sp,32
    8000306c:	8082                	ret

000000008000306e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000306e:	1141                	addi	sp,sp,-16
    80003070:	e406                	sd	ra,8(sp)
    80003072:	e022                	sd	s0,0(sp)
    80003074:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	a60080e7          	jalr	-1440(ra) # 80001ad6 <myproc>
}
    8000307e:	5908                	lw	a0,48(a0)
    80003080:	60a2                	ld	ra,8(sp)
    80003082:	6402                	ld	s0,0(sp)
    80003084:	0141                	addi	sp,sp,16
    80003086:	8082                	ret

0000000080003088 <sys_fork>:

uint64
sys_fork(void)
{
    80003088:	1141                	addi	sp,sp,-16
    8000308a:	e406                	sd	ra,8(sp)
    8000308c:	e022                	sd	s0,0(sp)
    8000308e:	0800                	addi	s0,sp,16
  return fork();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	e60080e7          	jalr	-416(ra) # 80001ef0 <fork>
}
    80003098:	60a2                	ld	ra,8(sp)
    8000309a:	6402                	ld	s0,0(sp)
    8000309c:	0141                	addi	sp,sp,16
    8000309e:	8082                	ret

00000000800030a0 <sys_wait>:

uint64
sys_wait(void)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800030a8:	fe840593          	addi	a1,s0,-24
    800030ac:	4501                	li	a0,0
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	daa080e7          	jalr	-598(ra) # 80002e58 <argaddr>
    800030b6:	87aa                	mv	a5,a0
    return -1;
    800030b8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800030ba:	0007c863          	bltz	a5,800030ca <sys_wait+0x2a>
  return wait(p);
    800030be:	fe843503          	ld	a0,-24(s0)
    800030c2:	fffff097          	auipc	ra,0xfffff
    800030c6:	224080e7          	jalr	548(ra) # 800022e6 <wait>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret

00000000800030d2 <sys_waitx>:

uint64
sys_waitx(void)
{
    800030d2:	7139                	addi	sp,sp,-64
    800030d4:	fc06                	sd	ra,56(sp)
    800030d6:	f822                	sd	s0,48(sp)
    800030d8:	f426                	sd	s1,40(sp)
    800030da:	f04a                	sd	s2,32(sp)
    800030dc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    800030de:	fd840593          	addi	a1,s0,-40
    800030e2:	4501                	li	a0,0
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	d74080e7          	jalr	-652(ra) # 80002e58 <argaddr>
    return -1;
    800030ec:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800030ee:	08054063          	bltz	a0,8000316e <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800030f2:	fd040593          	addi	a1,s0,-48
    800030f6:	4505                	li	a0,1
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d60080e7          	jalr	-672(ra) # 80002e58 <argaddr>
    return -1;
    80003100:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003102:	06054663          	bltz	a0,8000316e <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003106:	fc840593          	addi	a1,s0,-56
    8000310a:	4509                	li	a0,2
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	d4c080e7          	jalr	-692(ra) # 80002e58 <argaddr>
    return -1;
    80003114:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80003116:	04054c63          	bltz	a0,8000316e <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    8000311a:	fc040613          	addi	a2,s0,-64
    8000311e:	fc440593          	addi	a1,s0,-60
    80003122:	fd843503          	ld	a0,-40(s0)
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	2e8080e7          	jalr	744(ra) # 8000240e <waitx>
    8000312e:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	9a6080e7          	jalr	-1626(ra) # 80001ad6 <myproc>
    80003138:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000313a:	4691                	li	a3,4
    8000313c:	fc440613          	addi	a2,s0,-60
    80003140:	fd043583          	ld	a1,-48(s0)
    80003144:	6928                	ld	a0,80(a0)
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	534080e7          	jalr	1332(ra) # 8000167a <copyout>
    return -1;
    8000314e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003150:	00054f63          	bltz	a0,8000316e <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003154:	4691                	li	a3,4
    80003156:	fc040613          	addi	a2,s0,-64
    8000315a:	fc843583          	ld	a1,-56(s0)
    8000315e:	68a8                	ld	a0,80(s1)
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	51a080e7          	jalr	1306(ra) # 8000167a <copyout>
    80003168:	00054a63          	bltz	a0,8000317c <sys_waitx+0xaa>
    return -1;
  return ret;
    8000316c:	87ca                	mv	a5,s2
}
    8000316e:	853e                	mv	a0,a5
    80003170:	70e2                	ld	ra,56(sp)
    80003172:	7442                	ld	s0,48(sp)
    80003174:	74a2                	ld	s1,40(sp)
    80003176:	7902                	ld	s2,32(sp)
    80003178:	6121                	addi	sp,sp,64
    8000317a:	8082                	ret
    return -1;
    8000317c:	57fd                	li	a5,-1
    8000317e:	bfc5                	j	8000316e <sys_waitx+0x9c>

0000000080003180 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003180:	7179                	addi	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000318a:	fdc40593          	addi	a1,s0,-36
    8000318e:	4501                	li	a0,0
    80003190:	00000097          	auipc	ra,0x0
    80003194:	ca6080e7          	jalr	-858(ra) # 80002e36 <argint>
    80003198:	87aa                	mv	a5,a0
    return -1;
    8000319a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000319c:	0207c063          	bltz	a5,800031bc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	936080e7          	jalr	-1738(ra) # 80001ad6 <myproc>
    800031a8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800031aa:	fdc42503          	lw	a0,-36(s0)
    800031ae:	fffff097          	auipc	ra,0xfffff
    800031b2:	cce080e7          	jalr	-818(ra) # 80001e7c <growproc>
    800031b6:	00054863          	bltz	a0,800031c6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800031ba:	8526                	mv	a0,s1
}
    800031bc:	70a2                	ld	ra,40(sp)
    800031be:	7402                	ld	s0,32(sp)
    800031c0:	64e2                	ld	s1,24(sp)
    800031c2:	6145                	addi	sp,sp,48
    800031c4:	8082                	ret
    return -1;
    800031c6:	557d                	li	a0,-1
    800031c8:	bfd5                	j	800031bc <sys_sbrk+0x3c>

00000000800031ca <sys_sleep>:

uint64
sys_sleep(void)
{
    800031ca:	7139                	addi	sp,sp,-64
    800031cc:	fc06                	sd	ra,56(sp)
    800031ce:	f822                	sd	s0,48(sp)
    800031d0:	f426                	sd	s1,40(sp)
    800031d2:	f04a                	sd	s2,32(sp)
    800031d4:	ec4e                	sd	s3,24(sp)
    800031d6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031d8:	fcc40593          	addi	a1,s0,-52
    800031dc:	4501                	li	a0,0
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	c58080e7          	jalr	-936(ra) # 80002e36 <argint>
    return -1;
    800031e6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031e8:	06054563          	bltz	a0,80003252 <sys_sleep+0x88>
  acquire(&tickslock);
    800031ec:	00016517          	auipc	a0,0x16
    800031f0:	d5c50513          	addi	a0,a0,-676 # 80018f48 <tickslock>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	9f0080e7          	jalr	-1552(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031fc:	00006917          	auipc	s2,0x6
    80003200:	e3492903          	lw	s2,-460(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003204:	fcc42783          	lw	a5,-52(s0)
    80003208:	cf85                	beqz	a5,80003240 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000320a:	00016997          	auipc	s3,0x16
    8000320e:	d3e98993          	addi	s3,s3,-706 # 80018f48 <tickslock>
    80003212:	00006497          	auipc	s1,0x6
    80003216:	e1e48493          	addi	s1,s1,-482 # 80009030 <ticks>
    if(myproc()->killed){
    8000321a:	fffff097          	auipc	ra,0xfffff
    8000321e:	8bc080e7          	jalr	-1860(ra) # 80001ad6 <myproc>
    80003222:	551c                	lw	a5,40(a0)
    80003224:	ef9d                	bnez	a5,80003262 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003226:	85ce                	mv	a1,s3
    80003228:	8526                	mv	a0,s1
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	058080e7          	jalr	88(ra) # 80002282 <sleep>
  while(ticks - ticks0 < n){
    80003232:	409c                	lw	a5,0(s1)
    80003234:	412787bb          	subw	a5,a5,s2
    80003238:	fcc42703          	lw	a4,-52(s0)
    8000323c:	fce7efe3          	bltu	a5,a4,8000321a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003240:	00016517          	auipc	a0,0x16
    80003244:	d0850513          	addi	a0,a0,-760 # 80018f48 <tickslock>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a50080e7          	jalr	-1456(ra) # 80000c98 <release>
  return 0;
    80003250:	4781                	li	a5,0
}
    80003252:	853e                	mv	a0,a5
    80003254:	70e2                	ld	ra,56(sp)
    80003256:	7442                	ld	s0,48(sp)
    80003258:	74a2                	ld	s1,40(sp)
    8000325a:	7902                	ld	s2,32(sp)
    8000325c:	69e2                	ld	s3,24(sp)
    8000325e:	6121                	addi	sp,sp,64
    80003260:	8082                	ret
      release(&tickslock);
    80003262:	00016517          	auipc	a0,0x16
    80003266:	ce650513          	addi	a0,a0,-794 # 80018f48 <tickslock>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
      return -1;
    80003272:	57fd                	li	a5,-1
    80003274:	bff9                	j	80003252 <sys_sleep+0x88>

0000000080003276 <sys_kill>:

uint64
sys_kill(void)
{
    80003276:	1101                	addi	sp,sp,-32
    80003278:	ec06                	sd	ra,24(sp)
    8000327a:	e822                	sd	s0,16(sp)
    8000327c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000327e:	fec40593          	addi	a1,s0,-20
    80003282:	4501                	li	a0,0
    80003284:	00000097          	auipc	ra,0x0
    80003288:	bb2080e7          	jalr	-1102(ra) # 80002e36 <argint>
    8000328c:	87aa                	mv	a5,a0
    return -1;
    8000328e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003290:	0007c863          	bltz	a5,800032a0 <sys_kill+0x2a>
  return kill(pid);
    80003294:	fec42503          	lw	a0,-20(s0)
    80003298:	fffff097          	auipc	ra,0xfffff
    8000329c:	474080e7          	jalr	1140(ra) # 8000270c <kill>
}
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret

00000000800032a8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032b2:	00016517          	auipc	a0,0x16
    800032b6:	c9650513          	addi	a0,a0,-874 # 80018f48 <tickslock>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	92a080e7          	jalr	-1750(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032c2:	00006497          	auipc	s1,0x6
    800032c6:	d6e4a483          	lw	s1,-658(s1) # 80009030 <ticks>
  release(&tickslock);
    800032ca:	00016517          	auipc	a0,0x16
    800032ce:	c7e50513          	addi	a0,a0,-898 # 80018f48 <tickslock>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	9c6080e7          	jalr	-1594(ra) # 80000c98 <release>
  return xticks;
}
    800032da:	02049513          	slli	a0,s1,0x20
    800032de:	9101                	srli	a0,a0,0x20
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    800032f2:	fec40593          	addi	a1,s0,-20
    800032f6:	4501                	li	a0,0
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	b3e080e7          	jalr	-1218(ra) # 80002e36 <argint>
  trace(n);
    80003300:	fec42503          	lw	a0,-20(s0)
    80003304:	fffff097          	auipc	ra,0xfffff
    80003308:	5d4080e7          	jalr	1492(ra) # 800028d8 <trace>
  return 0; // if the syscall is successful, return 0
}
    8000330c:	4501                	li	a0,0
    8000330e:	60e2                	ld	ra,24(sp)
    80003310:	6442                	ld	s0,16(sp)
    80003312:	6105                	addi	sp,sp,32
    80003314:	8082                	ret

0000000080003316 <sys_set_priority>:

// to change the static priority of a process with given pid
uint64
sys_set_priority(void)
{
    80003316:	1101                	addi	sp,sp,-32
    80003318:	ec06                	sd	ra,24(sp)
    8000331a:	e822                	sd	s0,16(sp)
    8000331c:	1000                	addi	s0,sp,32
  int pid, new_priority;
  if(argint(0, &new_priority) < 0)
    8000331e:	fe840593          	addi	a1,s0,-24
    80003322:	4501                	li	a0,0
    80003324:	00000097          	auipc	ra,0x0
    80003328:	b12080e7          	jalr	-1262(ra) # 80002e36 <argint>
    return -1;
    8000332c:	57fd                	li	a5,-1
  if(argint(0, &new_priority) < 0)
    8000332e:	02054563          	bltz	a0,80003358 <sys_set_priority+0x42>
  if(argint(1, &pid) < 0)
    80003332:	fec40593          	addi	a1,s0,-20
    80003336:	4505                	li	a0,1
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	afe080e7          	jalr	-1282(ra) # 80002e36 <argint>
    return -1;
    80003340:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    80003342:	00054b63          	bltz	a0,80003358 <sys_set_priority+0x42>
  return set_priority(new_priority, pid);
    80003346:	fec42583          	lw	a1,-20(s0)
    8000334a:	fe842503          	lw	a0,-24(s0)
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	5ac080e7          	jalr	1452(ra) # 800028fa <set_priority>
    80003356:	87aa                	mv	a5,a0
    80003358:	853e                	mv	a0,a5
    8000335a:	60e2                	ld	ra,24(sp)
    8000335c:	6442                	ld	s0,16(sp)
    8000335e:	6105                	addi	sp,sp,32
    80003360:	8082                	ret

0000000080003362 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003362:	7179                	addi	sp,sp,-48
    80003364:	f406                	sd	ra,40(sp)
    80003366:	f022                	sd	s0,32(sp)
    80003368:	ec26                	sd	s1,24(sp)
    8000336a:	e84a                	sd	s2,16(sp)
    8000336c:	e44e                	sd	s3,8(sp)
    8000336e:	e052                	sd	s4,0(sp)
    80003370:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003372:	00005597          	auipc	a1,0x5
    80003376:	28e58593          	addi	a1,a1,654 # 80008600 <syscalls+0xc8>
    8000337a:	00016517          	auipc	a0,0x16
    8000337e:	be650513          	addi	a0,a0,-1050 # 80018f60 <bcache>
    80003382:	ffffd097          	auipc	ra,0xffffd
    80003386:	7d2080e7          	jalr	2002(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000338a:	0001e797          	auipc	a5,0x1e
    8000338e:	bd678793          	addi	a5,a5,-1066 # 80020f60 <bcache+0x8000>
    80003392:	0001e717          	auipc	a4,0x1e
    80003396:	e3670713          	addi	a4,a4,-458 # 800211c8 <bcache+0x8268>
    8000339a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000339e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033a2:	00016497          	auipc	s1,0x16
    800033a6:	bd648493          	addi	s1,s1,-1066 # 80018f78 <bcache+0x18>
    b->next = bcache.head.next;
    800033aa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033ac:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033ae:	00005a17          	auipc	s4,0x5
    800033b2:	25aa0a13          	addi	s4,s4,602 # 80008608 <syscalls+0xd0>
    b->next = bcache.head.next;
    800033b6:	2b893783          	ld	a5,696(s2)
    800033ba:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033bc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033c0:	85d2                	mv	a1,s4
    800033c2:	01048513          	addi	a0,s1,16
    800033c6:	00001097          	auipc	ra,0x1
    800033ca:	4bc080e7          	jalr	1212(ra) # 80004882 <initsleeplock>
    bcache.head.next->prev = b;
    800033ce:	2b893783          	ld	a5,696(s2)
    800033d2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033d4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033d8:	45848493          	addi	s1,s1,1112
    800033dc:	fd349de3          	bne	s1,s3,800033b6 <binit+0x54>
  }
}
    800033e0:	70a2                	ld	ra,40(sp)
    800033e2:	7402                	ld	s0,32(sp)
    800033e4:	64e2                	ld	s1,24(sp)
    800033e6:	6942                	ld	s2,16(sp)
    800033e8:	69a2                	ld	s3,8(sp)
    800033ea:	6a02                	ld	s4,0(sp)
    800033ec:	6145                	addi	sp,sp,48
    800033ee:	8082                	ret

00000000800033f0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033f0:	7179                	addi	sp,sp,-48
    800033f2:	f406                	sd	ra,40(sp)
    800033f4:	f022                	sd	s0,32(sp)
    800033f6:	ec26                	sd	s1,24(sp)
    800033f8:	e84a                	sd	s2,16(sp)
    800033fa:	e44e                	sd	s3,8(sp)
    800033fc:	1800                	addi	s0,sp,48
    800033fe:	89aa                	mv	s3,a0
    80003400:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003402:	00016517          	auipc	a0,0x16
    80003406:	b5e50513          	addi	a0,a0,-1186 # 80018f60 <bcache>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	7da080e7          	jalr	2010(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003412:	0001e497          	auipc	s1,0x1e
    80003416:	e064b483          	ld	s1,-506(s1) # 80021218 <bcache+0x82b8>
    8000341a:	0001e797          	auipc	a5,0x1e
    8000341e:	dae78793          	addi	a5,a5,-594 # 800211c8 <bcache+0x8268>
    80003422:	02f48f63          	beq	s1,a5,80003460 <bread+0x70>
    80003426:	873e                	mv	a4,a5
    80003428:	a021                	j	80003430 <bread+0x40>
    8000342a:	68a4                	ld	s1,80(s1)
    8000342c:	02e48a63          	beq	s1,a4,80003460 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003430:	449c                	lw	a5,8(s1)
    80003432:	ff379ce3          	bne	a5,s3,8000342a <bread+0x3a>
    80003436:	44dc                	lw	a5,12(s1)
    80003438:	ff2799e3          	bne	a5,s2,8000342a <bread+0x3a>
      b->refcnt++;
    8000343c:	40bc                	lw	a5,64(s1)
    8000343e:	2785                	addiw	a5,a5,1
    80003440:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003442:	00016517          	auipc	a0,0x16
    80003446:	b1e50513          	addi	a0,a0,-1250 # 80018f60 <bcache>
    8000344a:	ffffe097          	auipc	ra,0xffffe
    8000344e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003452:	01048513          	addi	a0,s1,16
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	466080e7          	jalr	1126(ra) # 800048bc <acquiresleep>
      return b;
    8000345e:	a8b9                	j	800034bc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003460:	0001e497          	auipc	s1,0x1e
    80003464:	db04b483          	ld	s1,-592(s1) # 80021210 <bcache+0x82b0>
    80003468:	0001e797          	auipc	a5,0x1e
    8000346c:	d6078793          	addi	a5,a5,-672 # 800211c8 <bcache+0x8268>
    80003470:	00f48863          	beq	s1,a5,80003480 <bread+0x90>
    80003474:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003476:	40bc                	lw	a5,64(s1)
    80003478:	cf81                	beqz	a5,80003490 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000347a:	64a4                	ld	s1,72(s1)
    8000347c:	fee49de3          	bne	s1,a4,80003476 <bread+0x86>
  panic("bget: no buffers");
    80003480:	00005517          	auipc	a0,0x5
    80003484:	19050513          	addi	a0,a0,400 # 80008610 <syscalls+0xd8>
    80003488:	ffffd097          	auipc	ra,0xffffd
    8000348c:	0b6080e7          	jalr	182(ra) # 8000053e <panic>
      b->dev = dev;
    80003490:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003494:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003498:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000349c:	4785                	li	a5,1
    8000349e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034a0:	00016517          	auipc	a0,0x16
    800034a4:	ac050513          	addi	a0,a0,-1344 # 80018f60 <bcache>
    800034a8:	ffffd097          	auipc	ra,0xffffd
    800034ac:	7f0080e7          	jalr	2032(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034b0:	01048513          	addi	a0,s1,16
    800034b4:	00001097          	auipc	ra,0x1
    800034b8:	408080e7          	jalr	1032(ra) # 800048bc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034bc:	409c                	lw	a5,0(s1)
    800034be:	cb89                	beqz	a5,800034d0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034c0:	8526                	mv	a0,s1
    800034c2:	70a2                	ld	ra,40(sp)
    800034c4:	7402                	ld	s0,32(sp)
    800034c6:	64e2                	ld	s1,24(sp)
    800034c8:	6942                	ld	s2,16(sp)
    800034ca:	69a2                	ld	s3,8(sp)
    800034cc:	6145                	addi	sp,sp,48
    800034ce:	8082                	ret
    virtio_disk_rw(b, 0);
    800034d0:	4581                	li	a1,0
    800034d2:	8526                	mv	a0,s1
    800034d4:	00003097          	auipc	ra,0x3
    800034d8:	f12080e7          	jalr	-238(ra) # 800063e6 <virtio_disk_rw>
    b->valid = 1;
    800034dc:	4785                	li	a5,1
    800034de:	c09c                	sw	a5,0(s1)
  return b;
    800034e0:	b7c5                	j	800034c0 <bread+0xd0>

00000000800034e2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034e2:	1101                	addi	sp,sp,-32
    800034e4:	ec06                	sd	ra,24(sp)
    800034e6:	e822                	sd	s0,16(sp)
    800034e8:	e426                	sd	s1,8(sp)
    800034ea:	1000                	addi	s0,sp,32
    800034ec:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034ee:	0541                	addi	a0,a0,16
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	466080e7          	jalr	1126(ra) # 80004956 <holdingsleep>
    800034f8:	cd01                	beqz	a0,80003510 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034fa:	4585                	li	a1,1
    800034fc:	8526                	mv	a0,s1
    800034fe:	00003097          	auipc	ra,0x3
    80003502:	ee8080e7          	jalr	-280(ra) # 800063e6 <virtio_disk_rw>
}
    80003506:	60e2                	ld	ra,24(sp)
    80003508:	6442                	ld	s0,16(sp)
    8000350a:	64a2                	ld	s1,8(sp)
    8000350c:	6105                	addi	sp,sp,32
    8000350e:	8082                	ret
    panic("bwrite");
    80003510:	00005517          	auipc	a0,0x5
    80003514:	11850513          	addi	a0,a0,280 # 80008628 <syscalls+0xf0>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	026080e7          	jalr	38(ra) # 8000053e <panic>

0000000080003520 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003520:	1101                	addi	sp,sp,-32
    80003522:	ec06                	sd	ra,24(sp)
    80003524:	e822                	sd	s0,16(sp)
    80003526:	e426                	sd	s1,8(sp)
    80003528:	e04a                	sd	s2,0(sp)
    8000352a:	1000                	addi	s0,sp,32
    8000352c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000352e:	01050913          	addi	s2,a0,16
    80003532:	854a                	mv	a0,s2
    80003534:	00001097          	auipc	ra,0x1
    80003538:	422080e7          	jalr	1058(ra) # 80004956 <holdingsleep>
    8000353c:	c92d                	beqz	a0,800035ae <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000353e:	854a                	mv	a0,s2
    80003540:	00001097          	auipc	ra,0x1
    80003544:	3d2080e7          	jalr	978(ra) # 80004912 <releasesleep>

  acquire(&bcache.lock);
    80003548:	00016517          	auipc	a0,0x16
    8000354c:	a1850513          	addi	a0,a0,-1512 # 80018f60 <bcache>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	694080e7          	jalr	1684(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003558:	40bc                	lw	a5,64(s1)
    8000355a:	37fd                	addiw	a5,a5,-1
    8000355c:	0007871b          	sext.w	a4,a5
    80003560:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003562:	eb05                	bnez	a4,80003592 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003564:	68bc                	ld	a5,80(s1)
    80003566:	64b8                	ld	a4,72(s1)
    80003568:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000356a:	64bc                	ld	a5,72(s1)
    8000356c:	68b8                	ld	a4,80(s1)
    8000356e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003570:	0001e797          	auipc	a5,0x1e
    80003574:	9f078793          	addi	a5,a5,-1552 # 80020f60 <bcache+0x8000>
    80003578:	2b87b703          	ld	a4,696(a5)
    8000357c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000357e:	0001e717          	auipc	a4,0x1e
    80003582:	c4a70713          	addi	a4,a4,-950 # 800211c8 <bcache+0x8268>
    80003586:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003588:	2b87b703          	ld	a4,696(a5)
    8000358c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000358e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003592:	00016517          	auipc	a0,0x16
    80003596:	9ce50513          	addi	a0,a0,-1586 # 80018f60 <bcache>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
}
    800035a2:	60e2                	ld	ra,24(sp)
    800035a4:	6442                	ld	s0,16(sp)
    800035a6:	64a2                	ld	s1,8(sp)
    800035a8:	6902                	ld	s2,0(sp)
    800035aa:	6105                	addi	sp,sp,32
    800035ac:	8082                	ret
    panic("brelse");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	08250513          	addi	a0,a0,130 # 80008630 <syscalls+0xf8>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>

00000000800035be <bpin>:

void
bpin(struct buf *b) {
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	e426                	sd	s1,8(sp)
    800035c6:	1000                	addi	s0,sp,32
    800035c8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ca:	00016517          	auipc	a0,0x16
    800035ce:	99650513          	addi	a0,a0,-1642 # 80018f60 <bcache>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	612080e7          	jalr	1554(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035da:	40bc                	lw	a5,64(s1)
    800035dc:	2785                	addiw	a5,a5,1
    800035de:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035e0:	00016517          	auipc	a0,0x16
    800035e4:	98050513          	addi	a0,a0,-1664 # 80018f60 <bcache>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	6b0080e7          	jalr	1712(ra) # 80000c98 <release>
}
    800035f0:	60e2                	ld	ra,24(sp)
    800035f2:	6442                	ld	s0,16(sp)
    800035f4:	64a2                	ld	s1,8(sp)
    800035f6:	6105                	addi	sp,sp,32
    800035f8:	8082                	ret

00000000800035fa <bunpin>:

void
bunpin(struct buf *b) {
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	e426                	sd	s1,8(sp)
    80003602:	1000                	addi	s0,sp,32
    80003604:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003606:	00016517          	auipc	a0,0x16
    8000360a:	95a50513          	addi	a0,a0,-1702 # 80018f60 <bcache>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003616:	40bc                	lw	a5,64(s1)
    80003618:	37fd                	addiw	a5,a5,-1
    8000361a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000361c:	00016517          	auipc	a0,0x16
    80003620:	94450513          	addi	a0,a0,-1724 # 80018f60 <bcache>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	674080e7          	jalr	1652(ra) # 80000c98 <release>
}
    8000362c:	60e2                	ld	ra,24(sp)
    8000362e:	6442                	ld	s0,16(sp)
    80003630:	64a2                	ld	s1,8(sp)
    80003632:	6105                	addi	sp,sp,32
    80003634:	8082                	ret

0000000080003636 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003636:	1101                	addi	sp,sp,-32
    80003638:	ec06                	sd	ra,24(sp)
    8000363a:	e822                	sd	s0,16(sp)
    8000363c:	e426                	sd	s1,8(sp)
    8000363e:	e04a                	sd	s2,0(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003644:	00d5d59b          	srliw	a1,a1,0xd
    80003648:	0001e797          	auipc	a5,0x1e
    8000364c:	ff47a783          	lw	a5,-12(a5) # 8002163c <sb+0x1c>
    80003650:	9dbd                	addw	a1,a1,a5
    80003652:	00000097          	auipc	ra,0x0
    80003656:	d9e080e7          	jalr	-610(ra) # 800033f0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000365a:	0074f713          	andi	a4,s1,7
    8000365e:	4785                	li	a5,1
    80003660:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003664:	14ce                	slli	s1,s1,0x33
    80003666:	90d9                	srli	s1,s1,0x36
    80003668:	00950733          	add	a4,a0,s1
    8000366c:	05874703          	lbu	a4,88(a4)
    80003670:	00e7f6b3          	and	a3,a5,a4
    80003674:	c69d                	beqz	a3,800036a2 <bfree+0x6c>
    80003676:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003678:	94aa                	add	s1,s1,a0
    8000367a:	fff7c793          	not	a5,a5
    8000367e:	8ff9                	and	a5,a5,a4
    80003680:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003684:	00001097          	auipc	ra,0x1
    80003688:	118080e7          	jalr	280(ra) # 8000479c <log_write>
  brelse(bp);
    8000368c:	854a                	mv	a0,s2
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	e92080e7          	jalr	-366(ra) # 80003520 <brelse>
}
    80003696:	60e2                	ld	ra,24(sp)
    80003698:	6442                	ld	s0,16(sp)
    8000369a:	64a2                	ld	s1,8(sp)
    8000369c:	6902                	ld	s2,0(sp)
    8000369e:	6105                	addi	sp,sp,32
    800036a0:	8082                	ret
    panic("freeing free block");
    800036a2:	00005517          	auipc	a0,0x5
    800036a6:	f9650513          	addi	a0,a0,-106 # 80008638 <syscalls+0x100>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>

00000000800036b2 <balloc>:
{
    800036b2:	711d                	addi	sp,sp,-96
    800036b4:	ec86                	sd	ra,88(sp)
    800036b6:	e8a2                	sd	s0,80(sp)
    800036b8:	e4a6                	sd	s1,72(sp)
    800036ba:	e0ca                	sd	s2,64(sp)
    800036bc:	fc4e                	sd	s3,56(sp)
    800036be:	f852                	sd	s4,48(sp)
    800036c0:	f456                	sd	s5,40(sp)
    800036c2:	f05a                	sd	s6,32(sp)
    800036c4:	ec5e                	sd	s7,24(sp)
    800036c6:	e862                	sd	s8,16(sp)
    800036c8:	e466                	sd	s9,8(sp)
    800036ca:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036cc:	0001e797          	auipc	a5,0x1e
    800036d0:	f587a783          	lw	a5,-168(a5) # 80021624 <sb+0x4>
    800036d4:	cbd1                	beqz	a5,80003768 <balloc+0xb6>
    800036d6:	8baa                	mv	s7,a0
    800036d8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036da:	0001eb17          	auipc	s6,0x1e
    800036de:	f46b0b13          	addi	s6,s6,-186 # 80021620 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036e4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036e8:	6c89                	lui	s9,0x2
    800036ea:	a831                	j	80003706 <balloc+0x54>
    brelse(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	e32080e7          	jalr	-462(ra) # 80003520 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036f6:	015c87bb          	addw	a5,s9,s5
    800036fa:	00078a9b          	sext.w	s5,a5
    800036fe:	004b2703          	lw	a4,4(s6)
    80003702:	06eaf363          	bgeu	s5,a4,80003768 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003706:	41fad79b          	sraiw	a5,s5,0x1f
    8000370a:	0137d79b          	srliw	a5,a5,0x13
    8000370e:	015787bb          	addw	a5,a5,s5
    80003712:	40d7d79b          	sraiw	a5,a5,0xd
    80003716:	01cb2583          	lw	a1,28(s6)
    8000371a:	9dbd                	addw	a1,a1,a5
    8000371c:	855e                	mv	a0,s7
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	cd2080e7          	jalr	-814(ra) # 800033f0 <bread>
    80003726:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003728:	004b2503          	lw	a0,4(s6)
    8000372c:	000a849b          	sext.w	s1,s5
    80003730:	8662                	mv	a2,s8
    80003732:	faa4fde3          	bgeu	s1,a0,800036ec <balloc+0x3a>
      m = 1 << (bi % 8);
    80003736:	41f6579b          	sraiw	a5,a2,0x1f
    8000373a:	01d7d69b          	srliw	a3,a5,0x1d
    8000373e:	00c6873b          	addw	a4,a3,a2
    80003742:	00777793          	andi	a5,a4,7
    80003746:	9f95                	subw	a5,a5,a3
    80003748:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000374c:	4037571b          	sraiw	a4,a4,0x3
    80003750:	00e906b3          	add	a3,s2,a4
    80003754:	0586c683          	lbu	a3,88(a3)
    80003758:	00d7f5b3          	and	a1,a5,a3
    8000375c:	cd91                	beqz	a1,80003778 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000375e:	2605                	addiw	a2,a2,1
    80003760:	2485                	addiw	s1,s1,1
    80003762:	fd4618e3          	bne	a2,s4,80003732 <balloc+0x80>
    80003766:	b759                	j	800036ec <balloc+0x3a>
  panic("balloc: out of blocks");
    80003768:	00005517          	auipc	a0,0x5
    8000376c:	ee850513          	addi	a0,a0,-280 # 80008650 <syscalls+0x118>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	dce080e7          	jalr	-562(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003778:	974a                	add	a4,a4,s2
    8000377a:	8fd5                	or	a5,a5,a3
    8000377c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	01a080e7          	jalr	26(ra) # 8000479c <log_write>
        brelse(bp);
    8000378a:	854a                	mv	a0,s2
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	d94080e7          	jalr	-620(ra) # 80003520 <brelse>
  bp = bread(dev, bno);
    80003794:	85a6                	mv	a1,s1
    80003796:	855e                	mv	a0,s7
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	c58080e7          	jalr	-936(ra) # 800033f0 <bread>
    800037a0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037a2:	40000613          	li	a2,1024
    800037a6:	4581                	li	a1,0
    800037a8:	05850513          	addi	a0,a0,88
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	534080e7          	jalr	1332(ra) # 80000ce0 <memset>
  log_write(bp);
    800037b4:	854a                	mv	a0,s2
    800037b6:	00001097          	auipc	ra,0x1
    800037ba:	fe6080e7          	jalr	-26(ra) # 8000479c <log_write>
  brelse(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	d60080e7          	jalr	-672(ra) # 80003520 <brelse>
}
    800037c8:	8526                	mv	a0,s1
    800037ca:	60e6                	ld	ra,88(sp)
    800037cc:	6446                	ld	s0,80(sp)
    800037ce:	64a6                	ld	s1,72(sp)
    800037d0:	6906                	ld	s2,64(sp)
    800037d2:	79e2                	ld	s3,56(sp)
    800037d4:	7a42                	ld	s4,48(sp)
    800037d6:	7aa2                	ld	s5,40(sp)
    800037d8:	7b02                	ld	s6,32(sp)
    800037da:	6be2                	ld	s7,24(sp)
    800037dc:	6c42                	ld	s8,16(sp)
    800037de:	6ca2                	ld	s9,8(sp)
    800037e0:	6125                	addi	sp,sp,96
    800037e2:	8082                	ret

00000000800037e4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037e4:	7179                	addi	sp,sp,-48
    800037e6:	f406                	sd	ra,40(sp)
    800037e8:	f022                	sd	s0,32(sp)
    800037ea:	ec26                	sd	s1,24(sp)
    800037ec:	e84a                	sd	s2,16(sp)
    800037ee:	e44e                	sd	s3,8(sp)
    800037f0:	e052                	sd	s4,0(sp)
    800037f2:	1800                	addi	s0,sp,48
    800037f4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037f6:	47ad                	li	a5,11
    800037f8:	04b7fe63          	bgeu	a5,a1,80003854 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037fc:	ff45849b          	addiw	s1,a1,-12
    80003800:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003804:	0ff00793          	li	a5,255
    80003808:	0ae7e363          	bltu	a5,a4,800038ae <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000380c:	08052583          	lw	a1,128(a0)
    80003810:	c5ad                	beqz	a1,8000387a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003812:	00092503          	lw	a0,0(s2)
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	bda080e7          	jalr	-1062(ra) # 800033f0 <bread>
    8000381e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003820:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003824:	02049593          	slli	a1,s1,0x20
    80003828:	9181                	srli	a1,a1,0x20
    8000382a:	058a                	slli	a1,a1,0x2
    8000382c:	00b784b3          	add	s1,a5,a1
    80003830:	0004a983          	lw	s3,0(s1)
    80003834:	04098d63          	beqz	s3,8000388e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003838:	8552                	mv	a0,s4
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	ce6080e7          	jalr	-794(ra) # 80003520 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003842:	854e                	mv	a0,s3
    80003844:	70a2                	ld	ra,40(sp)
    80003846:	7402                	ld	s0,32(sp)
    80003848:	64e2                	ld	s1,24(sp)
    8000384a:	6942                	ld	s2,16(sp)
    8000384c:	69a2                	ld	s3,8(sp)
    8000384e:	6a02                	ld	s4,0(sp)
    80003850:	6145                	addi	sp,sp,48
    80003852:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003854:	02059493          	slli	s1,a1,0x20
    80003858:	9081                	srli	s1,s1,0x20
    8000385a:	048a                	slli	s1,s1,0x2
    8000385c:	94aa                	add	s1,s1,a0
    8000385e:	0504a983          	lw	s3,80(s1)
    80003862:	fe0990e3          	bnez	s3,80003842 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003866:	4108                	lw	a0,0(a0)
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	e4a080e7          	jalr	-438(ra) # 800036b2 <balloc>
    80003870:	0005099b          	sext.w	s3,a0
    80003874:	0534a823          	sw	s3,80(s1)
    80003878:	b7e9                	j	80003842 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000387a:	4108                	lw	a0,0(a0)
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	e36080e7          	jalr	-458(ra) # 800036b2 <balloc>
    80003884:	0005059b          	sext.w	a1,a0
    80003888:	08b92023          	sw	a1,128(s2)
    8000388c:	b759                	j	80003812 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000388e:	00092503          	lw	a0,0(s2)
    80003892:	00000097          	auipc	ra,0x0
    80003896:	e20080e7          	jalr	-480(ra) # 800036b2 <balloc>
    8000389a:	0005099b          	sext.w	s3,a0
    8000389e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038a2:	8552                	mv	a0,s4
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	ef8080e7          	jalr	-264(ra) # 8000479c <log_write>
    800038ac:	b771                	j	80003838 <bmap+0x54>
  panic("bmap: out of range");
    800038ae:	00005517          	auipc	a0,0x5
    800038b2:	dba50513          	addi	a0,a0,-582 # 80008668 <syscalls+0x130>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	c88080e7          	jalr	-888(ra) # 8000053e <panic>

00000000800038be <iget>:
{
    800038be:	7179                	addi	sp,sp,-48
    800038c0:	f406                	sd	ra,40(sp)
    800038c2:	f022                	sd	s0,32(sp)
    800038c4:	ec26                	sd	s1,24(sp)
    800038c6:	e84a                	sd	s2,16(sp)
    800038c8:	e44e                	sd	s3,8(sp)
    800038ca:	e052                	sd	s4,0(sp)
    800038cc:	1800                	addi	s0,sp,48
    800038ce:	89aa                	mv	s3,a0
    800038d0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038d2:	0001e517          	auipc	a0,0x1e
    800038d6:	d6e50513          	addi	a0,a0,-658 # 80021640 <itable>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	30a080e7          	jalr	778(ra) # 80000be4 <acquire>
  empty = 0;
    800038e2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038e4:	0001e497          	auipc	s1,0x1e
    800038e8:	d7448493          	addi	s1,s1,-652 # 80021658 <itable+0x18>
    800038ec:	0001f697          	auipc	a3,0x1f
    800038f0:	7fc68693          	addi	a3,a3,2044 # 800230e8 <log>
    800038f4:	a039                	j	80003902 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038f6:	02090b63          	beqz	s2,8000392c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038fa:	08848493          	addi	s1,s1,136
    800038fe:	02d48a63          	beq	s1,a3,80003932 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003902:	449c                	lw	a5,8(s1)
    80003904:	fef059e3          	blez	a5,800038f6 <iget+0x38>
    80003908:	4098                	lw	a4,0(s1)
    8000390a:	ff3716e3          	bne	a4,s3,800038f6 <iget+0x38>
    8000390e:	40d8                	lw	a4,4(s1)
    80003910:	ff4713e3          	bne	a4,s4,800038f6 <iget+0x38>
      ip->ref++;
    80003914:	2785                	addiw	a5,a5,1
    80003916:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003918:	0001e517          	auipc	a0,0x1e
    8000391c:	d2850513          	addi	a0,a0,-728 # 80021640 <itable>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	378080e7          	jalr	888(ra) # 80000c98 <release>
      return ip;
    80003928:	8926                	mv	s2,s1
    8000392a:	a03d                	j	80003958 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000392c:	f7f9                	bnez	a5,800038fa <iget+0x3c>
    8000392e:	8926                	mv	s2,s1
    80003930:	b7e9                	j	800038fa <iget+0x3c>
  if(empty == 0)
    80003932:	02090c63          	beqz	s2,8000396a <iget+0xac>
  ip->dev = dev;
    80003936:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000393a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000393e:	4785                	li	a5,1
    80003940:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003944:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003948:	0001e517          	auipc	a0,0x1e
    8000394c:	cf850513          	addi	a0,a0,-776 # 80021640 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	348080e7          	jalr	840(ra) # 80000c98 <release>
}
    80003958:	854a                	mv	a0,s2
    8000395a:	70a2                	ld	ra,40(sp)
    8000395c:	7402                	ld	s0,32(sp)
    8000395e:	64e2                	ld	s1,24(sp)
    80003960:	6942                	ld	s2,16(sp)
    80003962:	69a2                	ld	s3,8(sp)
    80003964:	6a02                	ld	s4,0(sp)
    80003966:	6145                	addi	sp,sp,48
    80003968:	8082                	ret
    panic("iget: no inodes");
    8000396a:	00005517          	auipc	a0,0x5
    8000396e:	d1650513          	addi	a0,a0,-746 # 80008680 <syscalls+0x148>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	bcc080e7          	jalr	-1076(ra) # 8000053e <panic>

000000008000397a <fsinit>:
fsinit(int dev) {
    8000397a:	7179                	addi	sp,sp,-48
    8000397c:	f406                	sd	ra,40(sp)
    8000397e:	f022                	sd	s0,32(sp)
    80003980:	ec26                	sd	s1,24(sp)
    80003982:	e84a                	sd	s2,16(sp)
    80003984:	e44e                	sd	s3,8(sp)
    80003986:	1800                	addi	s0,sp,48
    80003988:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000398a:	4585                	li	a1,1
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	a64080e7          	jalr	-1436(ra) # 800033f0 <bread>
    80003994:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003996:	0001e997          	auipc	s3,0x1e
    8000399a:	c8a98993          	addi	s3,s3,-886 # 80021620 <sb>
    8000399e:	02000613          	li	a2,32
    800039a2:	05850593          	addi	a1,a0,88
    800039a6:	854e                	mv	a0,s3
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	398080e7          	jalr	920(ra) # 80000d40 <memmove>
  brelse(bp);
    800039b0:	8526                	mv	a0,s1
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	b6e080e7          	jalr	-1170(ra) # 80003520 <brelse>
  if(sb.magic != FSMAGIC)
    800039ba:	0009a703          	lw	a4,0(s3)
    800039be:	102037b7          	lui	a5,0x10203
    800039c2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039c6:	02f71263          	bne	a4,a5,800039ea <fsinit+0x70>
  initlog(dev, &sb);
    800039ca:	0001e597          	auipc	a1,0x1e
    800039ce:	c5658593          	addi	a1,a1,-938 # 80021620 <sb>
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	b4c080e7          	jalr	-1204(ra) # 80004520 <initlog>
}
    800039dc:	70a2                	ld	ra,40(sp)
    800039de:	7402                	ld	s0,32(sp)
    800039e0:	64e2                	ld	s1,24(sp)
    800039e2:	6942                	ld	s2,16(sp)
    800039e4:	69a2                	ld	s3,8(sp)
    800039e6:	6145                	addi	sp,sp,48
    800039e8:	8082                	ret
    panic("invalid file system");
    800039ea:	00005517          	auipc	a0,0x5
    800039ee:	ca650513          	addi	a0,a0,-858 # 80008690 <syscalls+0x158>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>

00000000800039fa <iinit>:
{
    800039fa:	7179                	addi	sp,sp,-48
    800039fc:	f406                	sd	ra,40(sp)
    800039fe:	f022                	sd	s0,32(sp)
    80003a00:	ec26                	sd	s1,24(sp)
    80003a02:	e84a                	sd	s2,16(sp)
    80003a04:	e44e                	sd	s3,8(sp)
    80003a06:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a08:	00005597          	auipc	a1,0x5
    80003a0c:	ca058593          	addi	a1,a1,-864 # 800086a8 <syscalls+0x170>
    80003a10:	0001e517          	auipc	a0,0x1e
    80003a14:	c3050513          	addi	a0,a0,-976 # 80021640 <itable>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	13c080e7          	jalr	316(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a20:	0001e497          	auipc	s1,0x1e
    80003a24:	c4848493          	addi	s1,s1,-952 # 80021668 <itable+0x28>
    80003a28:	0001f997          	auipc	s3,0x1f
    80003a2c:	6d098993          	addi	s3,s3,1744 # 800230f8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a30:	00005917          	auipc	s2,0x5
    80003a34:	c8090913          	addi	s2,s2,-896 # 800086b0 <syscalls+0x178>
    80003a38:	85ca                	mv	a1,s2
    80003a3a:	8526                	mv	a0,s1
    80003a3c:	00001097          	auipc	ra,0x1
    80003a40:	e46080e7          	jalr	-442(ra) # 80004882 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a44:	08848493          	addi	s1,s1,136
    80003a48:	ff3498e3          	bne	s1,s3,80003a38 <iinit+0x3e>
}
    80003a4c:	70a2                	ld	ra,40(sp)
    80003a4e:	7402                	ld	s0,32(sp)
    80003a50:	64e2                	ld	s1,24(sp)
    80003a52:	6942                	ld	s2,16(sp)
    80003a54:	69a2                	ld	s3,8(sp)
    80003a56:	6145                	addi	sp,sp,48
    80003a58:	8082                	ret

0000000080003a5a <ialloc>:
{
    80003a5a:	715d                	addi	sp,sp,-80
    80003a5c:	e486                	sd	ra,72(sp)
    80003a5e:	e0a2                	sd	s0,64(sp)
    80003a60:	fc26                	sd	s1,56(sp)
    80003a62:	f84a                	sd	s2,48(sp)
    80003a64:	f44e                	sd	s3,40(sp)
    80003a66:	f052                	sd	s4,32(sp)
    80003a68:	ec56                	sd	s5,24(sp)
    80003a6a:	e85a                	sd	s6,16(sp)
    80003a6c:	e45e                	sd	s7,8(sp)
    80003a6e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a70:	0001e717          	auipc	a4,0x1e
    80003a74:	bbc72703          	lw	a4,-1092(a4) # 8002162c <sb+0xc>
    80003a78:	4785                	li	a5,1
    80003a7a:	04e7fa63          	bgeu	a5,a4,80003ace <ialloc+0x74>
    80003a7e:	8aaa                	mv	s5,a0
    80003a80:	8bae                	mv	s7,a1
    80003a82:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a84:	0001ea17          	auipc	s4,0x1e
    80003a88:	b9ca0a13          	addi	s4,s4,-1124 # 80021620 <sb>
    80003a8c:	00048b1b          	sext.w	s6,s1
    80003a90:	0044d593          	srli	a1,s1,0x4
    80003a94:	018a2783          	lw	a5,24(s4)
    80003a98:	9dbd                	addw	a1,a1,a5
    80003a9a:	8556                	mv	a0,s5
    80003a9c:	00000097          	auipc	ra,0x0
    80003aa0:	954080e7          	jalr	-1708(ra) # 800033f0 <bread>
    80003aa4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aa6:	05850993          	addi	s3,a0,88
    80003aaa:	00f4f793          	andi	a5,s1,15
    80003aae:	079a                	slli	a5,a5,0x6
    80003ab0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ab2:	00099783          	lh	a5,0(s3)
    80003ab6:	c785                	beqz	a5,80003ade <ialloc+0x84>
    brelse(bp);
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	a68080e7          	jalr	-1432(ra) # 80003520 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ac0:	0485                	addi	s1,s1,1
    80003ac2:	00ca2703          	lw	a4,12(s4)
    80003ac6:	0004879b          	sext.w	a5,s1
    80003aca:	fce7e1e3          	bltu	a5,a4,80003a8c <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ace:	00005517          	auipc	a0,0x5
    80003ad2:	bea50513          	addi	a0,a0,-1046 # 800086b8 <syscalls+0x180>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	a68080e7          	jalr	-1432(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003ade:	04000613          	li	a2,64
    80003ae2:	4581                	li	a1,0
    80003ae4:	854e                	mv	a0,s3
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	1fa080e7          	jalr	506(ra) # 80000ce0 <memset>
      dip->type = type;
    80003aee:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003af2:	854a                	mv	a0,s2
    80003af4:	00001097          	auipc	ra,0x1
    80003af8:	ca8080e7          	jalr	-856(ra) # 8000479c <log_write>
      brelse(bp);
    80003afc:	854a                	mv	a0,s2
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	a22080e7          	jalr	-1502(ra) # 80003520 <brelse>
      return iget(dev, inum);
    80003b06:	85da                	mv	a1,s6
    80003b08:	8556                	mv	a0,s5
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	db4080e7          	jalr	-588(ra) # 800038be <iget>
}
    80003b12:	60a6                	ld	ra,72(sp)
    80003b14:	6406                	ld	s0,64(sp)
    80003b16:	74e2                	ld	s1,56(sp)
    80003b18:	7942                	ld	s2,48(sp)
    80003b1a:	79a2                	ld	s3,40(sp)
    80003b1c:	7a02                	ld	s4,32(sp)
    80003b1e:	6ae2                	ld	s5,24(sp)
    80003b20:	6b42                	ld	s6,16(sp)
    80003b22:	6ba2                	ld	s7,8(sp)
    80003b24:	6161                	addi	sp,sp,80
    80003b26:	8082                	ret

0000000080003b28 <iupdate>:
{
    80003b28:	1101                	addi	sp,sp,-32
    80003b2a:	ec06                	sd	ra,24(sp)
    80003b2c:	e822                	sd	s0,16(sp)
    80003b2e:	e426                	sd	s1,8(sp)
    80003b30:	e04a                	sd	s2,0(sp)
    80003b32:	1000                	addi	s0,sp,32
    80003b34:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b36:	415c                	lw	a5,4(a0)
    80003b38:	0047d79b          	srliw	a5,a5,0x4
    80003b3c:	0001e597          	auipc	a1,0x1e
    80003b40:	afc5a583          	lw	a1,-1284(a1) # 80021638 <sb+0x18>
    80003b44:	9dbd                	addw	a1,a1,a5
    80003b46:	4108                	lw	a0,0(a0)
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	8a8080e7          	jalr	-1880(ra) # 800033f0 <bread>
    80003b50:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b52:	05850793          	addi	a5,a0,88
    80003b56:	40c8                	lw	a0,4(s1)
    80003b58:	893d                	andi	a0,a0,15
    80003b5a:	051a                	slli	a0,a0,0x6
    80003b5c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b5e:	04449703          	lh	a4,68(s1)
    80003b62:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b66:	04649703          	lh	a4,70(s1)
    80003b6a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b6e:	04849703          	lh	a4,72(s1)
    80003b72:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b76:	04a49703          	lh	a4,74(s1)
    80003b7a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b7e:	44f8                	lw	a4,76(s1)
    80003b80:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b82:	03400613          	li	a2,52
    80003b86:	05048593          	addi	a1,s1,80
    80003b8a:	0531                	addi	a0,a0,12
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	1b4080e7          	jalr	436(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b94:	854a                	mv	a0,s2
    80003b96:	00001097          	auipc	ra,0x1
    80003b9a:	c06080e7          	jalr	-1018(ra) # 8000479c <log_write>
  brelse(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	980080e7          	jalr	-1664(ra) # 80003520 <brelse>
}
    80003ba8:	60e2                	ld	ra,24(sp)
    80003baa:	6442                	ld	s0,16(sp)
    80003bac:	64a2                	ld	s1,8(sp)
    80003bae:	6902                	ld	s2,0(sp)
    80003bb0:	6105                	addi	sp,sp,32
    80003bb2:	8082                	ret

0000000080003bb4 <idup>:
{
    80003bb4:	1101                	addi	sp,sp,-32
    80003bb6:	ec06                	sd	ra,24(sp)
    80003bb8:	e822                	sd	s0,16(sp)
    80003bba:	e426                	sd	s1,8(sp)
    80003bbc:	1000                	addi	s0,sp,32
    80003bbe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bc0:	0001e517          	auipc	a0,0x1e
    80003bc4:	a8050513          	addi	a0,a0,-1408 # 80021640 <itable>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	01c080e7          	jalr	28(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bd0:	449c                	lw	a5,8(s1)
    80003bd2:	2785                	addiw	a5,a5,1
    80003bd4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd6:	0001e517          	auipc	a0,0x1e
    80003bda:	a6a50513          	addi	a0,a0,-1430 # 80021640 <itable>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
}
    80003be6:	8526                	mv	a0,s1
    80003be8:	60e2                	ld	ra,24(sp)
    80003bea:	6442                	ld	s0,16(sp)
    80003bec:	64a2                	ld	s1,8(sp)
    80003bee:	6105                	addi	sp,sp,32
    80003bf0:	8082                	ret

0000000080003bf2 <ilock>:
{
    80003bf2:	1101                	addi	sp,sp,-32
    80003bf4:	ec06                	sd	ra,24(sp)
    80003bf6:	e822                	sd	s0,16(sp)
    80003bf8:	e426                	sd	s1,8(sp)
    80003bfa:	e04a                	sd	s2,0(sp)
    80003bfc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bfe:	c115                	beqz	a0,80003c22 <ilock+0x30>
    80003c00:	84aa                	mv	s1,a0
    80003c02:	451c                	lw	a5,8(a0)
    80003c04:	00f05f63          	blez	a5,80003c22 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c08:	0541                	addi	a0,a0,16
    80003c0a:	00001097          	auipc	ra,0x1
    80003c0e:	cb2080e7          	jalr	-846(ra) # 800048bc <acquiresleep>
  if(ip->valid == 0){
    80003c12:	40bc                	lw	a5,64(s1)
    80003c14:	cf99                	beqz	a5,80003c32 <ilock+0x40>
}
    80003c16:	60e2                	ld	ra,24(sp)
    80003c18:	6442                	ld	s0,16(sp)
    80003c1a:	64a2                	ld	s1,8(sp)
    80003c1c:	6902                	ld	s2,0(sp)
    80003c1e:	6105                	addi	sp,sp,32
    80003c20:	8082                	ret
    panic("ilock");
    80003c22:	00005517          	auipc	a0,0x5
    80003c26:	aae50513          	addi	a0,a0,-1362 # 800086d0 <syscalls+0x198>
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c32:	40dc                	lw	a5,4(s1)
    80003c34:	0047d79b          	srliw	a5,a5,0x4
    80003c38:	0001e597          	auipc	a1,0x1e
    80003c3c:	a005a583          	lw	a1,-1536(a1) # 80021638 <sb+0x18>
    80003c40:	9dbd                	addw	a1,a1,a5
    80003c42:	4088                	lw	a0,0(s1)
    80003c44:	fffff097          	auipc	ra,0xfffff
    80003c48:	7ac080e7          	jalr	1964(ra) # 800033f0 <bread>
    80003c4c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c4e:	05850593          	addi	a1,a0,88
    80003c52:	40dc                	lw	a5,4(s1)
    80003c54:	8bbd                	andi	a5,a5,15
    80003c56:	079a                	slli	a5,a5,0x6
    80003c58:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c5a:	00059783          	lh	a5,0(a1)
    80003c5e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c62:	00259783          	lh	a5,2(a1)
    80003c66:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c6a:	00459783          	lh	a5,4(a1)
    80003c6e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c72:	00659783          	lh	a5,6(a1)
    80003c76:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c7a:	459c                	lw	a5,8(a1)
    80003c7c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c7e:	03400613          	li	a2,52
    80003c82:	05b1                	addi	a1,a1,12
    80003c84:	05048513          	addi	a0,s1,80
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	0b8080e7          	jalr	184(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c90:	854a                	mv	a0,s2
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	88e080e7          	jalr	-1906(ra) # 80003520 <brelse>
    ip->valid = 1;
    80003c9a:	4785                	li	a5,1
    80003c9c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c9e:	04449783          	lh	a5,68(s1)
    80003ca2:	fbb5                	bnez	a5,80003c16 <ilock+0x24>
      panic("ilock: no type");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	a3450513          	addi	a0,a0,-1484 # 800086d8 <syscalls+0x1a0>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	892080e7          	jalr	-1902(ra) # 8000053e <panic>

0000000080003cb4 <iunlock>:
{
    80003cb4:	1101                	addi	sp,sp,-32
    80003cb6:	ec06                	sd	ra,24(sp)
    80003cb8:	e822                	sd	s0,16(sp)
    80003cba:	e426                	sd	s1,8(sp)
    80003cbc:	e04a                	sd	s2,0(sp)
    80003cbe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cc0:	c905                	beqz	a0,80003cf0 <iunlock+0x3c>
    80003cc2:	84aa                	mv	s1,a0
    80003cc4:	01050913          	addi	s2,a0,16
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00001097          	auipc	ra,0x1
    80003cce:	c8c080e7          	jalr	-884(ra) # 80004956 <holdingsleep>
    80003cd2:	cd19                	beqz	a0,80003cf0 <iunlock+0x3c>
    80003cd4:	449c                	lw	a5,8(s1)
    80003cd6:	00f05d63          	blez	a5,80003cf0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cda:	854a                	mv	a0,s2
    80003cdc:	00001097          	auipc	ra,0x1
    80003ce0:	c36080e7          	jalr	-970(ra) # 80004912 <releasesleep>
}
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6902                	ld	s2,0(sp)
    80003cec:	6105                	addi	sp,sp,32
    80003cee:	8082                	ret
    panic("iunlock");
    80003cf0:	00005517          	auipc	a0,0x5
    80003cf4:	9f850513          	addi	a0,a0,-1544 # 800086e8 <syscalls+0x1b0>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>

0000000080003d00 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d00:	7179                	addi	sp,sp,-48
    80003d02:	f406                	sd	ra,40(sp)
    80003d04:	f022                	sd	s0,32(sp)
    80003d06:	ec26                	sd	s1,24(sp)
    80003d08:	e84a                	sd	s2,16(sp)
    80003d0a:	e44e                	sd	s3,8(sp)
    80003d0c:	e052                	sd	s4,0(sp)
    80003d0e:	1800                	addi	s0,sp,48
    80003d10:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d12:	05050493          	addi	s1,a0,80
    80003d16:	08050913          	addi	s2,a0,128
    80003d1a:	a021                	j	80003d22 <itrunc+0x22>
    80003d1c:	0491                	addi	s1,s1,4
    80003d1e:	01248d63          	beq	s1,s2,80003d38 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d22:	408c                	lw	a1,0(s1)
    80003d24:	dde5                	beqz	a1,80003d1c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d26:	0009a503          	lw	a0,0(s3)
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	90c080e7          	jalr	-1780(ra) # 80003636 <bfree>
      ip->addrs[i] = 0;
    80003d32:	0004a023          	sw	zero,0(s1)
    80003d36:	b7dd                	j	80003d1c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d38:	0809a583          	lw	a1,128(s3)
    80003d3c:	e185                	bnez	a1,80003d5c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d3e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d42:	854e                	mv	a0,s3
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	de4080e7          	jalr	-540(ra) # 80003b28 <iupdate>
}
    80003d4c:	70a2                	ld	ra,40(sp)
    80003d4e:	7402                	ld	s0,32(sp)
    80003d50:	64e2                	ld	s1,24(sp)
    80003d52:	6942                	ld	s2,16(sp)
    80003d54:	69a2                	ld	s3,8(sp)
    80003d56:	6a02                	ld	s4,0(sp)
    80003d58:	6145                	addi	sp,sp,48
    80003d5a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d5c:	0009a503          	lw	a0,0(s3)
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	690080e7          	jalr	1680(ra) # 800033f0 <bread>
    80003d68:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d6a:	05850493          	addi	s1,a0,88
    80003d6e:	45850913          	addi	s2,a0,1112
    80003d72:	a811                	j	80003d86 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d74:	0009a503          	lw	a0,0(s3)
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	8be080e7          	jalr	-1858(ra) # 80003636 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d80:	0491                	addi	s1,s1,4
    80003d82:	01248563          	beq	s1,s2,80003d8c <itrunc+0x8c>
      if(a[j])
    80003d86:	408c                	lw	a1,0(s1)
    80003d88:	dde5                	beqz	a1,80003d80 <itrunc+0x80>
    80003d8a:	b7ed                	j	80003d74 <itrunc+0x74>
    brelse(bp);
    80003d8c:	8552                	mv	a0,s4
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	792080e7          	jalr	1938(ra) # 80003520 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d96:	0809a583          	lw	a1,128(s3)
    80003d9a:	0009a503          	lw	a0,0(s3)
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	898080e7          	jalr	-1896(ra) # 80003636 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003da6:	0809a023          	sw	zero,128(s3)
    80003daa:	bf51                	j	80003d3e <itrunc+0x3e>

0000000080003dac <iput>:
{
    80003dac:	1101                	addi	sp,sp,-32
    80003dae:	ec06                	sd	ra,24(sp)
    80003db0:	e822                	sd	s0,16(sp)
    80003db2:	e426                	sd	s1,8(sp)
    80003db4:	e04a                	sd	s2,0(sp)
    80003db6:	1000                	addi	s0,sp,32
    80003db8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dba:	0001e517          	auipc	a0,0x1e
    80003dbe:	88650513          	addi	a0,a0,-1914 # 80021640 <itable>
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	e22080e7          	jalr	-478(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dca:	4498                	lw	a4,8(s1)
    80003dcc:	4785                	li	a5,1
    80003dce:	02f70363          	beq	a4,a5,80003df4 <iput+0x48>
  ip->ref--;
    80003dd2:	449c                	lw	a5,8(s1)
    80003dd4:	37fd                	addiw	a5,a5,-1
    80003dd6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dd8:	0001e517          	auipc	a0,0x1e
    80003ddc:	86850513          	addi	a0,a0,-1944 # 80021640 <itable>
    80003de0:	ffffd097          	auipc	ra,0xffffd
    80003de4:	eb8080e7          	jalr	-328(ra) # 80000c98 <release>
}
    80003de8:	60e2                	ld	ra,24(sp)
    80003dea:	6442                	ld	s0,16(sp)
    80003dec:	64a2                	ld	s1,8(sp)
    80003dee:	6902                	ld	s2,0(sp)
    80003df0:	6105                	addi	sp,sp,32
    80003df2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003df4:	40bc                	lw	a5,64(s1)
    80003df6:	dff1                	beqz	a5,80003dd2 <iput+0x26>
    80003df8:	04a49783          	lh	a5,74(s1)
    80003dfc:	fbf9                	bnez	a5,80003dd2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dfe:	01048913          	addi	s2,s1,16
    80003e02:	854a                	mv	a0,s2
    80003e04:	00001097          	auipc	ra,0x1
    80003e08:	ab8080e7          	jalr	-1352(ra) # 800048bc <acquiresleep>
    release(&itable.lock);
    80003e0c:	0001e517          	auipc	a0,0x1e
    80003e10:	83450513          	addi	a0,a0,-1996 # 80021640 <itable>
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	e84080e7          	jalr	-380(ra) # 80000c98 <release>
    itrunc(ip);
    80003e1c:	8526                	mv	a0,s1
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	ee2080e7          	jalr	-286(ra) # 80003d00 <itrunc>
    ip->type = 0;
    80003e26:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e2a:	8526                	mv	a0,s1
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	cfc080e7          	jalr	-772(ra) # 80003b28 <iupdate>
    ip->valid = 0;
    80003e34:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00001097          	auipc	ra,0x1
    80003e3e:	ad8080e7          	jalr	-1320(ra) # 80004912 <releasesleep>
    acquire(&itable.lock);
    80003e42:	0001d517          	auipc	a0,0x1d
    80003e46:	7fe50513          	addi	a0,a0,2046 # 80021640 <itable>
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	d9a080e7          	jalr	-614(ra) # 80000be4 <acquire>
    80003e52:	b741                	j	80003dd2 <iput+0x26>

0000000080003e54 <iunlockput>:
{
    80003e54:	1101                	addi	sp,sp,-32
    80003e56:	ec06                	sd	ra,24(sp)
    80003e58:	e822                	sd	s0,16(sp)
    80003e5a:	e426                	sd	s1,8(sp)
    80003e5c:	1000                	addi	s0,sp,32
    80003e5e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	e54080e7          	jalr	-428(ra) # 80003cb4 <iunlock>
  iput(ip);
    80003e68:	8526                	mv	a0,s1
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	f42080e7          	jalr	-190(ra) # 80003dac <iput>
}
    80003e72:	60e2                	ld	ra,24(sp)
    80003e74:	6442                	ld	s0,16(sp)
    80003e76:	64a2                	ld	s1,8(sp)
    80003e78:	6105                	addi	sp,sp,32
    80003e7a:	8082                	ret

0000000080003e7c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e7c:	1141                	addi	sp,sp,-16
    80003e7e:	e422                	sd	s0,8(sp)
    80003e80:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e82:	411c                	lw	a5,0(a0)
    80003e84:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e86:	415c                	lw	a5,4(a0)
    80003e88:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e8a:	04451783          	lh	a5,68(a0)
    80003e8e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e92:	04a51783          	lh	a5,74(a0)
    80003e96:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e9a:	04c56783          	lwu	a5,76(a0)
    80003e9e:	e99c                	sd	a5,16(a1)
}
    80003ea0:	6422                	ld	s0,8(sp)
    80003ea2:	0141                	addi	sp,sp,16
    80003ea4:	8082                	ret

0000000080003ea6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ea6:	457c                	lw	a5,76(a0)
    80003ea8:	0ed7e963          	bltu	a5,a3,80003f9a <readi+0xf4>
{
    80003eac:	7159                	addi	sp,sp,-112
    80003eae:	f486                	sd	ra,104(sp)
    80003eb0:	f0a2                	sd	s0,96(sp)
    80003eb2:	eca6                	sd	s1,88(sp)
    80003eb4:	e8ca                	sd	s2,80(sp)
    80003eb6:	e4ce                	sd	s3,72(sp)
    80003eb8:	e0d2                	sd	s4,64(sp)
    80003eba:	fc56                	sd	s5,56(sp)
    80003ebc:	f85a                	sd	s6,48(sp)
    80003ebe:	f45e                	sd	s7,40(sp)
    80003ec0:	f062                	sd	s8,32(sp)
    80003ec2:	ec66                	sd	s9,24(sp)
    80003ec4:	e86a                	sd	s10,16(sp)
    80003ec6:	e46e                	sd	s11,8(sp)
    80003ec8:	1880                	addi	s0,sp,112
    80003eca:	8baa                	mv	s7,a0
    80003ecc:	8c2e                	mv	s8,a1
    80003ece:	8ab2                	mv	s5,a2
    80003ed0:	84b6                	mv	s1,a3
    80003ed2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ed4:	9f35                	addw	a4,a4,a3
    return 0;
    80003ed6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ed8:	0ad76063          	bltu	a4,a3,80003f78 <readi+0xd2>
  if(off + n > ip->size)
    80003edc:	00e7f463          	bgeu	a5,a4,80003ee4 <readi+0x3e>
    n = ip->size - off;
    80003ee0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee4:	0a0b0963          	beqz	s6,80003f96 <readi+0xf0>
    80003ee8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eea:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eee:	5cfd                	li	s9,-1
    80003ef0:	a82d                	j	80003f2a <readi+0x84>
    80003ef2:	020a1d93          	slli	s11,s4,0x20
    80003ef6:	020ddd93          	srli	s11,s11,0x20
    80003efa:	05890613          	addi	a2,s2,88
    80003efe:	86ee                	mv	a3,s11
    80003f00:	963a                	add	a2,a2,a4
    80003f02:	85d6                	mv	a1,s5
    80003f04:	8562                	mv	a0,s8
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	878080e7          	jalr	-1928(ra) # 8000277e <either_copyout>
    80003f0e:	05950d63          	beq	a0,s9,80003f68 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f12:	854a                	mv	a0,s2
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	60c080e7          	jalr	1548(ra) # 80003520 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1c:	013a09bb          	addw	s3,s4,s3
    80003f20:	009a04bb          	addw	s1,s4,s1
    80003f24:	9aee                	add	s5,s5,s11
    80003f26:	0569f763          	bgeu	s3,s6,80003f74 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f2a:	000ba903          	lw	s2,0(s7)
    80003f2e:	00a4d59b          	srliw	a1,s1,0xa
    80003f32:	855e                	mv	a0,s7
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	8b0080e7          	jalr	-1872(ra) # 800037e4 <bmap>
    80003f3c:	0005059b          	sext.w	a1,a0
    80003f40:	854a                	mv	a0,s2
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	4ae080e7          	jalr	1198(ra) # 800033f0 <bread>
    80003f4a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f4c:	3ff4f713          	andi	a4,s1,1023
    80003f50:	40ed07bb          	subw	a5,s10,a4
    80003f54:	413b06bb          	subw	a3,s6,s3
    80003f58:	8a3e                	mv	s4,a5
    80003f5a:	2781                	sext.w	a5,a5
    80003f5c:	0006861b          	sext.w	a2,a3
    80003f60:	f8f679e3          	bgeu	a2,a5,80003ef2 <readi+0x4c>
    80003f64:	8a36                	mv	s4,a3
    80003f66:	b771                	j	80003ef2 <readi+0x4c>
      brelse(bp);
    80003f68:	854a                	mv	a0,s2
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	5b6080e7          	jalr	1462(ra) # 80003520 <brelse>
      tot = -1;
    80003f72:	59fd                	li	s3,-1
  }
  return tot;
    80003f74:	0009851b          	sext.w	a0,s3
}
    80003f78:	70a6                	ld	ra,104(sp)
    80003f7a:	7406                	ld	s0,96(sp)
    80003f7c:	64e6                	ld	s1,88(sp)
    80003f7e:	6946                	ld	s2,80(sp)
    80003f80:	69a6                	ld	s3,72(sp)
    80003f82:	6a06                	ld	s4,64(sp)
    80003f84:	7ae2                	ld	s5,56(sp)
    80003f86:	7b42                	ld	s6,48(sp)
    80003f88:	7ba2                	ld	s7,40(sp)
    80003f8a:	7c02                	ld	s8,32(sp)
    80003f8c:	6ce2                	ld	s9,24(sp)
    80003f8e:	6d42                	ld	s10,16(sp)
    80003f90:	6da2                	ld	s11,8(sp)
    80003f92:	6165                	addi	sp,sp,112
    80003f94:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f96:	89da                	mv	s3,s6
    80003f98:	bff1                	j	80003f74 <readi+0xce>
    return 0;
    80003f9a:	4501                	li	a0,0
}
    80003f9c:	8082                	ret

0000000080003f9e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f9e:	457c                	lw	a5,76(a0)
    80003fa0:	10d7e863          	bltu	a5,a3,800040b0 <writei+0x112>
{
    80003fa4:	7159                	addi	sp,sp,-112
    80003fa6:	f486                	sd	ra,104(sp)
    80003fa8:	f0a2                	sd	s0,96(sp)
    80003faa:	eca6                	sd	s1,88(sp)
    80003fac:	e8ca                	sd	s2,80(sp)
    80003fae:	e4ce                	sd	s3,72(sp)
    80003fb0:	e0d2                	sd	s4,64(sp)
    80003fb2:	fc56                	sd	s5,56(sp)
    80003fb4:	f85a                	sd	s6,48(sp)
    80003fb6:	f45e                	sd	s7,40(sp)
    80003fb8:	f062                	sd	s8,32(sp)
    80003fba:	ec66                	sd	s9,24(sp)
    80003fbc:	e86a                	sd	s10,16(sp)
    80003fbe:	e46e                	sd	s11,8(sp)
    80003fc0:	1880                	addi	s0,sp,112
    80003fc2:	8b2a                	mv	s6,a0
    80003fc4:	8c2e                	mv	s8,a1
    80003fc6:	8ab2                	mv	s5,a2
    80003fc8:	8936                	mv	s2,a3
    80003fca:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fcc:	00e687bb          	addw	a5,a3,a4
    80003fd0:	0ed7e263          	bltu	a5,a3,800040b4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fd4:	00043737          	lui	a4,0x43
    80003fd8:	0ef76063          	bltu	a4,a5,800040b8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fdc:	0c0b8863          	beqz	s7,800040ac <writei+0x10e>
    80003fe0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fe6:	5cfd                	li	s9,-1
    80003fe8:	a091                	j	8000402c <writei+0x8e>
    80003fea:	02099d93          	slli	s11,s3,0x20
    80003fee:	020ddd93          	srli	s11,s11,0x20
    80003ff2:	05848513          	addi	a0,s1,88
    80003ff6:	86ee                	mv	a3,s11
    80003ff8:	8656                	mv	a2,s5
    80003ffa:	85e2                	mv	a1,s8
    80003ffc:	953a                	add	a0,a0,a4
    80003ffe:	ffffe097          	auipc	ra,0xffffe
    80004002:	7d6080e7          	jalr	2006(ra) # 800027d4 <either_copyin>
    80004006:	07950263          	beq	a0,s9,8000406a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000400a:	8526                	mv	a0,s1
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	790080e7          	jalr	1936(ra) # 8000479c <log_write>
    brelse(bp);
    80004014:	8526                	mv	a0,s1
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	50a080e7          	jalr	1290(ra) # 80003520 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000401e:	01498a3b          	addw	s4,s3,s4
    80004022:	0129893b          	addw	s2,s3,s2
    80004026:	9aee                	add	s5,s5,s11
    80004028:	057a7663          	bgeu	s4,s7,80004074 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000402c:	000b2483          	lw	s1,0(s6)
    80004030:	00a9559b          	srliw	a1,s2,0xa
    80004034:	855a                	mv	a0,s6
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	7ae080e7          	jalr	1966(ra) # 800037e4 <bmap>
    8000403e:	0005059b          	sext.w	a1,a0
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	3ac080e7          	jalr	940(ra) # 800033f0 <bread>
    8000404c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000404e:	3ff97713          	andi	a4,s2,1023
    80004052:	40ed07bb          	subw	a5,s10,a4
    80004056:	414b86bb          	subw	a3,s7,s4
    8000405a:	89be                	mv	s3,a5
    8000405c:	2781                	sext.w	a5,a5
    8000405e:	0006861b          	sext.w	a2,a3
    80004062:	f8f674e3          	bgeu	a2,a5,80003fea <writei+0x4c>
    80004066:	89b6                	mv	s3,a3
    80004068:	b749                	j	80003fea <writei+0x4c>
      brelse(bp);
    8000406a:	8526                	mv	a0,s1
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	4b4080e7          	jalr	1204(ra) # 80003520 <brelse>
  }

  if(off > ip->size)
    80004074:	04cb2783          	lw	a5,76(s6)
    80004078:	0127f463          	bgeu	a5,s2,80004080 <writei+0xe2>
    ip->size = off;
    8000407c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004080:	855a                	mv	a0,s6
    80004082:	00000097          	auipc	ra,0x0
    80004086:	aa6080e7          	jalr	-1370(ra) # 80003b28 <iupdate>

  return tot;
    8000408a:	000a051b          	sext.w	a0,s4
}
    8000408e:	70a6                	ld	ra,104(sp)
    80004090:	7406                	ld	s0,96(sp)
    80004092:	64e6                	ld	s1,88(sp)
    80004094:	6946                	ld	s2,80(sp)
    80004096:	69a6                	ld	s3,72(sp)
    80004098:	6a06                	ld	s4,64(sp)
    8000409a:	7ae2                	ld	s5,56(sp)
    8000409c:	7b42                	ld	s6,48(sp)
    8000409e:	7ba2                	ld	s7,40(sp)
    800040a0:	7c02                	ld	s8,32(sp)
    800040a2:	6ce2                	ld	s9,24(sp)
    800040a4:	6d42                	ld	s10,16(sp)
    800040a6:	6da2                	ld	s11,8(sp)
    800040a8:	6165                	addi	sp,sp,112
    800040aa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ac:	8a5e                	mv	s4,s7
    800040ae:	bfc9                	j	80004080 <writei+0xe2>
    return -1;
    800040b0:	557d                	li	a0,-1
}
    800040b2:	8082                	ret
    return -1;
    800040b4:	557d                	li	a0,-1
    800040b6:	bfe1                	j	8000408e <writei+0xf0>
    return -1;
    800040b8:	557d                	li	a0,-1
    800040ba:	bfd1                	j	8000408e <writei+0xf0>

00000000800040bc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040bc:	1141                	addi	sp,sp,-16
    800040be:	e406                	sd	ra,8(sp)
    800040c0:	e022                	sd	s0,0(sp)
    800040c2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040c4:	4639                	li	a2,14
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	cf2080e7          	jalr	-782(ra) # 80000db8 <strncmp>
}
    800040ce:	60a2                	ld	ra,8(sp)
    800040d0:	6402                	ld	s0,0(sp)
    800040d2:	0141                	addi	sp,sp,16
    800040d4:	8082                	ret

00000000800040d6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040d6:	7139                	addi	sp,sp,-64
    800040d8:	fc06                	sd	ra,56(sp)
    800040da:	f822                	sd	s0,48(sp)
    800040dc:	f426                	sd	s1,40(sp)
    800040de:	f04a                	sd	s2,32(sp)
    800040e0:	ec4e                	sd	s3,24(sp)
    800040e2:	e852                	sd	s4,16(sp)
    800040e4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040e6:	04451703          	lh	a4,68(a0)
    800040ea:	4785                	li	a5,1
    800040ec:	00f71a63          	bne	a4,a5,80004100 <dirlookup+0x2a>
    800040f0:	892a                	mv	s2,a0
    800040f2:	89ae                	mv	s3,a1
    800040f4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f6:	457c                	lw	a5,76(a0)
    800040f8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040fa:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fc:	e79d                	bnez	a5,8000412a <dirlookup+0x54>
    800040fe:	a8a5                	j	80004176 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004100:	00004517          	auipc	a0,0x4
    80004104:	5f050513          	addi	a0,a0,1520 # 800086f0 <syscalls+0x1b8>
    80004108:	ffffc097          	auipc	ra,0xffffc
    8000410c:	436080e7          	jalr	1078(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004110:	00004517          	auipc	a0,0x4
    80004114:	5f850513          	addi	a0,a0,1528 # 80008708 <syscalls+0x1d0>
    80004118:	ffffc097          	auipc	ra,0xffffc
    8000411c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004120:	24c1                	addiw	s1,s1,16
    80004122:	04c92783          	lw	a5,76(s2)
    80004126:	04f4f763          	bgeu	s1,a5,80004174 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412a:	4741                	li	a4,16
    8000412c:	86a6                	mv	a3,s1
    8000412e:	fc040613          	addi	a2,s0,-64
    80004132:	4581                	li	a1,0
    80004134:	854a                	mv	a0,s2
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	d70080e7          	jalr	-656(ra) # 80003ea6 <readi>
    8000413e:	47c1                	li	a5,16
    80004140:	fcf518e3          	bne	a0,a5,80004110 <dirlookup+0x3a>
    if(de.inum == 0)
    80004144:	fc045783          	lhu	a5,-64(s0)
    80004148:	dfe1                	beqz	a5,80004120 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000414a:	fc240593          	addi	a1,s0,-62
    8000414e:	854e                	mv	a0,s3
    80004150:	00000097          	auipc	ra,0x0
    80004154:	f6c080e7          	jalr	-148(ra) # 800040bc <namecmp>
    80004158:	f561                	bnez	a0,80004120 <dirlookup+0x4a>
      if(poff)
    8000415a:	000a0463          	beqz	s4,80004162 <dirlookup+0x8c>
        *poff = off;
    8000415e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004162:	fc045583          	lhu	a1,-64(s0)
    80004166:	00092503          	lw	a0,0(s2)
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	754080e7          	jalr	1876(ra) # 800038be <iget>
    80004172:	a011                	j	80004176 <dirlookup+0xa0>
  return 0;
    80004174:	4501                	li	a0,0
}
    80004176:	70e2                	ld	ra,56(sp)
    80004178:	7442                	ld	s0,48(sp)
    8000417a:	74a2                	ld	s1,40(sp)
    8000417c:	7902                	ld	s2,32(sp)
    8000417e:	69e2                	ld	s3,24(sp)
    80004180:	6a42                	ld	s4,16(sp)
    80004182:	6121                	addi	sp,sp,64
    80004184:	8082                	ret

0000000080004186 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004186:	711d                	addi	sp,sp,-96
    80004188:	ec86                	sd	ra,88(sp)
    8000418a:	e8a2                	sd	s0,80(sp)
    8000418c:	e4a6                	sd	s1,72(sp)
    8000418e:	e0ca                	sd	s2,64(sp)
    80004190:	fc4e                	sd	s3,56(sp)
    80004192:	f852                	sd	s4,48(sp)
    80004194:	f456                	sd	s5,40(sp)
    80004196:	f05a                	sd	s6,32(sp)
    80004198:	ec5e                	sd	s7,24(sp)
    8000419a:	e862                	sd	s8,16(sp)
    8000419c:	e466                	sd	s9,8(sp)
    8000419e:	1080                	addi	s0,sp,96
    800041a0:	84aa                	mv	s1,a0
    800041a2:	8b2e                	mv	s6,a1
    800041a4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041a6:	00054703          	lbu	a4,0(a0)
    800041aa:	02f00793          	li	a5,47
    800041ae:	02f70363          	beq	a4,a5,800041d4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041b2:	ffffe097          	auipc	ra,0xffffe
    800041b6:	924080e7          	jalr	-1756(ra) # 80001ad6 <myproc>
    800041ba:	15053503          	ld	a0,336(a0)
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	9f6080e7          	jalr	-1546(ra) # 80003bb4 <idup>
    800041c6:	89aa                	mv	s3,a0
  while(*path == '/')
    800041c8:	02f00913          	li	s2,47
  len = path - s;
    800041cc:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041ce:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041d0:	4c05                	li	s8,1
    800041d2:	a865                	j	8000428a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041d4:	4585                	li	a1,1
    800041d6:	4505                	li	a0,1
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	6e6080e7          	jalr	1766(ra) # 800038be <iget>
    800041e0:	89aa                	mv	s3,a0
    800041e2:	b7dd                	j	800041c8 <namex+0x42>
      iunlockput(ip);
    800041e4:	854e                	mv	a0,s3
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	c6e080e7          	jalr	-914(ra) # 80003e54 <iunlockput>
      return 0;
    800041ee:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041f0:	854e                	mv	a0,s3
    800041f2:	60e6                	ld	ra,88(sp)
    800041f4:	6446                	ld	s0,80(sp)
    800041f6:	64a6                	ld	s1,72(sp)
    800041f8:	6906                	ld	s2,64(sp)
    800041fa:	79e2                	ld	s3,56(sp)
    800041fc:	7a42                	ld	s4,48(sp)
    800041fe:	7aa2                	ld	s5,40(sp)
    80004200:	7b02                	ld	s6,32(sp)
    80004202:	6be2                	ld	s7,24(sp)
    80004204:	6c42                	ld	s8,16(sp)
    80004206:	6ca2                	ld	s9,8(sp)
    80004208:	6125                	addi	sp,sp,96
    8000420a:	8082                	ret
      iunlock(ip);
    8000420c:	854e                	mv	a0,s3
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	aa6080e7          	jalr	-1370(ra) # 80003cb4 <iunlock>
      return ip;
    80004216:	bfe9                	j	800041f0 <namex+0x6a>
      iunlockput(ip);
    80004218:	854e                	mv	a0,s3
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	c3a080e7          	jalr	-966(ra) # 80003e54 <iunlockput>
      return 0;
    80004222:	89d2                	mv	s3,s4
    80004224:	b7f1                	j	800041f0 <namex+0x6a>
  len = path - s;
    80004226:	40b48633          	sub	a2,s1,a1
    8000422a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000422e:	094cd463          	bge	s9,s4,800042b6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004232:	4639                	li	a2,14
    80004234:	8556                	mv	a0,s5
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	b0a080e7          	jalr	-1270(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000423e:	0004c783          	lbu	a5,0(s1)
    80004242:	01279763          	bne	a5,s2,80004250 <namex+0xca>
    path++;
    80004246:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004248:	0004c783          	lbu	a5,0(s1)
    8000424c:	ff278de3          	beq	a5,s2,80004246 <namex+0xc0>
    ilock(ip);
    80004250:	854e                	mv	a0,s3
    80004252:	00000097          	auipc	ra,0x0
    80004256:	9a0080e7          	jalr	-1632(ra) # 80003bf2 <ilock>
    if(ip->type != T_DIR){
    8000425a:	04499783          	lh	a5,68(s3)
    8000425e:	f98793e3          	bne	a5,s8,800041e4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004262:	000b0563          	beqz	s6,8000426c <namex+0xe6>
    80004266:	0004c783          	lbu	a5,0(s1)
    8000426a:	d3cd                	beqz	a5,8000420c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000426c:	865e                	mv	a2,s7
    8000426e:	85d6                	mv	a1,s5
    80004270:	854e                	mv	a0,s3
    80004272:	00000097          	auipc	ra,0x0
    80004276:	e64080e7          	jalr	-412(ra) # 800040d6 <dirlookup>
    8000427a:	8a2a                	mv	s4,a0
    8000427c:	dd51                	beqz	a0,80004218 <namex+0x92>
    iunlockput(ip);
    8000427e:	854e                	mv	a0,s3
    80004280:	00000097          	auipc	ra,0x0
    80004284:	bd4080e7          	jalr	-1068(ra) # 80003e54 <iunlockput>
    ip = next;
    80004288:	89d2                	mv	s3,s4
  while(*path == '/')
    8000428a:	0004c783          	lbu	a5,0(s1)
    8000428e:	05279763          	bne	a5,s2,800042dc <namex+0x156>
    path++;
    80004292:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004294:	0004c783          	lbu	a5,0(s1)
    80004298:	ff278de3          	beq	a5,s2,80004292 <namex+0x10c>
  if(*path == 0)
    8000429c:	c79d                	beqz	a5,800042ca <namex+0x144>
    path++;
    8000429e:	85a6                	mv	a1,s1
  len = path - s;
    800042a0:	8a5e                	mv	s4,s7
    800042a2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042a4:	01278963          	beq	a5,s2,800042b6 <namex+0x130>
    800042a8:	dfbd                	beqz	a5,80004226 <namex+0xa0>
    path++;
    800042aa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042ac:	0004c783          	lbu	a5,0(s1)
    800042b0:	ff279ce3          	bne	a5,s2,800042a8 <namex+0x122>
    800042b4:	bf8d                	j	80004226 <namex+0xa0>
    memmove(name, s, len);
    800042b6:	2601                	sext.w	a2,a2
    800042b8:	8556                	mv	a0,s5
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	a86080e7          	jalr	-1402(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042c2:	9a56                	add	s4,s4,s5
    800042c4:	000a0023          	sb	zero,0(s4)
    800042c8:	bf9d                	j	8000423e <namex+0xb8>
  if(nameiparent){
    800042ca:	f20b03e3          	beqz	s6,800041f0 <namex+0x6a>
    iput(ip);
    800042ce:	854e                	mv	a0,s3
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	adc080e7          	jalr	-1316(ra) # 80003dac <iput>
    return 0;
    800042d8:	4981                	li	s3,0
    800042da:	bf19                	j	800041f0 <namex+0x6a>
  if(*path == 0)
    800042dc:	d7fd                	beqz	a5,800042ca <namex+0x144>
  while(*path != '/' && *path != 0)
    800042de:	0004c783          	lbu	a5,0(s1)
    800042e2:	85a6                	mv	a1,s1
    800042e4:	b7d1                	j	800042a8 <namex+0x122>

00000000800042e6 <dirlink>:
{
    800042e6:	7139                	addi	sp,sp,-64
    800042e8:	fc06                	sd	ra,56(sp)
    800042ea:	f822                	sd	s0,48(sp)
    800042ec:	f426                	sd	s1,40(sp)
    800042ee:	f04a                	sd	s2,32(sp)
    800042f0:	ec4e                	sd	s3,24(sp)
    800042f2:	e852                	sd	s4,16(sp)
    800042f4:	0080                	addi	s0,sp,64
    800042f6:	892a                	mv	s2,a0
    800042f8:	8a2e                	mv	s4,a1
    800042fa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042fc:	4601                	li	a2,0
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	dd8080e7          	jalr	-552(ra) # 800040d6 <dirlookup>
    80004306:	e93d                	bnez	a0,8000437c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004308:	04c92483          	lw	s1,76(s2)
    8000430c:	c49d                	beqz	s1,8000433a <dirlink+0x54>
    8000430e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004310:	4741                	li	a4,16
    80004312:	86a6                	mv	a3,s1
    80004314:	fc040613          	addi	a2,s0,-64
    80004318:	4581                	li	a1,0
    8000431a:	854a                	mv	a0,s2
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	b8a080e7          	jalr	-1142(ra) # 80003ea6 <readi>
    80004324:	47c1                	li	a5,16
    80004326:	06f51163          	bne	a0,a5,80004388 <dirlink+0xa2>
    if(de.inum == 0)
    8000432a:	fc045783          	lhu	a5,-64(s0)
    8000432e:	c791                	beqz	a5,8000433a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004330:	24c1                	addiw	s1,s1,16
    80004332:	04c92783          	lw	a5,76(s2)
    80004336:	fcf4ede3          	bltu	s1,a5,80004310 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000433a:	4639                	li	a2,14
    8000433c:	85d2                	mv	a1,s4
    8000433e:	fc240513          	addi	a0,s0,-62
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	ab2080e7          	jalr	-1358(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000434a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000434e:	4741                	li	a4,16
    80004350:	86a6                	mv	a3,s1
    80004352:	fc040613          	addi	a2,s0,-64
    80004356:	4581                	li	a1,0
    80004358:	854a                	mv	a0,s2
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	c44080e7          	jalr	-956(ra) # 80003f9e <writei>
    80004362:	872a                	mv	a4,a0
    80004364:	47c1                	li	a5,16
  return 0;
    80004366:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004368:	02f71863          	bne	a4,a5,80004398 <dirlink+0xb2>
}
    8000436c:	70e2                	ld	ra,56(sp)
    8000436e:	7442                	ld	s0,48(sp)
    80004370:	74a2                	ld	s1,40(sp)
    80004372:	7902                	ld	s2,32(sp)
    80004374:	69e2                	ld	s3,24(sp)
    80004376:	6a42                	ld	s4,16(sp)
    80004378:	6121                	addi	sp,sp,64
    8000437a:	8082                	ret
    iput(ip);
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	a30080e7          	jalr	-1488(ra) # 80003dac <iput>
    return -1;
    80004384:	557d                	li	a0,-1
    80004386:	b7dd                	j	8000436c <dirlink+0x86>
      panic("dirlink read");
    80004388:	00004517          	auipc	a0,0x4
    8000438c:	39050513          	addi	a0,a0,912 # 80008718 <syscalls+0x1e0>
    80004390:	ffffc097          	auipc	ra,0xffffc
    80004394:	1ae080e7          	jalr	430(ra) # 8000053e <panic>
    panic("dirlink");
    80004398:	00004517          	auipc	a0,0x4
    8000439c:	48850513          	addi	a0,a0,1160 # 80008820 <syscalls+0x2e8>
    800043a0:	ffffc097          	auipc	ra,0xffffc
    800043a4:	19e080e7          	jalr	414(ra) # 8000053e <panic>

00000000800043a8 <namei>:

struct inode*
namei(char *path)
{
    800043a8:	1101                	addi	sp,sp,-32
    800043aa:	ec06                	sd	ra,24(sp)
    800043ac:	e822                	sd	s0,16(sp)
    800043ae:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043b0:	fe040613          	addi	a2,s0,-32
    800043b4:	4581                	li	a1,0
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	dd0080e7          	jalr	-560(ra) # 80004186 <namex>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043c6:	1141                	addi	sp,sp,-16
    800043c8:	e406                	sd	ra,8(sp)
    800043ca:	e022                	sd	s0,0(sp)
    800043cc:	0800                	addi	s0,sp,16
    800043ce:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043d0:	4585                	li	a1,1
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	db4080e7          	jalr	-588(ra) # 80004186 <namex>
}
    800043da:	60a2                	ld	ra,8(sp)
    800043dc:	6402                	ld	s0,0(sp)
    800043de:	0141                	addi	sp,sp,16
    800043e0:	8082                	ret

00000000800043e2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	e426                	sd	s1,8(sp)
    800043ea:	e04a                	sd	s2,0(sp)
    800043ec:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043ee:	0001f917          	auipc	s2,0x1f
    800043f2:	cfa90913          	addi	s2,s2,-774 # 800230e8 <log>
    800043f6:	01892583          	lw	a1,24(s2)
    800043fa:	02892503          	lw	a0,40(s2)
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	ff2080e7          	jalr	-14(ra) # 800033f0 <bread>
    80004406:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004408:	02c92683          	lw	a3,44(s2)
    8000440c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000440e:	02d05763          	blez	a3,8000443c <write_head+0x5a>
    80004412:	0001f797          	auipc	a5,0x1f
    80004416:	d0678793          	addi	a5,a5,-762 # 80023118 <log+0x30>
    8000441a:	05c50713          	addi	a4,a0,92
    8000441e:	36fd                	addiw	a3,a3,-1
    80004420:	1682                	slli	a3,a3,0x20
    80004422:	9281                	srli	a3,a3,0x20
    80004424:	068a                	slli	a3,a3,0x2
    80004426:	0001f617          	auipc	a2,0x1f
    8000442a:	cf660613          	addi	a2,a2,-778 # 8002311c <log+0x34>
    8000442e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004430:	4390                	lw	a2,0(a5)
    80004432:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004434:	0791                	addi	a5,a5,4
    80004436:	0711                	addi	a4,a4,4
    80004438:	fed79ce3          	bne	a5,a3,80004430 <write_head+0x4e>
  }
  bwrite(buf);
    8000443c:	8526                	mv	a0,s1
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	0a4080e7          	jalr	164(ra) # 800034e2 <bwrite>
  brelse(buf);
    80004446:	8526                	mv	a0,s1
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	0d8080e7          	jalr	216(ra) # 80003520 <brelse>
}
    80004450:	60e2                	ld	ra,24(sp)
    80004452:	6442                	ld	s0,16(sp)
    80004454:	64a2                	ld	s1,8(sp)
    80004456:	6902                	ld	s2,0(sp)
    80004458:	6105                	addi	sp,sp,32
    8000445a:	8082                	ret

000000008000445c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000445c:	0001f797          	auipc	a5,0x1f
    80004460:	cb87a783          	lw	a5,-840(a5) # 80023114 <log+0x2c>
    80004464:	0af05d63          	blez	a5,8000451e <install_trans+0xc2>
{
    80004468:	7139                	addi	sp,sp,-64
    8000446a:	fc06                	sd	ra,56(sp)
    8000446c:	f822                	sd	s0,48(sp)
    8000446e:	f426                	sd	s1,40(sp)
    80004470:	f04a                	sd	s2,32(sp)
    80004472:	ec4e                	sd	s3,24(sp)
    80004474:	e852                	sd	s4,16(sp)
    80004476:	e456                	sd	s5,8(sp)
    80004478:	e05a                	sd	s6,0(sp)
    8000447a:	0080                	addi	s0,sp,64
    8000447c:	8b2a                	mv	s6,a0
    8000447e:	0001fa97          	auipc	s5,0x1f
    80004482:	c9aa8a93          	addi	s5,s5,-870 # 80023118 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004486:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004488:	0001f997          	auipc	s3,0x1f
    8000448c:	c6098993          	addi	s3,s3,-928 # 800230e8 <log>
    80004490:	a035                	j	800044bc <install_trans+0x60>
      bunpin(dbuf);
    80004492:	8526                	mv	a0,s1
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	166080e7          	jalr	358(ra) # 800035fa <bunpin>
    brelse(lbuf);
    8000449c:	854a                	mv	a0,s2
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	082080e7          	jalr	130(ra) # 80003520 <brelse>
    brelse(dbuf);
    800044a6:	8526                	mv	a0,s1
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	078080e7          	jalr	120(ra) # 80003520 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b0:	2a05                	addiw	s4,s4,1
    800044b2:	0a91                	addi	s5,s5,4
    800044b4:	02c9a783          	lw	a5,44(s3)
    800044b8:	04fa5963          	bge	s4,a5,8000450a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044bc:	0189a583          	lw	a1,24(s3)
    800044c0:	014585bb          	addw	a1,a1,s4
    800044c4:	2585                	addiw	a1,a1,1
    800044c6:	0289a503          	lw	a0,40(s3)
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	f26080e7          	jalr	-218(ra) # 800033f0 <bread>
    800044d2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044d4:	000aa583          	lw	a1,0(s5)
    800044d8:	0289a503          	lw	a0,40(s3)
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	f14080e7          	jalr	-236(ra) # 800033f0 <bread>
    800044e4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044e6:	40000613          	li	a2,1024
    800044ea:	05890593          	addi	a1,s2,88
    800044ee:	05850513          	addi	a0,a0,88
    800044f2:	ffffd097          	auipc	ra,0xffffd
    800044f6:	84e080e7          	jalr	-1970(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044fa:	8526                	mv	a0,s1
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	fe6080e7          	jalr	-26(ra) # 800034e2 <bwrite>
    if(recovering == 0)
    80004504:	f80b1ce3          	bnez	s6,8000449c <install_trans+0x40>
    80004508:	b769                	j	80004492 <install_trans+0x36>
}
    8000450a:	70e2                	ld	ra,56(sp)
    8000450c:	7442                	ld	s0,48(sp)
    8000450e:	74a2                	ld	s1,40(sp)
    80004510:	7902                	ld	s2,32(sp)
    80004512:	69e2                	ld	s3,24(sp)
    80004514:	6a42                	ld	s4,16(sp)
    80004516:	6aa2                	ld	s5,8(sp)
    80004518:	6b02                	ld	s6,0(sp)
    8000451a:	6121                	addi	sp,sp,64
    8000451c:	8082                	ret
    8000451e:	8082                	ret

0000000080004520 <initlog>:
{
    80004520:	7179                	addi	sp,sp,-48
    80004522:	f406                	sd	ra,40(sp)
    80004524:	f022                	sd	s0,32(sp)
    80004526:	ec26                	sd	s1,24(sp)
    80004528:	e84a                	sd	s2,16(sp)
    8000452a:	e44e                	sd	s3,8(sp)
    8000452c:	1800                	addi	s0,sp,48
    8000452e:	892a                	mv	s2,a0
    80004530:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004532:	0001f497          	auipc	s1,0x1f
    80004536:	bb648493          	addi	s1,s1,-1098 # 800230e8 <log>
    8000453a:	00004597          	auipc	a1,0x4
    8000453e:	1ee58593          	addi	a1,a1,494 # 80008728 <syscalls+0x1f0>
    80004542:	8526                	mv	a0,s1
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	610080e7          	jalr	1552(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000454c:	0149a583          	lw	a1,20(s3)
    80004550:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004552:	0109a783          	lw	a5,16(s3)
    80004556:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004558:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000455c:	854a                	mv	a0,s2
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	e92080e7          	jalr	-366(ra) # 800033f0 <bread>
  log.lh.n = lh->n;
    80004566:	4d3c                	lw	a5,88(a0)
    80004568:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	02f05563          	blez	a5,80004594 <initlog+0x74>
    8000456e:	05c50713          	addi	a4,a0,92
    80004572:	0001f697          	auipc	a3,0x1f
    80004576:	ba668693          	addi	a3,a3,-1114 # 80023118 <log+0x30>
    8000457a:	37fd                	addiw	a5,a5,-1
    8000457c:	1782                	slli	a5,a5,0x20
    8000457e:	9381                	srli	a5,a5,0x20
    80004580:	078a                	slli	a5,a5,0x2
    80004582:	06050613          	addi	a2,a0,96
    80004586:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004588:	4310                	lw	a2,0(a4)
    8000458a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000458c:	0711                	addi	a4,a4,4
    8000458e:	0691                	addi	a3,a3,4
    80004590:	fef71ce3          	bne	a4,a5,80004588 <initlog+0x68>
  brelse(buf);
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	f8c080e7          	jalr	-116(ra) # 80003520 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000459c:	4505                	li	a0,1
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	ebe080e7          	jalr	-322(ra) # 8000445c <install_trans>
  log.lh.n = 0;
    800045a6:	0001f797          	auipc	a5,0x1f
    800045aa:	b607a723          	sw	zero,-1170(a5) # 80023114 <log+0x2c>
  write_head(); // clear the log
    800045ae:	00000097          	auipc	ra,0x0
    800045b2:	e34080e7          	jalr	-460(ra) # 800043e2 <write_head>
}
    800045b6:	70a2                	ld	ra,40(sp)
    800045b8:	7402                	ld	s0,32(sp)
    800045ba:	64e2                	ld	s1,24(sp)
    800045bc:	6942                	ld	s2,16(sp)
    800045be:	69a2                	ld	s3,8(sp)
    800045c0:	6145                	addi	sp,sp,48
    800045c2:	8082                	ret

00000000800045c4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045c4:	1101                	addi	sp,sp,-32
    800045c6:	ec06                	sd	ra,24(sp)
    800045c8:	e822                	sd	s0,16(sp)
    800045ca:	e426                	sd	s1,8(sp)
    800045cc:	e04a                	sd	s2,0(sp)
    800045ce:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045d0:	0001f517          	auipc	a0,0x1f
    800045d4:	b1850513          	addi	a0,a0,-1256 # 800230e8 <log>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	60c080e7          	jalr	1548(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045e0:	0001f497          	auipc	s1,0x1f
    800045e4:	b0848493          	addi	s1,s1,-1272 # 800230e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045e8:	4979                	li	s2,30
    800045ea:	a039                	j	800045f8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045ec:	85a6                	mv	a1,s1
    800045ee:	8526                	mv	a0,s1
    800045f0:	ffffe097          	auipc	ra,0xffffe
    800045f4:	c92080e7          	jalr	-878(ra) # 80002282 <sleep>
    if(log.committing){
    800045f8:	50dc                	lw	a5,36(s1)
    800045fa:	fbed                	bnez	a5,800045ec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045fc:	509c                	lw	a5,32(s1)
    800045fe:	0017871b          	addiw	a4,a5,1
    80004602:	0007069b          	sext.w	a3,a4
    80004606:	0027179b          	slliw	a5,a4,0x2
    8000460a:	9fb9                	addw	a5,a5,a4
    8000460c:	0017979b          	slliw	a5,a5,0x1
    80004610:	54d8                	lw	a4,44(s1)
    80004612:	9fb9                	addw	a5,a5,a4
    80004614:	00f95963          	bge	s2,a5,80004626 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004618:	85a6                	mv	a1,s1
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffe097          	auipc	ra,0xffffe
    80004620:	c66080e7          	jalr	-922(ra) # 80002282 <sleep>
    80004624:	bfd1                	j	800045f8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004626:	0001f517          	auipc	a0,0x1f
    8000462a:	ac250513          	addi	a0,a0,-1342 # 800230e8 <log>
    8000462e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	668080e7          	jalr	1640(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004638:	60e2                	ld	ra,24(sp)
    8000463a:	6442                	ld	s0,16(sp)
    8000463c:	64a2                	ld	s1,8(sp)
    8000463e:	6902                	ld	s2,0(sp)
    80004640:	6105                	addi	sp,sp,32
    80004642:	8082                	ret

0000000080004644 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004644:	7139                	addi	sp,sp,-64
    80004646:	fc06                	sd	ra,56(sp)
    80004648:	f822                	sd	s0,48(sp)
    8000464a:	f426                	sd	s1,40(sp)
    8000464c:	f04a                	sd	s2,32(sp)
    8000464e:	ec4e                	sd	s3,24(sp)
    80004650:	e852                	sd	s4,16(sp)
    80004652:	e456                	sd	s5,8(sp)
    80004654:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004656:	0001f497          	auipc	s1,0x1f
    8000465a:	a9248493          	addi	s1,s1,-1390 # 800230e8 <log>
    8000465e:	8526                	mv	a0,s1
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	584080e7          	jalr	1412(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004668:	509c                	lw	a5,32(s1)
    8000466a:	37fd                	addiw	a5,a5,-1
    8000466c:	0007891b          	sext.w	s2,a5
    80004670:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004672:	50dc                	lw	a5,36(s1)
    80004674:	efb9                	bnez	a5,800046d2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004676:	06091663          	bnez	s2,800046e2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000467a:	0001f497          	auipc	s1,0x1f
    8000467e:	a6e48493          	addi	s1,s1,-1426 # 800230e8 <log>
    80004682:	4785                	li	a5,1
    80004684:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004686:	8526                	mv	a0,s1
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	610080e7          	jalr	1552(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004690:	54dc                	lw	a5,44(s1)
    80004692:	06f04763          	bgtz	a5,80004700 <end_op+0xbc>
    acquire(&log.lock);
    80004696:	0001f497          	auipc	s1,0x1f
    8000469a:	a5248493          	addi	s1,s1,-1454 # 800230e8 <log>
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	544080e7          	jalr	1348(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046a8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046ac:	8526                	mv	a0,s1
    800046ae:	ffffe097          	auipc	ra,0xffffe
    800046b2:	eac080e7          	jalr	-340(ra) # 8000255a <wakeup>
    release(&log.lock);
    800046b6:	8526                	mv	a0,s1
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	5e0080e7          	jalr	1504(ra) # 80000c98 <release>
}
    800046c0:	70e2                	ld	ra,56(sp)
    800046c2:	7442                	ld	s0,48(sp)
    800046c4:	74a2                	ld	s1,40(sp)
    800046c6:	7902                	ld	s2,32(sp)
    800046c8:	69e2                	ld	s3,24(sp)
    800046ca:	6a42                	ld	s4,16(sp)
    800046cc:	6aa2                	ld	s5,8(sp)
    800046ce:	6121                	addi	sp,sp,64
    800046d0:	8082                	ret
    panic("log.committing");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	05e50513          	addi	a0,a0,94 # 80008730 <syscalls+0x1f8>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>
    wakeup(&log);
    800046e2:	0001f497          	auipc	s1,0x1f
    800046e6:	a0648493          	addi	s1,s1,-1530 # 800230e8 <log>
    800046ea:	8526                	mv	a0,s1
    800046ec:	ffffe097          	auipc	ra,0xffffe
    800046f0:	e6e080e7          	jalr	-402(ra) # 8000255a <wakeup>
  release(&log.lock);
    800046f4:	8526                	mv	a0,s1
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	5a2080e7          	jalr	1442(ra) # 80000c98 <release>
  if(do_commit){
    800046fe:	b7c9                	j	800046c0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004700:	0001fa97          	auipc	s5,0x1f
    80004704:	a18a8a93          	addi	s5,s5,-1512 # 80023118 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004708:	0001fa17          	auipc	s4,0x1f
    8000470c:	9e0a0a13          	addi	s4,s4,-1568 # 800230e8 <log>
    80004710:	018a2583          	lw	a1,24(s4)
    80004714:	012585bb          	addw	a1,a1,s2
    80004718:	2585                	addiw	a1,a1,1
    8000471a:	028a2503          	lw	a0,40(s4)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	cd2080e7          	jalr	-814(ra) # 800033f0 <bread>
    80004726:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004728:	000aa583          	lw	a1,0(s5)
    8000472c:	028a2503          	lw	a0,40(s4)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	cc0080e7          	jalr	-832(ra) # 800033f0 <bread>
    80004738:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000473a:	40000613          	li	a2,1024
    8000473e:	05850593          	addi	a1,a0,88
    80004742:	05848513          	addi	a0,s1,88
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	5fa080e7          	jalr	1530(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000474e:	8526                	mv	a0,s1
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	d92080e7          	jalr	-622(ra) # 800034e2 <bwrite>
    brelse(from);
    80004758:	854e                	mv	a0,s3
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	dc6080e7          	jalr	-570(ra) # 80003520 <brelse>
    brelse(to);
    80004762:	8526                	mv	a0,s1
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	dbc080e7          	jalr	-580(ra) # 80003520 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476c:	2905                	addiw	s2,s2,1
    8000476e:	0a91                	addi	s5,s5,4
    80004770:	02ca2783          	lw	a5,44(s4)
    80004774:	f8f94ee3          	blt	s2,a5,80004710 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	c6a080e7          	jalr	-918(ra) # 800043e2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004780:	4501                	li	a0,0
    80004782:	00000097          	auipc	ra,0x0
    80004786:	cda080e7          	jalr	-806(ra) # 8000445c <install_trans>
    log.lh.n = 0;
    8000478a:	0001f797          	auipc	a5,0x1f
    8000478e:	9807a523          	sw	zero,-1654(a5) # 80023114 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004792:	00000097          	auipc	ra,0x0
    80004796:	c50080e7          	jalr	-944(ra) # 800043e2 <write_head>
    8000479a:	bdf5                	j	80004696 <end_op+0x52>

000000008000479c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000479c:	1101                	addi	sp,sp,-32
    8000479e:	ec06                	sd	ra,24(sp)
    800047a0:	e822                	sd	s0,16(sp)
    800047a2:	e426                	sd	s1,8(sp)
    800047a4:	e04a                	sd	s2,0(sp)
    800047a6:	1000                	addi	s0,sp,32
    800047a8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047aa:	0001f917          	auipc	s2,0x1f
    800047ae:	93e90913          	addi	s2,s2,-1730 # 800230e8 <log>
    800047b2:	854a                	mv	a0,s2
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	430080e7          	jalr	1072(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047bc:	02c92603          	lw	a2,44(s2)
    800047c0:	47f5                	li	a5,29
    800047c2:	06c7c563          	blt	a5,a2,8000482c <log_write+0x90>
    800047c6:	0001f797          	auipc	a5,0x1f
    800047ca:	93e7a783          	lw	a5,-1730(a5) # 80023104 <log+0x1c>
    800047ce:	37fd                	addiw	a5,a5,-1
    800047d0:	04f65e63          	bge	a2,a5,8000482c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047d4:	0001f797          	auipc	a5,0x1f
    800047d8:	9347a783          	lw	a5,-1740(a5) # 80023108 <log+0x20>
    800047dc:	06f05063          	blez	a5,8000483c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047e0:	4781                	li	a5,0
    800047e2:	06c05563          	blez	a2,8000484c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047e6:	44cc                	lw	a1,12(s1)
    800047e8:	0001f717          	auipc	a4,0x1f
    800047ec:	93070713          	addi	a4,a4,-1744 # 80023118 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047f0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047f2:	4314                	lw	a3,0(a4)
    800047f4:	04b68c63          	beq	a3,a1,8000484c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047f8:	2785                	addiw	a5,a5,1
    800047fa:	0711                	addi	a4,a4,4
    800047fc:	fef61be3          	bne	a2,a5,800047f2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004800:	0621                	addi	a2,a2,8
    80004802:	060a                	slli	a2,a2,0x2
    80004804:	0001f797          	auipc	a5,0x1f
    80004808:	8e478793          	addi	a5,a5,-1820 # 800230e8 <log>
    8000480c:	963e                	add	a2,a2,a5
    8000480e:	44dc                	lw	a5,12(s1)
    80004810:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004812:	8526                	mv	a0,s1
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	daa080e7          	jalr	-598(ra) # 800035be <bpin>
    log.lh.n++;
    8000481c:	0001f717          	auipc	a4,0x1f
    80004820:	8cc70713          	addi	a4,a4,-1844 # 800230e8 <log>
    80004824:	575c                	lw	a5,44(a4)
    80004826:	2785                	addiw	a5,a5,1
    80004828:	d75c                	sw	a5,44(a4)
    8000482a:	a835                	j	80004866 <log_write+0xca>
    panic("too big a transaction");
    8000482c:	00004517          	auipc	a0,0x4
    80004830:	f1450513          	addi	a0,a0,-236 # 80008740 <syscalls+0x208>
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	d0a080e7          	jalr	-758(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	f1c50513          	addi	a0,a0,-228 # 80008758 <syscalls+0x220>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	cfa080e7          	jalr	-774(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000484c:	00878713          	addi	a4,a5,8
    80004850:	00271693          	slli	a3,a4,0x2
    80004854:	0001f717          	auipc	a4,0x1f
    80004858:	89470713          	addi	a4,a4,-1900 # 800230e8 <log>
    8000485c:	9736                	add	a4,a4,a3
    8000485e:	44d4                	lw	a3,12(s1)
    80004860:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004862:	faf608e3          	beq	a2,a5,80004812 <log_write+0x76>
  }
  release(&log.lock);
    80004866:	0001f517          	auipc	a0,0x1f
    8000486a:	88250513          	addi	a0,a0,-1918 # 800230e8 <log>
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	42a080e7          	jalr	1066(ra) # 80000c98 <release>
}
    80004876:	60e2                	ld	ra,24(sp)
    80004878:	6442                	ld	s0,16(sp)
    8000487a:	64a2                	ld	s1,8(sp)
    8000487c:	6902                	ld	s2,0(sp)
    8000487e:	6105                	addi	sp,sp,32
    80004880:	8082                	ret

0000000080004882 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004882:	1101                	addi	sp,sp,-32
    80004884:	ec06                	sd	ra,24(sp)
    80004886:	e822                	sd	s0,16(sp)
    80004888:	e426                	sd	s1,8(sp)
    8000488a:	e04a                	sd	s2,0(sp)
    8000488c:	1000                	addi	s0,sp,32
    8000488e:	84aa                	mv	s1,a0
    80004890:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004892:	00004597          	auipc	a1,0x4
    80004896:	ee658593          	addi	a1,a1,-282 # 80008778 <syscalls+0x240>
    8000489a:	0521                	addi	a0,a0,8
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	2b8080e7          	jalr	696(ra) # 80000b54 <initlock>
  lk->name = name;
    800048a4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ac:	0204a423          	sw	zero,40(s1)
}
    800048b0:	60e2                	ld	ra,24(sp)
    800048b2:	6442                	ld	s0,16(sp)
    800048b4:	64a2                	ld	s1,8(sp)
    800048b6:	6902                	ld	s2,0(sp)
    800048b8:	6105                	addi	sp,sp,32
    800048ba:	8082                	ret

00000000800048bc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048bc:	1101                	addi	sp,sp,-32
    800048be:	ec06                	sd	ra,24(sp)
    800048c0:	e822                	sd	s0,16(sp)
    800048c2:	e426                	sd	s1,8(sp)
    800048c4:	e04a                	sd	s2,0(sp)
    800048c6:	1000                	addi	s0,sp,32
    800048c8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ca:	00850913          	addi	s2,a0,8
    800048ce:	854a                	mv	a0,s2
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	314080e7          	jalr	788(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048d8:	409c                	lw	a5,0(s1)
    800048da:	cb89                	beqz	a5,800048ec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048dc:	85ca                	mv	a1,s2
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffe097          	auipc	ra,0xffffe
    800048e4:	9a2080e7          	jalr	-1630(ra) # 80002282 <sleep>
  while (lk->locked) {
    800048e8:	409c                	lw	a5,0(s1)
    800048ea:	fbed                	bnez	a5,800048dc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048ec:	4785                	li	a5,1
    800048ee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048f0:	ffffd097          	auipc	ra,0xffffd
    800048f4:	1e6080e7          	jalr	486(ra) # 80001ad6 <myproc>
    800048f8:	591c                	lw	a5,48(a0)
    800048fa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048fc:	854a                	mv	a0,s2
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	39a080e7          	jalr	922(ra) # 80000c98 <release>
}
    80004906:	60e2                	ld	ra,24(sp)
    80004908:	6442                	ld	s0,16(sp)
    8000490a:	64a2                	ld	s1,8(sp)
    8000490c:	6902                	ld	s2,0(sp)
    8000490e:	6105                	addi	sp,sp,32
    80004910:	8082                	ret

0000000080004912 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004912:	1101                	addi	sp,sp,-32
    80004914:	ec06                	sd	ra,24(sp)
    80004916:	e822                	sd	s0,16(sp)
    80004918:	e426                	sd	s1,8(sp)
    8000491a:	e04a                	sd	s2,0(sp)
    8000491c:	1000                	addi	s0,sp,32
    8000491e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004920:	00850913          	addi	s2,a0,8
    80004924:	854a                	mv	a0,s2
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	2be080e7          	jalr	702(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000492e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004932:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffe097          	auipc	ra,0xffffe
    8000493c:	c22080e7          	jalr	-990(ra) # 8000255a <wakeup>
  release(&lk->lk);
    80004940:	854a                	mv	a0,s2
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	356080e7          	jalr	854(ra) # 80000c98 <release>
}
    8000494a:	60e2                	ld	ra,24(sp)
    8000494c:	6442                	ld	s0,16(sp)
    8000494e:	64a2                	ld	s1,8(sp)
    80004950:	6902                	ld	s2,0(sp)
    80004952:	6105                	addi	sp,sp,32
    80004954:	8082                	ret

0000000080004956 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004956:	7179                	addi	sp,sp,-48
    80004958:	f406                	sd	ra,40(sp)
    8000495a:	f022                	sd	s0,32(sp)
    8000495c:	ec26                	sd	s1,24(sp)
    8000495e:	e84a                	sd	s2,16(sp)
    80004960:	e44e                	sd	s3,8(sp)
    80004962:	1800                	addi	s0,sp,48
    80004964:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004966:	00850913          	addi	s2,a0,8
    8000496a:	854a                	mv	a0,s2
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	278080e7          	jalr	632(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004974:	409c                	lw	a5,0(s1)
    80004976:	ef99                	bnez	a5,80004994 <holdingsleep+0x3e>
    80004978:	4481                	li	s1,0
  release(&lk->lk);
    8000497a:	854a                	mv	a0,s2
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	31c080e7          	jalr	796(ra) # 80000c98 <release>
  return r;
}
    80004984:	8526                	mv	a0,s1
    80004986:	70a2                	ld	ra,40(sp)
    80004988:	7402                	ld	s0,32(sp)
    8000498a:	64e2                	ld	s1,24(sp)
    8000498c:	6942                	ld	s2,16(sp)
    8000498e:	69a2                	ld	s3,8(sp)
    80004990:	6145                	addi	sp,sp,48
    80004992:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004994:	0284a983          	lw	s3,40(s1)
    80004998:	ffffd097          	auipc	ra,0xffffd
    8000499c:	13e080e7          	jalr	318(ra) # 80001ad6 <myproc>
    800049a0:	5904                	lw	s1,48(a0)
    800049a2:	413484b3          	sub	s1,s1,s3
    800049a6:	0014b493          	seqz	s1,s1
    800049aa:	bfc1                	j	8000497a <holdingsleep+0x24>

00000000800049ac <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049ac:	1141                	addi	sp,sp,-16
    800049ae:	e406                	sd	ra,8(sp)
    800049b0:	e022                	sd	s0,0(sp)
    800049b2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049b4:	00004597          	auipc	a1,0x4
    800049b8:	dd458593          	addi	a1,a1,-556 # 80008788 <syscalls+0x250>
    800049bc:	0001f517          	auipc	a0,0x1f
    800049c0:	87450513          	addi	a0,a0,-1932 # 80023230 <ftable>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	190080e7          	jalr	400(ra) # 80000b54 <initlock>
}
    800049cc:	60a2                	ld	ra,8(sp)
    800049ce:	6402                	ld	s0,0(sp)
    800049d0:	0141                	addi	sp,sp,16
    800049d2:	8082                	ret

00000000800049d4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049d4:	1101                	addi	sp,sp,-32
    800049d6:	ec06                	sd	ra,24(sp)
    800049d8:	e822                	sd	s0,16(sp)
    800049da:	e426                	sd	s1,8(sp)
    800049dc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049de:	0001f517          	auipc	a0,0x1f
    800049e2:	85250513          	addi	a0,a0,-1966 # 80023230 <ftable>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	1fe080e7          	jalr	510(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049ee:	0001f497          	auipc	s1,0x1f
    800049f2:	85a48493          	addi	s1,s1,-1958 # 80023248 <ftable+0x18>
    800049f6:	0001f717          	auipc	a4,0x1f
    800049fa:	7f270713          	addi	a4,a4,2034 # 800241e8 <ftable+0xfb8>
    if(f->ref == 0){
    800049fe:	40dc                	lw	a5,4(s1)
    80004a00:	cf99                	beqz	a5,80004a1e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a02:	02848493          	addi	s1,s1,40
    80004a06:	fee49ce3          	bne	s1,a4,800049fe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a0a:	0001f517          	auipc	a0,0x1f
    80004a0e:	82650513          	addi	a0,a0,-2010 # 80023230 <ftable>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
  return 0;
    80004a1a:	4481                	li	s1,0
    80004a1c:	a819                	j	80004a32 <filealloc+0x5e>
      f->ref = 1;
    80004a1e:	4785                	li	a5,1
    80004a20:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a22:	0001f517          	auipc	a0,0x1f
    80004a26:	80e50513          	addi	a0,a0,-2034 # 80023230 <ftable>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	26e080e7          	jalr	622(ra) # 80000c98 <release>
}
    80004a32:	8526                	mv	a0,s1
    80004a34:	60e2                	ld	ra,24(sp)
    80004a36:	6442                	ld	s0,16(sp)
    80004a38:	64a2                	ld	s1,8(sp)
    80004a3a:	6105                	addi	sp,sp,32
    80004a3c:	8082                	ret

0000000080004a3e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a3e:	1101                	addi	sp,sp,-32
    80004a40:	ec06                	sd	ra,24(sp)
    80004a42:	e822                	sd	s0,16(sp)
    80004a44:	e426                	sd	s1,8(sp)
    80004a46:	1000                	addi	s0,sp,32
    80004a48:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a4a:	0001e517          	auipc	a0,0x1e
    80004a4e:	7e650513          	addi	a0,a0,2022 # 80023230 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	192080e7          	jalr	402(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a5a:	40dc                	lw	a5,4(s1)
    80004a5c:	02f05263          	blez	a5,80004a80 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a60:	2785                	addiw	a5,a5,1
    80004a62:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a64:	0001e517          	auipc	a0,0x1e
    80004a68:	7cc50513          	addi	a0,a0,1996 # 80023230 <ftable>
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	22c080e7          	jalr	556(ra) # 80000c98 <release>
  return f;
}
    80004a74:	8526                	mv	a0,s1
    80004a76:	60e2                	ld	ra,24(sp)
    80004a78:	6442                	ld	s0,16(sp)
    80004a7a:	64a2                	ld	s1,8(sp)
    80004a7c:	6105                	addi	sp,sp,32
    80004a7e:	8082                	ret
    panic("filedup");
    80004a80:	00004517          	auipc	a0,0x4
    80004a84:	d1050513          	addi	a0,a0,-752 # 80008790 <syscalls+0x258>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>

0000000080004a90 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a90:	7139                	addi	sp,sp,-64
    80004a92:	fc06                	sd	ra,56(sp)
    80004a94:	f822                	sd	s0,48(sp)
    80004a96:	f426                	sd	s1,40(sp)
    80004a98:	f04a                	sd	s2,32(sp)
    80004a9a:	ec4e                	sd	s3,24(sp)
    80004a9c:	e852                	sd	s4,16(sp)
    80004a9e:	e456                	sd	s5,8(sp)
    80004aa0:	0080                	addi	s0,sp,64
    80004aa2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004aa4:	0001e517          	auipc	a0,0x1e
    80004aa8:	78c50513          	addi	a0,a0,1932 # 80023230 <ftable>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	138080e7          	jalr	312(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ab4:	40dc                	lw	a5,4(s1)
    80004ab6:	06f05163          	blez	a5,80004b18 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aba:	37fd                	addiw	a5,a5,-1
    80004abc:	0007871b          	sext.w	a4,a5
    80004ac0:	c0dc                	sw	a5,4(s1)
    80004ac2:	06e04363          	bgtz	a4,80004b28 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ac6:	0004a903          	lw	s2,0(s1)
    80004aca:	0094ca83          	lbu	s5,9(s1)
    80004ace:	0104ba03          	ld	s4,16(s1)
    80004ad2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ad6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ada:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ade:	0001e517          	auipc	a0,0x1e
    80004ae2:	75250513          	addi	a0,a0,1874 # 80023230 <ftable>
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	1b2080e7          	jalr	434(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004aee:	4785                	li	a5,1
    80004af0:	04f90d63          	beq	s2,a5,80004b4a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004af4:	3979                	addiw	s2,s2,-2
    80004af6:	4785                	li	a5,1
    80004af8:	0527e063          	bltu	a5,s2,80004b38 <fileclose+0xa8>
    begin_op();
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	ac8080e7          	jalr	-1336(ra) # 800045c4 <begin_op>
    iput(ff.ip);
    80004b04:	854e                	mv	a0,s3
    80004b06:	fffff097          	auipc	ra,0xfffff
    80004b0a:	2a6080e7          	jalr	678(ra) # 80003dac <iput>
    end_op();
    80004b0e:	00000097          	auipc	ra,0x0
    80004b12:	b36080e7          	jalr	-1226(ra) # 80004644 <end_op>
    80004b16:	a00d                	j	80004b38 <fileclose+0xa8>
    panic("fileclose");
    80004b18:	00004517          	auipc	a0,0x4
    80004b1c:	c8050513          	addi	a0,a0,-896 # 80008798 <syscalls+0x260>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	a1e080e7          	jalr	-1506(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b28:	0001e517          	auipc	a0,0x1e
    80004b2c:	70850513          	addi	a0,a0,1800 # 80023230 <ftable>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	168080e7          	jalr	360(ra) # 80000c98 <release>
  }
}
    80004b38:	70e2                	ld	ra,56(sp)
    80004b3a:	7442                	ld	s0,48(sp)
    80004b3c:	74a2                	ld	s1,40(sp)
    80004b3e:	7902                	ld	s2,32(sp)
    80004b40:	69e2                	ld	s3,24(sp)
    80004b42:	6a42                	ld	s4,16(sp)
    80004b44:	6aa2                	ld	s5,8(sp)
    80004b46:	6121                	addi	sp,sp,64
    80004b48:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b4a:	85d6                	mv	a1,s5
    80004b4c:	8552                	mv	a0,s4
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	34c080e7          	jalr	844(ra) # 80004e9a <pipeclose>
    80004b56:	b7cd                	j	80004b38 <fileclose+0xa8>

0000000080004b58 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b58:	715d                	addi	sp,sp,-80
    80004b5a:	e486                	sd	ra,72(sp)
    80004b5c:	e0a2                	sd	s0,64(sp)
    80004b5e:	fc26                	sd	s1,56(sp)
    80004b60:	f84a                	sd	s2,48(sp)
    80004b62:	f44e                	sd	s3,40(sp)
    80004b64:	0880                	addi	s0,sp,80
    80004b66:	84aa                	mv	s1,a0
    80004b68:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	f6c080e7          	jalr	-148(ra) # 80001ad6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b72:	409c                	lw	a5,0(s1)
    80004b74:	37f9                	addiw	a5,a5,-2
    80004b76:	4705                	li	a4,1
    80004b78:	04f76763          	bltu	a4,a5,80004bc6 <filestat+0x6e>
    80004b7c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b7e:	6c88                	ld	a0,24(s1)
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	072080e7          	jalr	114(ra) # 80003bf2 <ilock>
    stati(f->ip, &st);
    80004b88:	fb840593          	addi	a1,s0,-72
    80004b8c:	6c88                	ld	a0,24(s1)
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	2ee080e7          	jalr	750(ra) # 80003e7c <stati>
    iunlock(f->ip);
    80004b96:	6c88                	ld	a0,24(s1)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	11c080e7          	jalr	284(ra) # 80003cb4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ba0:	46e1                	li	a3,24
    80004ba2:	fb840613          	addi	a2,s0,-72
    80004ba6:	85ce                	mv	a1,s3
    80004ba8:	05093503          	ld	a0,80(s2)
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	ace080e7          	jalr	-1330(ra) # 8000167a <copyout>
    80004bb4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bb8:	60a6                	ld	ra,72(sp)
    80004bba:	6406                	ld	s0,64(sp)
    80004bbc:	74e2                	ld	s1,56(sp)
    80004bbe:	7942                	ld	s2,48(sp)
    80004bc0:	79a2                	ld	s3,40(sp)
    80004bc2:	6161                	addi	sp,sp,80
    80004bc4:	8082                	ret
  return -1;
    80004bc6:	557d                	li	a0,-1
    80004bc8:	bfc5                	j	80004bb8 <filestat+0x60>

0000000080004bca <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bca:	7179                	addi	sp,sp,-48
    80004bcc:	f406                	sd	ra,40(sp)
    80004bce:	f022                	sd	s0,32(sp)
    80004bd0:	ec26                	sd	s1,24(sp)
    80004bd2:	e84a                	sd	s2,16(sp)
    80004bd4:	e44e                	sd	s3,8(sp)
    80004bd6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bd8:	00854783          	lbu	a5,8(a0)
    80004bdc:	c3d5                	beqz	a5,80004c80 <fileread+0xb6>
    80004bde:	84aa                	mv	s1,a0
    80004be0:	89ae                	mv	s3,a1
    80004be2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004be4:	411c                	lw	a5,0(a0)
    80004be6:	4705                	li	a4,1
    80004be8:	04e78963          	beq	a5,a4,80004c3a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bec:	470d                	li	a4,3
    80004bee:	04e78d63          	beq	a5,a4,80004c48 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bf2:	4709                	li	a4,2
    80004bf4:	06e79e63          	bne	a5,a4,80004c70 <fileread+0xa6>
    ilock(f->ip);
    80004bf8:	6d08                	ld	a0,24(a0)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	ff8080e7          	jalr	-8(ra) # 80003bf2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c02:	874a                	mv	a4,s2
    80004c04:	5094                	lw	a3,32(s1)
    80004c06:	864e                	mv	a2,s3
    80004c08:	4585                	li	a1,1
    80004c0a:	6c88                	ld	a0,24(s1)
    80004c0c:	fffff097          	auipc	ra,0xfffff
    80004c10:	29a080e7          	jalr	666(ra) # 80003ea6 <readi>
    80004c14:	892a                	mv	s2,a0
    80004c16:	00a05563          	blez	a0,80004c20 <fileread+0x56>
      f->off += r;
    80004c1a:	509c                	lw	a5,32(s1)
    80004c1c:	9fa9                	addw	a5,a5,a0
    80004c1e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c20:	6c88                	ld	a0,24(s1)
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	092080e7          	jalr	146(ra) # 80003cb4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c2a:	854a                	mv	a0,s2
    80004c2c:	70a2                	ld	ra,40(sp)
    80004c2e:	7402                	ld	s0,32(sp)
    80004c30:	64e2                	ld	s1,24(sp)
    80004c32:	6942                	ld	s2,16(sp)
    80004c34:	69a2                	ld	s3,8(sp)
    80004c36:	6145                	addi	sp,sp,48
    80004c38:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c3a:	6908                	ld	a0,16(a0)
    80004c3c:	00000097          	auipc	ra,0x0
    80004c40:	3c8080e7          	jalr	968(ra) # 80005004 <piperead>
    80004c44:	892a                	mv	s2,a0
    80004c46:	b7d5                	j	80004c2a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c48:	02451783          	lh	a5,36(a0)
    80004c4c:	03079693          	slli	a3,a5,0x30
    80004c50:	92c1                	srli	a3,a3,0x30
    80004c52:	4725                	li	a4,9
    80004c54:	02d76863          	bltu	a4,a3,80004c84 <fileread+0xba>
    80004c58:	0792                	slli	a5,a5,0x4
    80004c5a:	0001e717          	auipc	a4,0x1e
    80004c5e:	53670713          	addi	a4,a4,1334 # 80023190 <devsw>
    80004c62:	97ba                	add	a5,a5,a4
    80004c64:	639c                	ld	a5,0(a5)
    80004c66:	c38d                	beqz	a5,80004c88 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c68:	4505                	li	a0,1
    80004c6a:	9782                	jalr	a5
    80004c6c:	892a                	mv	s2,a0
    80004c6e:	bf75                	j	80004c2a <fileread+0x60>
    panic("fileread");
    80004c70:	00004517          	auipc	a0,0x4
    80004c74:	b3850513          	addi	a0,a0,-1224 # 800087a8 <syscalls+0x270>
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	8c6080e7          	jalr	-1850(ra) # 8000053e <panic>
    return -1;
    80004c80:	597d                	li	s2,-1
    80004c82:	b765                	j	80004c2a <fileread+0x60>
      return -1;
    80004c84:	597d                	li	s2,-1
    80004c86:	b755                	j	80004c2a <fileread+0x60>
    80004c88:	597d                	li	s2,-1
    80004c8a:	b745                	j	80004c2a <fileread+0x60>

0000000080004c8c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c8c:	715d                	addi	sp,sp,-80
    80004c8e:	e486                	sd	ra,72(sp)
    80004c90:	e0a2                	sd	s0,64(sp)
    80004c92:	fc26                	sd	s1,56(sp)
    80004c94:	f84a                	sd	s2,48(sp)
    80004c96:	f44e                	sd	s3,40(sp)
    80004c98:	f052                	sd	s4,32(sp)
    80004c9a:	ec56                	sd	s5,24(sp)
    80004c9c:	e85a                	sd	s6,16(sp)
    80004c9e:	e45e                	sd	s7,8(sp)
    80004ca0:	e062                	sd	s8,0(sp)
    80004ca2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ca4:	00954783          	lbu	a5,9(a0)
    80004ca8:	10078663          	beqz	a5,80004db4 <filewrite+0x128>
    80004cac:	892a                	mv	s2,a0
    80004cae:	8aae                	mv	s5,a1
    80004cb0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cb2:	411c                	lw	a5,0(a0)
    80004cb4:	4705                	li	a4,1
    80004cb6:	02e78263          	beq	a5,a4,80004cda <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cba:	470d                	li	a4,3
    80004cbc:	02e78663          	beq	a5,a4,80004ce8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cc0:	4709                	li	a4,2
    80004cc2:	0ee79163          	bne	a5,a4,80004da4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cc6:	0ac05d63          	blez	a2,80004d80 <filewrite+0xf4>
    int i = 0;
    80004cca:	4981                	li	s3,0
    80004ccc:	6b05                	lui	s6,0x1
    80004cce:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cd2:	6b85                	lui	s7,0x1
    80004cd4:	c00b8b9b          	addiw	s7,s7,-1024
    80004cd8:	a861                	j	80004d70 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cda:	6908                	ld	a0,16(a0)
    80004cdc:	00000097          	auipc	ra,0x0
    80004ce0:	22e080e7          	jalr	558(ra) # 80004f0a <pipewrite>
    80004ce4:	8a2a                	mv	s4,a0
    80004ce6:	a045                	j	80004d86 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ce8:	02451783          	lh	a5,36(a0)
    80004cec:	03079693          	slli	a3,a5,0x30
    80004cf0:	92c1                	srli	a3,a3,0x30
    80004cf2:	4725                	li	a4,9
    80004cf4:	0cd76263          	bltu	a4,a3,80004db8 <filewrite+0x12c>
    80004cf8:	0792                	slli	a5,a5,0x4
    80004cfa:	0001e717          	auipc	a4,0x1e
    80004cfe:	49670713          	addi	a4,a4,1174 # 80023190 <devsw>
    80004d02:	97ba                	add	a5,a5,a4
    80004d04:	679c                	ld	a5,8(a5)
    80004d06:	cbdd                	beqz	a5,80004dbc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d08:	4505                	li	a0,1
    80004d0a:	9782                	jalr	a5
    80004d0c:	8a2a                	mv	s4,a0
    80004d0e:	a8a5                	j	80004d86 <filewrite+0xfa>
    80004d10:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	8b0080e7          	jalr	-1872(ra) # 800045c4 <begin_op>
      ilock(f->ip);
    80004d1c:	01893503          	ld	a0,24(s2)
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	ed2080e7          	jalr	-302(ra) # 80003bf2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d28:	8762                	mv	a4,s8
    80004d2a:	02092683          	lw	a3,32(s2)
    80004d2e:	01598633          	add	a2,s3,s5
    80004d32:	4585                	li	a1,1
    80004d34:	01893503          	ld	a0,24(s2)
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	266080e7          	jalr	614(ra) # 80003f9e <writei>
    80004d40:	84aa                	mv	s1,a0
    80004d42:	00a05763          	blez	a0,80004d50 <filewrite+0xc4>
        f->off += r;
    80004d46:	02092783          	lw	a5,32(s2)
    80004d4a:	9fa9                	addw	a5,a5,a0
    80004d4c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d50:	01893503          	ld	a0,24(s2)
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	f60080e7          	jalr	-160(ra) # 80003cb4 <iunlock>
      end_op();
    80004d5c:	00000097          	auipc	ra,0x0
    80004d60:	8e8080e7          	jalr	-1816(ra) # 80004644 <end_op>

      if(r != n1){
    80004d64:	009c1f63          	bne	s8,s1,80004d82 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d68:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d6c:	0149db63          	bge	s3,s4,80004d82 <filewrite+0xf6>
      int n1 = n - i;
    80004d70:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d74:	84be                	mv	s1,a5
    80004d76:	2781                	sext.w	a5,a5
    80004d78:	f8fb5ce3          	bge	s6,a5,80004d10 <filewrite+0x84>
    80004d7c:	84de                	mv	s1,s7
    80004d7e:	bf49                	j	80004d10 <filewrite+0x84>
    int i = 0;
    80004d80:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d82:	013a1f63          	bne	s4,s3,80004da0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d86:	8552                	mv	a0,s4
    80004d88:	60a6                	ld	ra,72(sp)
    80004d8a:	6406                	ld	s0,64(sp)
    80004d8c:	74e2                	ld	s1,56(sp)
    80004d8e:	7942                	ld	s2,48(sp)
    80004d90:	79a2                	ld	s3,40(sp)
    80004d92:	7a02                	ld	s4,32(sp)
    80004d94:	6ae2                	ld	s5,24(sp)
    80004d96:	6b42                	ld	s6,16(sp)
    80004d98:	6ba2                	ld	s7,8(sp)
    80004d9a:	6c02                	ld	s8,0(sp)
    80004d9c:	6161                	addi	sp,sp,80
    80004d9e:	8082                	ret
    ret = (i == n ? n : -1);
    80004da0:	5a7d                	li	s4,-1
    80004da2:	b7d5                	j	80004d86 <filewrite+0xfa>
    panic("filewrite");
    80004da4:	00004517          	auipc	a0,0x4
    80004da8:	a1450513          	addi	a0,a0,-1516 # 800087b8 <syscalls+0x280>
    80004dac:	ffffb097          	auipc	ra,0xffffb
    80004db0:	792080e7          	jalr	1938(ra) # 8000053e <panic>
    return -1;
    80004db4:	5a7d                	li	s4,-1
    80004db6:	bfc1                	j	80004d86 <filewrite+0xfa>
      return -1;
    80004db8:	5a7d                	li	s4,-1
    80004dba:	b7f1                	j	80004d86 <filewrite+0xfa>
    80004dbc:	5a7d                	li	s4,-1
    80004dbe:	b7e1                	j	80004d86 <filewrite+0xfa>

0000000080004dc0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dc0:	7179                	addi	sp,sp,-48
    80004dc2:	f406                	sd	ra,40(sp)
    80004dc4:	f022                	sd	s0,32(sp)
    80004dc6:	ec26                	sd	s1,24(sp)
    80004dc8:	e84a                	sd	s2,16(sp)
    80004dca:	e44e                	sd	s3,8(sp)
    80004dcc:	e052                	sd	s4,0(sp)
    80004dce:	1800                	addi	s0,sp,48
    80004dd0:	84aa                	mv	s1,a0
    80004dd2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dd4:	0005b023          	sd	zero,0(a1)
    80004dd8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ddc:	00000097          	auipc	ra,0x0
    80004de0:	bf8080e7          	jalr	-1032(ra) # 800049d4 <filealloc>
    80004de4:	e088                	sd	a0,0(s1)
    80004de6:	c551                	beqz	a0,80004e72 <pipealloc+0xb2>
    80004de8:	00000097          	auipc	ra,0x0
    80004dec:	bec080e7          	jalr	-1044(ra) # 800049d4 <filealloc>
    80004df0:	00aa3023          	sd	a0,0(s4)
    80004df4:	c92d                	beqz	a0,80004e66 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	cfe080e7          	jalr	-770(ra) # 80000af4 <kalloc>
    80004dfe:	892a                	mv	s2,a0
    80004e00:	c125                	beqz	a0,80004e60 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e02:	4985                	li	s3,1
    80004e04:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e08:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e0c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e10:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e14:	00003597          	auipc	a1,0x3
    80004e18:	66458593          	addi	a1,a1,1636 # 80008478 <states.1807+0x1b8>
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	d38080e7          	jalr	-712(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e24:	609c                	ld	a5,0(s1)
    80004e26:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e2a:	609c                	ld	a5,0(s1)
    80004e2c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e30:	609c                	ld	a5,0(s1)
    80004e32:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e36:	609c                	ld	a5,0(s1)
    80004e38:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e3c:	000a3783          	ld	a5,0(s4)
    80004e40:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e44:	000a3783          	ld	a5,0(s4)
    80004e48:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e4c:	000a3783          	ld	a5,0(s4)
    80004e50:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e54:	000a3783          	ld	a5,0(s4)
    80004e58:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e5c:	4501                	li	a0,0
    80004e5e:	a025                	j	80004e86 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e60:	6088                	ld	a0,0(s1)
    80004e62:	e501                	bnez	a0,80004e6a <pipealloc+0xaa>
    80004e64:	a039                	j	80004e72 <pipealloc+0xb2>
    80004e66:	6088                	ld	a0,0(s1)
    80004e68:	c51d                	beqz	a0,80004e96 <pipealloc+0xd6>
    fileclose(*f0);
    80004e6a:	00000097          	auipc	ra,0x0
    80004e6e:	c26080e7          	jalr	-986(ra) # 80004a90 <fileclose>
  if(*f1)
    80004e72:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e76:	557d                	li	a0,-1
  if(*f1)
    80004e78:	c799                	beqz	a5,80004e86 <pipealloc+0xc6>
    fileclose(*f1);
    80004e7a:	853e                	mv	a0,a5
    80004e7c:	00000097          	auipc	ra,0x0
    80004e80:	c14080e7          	jalr	-1004(ra) # 80004a90 <fileclose>
  return -1;
    80004e84:	557d                	li	a0,-1
}
    80004e86:	70a2                	ld	ra,40(sp)
    80004e88:	7402                	ld	s0,32(sp)
    80004e8a:	64e2                	ld	s1,24(sp)
    80004e8c:	6942                	ld	s2,16(sp)
    80004e8e:	69a2                	ld	s3,8(sp)
    80004e90:	6a02                	ld	s4,0(sp)
    80004e92:	6145                	addi	sp,sp,48
    80004e94:	8082                	ret
  return -1;
    80004e96:	557d                	li	a0,-1
    80004e98:	b7fd                	j	80004e86 <pipealloc+0xc6>

0000000080004e9a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e9a:	1101                	addi	sp,sp,-32
    80004e9c:	ec06                	sd	ra,24(sp)
    80004e9e:	e822                	sd	s0,16(sp)
    80004ea0:	e426                	sd	s1,8(sp)
    80004ea2:	e04a                	sd	s2,0(sp)
    80004ea4:	1000                	addi	s0,sp,32
    80004ea6:	84aa                	mv	s1,a0
    80004ea8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	d3a080e7          	jalr	-710(ra) # 80000be4 <acquire>
  if(writable){
    80004eb2:	02090d63          	beqz	s2,80004eec <pipeclose+0x52>
    pi->writeopen = 0;
    80004eb6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004eba:	21848513          	addi	a0,s1,536
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	69c080e7          	jalr	1692(ra) # 8000255a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ec6:	2204b783          	ld	a5,544(s1)
    80004eca:	eb95                	bnez	a5,80004efe <pipeclose+0x64>
    release(&pi->lock);
    80004ecc:	8526                	mv	a0,s1
    80004ece:	ffffc097          	auipc	ra,0xffffc
    80004ed2:	dca080e7          	jalr	-566(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	b20080e7          	jalr	-1248(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ee0:	60e2                	ld	ra,24(sp)
    80004ee2:	6442                	ld	s0,16(sp)
    80004ee4:	64a2                	ld	s1,8(sp)
    80004ee6:	6902                	ld	s2,0(sp)
    80004ee8:	6105                	addi	sp,sp,32
    80004eea:	8082                	ret
    pi->readopen = 0;
    80004eec:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ef0:	21c48513          	addi	a0,s1,540
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	666080e7          	jalr	1638(ra) # 8000255a <wakeup>
    80004efc:	b7e9                	j	80004ec6 <pipeclose+0x2c>
    release(&pi->lock);
    80004efe:	8526                	mv	a0,s1
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	d98080e7          	jalr	-616(ra) # 80000c98 <release>
}
    80004f08:	bfe1                	j	80004ee0 <pipeclose+0x46>

0000000080004f0a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f0a:	7159                	addi	sp,sp,-112
    80004f0c:	f486                	sd	ra,104(sp)
    80004f0e:	f0a2                	sd	s0,96(sp)
    80004f10:	eca6                	sd	s1,88(sp)
    80004f12:	e8ca                	sd	s2,80(sp)
    80004f14:	e4ce                	sd	s3,72(sp)
    80004f16:	e0d2                	sd	s4,64(sp)
    80004f18:	fc56                	sd	s5,56(sp)
    80004f1a:	f85a                	sd	s6,48(sp)
    80004f1c:	f45e                	sd	s7,40(sp)
    80004f1e:	f062                	sd	s8,32(sp)
    80004f20:	ec66                	sd	s9,24(sp)
    80004f22:	1880                	addi	s0,sp,112
    80004f24:	84aa                	mv	s1,a0
    80004f26:	8aae                	mv	s5,a1
    80004f28:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	bac080e7          	jalr	-1108(ra) # 80001ad6 <myproc>
    80004f32:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f34:	8526                	mv	a0,s1
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	cae080e7          	jalr	-850(ra) # 80000be4 <acquire>
  while(i < n){
    80004f3e:	0d405163          	blez	s4,80005000 <pipewrite+0xf6>
    80004f42:	8ba6                	mv	s7,s1
  int i = 0;
    80004f44:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f46:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f48:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f4c:	21c48c13          	addi	s8,s1,540
    80004f50:	a08d                	j	80004fb2 <pipewrite+0xa8>
      release(&pi->lock);
    80004f52:	8526                	mv	a0,s1
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
      return -1;
    80004f5c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f5e:	854a                	mv	a0,s2
    80004f60:	70a6                	ld	ra,104(sp)
    80004f62:	7406                	ld	s0,96(sp)
    80004f64:	64e6                	ld	s1,88(sp)
    80004f66:	6946                	ld	s2,80(sp)
    80004f68:	69a6                	ld	s3,72(sp)
    80004f6a:	6a06                	ld	s4,64(sp)
    80004f6c:	7ae2                	ld	s5,56(sp)
    80004f6e:	7b42                	ld	s6,48(sp)
    80004f70:	7ba2                	ld	s7,40(sp)
    80004f72:	7c02                	ld	s8,32(sp)
    80004f74:	6ce2                	ld	s9,24(sp)
    80004f76:	6165                	addi	sp,sp,112
    80004f78:	8082                	ret
      wakeup(&pi->nread);
    80004f7a:	8566                	mv	a0,s9
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	5de080e7          	jalr	1502(ra) # 8000255a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f84:	85de                	mv	a1,s7
    80004f86:	8562                	mv	a0,s8
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	2fa080e7          	jalr	762(ra) # 80002282 <sleep>
    80004f90:	a839                	j	80004fae <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f92:	21c4a783          	lw	a5,540(s1)
    80004f96:	0017871b          	addiw	a4,a5,1
    80004f9a:	20e4ae23          	sw	a4,540(s1)
    80004f9e:	1ff7f793          	andi	a5,a5,511
    80004fa2:	97a6                	add	a5,a5,s1
    80004fa4:	f9f44703          	lbu	a4,-97(s0)
    80004fa8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fac:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fae:	03495d63          	bge	s2,s4,80004fe8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fb2:	2204a783          	lw	a5,544(s1)
    80004fb6:	dfd1                	beqz	a5,80004f52 <pipewrite+0x48>
    80004fb8:	0289a783          	lw	a5,40(s3)
    80004fbc:	fbd9                	bnez	a5,80004f52 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fbe:	2184a783          	lw	a5,536(s1)
    80004fc2:	21c4a703          	lw	a4,540(s1)
    80004fc6:	2007879b          	addiw	a5,a5,512
    80004fca:	faf708e3          	beq	a4,a5,80004f7a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fce:	4685                	li	a3,1
    80004fd0:	01590633          	add	a2,s2,s5
    80004fd4:	f9f40593          	addi	a1,s0,-97
    80004fd8:	0509b503          	ld	a0,80(s3)
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	72a080e7          	jalr	1834(ra) # 80001706 <copyin>
    80004fe4:	fb6517e3          	bne	a0,s6,80004f92 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004fe8:	21848513          	addi	a0,s1,536
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	56e080e7          	jalr	1390(ra) # 8000255a <wakeup>
  release(&pi->lock);
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	ca2080e7          	jalr	-862(ra) # 80000c98 <release>
  return i;
    80004ffe:	b785                	j	80004f5e <pipewrite+0x54>
  int i = 0;
    80005000:	4901                	li	s2,0
    80005002:	b7dd                	j	80004fe8 <pipewrite+0xde>

0000000080005004 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005004:	715d                	addi	sp,sp,-80
    80005006:	e486                	sd	ra,72(sp)
    80005008:	e0a2                	sd	s0,64(sp)
    8000500a:	fc26                	sd	s1,56(sp)
    8000500c:	f84a                	sd	s2,48(sp)
    8000500e:	f44e                	sd	s3,40(sp)
    80005010:	f052                	sd	s4,32(sp)
    80005012:	ec56                	sd	s5,24(sp)
    80005014:	e85a                	sd	s6,16(sp)
    80005016:	0880                	addi	s0,sp,80
    80005018:	84aa                	mv	s1,a0
    8000501a:	892e                	mv	s2,a1
    8000501c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	ab8080e7          	jalr	-1352(ra) # 80001ad6 <myproc>
    80005026:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005028:	8b26                	mv	s6,s1
    8000502a:	8526                	mv	a0,s1
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	bb8080e7          	jalr	-1096(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005034:	2184a703          	lw	a4,536(s1)
    80005038:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000503c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005040:	02f71463          	bne	a4,a5,80005068 <piperead+0x64>
    80005044:	2244a783          	lw	a5,548(s1)
    80005048:	c385                	beqz	a5,80005068 <piperead+0x64>
    if(pr->killed){
    8000504a:	028a2783          	lw	a5,40(s4)
    8000504e:	ebc1                	bnez	a5,800050de <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005050:	85da                	mv	a1,s6
    80005052:	854e                	mv	a0,s3
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	22e080e7          	jalr	558(ra) # 80002282 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000505c:	2184a703          	lw	a4,536(s1)
    80005060:	21c4a783          	lw	a5,540(s1)
    80005064:	fef700e3          	beq	a4,a5,80005044 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005068:	09505263          	blez	s5,800050ec <piperead+0xe8>
    8000506c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000506e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005070:	2184a783          	lw	a5,536(s1)
    80005074:	21c4a703          	lw	a4,540(s1)
    80005078:	02f70d63          	beq	a4,a5,800050b2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000507c:	0017871b          	addiw	a4,a5,1
    80005080:	20e4ac23          	sw	a4,536(s1)
    80005084:	1ff7f793          	andi	a5,a5,511
    80005088:	97a6                	add	a5,a5,s1
    8000508a:	0187c783          	lbu	a5,24(a5)
    8000508e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005092:	4685                	li	a3,1
    80005094:	fbf40613          	addi	a2,s0,-65
    80005098:	85ca                	mv	a1,s2
    8000509a:	050a3503          	ld	a0,80(s4)
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	5dc080e7          	jalr	1500(ra) # 8000167a <copyout>
    800050a6:	01650663          	beq	a0,s6,800050b2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050aa:	2985                	addiw	s3,s3,1
    800050ac:	0905                	addi	s2,s2,1
    800050ae:	fd3a91e3          	bne	s5,s3,80005070 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050b2:	21c48513          	addi	a0,s1,540
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	4a4080e7          	jalr	1188(ra) # 8000255a <wakeup>
  release(&pi->lock);
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	bd8080e7          	jalr	-1064(ra) # 80000c98 <release>
  return i;
}
    800050c8:	854e                	mv	a0,s3
    800050ca:	60a6                	ld	ra,72(sp)
    800050cc:	6406                	ld	s0,64(sp)
    800050ce:	74e2                	ld	s1,56(sp)
    800050d0:	7942                	ld	s2,48(sp)
    800050d2:	79a2                	ld	s3,40(sp)
    800050d4:	7a02                	ld	s4,32(sp)
    800050d6:	6ae2                	ld	s5,24(sp)
    800050d8:	6b42                	ld	s6,16(sp)
    800050da:	6161                	addi	sp,sp,80
    800050dc:	8082                	ret
      release(&pi->lock);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	bb8080e7          	jalr	-1096(ra) # 80000c98 <release>
      return -1;
    800050e8:	59fd                	li	s3,-1
    800050ea:	bff9                	j	800050c8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ec:	4981                	li	s3,0
    800050ee:	b7d1                	j	800050b2 <piperead+0xae>

00000000800050f0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050f0:	df010113          	addi	sp,sp,-528
    800050f4:	20113423          	sd	ra,520(sp)
    800050f8:	20813023          	sd	s0,512(sp)
    800050fc:	ffa6                	sd	s1,504(sp)
    800050fe:	fbca                	sd	s2,496(sp)
    80005100:	f7ce                	sd	s3,488(sp)
    80005102:	f3d2                	sd	s4,480(sp)
    80005104:	efd6                	sd	s5,472(sp)
    80005106:	ebda                	sd	s6,464(sp)
    80005108:	e7de                	sd	s7,456(sp)
    8000510a:	e3e2                	sd	s8,448(sp)
    8000510c:	ff66                	sd	s9,440(sp)
    8000510e:	fb6a                	sd	s10,432(sp)
    80005110:	f76e                	sd	s11,424(sp)
    80005112:	0c00                	addi	s0,sp,528
    80005114:	84aa                	mv	s1,a0
    80005116:	dea43c23          	sd	a0,-520(s0)
    8000511a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	9b8080e7          	jalr	-1608(ra) # 80001ad6 <myproc>
    80005126:	892a                	mv	s2,a0

  begin_op();
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	49c080e7          	jalr	1180(ra) # 800045c4 <begin_op>

  if((ip = namei(path)) == 0){
    80005130:	8526                	mv	a0,s1
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	276080e7          	jalr	630(ra) # 800043a8 <namei>
    8000513a:	c92d                	beqz	a0,800051ac <exec+0xbc>
    8000513c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	ab4080e7          	jalr	-1356(ra) # 80003bf2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005146:	04000713          	li	a4,64
    8000514a:	4681                	li	a3,0
    8000514c:	e5040613          	addi	a2,s0,-432
    80005150:	4581                	li	a1,0
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	d52080e7          	jalr	-686(ra) # 80003ea6 <readi>
    8000515c:	04000793          	li	a5,64
    80005160:	00f51a63          	bne	a0,a5,80005174 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005164:	e5042703          	lw	a4,-432(s0)
    80005168:	464c47b7          	lui	a5,0x464c4
    8000516c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005170:	04f70463          	beq	a4,a5,800051b8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005174:	8526                	mv	a0,s1
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	cde080e7          	jalr	-802(ra) # 80003e54 <iunlockput>
    end_op();
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	4c6080e7          	jalr	1222(ra) # 80004644 <end_op>
  }
  return -1;
    80005186:	557d                	li	a0,-1
}
    80005188:	20813083          	ld	ra,520(sp)
    8000518c:	20013403          	ld	s0,512(sp)
    80005190:	74fe                	ld	s1,504(sp)
    80005192:	795e                	ld	s2,496(sp)
    80005194:	79be                	ld	s3,488(sp)
    80005196:	7a1e                	ld	s4,480(sp)
    80005198:	6afe                	ld	s5,472(sp)
    8000519a:	6b5e                	ld	s6,464(sp)
    8000519c:	6bbe                	ld	s7,456(sp)
    8000519e:	6c1e                	ld	s8,448(sp)
    800051a0:	7cfa                	ld	s9,440(sp)
    800051a2:	7d5a                	ld	s10,432(sp)
    800051a4:	7dba                	ld	s11,424(sp)
    800051a6:	21010113          	addi	sp,sp,528
    800051aa:	8082                	ret
    end_op();
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	498080e7          	jalr	1176(ra) # 80004644 <end_op>
    return -1;
    800051b4:	557d                	li	a0,-1
    800051b6:	bfc9                	j	80005188 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051b8:	854a                	mv	a0,s2
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	9e0080e7          	jalr	-1568(ra) # 80001b9a <proc_pagetable>
    800051c2:	8baa                	mv	s7,a0
    800051c4:	d945                	beqz	a0,80005174 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051c6:	e7042983          	lw	s3,-400(s0)
    800051ca:	e8845783          	lhu	a5,-376(s0)
    800051ce:	c7ad                	beqz	a5,80005238 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051d0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d2:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051d4:	6c85                	lui	s9,0x1
    800051d6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051da:	def43823          	sd	a5,-528(s0)
    800051de:	a42d                	j	80005408 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051e0:	00003517          	auipc	a0,0x3
    800051e4:	5e850513          	addi	a0,a0,1512 # 800087c8 <syscalls+0x290>
    800051e8:	ffffb097          	auipc	ra,0xffffb
    800051ec:	356080e7          	jalr	854(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051f0:	8756                	mv	a4,s5
    800051f2:	012d86bb          	addw	a3,s11,s2
    800051f6:	4581                	li	a1,0
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	cac080e7          	jalr	-852(ra) # 80003ea6 <readi>
    80005202:	2501                	sext.w	a0,a0
    80005204:	1aaa9963          	bne	s5,a0,800053b6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005208:	6785                	lui	a5,0x1
    8000520a:	0127893b          	addw	s2,a5,s2
    8000520e:	77fd                	lui	a5,0xfffff
    80005210:	01478a3b          	addw	s4,a5,s4
    80005214:	1f897163          	bgeu	s2,s8,800053f6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005218:	02091593          	slli	a1,s2,0x20
    8000521c:	9181                	srli	a1,a1,0x20
    8000521e:	95ea                	add	a1,a1,s10
    80005220:	855e                	mv	a0,s7
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	e54080e7          	jalr	-428(ra) # 80001076 <walkaddr>
    8000522a:	862a                	mv	a2,a0
    if(pa == 0)
    8000522c:	d955                	beqz	a0,800051e0 <exec+0xf0>
      n = PGSIZE;
    8000522e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005230:	fd9a70e3          	bgeu	s4,s9,800051f0 <exec+0x100>
      n = sz - i;
    80005234:	8ad2                	mv	s5,s4
    80005236:	bf6d                	j	800051f0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005238:	4901                	li	s2,0
  iunlockput(ip);
    8000523a:	8526                	mv	a0,s1
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	c18080e7          	jalr	-1000(ra) # 80003e54 <iunlockput>
  end_op();
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	400080e7          	jalr	1024(ra) # 80004644 <end_op>
  p = myproc();
    8000524c:	ffffd097          	auipc	ra,0xffffd
    80005250:	88a080e7          	jalr	-1910(ra) # 80001ad6 <myproc>
    80005254:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005256:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000525a:	6785                	lui	a5,0x1
    8000525c:	17fd                	addi	a5,a5,-1
    8000525e:	993e                	add	s2,s2,a5
    80005260:	757d                	lui	a0,0xfffff
    80005262:	00a977b3          	and	a5,s2,a0
    80005266:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000526a:	6609                	lui	a2,0x2
    8000526c:	963e                	add	a2,a2,a5
    8000526e:	85be                	mv	a1,a5
    80005270:	855e                	mv	a0,s7
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	1b8080e7          	jalr	440(ra) # 8000142a <uvmalloc>
    8000527a:	8b2a                	mv	s6,a0
  ip = 0;
    8000527c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000527e:	12050c63          	beqz	a0,800053b6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005282:	75f9                	lui	a1,0xffffe
    80005284:	95aa                	add	a1,a1,a0
    80005286:	855e                	mv	a0,s7
    80005288:	ffffc097          	auipc	ra,0xffffc
    8000528c:	3c0080e7          	jalr	960(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005290:	7c7d                	lui	s8,0xfffff
    80005292:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005294:	e0043783          	ld	a5,-512(s0)
    80005298:	6388                	ld	a0,0(a5)
    8000529a:	c535                	beqz	a0,80005306 <exec+0x216>
    8000529c:	e9040993          	addi	s3,s0,-368
    800052a0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052a4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	bbe080e7          	jalr	-1090(ra) # 80000e64 <strlen>
    800052ae:	2505                	addiw	a0,a0,1
    800052b0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052b4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052b8:	13896363          	bltu	s2,s8,800053de <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052bc:	e0043d83          	ld	s11,-512(s0)
    800052c0:	000dba03          	ld	s4,0(s11)
    800052c4:	8552                	mv	a0,s4
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	b9e080e7          	jalr	-1122(ra) # 80000e64 <strlen>
    800052ce:	0015069b          	addiw	a3,a0,1
    800052d2:	8652                	mv	a2,s4
    800052d4:	85ca                	mv	a1,s2
    800052d6:	855e                	mv	a0,s7
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	3a2080e7          	jalr	930(ra) # 8000167a <copyout>
    800052e0:	10054363          	bltz	a0,800053e6 <exec+0x2f6>
    ustack[argc] = sp;
    800052e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052e8:	0485                	addi	s1,s1,1
    800052ea:	008d8793          	addi	a5,s11,8
    800052ee:	e0f43023          	sd	a5,-512(s0)
    800052f2:	008db503          	ld	a0,8(s11)
    800052f6:	c911                	beqz	a0,8000530a <exec+0x21a>
    if(argc >= MAXARG)
    800052f8:	09a1                	addi	s3,s3,8
    800052fa:	fb3c96e3          	bne	s9,s3,800052a6 <exec+0x1b6>
  sz = sz1;
    800052fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005302:	4481                	li	s1,0
    80005304:	a84d                	j	800053b6 <exec+0x2c6>
  sp = sz;
    80005306:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005308:	4481                	li	s1,0
  ustack[argc] = 0;
    8000530a:	00349793          	slli	a5,s1,0x3
    8000530e:	f9040713          	addi	a4,s0,-112
    80005312:	97ba                	add	a5,a5,a4
    80005314:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005318:	00148693          	addi	a3,s1,1
    8000531c:	068e                	slli	a3,a3,0x3
    8000531e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005322:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005326:	01897663          	bgeu	s2,s8,80005332 <exec+0x242>
  sz = sz1;
    8000532a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000532e:	4481                	li	s1,0
    80005330:	a059                	j	800053b6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005332:	e9040613          	addi	a2,s0,-368
    80005336:	85ca                	mv	a1,s2
    80005338:	855e                	mv	a0,s7
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	340080e7          	jalr	832(ra) # 8000167a <copyout>
    80005342:	0a054663          	bltz	a0,800053ee <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005346:	058ab783          	ld	a5,88(s5)
    8000534a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000534e:	df843783          	ld	a5,-520(s0)
    80005352:	0007c703          	lbu	a4,0(a5)
    80005356:	cf11                	beqz	a4,80005372 <exec+0x282>
    80005358:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000535a:	02f00693          	li	a3,47
    8000535e:	a039                	j	8000536c <exec+0x27c>
      last = s+1;
    80005360:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005364:	0785                	addi	a5,a5,1
    80005366:	fff7c703          	lbu	a4,-1(a5)
    8000536a:	c701                	beqz	a4,80005372 <exec+0x282>
    if(*s == '/')
    8000536c:	fed71ce3          	bne	a4,a3,80005364 <exec+0x274>
    80005370:	bfc5                	j	80005360 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005372:	4641                	li	a2,16
    80005374:	df843583          	ld	a1,-520(s0)
    80005378:	158a8513          	addi	a0,s5,344
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	ab6080e7          	jalr	-1354(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005384:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005388:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000538c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005390:	058ab783          	ld	a5,88(s5)
    80005394:	e6843703          	ld	a4,-408(s0)
    80005398:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000539a:	058ab783          	ld	a5,88(s5)
    8000539e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053a2:	85ea                	mv	a1,s10
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	892080e7          	jalr	-1902(ra) # 80001c36 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053ac:	0004851b          	sext.w	a0,s1
    800053b0:	bbe1                	j	80005188 <exec+0x98>
    800053b2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053b6:	e0843583          	ld	a1,-504(s0)
    800053ba:	855e                	mv	a0,s7
    800053bc:	ffffd097          	auipc	ra,0xffffd
    800053c0:	87a080e7          	jalr	-1926(ra) # 80001c36 <proc_freepagetable>
  if(ip){
    800053c4:	da0498e3          	bnez	s1,80005174 <exec+0x84>
  return -1;
    800053c8:	557d                	li	a0,-1
    800053ca:	bb7d                	j	80005188 <exec+0x98>
    800053cc:	e1243423          	sd	s2,-504(s0)
    800053d0:	b7dd                	j	800053b6 <exec+0x2c6>
    800053d2:	e1243423          	sd	s2,-504(s0)
    800053d6:	b7c5                	j	800053b6 <exec+0x2c6>
    800053d8:	e1243423          	sd	s2,-504(s0)
    800053dc:	bfe9                	j	800053b6 <exec+0x2c6>
  sz = sz1;
    800053de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053e2:	4481                	li	s1,0
    800053e4:	bfc9                	j	800053b6 <exec+0x2c6>
  sz = sz1;
    800053e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ea:	4481                	li	s1,0
    800053ec:	b7e9                	j	800053b6 <exec+0x2c6>
  sz = sz1;
    800053ee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053f2:	4481                	li	s1,0
    800053f4:	b7c9                	j	800053b6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053f6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053fa:	2b05                	addiw	s6,s6,1
    800053fc:	0389899b          	addiw	s3,s3,56
    80005400:	e8845783          	lhu	a5,-376(s0)
    80005404:	e2fb5be3          	bge	s6,a5,8000523a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005408:	2981                	sext.w	s3,s3
    8000540a:	03800713          	li	a4,56
    8000540e:	86ce                	mv	a3,s3
    80005410:	e1840613          	addi	a2,s0,-488
    80005414:	4581                	li	a1,0
    80005416:	8526                	mv	a0,s1
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	a8e080e7          	jalr	-1394(ra) # 80003ea6 <readi>
    80005420:	03800793          	li	a5,56
    80005424:	f8f517e3          	bne	a0,a5,800053b2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005428:	e1842783          	lw	a5,-488(s0)
    8000542c:	4705                	li	a4,1
    8000542e:	fce796e3          	bne	a5,a4,800053fa <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005432:	e4043603          	ld	a2,-448(s0)
    80005436:	e3843783          	ld	a5,-456(s0)
    8000543a:	f8f669e3          	bltu	a2,a5,800053cc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000543e:	e2843783          	ld	a5,-472(s0)
    80005442:	963e                	add	a2,a2,a5
    80005444:	f8f667e3          	bltu	a2,a5,800053d2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005448:	85ca                	mv	a1,s2
    8000544a:	855e                	mv	a0,s7
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	fde080e7          	jalr	-34(ra) # 8000142a <uvmalloc>
    80005454:	e0a43423          	sd	a0,-504(s0)
    80005458:	d141                	beqz	a0,800053d8 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000545a:	e2843d03          	ld	s10,-472(s0)
    8000545e:	df043783          	ld	a5,-528(s0)
    80005462:	00fd77b3          	and	a5,s10,a5
    80005466:	fba1                	bnez	a5,800053b6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005468:	e2042d83          	lw	s11,-480(s0)
    8000546c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005470:	f80c03e3          	beqz	s8,800053f6 <exec+0x306>
    80005474:	8a62                	mv	s4,s8
    80005476:	4901                	li	s2,0
    80005478:	b345                	j	80005218 <exec+0x128>

000000008000547a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000547a:	7179                	addi	sp,sp,-48
    8000547c:	f406                	sd	ra,40(sp)
    8000547e:	f022                	sd	s0,32(sp)
    80005480:	ec26                	sd	s1,24(sp)
    80005482:	e84a                	sd	s2,16(sp)
    80005484:	1800                	addi	s0,sp,48
    80005486:	892e                	mv	s2,a1
    80005488:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000548a:	fdc40593          	addi	a1,s0,-36
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	9a8080e7          	jalr	-1624(ra) # 80002e36 <argint>
    80005496:	04054063          	bltz	a0,800054d6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000549a:	fdc42703          	lw	a4,-36(s0)
    8000549e:	47bd                	li	a5,15
    800054a0:	02e7ed63          	bltu	a5,a4,800054da <argfd+0x60>
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	632080e7          	jalr	1586(ra) # 80001ad6 <myproc>
    800054ac:	fdc42703          	lw	a4,-36(s0)
    800054b0:	01a70793          	addi	a5,a4,26
    800054b4:	078e                	slli	a5,a5,0x3
    800054b6:	953e                	add	a0,a0,a5
    800054b8:	611c                	ld	a5,0(a0)
    800054ba:	c395                	beqz	a5,800054de <argfd+0x64>
    return -1;
  if(pfd)
    800054bc:	00090463          	beqz	s2,800054c4 <argfd+0x4a>
    *pfd = fd;
    800054c0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054c4:	4501                	li	a0,0
  if(pf)
    800054c6:	c091                	beqz	s1,800054ca <argfd+0x50>
    *pf = f;
    800054c8:	e09c                	sd	a5,0(s1)
}
    800054ca:	70a2                	ld	ra,40(sp)
    800054cc:	7402                	ld	s0,32(sp)
    800054ce:	64e2                	ld	s1,24(sp)
    800054d0:	6942                	ld	s2,16(sp)
    800054d2:	6145                	addi	sp,sp,48
    800054d4:	8082                	ret
    return -1;
    800054d6:	557d                	li	a0,-1
    800054d8:	bfcd                	j	800054ca <argfd+0x50>
    return -1;
    800054da:	557d                	li	a0,-1
    800054dc:	b7fd                	j	800054ca <argfd+0x50>
    800054de:	557d                	li	a0,-1
    800054e0:	b7ed                	j	800054ca <argfd+0x50>

00000000800054e2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054e2:	1101                	addi	sp,sp,-32
    800054e4:	ec06                	sd	ra,24(sp)
    800054e6:	e822                	sd	s0,16(sp)
    800054e8:	e426                	sd	s1,8(sp)
    800054ea:	1000                	addi	s0,sp,32
    800054ec:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	5e8080e7          	jalr	1512(ra) # 80001ad6 <myproc>
    800054f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054f8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd70d0>
    800054fc:	4501                	li	a0,0
    800054fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005500:	6398                	ld	a4,0(a5)
    80005502:	cb19                	beqz	a4,80005518 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005504:	2505                	addiw	a0,a0,1
    80005506:	07a1                	addi	a5,a5,8
    80005508:	fed51ce3          	bne	a0,a3,80005500 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000550c:	557d                	li	a0,-1
}
    8000550e:	60e2                	ld	ra,24(sp)
    80005510:	6442                	ld	s0,16(sp)
    80005512:	64a2                	ld	s1,8(sp)
    80005514:	6105                	addi	sp,sp,32
    80005516:	8082                	ret
      p->ofile[fd] = f;
    80005518:	01a50793          	addi	a5,a0,26
    8000551c:	078e                	slli	a5,a5,0x3
    8000551e:	963e                	add	a2,a2,a5
    80005520:	e204                	sd	s1,0(a2)
      return fd;
    80005522:	b7f5                	j	8000550e <fdalloc+0x2c>

0000000080005524 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005524:	715d                	addi	sp,sp,-80
    80005526:	e486                	sd	ra,72(sp)
    80005528:	e0a2                	sd	s0,64(sp)
    8000552a:	fc26                	sd	s1,56(sp)
    8000552c:	f84a                	sd	s2,48(sp)
    8000552e:	f44e                	sd	s3,40(sp)
    80005530:	f052                	sd	s4,32(sp)
    80005532:	ec56                	sd	s5,24(sp)
    80005534:	0880                	addi	s0,sp,80
    80005536:	89ae                	mv	s3,a1
    80005538:	8ab2                	mv	s5,a2
    8000553a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000553c:	fb040593          	addi	a1,s0,-80
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	e86080e7          	jalr	-378(ra) # 800043c6 <nameiparent>
    80005548:	892a                	mv	s2,a0
    8000554a:	12050f63          	beqz	a0,80005688 <create+0x164>
    return 0;

  ilock(dp);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	6a4080e7          	jalr	1700(ra) # 80003bf2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005556:	4601                	li	a2,0
    80005558:	fb040593          	addi	a1,s0,-80
    8000555c:	854a                	mv	a0,s2
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	b78080e7          	jalr	-1160(ra) # 800040d6 <dirlookup>
    80005566:	84aa                	mv	s1,a0
    80005568:	c921                	beqz	a0,800055b8 <create+0x94>
    iunlockput(dp);
    8000556a:	854a                	mv	a0,s2
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	8e8080e7          	jalr	-1816(ra) # 80003e54 <iunlockput>
    ilock(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	67c080e7          	jalr	1660(ra) # 80003bf2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000557e:	2981                	sext.w	s3,s3
    80005580:	4789                	li	a5,2
    80005582:	02f99463          	bne	s3,a5,800055aa <create+0x86>
    80005586:	0444d783          	lhu	a5,68(s1)
    8000558a:	37f9                	addiw	a5,a5,-2
    8000558c:	17c2                	slli	a5,a5,0x30
    8000558e:	93c1                	srli	a5,a5,0x30
    80005590:	4705                	li	a4,1
    80005592:	00f76c63          	bltu	a4,a5,800055aa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005596:	8526                	mv	a0,s1
    80005598:	60a6                	ld	ra,72(sp)
    8000559a:	6406                	ld	s0,64(sp)
    8000559c:	74e2                	ld	s1,56(sp)
    8000559e:	7942                	ld	s2,48(sp)
    800055a0:	79a2                	ld	s3,40(sp)
    800055a2:	7a02                	ld	s4,32(sp)
    800055a4:	6ae2                	ld	s5,24(sp)
    800055a6:	6161                	addi	sp,sp,80
    800055a8:	8082                	ret
    iunlockput(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	8a8080e7          	jalr	-1880(ra) # 80003e54 <iunlockput>
    return 0;
    800055b4:	4481                	li	s1,0
    800055b6:	b7c5                	j	80005596 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055b8:	85ce                	mv	a1,s3
    800055ba:	00092503          	lw	a0,0(s2)
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	49c080e7          	jalr	1180(ra) # 80003a5a <ialloc>
    800055c6:	84aa                	mv	s1,a0
    800055c8:	c529                	beqz	a0,80005612 <create+0xee>
  ilock(ip);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	628080e7          	jalr	1576(ra) # 80003bf2 <ilock>
  ip->major = major;
    800055d2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055d6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055da:	4785                	li	a5,1
    800055dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	546080e7          	jalr	1350(ra) # 80003b28 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055ea:	2981                	sext.w	s3,s3
    800055ec:	4785                	li	a5,1
    800055ee:	02f98a63          	beq	s3,a5,80005622 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055f2:	40d0                	lw	a2,4(s1)
    800055f4:	fb040593          	addi	a1,s0,-80
    800055f8:	854a                	mv	a0,s2
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	cec080e7          	jalr	-788(ra) # 800042e6 <dirlink>
    80005602:	06054b63          	bltz	a0,80005678 <create+0x154>
  iunlockput(dp);
    80005606:	854a                	mv	a0,s2
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	84c080e7          	jalr	-1972(ra) # 80003e54 <iunlockput>
  return ip;
    80005610:	b759                	j	80005596 <create+0x72>
    panic("create: ialloc");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	1d650513          	addi	a0,a0,470 # 800087e8 <syscalls+0x2b0>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f24080e7          	jalr	-220(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005622:	04a95783          	lhu	a5,74(s2)
    80005626:	2785                	addiw	a5,a5,1
    80005628:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000562c:	854a                	mv	a0,s2
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	4fa080e7          	jalr	1274(ra) # 80003b28 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005636:	40d0                	lw	a2,4(s1)
    80005638:	00003597          	auipc	a1,0x3
    8000563c:	1c058593          	addi	a1,a1,448 # 800087f8 <syscalls+0x2c0>
    80005640:	8526                	mv	a0,s1
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	ca4080e7          	jalr	-860(ra) # 800042e6 <dirlink>
    8000564a:	00054f63          	bltz	a0,80005668 <create+0x144>
    8000564e:	00492603          	lw	a2,4(s2)
    80005652:	00003597          	auipc	a1,0x3
    80005656:	1ae58593          	addi	a1,a1,430 # 80008800 <syscalls+0x2c8>
    8000565a:	8526                	mv	a0,s1
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	c8a080e7          	jalr	-886(ra) # 800042e6 <dirlink>
    80005664:	f80557e3          	bgez	a0,800055f2 <create+0xce>
      panic("create dots");
    80005668:	00003517          	auipc	a0,0x3
    8000566c:	1a050513          	addi	a0,a0,416 # 80008808 <syscalls+0x2d0>
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005678:	00003517          	auipc	a0,0x3
    8000567c:	1a050513          	addi	a0,a0,416 # 80008818 <syscalls+0x2e0>
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	ebe080e7          	jalr	-322(ra) # 8000053e <panic>
    return 0;
    80005688:	84aa                	mv	s1,a0
    8000568a:	b731                	j	80005596 <create+0x72>

000000008000568c <sys_dup>:
{
    8000568c:	7179                	addi	sp,sp,-48
    8000568e:	f406                	sd	ra,40(sp)
    80005690:	f022                	sd	s0,32(sp)
    80005692:	ec26                	sd	s1,24(sp)
    80005694:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005696:	fd840613          	addi	a2,s0,-40
    8000569a:	4581                	li	a1,0
    8000569c:	4501                	li	a0,0
    8000569e:	00000097          	auipc	ra,0x0
    800056a2:	ddc080e7          	jalr	-548(ra) # 8000547a <argfd>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056a8:	02054363          	bltz	a0,800056ce <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056ac:	fd843503          	ld	a0,-40(s0)
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	e32080e7          	jalr	-462(ra) # 800054e2 <fdalloc>
    800056b8:	84aa                	mv	s1,a0
    return -1;
    800056ba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056bc:	00054963          	bltz	a0,800056ce <sys_dup+0x42>
  filedup(f);
    800056c0:	fd843503          	ld	a0,-40(s0)
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	37a080e7          	jalr	890(ra) # 80004a3e <filedup>
  return fd;
    800056cc:	87a6                	mv	a5,s1
}
    800056ce:	853e                	mv	a0,a5
    800056d0:	70a2                	ld	ra,40(sp)
    800056d2:	7402                	ld	s0,32(sp)
    800056d4:	64e2                	ld	s1,24(sp)
    800056d6:	6145                	addi	sp,sp,48
    800056d8:	8082                	ret

00000000800056da <sys_read>:
{
    800056da:	7179                	addi	sp,sp,-48
    800056dc:	f406                	sd	ra,40(sp)
    800056de:	f022                	sd	s0,32(sp)
    800056e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	fe840613          	addi	a2,s0,-24
    800056e6:	4581                	li	a1,0
    800056e8:	4501                	li	a0,0
    800056ea:	00000097          	auipc	ra,0x0
    800056ee:	d90080e7          	jalr	-624(ra) # 8000547a <argfd>
    return -1;
    800056f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f4:	04054163          	bltz	a0,80005736 <sys_read+0x5c>
    800056f8:	fe440593          	addi	a1,s0,-28
    800056fc:	4509                	li	a0,2
    800056fe:	ffffd097          	auipc	ra,0xffffd
    80005702:	738080e7          	jalr	1848(ra) # 80002e36 <argint>
    return -1;
    80005706:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005708:	02054763          	bltz	a0,80005736 <sys_read+0x5c>
    8000570c:	fd840593          	addi	a1,s0,-40
    80005710:	4505                	li	a0,1
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	746080e7          	jalr	1862(ra) # 80002e58 <argaddr>
    return -1;
    8000571a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000571c:	00054d63          	bltz	a0,80005736 <sys_read+0x5c>
  return fileread(f, p, n);
    80005720:	fe442603          	lw	a2,-28(s0)
    80005724:	fd843583          	ld	a1,-40(s0)
    80005728:	fe843503          	ld	a0,-24(s0)
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	49e080e7          	jalr	1182(ra) # 80004bca <fileread>
    80005734:	87aa                	mv	a5,a0
}
    80005736:	853e                	mv	a0,a5
    80005738:	70a2                	ld	ra,40(sp)
    8000573a:	7402                	ld	s0,32(sp)
    8000573c:	6145                	addi	sp,sp,48
    8000573e:	8082                	ret

0000000080005740 <sys_write>:
{
    80005740:	7179                	addi	sp,sp,-48
    80005742:	f406                	sd	ra,40(sp)
    80005744:	f022                	sd	s0,32(sp)
    80005746:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005748:	fe840613          	addi	a2,s0,-24
    8000574c:	4581                	li	a1,0
    8000574e:	4501                	li	a0,0
    80005750:	00000097          	auipc	ra,0x0
    80005754:	d2a080e7          	jalr	-726(ra) # 8000547a <argfd>
    return -1;
    80005758:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000575a:	04054163          	bltz	a0,8000579c <sys_write+0x5c>
    8000575e:	fe440593          	addi	a1,s0,-28
    80005762:	4509                	li	a0,2
    80005764:	ffffd097          	auipc	ra,0xffffd
    80005768:	6d2080e7          	jalr	1746(ra) # 80002e36 <argint>
    return -1;
    8000576c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576e:	02054763          	bltz	a0,8000579c <sys_write+0x5c>
    80005772:	fd840593          	addi	a1,s0,-40
    80005776:	4505                	li	a0,1
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	6e0080e7          	jalr	1760(ra) # 80002e58 <argaddr>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005782:	00054d63          	bltz	a0,8000579c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005786:	fe442603          	lw	a2,-28(s0)
    8000578a:	fd843583          	ld	a1,-40(s0)
    8000578e:	fe843503          	ld	a0,-24(s0)
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	4fa080e7          	jalr	1274(ra) # 80004c8c <filewrite>
    8000579a:	87aa                	mv	a5,a0
}
    8000579c:	853e                	mv	a0,a5
    8000579e:	70a2                	ld	ra,40(sp)
    800057a0:	7402                	ld	s0,32(sp)
    800057a2:	6145                	addi	sp,sp,48
    800057a4:	8082                	ret

00000000800057a6 <sys_close>:
{
    800057a6:	1101                	addi	sp,sp,-32
    800057a8:	ec06                	sd	ra,24(sp)
    800057aa:	e822                	sd	s0,16(sp)
    800057ac:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057ae:	fe040613          	addi	a2,s0,-32
    800057b2:	fec40593          	addi	a1,s0,-20
    800057b6:	4501                	li	a0,0
    800057b8:	00000097          	auipc	ra,0x0
    800057bc:	cc2080e7          	jalr	-830(ra) # 8000547a <argfd>
    return -1;
    800057c0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057c2:	02054463          	bltz	a0,800057ea <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057c6:	ffffc097          	auipc	ra,0xffffc
    800057ca:	310080e7          	jalr	784(ra) # 80001ad6 <myproc>
    800057ce:	fec42783          	lw	a5,-20(s0)
    800057d2:	07e9                	addi	a5,a5,26
    800057d4:	078e                	slli	a5,a5,0x3
    800057d6:	97aa                	add	a5,a5,a0
    800057d8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057dc:	fe043503          	ld	a0,-32(s0)
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	2b0080e7          	jalr	688(ra) # 80004a90 <fileclose>
  return 0;
    800057e8:	4781                	li	a5,0
}
    800057ea:	853e                	mv	a0,a5
    800057ec:	60e2                	ld	ra,24(sp)
    800057ee:	6442                	ld	s0,16(sp)
    800057f0:	6105                	addi	sp,sp,32
    800057f2:	8082                	ret

00000000800057f4 <sys_fstat>:
{
    800057f4:	1101                	addi	sp,sp,-32
    800057f6:	ec06                	sd	ra,24(sp)
    800057f8:	e822                	sd	s0,16(sp)
    800057fa:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057fc:	fe840613          	addi	a2,s0,-24
    80005800:	4581                	li	a1,0
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	c76080e7          	jalr	-906(ra) # 8000547a <argfd>
    return -1;
    8000580c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000580e:	02054563          	bltz	a0,80005838 <sys_fstat+0x44>
    80005812:	fe040593          	addi	a1,s0,-32
    80005816:	4505                	li	a0,1
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	640080e7          	jalr	1600(ra) # 80002e58 <argaddr>
    return -1;
    80005820:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005822:	00054b63          	bltz	a0,80005838 <sys_fstat+0x44>
  return filestat(f, st);
    80005826:	fe043583          	ld	a1,-32(s0)
    8000582a:	fe843503          	ld	a0,-24(s0)
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	32a080e7          	jalr	810(ra) # 80004b58 <filestat>
    80005836:	87aa                	mv	a5,a0
}
    80005838:	853e                	mv	a0,a5
    8000583a:	60e2                	ld	ra,24(sp)
    8000583c:	6442                	ld	s0,16(sp)
    8000583e:	6105                	addi	sp,sp,32
    80005840:	8082                	ret

0000000080005842 <sys_link>:
{
    80005842:	7169                	addi	sp,sp,-304
    80005844:	f606                	sd	ra,296(sp)
    80005846:	f222                	sd	s0,288(sp)
    80005848:	ee26                	sd	s1,280(sp)
    8000584a:	ea4a                	sd	s2,272(sp)
    8000584c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000584e:	08000613          	li	a2,128
    80005852:	ed040593          	addi	a1,s0,-304
    80005856:	4501                	li	a0,0
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	622080e7          	jalr	1570(ra) # 80002e7a <argstr>
    return -1;
    80005860:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005862:	10054e63          	bltz	a0,8000597e <sys_link+0x13c>
    80005866:	08000613          	li	a2,128
    8000586a:	f5040593          	addi	a1,s0,-176
    8000586e:	4505                	li	a0,1
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	60a080e7          	jalr	1546(ra) # 80002e7a <argstr>
    return -1;
    80005878:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000587a:	10054263          	bltz	a0,8000597e <sys_link+0x13c>
  begin_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	d46080e7          	jalr	-698(ra) # 800045c4 <begin_op>
  if((ip = namei(old)) == 0){
    80005886:	ed040513          	addi	a0,s0,-304
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	b1e080e7          	jalr	-1250(ra) # 800043a8 <namei>
    80005892:	84aa                	mv	s1,a0
    80005894:	c551                	beqz	a0,80005920 <sys_link+0xde>
  ilock(ip);
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	35c080e7          	jalr	860(ra) # 80003bf2 <ilock>
  if(ip->type == T_DIR){
    8000589e:	04449703          	lh	a4,68(s1)
    800058a2:	4785                	li	a5,1
    800058a4:	08f70463          	beq	a4,a5,8000592c <sys_link+0xea>
  ip->nlink++;
    800058a8:	04a4d783          	lhu	a5,74(s1)
    800058ac:	2785                	addiw	a5,a5,1
    800058ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	274080e7          	jalr	628(ra) # 80003b28 <iupdate>
  iunlock(ip);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	3f6080e7          	jalr	1014(ra) # 80003cb4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058c6:	fd040593          	addi	a1,s0,-48
    800058ca:	f5040513          	addi	a0,s0,-176
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	af8080e7          	jalr	-1288(ra) # 800043c6 <nameiparent>
    800058d6:	892a                	mv	s2,a0
    800058d8:	c935                	beqz	a0,8000594c <sys_link+0x10a>
  ilock(dp);
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	318080e7          	jalr	792(ra) # 80003bf2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058e2:	00092703          	lw	a4,0(s2)
    800058e6:	409c                	lw	a5,0(s1)
    800058e8:	04f71d63          	bne	a4,a5,80005942 <sys_link+0x100>
    800058ec:	40d0                	lw	a2,4(s1)
    800058ee:	fd040593          	addi	a1,s0,-48
    800058f2:	854a                	mv	a0,s2
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	9f2080e7          	jalr	-1550(ra) # 800042e6 <dirlink>
    800058fc:	04054363          	bltz	a0,80005942 <sys_link+0x100>
  iunlockput(dp);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	552080e7          	jalr	1362(ra) # 80003e54 <iunlockput>
  iput(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	4a0080e7          	jalr	1184(ra) # 80003dac <iput>
  end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	d30080e7          	jalr	-720(ra) # 80004644 <end_op>
  return 0;
    8000591c:	4781                	li	a5,0
    8000591e:	a085                	j	8000597e <sys_link+0x13c>
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	d24080e7          	jalr	-732(ra) # 80004644 <end_op>
    return -1;
    80005928:	57fd                	li	a5,-1
    8000592a:	a891                	j	8000597e <sys_link+0x13c>
    iunlockput(ip);
    8000592c:	8526                	mv	a0,s1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	526080e7          	jalr	1318(ra) # 80003e54 <iunlockput>
    end_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	d0e080e7          	jalr	-754(ra) # 80004644 <end_op>
    return -1;
    8000593e:	57fd                	li	a5,-1
    80005940:	a83d                	j	8000597e <sys_link+0x13c>
    iunlockput(dp);
    80005942:	854a                	mv	a0,s2
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	510080e7          	jalr	1296(ra) # 80003e54 <iunlockput>
  ilock(ip);
    8000594c:	8526                	mv	a0,s1
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	2a4080e7          	jalr	676(ra) # 80003bf2 <ilock>
  ip->nlink--;
    80005956:	04a4d783          	lhu	a5,74(s1)
    8000595a:	37fd                	addiw	a5,a5,-1
    8000595c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	1c6080e7          	jalr	454(ra) # 80003b28 <iupdate>
  iunlockput(ip);
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	4e8080e7          	jalr	1256(ra) # 80003e54 <iunlockput>
  end_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	cd0080e7          	jalr	-816(ra) # 80004644 <end_op>
  return -1;
    8000597c:	57fd                	li	a5,-1
}
    8000597e:	853e                	mv	a0,a5
    80005980:	70b2                	ld	ra,296(sp)
    80005982:	7412                	ld	s0,288(sp)
    80005984:	64f2                	ld	s1,280(sp)
    80005986:	6952                	ld	s2,272(sp)
    80005988:	6155                	addi	sp,sp,304
    8000598a:	8082                	ret

000000008000598c <sys_unlink>:
{
    8000598c:	7151                	addi	sp,sp,-240
    8000598e:	f586                	sd	ra,232(sp)
    80005990:	f1a2                	sd	s0,224(sp)
    80005992:	eda6                	sd	s1,216(sp)
    80005994:	e9ca                	sd	s2,208(sp)
    80005996:	e5ce                	sd	s3,200(sp)
    80005998:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000599a:	08000613          	li	a2,128
    8000599e:	f3040593          	addi	a1,s0,-208
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	4d6080e7          	jalr	1238(ra) # 80002e7a <argstr>
    800059ac:	18054163          	bltz	a0,80005b2e <sys_unlink+0x1a2>
  begin_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	c14080e7          	jalr	-1004(ra) # 800045c4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059b8:	fb040593          	addi	a1,s0,-80
    800059bc:	f3040513          	addi	a0,s0,-208
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	a06080e7          	jalr	-1530(ra) # 800043c6 <nameiparent>
    800059c8:	84aa                	mv	s1,a0
    800059ca:	c979                	beqz	a0,80005aa0 <sys_unlink+0x114>
  ilock(dp);
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	226080e7          	jalr	550(ra) # 80003bf2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059d4:	00003597          	auipc	a1,0x3
    800059d8:	e2458593          	addi	a1,a1,-476 # 800087f8 <syscalls+0x2c0>
    800059dc:	fb040513          	addi	a0,s0,-80
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	6dc080e7          	jalr	1756(ra) # 800040bc <namecmp>
    800059e8:	14050a63          	beqz	a0,80005b3c <sys_unlink+0x1b0>
    800059ec:	00003597          	auipc	a1,0x3
    800059f0:	e1458593          	addi	a1,a1,-492 # 80008800 <syscalls+0x2c8>
    800059f4:	fb040513          	addi	a0,s0,-80
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	6c4080e7          	jalr	1732(ra) # 800040bc <namecmp>
    80005a00:	12050e63          	beqz	a0,80005b3c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a04:	f2c40613          	addi	a2,s0,-212
    80005a08:	fb040593          	addi	a1,s0,-80
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	6c8080e7          	jalr	1736(ra) # 800040d6 <dirlookup>
    80005a16:	892a                	mv	s2,a0
    80005a18:	12050263          	beqz	a0,80005b3c <sys_unlink+0x1b0>
  ilock(ip);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	1d6080e7          	jalr	470(ra) # 80003bf2 <ilock>
  if(ip->nlink < 1)
    80005a24:	04a91783          	lh	a5,74(s2)
    80005a28:	08f05263          	blez	a5,80005aac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a2c:	04491703          	lh	a4,68(s2)
    80005a30:	4785                	li	a5,1
    80005a32:	08f70563          	beq	a4,a5,80005abc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a36:	4641                	li	a2,16
    80005a38:	4581                	li	a1,0
    80005a3a:	fc040513          	addi	a0,s0,-64
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	2a2080e7          	jalr	674(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a46:	4741                	li	a4,16
    80005a48:	f2c42683          	lw	a3,-212(s0)
    80005a4c:	fc040613          	addi	a2,s0,-64
    80005a50:	4581                	li	a1,0
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	54a080e7          	jalr	1354(ra) # 80003f9e <writei>
    80005a5c:	47c1                	li	a5,16
    80005a5e:	0af51563          	bne	a0,a5,80005b08 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a62:	04491703          	lh	a4,68(s2)
    80005a66:	4785                	li	a5,1
    80005a68:	0af70863          	beq	a4,a5,80005b18 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	3e6080e7          	jalr	998(ra) # 80003e54 <iunlockput>
  ip->nlink--;
    80005a76:	04a95783          	lhu	a5,74(s2)
    80005a7a:	37fd                	addiw	a5,a5,-1
    80005a7c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	0a6080e7          	jalr	166(ra) # 80003b28 <iupdate>
  iunlockput(ip);
    80005a8a:	854a                	mv	a0,s2
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	3c8080e7          	jalr	968(ra) # 80003e54 <iunlockput>
  end_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	bb0080e7          	jalr	-1104(ra) # 80004644 <end_op>
  return 0;
    80005a9c:	4501                	li	a0,0
    80005a9e:	a84d                	j	80005b50 <sys_unlink+0x1c4>
    end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	ba4080e7          	jalr	-1116(ra) # 80004644 <end_op>
    return -1;
    80005aa8:	557d                	li	a0,-1
    80005aaa:	a05d                	j	80005b50 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005aac:	00003517          	auipc	a0,0x3
    80005ab0:	d7c50513          	addi	a0,a0,-644 # 80008828 <syscalls+0x2f0>
    80005ab4:	ffffb097          	auipc	ra,0xffffb
    80005ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005abc:	04c92703          	lw	a4,76(s2)
    80005ac0:	02000793          	li	a5,32
    80005ac4:	f6e7f9e3          	bgeu	a5,a4,80005a36 <sys_unlink+0xaa>
    80005ac8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005acc:	4741                	li	a4,16
    80005ace:	86ce                	mv	a3,s3
    80005ad0:	f1840613          	addi	a2,s0,-232
    80005ad4:	4581                	li	a1,0
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	3ce080e7          	jalr	974(ra) # 80003ea6 <readi>
    80005ae0:	47c1                	li	a5,16
    80005ae2:	00f51b63          	bne	a0,a5,80005af8 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ae6:	f1845783          	lhu	a5,-232(s0)
    80005aea:	e7a1                	bnez	a5,80005b32 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aec:	29c1                	addiw	s3,s3,16
    80005aee:	04c92783          	lw	a5,76(s2)
    80005af2:	fcf9ede3          	bltu	s3,a5,80005acc <sys_unlink+0x140>
    80005af6:	b781                	j	80005a36 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005af8:	00003517          	auipc	a0,0x3
    80005afc:	d4850513          	addi	a0,a0,-696 # 80008840 <syscalls+0x308>
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	a3e080e7          	jalr	-1474(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b08:	00003517          	auipc	a0,0x3
    80005b0c:	d5050513          	addi	a0,a0,-688 # 80008858 <syscalls+0x320>
    80005b10:	ffffb097          	auipc	ra,0xffffb
    80005b14:	a2e080e7          	jalr	-1490(ra) # 8000053e <panic>
    dp->nlink--;
    80005b18:	04a4d783          	lhu	a5,74(s1)
    80005b1c:	37fd                	addiw	a5,a5,-1
    80005b1e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	004080e7          	jalr	4(ra) # 80003b28 <iupdate>
    80005b2c:	b781                	j	80005a6c <sys_unlink+0xe0>
    return -1;
    80005b2e:	557d                	li	a0,-1
    80005b30:	a005                	j	80005b50 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b32:	854a                	mv	a0,s2
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	320080e7          	jalr	800(ra) # 80003e54 <iunlockput>
  iunlockput(dp);
    80005b3c:	8526                	mv	a0,s1
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	316080e7          	jalr	790(ra) # 80003e54 <iunlockput>
  end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	afe080e7          	jalr	-1282(ra) # 80004644 <end_op>
  return -1;
    80005b4e:	557d                	li	a0,-1
}
    80005b50:	70ae                	ld	ra,232(sp)
    80005b52:	740e                	ld	s0,224(sp)
    80005b54:	64ee                	ld	s1,216(sp)
    80005b56:	694e                	ld	s2,208(sp)
    80005b58:	69ae                	ld	s3,200(sp)
    80005b5a:	616d                	addi	sp,sp,240
    80005b5c:	8082                	ret

0000000080005b5e <sys_open>:

uint64
sys_open(void)
{
    80005b5e:	7131                	addi	sp,sp,-192
    80005b60:	fd06                	sd	ra,184(sp)
    80005b62:	f922                	sd	s0,176(sp)
    80005b64:	f526                	sd	s1,168(sp)
    80005b66:	f14a                	sd	s2,160(sp)
    80005b68:	ed4e                	sd	s3,152(sp)
    80005b6a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b6c:	08000613          	li	a2,128
    80005b70:	f5040593          	addi	a1,s0,-176
    80005b74:	4501                	li	a0,0
    80005b76:	ffffd097          	auipc	ra,0xffffd
    80005b7a:	304080e7          	jalr	772(ra) # 80002e7a <argstr>
    return -1;
    80005b7e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b80:	0c054163          	bltz	a0,80005c42 <sys_open+0xe4>
    80005b84:	f4c40593          	addi	a1,s0,-180
    80005b88:	4505                	li	a0,1
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	2ac080e7          	jalr	684(ra) # 80002e36 <argint>
    80005b92:	0a054863          	bltz	a0,80005c42 <sys_open+0xe4>

  begin_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	a2e080e7          	jalr	-1490(ra) # 800045c4 <begin_op>

  if(omode & O_CREATE){
    80005b9e:	f4c42783          	lw	a5,-180(s0)
    80005ba2:	2007f793          	andi	a5,a5,512
    80005ba6:	cbdd                	beqz	a5,80005c5c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ba8:	4681                	li	a3,0
    80005baa:	4601                	li	a2,0
    80005bac:	4589                	li	a1,2
    80005bae:	f5040513          	addi	a0,s0,-176
    80005bb2:	00000097          	auipc	ra,0x0
    80005bb6:	972080e7          	jalr	-1678(ra) # 80005524 <create>
    80005bba:	892a                	mv	s2,a0
    if(ip == 0){
    80005bbc:	c959                	beqz	a0,80005c52 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bbe:	04491703          	lh	a4,68(s2)
    80005bc2:	478d                	li	a5,3
    80005bc4:	00f71763          	bne	a4,a5,80005bd2 <sys_open+0x74>
    80005bc8:	04695703          	lhu	a4,70(s2)
    80005bcc:	47a5                	li	a5,9
    80005bce:	0ce7ec63          	bltu	a5,a4,80005ca6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	e02080e7          	jalr	-510(ra) # 800049d4 <filealloc>
    80005bda:	89aa                	mv	s3,a0
    80005bdc:	10050263          	beqz	a0,80005ce0 <sys_open+0x182>
    80005be0:	00000097          	auipc	ra,0x0
    80005be4:	902080e7          	jalr	-1790(ra) # 800054e2 <fdalloc>
    80005be8:	84aa                	mv	s1,a0
    80005bea:	0e054663          	bltz	a0,80005cd6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bee:	04491703          	lh	a4,68(s2)
    80005bf2:	478d                	li	a5,3
    80005bf4:	0cf70463          	beq	a4,a5,80005cbc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bf8:	4789                	li	a5,2
    80005bfa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bfe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c02:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c06:	f4c42783          	lw	a5,-180(s0)
    80005c0a:	0017c713          	xori	a4,a5,1
    80005c0e:	8b05                	andi	a4,a4,1
    80005c10:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c14:	0037f713          	andi	a4,a5,3
    80005c18:	00e03733          	snez	a4,a4
    80005c1c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c20:	4007f793          	andi	a5,a5,1024
    80005c24:	c791                	beqz	a5,80005c30 <sys_open+0xd2>
    80005c26:	04491703          	lh	a4,68(s2)
    80005c2a:	4789                	li	a5,2
    80005c2c:	08f70f63          	beq	a4,a5,80005cca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c30:	854a                	mv	a0,s2
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	082080e7          	jalr	130(ra) # 80003cb4 <iunlock>
  end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	a0a080e7          	jalr	-1526(ra) # 80004644 <end_op>

  return fd;
}
    80005c42:	8526                	mv	a0,s1
    80005c44:	70ea                	ld	ra,184(sp)
    80005c46:	744a                	ld	s0,176(sp)
    80005c48:	74aa                	ld	s1,168(sp)
    80005c4a:	790a                	ld	s2,160(sp)
    80005c4c:	69ea                	ld	s3,152(sp)
    80005c4e:	6129                	addi	sp,sp,192
    80005c50:	8082                	ret
      end_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	9f2080e7          	jalr	-1550(ra) # 80004644 <end_op>
      return -1;
    80005c5a:	b7e5                	j	80005c42 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c5c:	f5040513          	addi	a0,s0,-176
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	748080e7          	jalr	1864(ra) # 800043a8 <namei>
    80005c68:	892a                	mv	s2,a0
    80005c6a:	c905                	beqz	a0,80005c9a <sys_open+0x13c>
    ilock(ip);
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	f86080e7          	jalr	-122(ra) # 80003bf2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c74:	04491703          	lh	a4,68(s2)
    80005c78:	4785                	li	a5,1
    80005c7a:	f4f712e3          	bne	a4,a5,80005bbe <sys_open+0x60>
    80005c7e:	f4c42783          	lw	a5,-180(s0)
    80005c82:	dba1                	beqz	a5,80005bd2 <sys_open+0x74>
      iunlockput(ip);
    80005c84:	854a                	mv	a0,s2
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	1ce080e7          	jalr	462(ra) # 80003e54 <iunlockput>
      end_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	9b6080e7          	jalr	-1610(ra) # 80004644 <end_op>
      return -1;
    80005c96:	54fd                	li	s1,-1
    80005c98:	b76d                	j	80005c42 <sys_open+0xe4>
      end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	9aa080e7          	jalr	-1622(ra) # 80004644 <end_op>
      return -1;
    80005ca2:	54fd                	li	s1,-1
    80005ca4:	bf79                	j	80005c42 <sys_open+0xe4>
    iunlockput(ip);
    80005ca6:	854a                	mv	a0,s2
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	1ac080e7          	jalr	428(ra) # 80003e54 <iunlockput>
    end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	994080e7          	jalr	-1644(ra) # 80004644 <end_op>
    return -1;
    80005cb8:	54fd                	li	s1,-1
    80005cba:	b761                	j	80005c42 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cbc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cc0:	04691783          	lh	a5,70(s2)
    80005cc4:	02f99223          	sh	a5,36(s3)
    80005cc8:	bf2d                	j	80005c02 <sys_open+0xa4>
    itrunc(ip);
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	034080e7          	jalr	52(ra) # 80003d00 <itrunc>
    80005cd4:	bfb1                	j	80005c30 <sys_open+0xd2>
      fileclose(f);
    80005cd6:	854e                	mv	a0,s3
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	db8080e7          	jalr	-584(ra) # 80004a90 <fileclose>
    iunlockput(ip);
    80005ce0:	854a                	mv	a0,s2
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	172080e7          	jalr	370(ra) # 80003e54 <iunlockput>
    end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	95a080e7          	jalr	-1702(ra) # 80004644 <end_op>
    return -1;
    80005cf2:	54fd                	li	s1,-1
    80005cf4:	b7b9                	j	80005c42 <sys_open+0xe4>

0000000080005cf6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cf6:	7175                	addi	sp,sp,-144
    80005cf8:	e506                	sd	ra,136(sp)
    80005cfa:	e122                	sd	s0,128(sp)
    80005cfc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	8c6080e7          	jalr	-1850(ra) # 800045c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d06:	08000613          	li	a2,128
    80005d0a:	f7040593          	addi	a1,s0,-144
    80005d0e:	4501                	li	a0,0
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	16a080e7          	jalr	362(ra) # 80002e7a <argstr>
    80005d18:	02054963          	bltz	a0,80005d4a <sys_mkdir+0x54>
    80005d1c:	4681                	li	a3,0
    80005d1e:	4601                	li	a2,0
    80005d20:	4585                	li	a1,1
    80005d22:	f7040513          	addi	a0,s0,-144
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	7fe080e7          	jalr	2046(ra) # 80005524 <create>
    80005d2e:	cd11                	beqz	a0,80005d4a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	124080e7          	jalr	292(ra) # 80003e54 <iunlockput>
  end_op();
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	90c080e7          	jalr	-1780(ra) # 80004644 <end_op>
  return 0;
    80005d40:	4501                	li	a0,0
}
    80005d42:	60aa                	ld	ra,136(sp)
    80005d44:	640a                	ld	s0,128(sp)
    80005d46:	6149                	addi	sp,sp,144
    80005d48:	8082                	ret
    end_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	8fa080e7          	jalr	-1798(ra) # 80004644 <end_op>
    return -1;
    80005d52:	557d                	li	a0,-1
    80005d54:	b7fd                	j	80005d42 <sys_mkdir+0x4c>

0000000080005d56 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d56:	7135                	addi	sp,sp,-160
    80005d58:	ed06                	sd	ra,152(sp)
    80005d5a:	e922                	sd	s0,144(sp)
    80005d5c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	866080e7          	jalr	-1946(ra) # 800045c4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d66:	08000613          	li	a2,128
    80005d6a:	f7040593          	addi	a1,s0,-144
    80005d6e:	4501                	li	a0,0
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	10a080e7          	jalr	266(ra) # 80002e7a <argstr>
    80005d78:	04054a63          	bltz	a0,80005dcc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d7c:	f6c40593          	addi	a1,s0,-148
    80005d80:	4505                	li	a0,1
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	0b4080e7          	jalr	180(ra) # 80002e36 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d8a:	04054163          	bltz	a0,80005dcc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d8e:	f6840593          	addi	a1,s0,-152
    80005d92:	4509                	li	a0,2
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	0a2080e7          	jalr	162(ra) # 80002e36 <argint>
     argint(1, &major) < 0 ||
    80005d9c:	02054863          	bltz	a0,80005dcc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005da0:	f6841683          	lh	a3,-152(s0)
    80005da4:	f6c41603          	lh	a2,-148(s0)
    80005da8:	458d                	li	a1,3
    80005daa:	f7040513          	addi	a0,s0,-144
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	776080e7          	jalr	1910(ra) # 80005524 <create>
     argint(2, &minor) < 0 ||
    80005db6:	c919                	beqz	a0,80005dcc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	09c080e7          	jalr	156(ra) # 80003e54 <iunlockput>
  end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	884080e7          	jalr	-1916(ra) # 80004644 <end_op>
  return 0;
    80005dc8:	4501                	li	a0,0
    80005dca:	a031                	j	80005dd6 <sys_mknod+0x80>
    end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	878080e7          	jalr	-1928(ra) # 80004644 <end_op>
    return -1;
    80005dd4:	557d                	li	a0,-1
}
    80005dd6:	60ea                	ld	ra,152(sp)
    80005dd8:	644a                	ld	s0,144(sp)
    80005dda:	610d                	addi	sp,sp,160
    80005ddc:	8082                	ret

0000000080005dde <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dde:	7135                	addi	sp,sp,-160
    80005de0:	ed06                	sd	ra,152(sp)
    80005de2:	e922                	sd	s0,144(sp)
    80005de4:	e526                	sd	s1,136(sp)
    80005de6:	e14a                	sd	s2,128(sp)
    80005de8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dea:	ffffc097          	auipc	ra,0xffffc
    80005dee:	cec080e7          	jalr	-788(ra) # 80001ad6 <myproc>
    80005df2:	892a                	mv	s2,a0
  
  begin_op();
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	7d0080e7          	jalr	2000(ra) # 800045c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dfc:	08000613          	li	a2,128
    80005e00:	f6040593          	addi	a1,s0,-160
    80005e04:	4501                	li	a0,0
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	074080e7          	jalr	116(ra) # 80002e7a <argstr>
    80005e0e:	04054b63          	bltz	a0,80005e64 <sys_chdir+0x86>
    80005e12:	f6040513          	addi	a0,s0,-160
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	592080e7          	jalr	1426(ra) # 800043a8 <namei>
    80005e1e:	84aa                	mv	s1,a0
    80005e20:	c131                	beqz	a0,80005e64 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	dd0080e7          	jalr	-560(ra) # 80003bf2 <ilock>
  if(ip->type != T_DIR){
    80005e2a:	04449703          	lh	a4,68(s1)
    80005e2e:	4785                	li	a5,1
    80005e30:	04f71063          	bne	a4,a5,80005e70 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e34:	8526                	mv	a0,s1
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	e7e080e7          	jalr	-386(ra) # 80003cb4 <iunlock>
  iput(p->cwd);
    80005e3e:	15093503          	ld	a0,336(s2)
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	f6a080e7          	jalr	-150(ra) # 80003dac <iput>
  end_op();
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	7fa080e7          	jalr	2042(ra) # 80004644 <end_op>
  p->cwd = ip;
    80005e52:	14993823          	sd	s1,336(s2)
  return 0;
    80005e56:	4501                	li	a0,0
}
    80005e58:	60ea                	ld	ra,152(sp)
    80005e5a:	644a                	ld	s0,144(sp)
    80005e5c:	64aa                	ld	s1,136(sp)
    80005e5e:	690a                	ld	s2,128(sp)
    80005e60:	610d                	addi	sp,sp,160
    80005e62:	8082                	ret
    end_op();
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	7e0080e7          	jalr	2016(ra) # 80004644 <end_op>
    return -1;
    80005e6c:	557d                	li	a0,-1
    80005e6e:	b7ed                	j	80005e58 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e70:	8526                	mv	a0,s1
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	fe2080e7          	jalr	-30(ra) # 80003e54 <iunlockput>
    end_op();
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	7ca080e7          	jalr	1994(ra) # 80004644 <end_op>
    return -1;
    80005e82:	557d                	li	a0,-1
    80005e84:	bfd1                	j	80005e58 <sys_chdir+0x7a>

0000000080005e86 <sys_exec>:

uint64
sys_exec(void)
{
    80005e86:	7145                	addi	sp,sp,-464
    80005e88:	e786                	sd	ra,456(sp)
    80005e8a:	e3a2                	sd	s0,448(sp)
    80005e8c:	ff26                	sd	s1,440(sp)
    80005e8e:	fb4a                	sd	s2,432(sp)
    80005e90:	f74e                	sd	s3,424(sp)
    80005e92:	f352                	sd	s4,416(sp)
    80005e94:	ef56                	sd	s5,408(sp)
    80005e96:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e98:	08000613          	li	a2,128
    80005e9c:	f4040593          	addi	a1,s0,-192
    80005ea0:	4501                	li	a0,0
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	fd8080e7          	jalr	-40(ra) # 80002e7a <argstr>
    return -1;
    80005eaa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005eac:	0c054a63          	bltz	a0,80005f80 <sys_exec+0xfa>
    80005eb0:	e3840593          	addi	a1,s0,-456
    80005eb4:	4505                	li	a0,1
    80005eb6:	ffffd097          	auipc	ra,0xffffd
    80005eba:	fa2080e7          	jalr	-94(ra) # 80002e58 <argaddr>
    80005ebe:	0c054163          	bltz	a0,80005f80 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ec2:	10000613          	li	a2,256
    80005ec6:	4581                	li	a1,0
    80005ec8:	e4040513          	addi	a0,s0,-448
    80005ecc:	ffffb097          	auipc	ra,0xffffb
    80005ed0:	e14080e7          	jalr	-492(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ed4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ed8:	89a6                	mv	s3,s1
    80005eda:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005edc:	02000a13          	li	s4,32
    80005ee0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ee4:	00391513          	slli	a0,s2,0x3
    80005ee8:	e3040593          	addi	a1,s0,-464
    80005eec:	e3843783          	ld	a5,-456(s0)
    80005ef0:	953e                	add	a0,a0,a5
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	eaa080e7          	jalr	-342(ra) # 80002d9c <fetchaddr>
    80005efa:	02054a63          	bltz	a0,80005f2e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005efe:	e3043783          	ld	a5,-464(s0)
    80005f02:	c3b9                	beqz	a5,80005f48 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	bf0080e7          	jalr	-1040(ra) # 80000af4 <kalloc>
    80005f0c:	85aa                	mv	a1,a0
    80005f0e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f12:	cd11                	beqz	a0,80005f2e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f14:	6605                	lui	a2,0x1
    80005f16:	e3043503          	ld	a0,-464(s0)
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	ed4080e7          	jalr	-300(ra) # 80002dee <fetchstr>
    80005f22:	00054663          	bltz	a0,80005f2e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f26:	0905                	addi	s2,s2,1
    80005f28:	09a1                	addi	s3,s3,8
    80005f2a:	fb491be3          	bne	s2,s4,80005ee0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f2e:	10048913          	addi	s2,s1,256
    80005f32:	6088                	ld	a0,0(s1)
    80005f34:	c529                	beqz	a0,80005f7e <sys_exec+0xf8>
    kfree(argv[i]);
    80005f36:	ffffb097          	auipc	ra,0xffffb
    80005f3a:	ac2080e7          	jalr	-1342(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f3e:	04a1                	addi	s1,s1,8
    80005f40:	ff2499e3          	bne	s1,s2,80005f32 <sys_exec+0xac>
  return -1;
    80005f44:	597d                	li	s2,-1
    80005f46:	a82d                	j	80005f80 <sys_exec+0xfa>
      argv[i] = 0;
    80005f48:	0a8e                	slli	s5,s5,0x3
    80005f4a:	fc040793          	addi	a5,s0,-64
    80005f4e:	9abe                	add	s5,s5,a5
    80005f50:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f54:	e4040593          	addi	a1,s0,-448
    80005f58:	f4040513          	addi	a0,s0,-192
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	194080e7          	jalr	404(ra) # 800050f0 <exec>
    80005f64:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f66:	10048993          	addi	s3,s1,256
    80005f6a:	6088                	ld	a0,0(s1)
    80005f6c:	c911                	beqz	a0,80005f80 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	a8a080e7          	jalr	-1398(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f76:	04a1                	addi	s1,s1,8
    80005f78:	ff3499e3          	bne	s1,s3,80005f6a <sys_exec+0xe4>
    80005f7c:	a011                	j	80005f80 <sys_exec+0xfa>
  return -1;
    80005f7e:	597d                	li	s2,-1
}
    80005f80:	854a                	mv	a0,s2
    80005f82:	60be                	ld	ra,456(sp)
    80005f84:	641e                	ld	s0,448(sp)
    80005f86:	74fa                	ld	s1,440(sp)
    80005f88:	795a                	ld	s2,432(sp)
    80005f8a:	79ba                	ld	s3,424(sp)
    80005f8c:	7a1a                	ld	s4,416(sp)
    80005f8e:	6afa                	ld	s5,408(sp)
    80005f90:	6179                	addi	sp,sp,464
    80005f92:	8082                	ret

0000000080005f94 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f94:	7139                	addi	sp,sp,-64
    80005f96:	fc06                	sd	ra,56(sp)
    80005f98:	f822                	sd	s0,48(sp)
    80005f9a:	f426                	sd	s1,40(sp)
    80005f9c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f9e:	ffffc097          	auipc	ra,0xffffc
    80005fa2:	b38080e7          	jalr	-1224(ra) # 80001ad6 <myproc>
    80005fa6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fa8:	fd840593          	addi	a1,s0,-40
    80005fac:	4501                	li	a0,0
    80005fae:	ffffd097          	auipc	ra,0xffffd
    80005fb2:	eaa080e7          	jalr	-342(ra) # 80002e58 <argaddr>
    return -1;
    80005fb6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fb8:	0e054063          	bltz	a0,80006098 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fbc:	fc840593          	addi	a1,s0,-56
    80005fc0:	fd040513          	addi	a0,s0,-48
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	dfc080e7          	jalr	-516(ra) # 80004dc0 <pipealloc>
    return -1;
    80005fcc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fce:	0c054563          	bltz	a0,80006098 <sys_pipe+0x104>
  fd0 = -1;
    80005fd2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fd6:	fd043503          	ld	a0,-48(s0)
    80005fda:	fffff097          	auipc	ra,0xfffff
    80005fde:	508080e7          	jalr	1288(ra) # 800054e2 <fdalloc>
    80005fe2:	fca42223          	sw	a0,-60(s0)
    80005fe6:	08054c63          	bltz	a0,8000607e <sys_pipe+0xea>
    80005fea:	fc843503          	ld	a0,-56(s0)
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	4f4080e7          	jalr	1268(ra) # 800054e2 <fdalloc>
    80005ff6:	fca42023          	sw	a0,-64(s0)
    80005ffa:	06054863          	bltz	a0,8000606a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ffe:	4691                	li	a3,4
    80006000:	fc440613          	addi	a2,s0,-60
    80006004:	fd843583          	ld	a1,-40(s0)
    80006008:	68a8                	ld	a0,80(s1)
    8000600a:	ffffb097          	auipc	ra,0xffffb
    8000600e:	670080e7          	jalr	1648(ra) # 8000167a <copyout>
    80006012:	02054063          	bltz	a0,80006032 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006016:	4691                	li	a3,4
    80006018:	fc040613          	addi	a2,s0,-64
    8000601c:	fd843583          	ld	a1,-40(s0)
    80006020:	0591                	addi	a1,a1,4
    80006022:	68a8                	ld	a0,80(s1)
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	656080e7          	jalr	1622(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000602c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000602e:	06055563          	bgez	a0,80006098 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006032:	fc442783          	lw	a5,-60(s0)
    80006036:	07e9                	addi	a5,a5,26
    80006038:	078e                	slli	a5,a5,0x3
    8000603a:	97a6                	add	a5,a5,s1
    8000603c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006040:	fc042503          	lw	a0,-64(s0)
    80006044:	0569                	addi	a0,a0,26
    80006046:	050e                	slli	a0,a0,0x3
    80006048:	9526                	add	a0,a0,s1
    8000604a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000604e:	fd043503          	ld	a0,-48(s0)
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	a3e080e7          	jalr	-1474(ra) # 80004a90 <fileclose>
    fileclose(wf);
    8000605a:	fc843503          	ld	a0,-56(s0)
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	a32080e7          	jalr	-1486(ra) # 80004a90 <fileclose>
    return -1;
    80006066:	57fd                	li	a5,-1
    80006068:	a805                	j	80006098 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000606a:	fc442783          	lw	a5,-60(s0)
    8000606e:	0007c863          	bltz	a5,8000607e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006072:	01a78513          	addi	a0,a5,26
    80006076:	050e                	slli	a0,a0,0x3
    80006078:	9526                	add	a0,a0,s1
    8000607a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000607e:	fd043503          	ld	a0,-48(s0)
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	a0e080e7          	jalr	-1522(ra) # 80004a90 <fileclose>
    fileclose(wf);
    8000608a:	fc843503          	ld	a0,-56(s0)
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	a02080e7          	jalr	-1534(ra) # 80004a90 <fileclose>
    return -1;
    80006096:	57fd                	li	a5,-1
}
    80006098:	853e                	mv	a0,a5
    8000609a:	70e2                	ld	ra,56(sp)
    8000609c:	7442                	ld	s0,48(sp)
    8000609e:	74a2                	ld	s1,40(sp)
    800060a0:	6121                	addi	sp,sp,64
    800060a2:	8082                	ret
	...

00000000800060b0 <kernelvec>:
    800060b0:	7111                	addi	sp,sp,-256
    800060b2:	e006                	sd	ra,0(sp)
    800060b4:	e40a                	sd	sp,8(sp)
    800060b6:	e80e                	sd	gp,16(sp)
    800060b8:	ec12                	sd	tp,24(sp)
    800060ba:	f016                	sd	t0,32(sp)
    800060bc:	f41a                	sd	t1,40(sp)
    800060be:	f81e                	sd	t2,48(sp)
    800060c0:	fc22                	sd	s0,56(sp)
    800060c2:	e0a6                	sd	s1,64(sp)
    800060c4:	e4aa                	sd	a0,72(sp)
    800060c6:	e8ae                	sd	a1,80(sp)
    800060c8:	ecb2                	sd	a2,88(sp)
    800060ca:	f0b6                	sd	a3,96(sp)
    800060cc:	f4ba                	sd	a4,104(sp)
    800060ce:	f8be                	sd	a5,112(sp)
    800060d0:	fcc2                	sd	a6,120(sp)
    800060d2:	e146                	sd	a7,128(sp)
    800060d4:	e54a                	sd	s2,136(sp)
    800060d6:	e94e                	sd	s3,144(sp)
    800060d8:	ed52                	sd	s4,152(sp)
    800060da:	f156                	sd	s5,160(sp)
    800060dc:	f55a                	sd	s6,168(sp)
    800060de:	f95e                	sd	s7,176(sp)
    800060e0:	fd62                	sd	s8,184(sp)
    800060e2:	e1e6                	sd	s9,192(sp)
    800060e4:	e5ea                	sd	s10,200(sp)
    800060e6:	e9ee                	sd	s11,208(sp)
    800060e8:	edf2                	sd	t3,216(sp)
    800060ea:	f1f6                	sd	t4,224(sp)
    800060ec:	f5fa                	sd	t5,232(sp)
    800060ee:	f9fe                	sd	t6,240(sp)
    800060f0:	ba3fc0ef          	jal	ra,80002c92 <kerneltrap>
    800060f4:	6082                	ld	ra,0(sp)
    800060f6:	6122                	ld	sp,8(sp)
    800060f8:	61c2                	ld	gp,16(sp)
    800060fa:	7282                	ld	t0,32(sp)
    800060fc:	7322                	ld	t1,40(sp)
    800060fe:	73c2                	ld	t2,48(sp)
    80006100:	7462                	ld	s0,56(sp)
    80006102:	6486                	ld	s1,64(sp)
    80006104:	6526                	ld	a0,72(sp)
    80006106:	65c6                	ld	a1,80(sp)
    80006108:	6666                	ld	a2,88(sp)
    8000610a:	7686                	ld	a3,96(sp)
    8000610c:	7726                	ld	a4,104(sp)
    8000610e:	77c6                	ld	a5,112(sp)
    80006110:	7866                	ld	a6,120(sp)
    80006112:	688a                	ld	a7,128(sp)
    80006114:	692a                	ld	s2,136(sp)
    80006116:	69ca                	ld	s3,144(sp)
    80006118:	6a6a                	ld	s4,152(sp)
    8000611a:	7a8a                	ld	s5,160(sp)
    8000611c:	7b2a                	ld	s6,168(sp)
    8000611e:	7bca                	ld	s7,176(sp)
    80006120:	7c6a                	ld	s8,184(sp)
    80006122:	6c8e                	ld	s9,192(sp)
    80006124:	6d2e                	ld	s10,200(sp)
    80006126:	6dce                	ld	s11,208(sp)
    80006128:	6e6e                	ld	t3,216(sp)
    8000612a:	7e8e                	ld	t4,224(sp)
    8000612c:	7f2e                	ld	t5,232(sp)
    8000612e:	7fce                	ld	t6,240(sp)
    80006130:	6111                	addi	sp,sp,256
    80006132:	10200073          	sret
    80006136:	00000013          	nop
    8000613a:	00000013          	nop
    8000613e:	0001                	nop

0000000080006140 <timervec>:
    80006140:	34051573          	csrrw	a0,mscratch,a0
    80006144:	e10c                	sd	a1,0(a0)
    80006146:	e510                	sd	a2,8(a0)
    80006148:	e914                	sd	a3,16(a0)
    8000614a:	6d0c                	ld	a1,24(a0)
    8000614c:	7110                	ld	a2,32(a0)
    8000614e:	6194                	ld	a3,0(a1)
    80006150:	96b2                	add	a3,a3,a2
    80006152:	e194                	sd	a3,0(a1)
    80006154:	4589                	li	a1,2
    80006156:	14459073          	csrw	sip,a1
    8000615a:	6914                	ld	a3,16(a0)
    8000615c:	6510                	ld	a2,8(a0)
    8000615e:	610c                	ld	a1,0(a0)
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	30200073          	mret
	...

000000008000616a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000616a:	1141                	addi	sp,sp,-16
    8000616c:	e422                	sd	s0,8(sp)
    8000616e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006170:	0c0007b7          	lui	a5,0xc000
    80006174:	4705                	li	a4,1
    80006176:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006178:	c3d8                	sw	a4,4(a5)
}
    8000617a:	6422                	ld	s0,8(sp)
    8000617c:	0141                	addi	sp,sp,16
    8000617e:	8082                	ret

0000000080006180 <plicinithart>:

void
plicinithart(void)
{
    80006180:	1141                	addi	sp,sp,-16
    80006182:	e406                	sd	ra,8(sp)
    80006184:	e022                	sd	s0,0(sp)
    80006186:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	922080e7          	jalr	-1758(ra) # 80001aaa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006190:	0085171b          	slliw	a4,a0,0x8
    80006194:	0c0027b7          	lui	a5,0xc002
    80006198:	97ba                	add	a5,a5,a4
    8000619a:	40200713          	li	a4,1026
    8000619e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061a2:	00d5151b          	slliw	a0,a0,0xd
    800061a6:	0c2017b7          	lui	a5,0xc201
    800061aa:	953e                	add	a0,a0,a5
    800061ac:	00052023          	sw	zero,0(a0)
}
    800061b0:	60a2                	ld	ra,8(sp)
    800061b2:	6402                	ld	s0,0(sp)
    800061b4:	0141                	addi	sp,sp,16
    800061b6:	8082                	ret

00000000800061b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061b8:	1141                	addi	sp,sp,-16
    800061ba:	e406                	sd	ra,8(sp)
    800061bc:	e022                	sd	s0,0(sp)
    800061be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061c0:	ffffc097          	auipc	ra,0xffffc
    800061c4:	8ea080e7          	jalr	-1814(ra) # 80001aaa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061c8:	00d5179b          	slliw	a5,a0,0xd
    800061cc:	0c201537          	lui	a0,0xc201
    800061d0:	953e                	add	a0,a0,a5
  return irq;
}
    800061d2:	4148                	lw	a0,4(a0)
    800061d4:	60a2                	ld	ra,8(sp)
    800061d6:	6402                	ld	s0,0(sp)
    800061d8:	0141                	addi	sp,sp,16
    800061da:	8082                	ret

00000000800061dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061dc:	1101                	addi	sp,sp,-32
    800061de:	ec06                	sd	ra,24(sp)
    800061e0:	e822                	sd	s0,16(sp)
    800061e2:	e426                	sd	s1,8(sp)
    800061e4:	1000                	addi	s0,sp,32
    800061e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	8c2080e7          	jalr	-1854(ra) # 80001aaa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061f0:	00d5151b          	slliw	a0,a0,0xd
    800061f4:	0c2017b7          	lui	a5,0xc201
    800061f8:	97aa                	add	a5,a5,a0
    800061fa:	c3c4                	sw	s1,4(a5)
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6105                	addi	sp,sp,32
    80006204:	8082                	ret

0000000080006206 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006206:	1141                	addi	sp,sp,-16
    80006208:	e406                	sd	ra,8(sp)
    8000620a:	e022                	sd	s0,0(sp)
    8000620c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000620e:	479d                	li	a5,7
    80006210:	06a7c963          	blt	a5,a0,80006282 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006214:	0001f797          	auipc	a5,0x1f
    80006218:	dec78793          	addi	a5,a5,-532 # 80025000 <disk>
    8000621c:	00a78733          	add	a4,a5,a0
    80006220:	6789                	lui	a5,0x2
    80006222:	97ba                	add	a5,a5,a4
    80006224:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006228:	e7ad                	bnez	a5,80006292 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000622a:	00451793          	slli	a5,a0,0x4
    8000622e:	00021717          	auipc	a4,0x21
    80006232:	dd270713          	addi	a4,a4,-558 # 80027000 <disk+0x2000>
    80006236:	6314                	ld	a3,0(a4)
    80006238:	96be                	add	a3,a3,a5
    8000623a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000623e:	6314                	ld	a3,0(a4)
    80006240:	96be                	add	a3,a3,a5
    80006242:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006246:	6314                	ld	a3,0(a4)
    80006248:	96be                	add	a3,a3,a5
    8000624a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000624e:	6318                	ld	a4,0(a4)
    80006250:	97ba                	add	a5,a5,a4
    80006252:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006256:	0001f797          	auipc	a5,0x1f
    8000625a:	daa78793          	addi	a5,a5,-598 # 80025000 <disk>
    8000625e:	97aa                	add	a5,a5,a0
    80006260:	6509                	lui	a0,0x2
    80006262:	953e                	add	a0,a0,a5
    80006264:	4785                	li	a5,1
    80006266:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000626a:	00021517          	auipc	a0,0x21
    8000626e:	dae50513          	addi	a0,a0,-594 # 80027018 <disk+0x2018>
    80006272:	ffffc097          	auipc	ra,0xffffc
    80006276:	2e8080e7          	jalr	744(ra) # 8000255a <wakeup>
}
    8000627a:	60a2                	ld	ra,8(sp)
    8000627c:	6402                	ld	s0,0(sp)
    8000627e:	0141                	addi	sp,sp,16
    80006280:	8082                	ret
    panic("free_desc 1");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	5e650513          	addi	a0,a0,1510 # 80008868 <syscalls+0x330>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	5e650513          	addi	a0,a0,1510 # 80008878 <syscalls+0x340>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a4080e7          	jalr	676(ra) # 8000053e <panic>

00000000800062a2 <virtio_disk_init>:
{
    800062a2:	1101                	addi	sp,sp,-32
    800062a4:	ec06                	sd	ra,24(sp)
    800062a6:	e822                	sd	s0,16(sp)
    800062a8:	e426                	sd	s1,8(sp)
    800062aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062ac:	00002597          	auipc	a1,0x2
    800062b0:	5dc58593          	addi	a1,a1,1500 # 80008888 <syscalls+0x350>
    800062b4:	00021517          	auipc	a0,0x21
    800062b8:	e7450513          	addi	a0,a0,-396 # 80027128 <disk+0x2128>
    800062bc:	ffffb097          	auipc	ra,0xffffb
    800062c0:	898080e7          	jalr	-1896(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062c4:	100017b7          	lui	a5,0x10001
    800062c8:	4398                	lw	a4,0(a5)
    800062ca:	2701                	sext.w	a4,a4
    800062cc:	747277b7          	lui	a5,0x74727
    800062d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062d4:	0ef71163          	bne	a4,a5,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	43dc                	lw	a5,4(a5)
    800062de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e0:	4705                	li	a4,1
    800062e2:	0ce79a63          	bne	a5,a4,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062e6:	100017b7          	lui	a5,0x10001
    800062ea:	479c                	lw	a5,8(a5)
    800062ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062ee:	4709                	li	a4,2
    800062f0:	0ce79363          	bne	a5,a4,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062f4:	100017b7          	lui	a5,0x10001
    800062f8:	47d8                	lw	a4,12(a5)
    800062fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062fc:	554d47b7          	lui	a5,0x554d4
    80006300:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006304:	0af71963          	bne	a4,a5,800063b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006308:	100017b7          	lui	a5,0x10001
    8000630c:	4705                	li	a4,1
    8000630e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006310:	470d                	li	a4,3
    80006312:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006314:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006316:	c7ffe737          	lui	a4,0xc7ffe
    8000631a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    8000631e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006320:	2701                	sext.w	a4,a4
    80006322:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006324:	472d                	li	a4,11
    80006326:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006328:	473d                	li	a4,15
    8000632a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000632c:	6705                	lui	a4,0x1
    8000632e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006330:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006334:	5bdc                	lw	a5,52(a5)
    80006336:	2781                	sext.w	a5,a5
  if(max == 0)
    80006338:	c7d9                	beqz	a5,800063c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000633a:	471d                	li	a4,7
    8000633c:	08f77d63          	bgeu	a4,a5,800063d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006340:	100014b7          	lui	s1,0x10001
    80006344:	47a1                	li	a5,8
    80006346:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006348:	6609                	lui	a2,0x2
    8000634a:	4581                	li	a1,0
    8000634c:	0001f517          	auipc	a0,0x1f
    80006350:	cb450513          	addi	a0,a0,-844 # 80025000 <disk>
    80006354:	ffffb097          	auipc	ra,0xffffb
    80006358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000635c:	0001f717          	auipc	a4,0x1f
    80006360:	ca470713          	addi	a4,a4,-860 # 80025000 <disk>
    80006364:	00c75793          	srli	a5,a4,0xc
    80006368:	2781                	sext.w	a5,a5
    8000636a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000636c:	00021797          	auipc	a5,0x21
    80006370:	c9478793          	addi	a5,a5,-876 # 80027000 <disk+0x2000>
    80006374:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006376:	0001f717          	auipc	a4,0x1f
    8000637a:	d0a70713          	addi	a4,a4,-758 # 80025080 <disk+0x80>
    8000637e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006380:	00020717          	auipc	a4,0x20
    80006384:	c8070713          	addi	a4,a4,-896 # 80026000 <disk+0x1000>
    80006388:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000638a:	4705                	li	a4,1
    8000638c:	00e78c23          	sb	a4,24(a5)
    80006390:	00e78ca3          	sb	a4,25(a5)
    80006394:	00e78d23          	sb	a4,26(a5)
    80006398:	00e78da3          	sb	a4,27(a5)
    8000639c:	00e78e23          	sb	a4,28(a5)
    800063a0:	00e78ea3          	sb	a4,29(a5)
    800063a4:	00e78f23          	sb	a4,30(a5)
    800063a8:	00e78fa3          	sb	a4,31(a5)
}
    800063ac:	60e2                	ld	ra,24(sp)
    800063ae:	6442                	ld	s0,16(sp)
    800063b0:	64a2                	ld	s1,8(sp)
    800063b2:	6105                	addi	sp,sp,32
    800063b4:	8082                	ret
    panic("could not find virtio disk");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	4e250513          	addi	a0,a0,1250 # 80008898 <syscalls+0x360>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	180080e7          	jalr	384(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	4f250513          	addi	a0,a0,1266 # 800088b8 <syscalls+0x380>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	50250513          	addi	a0,a0,1282 # 800088d8 <syscalls+0x3a0>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>

00000000800063e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063e6:	7159                	addi	sp,sp,-112
    800063e8:	f486                	sd	ra,104(sp)
    800063ea:	f0a2                	sd	s0,96(sp)
    800063ec:	eca6                	sd	s1,88(sp)
    800063ee:	e8ca                	sd	s2,80(sp)
    800063f0:	e4ce                	sd	s3,72(sp)
    800063f2:	e0d2                	sd	s4,64(sp)
    800063f4:	fc56                	sd	s5,56(sp)
    800063f6:	f85a                	sd	s6,48(sp)
    800063f8:	f45e                	sd	s7,40(sp)
    800063fa:	f062                	sd	s8,32(sp)
    800063fc:	ec66                	sd	s9,24(sp)
    800063fe:	e86a                	sd	s10,16(sp)
    80006400:	1880                	addi	s0,sp,112
    80006402:	892a                	mv	s2,a0
    80006404:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006406:	00c52c83          	lw	s9,12(a0)
    8000640a:	001c9c9b          	slliw	s9,s9,0x1
    8000640e:	1c82                	slli	s9,s9,0x20
    80006410:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006414:	00021517          	auipc	a0,0x21
    80006418:	d1450513          	addi	a0,a0,-748 # 80027128 <disk+0x2128>
    8000641c:	ffffa097          	auipc	ra,0xffffa
    80006420:	7c8080e7          	jalr	1992(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006424:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006426:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006428:	0001fb97          	auipc	s7,0x1f
    8000642c:	bd8b8b93          	addi	s7,s7,-1064 # 80025000 <disk>
    80006430:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006432:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006434:	8a4e                	mv	s4,s3
    80006436:	a051                	j	800064ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006438:	00fb86b3          	add	a3,s7,a5
    8000643c:	96da                	add	a3,a3,s6
    8000643e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006442:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006444:	0207c563          	bltz	a5,8000646e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006448:	2485                	addiw	s1,s1,1
    8000644a:	0711                	addi	a4,a4,4
    8000644c:	25548063          	beq	s1,s5,8000668c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006450:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006452:	00021697          	auipc	a3,0x21
    80006456:	bc668693          	addi	a3,a3,-1082 # 80027018 <disk+0x2018>
    8000645a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000645c:	0006c583          	lbu	a1,0(a3)
    80006460:	fde1                	bnez	a1,80006438 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006462:	2785                	addiw	a5,a5,1
    80006464:	0685                	addi	a3,a3,1
    80006466:	ff879be3          	bne	a5,s8,8000645c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000646a:	57fd                	li	a5,-1
    8000646c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000646e:	02905a63          	blez	s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006472:	f9042503          	lw	a0,-112(s0)
    80006476:	00000097          	auipc	ra,0x0
    8000647a:	d90080e7          	jalr	-624(ra) # 80006206 <free_desc>
      for(int j = 0; j < i; j++)
    8000647e:	4785                	li	a5,1
    80006480:	0297d163          	bge	a5,s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006484:	f9442503          	lw	a0,-108(s0)
    80006488:	00000097          	auipc	ra,0x0
    8000648c:	d7e080e7          	jalr	-642(ra) # 80006206 <free_desc>
      for(int j = 0; j < i; j++)
    80006490:	4789                	li	a5,2
    80006492:	0097d863          	bge	a5,s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006496:	f9842503          	lw	a0,-104(s0)
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	d6c080e7          	jalr	-660(ra) # 80006206 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064a2:	00021597          	auipc	a1,0x21
    800064a6:	c8658593          	addi	a1,a1,-890 # 80027128 <disk+0x2128>
    800064aa:	00021517          	auipc	a0,0x21
    800064ae:	b6e50513          	addi	a0,a0,-1170 # 80027018 <disk+0x2018>
    800064b2:	ffffc097          	auipc	ra,0xffffc
    800064b6:	dd0080e7          	jalr	-560(ra) # 80002282 <sleep>
  for(int i = 0; i < 3; i++){
    800064ba:	f9040713          	addi	a4,s0,-112
    800064be:	84ce                	mv	s1,s3
    800064c0:	bf41                	j	80006450 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064c2:	20058713          	addi	a4,a1,512
    800064c6:	00471693          	slli	a3,a4,0x4
    800064ca:	0001f717          	auipc	a4,0x1f
    800064ce:	b3670713          	addi	a4,a4,-1226 # 80025000 <disk>
    800064d2:	9736                	add	a4,a4,a3
    800064d4:	4685                	li	a3,1
    800064d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064da:	20058713          	addi	a4,a1,512
    800064de:	00471693          	slli	a3,a4,0x4
    800064e2:	0001f717          	auipc	a4,0x1f
    800064e6:	b1e70713          	addi	a4,a4,-1250 # 80025000 <disk>
    800064ea:	9736                	add	a4,a4,a3
    800064ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064f4:	7679                	lui	a2,0xffffe
    800064f6:	963e                	add	a2,a2,a5
    800064f8:	00021697          	auipc	a3,0x21
    800064fc:	b0868693          	addi	a3,a3,-1272 # 80027000 <disk+0x2000>
    80006500:	6298                	ld	a4,0(a3)
    80006502:	9732                	add	a4,a4,a2
    80006504:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006506:	6298                	ld	a4,0(a3)
    80006508:	9732                	add	a4,a4,a2
    8000650a:	4541                	li	a0,16
    8000650c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000650e:	6298                	ld	a4,0(a3)
    80006510:	9732                	add	a4,a4,a2
    80006512:	4505                	li	a0,1
    80006514:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006518:	f9442703          	lw	a4,-108(s0)
    8000651c:	6288                	ld	a0,0(a3)
    8000651e:	962a                	add	a2,a2,a0
    80006520:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006524:	0712                	slli	a4,a4,0x4
    80006526:	6290                	ld	a2,0(a3)
    80006528:	963a                	add	a2,a2,a4
    8000652a:	05890513          	addi	a0,s2,88
    8000652e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006530:	6294                	ld	a3,0(a3)
    80006532:	96ba                	add	a3,a3,a4
    80006534:	40000613          	li	a2,1024
    80006538:	c690                	sw	a2,8(a3)
  if(write)
    8000653a:	140d0063          	beqz	s10,8000667a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000653e:	00021697          	auipc	a3,0x21
    80006542:	ac26b683          	ld	a3,-1342(a3) # 80027000 <disk+0x2000>
    80006546:	96ba                	add	a3,a3,a4
    80006548:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000654c:	0001f817          	auipc	a6,0x1f
    80006550:	ab480813          	addi	a6,a6,-1356 # 80025000 <disk>
    80006554:	00021517          	auipc	a0,0x21
    80006558:	aac50513          	addi	a0,a0,-1364 # 80027000 <disk+0x2000>
    8000655c:	6114                	ld	a3,0(a0)
    8000655e:	96ba                	add	a3,a3,a4
    80006560:	00c6d603          	lhu	a2,12(a3)
    80006564:	00166613          	ori	a2,a2,1
    80006568:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000656c:	f9842683          	lw	a3,-104(s0)
    80006570:	6110                	ld	a2,0(a0)
    80006572:	9732                	add	a4,a4,a2
    80006574:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006578:	20058613          	addi	a2,a1,512
    8000657c:	0612                	slli	a2,a2,0x4
    8000657e:	9642                	add	a2,a2,a6
    80006580:	577d                	li	a4,-1
    80006582:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006586:	00469713          	slli	a4,a3,0x4
    8000658a:	6114                	ld	a3,0(a0)
    8000658c:	96ba                	add	a3,a3,a4
    8000658e:	03078793          	addi	a5,a5,48
    80006592:	97c2                	add	a5,a5,a6
    80006594:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006596:	611c                	ld	a5,0(a0)
    80006598:	97ba                	add	a5,a5,a4
    8000659a:	4685                	li	a3,1
    8000659c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000659e:	611c                	ld	a5,0(a0)
    800065a0:	97ba                	add	a5,a5,a4
    800065a2:	4809                	li	a6,2
    800065a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065a8:	611c                	ld	a5,0(a0)
    800065aa:	973e                	add	a4,a4,a5
    800065ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065b8:	6518                	ld	a4,8(a0)
    800065ba:	00275783          	lhu	a5,2(a4)
    800065be:	8b9d                	andi	a5,a5,7
    800065c0:	0786                	slli	a5,a5,0x1
    800065c2:	97ba                	add	a5,a5,a4
    800065c4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065cc:	6518                	ld	a4,8(a0)
    800065ce:	00275783          	lhu	a5,2(a4)
    800065d2:	2785                	addiw	a5,a5,1
    800065d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065dc:	100017b7          	lui	a5,0x10001
    800065e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065e4:	00492703          	lw	a4,4(s2)
    800065e8:	4785                	li	a5,1
    800065ea:	02f71163          	bne	a4,a5,8000660c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065ee:	00021997          	auipc	s3,0x21
    800065f2:	b3a98993          	addi	s3,s3,-1222 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800065f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065f8:	85ce                	mv	a1,s3
    800065fa:	854a                	mv	a0,s2
    800065fc:	ffffc097          	auipc	ra,0xffffc
    80006600:	c86080e7          	jalr	-890(ra) # 80002282 <sleep>
  while(b->disk == 1) {
    80006604:	00492783          	lw	a5,4(s2)
    80006608:	fe9788e3          	beq	a5,s1,800065f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000660c:	f9042903          	lw	s2,-112(s0)
    80006610:	20090793          	addi	a5,s2,512
    80006614:	00479713          	slli	a4,a5,0x4
    80006618:	0001f797          	auipc	a5,0x1f
    8000661c:	9e878793          	addi	a5,a5,-1560 # 80025000 <disk>
    80006620:	97ba                	add	a5,a5,a4
    80006622:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006626:	00021997          	auipc	s3,0x21
    8000662a:	9da98993          	addi	s3,s3,-1574 # 80027000 <disk+0x2000>
    8000662e:	00491713          	slli	a4,s2,0x4
    80006632:	0009b783          	ld	a5,0(s3)
    80006636:	97ba                	add	a5,a5,a4
    80006638:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000663c:	854a                	mv	a0,s2
    8000663e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006642:	00000097          	auipc	ra,0x0
    80006646:	bc4080e7          	jalr	-1084(ra) # 80006206 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000664a:	8885                	andi	s1,s1,1
    8000664c:	f0ed                	bnez	s1,8000662e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000664e:	00021517          	auipc	a0,0x21
    80006652:	ada50513          	addi	a0,a0,-1318 # 80027128 <disk+0x2128>
    80006656:	ffffa097          	auipc	ra,0xffffa
    8000665a:	642080e7          	jalr	1602(ra) # 80000c98 <release>
}
    8000665e:	70a6                	ld	ra,104(sp)
    80006660:	7406                	ld	s0,96(sp)
    80006662:	64e6                	ld	s1,88(sp)
    80006664:	6946                	ld	s2,80(sp)
    80006666:	69a6                	ld	s3,72(sp)
    80006668:	6a06                	ld	s4,64(sp)
    8000666a:	7ae2                	ld	s5,56(sp)
    8000666c:	7b42                	ld	s6,48(sp)
    8000666e:	7ba2                	ld	s7,40(sp)
    80006670:	7c02                	ld	s8,32(sp)
    80006672:	6ce2                	ld	s9,24(sp)
    80006674:	6d42                	ld	s10,16(sp)
    80006676:	6165                	addi	sp,sp,112
    80006678:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000667a:	00021697          	auipc	a3,0x21
    8000667e:	9866b683          	ld	a3,-1658(a3) # 80027000 <disk+0x2000>
    80006682:	96ba                	add	a3,a3,a4
    80006684:	4609                	li	a2,2
    80006686:	00c69623          	sh	a2,12(a3)
    8000668a:	b5c9                	j	8000654c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000668c:	f9042583          	lw	a1,-112(s0)
    80006690:	20058793          	addi	a5,a1,512
    80006694:	0792                	slli	a5,a5,0x4
    80006696:	0001f517          	auipc	a0,0x1f
    8000669a:	a1250513          	addi	a0,a0,-1518 # 800250a8 <disk+0xa8>
    8000669e:	953e                	add	a0,a0,a5
  if(write)
    800066a0:	e20d11e3          	bnez	s10,800064c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066a4:	20058713          	addi	a4,a1,512
    800066a8:	00471693          	slli	a3,a4,0x4
    800066ac:	0001f717          	auipc	a4,0x1f
    800066b0:	95470713          	addi	a4,a4,-1708 # 80025000 <disk>
    800066b4:	9736                	add	a4,a4,a3
    800066b6:	0a072423          	sw	zero,168(a4)
    800066ba:	b505                	j	800064da <virtio_disk_rw+0xf4>

00000000800066bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066bc:	1101                	addi	sp,sp,-32
    800066be:	ec06                	sd	ra,24(sp)
    800066c0:	e822                	sd	s0,16(sp)
    800066c2:	e426                	sd	s1,8(sp)
    800066c4:	e04a                	sd	s2,0(sp)
    800066c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066c8:	00021517          	auipc	a0,0x21
    800066cc:	a6050513          	addi	a0,a0,-1440 # 80027128 <disk+0x2128>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	514080e7          	jalr	1300(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066d8:	10001737          	lui	a4,0x10001
    800066dc:	533c                	lw	a5,96(a4)
    800066de:	8b8d                	andi	a5,a5,3
    800066e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066e6:	00021797          	auipc	a5,0x21
    800066ea:	91a78793          	addi	a5,a5,-1766 # 80027000 <disk+0x2000>
    800066ee:	6b94                	ld	a3,16(a5)
    800066f0:	0207d703          	lhu	a4,32(a5)
    800066f4:	0026d783          	lhu	a5,2(a3)
    800066f8:	06f70163          	beq	a4,a5,8000675a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066fc:	0001f917          	auipc	s2,0x1f
    80006700:	90490913          	addi	s2,s2,-1788 # 80025000 <disk>
    80006704:	00021497          	auipc	s1,0x21
    80006708:	8fc48493          	addi	s1,s1,-1796 # 80027000 <disk+0x2000>
    __sync_synchronize();
    8000670c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006710:	6898                	ld	a4,16(s1)
    80006712:	0204d783          	lhu	a5,32(s1)
    80006716:	8b9d                	andi	a5,a5,7
    80006718:	078e                	slli	a5,a5,0x3
    8000671a:	97ba                	add	a5,a5,a4
    8000671c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000671e:	20078713          	addi	a4,a5,512
    80006722:	0712                	slli	a4,a4,0x4
    80006724:	974a                	add	a4,a4,s2
    80006726:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000672a:	e731                	bnez	a4,80006776 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000672c:	20078793          	addi	a5,a5,512
    80006730:	0792                	slli	a5,a5,0x4
    80006732:	97ca                	add	a5,a5,s2
    80006734:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006736:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000673a:	ffffc097          	auipc	ra,0xffffc
    8000673e:	e20080e7          	jalr	-480(ra) # 8000255a <wakeup>

    disk.used_idx += 1;
    80006742:	0204d783          	lhu	a5,32(s1)
    80006746:	2785                	addiw	a5,a5,1
    80006748:	17c2                	slli	a5,a5,0x30
    8000674a:	93c1                	srli	a5,a5,0x30
    8000674c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006750:	6898                	ld	a4,16(s1)
    80006752:	00275703          	lhu	a4,2(a4)
    80006756:	faf71be3          	bne	a4,a5,8000670c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000675a:	00021517          	auipc	a0,0x21
    8000675e:	9ce50513          	addi	a0,a0,-1586 # 80027128 <disk+0x2128>
    80006762:	ffffa097          	auipc	ra,0xffffa
    80006766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
}
    8000676a:	60e2                	ld	ra,24(sp)
    8000676c:	6442                	ld	s0,16(sp)
    8000676e:	64a2                	ld	s1,8(sp)
    80006770:	6902                	ld	s2,0(sp)
    80006772:	6105                	addi	sp,sp,32
    80006774:	8082                	ret
      panic("virtio_disk_intr status");
    80006776:	00002517          	auipc	a0,0x2
    8000677a:	18250513          	addi	a0,a0,386 # 800088f8 <syscalls+0x3c0>
    8000677e:	ffffa097          	auipc	ra,0xffffa
    80006782:	dc0080e7          	jalr	-576(ra) # 8000053e <panic>
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
