
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
    80000068:	09c78793          	addi	a5,a5,156 # 80006100 <timervec>
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
    80000130:	672080e7          	jalr	1650(ra) # 8000279e <either_copyin>
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
    800001d8:	058080e7          	jalr	88(ra) # 8000222c <sleep>
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
    80000214:	538080e7          	jalr	1336(ra) # 80002748 <either_copyout>
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
    800002f6:	502080e7          	jalr	1282(ra) # 800027f4 <procdump>
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
    8000044a:	0be080e7          	jalr	190(ra) # 80002504 <wakeup>
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
    80000570:	eb450513          	addi	a0,a0,-332 # 80008420 <states.1756+0x160>
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
    800008a4:	c64080e7          	jalr	-924(ra) # 80002504 <wakeup>
    
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
    80000930:	900080e7          	jalr	-1792(ra) # 8000222c <sleep>
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
    80000ed8:	b06080e7          	jalr	-1274(ra) # 800029da <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	264080e7          	jalr	612(ra) # 80006140 <plicinithart>
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
    80000f00:	52450513          	addi	a0,a0,1316 # 80008420 <states.1756+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	50450513          	addi	a0,a0,1284 # 80008420 <states.1756+0x160>
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
    80000f50:	a66080e7          	jalr	-1434(ra) # 800029b2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a86080e7          	jalr	-1402(ra) # 800029da <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	1ce080e7          	jalr	462(ra) # 8000612a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	1dc080e7          	jalr	476(ra) # 80006140 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	3c0080e7          	jalr	960(ra) # 8000332c <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a50080e7          	jalr	-1456(ra) # 800039c4 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9fa080e7          	jalr	-1542(ra) # 80004976 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	2de080e7          	jalr	734(ra) # 80006262 <virtio_disk_init>
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
    80001a04:	f107a783          	lw	a5,-240(a5) # 80008910 <first.1719>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	fe8080e7          	jalr	-24(ra) # 800029f2 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ee07ab23          	sw	zero,-266(a5) # 80008910 <first.1719>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	f20080e7          	jalr	-224(ra) # 80003944 <fsinit>
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
    80001a50:	ec878793          	addi	a5,a5,-312 # 80008914 <nextpid>
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
    80001cd6:	c4e58593          	addi	a1,a1,-946 # 80008920 <initcode>
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
    80001d14:	662080e7          	jalr	1634(ra) # 80004372 <namei>
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
    80001e52:	bba080e7          	jalr	-1094(ra) # 80004a08 <filedup>
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
    80001e74:	d0e080e7          	jalr	-754(ra) # 80003b7e <idup>
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
    80001f54:	7119                	addi	sp,sp,-128
    80001f56:	fc86                	sd	ra,120(sp)
    80001f58:	f8a2                	sd	s0,112(sp)
    80001f5a:	f4a6                	sd	s1,104(sp)
    80001f5c:	f0ca                	sd	s2,96(sp)
    80001f5e:	ecce                	sd	s3,88(sp)
    80001f60:	e8d2                	sd	s4,80(sp)
    80001f62:	e4d6                	sd	s5,72(sp)
    80001f64:	e0da                	sd	s6,64(sp)
    80001f66:	fc5e                	sd	s7,56(sp)
    80001f68:	f862                	sd	s8,48(sp)
    80001f6a:	f466                	sd	s9,40(sp)
    80001f6c:	f06a                	sd	s10,32(sp)
    80001f6e:	ec6e                	sd	s11,24(sp)
    80001f70:	0100                	addi	s0,sp,128
    80001f72:	4a81                	li	s5,0
    80001f74:	8792                	mv	a5,tp
  int id = r_tp();
    80001f76:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f78:	00779693          	slli	a3,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	32470713          	addi	a4,a4,804 # 800112a0 <pid_lock>
    80001f84:	9736                	add	a4,a4,a3
    80001f86:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &minimum->context);
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	34e70713          	addi	a4,a4,846 # 800112d8 <cpus+0x8>
    80001f92:	9736                	add	a4,a4,a3
    80001f94:	f8e43423          	sd	a4,-120(s0)
    int chosenFlag = 0;
    80001f98:	4d01                	li	s10,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9a:	00016997          	auipc	s3,0x16
    80001f9e:	b3698993          	addi	s3,s3,-1226 # 80017ad0 <tickslock>
        chosenFlag = 1;
    80001fa2:	4b85                	li	s7,1
      minimum->sched_begin = ticks;
    80001fa4:	00007d97          	auipc	s11,0x7
    80001fa8:	08cd8d93          	addi	s11,s11,140 # 80009030 <ticks>
      c->proc = minimum;
    80001fac:	0000f717          	auipc	a4,0xf
    80001fb0:	2f470713          	addi	a4,a4,756 # 800112a0 <pid_lock>
    80001fb4:	00d707b3          	add	a5,a4,a3
    80001fb8:	f8f43023          	sd	a5,-128(s0)
    80001fbc:	a8c9                	j	8000208e <scheduler+0x13a>
          sleeptime = p->sched_end - p->sched_begin + p->run_last;
    80001fbe:	1884a703          	lw	a4,392(s1)
    80001fc2:	1844a783          	lw	a5,388(s1)
    80001fc6:	1804a683          	lw	a3,384(s1)
    80001fca:	9f95                	subw	a5,a5,a3
    80001fcc:	9fb9                	addw	a5,a5,a4
          niceness = (sleeptime/(p->run_last + sleeptime))*10;
    80001fce:	9f3d                	addw	a4,a4,a5
    80001fd0:	02e7c7bb          	divw	a5,a5,a4
    80001fd4:	0027971b          	slliw	a4,a5,0x2
    80001fd8:	9fb9                	addw	a5,a5,a4
    80001fda:	0017971b          	slliw	a4,a5,0x1
          dp = p->static_priority - niceness + 5;
    80001fde:	1784a783          	lw	a5,376(s1)
    80001fe2:	9f99                	subw	a5,a5,a4
    80001fe4:	2795                	addiw	a5,a5,5
    80001fe6:	0007871b          	sext.w	a4,a5
    80001fea:	fff74713          	not	a4,a4
    80001fee:	977d                	srai	a4,a4,0x3f
    80001ff0:	8ff9                	and	a5,a5,a4
    80001ff2:	0007871b          	sext.w	a4,a5
    80001ff6:	00ec5363          	bge	s8,a4,80001ffc <scheduler+0xa8>
    80001ffa:	87e6                	mv	a5,s9
    80001ffc:	2781                	sext.w	a5,a5
    80001ffe:	a881                	j	8000204e <scheduler+0xfa>
          min_dp = dp;
    80002000:	8abe                	mv	s5,a5
    80002002:	8a26                	mv	s4,s1
        chosenFlag = 1;
    80002004:	8b5e                	mv	s6,s7
      release(&p->lock);
    80002006:	8526                	mv	a0,s1
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	c90080e7          	jalr	-880(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002010:	19048493          	addi	s1,s1,400
    80002014:	07348b63          	beq	s1,s3,8000208a <scheduler+0x136>
      acquire(&p->lock);
    80002018:	8526                	mv	a0,s1
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	bca080e7          	jalr	-1078(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE)
    80002022:	4c9c                	lw	a5,24(s1)
    80002024:	ff2791e3          	bne	a5,s2,80002006 <scheduler+0xb2>
        if(p->new_proc)
    80002028:	18c4a783          	lw	a5,396(s1)
    8000202c:	dbc9                	beqz	a5,80001fbe <scheduler+0x6a>
          p->new_proc = 0;
    8000202e:	1804a623          	sw	zero,396(s1)
          if(dp > 100)
    80002032:	1784a783          	lw	a5,376(s1)
    80002036:	0007871b          	sext.w	a4,a5
    8000203a:	fff74713          	not	a4,a4
    8000203e:	977d                	srai	a4,a4,0x3f
    80002040:	8ff9                	and	a5,a5,a4
    80002042:	0007871b          	sext.w	a4,a5
    80002046:	00ec5363          	bge	s8,a4,8000204c <scheduler+0xf8>
    8000204a:	87e6                	mv	a5,s9
    8000204c:	2781                	sext.w	a5,a5
        if(minimum == 0)
    8000204e:	fa0a09e3          	beqz	s4,80002000 <scheduler+0xac>
        chosenFlag = 1;
    80002052:	8b5e                	mv	s6,s7
        else if(dp <= min_dp)
    80002054:	fafac9e3          	blt	s5,a5,80002006 <scheduler+0xb2>
          if(dp < min_dp)
    80002058:	0357c363          	blt	a5,s5,8000207e <scheduler+0x12a>
            if(p->num_run <= minimum->num_run)
    8000205c:	17c4a683          	lw	a3,380(s1)
    80002060:	17ca2703          	lw	a4,380(s4)
    80002064:	fad741e3          	blt	a4,a3,80002006 <scheduler+0xb2>
              if(p->num_run < minimum->num_run)
    80002068:	00e6ce63          	blt	a3,a4,80002084 <scheduler+0x130>
                if(p->ctime < minimum->ctime)
    8000206c:	1704a683          	lw	a3,368(s1)
    80002070:	170a2703          	lw	a4,368(s4)
    80002074:	f8e6f9e3          	bgeu	a3,a4,80002006 <scheduler+0xb2>
                  min_dp = dp;
    80002078:	8abe                	mv	s5,a5
                if(p->ctime < minimum->ctime)
    8000207a:	8a26                	mv	s4,s1
    8000207c:	b769                	j	80002006 <scheduler+0xb2>
            min_dp = dp;
    8000207e:	8abe                	mv	s5,a5
    80002080:	8a26                	mv	s4,s1
    80002082:	b751                	j	80002006 <scheduler+0xb2>
                min_dp = dp;
    80002084:	8abe                	mv	s5,a5
    80002086:	8a26                	mv	s4,s1
    80002088:	bfbd                	j	80002006 <scheduler+0xb2>
    if(chosenFlag == 0)
    8000208a:	020b1463          	bnez	s6,800020b2 <scheduler+0x15e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000208e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002092:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002096:	10079073          	csrw	sstatus,a5
    int chosenFlag = 0;
    8000209a:	8b6a                	mv	s6,s10
    struct proc *minimum = 0;
    8000209c:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++) {
    8000209e:	0000f497          	auipc	s1,0xf
    800020a2:	63248493          	addi	s1,s1,1586 # 800116d0 <proc>
      if(p->state == RUNNABLE)
    800020a6:	490d                	li	s2,3
    800020a8:	06400c13          	li	s8,100
    800020ac:	06400c93          	li	s9,100
    800020b0:	b7a5                	j	80002018 <scheduler+0xc4>
    acquire(&minimum->lock);
    800020b2:	84d2                	mv	s1,s4
    800020b4:	8552                	mv	a0,s4
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b2e080e7          	jalr	-1234(ra) # 80000be4 <acquire>
    if(minimum->state == RUNNABLE)
    800020be:	018a2703          	lw	a4,24(s4)
    800020c2:	478d                	li	a5,3
    800020c4:	00f70863          	beq	a4,a5,800020d4 <scheduler+0x180>
    release(&minimum->lock);
    800020c8:	8526                	mv	a0,s1
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	bce080e7          	jalr	-1074(ra) # 80000c98 <release>
    800020d2:	bf75                	j	8000208e <scheduler+0x13a>
      minimum->sched_begin = ticks;
    800020d4:	000da783          	lw	a5,0(s11)
    800020d8:	18fa2023          	sw	a5,384(s4)
      minimum->num_run++;
    800020dc:	17ca2783          	lw	a5,380(s4)
    800020e0:	2785                	addiw	a5,a5,1
    800020e2:	16fa2e23          	sw	a5,380(s4)
      minimum->run_last = 0;
    800020e6:	180a2423          	sw	zero,392(s4)
      minimum->state = RUNNING;
    800020ea:	4791                	li	a5,4
    800020ec:	00fa2c23          	sw	a5,24(s4)
      c->proc = minimum;
    800020f0:	f8043903          	ld	s2,-128(s0)
    800020f4:	03493823          	sd	s4,48(s2)
      swtch(&c->context, &minimum->context);
    800020f8:	060a0593          	addi	a1,s4,96
    800020fc:	f8843503          	ld	a0,-120(s0)
    80002100:	00001097          	auipc	ra,0x1
    80002104:	848080e7          	jalr	-1976(ra) # 80002948 <swtch>
      c->proc = 0;
    80002108:	02093823          	sd	zero,48(s2)
    8000210c:	bf75                	j	800020c8 <scheduler+0x174>

000000008000210e <sched>:
{
    8000210e:	7179                	addi	sp,sp,-48
    80002110:	f406                	sd	ra,40(sp)
    80002112:	f022                	sd	s0,32(sp)
    80002114:	ec26                	sd	s1,24(sp)
    80002116:	e84a                	sd	s2,16(sp)
    80002118:	e44e                	sd	s3,8(sp)
    8000211a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	894080e7          	jalr	-1900(ra) # 800019b0 <myproc>
    80002124:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	a44080e7          	jalr	-1468(ra) # 80000b6a <holding>
    8000212e:	c93d                	beqz	a0,800021a4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002130:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002132:	2781                	sext.w	a5,a5
    80002134:	079e                	slli	a5,a5,0x7
    80002136:	0000f717          	auipc	a4,0xf
    8000213a:	16a70713          	addi	a4,a4,362 # 800112a0 <pid_lock>
    8000213e:	97ba                	add	a5,a5,a4
    80002140:	0a87a703          	lw	a4,168(a5)
    80002144:	4785                	li	a5,1
    80002146:	06f71763          	bne	a4,a5,800021b4 <sched+0xa6>
  if(p->state == RUNNING)
    8000214a:	4c98                	lw	a4,24(s1)
    8000214c:	4791                	li	a5,4
    8000214e:	06f70b63          	beq	a4,a5,800021c4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002152:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002156:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002158:	efb5                	bnez	a5,800021d4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000215a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000215c:	0000f917          	auipc	s2,0xf
    80002160:	14490913          	addi	s2,s2,324 # 800112a0 <pid_lock>
    80002164:	2781                	sext.w	a5,a5
    80002166:	079e                	slli	a5,a5,0x7
    80002168:	97ca                	add	a5,a5,s2
    8000216a:	0ac7a983          	lw	s3,172(a5)
    8000216e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002170:	2781                	sext.w	a5,a5
    80002172:	079e                	slli	a5,a5,0x7
    80002174:	0000f597          	auipc	a1,0xf
    80002178:	16458593          	addi	a1,a1,356 # 800112d8 <cpus+0x8>
    8000217c:	95be                	add	a1,a1,a5
    8000217e:	06048513          	addi	a0,s1,96
    80002182:	00000097          	auipc	ra,0x0
    80002186:	7c6080e7          	jalr	1990(ra) # 80002948 <swtch>
    8000218a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000218c:	2781                	sext.w	a5,a5
    8000218e:	079e                	slli	a5,a5,0x7
    80002190:	97ca                	add	a5,a5,s2
    80002192:	0b37a623          	sw	s3,172(a5)
}
    80002196:	70a2                	ld	ra,40(sp)
    80002198:	7402                	ld	s0,32(sp)
    8000219a:	64e2                	ld	s1,24(sp)
    8000219c:	6942                	ld	s2,16(sp)
    8000219e:	69a2                	ld	s3,8(sp)
    800021a0:	6145                	addi	sp,sp,48
    800021a2:	8082                	ret
    panic("sched p->lock");
    800021a4:	00006517          	auipc	a0,0x6
    800021a8:	07450513          	addi	a0,a0,116 # 80008218 <digits+0x1d8>
    800021ac:	ffffe097          	auipc	ra,0xffffe
    800021b0:	392080e7          	jalr	914(ra) # 8000053e <panic>
    panic("sched locks");
    800021b4:	00006517          	auipc	a0,0x6
    800021b8:	07450513          	addi	a0,a0,116 # 80008228 <digits+0x1e8>
    800021bc:	ffffe097          	auipc	ra,0xffffe
    800021c0:	382080e7          	jalr	898(ra) # 8000053e <panic>
    panic("sched running");
    800021c4:	00006517          	auipc	a0,0x6
    800021c8:	07450513          	addi	a0,a0,116 # 80008238 <digits+0x1f8>
    800021cc:	ffffe097          	auipc	ra,0xffffe
    800021d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021d4:	00006517          	auipc	a0,0x6
    800021d8:	07450513          	addi	a0,a0,116 # 80008248 <digits+0x208>
    800021dc:	ffffe097          	auipc	ra,0xffffe
    800021e0:	362080e7          	jalr	866(ra) # 8000053e <panic>

00000000800021e4 <yield>:
{
    800021e4:	1101                	addi	sp,sp,-32
    800021e6:	ec06                	sd	ra,24(sp)
    800021e8:	e822                	sd	s0,16(sp)
    800021ea:	e426                	sd	s1,8(sp)
    800021ec:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	7c2080e7          	jalr	1986(ra) # 800019b0 <myproc>
    800021f6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	9ec080e7          	jalr	-1556(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002200:	478d                	li	a5,3
    80002202:	cc9c                	sw	a5,24(s1)
  p->sched_end = ticks;
    80002204:	00007797          	auipc	a5,0x7
    80002208:	e2c7a783          	lw	a5,-468(a5) # 80009030 <ticks>
    8000220c:	18f4a223          	sw	a5,388(s1)
  sched();
    80002210:	00000097          	auipc	ra,0x0
    80002214:	efe080e7          	jalr	-258(ra) # 8000210e <sched>
  release(&p->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
}
    80002222:	60e2                	ld	ra,24(sp)
    80002224:	6442                	ld	s0,16(sp)
    80002226:	64a2                	ld	s1,8(sp)
    80002228:	6105                	addi	sp,sp,32
    8000222a:	8082                	ret

000000008000222c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000222c:	7179                	addi	sp,sp,-48
    8000222e:	f406                	sd	ra,40(sp)
    80002230:	f022                	sd	s0,32(sp)
    80002232:	ec26                	sd	s1,24(sp)
    80002234:	e84a                	sd	s2,16(sp)
    80002236:	e44e                	sd	s3,8(sp)
    80002238:	1800                	addi	s0,sp,48
    8000223a:	89aa                	mv	s3,a0
    8000223c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	772080e7          	jalr	1906(ra) # 800019b0 <myproc>
    80002246:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	99c080e7          	jalr	-1636(ra) # 80000be4 <acquire>
  release(lk);
    80002250:	854a                	mv	a0,s2
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000225a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000225e:	4789                	li	a5,2
    80002260:	cc9c                	sw	a5,24(s1)

  sched();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	eac080e7          	jalr	-340(ra) # 8000210e <sched>

  // Tidy up.
  p->chan = 0;
    8000226a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
  acquire(lk);
    80002278:	854a                	mv	a0,s2
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	96a080e7          	jalr	-1686(ra) # 80000be4 <acquire>
}
    80002282:	70a2                	ld	ra,40(sp)
    80002284:	7402                	ld	s0,32(sp)
    80002286:	64e2                	ld	s1,24(sp)
    80002288:	6942                	ld	s2,16(sp)
    8000228a:	69a2                	ld	s3,8(sp)
    8000228c:	6145                	addi	sp,sp,48
    8000228e:	8082                	ret

0000000080002290 <wait>:
{
    80002290:	715d                	addi	sp,sp,-80
    80002292:	e486                	sd	ra,72(sp)
    80002294:	e0a2                	sd	s0,64(sp)
    80002296:	fc26                	sd	s1,56(sp)
    80002298:	f84a                	sd	s2,48(sp)
    8000229a:	f44e                	sd	s3,40(sp)
    8000229c:	f052                	sd	s4,32(sp)
    8000229e:	ec56                	sd	s5,24(sp)
    800022a0:	e85a                	sd	s6,16(sp)
    800022a2:	e45e                	sd	s7,8(sp)
    800022a4:	e062                	sd	s8,0(sp)
    800022a6:	0880                	addi	s0,sp,80
    800022a8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	706080e7          	jalr	1798(ra) # 800019b0 <myproc>
    800022b2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022b4:	0000f517          	auipc	a0,0xf
    800022b8:	00450513          	addi	a0,a0,4 # 800112b8 <wait_lock>
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	928080e7          	jalr	-1752(ra) # 80000be4 <acquire>
    havekids = 0;
    800022c4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022c6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022c8:	00016997          	auipc	s3,0x16
    800022cc:	80898993          	addi	s3,s3,-2040 # 80017ad0 <tickslock>
        havekids = 1;
    800022d0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022d2:	0000fc17          	auipc	s8,0xf
    800022d6:	fe6c0c13          	addi	s8,s8,-26 # 800112b8 <wait_lock>
    havekids = 0;
    800022da:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022dc:	0000f497          	auipc	s1,0xf
    800022e0:	3f448493          	addi	s1,s1,1012 # 800116d0 <proc>
    800022e4:	a0bd                	j	80002352 <wait+0xc2>
          pid = np->pid;
    800022e6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ea:	000b0e63          	beqz	s6,80002306 <wait+0x76>
    800022ee:	4691                	li	a3,4
    800022f0:	02c48613          	addi	a2,s1,44
    800022f4:	85da                	mv	a1,s6
    800022f6:	05093503          	ld	a0,80(s2)
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	378080e7          	jalr	888(ra) # 80001672 <copyout>
    80002302:	02054563          	bltz	a0,8000232c <wait+0x9c>
          freeproc(np);
    80002306:	8526                	mv	a0,s1
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	85a080e7          	jalr	-1958(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	986080e7          	jalr	-1658(ra) # 80000c98 <release>
          release(&wait_lock);
    8000231a:	0000f517          	auipc	a0,0xf
    8000231e:	f9e50513          	addi	a0,a0,-98 # 800112b8 <wait_lock>
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	976080e7          	jalr	-1674(ra) # 80000c98 <release>
          return pid;
    8000232a:	a09d                	j	80002390 <wait+0x100>
            release(&np->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	96a080e7          	jalr	-1686(ra) # 80000c98 <release>
            release(&wait_lock);
    80002336:	0000f517          	auipc	a0,0xf
    8000233a:	f8250513          	addi	a0,a0,-126 # 800112b8 <wait_lock>
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	95a080e7          	jalr	-1702(ra) # 80000c98 <release>
            return -1;
    80002346:	59fd                	li	s3,-1
    80002348:	a0a1                	j	80002390 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000234a:	19048493          	addi	s1,s1,400
    8000234e:	03348463          	beq	s1,s3,80002376 <wait+0xe6>
      if(np->parent == p){
    80002352:	7c9c                	ld	a5,56(s1)
    80002354:	ff279be3          	bne	a5,s2,8000234a <wait+0xba>
        acquire(&np->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	88a080e7          	jalr	-1910(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002362:	4c9c                	lw	a5,24(s1)
    80002364:	f94781e3          	beq	a5,s4,800022e6 <wait+0x56>
        release(&np->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	92e080e7          	jalr	-1746(ra) # 80000c98 <release>
        havekids = 1;
    80002372:	8756                	mv	a4,s5
    80002374:	bfd9                	j	8000234a <wait+0xba>
    if(!havekids || p->killed){
    80002376:	c701                	beqz	a4,8000237e <wait+0xee>
    80002378:	02892783          	lw	a5,40(s2)
    8000237c:	c79d                	beqz	a5,800023aa <wait+0x11a>
      release(&wait_lock);
    8000237e:	0000f517          	auipc	a0,0xf
    80002382:	f3a50513          	addi	a0,a0,-198 # 800112b8 <wait_lock>
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
      return -1;
    8000238e:	59fd                	li	s3,-1
}
    80002390:	854e                	mv	a0,s3
    80002392:	60a6                	ld	ra,72(sp)
    80002394:	6406                	ld	s0,64(sp)
    80002396:	74e2                	ld	s1,56(sp)
    80002398:	7942                	ld	s2,48(sp)
    8000239a:	79a2                	ld	s3,40(sp)
    8000239c:	7a02                	ld	s4,32(sp)
    8000239e:	6ae2                	ld	s5,24(sp)
    800023a0:	6b42                	ld	s6,16(sp)
    800023a2:	6ba2                	ld	s7,8(sp)
    800023a4:	6c02                	ld	s8,0(sp)
    800023a6:	6161                	addi	sp,sp,80
    800023a8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023aa:	85e2                	mv	a1,s8
    800023ac:	854a                	mv	a0,s2
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	e7e080e7          	jalr	-386(ra) # 8000222c <sleep>
    havekids = 0;
    800023b6:	b715                	j	800022da <wait+0x4a>

00000000800023b8 <waitx>:
{
    800023b8:	711d                	addi	sp,sp,-96
    800023ba:	ec86                	sd	ra,88(sp)
    800023bc:	e8a2                	sd	s0,80(sp)
    800023be:	e4a6                	sd	s1,72(sp)
    800023c0:	e0ca                	sd	s2,64(sp)
    800023c2:	fc4e                	sd	s3,56(sp)
    800023c4:	f852                	sd	s4,48(sp)
    800023c6:	f456                	sd	s5,40(sp)
    800023c8:	f05a                	sd	s6,32(sp)
    800023ca:	ec5e                	sd	s7,24(sp)
    800023cc:	e862                	sd	s8,16(sp)
    800023ce:	e466                	sd	s9,8(sp)
    800023d0:	e06a                	sd	s10,0(sp)
    800023d2:	1080                	addi	s0,sp,96
    800023d4:	8b2a                	mv	s6,a0
    800023d6:	8c2e                	mv	s8,a1
    800023d8:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	5d6080e7          	jalr	1494(ra) # 800019b0 <myproc>
    800023e2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023e4:	0000f517          	auipc	a0,0xf
    800023e8:	ed450513          	addi	a0,a0,-300 # 800112b8 <wait_lock>
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7f8080e7          	jalr	2040(ra) # 80000be4 <acquire>
    havekids = 0;
    800023f4:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800023f6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023f8:	00015997          	auipc	s3,0x15
    800023fc:	6d898993          	addi	s3,s3,1752 # 80017ad0 <tickslock>
        havekids = 1;
    80002400:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002402:	0000fd17          	auipc	s10,0xf
    80002406:	eb6d0d13          	addi	s10,s10,-330 # 800112b8 <wait_lock>
    havekids = 0;
    8000240a:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    8000240c:	0000f497          	auipc	s1,0xf
    80002410:	2c448493          	addi	s1,s1,708 # 800116d0 <proc>
    80002414:	a059                	j	8000249a <waitx+0xe2>
          pid = np->pid;
    80002416:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000241a:	16c4a703          	lw	a4,364(s1)
    8000241e:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002422:	1704a783          	lw	a5,368(s1)
    80002426:	9f3d                	addw	a4,a4,a5
    80002428:	1744a783          	lw	a5,372(s1)
    8000242c:	9f99                	subw	a5,a5,a4
    8000242e:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002432:	000b0e63          	beqz	s6,8000244e <waitx+0x96>
    80002436:	4691                	li	a3,4
    80002438:	02c48613          	addi	a2,s1,44
    8000243c:	85da                	mv	a1,s6
    8000243e:	05093503          	ld	a0,80(s2)
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	230080e7          	jalr	560(ra) # 80001672 <copyout>
    8000244a:	02054563          	bltz	a0,80002474 <waitx+0xbc>
          freeproc(np);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	712080e7          	jalr	1810(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
          release(&wait_lock);
    80002462:	0000f517          	auipc	a0,0xf
    80002466:	e5650513          	addi	a0,a0,-426 # 800112b8 <wait_lock>
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	82e080e7          	jalr	-2002(ra) # 80000c98 <release>
          return pid;
    80002472:	a09d                	j	800024d8 <waitx+0x120>
            release(&np->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
            release(&wait_lock);
    8000247e:	0000f517          	auipc	a0,0xf
    80002482:	e3a50513          	addi	a0,a0,-454 # 800112b8 <wait_lock>
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
            return -1;
    8000248e:	59fd                	li	s3,-1
    80002490:	a0a1                	j	800024d8 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002492:	19048493          	addi	s1,s1,400
    80002496:	03348463          	beq	s1,s3,800024be <waitx+0x106>
      if(np->parent == p){
    8000249a:	7c9c                	ld	a5,56(s1)
    8000249c:	ff279be3          	bne	a5,s2,80002492 <waitx+0xda>
        acquire(&np->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	742080e7          	jalr	1858(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800024aa:	4c9c                	lw	a5,24(s1)
    800024ac:	f74785e3          	beq	a5,s4,80002416 <waitx+0x5e>
        release(&np->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7e6080e7          	jalr	2022(ra) # 80000c98 <release>
        havekids = 1;
    800024ba:	8756                	mv	a4,s5
    800024bc:	bfd9                	j	80002492 <waitx+0xda>
    if(!havekids || p->killed){
    800024be:	c701                	beqz	a4,800024c6 <waitx+0x10e>
    800024c0:	02892783          	lw	a5,40(s2)
    800024c4:	cb8d                	beqz	a5,800024f6 <waitx+0x13e>
      release(&wait_lock);
    800024c6:	0000f517          	auipc	a0,0xf
    800024ca:	df250513          	addi	a0,a0,-526 # 800112b8 <wait_lock>
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7ca080e7          	jalr	1994(ra) # 80000c98 <release>
      return -1;
    800024d6:	59fd                	li	s3,-1
}
    800024d8:	854e                	mv	a0,s3
    800024da:	60e6                	ld	ra,88(sp)
    800024dc:	6446                	ld	s0,80(sp)
    800024de:	64a6                	ld	s1,72(sp)
    800024e0:	6906                	ld	s2,64(sp)
    800024e2:	79e2                	ld	s3,56(sp)
    800024e4:	7a42                	ld	s4,48(sp)
    800024e6:	7aa2                	ld	s5,40(sp)
    800024e8:	7b02                	ld	s6,32(sp)
    800024ea:	6be2                	ld	s7,24(sp)
    800024ec:	6c42                	ld	s8,16(sp)
    800024ee:	6ca2                	ld	s9,8(sp)
    800024f0:	6d02                	ld	s10,0(sp)
    800024f2:	6125                	addi	sp,sp,96
    800024f4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024f6:	85ea                	mv	a1,s10
    800024f8:	854a                	mv	a0,s2
    800024fa:	00000097          	auipc	ra,0x0
    800024fe:	d32080e7          	jalr	-718(ra) # 8000222c <sleep>
    havekids = 0;
    80002502:	b721                	j	8000240a <waitx+0x52>

0000000080002504 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002504:	7139                	addi	sp,sp,-64
    80002506:	fc06                	sd	ra,56(sp)
    80002508:	f822                	sd	s0,48(sp)
    8000250a:	f426                	sd	s1,40(sp)
    8000250c:	f04a                	sd	s2,32(sp)
    8000250e:	ec4e                	sd	s3,24(sp)
    80002510:	e852                	sd	s4,16(sp)
    80002512:	e456                	sd	s5,8(sp)
    80002514:	e05a                	sd	s6,0(sp)
    80002516:	0080                	addi	s0,sp,64
    80002518:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000251a:	0000f497          	auipc	s1,0xf
    8000251e:	1b648493          	addi	s1,s1,438 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002522:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002524:	4b0d                	li	s6,3
        #ifdef PBS
        p->sched_end = ticks;
    80002526:	00007a97          	auipc	s5,0x7
    8000252a:	b0aa8a93          	addi	s5,s5,-1270 # 80009030 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000252e:	00015917          	auipc	s2,0x15
    80002532:	5a290913          	addi	s2,s2,1442 # 80017ad0 <tickslock>
    80002536:	a005                	j	80002556 <wakeup+0x52>
        p->state = RUNNABLE;
    80002538:	0164ac23          	sw	s6,24(s1)
        p->sched_end = ticks;
    8000253c:	000aa783          	lw	a5,0(s5)
    80002540:	18f4a223          	sw	a5,388(s1)
        #endif
      }
      release(&p->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000254e:	19048493          	addi	s1,s1,400
    80002552:	03248463          	beq	s1,s2,8000257a <wakeup+0x76>
    if(p != myproc()){
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	45a080e7          	jalr	1114(ra) # 800019b0 <myproc>
    8000255e:	fea488e3          	beq	s1,a0,8000254e <wakeup+0x4a>
      acquire(&p->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	680080e7          	jalr	1664(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000256c:	4c9c                	lw	a5,24(s1)
    8000256e:	fd379be3          	bne	a5,s3,80002544 <wakeup+0x40>
    80002572:	709c                	ld	a5,32(s1)
    80002574:	fd4798e3          	bne	a5,s4,80002544 <wakeup+0x40>
    80002578:	b7c1                	j	80002538 <wakeup+0x34>
    }
  }
}
    8000257a:	70e2                	ld	ra,56(sp)
    8000257c:	7442                	ld	s0,48(sp)
    8000257e:	74a2                	ld	s1,40(sp)
    80002580:	7902                	ld	s2,32(sp)
    80002582:	69e2                	ld	s3,24(sp)
    80002584:	6a42                	ld	s4,16(sp)
    80002586:	6aa2                	ld	s5,8(sp)
    80002588:	6b02                	ld	s6,0(sp)
    8000258a:	6121                	addi	sp,sp,64
    8000258c:	8082                	ret

000000008000258e <reparent>:
{
    8000258e:	7179                	addi	sp,sp,-48
    80002590:	f406                	sd	ra,40(sp)
    80002592:	f022                	sd	s0,32(sp)
    80002594:	ec26                	sd	s1,24(sp)
    80002596:	e84a                	sd	s2,16(sp)
    80002598:	e44e                	sd	s3,8(sp)
    8000259a:	e052                	sd	s4,0(sp)
    8000259c:	1800                	addi	s0,sp,48
    8000259e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025a0:	0000f497          	auipc	s1,0xf
    800025a4:	13048493          	addi	s1,s1,304 # 800116d0 <proc>
      pp->parent = initproc;
    800025a8:	00007a17          	auipc	s4,0x7
    800025ac:	a80a0a13          	addi	s4,s4,-1408 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025b0:	00015997          	auipc	s3,0x15
    800025b4:	52098993          	addi	s3,s3,1312 # 80017ad0 <tickslock>
    800025b8:	a029                	j	800025c2 <reparent+0x34>
    800025ba:	19048493          	addi	s1,s1,400
    800025be:	01348d63          	beq	s1,s3,800025d8 <reparent+0x4a>
    if(pp->parent == p){
    800025c2:	7c9c                	ld	a5,56(s1)
    800025c4:	ff279be3          	bne	a5,s2,800025ba <reparent+0x2c>
      pp->parent = initproc;
    800025c8:	000a3503          	ld	a0,0(s4)
    800025cc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	f36080e7          	jalr	-202(ra) # 80002504 <wakeup>
    800025d6:	b7d5                	j	800025ba <reparent+0x2c>
}
    800025d8:	70a2                	ld	ra,40(sp)
    800025da:	7402                	ld	s0,32(sp)
    800025dc:	64e2                	ld	s1,24(sp)
    800025de:	6942                	ld	s2,16(sp)
    800025e0:	69a2                	ld	s3,8(sp)
    800025e2:	6a02                	ld	s4,0(sp)
    800025e4:	6145                	addi	sp,sp,48
    800025e6:	8082                	ret

00000000800025e8 <exit>:
{
    800025e8:	7179                	addi	sp,sp,-48
    800025ea:	f406                	sd	ra,40(sp)
    800025ec:	f022                	sd	s0,32(sp)
    800025ee:	ec26                	sd	s1,24(sp)
    800025f0:	e84a                	sd	s2,16(sp)
    800025f2:	e44e                	sd	s3,8(sp)
    800025f4:	e052                	sd	s4,0(sp)
    800025f6:	1800                	addi	s0,sp,48
    800025f8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025fa:	fffff097          	auipc	ra,0xfffff
    800025fe:	3b6080e7          	jalr	950(ra) # 800019b0 <myproc>
    80002602:	89aa                	mv	s3,a0
  if(p == initproc)
    80002604:	00007797          	auipc	a5,0x7
    80002608:	a247b783          	ld	a5,-1500(a5) # 80009028 <initproc>
    8000260c:	0d050493          	addi	s1,a0,208
    80002610:	15050913          	addi	s2,a0,336
    80002614:	02a79363          	bne	a5,a0,8000263a <exit+0x52>
    panic("init exiting");
    80002618:	00006517          	auipc	a0,0x6
    8000261c:	c4850513          	addi	a0,a0,-952 # 80008260 <digits+0x220>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
      fileclose(f);
    80002628:	00002097          	auipc	ra,0x2
    8000262c:	432080e7          	jalr	1074(ra) # 80004a5a <fileclose>
      p->ofile[fd] = 0;
    80002630:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002634:	04a1                	addi	s1,s1,8
    80002636:	01248563          	beq	s1,s2,80002640 <exit+0x58>
    if(p->ofile[fd]){
    8000263a:	6088                	ld	a0,0(s1)
    8000263c:	f575                	bnez	a0,80002628 <exit+0x40>
    8000263e:	bfdd                	j	80002634 <exit+0x4c>
  begin_op();
    80002640:	00002097          	auipc	ra,0x2
    80002644:	f4e080e7          	jalr	-178(ra) # 8000458e <begin_op>
  iput(p->cwd);
    80002648:	1509b503          	ld	a0,336(s3)
    8000264c:	00001097          	auipc	ra,0x1
    80002650:	72a080e7          	jalr	1834(ra) # 80003d76 <iput>
  end_op();
    80002654:	00002097          	auipc	ra,0x2
    80002658:	fba080e7          	jalr	-70(ra) # 8000460e <end_op>
  p->cwd = 0;
    8000265c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002660:	0000f497          	auipc	s1,0xf
    80002664:	c5848493          	addi	s1,s1,-936 # 800112b8 <wait_lock>
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
  reparent(p);
    80002672:	854e                	mv	a0,s3
    80002674:	00000097          	auipc	ra,0x0
    80002678:	f1a080e7          	jalr	-230(ra) # 8000258e <reparent>
  wakeup(p->parent);
    8000267c:	0389b503          	ld	a0,56(s3)
    80002680:	00000097          	auipc	ra,0x0
    80002684:	e84080e7          	jalr	-380(ra) # 80002504 <wakeup>
  acquire(&p->lock);
    80002688:	854e                	mv	a0,s3
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	55a080e7          	jalr	1370(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002692:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002696:	4795                	li	a5,5
    80002698:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000269c:	00007797          	auipc	a5,0x7
    800026a0:	9947a783          	lw	a5,-1644(a5) # 80009030 <ticks>
    800026a4:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	5ee080e7          	jalr	1518(ra) # 80000c98 <release>
  sched();
    800026b2:	00000097          	auipc	ra,0x0
    800026b6:	a5c080e7          	jalr	-1444(ra) # 8000210e <sched>
  panic("zombie exit");
    800026ba:	00006517          	auipc	a0,0x6
    800026be:	bb650513          	addi	a0,a0,-1098 # 80008270 <digits+0x230>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	e7c080e7          	jalr	-388(ra) # 8000053e <panic>

00000000800026ca <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800026ca:	7179                	addi	sp,sp,-48
    800026cc:	f406                	sd	ra,40(sp)
    800026ce:	f022                	sd	s0,32(sp)
    800026d0:	ec26                	sd	s1,24(sp)
    800026d2:	e84a                	sd	s2,16(sp)
    800026d4:	e44e                	sd	s3,8(sp)
    800026d6:	1800                	addi	s0,sp,48
    800026d8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800026da:	0000f497          	auipc	s1,0xf
    800026de:	ff648493          	addi	s1,s1,-10 # 800116d0 <proc>
    800026e2:	00015997          	auipc	s3,0x15
    800026e6:	3ee98993          	addi	s3,s3,1006 # 80017ad0 <tickslock>
    acquire(&p->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	4f8080e7          	jalr	1272(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800026f4:	589c                	lw	a5,48(s1)
    800026f6:	01278d63          	beq	a5,s2,80002710 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026fa:	8526                	mv	a0,s1
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	59c080e7          	jalr	1436(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002704:	19048493          	addi	s1,s1,400
    80002708:	ff3491e3          	bne	s1,s3,800026ea <kill+0x20>
  }
  return -1;
    8000270c:	557d                	li	a0,-1
    8000270e:	a829                	j	80002728 <kill+0x5e>
      p->killed = 1;
    80002710:	4785                	li	a5,1
    80002712:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002714:	4c98                	lw	a4,24(s1)
    80002716:	4789                	li	a5,2
    80002718:	00f70f63          	beq	a4,a5,80002736 <kill+0x6c>
      release(&p->lock);
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	57a080e7          	jalr	1402(ra) # 80000c98 <release>
      return 0;
    80002726:	4501                	li	a0,0
}
    80002728:	70a2                	ld	ra,40(sp)
    8000272a:	7402                	ld	s0,32(sp)
    8000272c:	64e2                	ld	s1,24(sp)
    8000272e:	6942                	ld	s2,16(sp)
    80002730:	69a2                	ld	s3,8(sp)
    80002732:	6145                	addi	sp,sp,48
    80002734:	8082                	ret
        p->state = RUNNABLE;
    80002736:	478d                	li	a5,3
    80002738:	cc9c                	sw	a5,24(s1)
        p->sched_end = ticks;
    8000273a:	00007797          	auipc	a5,0x7
    8000273e:	8f67a783          	lw	a5,-1802(a5) # 80009030 <ticks>
    80002742:	18f4a223          	sw	a5,388(s1)
    80002746:	bfd9                	j	8000271c <kill+0x52>

0000000080002748 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002748:	7179                	addi	sp,sp,-48
    8000274a:	f406                	sd	ra,40(sp)
    8000274c:	f022                	sd	s0,32(sp)
    8000274e:	ec26                	sd	s1,24(sp)
    80002750:	e84a                	sd	s2,16(sp)
    80002752:	e44e                	sd	s3,8(sp)
    80002754:	e052                	sd	s4,0(sp)
    80002756:	1800                	addi	s0,sp,48
    80002758:	84aa                	mv	s1,a0
    8000275a:	892e                	mv	s2,a1
    8000275c:	89b2                	mv	s3,a2
    8000275e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	250080e7          	jalr	592(ra) # 800019b0 <myproc>
  if(user_dst){
    80002768:	c08d                	beqz	s1,8000278a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000276a:	86d2                	mv	a3,s4
    8000276c:	864e                	mv	a2,s3
    8000276e:	85ca                	mv	a1,s2
    80002770:	6928                	ld	a0,80(a0)
    80002772:	fffff097          	auipc	ra,0xfffff
    80002776:	f00080e7          	jalr	-256(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000277a:	70a2                	ld	ra,40(sp)
    8000277c:	7402                	ld	s0,32(sp)
    8000277e:	64e2                	ld	s1,24(sp)
    80002780:	6942                	ld	s2,16(sp)
    80002782:	69a2                	ld	s3,8(sp)
    80002784:	6a02                	ld	s4,0(sp)
    80002786:	6145                	addi	sp,sp,48
    80002788:	8082                	ret
    memmove((char *)dst, src, len);
    8000278a:	000a061b          	sext.w	a2,s4
    8000278e:	85ce                	mv	a1,s3
    80002790:	854a                	mv	a0,s2
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	5ae080e7          	jalr	1454(ra) # 80000d40 <memmove>
    return 0;
    8000279a:	8526                	mv	a0,s1
    8000279c:	bff9                	j	8000277a <either_copyout+0x32>

000000008000279e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000279e:	7179                	addi	sp,sp,-48
    800027a0:	f406                	sd	ra,40(sp)
    800027a2:	f022                	sd	s0,32(sp)
    800027a4:	ec26                	sd	s1,24(sp)
    800027a6:	e84a                	sd	s2,16(sp)
    800027a8:	e44e                	sd	s3,8(sp)
    800027aa:	e052                	sd	s4,0(sp)
    800027ac:	1800                	addi	s0,sp,48
    800027ae:	892a                	mv	s2,a0
    800027b0:	84ae                	mv	s1,a1
    800027b2:	89b2                	mv	s3,a2
    800027b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	1fa080e7          	jalr	506(ra) # 800019b0 <myproc>
  if(user_src){
    800027be:	c08d                	beqz	s1,800027e0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027c0:	86d2                	mv	a3,s4
    800027c2:	864e                	mv	a2,s3
    800027c4:	85ca                	mv	a1,s2
    800027c6:	6928                	ld	a0,80(a0)
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	f36080e7          	jalr	-202(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6a02                	ld	s4,0(sp)
    800027dc:	6145                	addi	sp,sp,48
    800027de:	8082                	ret
    memmove(dst, (char*)src, len);
    800027e0:	000a061b          	sext.w	a2,s4
    800027e4:	85ce                	mv	a1,s3
    800027e6:	854a                	mv	a0,s2
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	558080e7          	jalr	1368(ra) # 80000d40 <memmove>
    return 0;
    800027f0:	8526                	mv	a0,s1
    800027f2:	bff9                	j	800027d0 <either_copyin+0x32>

00000000800027f4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027f4:	715d                	addi	sp,sp,-80
    800027f6:	e486                	sd	ra,72(sp)
    800027f8:	e0a2                	sd	s0,64(sp)
    800027fa:	fc26                	sd	s1,56(sp)
    800027fc:	f84a                	sd	s2,48(sp)
    800027fe:	f44e                	sd	s3,40(sp)
    80002800:	f052                	sd	s4,32(sp)
    80002802:	ec56                	sd	s5,24(sp)
    80002804:	e85a                	sd	s6,16(sp)
    80002806:	e45e                	sd	s7,8(sp)
    80002808:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000280a:	00006517          	auipc	a0,0x6
    8000280e:	c1650513          	addi	a0,a0,-1002 # 80008420 <states.1756+0x160>
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	d76080e7          	jalr	-650(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000281a:	0000f497          	auipc	s1,0xf
    8000281e:	00e48493          	addi	s1,s1,14 # 80011828 <proc+0x158>
    80002822:	00015917          	auipc	s2,0x15
    80002826:	40690913          	addi	s2,s2,1030 # 80017c28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000282a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000282c:	00006997          	auipc	s3,0x6
    80002830:	a5498993          	addi	s3,s3,-1452 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002834:	00006a97          	auipc	s5,0x6
    80002838:	a54a8a93          	addi	s5,s5,-1452 # 80008288 <digits+0x248>
    printf("\n");
    8000283c:	00006a17          	auipc	s4,0x6
    80002840:	be4a0a13          	addi	s4,s4,-1052 # 80008420 <states.1756+0x160>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002844:	00006b97          	auipc	s7,0x6
    80002848:	a7cb8b93          	addi	s7,s7,-1412 # 800082c0 <states.1756>
    8000284c:	a00d                	j	8000286e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000284e:	ed86a583          	lw	a1,-296(a3)
    80002852:	8556                	mv	a0,s5
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	d34080e7          	jalr	-716(ra) # 80000588 <printf>
    printf("\n");
    8000285c:	8552                	mv	a0,s4
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	d2a080e7          	jalr	-726(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002866:	19048493          	addi	s1,s1,400
    8000286a:	03248163          	beq	s1,s2,8000288c <procdump+0x98>
    if(p->state == UNUSED)
    8000286e:	86a6                	mv	a3,s1
    80002870:	ec04a783          	lw	a5,-320(s1)
    80002874:	dbed                	beqz	a5,80002866 <procdump+0x72>
      state = "???";
    80002876:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002878:	fcfb6be3          	bltu	s6,a5,8000284e <procdump+0x5a>
    8000287c:	1782                	slli	a5,a5,0x20
    8000287e:	9381                	srli	a5,a5,0x20
    80002880:	078e                	slli	a5,a5,0x3
    80002882:	97de                	add	a5,a5,s7
    80002884:	6390                	ld	a2,0(a5)
    80002886:	f661                	bnez	a2,8000284e <procdump+0x5a>
      state = "???";
    80002888:	864e                	mv	a2,s3
    8000288a:	b7d1                	j	8000284e <procdump+0x5a>
  }
}
    8000288c:	60a6                	ld	ra,72(sp)
    8000288e:	6406                	ld	s0,64(sp)
    80002890:	74e2                	ld	s1,56(sp)
    80002892:	7942                	ld	s2,48(sp)
    80002894:	79a2                	ld	s3,40(sp)
    80002896:	7a02                	ld	s4,32(sp)
    80002898:	6ae2                	ld	s5,24(sp)
    8000289a:	6b42                	ld	s6,16(sp)
    8000289c:	6ba2                	ld	s7,8(sp)
    8000289e:	6161                	addi	sp,sp,80
    800028a0:	8082                	ret

00000000800028a2 <trace>:

// enabling tracing for the current process
void
trace(int trace_mask)
{
    800028a2:	1101                	addi	sp,sp,-32
    800028a4:	ec06                	sd	ra,24(sp)
    800028a6:	e822                	sd	s0,16(sp)
    800028a8:	e426                	sd	s1,8(sp)
    800028aa:	1000                	addi	s0,sp,32
    800028ac:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	102080e7          	jalr	258(ra) # 800019b0 <myproc>
  p->trace_mask = trace_mask;
    800028b6:	16952423          	sw	s1,360(a0)
}
    800028ba:	60e2                	ld	ra,24(sp)
    800028bc:	6442                	ld	s0,16(sp)
    800028be:	64a2                	ld	s1,8(sp)
    800028c0:	6105                	addi	sp,sp,32
    800028c2:	8082                	ret

00000000800028c4 <set_priority>:


// Change the priority of the given process with pid to new_priority
int set_priority(int new_priority,int pid)
{
    800028c4:	7179                	addi	sp,sp,-48
    800028c6:	f406                	sd	ra,40(sp)
    800028c8:	f022                	sd	s0,32(sp)
    800028ca:	ec26                	sd	s1,24(sp)
    800028cc:	e84a                	sd	s2,16(sp)
    800028ce:	e44e                	sd	s3,8(sp)
    800028d0:	e052                	sd	s4,0(sp)
    800028d2:	1800                	addi	s0,sp,48
    800028d4:	8a2a                	mv	s4,a0
    800028d6:	892e                	mv	s2,a1
  struct proc *p;
  int old_priority = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    800028d8:	0000f497          	auipc	s1,0xf
    800028dc:	df848493          	addi	s1,s1,-520 # 800116d0 <proc>
    800028e0:	00015997          	auipc	s3,0x15
    800028e4:	1f098993          	addi	s3,s3,496 # 80017ad0 <tickslock>
    acquire(&p->lock);
    800028e8:	8526                	mv	a0,s1
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	2fa080e7          	jalr	762(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028f2:	589c                	lw	a5,48(s1)
    800028f4:	03278163          	beq	a5,s2,80002916 <set_priority+0x52>
      p->new_proc = 1;
      release(&p->lock);
      yield();
      return old_priority;
    }
    release(&p->lock);
    800028f8:	8526                	mv	a0,s1
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	39e080e7          	jalr	926(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002902:	19048493          	addi	s1,s1,400
    80002906:	ff3491e3          	bne	s1,s3,800028e8 <set_priority+0x24>
  }
  yield();
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	8da080e7          	jalr	-1830(ra) # 800021e4 <yield>
  return old_priority;
    80002912:	4901                	li	s2,0
    80002914:	a00d                	j	80002936 <set_priority+0x72>
      old_priority = p->static_priority;
    80002916:	1784a903          	lw	s2,376(s1)
      p->static_priority = new_priority;
    8000291a:	1744ac23          	sw	s4,376(s1)
      p->new_proc = 1;
    8000291e:	4785                	li	a5,1
    80002920:	18f4a623          	sw	a5,396(s1)
      release(&p->lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	372080e7          	jalr	882(ra) # 80000c98 <release>
      yield();
    8000292e:	00000097          	auipc	ra,0x0
    80002932:	8b6080e7          	jalr	-1866(ra) # 800021e4 <yield>
}
    80002936:	854a                	mv	a0,s2
    80002938:	70a2                	ld	ra,40(sp)
    8000293a:	7402                	ld	s0,32(sp)
    8000293c:	64e2                	ld	s1,24(sp)
    8000293e:	6942                	ld	s2,16(sp)
    80002940:	69a2                	ld	s3,8(sp)
    80002942:	6a02                	ld	s4,0(sp)
    80002944:	6145                	addi	sp,sp,48
    80002946:	8082                	ret

0000000080002948 <swtch>:
    80002948:	00153023          	sd	ra,0(a0)
    8000294c:	00253423          	sd	sp,8(a0)
    80002950:	e900                	sd	s0,16(a0)
    80002952:	ed04                	sd	s1,24(a0)
    80002954:	03253023          	sd	s2,32(a0)
    80002958:	03353423          	sd	s3,40(a0)
    8000295c:	03453823          	sd	s4,48(a0)
    80002960:	03553c23          	sd	s5,56(a0)
    80002964:	05653023          	sd	s6,64(a0)
    80002968:	05753423          	sd	s7,72(a0)
    8000296c:	05853823          	sd	s8,80(a0)
    80002970:	05953c23          	sd	s9,88(a0)
    80002974:	07a53023          	sd	s10,96(a0)
    80002978:	07b53423          	sd	s11,104(a0)
    8000297c:	0005b083          	ld	ra,0(a1)
    80002980:	0085b103          	ld	sp,8(a1)
    80002984:	6980                	ld	s0,16(a1)
    80002986:	6d84                	ld	s1,24(a1)
    80002988:	0205b903          	ld	s2,32(a1)
    8000298c:	0285b983          	ld	s3,40(a1)
    80002990:	0305ba03          	ld	s4,48(a1)
    80002994:	0385ba83          	ld	s5,56(a1)
    80002998:	0405bb03          	ld	s6,64(a1)
    8000299c:	0485bb83          	ld	s7,72(a1)
    800029a0:	0505bc03          	ld	s8,80(a1)
    800029a4:	0585bc83          	ld	s9,88(a1)
    800029a8:	0605bd03          	ld	s10,96(a1)
    800029ac:	0685bd83          	ld	s11,104(a1)
    800029b0:	8082                	ret

00000000800029b2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e406                	sd	ra,8(sp)
    800029b6:	e022                	sd	s0,0(sp)
    800029b8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029ba:	00006597          	auipc	a1,0x6
    800029be:	93658593          	addi	a1,a1,-1738 # 800082f0 <states.1756+0x30>
    800029c2:	00015517          	auipc	a0,0x15
    800029c6:	10e50513          	addi	a0,a0,270 # 80017ad0 <tickslock>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	18a080e7          	jalr	394(ra) # 80000b54 <initlock>
}
    800029d2:	60a2                	ld	ra,8(sp)
    800029d4:	6402                	ld	s0,0(sp)
    800029d6:	0141                	addi	sp,sp,16
    800029d8:	8082                	ret

00000000800029da <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029da:	1141                	addi	sp,sp,-16
    800029dc:	e422                	sd	s0,8(sp)
    800029de:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e0:	00003797          	auipc	a5,0x3
    800029e4:	69078793          	addi	a5,a5,1680 # 80006070 <kernelvec>
    800029e8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029ec:	6422                	ld	s0,8(sp)
    800029ee:	0141                	addi	sp,sp,16
    800029f0:	8082                	ret

00000000800029f2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029f2:	1141                	addi	sp,sp,-16
    800029f4:	e406                	sd	ra,8(sp)
    800029f6:	e022                	sd	s0,0(sp)
    800029f8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	fb6080e7          	jalr	-74(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a06:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a08:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a0c:	00004617          	auipc	a2,0x4
    80002a10:	5f460613          	addi	a2,a2,1524 # 80007000 <_trampoline>
    80002a14:	00004697          	auipc	a3,0x4
    80002a18:	5ec68693          	addi	a3,a3,1516 # 80007000 <_trampoline>
    80002a1c:	8e91                	sub	a3,a3,a2
    80002a1e:	040007b7          	lui	a5,0x4000
    80002a22:	17fd                	addi	a5,a5,-1
    80002a24:	07b2                	slli	a5,a5,0xc
    80002a26:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a28:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a2c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a2e:	180026f3          	csrr	a3,satp
    80002a32:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a34:	6d38                	ld	a4,88(a0)
    80002a36:	6134                	ld	a3,64(a0)
    80002a38:	6585                	lui	a1,0x1
    80002a3a:	96ae                	add	a3,a3,a1
    80002a3c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a3e:	6d38                	ld	a4,88(a0)
    80002a40:	00000697          	auipc	a3,0x0
    80002a44:	14668693          	addi	a3,a3,326 # 80002b86 <usertrap>
    80002a48:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a4a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a4c:	8692                	mv	a3,tp
    80002a4e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a50:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a54:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a58:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a5c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a60:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a62:	6f18                	ld	a4,24(a4)
    80002a64:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a68:	692c                	ld	a1,80(a0)
    80002a6a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a6c:	00004717          	auipc	a4,0x4
    80002a70:	62470713          	addi	a4,a4,1572 # 80007090 <userret>
    80002a74:	8f11                	sub	a4,a4,a2
    80002a76:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a78:	577d                	li	a4,-1
    80002a7a:	177e                	slli	a4,a4,0x3f
    80002a7c:	8dd9                	or	a1,a1,a4
    80002a7e:	02000537          	lui	a0,0x2000
    80002a82:	157d                	addi	a0,a0,-1
    80002a84:	0536                	slli	a0,a0,0xd
    80002a86:	9782                	jalr	a5
}
    80002a88:	60a2                	ld	ra,8(sp)
    80002a8a:	6402                	ld	s0,0(sp)
    80002a8c:	0141                	addi	sp,sp,16
    80002a8e:	8082                	ret

0000000080002a90 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a90:	1101                	addi	sp,sp,-32
    80002a92:	ec06                	sd	ra,24(sp)
    80002a94:	e822                	sd	s0,16(sp)
    80002a96:	e426                	sd	s1,8(sp)
    80002a98:	e04a                	sd	s2,0(sp)
    80002a9a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a9c:	00015917          	auipc	s2,0x15
    80002aa0:	03490913          	addi	s2,s2,52 # 80017ad0 <tickslock>
    80002aa4:	854a                	mv	a0,s2
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	13e080e7          	jalr	318(ra) # 80000be4 <acquire>
  ticks++;
    80002aae:	00006497          	auipc	s1,0x6
    80002ab2:	58248493          	addi	s1,s1,1410 # 80009030 <ticks>
    80002ab6:	409c                	lw	a5,0(s1)
    80002ab8:	2785                	addiw	a5,a5,1
    80002aba:	c09c                	sw	a5,0(s1)
  update_time();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	430080e7          	jalr	1072(ra) # 80001eec <update_time>
  wakeup(&ticks);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	a3e080e7          	jalr	-1474(ra) # 80002504 <wakeup>
  release(&tickslock);
    80002ace:	854a                	mv	a0,s2
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	1c8080e7          	jalr	456(ra) # 80000c98 <release>
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6902                	ld	s2,0(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret

0000000080002ae4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aee:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002af2:	00074d63          	bltz	a4,80002b0c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002af6:	57fd                	li	a5,-1
    80002af8:	17fe                	slli	a5,a5,0x3f
    80002afa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002afc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002afe:	06f70363          	beq	a4,a5,80002b64 <devintr+0x80>
  }
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6105                	addi	sp,sp,32
    80002b0a:	8082                	ret
     (scause & 0xff) == 9){
    80002b0c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b10:	46a5                	li	a3,9
    80002b12:	fed792e3          	bne	a5,a3,80002af6 <devintr+0x12>
    int irq = plic_claim();
    80002b16:	00003097          	auipc	ra,0x3
    80002b1a:	662080e7          	jalr	1634(ra) # 80006178 <plic_claim>
    80002b1e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b20:	47a9                	li	a5,10
    80002b22:	02f50763          	beq	a0,a5,80002b50 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b26:	4785                	li	a5,1
    80002b28:	02f50963          	beq	a0,a5,80002b5a <devintr+0x76>
    return 1;
    80002b2c:	4505                	li	a0,1
    } else if(irq){
    80002b2e:	d8f1                	beqz	s1,80002b02 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b30:	85a6                	mv	a1,s1
    80002b32:	00005517          	auipc	a0,0x5
    80002b36:	7c650513          	addi	a0,a0,1990 # 800082f8 <states.1756+0x38>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a4e080e7          	jalr	-1458(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b42:	8526                	mv	a0,s1
    80002b44:	00003097          	auipc	ra,0x3
    80002b48:	658080e7          	jalr	1624(ra) # 8000619c <plic_complete>
    return 1;
    80002b4c:	4505                	li	a0,1
    80002b4e:	bf55                	j	80002b02 <devintr+0x1e>
      uartintr();
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	e58080e7          	jalr	-424(ra) # 800009a8 <uartintr>
    80002b58:	b7ed                	j	80002b42 <devintr+0x5e>
      virtio_disk_intr();
    80002b5a:	00004097          	auipc	ra,0x4
    80002b5e:	b22080e7          	jalr	-1246(ra) # 8000667c <virtio_disk_intr>
    80002b62:	b7c5                	j	80002b42 <devintr+0x5e>
    if(cpuid() == 0){
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	e20080e7          	jalr	-480(ra) # 80001984 <cpuid>
    80002b6c:	c901                	beqz	a0,80002b7c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b6e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b72:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b74:	14479073          	csrw	sip,a5
    return 2;
    80002b78:	4509                	li	a0,2
    80002b7a:	b761                	j	80002b02 <devintr+0x1e>
      clockintr();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	f14080e7          	jalr	-236(ra) # 80002a90 <clockintr>
    80002b84:	b7ed                	j	80002b6e <devintr+0x8a>

0000000080002b86 <usertrap>:
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b90:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b94:	1007f793          	andi	a5,a5,256
    80002b98:	e3a5                	bnez	a5,80002bf8 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b9a:	00003797          	auipc	a5,0x3
    80002b9e:	4d678793          	addi	a5,a5,1238 # 80006070 <kernelvec>
    80002ba2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	e0a080e7          	jalr	-502(ra) # 800019b0 <myproc>
    80002bae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bb0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb2:	14102773          	csrr	a4,sepc
    80002bb6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bbc:	47a1                	li	a5,8
    80002bbe:	04f71b63          	bne	a4,a5,80002c14 <usertrap+0x8e>
    if(p->killed)
    80002bc2:	551c                	lw	a5,40(a0)
    80002bc4:	e3b1                	bnez	a5,80002c08 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002bc6:	6cb8                	ld	a4,88(s1)
    80002bc8:	6f1c                	ld	a5,24(a4)
    80002bca:	0791                	addi	a5,a5,4
    80002bcc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bd2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
    syscall();
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	29a080e7          	jalr	666(ra) # 80002e74 <syscall>
  if(p->killed)
    80002be2:	549c                	lw	a5,40(s1)
    80002be4:	e7b5                	bnez	a5,80002c50 <usertrap+0xca>
  usertrapret();
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	e0c080e7          	jalr	-500(ra) # 800029f2 <usertrapret>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret
    panic("usertrap: not from user mode");
    80002bf8:	00005517          	auipc	a0,0x5
    80002bfc:	72050513          	addi	a0,a0,1824 # 80008318 <states.1756+0x58>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	93e080e7          	jalr	-1730(ra) # 8000053e <panic>
      exit(-1);
    80002c08:	557d                	li	a0,-1
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	9de080e7          	jalr	-1570(ra) # 800025e8 <exit>
    80002c12:	bf55                	j	80002bc6 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	ed0080e7          	jalr	-304(ra) # 80002ae4 <devintr>
    80002c1c:	f179                	bnez	a0,80002be2 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c22:	5890                	lw	a2,48(s1)
    80002c24:	00005517          	auipc	a0,0x5
    80002c28:	71450513          	addi	a0,a0,1812 # 80008338 <states.1756+0x78>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	95c080e7          	jalr	-1700(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c38:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c3c:	00005517          	auipc	a0,0x5
    80002c40:	72c50513          	addi	a0,a0,1836 # 80008368 <states.1756+0xa8>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	944080e7          	jalr	-1724(ra) # 80000588 <printf>
    p->killed = 1;
    80002c4c:	4785                	li	a5,1
    80002c4e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c50:	557d                	li	a0,-1
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	996080e7          	jalr	-1642(ra) # 800025e8 <exit>
    80002c5a:	b771                	j	80002be6 <usertrap+0x60>

0000000080002c5c <kerneltrap>:
{
    80002c5c:	7179                	addi	sp,sp,-48
    80002c5e:	f406                	sd	ra,40(sp)
    80002c60:	f022                	sd	s0,32(sp)
    80002c62:	ec26                	sd	s1,24(sp)
    80002c64:	e84a                	sd	s2,16(sp)
    80002c66:	e44e                	sd	s3,8(sp)
    80002c68:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c72:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c76:	1004f793          	andi	a5,s1,256
    80002c7a:	c78d                	beqz	a5,80002ca4 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c80:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c82:	eb8d                	bnez	a5,80002cb4 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	e60080e7          	jalr	-416(ra) # 80002ae4 <devintr>
    80002c8c:	cd05                	beqz	a0,80002cc4 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c8e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c92:	10049073          	csrw	sstatus,s1
}
    80002c96:	70a2                	ld	ra,40(sp)
    80002c98:	7402                	ld	s0,32(sp)
    80002c9a:	64e2                	ld	s1,24(sp)
    80002c9c:	6942                	ld	s2,16(sp)
    80002c9e:	69a2                	ld	s3,8(sp)
    80002ca0:	6145                	addi	sp,sp,48
    80002ca2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	6e450513          	addi	a0,a0,1764 # 80008388 <states.1756+0xc8>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	892080e7          	jalr	-1902(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	6fc50513          	addi	a0,a0,1788 # 800083b0 <states.1756+0xf0>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002cc4:	85ce                	mv	a1,s3
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	70a50513          	addi	a0,a0,1802 # 800083d0 <states.1756+0x110>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8ba080e7          	jalr	-1862(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cda:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	70250513          	addi	a0,a0,1794 # 800083e0 <states.1756+0x120>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	8a2080e7          	jalr	-1886(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	70a50513          	addi	a0,a0,1802 # 800083f8 <states.1756+0x138>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>

0000000080002cfe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	e426                	sd	s1,8(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	ca6080e7          	jalr	-858(ra) # 800019b0 <myproc>
  switch (n) {
    80002d12:	4795                	li	a5,5
    80002d14:	0497e163          	bltu	a5,s1,80002d56 <argraw+0x58>
    80002d18:	048a                	slli	s1,s1,0x2
    80002d1a:	00006717          	auipc	a4,0x6
    80002d1e:	80670713          	addi	a4,a4,-2042 # 80008520 <states.1756+0x260>
    80002d22:	94ba                	add	s1,s1,a4
    80002d24:	409c                	lw	a5,0(s1)
    80002d26:	97ba                	add	a5,a5,a4
    80002d28:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d2a:	6d3c                	ld	a5,88(a0)
    80002d2c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d2e:	60e2                	ld	ra,24(sp)
    80002d30:	6442                	ld	s0,16(sp)
    80002d32:	64a2                	ld	s1,8(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret
    return p->trapframe->a1;
    80002d38:	6d3c                	ld	a5,88(a0)
    80002d3a:	7fa8                	ld	a0,120(a5)
    80002d3c:	bfcd                	j	80002d2e <argraw+0x30>
    return p->trapframe->a2;
    80002d3e:	6d3c                	ld	a5,88(a0)
    80002d40:	63c8                	ld	a0,128(a5)
    80002d42:	b7f5                	j	80002d2e <argraw+0x30>
    return p->trapframe->a3;
    80002d44:	6d3c                	ld	a5,88(a0)
    80002d46:	67c8                	ld	a0,136(a5)
    80002d48:	b7dd                	j	80002d2e <argraw+0x30>
    return p->trapframe->a4;
    80002d4a:	6d3c                	ld	a5,88(a0)
    80002d4c:	6bc8                	ld	a0,144(a5)
    80002d4e:	b7c5                	j	80002d2e <argraw+0x30>
    return p->trapframe->a5;
    80002d50:	6d3c                	ld	a5,88(a0)
    80002d52:	6fc8                	ld	a0,152(a5)
    80002d54:	bfe9                	j	80002d2e <argraw+0x30>
  panic("argraw");
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	6b250513          	addi	a0,a0,1714 # 80008408 <states.1756+0x148>
    80002d5e:	ffffd097          	auipc	ra,0xffffd
    80002d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>

0000000080002d66 <fetchaddr>:
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	e04a                	sd	s2,0(sp)
    80002d70:	1000                	addi	s0,sp,32
    80002d72:	84aa                	mv	s1,a0
    80002d74:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c3a080e7          	jalr	-966(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d7e:	653c                	ld	a5,72(a0)
    80002d80:	02f4f863          	bgeu	s1,a5,80002db0 <fetchaddr+0x4a>
    80002d84:	00848713          	addi	a4,s1,8
    80002d88:	02e7e663          	bltu	a5,a4,80002db4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d8c:	46a1                	li	a3,8
    80002d8e:	8626                	mv	a2,s1
    80002d90:	85ca                	mv	a1,s2
    80002d92:	6928                	ld	a0,80(a0)
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	96a080e7          	jalr	-1686(ra) # 800016fe <copyin>
    80002d9c:	00a03533          	snez	a0,a0
    80002da0:	40a00533          	neg	a0,a0
}
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	64a2                	ld	s1,8(sp)
    80002daa:	6902                	ld	s2,0(sp)
    80002dac:	6105                	addi	sp,sp,32
    80002dae:	8082                	ret
    return -1;
    80002db0:	557d                	li	a0,-1
    80002db2:	bfcd                	j	80002da4 <fetchaddr+0x3e>
    80002db4:	557d                	li	a0,-1
    80002db6:	b7fd                	j	80002da4 <fetchaddr+0x3e>

0000000080002db8 <fetchstr>:
{
    80002db8:	7179                	addi	sp,sp,-48
    80002dba:	f406                	sd	ra,40(sp)
    80002dbc:	f022                	sd	s0,32(sp)
    80002dbe:	ec26                	sd	s1,24(sp)
    80002dc0:	e84a                	sd	s2,16(sp)
    80002dc2:	e44e                	sd	s3,8(sp)
    80002dc4:	1800                	addi	s0,sp,48
    80002dc6:	892a                	mv	s2,a0
    80002dc8:	84ae                	mv	s1,a1
    80002dca:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	be4080e7          	jalr	-1052(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dd4:	86ce                	mv	a3,s3
    80002dd6:	864a                	mv	a2,s2
    80002dd8:	85a6                	mv	a1,s1
    80002dda:	6928                	ld	a0,80(a0)
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	9ae080e7          	jalr	-1618(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002de4:	00054763          	bltz	a0,80002df2 <fetchstr+0x3a>
  return strlen(buf);
    80002de8:	8526                	mv	a0,s1
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	07a080e7          	jalr	122(ra) # 80000e64 <strlen>
}
    80002df2:	70a2                	ld	ra,40(sp)
    80002df4:	7402                	ld	s0,32(sp)
    80002df6:	64e2                	ld	s1,24(sp)
    80002df8:	6942                	ld	s2,16(sp)
    80002dfa:	69a2                	ld	s3,8(sp)
    80002dfc:	6145                	addi	sp,sp,48
    80002dfe:	8082                	ret

0000000080002e00 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	e426                	sd	s1,8(sp)
    80002e08:	1000                	addi	s0,sp,32
    80002e0a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	ef2080e7          	jalr	-270(ra) # 80002cfe <argraw>
    80002e14:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e16:	4501                	li	a0,0
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	64a2                	ld	s1,8(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	e426                	sd	s1,8(sp)
    80002e2a:	1000                	addi	s0,sp,32
    80002e2c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	ed0080e7          	jalr	-304(ra) # 80002cfe <argraw>
    80002e36:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e38:	4501                	li	a0,0
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret

0000000080002e44 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	e426                	sd	s1,8(sp)
    80002e4c:	e04a                	sd	s2,0(sp)
    80002e4e:	1000                	addi	s0,sp,32
    80002e50:	84ae                	mv	s1,a1
    80002e52:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	eaa080e7          	jalr	-342(ra) # 80002cfe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e5c:	864a                	mv	a2,s2
    80002e5e:	85a6                	mv	a1,s1
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	f58080e7          	jalr	-168(ra) # 80002db8 <fetchstr>
}
    80002e68:	60e2                	ld	ra,24(sp)
    80002e6a:	6442                	ld	s0,16(sp)
    80002e6c:	64a2                	ld	s1,8(sp)
    80002e6e:	6902                	ld	s2,0(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <syscall>:
struct syscall_arg_info syscall_arg_infos[] = {{ 0, "fork" },{ 1, "exit" },{ 1, "wait" },{ 0, "pipe" },{ 3, "read" },{ 2, "kill" },{ 2, "exec" },{ 1, "fstat" },{ 1, "chdir" },{ 1, "dup" },{ 0, "getpid" },{ 1, "sbrk" },{ 1, "sleep" },{ 0, "uptime" },{ 2, "open" },{ 3, "write" },{ 3, "mknod" },{ 1, "unlink" },{ 2, "link" },{ 1, "mkdir" },{ 1, "close" },{ 1, "trace" },{ 3, "waitx" }, {2, "set_priority"},};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002e74:	711d                	addi	sp,sp,-96
    80002e76:	ec86                	sd	ra,88(sp)
    80002e78:	e8a2                	sd	s0,80(sp)
    80002e7a:	e4a6                	sd	s1,72(sp)
    80002e7c:	e0ca                	sd	s2,64(sp)
    80002e7e:	fc4e                	sd	s3,56(sp)
    80002e80:	f852                	sd	s4,48(sp)
    80002e82:	f456                	sd	s5,40(sp)
    80002e84:	f05a                	sd	s6,32(sp)
    80002e86:	ec5e                	sd	s7,24(sp)
    80002e88:	e862                	sd	s8,16(sp)
    80002e8a:	e466                	sd	s9,8(sp)
    80002e8c:	e06a                	sd	s10,0(sp)
    80002e8e:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	b20080e7          	jalr	-1248(ra) # 800019b0 <myproc>
    80002e98:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002e9a:	6d24                	ld	s1,88(a0)
    80002e9c:	74dc                	ld	a5,168(s1)
    80002e9e:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ea2:	37fd                	addiw	a5,a5,-1
    80002ea4:	475d                	li	a4,23
    80002ea6:	06f76f63          	bltu	a4,a5,80002f24 <syscall+0xb0>
    80002eaa:	003b1713          	slli	a4,s6,0x3
    80002eae:	00005797          	auipc	a5,0x5
    80002eb2:	68a78793          	addi	a5,a5,1674 # 80008538 <syscalls>
    80002eb6:	97ba                	add	a5,a5,a4
    80002eb8:	0007bd03          	ld	s10,0(a5)
    80002ebc:	060d0463          	beqz	s10,80002f24 <syscall+0xb0>
    80002ec0:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002ec2:	fffb0c1b          	addiw	s8,s6,-1
    80002ec6:	004c1713          	slli	a4,s8,0x4
    80002eca:	00006797          	auipc	a5,0x6
    80002ece:	a8e78793          	addi	a5,a5,-1394 # 80008958 <syscall_arg_infos>
    80002ed2:	97ba                	add	a5,a5,a4
    80002ed4:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002ed8:	00299793          	slli	a5,s3,0x2
    80002edc:	07bd                	addi	a5,a5,15
    80002ede:	9bc1                	andi	a5,a5,-16
    80002ee0:	40f10133          	sub	sp,sp,a5
    80002ee4:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002ee6:	0f305363          	blez	s3,80002fcc <syscall+0x158>
    80002eea:	8ade                	mv	s5,s7
    80002eec:	895e                	mv	s2,s7
    80002eee:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002ef0:	8526                	mv	a0,s1
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	e0c080e7          	jalr	-500(ra) # 80002cfe <argraw>
    80002efa:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002efe:	2485                	addiw	s1,s1,1
    80002f00:	0911                	addi	s2,s2,4
    80002f02:	fe9997e3          	bne	s3,s1,80002ef0 <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002f06:	058a3483          	ld	s1,88(s4)
    80002f0a:	9d02                	jalr	s10
    80002f0c:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002f0e:	4785                	li	a5,1
    80002f10:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002f14:	168a2b03          	lw	s6,360(s4)
    80002f18:	0167f7b3          	and	a5,a5,s6
    80002f1c:	2781                	sext.w	a5,a5
    80002f1e:	e7a1                	bnez	a5,80002f66 <syscall+0xf2>
    80002f20:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f22:	a015                	j	80002f46 <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f24:	86da                	mv	a3,s6
    80002f26:	158a0613          	addi	a2,s4,344
    80002f2a:	030a2583          	lw	a1,48(s4)
    80002f2e:	00005517          	auipc	a0,0x5
    80002f32:	4fa50513          	addi	a0,a0,1274 # 80008428 <states.1756+0x168>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	652080e7          	jalr	1618(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f3e:	058a3783          	ld	a5,88(s4)
    80002f42:	577d                	li	a4,-1
    80002f44:	fbb8                	sd	a4,112(a5)
  }
}
    80002f46:	fa040113          	addi	sp,s0,-96
    80002f4a:	60e6                	ld	ra,88(sp)
    80002f4c:	6446                	ld	s0,80(sp)
    80002f4e:	64a6                	ld	s1,72(sp)
    80002f50:	6906                	ld	s2,64(sp)
    80002f52:	79e2                	ld	s3,56(sp)
    80002f54:	7a42                	ld	s4,48(sp)
    80002f56:	7aa2                	ld	s5,40(sp)
    80002f58:	7b02                	ld	s6,32(sp)
    80002f5a:	6be2                	ld	s7,24(sp)
    80002f5c:	6c42                	ld	s8,16(sp)
    80002f5e:	6ca2                	ld	s9,8(sp)
    80002f60:	6d02                	ld	s10,0(sp)
    80002f62:	6125                	addi	sp,sp,96
    80002f64:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002f66:	0c12                	slli	s8,s8,0x4
    80002f68:	00006797          	auipc	a5,0x6
    80002f6c:	9f078793          	addi	a5,a5,-1552 # 80008958 <syscall_arg_infos>
    80002f70:	9c3e                	add	s8,s8,a5
    80002f72:	008c3603          	ld	a2,8(s8)
    80002f76:	030a2583          	lw	a1,48(s4)
    80002f7a:	00005517          	auipc	a0,0x5
    80002f7e:	4ce50513          	addi	a0,a0,1230 # 80008448 <states.1756+0x188>
    80002f82:	ffffd097          	auipc	ra,0xffffd
    80002f86:	606080e7          	jalr	1542(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002f8a:	fff9879b          	addiw	a5,s3,-1
    80002f8e:	1782                	slli	a5,a5,0x20
    80002f90:	9381                	srli	a5,a5,0x20
    80002f92:	0785                	addi	a5,a5,1
    80002f94:	078a                	slli	a5,a5,0x2
    80002f96:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80002f98:	00005497          	auipc	s1,0x5
    80002f9c:	47848493          	addi	s1,s1,1144 # 80008410 <states.1756+0x150>
    80002fa0:	000aa583          	lw	a1,0(s5)
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	ffffd097          	auipc	ra,0xffffd
    80002faa:	5e2080e7          	jalr	1506(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80002fae:	0a91                	addi	s5,s5,4
    80002fb0:	ff7a98e3          	bne	s5,s7,80002fa0 <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    80002fb4:	058a3783          	ld	a5,88(s4)
    80002fb8:	7bac                	ld	a1,112(a5)
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	45e50513          	addi	a0,a0,1118 # 80008418 <states.1756+0x158>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	5c6080e7          	jalr	1478(ra) # 80000588 <printf>
    80002fca:	bf99                	j	80002f20 <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002fcc:	9d02                	jalr	s10
    80002fce:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002fd0:	4785                	li	a5,1
    80002fd2:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80002fd6:	168a2703          	lw	a4,360(s4)
    80002fda:	8ff9                	and	a5,a5,a4
    80002fdc:	2781                	sext.w	a5,a5
    80002fde:	d3a9                	beqz	a5,80002f20 <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80002fe0:	0c12                	slli	s8,s8,0x4
    80002fe2:	00006797          	auipc	a5,0x6
    80002fe6:	97678793          	addi	a5,a5,-1674 # 80008958 <syscall_arg_infos>
    80002fea:	97e2                	add	a5,a5,s8
    80002fec:	6790                	ld	a2,8(a5)
    80002fee:	030a2583          	lw	a1,48(s4)
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	45650513          	addi	a0,a0,1110 # 80008448 <states.1756+0x188>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	58e080e7          	jalr	1422(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80003002:	bf4d                	j	80002fb4 <syscall+0x140>

0000000080003004 <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000300c:	fec40593          	addi	a1,s0,-20
    80003010:	4501                	li	a0,0
    80003012:	00000097          	auipc	ra,0x0
    80003016:	dee080e7          	jalr	-530(ra) # 80002e00 <argint>
    return -1;
    8000301a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000301c:	00054963          	bltz	a0,8000302e <sys_exit+0x2a>
  exit(n);
    80003020:	fec42503          	lw	a0,-20(s0)
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	5c4080e7          	jalr	1476(ra) # 800025e8 <exit>
  return 0;  // not reached
    8000302c:	4781                	li	a5,0
}
    8000302e:	853e                	mv	a0,a5
    80003030:	60e2                	ld	ra,24(sp)
    80003032:	6442                	ld	s0,16(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003038:	1141                	addi	sp,sp,-16
    8000303a:	e406                	sd	ra,8(sp)
    8000303c:	e022                	sd	s0,0(sp)
    8000303e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	970080e7          	jalr	-1680(ra) # 800019b0 <myproc>
}
    80003048:	5908                	lw	a0,48(a0)
    8000304a:	60a2                	ld	ra,8(sp)
    8000304c:	6402                	ld	s0,0(sp)
    8000304e:	0141                	addi	sp,sp,16
    80003050:	8082                	ret

0000000080003052 <sys_fork>:

uint64
sys_fork(void)
{
    80003052:	1141                	addi	sp,sp,-16
    80003054:	e406                	sd	ra,8(sp)
    80003056:	e022                	sd	s0,0(sp)
    80003058:	0800                	addi	s0,sp,16
  return fork();
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	d4e080e7          	jalr	-690(ra) # 80001da8 <fork>
}
    80003062:	60a2                	ld	ra,8(sp)
    80003064:	6402                	ld	s0,0(sp)
    80003066:	0141                	addi	sp,sp,16
    80003068:	8082                	ret

000000008000306a <sys_wait>:

uint64
sys_wait(void)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003072:	fe840593          	addi	a1,s0,-24
    80003076:	4501                	li	a0,0
    80003078:	00000097          	auipc	ra,0x0
    8000307c:	daa080e7          	jalr	-598(ra) # 80002e22 <argaddr>
    80003080:	87aa                	mv	a5,a0
    return -1;
    80003082:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003084:	0007c863          	bltz	a5,80003094 <sys_wait+0x2a>
  return wait(p);
    80003088:	fe843503          	ld	a0,-24(s0)
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	204080e7          	jalr	516(ra) # 80002290 <wait>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <sys_waitx>:

uint64
sys_waitx(void)
{
    8000309c:	7139                	addi	sp,sp,-64
    8000309e:	fc06                	sd	ra,56(sp)
    800030a0:	f822                	sd	s0,48(sp)
    800030a2:	f426                	sd	s1,40(sp)
    800030a4:	f04a                	sd	s2,32(sp)
    800030a6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    800030a8:	fd840593          	addi	a1,s0,-40
    800030ac:	4501                	li	a0,0
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	d74080e7          	jalr	-652(ra) # 80002e22 <argaddr>
    return -1;
    800030b6:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800030b8:	08054063          	bltz	a0,80003138 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800030bc:	fd040593          	addi	a1,s0,-48
    800030c0:	4505                	li	a0,1
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	d60080e7          	jalr	-672(ra) # 80002e22 <argaddr>
    return -1;
    800030ca:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800030cc:	06054663          	bltz	a0,80003138 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    800030d0:	fc840593          	addi	a1,s0,-56
    800030d4:	4509                	li	a0,2
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	d4c080e7          	jalr	-692(ra) # 80002e22 <argaddr>
    return -1;
    800030de:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800030e0:	04054c63          	bltz	a0,80003138 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800030e4:	fc040613          	addi	a2,s0,-64
    800030e8:	fc440593          	addi	a1,s0,-60
    800030ec:	fd843503          	ld	a0,-40(s0)
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	2c8080e7          	jalr	712(ra) # 800023b8 <waitx>
    800030f8:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	8b6080e7          	jalr	-1866(ra) # 800019b0 <myproc>
    80003102:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003104:	4691                	li	a3,4
    80003106:	fc440613          	addi	a2,s0,-60
    8000310a:	fd043583          	ld	a1,-48(s0)
    8000310e:	6928                	ld	a0,80(a0)
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	562080e7          	jalr	1378(ra) # 80001672 <copyout>
    return -1;
    80003118:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000311a:	00054f63          	bltz	a0,80003138 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    8000311e:	4691                	li	a3,4
    80003120:	fc040613          	addi	a2,s0,-64
    80003124:	fc843583          	ld	a1,-56(s0)
    80003128:	68a8                	ld	a0,80(s1)
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	548080e7          	jalr	1352(ra) # 80001672 <copyout>
    80003132:	00054a63          	bltz	a0,80003146 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003136:	87ca                	mv	a5,s2
}
    80003138:	853e                	mv	a0,a5
    8000313a:	70e2                	ld	ra,56(sp)
    8000313c:	7442                	ld	s0,48(sp)
    8000313e:	74a2                	ld	s1,40(sp)
    80003140:	7902                	ld	s2,32(sp)
    80003142:	6121                	addi	sp,sp,64
    80003144:	8082                	ret
    return -1;
    80003146:	57fd                	li	a5,-1
    80003148:	bfc5                	j	80003138 <sys_waitx+0x9c>

000000008000314a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003154:	fdc40593          	addi	a1,s0,-36
    80003158:	4501                	li	a0,0
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	ca6080e7          	jalr	-858(ra) # 80002e00 <argint>
    80003162:	87aa                	mv	a5,a0
    return -1;
    80003164:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003166:	0207c063          	bltz	a5,80003186 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	846080e7          	jalr	-1978(ra) # 800019b0 <myproc>
    80003172:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003174:	fdc42503          	lw	a0,-36(s0)
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	bbc080e7          	jalr	-1092(ra) # 80001d34 <growproc>
    80003180:	00054863          	bltz	a0,80003190 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003184:	8526                	mv	a0,s1
}
    80003186:	70a2                	ld	ra,40(sp)
    80003188:	7402                	ld	s0,32(sp)
    8000318a:	64e2                	ld	s1,24(sp)
    8000318c:	6145                	addi	sp,sp,48
    8000318e:	8082                	ret
    return -1;
    80003190:	557d                	li	a0,-1
    80003192:	bfd5                	j	80003186 <sys_sbrk+0x3c>

0000000080003194 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003194:	7139                	addi	sp,sp,-64
    80003196:	fc06                	sd	ra,56(sp)
    80003198:	f822                	sd	s0,48(sp)
    8000319a:	f426                	sd	s1,40(sp)
    8000319c:	f04a                	sd	s2,32(sp)
    8000319e:	ec4e                	sd	s3,24(sp)
    800031a0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031a2:	fcc40593          	addi	a1,s0,-52
    800031a6:	4501                	li	a0,0
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	c58080e7          	jalr	-936(ra) # 80002e00 <argint>
    return -1;
    800031b0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031b2:	06054563          	bltz	a0,8000321c <sys_sleep+0x88>
  acquire(&tickslock);
    800031b6:	00015517          	auipc	a0,0x15
    800031ba:	91a50513          	addi	a0,a0,-1766 # 80017ad0 <tickslock>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	a26080e7          	jalr	-1498(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031c6:	00006917          	auipc	s2,0x6
    800031ca:	e6a92903          	lw	s2,-406(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800031ce:	fcc42783          	lw	a5,-52(s0)
    800031d2:	cf85                	beqz	a5,8000320a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031d4:	00015997          	auipc	s3,0x15
    800031d8:	8fc98993          	addi	s3,s3,-1796 # 80017ad0 <tickslock>
    800031dc:	00006497          	auipc	s1,0x6
    800031e0:	e5448493          	addi	s1,s1,-428 # 80009030 <ticks>
    if(myproc()->killed){
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	7cc080e7          	jalr	1996(ra) # 800019b0 <myproc>
    800031ec:	551c                	lw	a5,40(a0)
    800031ee:	ef9d                	bnez	a5,8000322c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031f0:	85ce                	mv	a1,s3
    800031f2:	8526                	mv	a0,s1
    800031f4:	fffff097          	auipc	ra,0xfffff
    800031f8:	038080e7          	jalr	56(ra) # 8000222c <sleep>
  while(ticks - ticks0 < n){
    800031fc:	409c                	lw	a5,0(s1)
    800031fe:	412787bb          	subw	a5,a5,s2
    80003202:	fcc42703          	lw	a4,-52(s0)
    80003206:	fce7efe3          	bltu	a5,a4,800031e4 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000320a:	00015517          	auipc	a0,0x15
    8000320e:	8c650513          	addi	a0,a0,-1850 # 80017ad0 <tickslock>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
  return 0;
    8000321a:	4781                	li	a5,0
}
    8000321c:	853e                	mv	a0,a5
    8000321e:	70e2                	ld	ra,56(sp)
    80003220:	7442                	ld	s0,48(sp)
    80003222:	74a2                	ld	s1,40(sp)
    80003224:	7902                	ld	s2,32(sp)
    80003226:	69e2                	ld	s3,24(sp)
    80003228:	6121                	addi	sp,sp,64
    8000322a:	8082                	ret
      release(&tickslock);
    8000322c:	00015517          	auipc	a0,0x15
    80003230:	8a450513          	addi	a0,a0,-1884 # 80017ad0 <tickslock>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
      return -1;
    8000323c:	57fd                	li	a5,-1
    8000323e:	bff9                	j	8000321c <sys_sleep+0x88>

0000000080003240 <sys_kill>:

uint64
sys_kill(void)
{
    80003240:	1101                	addi	sp,sp,-32
    80003242:	ec06                	sd	ra,24(sp)
    80003244:	e822                	sd	s0,16(sp)
    80003246:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003248:	fec40593          	addi	a1,s0,-20
    8000324c:	4501                	li	a0,0
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	bb2080e7          	jalr	-1102(ra) # 80002e00 <argint>
    80003256:	87aa                	mv	a5,a0
    return -1;
    80003258:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000325a:	0007c863          	bltz	a5,8000326a <sys_kill+0x2a>
  return kill(pid);
    8000325e:	fec42503          	lw	a0,-20(s0)
    80003262:	fffff097          	auipc	ra,0xfffff
    80003266:	468080e7          	jalr	1128(ra) # 800026ca <kill>
}
    8000326a:	60e2                	ld	ra,24(sp)
    8000326c:	6442                	ld	s0,16(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000327c:	00015517          	auipc	a0,0x15
    80003280:	85450513          	addi	a0,a0,-1964 # 80017ad0 <tickslock>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	960080e7          	jalr	-1696(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000328c:	00006497          	auipc	s1,0x6
    80003290:	da44a483          	lw	s1,-604(s1) # 80009030 <ticks>
  release(&tickslock);
    80003294:	00015517          	auipc	a0,0x15
    80003298:	83c50513          	addi	a0,a0,-1988 # 80017ad0 <tickslock>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	9fc080e7          	jalr	-1540(ra) # 80000c98 <release>
  return xticks;
}
    800032a4:	02049513          	slli	a0,s1,0x20
    800032a8:	9101                	srli	a0,a0,0x20
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6105                	addi	sp,sp,32
    800032b2:	8082                	ret

00000000800032b4 <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    800032bc:	fec40593          	addi	a1,s0,-20
    800032c0:	4501                	li	a0,0
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	b3e080e7          	jalr	-1218(ra) # 80002e00 <argint>
  trace(n);
    800032ca:	fec42503          	lw	a0,-20(s0)
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	5d4080e7          	jalr	1492(ra) # 800028a2 <trace>
  return 0; // if the syscall is successful, return 0
}
    800032d6:	4501                	li	a0,0
    800032d8:	60e2                	ld	ra,24(sp)
    800032da:	6442                	ld	s0,16(sp)
    800032dc:	6105                	addi	sp,sp,32
    800032de:	8082                	ret

00000000800032e0 <sys_set_priority>:

// to change the static priority of a process with given pid
uint64
sys_set_priority(void)
{
    800032e0:	1101                	addi	sp,sp,-32
    800032e2:	ec06                	sd	ra,24(sp)
    800032e4:	e822                	sd	s0,16(sp)
    800032e6:	1000                	addi	s0,sp,32
  int pid, new_priority;
  if(argint(0, &new_priority) < 0)
    800032e8:	fe840593          	addi	a1,s0,-24
    800032ec:	4501                	li	a0,0
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	b12080e7          	jalr	-1262(ra) # 80002e00 <argint>
    return -1;
    800032f6:	57fd                	li	a5,-1
  if(argint(0, &new_priority) < 0)
    800032f8:	02054563          	bltz	a0,80003322 <sys_set_priority+0x42>
  if(argint(1, &pid) < 0)
    800032fc:	fec40593          	addi	a1,s0,-20
    80003300:	4505                	li	a0,1
    80003302:	00000097          	auipc	ra,0x0
    80003306:	afe080e7          	jalr	-1282(ra) # 80002e00 <argint>
    return -1;
    8000330a:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    8000330c:	00054b63          	bltz	a0,80003322 <sys_set_priority+0x42>
  return set_priority(new_priority, pid);
    80003310:	fec42583          	lw	a1,-20(s0)
    80003314:	fe842503          	lw	a0,-24(s0)
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	5ac080e7          	jalr	1452(ra) # 800028c4 <set_priority>
    80003320:	87aa                	mv	a5,a0
    80003322:	853e                	mv	a0,a5
    80003324:	60e2                	ld	ra,24(sp)
    80003326:	6442                	ld	s0,16(sp)
    80003328:	6105                	addi	sp,sp,32
    8000332a:	8082                	ret

000000008000332c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000332c:	7179                	addi	sp,sp,-48
    8000332e:	f406                	sd	ra,40(sp)
    80003330:	f022                	sd	s0,32(sp)
    80003332:	ec26                	sd	s1,24(sp)
    80003334:	e84a                	sd	s2,16(sp)
    80003336:	e44e                	sd	s3,8(sp)
    80003338:	e052                	sd	s4,0(sp)
    8000333a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000333c:	00005597          	auipc	a1,0x5
    80003340:	2c458593          	addi	a1,a1,708 # 80008600 <syscalls+0xc8>
    80003344:	00014517          	auipc	a0,0x14
    80003348:	7a450513          	addi	a0,a0,1956 # 80017ae8 <bcache>
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	808080e7          	jalr	-2040(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003354:	0001c797          	auipc	a5,0x1c
    80003358:	79478793          	addi	a5,a5,1940 # 8001fae8 <bcache+0x8000>
    8000335c:	0001d717          	auipc	a4,0x1d
    80003360:	9f470713          	addi	a4,a4,-1548 # 8001fd50 <bcache+0x8268>
    80003364:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003368:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000336c:	00014497          	auipc	s1,0x14
    80003370:	79448493          	addi	s1,s1,1940 # 80017b00 <bcache+0x18>
    b->next = bcache.head.next;
    80003374:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003376:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003378:	00005a17          	auipc	s4,0x5
    8000337c:	290a0a13          	addi	s4,s4,656 # 80008608 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003380:	2b893783          	ld	a5,696(s2)
    80003384:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003386:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000338a:	85d2                	mv	a1,s4
    8000338c:	01048513          	addi	a0,s1,16
    80003390:	00001097          	auipc	ra,0x1
    80003394:	4bc080e7          	jalr	1212(ra) # 8000484c <initsleeplock>
    bcache.head.next->prev = b;
    80003398:	2b893783          	ld	a5,696(s2)
    8000339c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000339e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033a2:	45848493          	addi	s1,s1,1112
    800033a6:	fd349de3          	bne	s1,s3,80003380 <binit+0x54>
  }
}
    800033aa:	70a2                	ld	ra,40(sp)
    800033ac:	7402                	ld	s0,32(sp)
    800033ae:	64e2                	ld	s1,24(sp)
    800033b0:	6942                	ld	s2,16(sp)
    800033b2:	69a2                	ld	s3,8(sp)
    800033b4:	6a02                	ld	s4,0(sp)
    800033b6:	6145                	addi	sp,sp,48
    800033b8:	8082                	ret

00000000800033ba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033ba:	7179                	addi	sp,sp,-48
    800033bc:	f406                	sd	ra,40(sp)
    800033be:	f022                	sd	s0,32(sp)
    800033c0:	ec26                	sd	s1,24(sp)
    800033c2:	e84a                	sd	s2,16(sp)
    800033c4:	e44e                	sd	s3,8(sp)
    800033c6:	1800                	addi	s0,sp,48
    800033c8:	89aa                	mv	s3,a0
    800033ca:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033cc:	00014517          	auipc	a0,0x14
    800033d0:	71c50513          	addi	a0,a0,1820 # 80017ae8 <bcache>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	810080e7          	jalr	-2032(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033dc:	0001d497          	auipc	s1,0x1d
    800033e0:	9c44b483          	ld	s1,-1596(s1) # 8001fda0 <bcache+0x82b8>
    800033e4:	0001d797          	auipc	a5,0x1d
    800033e8:	96c78793          	addi	a5,a5,-1684 # 8001fd50 <bcache+0x8268>
    800033ec:	02f48f63          	beq	s1,a5,8000342a <bread+0x70>
    800033f0:	873e                	mv	a4,a5
    800033f2:	a021                	j	800033fa <bread+0x40>
    800033f4:	68a4                	ld	s1,80(s1)
    800033f6:	02e48a63          	beq	s1,a4,8000342a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033fa:	449c                	lw	a5,8(s1)
    800033fc:	ff379ce3          	bne	a5,s3,800033f4 <bread+0x3a>
    80003400:	44dc                	lw	a5,12(s1)
    80003402:	ff2799e3          	bne	a5,s2,800033f4 <bread+0x3a>
      b->refcnt++;
    80003406:	40bc                	lw	a5,64(s1)
    80003408:	2785                	addiw	a5,a5,1
    8000340a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000340c:	00014517          	auipc	a0,0x14
    80003410:	6dc50513          	addi	a0,a0,1756 # 80017ae8 <bcache>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	884080e7          	jalr	-1916(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000341c:	01048513          	addi	a0,s1,16
    80003420:	00001097          	auipc	ra,0x1
    80003424:	466080e7          	jalr	1126(ra) # 80004886 <acquiresleep>
      return b;
    80003428:	a8b9                	j	80003486 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000342a:	0001d497          	auipc	s1,0x1d
    8000342e:	96e4b483          	ld	s1,-1682(s1) # 8001fd98 <bcache+0x82b0>
    80003432:	0001d797          	auipc	a5,0x1d
    80003436:	91e78793          	addi	a5,a5,-1762 # 8001fd50 <bcache+0x8268>
    8000343a:	00f48863          	beq	s1,a5,8000344a <bread+0x90>
    8000343e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003440:	40bc                	lw	a5,64(s1)
    80003442:	cf81                	beqz	a5,8000345a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003444:	64a4                	ld	s1,72(s1)
    80003446:	fee49de3          	bne	s1,a4,80003440 <bread+0x86>
  panic("bget: no buffers");
    8000344a:	00005517          	auipc	a0,0x5
    8000344e:	1c650513          	addi	a0,a0,454 # 80008610 <syscalls+0xd8>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>
      b->dev = dev;
    8000345a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000345e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003462:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003466:	4785                	li	a5,1
    80003468:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000346a:	00014517          	auipc	a0,0x14
    8000346e:	67e50513          	addi	a0,a0,1662 # 80017ae8 <bcache>
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	826080e7          	jalr	-2010(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000347a:	01048513          	addi	a0,s1,16
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	408080e7          	jalr	1032(ra) # 80004886 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003486:	409c                	lw	a5,0(s1)
    80003488:	cb89                	beqz	a5,8000349a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000348a:	8526                	mv	a0,s1
    8000348c:	70a2                	ld	ra,40(sp)
    8000348e:	7402                	ld	s0,32(sp)
    80003490:	64e2                	ld	s1,24(sp)
    80003492:	6942                	ld	s2,16(sp)
    80003494:	69a2                	ld	s3,8(sp)
    80003496:	6145                	addi	sp,sp,48
    80003498:	8082                	ret
    virtio_disk_rw(b, 0);
    8000349a:	4581                	li	a1,0
    8000349c:	8526                	mv	a0,s1
    8000349e:	00003097          	auipc	ra,0x3
    800034a2:	f08080e7          	jalr	-248(ra) # 800063a6 <virtio_disk_rw>
    b->valid = 1;
    800034a6:	4785                	li	a5,1
    800034a8:	c09c                	sw	a5,0(s1)
  return b;
    800034aa:	b7c5                	j	8000348a <bread+0xd0>

00000000800034ac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034ac:	1101                	addi	sp,sp,-32
    800034ae:	ec06                	sd	ra,24(sp)
    800034b0:	e822                	sd	s0,16(sp)
    800034b2:	e426                	sd	s1,8(sp)
    800034b4:	1000                	addi	s0,sp,32
    800034b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034b8:	0541                	addi	a0,a0,16
    800034ba:	00001097          	auipc	ra,0x1
    800034be:	466080e7          	jalr	1126(ra) # 80004920 <holdingsleep>
    800034c2:	cd01                	beqz	a0,800034da <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034c4:	4585                	li	a1,1
    800034c6:	8526                	mv	a0,s1
    800034c8:	00003097          	auipc	ra,0x3
    800034cc:	ede080e7          	jalr	-290(ra) # 800063a6 <virtio_disk_rw>
}
    800034d0:	60e2                	ld	ra,24(sp)
    800034d2:	6442                	ld	s0,16(sp)
    800034d4:	64a2                	ld	s1,8(sp)
    800034d6:	6105                	addi	sp,sp,32
    800034d8:	8082                	ret
    panic("bwrite");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	14e50513          	addi	a0,a0,334 # 80008628 <syscalls+0xf0>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>

00000000800034ea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034ea:	1101                	addi	sp,sp,-32
    800034ec:	ec06                	sd	ra,24(sp)
    800034ee:	e822                	sd	s0,16(sp)
    800034f0:	e426                	sd	s1,8(sp)
    800034f2:	e04a                	sd	s2,0(sp)
    800034f4:	1000                	addi	s0,sp,32
    800034f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034f8:	01050913          	addi	s2,a0,16
    800034fc:	854a                	mv	a0,s2
    800034fe:	00001097          	auipc	ra,0x1
    80003502:	422080e7          	jalr	1058(ra) # 80004920 <holdingsleep>
    80003506:	c92d                	beqz	a0,80003578 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003508:	854a                	mv	a0,s2
    8000350a:	00001097          	auipc	ra,0x1
    8000350e:	3d2080e7          	jalr	978(ra) # 800048dc <releasesleep>

  acquire(&bcache.lock);
    80003512:	00014517          	auipc	a0,0x14
    80003516:	5d650513          	addi	a0,a0,1494 # 80017ae8 <bcache>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	6ca080e7          	jalr	1738(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003522:	40bc                	lw	a5,64(s1)
    80003524:	37fd                	addiw	a5,a5,-1
    80003526:	0007871b          	sext.w	a4,a5
    8000352a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000352c:	eb05                	bnez	a4,8000355c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000352e:	68bc                	ld	a5,80(s1)
    80003530:	64b8                	ld	a4,72(s1)
    80003532:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003534:	64bc                	ld	a5,72(s1)
    80003536:	68b8                	ld	a4,80(s1)
    80003538:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000353a:	0001c797          	auipc	a5,0x1c
    8000353e:	5ae78793          	addi	a5,a5,1454 # 8001fae8 <bcache+0x8000>
    80003542:	2b87b703          	ld	a4,696(a5)
    80003546:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003548:	0001d717          	auipc	a4,0x1d
    8000354c:	80870713          	addi	a4,a4,-2040 # 8001fd50 <bcache+0x8268>
    80003550:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003552:	2b87b703          	ld	a4,696(a5)
    80003556:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003558:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000355c:	00014517          	auipc	a0,0x14
    80003560:	58c50513          	addi	a0,a0,1420 # 80017ae8 <bcache>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	734080e7          	jalr	1844(ra) # 80000c98 <release>
}
    8000356c:	60e2                	ld	ra,24(sp)
    8000356e:	6442                	ld	s0,16(sp)
    80003570:	64a2                	ld	s1,8(sp)
    80003572:	6902                	ld	s2,0(sp)
    80003574:	6105                	addi	sp,sp,32
    80003576:	8082                	ret
    panic("brelse");
    80003578:	00005517          	auipc	a0,0x5
    8000357c:	0b850513          	addi	a0,a0,184 # 80008630 <syscalls+0xf8>
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	fbe080e7          	jalr	-66(ra) # 8000053e <panic>

0000000080003588 <bpin>:

void
bpin(struct buf *b) {
    80003588:	1101                	addi	sp,sp,-32
    8000358a:	ec06                	sd	ra,24(sp)
    8000358c:	e822                	sd	s0,16(sp)
    8000358e:	e426                	sd	s1,8(sp)
    80003590:	1000                	addi	s0,sp,32
    80003592:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003594:	00014517          	auipc	a0,0x14
    80003598:	55450513          	addi	a0,a0,1364 # 80017ae8 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035a4:	40bc                	lw	a5,64(s1)
    800035a6:	2785                	addiw	a5,a5,1
    800035a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035aa:	00014517          	auipc	a0,0x14
    800035ae:	53e50513          	addi	a0,a0,1342 # 80017ae8 <bcache>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
}
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <bunpin>:

void
bunpin(struct buf *b) {
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	1000                	addi	s0,sp,32
    800035ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035d0:	00014517          	auipc	a0,0x14
    800035d4:	51850513          	addi	a0,a0,1304 # 80017ae8 <bcache>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	60c080e7          	jalr	1548(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035e0:	40bc                	lw	a5,64(s1)
    800035e2:	37fd                	addiw	a5,a5,-1
    800035e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035e6:	00014517          	auipc	a0,0x14
    800035ea:	50250513          	addi	a0,a0,1282 # 80017ae8 <bcache>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	6aa080e7          	jalr	1706(ra) # 80000c98 <release>
}
    800035f6:	60e2                	ld	ra,24(sp)
    800035f8:	6442                	ld	s0,16(sp)
    800035fa:	64a2                	ld	s1,8(sp)
    800035fc:	6105                	addi	sp,sp,32
    800035fe:	8082                	ret

0000000080003600 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003600:	1101                	addi	sp,sp,-32
    80003602:	ec06                	sd	ra,24(sp)
    80003604:	e822                	sd	s0,16(sp)
    80003606:	e426                	sd	s1,8(sp)
    80003608:	e04a                	sd	s2,0(sp)
    8000360a:	1000                	addi	s0,sp,32
    8000360c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000360e:	00d5d59b          	srliw	a1,a1,0xd
    80003612:	0001d797          	auipc	a5,0x1d
    80003616:	bb27a783          	lw	a5,-1102(a5) # 800201c4 <sb+0x1c>
    8000361a:	9dbd                	addw	a1,a1,a5
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	d9e080e7          	jalr	-610(ra) # 800033ba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003624:	0074f713          	andi	a4,s1,7
    80003628:	4785                	li	a5,1
    8000362a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000362e:	14ce                	slli	s1,s1,0x33
    80003630:	90d9                	srli	s1,s1,0x36
    80003632:	00950733          	add	a4,a0,s1
    80003636:	05874703          	lbu	a4,88(a4)
    8000363a:	00e7f6b3          	and	a3,a5,a4
    8000363e:	c69d                	beqz	a3,8000366c <bfree+0x6c>
    80003640:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003642:	94aa                	add	s1,s1,a0
    80003644:	fff7c793          	not	a5,a5
    80003648:	8ff9                	and	a5,a5,a4
    8000364a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	118080e7          	jalr	280(ra) # 80004766 <log_write>
  brelse(bp);
    80003656:	854a                	mv	a0,s2
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	e92080e7          	jalr	-366(ra) # 800034ea <brelse>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6902                	ld	s2,0(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret
    panic("freeing free block");
    8000366c:	00005517          	auipc	a0,0x5
    80003670:	fcc50513          	addi	a0,a0,-52 # 80008638 <syscalls+0x100>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>

000000008000367c <balloc>:
{
    8000367c:	711d                	addi	sp,sp,-96
    8000367e:	ec86                	sd	ra,88(sp)
    80003680:	e8a2                	sd	s0,80(sp)
    80003682:	e4a6                	sd	s1,72(sp)
    80003684:	e0ca                	sd	s2,64(sp)
    80003686:	fc4e                	sd	s3,56(sp)
    80003688:	f852                	sd	s4,48(sp)
    8000368a:	f456                	sd	s5,40(sp)
    8000368c:	f05a                	sd	s6,32(sp)
    8000368e:	ec5e                	sd	s7,24(sp)
    80003690:	e862                	sd	s8,16(sp)
    80003692:	e466                	sd	s9,8(sp)
    80003694:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003696:	0001d797          	auipc	a5,0x1d
    8000369a:	b167a783          	lw	a5,-1258(a5) # 800201ac <sb+0x4>
    8000369e:	cbd1                	beqz	a5,80003732 <balloc+0xb6>
    800036a0:	8baa                	mv	s7,a0
    800036a2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036a4:	0001db17          	auipc	s6,0x1d
    800036a8:	b04b0b13          	addi	s6,s6,-1276 # 800201a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ac:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036ae:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036b2:	6c89                	lui	s9,0x2
    800036b4:	a831                	j	800036d0 <balloc+0x54>
    brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	e32080e7          	jalr	-462(ra) # 800034ea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036c0:	015c87bb          	addw	a5,s9,s5
    800036c4:	00078a9b          	sext.w	s5,a5
    800036c8:	004b2703          	lw	a4,4(s6)
    800036cc:	06eaf363          	bgeu	s5,a4,80003732 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036d0:	41fad79b          	sraiw	a5,s5,0x1f
    800036d4:	0137d79b          	srliw	a5,a5,0x13
    800036d8:	015787bb          	addw	a5,a5,s5
    800036dc:	40d7d79b          	sraiw	a5,a5,0xd
    800036e0:	01cb2583          	lw	a1,28(s6)
    800036e4:	9dbd                	addw	a1,a1,a5
    800036e6:	855e                	mv	a0,s7
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	cd2080e7          	jalr	-814(ra) # 800033ba <bread>
    800036f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f2:	004b2503          	lw	a0,4(s6)
    800036f6:	000a849b          	sext.w	s1,s5
    800036fa:	8662                	mv	a2,s8
    800036fc:	faa4fde3          	bgeu	s1,a0,800036b6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003700:	41f6579b          	sraiw	a5,a2,0x1f
    80003704:	01d7d69b          	srliw	a3,a5,0x1d
    80003708:	00c6873b          	addw	a4,a3,a2
    8000370c:	00777793          	andi	a5,a4,7
    80003710:	9f95                	subw	a5,a5,a3
    80003712:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003716:	4037571b          	sraiw	a4,a4,0x3
    8000371a:	00e906b3          	add	a3,s2,a4
    8000371e:	0586c683          	lbu	a3,88(a3)
    80003722:	00d7f5b3          	and	a1,a5,a3
    80003726:	cd91                	beqz	a1,80003742 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003728:	2605                	addiw	a2,a2,1
    8000372a:	2485                	addiw	s1,s1,1
    8000372c:	fd4618e3          	bne	a2,s4,800036fc <balloc+0x80>
    80003730:	b759                	j	800036b6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	f1e50513          	addi	a0,a0,-226 # 80008650 <syscalls+0x118>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e04080e7          	jalr	-508(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003742:	974a                	add	a4,a4,s2
    80003744:	8fd5                	or	a5,a5,a3
    80003746:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	01a080e7          	jalr	26(ra) # 80004766 <log_write>
        brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	d94080e7          	jalr	-620(ra) # 800034ea <brelse>
  bp = bread(dev, bno);
    8000375e:	85a6                	mv	a1,s1
    80003760:	855e                	mv	a0,s7
    80003762:	00000097          	auipc	ra,0x0
    80003766:	c58080e7          	jalr	-936(ra) # 800033ba <bread>
    8000376a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000376c:	40000613          	li	a2,1024
    80003770:	4581                	li	a1,0
    80003772:	05850513          	addi	a0,a0,88
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	56a080e7          	jalr	1386(ra) # 80000ce0 <memset>
  log_write(bp);
    8000377e:	854a                	mv	a0,s2
    80003780:	00001097          	auipc	ra,0x1
    80003784:	fe6080e7          	jalr	-26(ra) # 80004766 <log_write>
  brelse(bp);
    80003788:	854a                	mv	a0,s2
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	d60080e7          	jalr	-672(ra) # 800034ea <brelse>
}
    80003792:	8526                	mv	a0,s1
    80003794:	60e6                	ld	ra,88(sp)
    80003796:	6446                	ld	s0,80(sp)
    80003798:	64a6                	ld	s1,72(sp)
    8000379a:	6906                	ld	s2,64(sp)
    8000379c:	79e2                	ld	s3,56(sp)
    8000379e:	7a42                	ld	s4,48(sp)
    800037a0:	7aa2                	ld	s5,40(sp)
    800037a2:	7b02                	ld	s6,32(sp)
    800037a4:	6be2                	ld	s7,24(sp)
    800037a6:	6c42                	ld	s8,16(sp)
    800037a8:	6ca2                	ld	s9,8(sp)
    800037aa:	6125                	addi	sp,sp,96
    800037ac:	8082                	ret

00000000800037ae <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037ae:	7179                	addi	sp,sp,-48
    800037b0:	f406                	sd	ra,40(sp)
    800037b2:	f022                	sd	s0,32(sp)
    800037b4:	ec26                	sd	s1,24(sp)
    800037b6:	e84a                	sd	s2,16(sp)
    800037b8:	e44e                	sd	s3,8(sp)
    800037ba:	e052                	sd	s4,0(sp)
    800037bc:	1800                	addi	s0,sp,48
    800037be:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037c0:	47ad                	li	a5,11
    800037c2:	04b7fe63          	bgeu	a5,a1,8000381e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037c6:	ff45849b          	addiw	s1,a1,-12
    800037ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037ce:	0ff00793          	li	a5,255
    800037d2:	0ae7e363          	bltu	a5,a4,80003878 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037d6:	08052583          	lw	a1,128(a0)
    800037da:	c5ad                	beqz	a1,80003844 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037dc:	00092503          	lw	a0,0(s2)
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	bda080e7          	jalr	-1062(ra) # 800033ba <bread>
    800037e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ee:	02049593          	slli	a1,s1,0x20
    800037f2:	9181                	srli	a1,a1,0x20
    800037f4:	058a                	slli	a1,a1,0x2
    800037f6:	00b784b3          	add	s1,a5,a1
    800037fa:	0004a983          	lw	s3,0(s1)
    800037fe:	04098d63          	beqz	s3,80003858 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003802:	8552                	mv	a0,s4
    80003804:	00000097          	auipc	ra,0x0
    80003808:	ce6080e7          	jalr	-794(ra) # 800034ea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000380c:	854e                	mv	a0,s3
    8000380e:	70a2                	ld	ra,40(sp)
    80003810:	7402                	ld	s0,32(sp)
    80003812:	64e2                	ld	s1,24(sp)
    80003814:	6942                	ld	s2,16(sp)
    80003816:	69a2                	ld	s3,8(sp)
    80003818:	6a02                	ld	s4,0(sp)
    8000381a:	6145                	addi	sp,sp,48
    8000381c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000381e:	02059493          	slli	s1,a1,0x20
    80003822:	9081                	srli	s1,s1,0x20
    80003824:	048a                	slli	s1,s1,0x2
    80003826:	94aa                	add	s1,s1,a0
    80003828:	0504a983          	lw	s3,80(s1)
    8000382c:	fe0990e3          	bnez	s3,8000380c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003830:	4108                	lw	a0,0(a0)
    80003832:	00000097          	auipc	ra,0x0
    80003836:	e4a080e7          	jalr	-438(ra) # 8000367c <balloc>
    8000383a:	0005099b          	sext.w	s3,a0
    8000383e:	0534a823          	sw	s3,80(s1)
    80003842:	b7e9                	j	8000380c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003844:	4108                	lw	a0,0(a0)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	e36080e7          	jalr	-458(ra) # 8000367c <balloc>
    8000384e:	0005059b          	sext.w	a1,a0
    80003852:	08b92023          	sw	a1,128(s2)
    80003856:	b759                	j	800037dc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003858:	00092503          	lw	a0,0(s2)
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	e20080e7          	jalr	-480(ra) # 8000367c <balloc>
    80003864:	0005099b          	sext.w	s3,a0
    80003868:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000386c:	8552                	mv	a0,s4
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	ef8080e7          	jalr	-264(ra) # 80004766 <log_write>
    80003876:	b771                	j	80003802 <bmap+0x54>
  panic("bmap: out of range");
    80003878:	00005517          	auipc	a0,0x5
    8000387c:	df050513          	addi	a0,a0,-528 # 80008668 <syscalls+0x130>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>

0000000080003888 <iget>:
{
    80003888:	7179                	addi	sp,sp,-48
    8000388a:	f406                	sd	ra,40(sp)
    8000388c:	f022                	sd	s0,32(sp)
    8000388e:	ec26                	sd	s1,24(sp)
    80003890:	e84a                	sd	s2,16(sp)
    80003892:	e44e                	sd	s3,8(sp)
    80003894:	e052                	sd	s4,0(sp)
    80003896:	1800                	addi	s0,sp,48
    80003898:	89aa                	mv	s3,a0
    8000389a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000389c:	0001d517          	auipc	a0,0x1d
    800038a0:	92c50513          	addi	a0,a0,-1748 # 800201c8 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	340080e7          	jalr	832(ra) # 80000be4 <acquire>
  empty = 0;
    800038ac:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038ae:	0001d497          	auipc	s1,0x1d
    800038b2:	93248493          	addi	s1,s1,-1742 # 800201e0 <itable+0x18>
    800038b6:	0001e697          	auipc	a3,0x1e
    800038ba:	3ba68693          	addi	a3,a3,954 # 80021c70 <log>
    800038be:	a039                	j	800038cc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038c0:	02090b63          	beqz	s2,800038f6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038c4:	08848493          	addi	s1,s1,136
    800038c8:	02d48a63          	beq	s1,a3,800038fc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038cc:	449c                	lw	a5,8(s1)
    800038ce:	fef059e3          	blez	a5,800038c0 <iget+0x38>
    800038d2:	4098                	lw	a4,0(s1)
    800038d4:	ff3716e3          	bne	a4,s3,800038c0 <iget+0x38>
    800038d8:	40d8                	lw	a4,4(s1)
    800038da:	ff4713e3          	bne	a4,s4,800038c0 <iget+0x38>
      ip->ref++;
    800038de:	2785                	addiw	a5,a5,1
    800038e0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038e2:	0001d517          	auipc	a0,0x1d
    800038e6:	8e650513          	addi	a0,a0,-1818 # 800201c8 <itable>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
      return ip;
    800038f2:	8926                	mv	s2,s1
    800038f4:	a03d                	j	80003922 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038f6:	f7f9                	bnez	a5,800038c4 <iget+0x3c>
    800038f8:	8926                	mv	s2,s1
    800038fa:	b7e9                	j	800038c4 <iget+0x3c>
  if(empty == 0)
    800038fc:	02090c63          	beqz	s2,80003934 <iget+0xac>
  ip->dev = dev;
    80003900:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003904:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003908:	4785                	li	a5,1
    8000390a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000390e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003912:	0001d517          	auipc	a0,0x1d
    80003916:	8b650513          	addi	a0,a0,-1866 # 800201c8 <itable>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	37e080e7          	jalr	894(ra) # 80000c98 <release>
}
    80003922:	854a                	mv	a0,s2
    80003924:	70a2                	ld	ra,40(sp)
    80003926:	7402                	ld	s0,32(sp)
    80003928:	64e2                	ld	s1,24(sp)
    8000392a:	6942                	ld	s2,16(sp)
    8000392c:	69a2                	ld	s3,8(sp)
    8000392e:	6a02                	ld	s4,0(sp)
    80003930:	6145                	addi	sp,sp,48
    80003932:	8082                	ret
    panic("iget: no inodes");
    80003934:	00005517          	auipc	a0,0x5
    80003938:	d4c50513          	addi	a0,a0,-692 # 80008680 <syscalls+0x148>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	c02080e7          	jalr	-1022(ra) # 8000053e <panic>

0000000080003944 <fsinit>:
fsinit(int dev) {
    80003944:	7179                	addi	sp,sp,-48
    80003946:	f406                	sd	ra,40(sp)
    80003948:	f022                	sd	s0,32(sp)
    8000394a:	ec26                	sd	s1,24(sp)
    8000394c:	e84a                	sd	s2,16(sp)
    8000394e:	e44e                	sd	s3,8(sp)
    80003950:	1800                	addi	s0,sp,48
    80003952:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003954:	4585                	li	a1,1
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	a64080e7          	jalr	-1436(ra) # 800033ba <bread>
    8000395e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003960:	0001d997          	auipc	s3,0x1d
    80003964:	84898993          	addi	s3,s3,-1976 # 800201a8 <sb>
    80003968:	02000613          	li	a2,32
    8000396c:	05850593          	addi	a1,a0,88
    80003970:	854e                	mv	a0,s3
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	3ce080e7          	jalr	974(ra) # 80000d40 <memmove>
  brelse(bp);
    8000397a:	8526                	mv	a0,s1
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	b6e080e7          	jalr	-1170(ra) # 800034ea <brelse>
  if(sb.magic != FSMAGIC)
    80003984:	0009a703          	lw	a4,0(s3)
    80003988:	102037b7          	lui	a5,0x10203
    8000398c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003990:	02f71263          	bne	a4,a5,800039b4 <fsinit+0x70>
  initlog(dev, &sb);
    80003994:	0001d597          	auipc	a1,0x1d
    80003998:	81458593          	addi	a1,a1,-2028 # 800201a8 <sb>
    8000399c:	854a                	mv	a0,s2
    8000399e:	00001097          	auipc	ra,0x1
    800039a2:	b4c080e7          	jalr	-1204(ra) # 800044ea <initlog>
}
    800039a6:	70a2                	ld	ra,40(sp)
    800039a8:	7402                	ld	s0,32(sp)
    800039aa:	64e2                	ld	s1,24(sp)
    800039ac:	6942                	ld	s2,16(sp)
    800039ae:	69a2                	ld	s3,8(sp)
    800039b0:	6145                	addi	sp,sp,48
    800039b2:	8082                	ret
    panic("invalid file system");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	cdc50513          	addi	a0,a0,-804 # 80008690 <syscalls+0x158>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b82080e7          	jalr	-1150(ra) # 8000053e <panic>

00000000800039c4 <iinit>:
{
    800039c4:	7179                	addi	sp,sp,-48
    800039c6:	f406                	sd	ra,40(sp)
    800039c8:	f022                	sd	s0,32(sp)
    800039ca:	ec26                	sd	s1,24(sp)
    800039cc:	e84a                	sd	s2,16(sp)
    800039ce:	e44e                	sd	s3,8(sp)
    800039d0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039d2:	00005597          	auipc	a1,0x5
    800039d6:	cd658593          	addi	a1,a1,-810 # 800086a8 <syscalls+0x170>
    800039da:	0001c517          	auipc	a0,0x1c
    800039de:	7ee50513          	addi	a0,a0,2030 # 800201c8 <itable>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	172080e7          	jalr	370(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039ea:	0001d497          	auipc	s1,0x1d
    800039ee:	80648493          	addi	s1,s1,-2042 # 800201f0 <itable+0x28>
    800039f2:	0001e997          	auipc	s3,0x1e
    800039f6:	28e98993          	addi	s3,s3,654 # 80021c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039fa:	00005917          	auipc	s2,0x5
    800039fe:	cb690913          	addi	s2,s2,-842 # 800086b0 <syscalls+0x178>
    80003a02:	85ca                	mv	a1,s2
    80003a04:	8526                	mv	a0,s1
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	e46080e7          	jalr	-442(ra) # 8000484c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a0e:	08848493          	addi	s1,s1,136
    80003a12:	ff3498e3          	bne	s1,s3,80003a02 <iinit+0x3e>
}
    80003a16:	70a2                	ld	ra,40(sp)
    80003a18:	7402                	ld	s0,32(sp)
    80003a1a:	64e2                	ld	s1,24(sp)
    80003a1c:	6942                	ld	s2,16(sp)
    80003a1e:	69a2                	ld	s3,8(sp)
    80003a20:	6145                	addi	sp,sp,48
    80003a22:	8082                	ret

0000000080003a24 <ialloc>:
{
    80003a24:	715d                	addi	sp,sp,-80
    80003a26:	e486                	sd	ra,72(sp)
    80003a28:	e0a2                	sd	s0,64(sp)
    80003a2a:	fc26                	sd	s1,56(sp)
    80003a2c:	f84a                	sd	s2,48(sp)
    80003a2e:	f44e                	sd	s3,40(sp)
    80003a30:	f052                	sd	s4,32(sp)
    80003a32:	ec56                	sd	s5,24(sp)
    80003a34:	e85a                	sd	s6,16(sp)
    80003a36:	e45e                	sd	s7,8(sp)
    80003a38:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a3a:	0001c717          	auipc	a4,0x1c
    80003a3e:	77a72703          	lw	a4,1914(a4) # 800201b4 <sb+0xc>
    80003a42:	4785                	li	a5,1
    80003a44:	04e7fa63          	bgeu	a5,a4,80003a98 <ialloc+0x74>
    80003a48:	8aaa                	mv	s5,a0
    80003a4a:	8bae                	mv	s7,a1
    80003a4c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a4e:	0001ca17          	auipc	s4,0x1c
    80003a52:	75aa0a13          	addi	s4,s4,1882 # 800201a8 <sb>
    80003a56:	00048b1b          	sext.w	s6,s1
    80003a5a:	0044d593          	srli	a1,s1,0x4
    80003a5e:	018a2783          	lw	a5,24(s4)
    80003a62:	9dbd                	addw	a1,a1,a5
    80003a64:	8556                	mv	a0,s5
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	954080e7          	jalr	-1708(ra) # 800033ba <bread>
    80003a6e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a70:	05850993          	addi	s3,a0,88
    80003a74:	00f4f793          	andi	a5,s1,15
    80003a78:	079a                	slli	a5,a5,0x6
    80003a7a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a7c:	00099783          	lh	a5,0(s3)
    80003a80:	c785                	beqz	a5,80003aa8 <ialloc+0x84>
    brelse(bp);
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	a68080e7          	jalr	-1432(ra) # 800034ea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a8a:	0485                	addi	s1,s1,1
    80003a8c:	00ca2703          	lw	a4,12(s4)
    80003a90:	0004879b          	sext.w	a5,s1
    80003a94:	fce7e1e3          	bltu	a5,a4,80003a56 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a98:	00005517          	auipc	a0,0x5
    80003a9c:	c2050513          	addi	a0,a0,-992 # 800086b8 <syscalls+0x180>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	a9e080e7          	jalr	-1378(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003aa8:	04000613          	li	a2,64
    80003aac:	4581                	li	a1,0
    80003aae:	854e                	mv	a0,s3
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	230080e7          	jalr	560(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ab8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003abc:	854a                	mv	a0,s2
    80003abe:	00001097          	auipc	ra,0x1
    80003ac2:	ca8080e7          	jalr	-856(ra) # 80004766 <log_write>
      brelse(bp);
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	a22080e7          	jalr	-1502(ra) # 800034ea <brelse>
      return iget(dev, inum);
    80003ad0:	85da                	mv	a1,s6
    80003ad2:	8556                	mv	a0,s5
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	db4080e7          	jalr	-588(ra) # 80003888 <iget>
}
    80003adc:	60a6                	ld	ra,72(sp)
    80003ade:	6406                	ld	s0,64(sp)
    80003ae0:	74e2                	ld	s1,56(sp)
    80003ae2:	7942                	ld	s2,48(sp)
    80003ae4:	79a2                	ld	s3,40(sp)
    80003ae6:	7a02                	ld	s4,32(sp)
    80003ae8:	6ae2                	ld	s5,24(sp)
    80003aea:	6b42                	ld	s6,16(sp)
    80003aec:	6ba2                	ld	s7,8(sp)
    80003aee:	6161                	addi	sp,sp,80
    80003af0:	8082                	ret

0000000080003af2 <iupdate>:
{
    80003af2:	1101                	addi	sp,sp,-32
    80003af4:	ec06                	sd	ra,24(sp)
    80003af6:	e822                	sd	s0,16(sp)
    80003af8:	e426                	sd	s1,8(sp)
    80003afa:	e04a                	sd	s2,0(sp)
    80003afc:	1000                	addi	s0,sp,32
    80003afe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b00:	415c                	lw	a5,4(a0)
    80003b02:	0047d79b          	srliw	a5,a5,0x4
    80003b06:	0001c597          	auipc	a1,0x1c
    80003b0a:	6ba5a583          	lw	a1,1722(a1) # 800201c0 <sb+0x18>
    80003b0e:	9dbd                	addw	a1,a1,a5
    80003b10:	4108                	lw	a0,0(a0)
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	8a8080e7          	jalr	-1880(ra) # 800033ba <bread>
    80003b1a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b1c:	05850793          	addi	a5,a0,88
    80003b20:	40c8                	lw	a0,4(s1)
    80003b22:	893d                	andi	a0,a0,15
    80003b24:	051a                	slli	a0,a0,0x6
    80003b26:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b28:	04449703          	lh	a4,68(s1)
    80003b2c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b30:	04649703          	lh	a4,70(s1)
    80003b34:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b38:	04849703          	lh	a4,72(s1)
    80003b3c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b40:	04a49703          	lh	a4,74(s1)
    80003b44:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b48:	44f8                	lw	a4,76(s1)
    80003b4a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b4c:	03400613          	li	a2,52
    80003b50:	05048593          	addi	a1,s1,80
    80003b54:	0531                	addi	a0,a0,12
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	1ea080e7          	jalr	490(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b5e:	854a                	mv	a0,s2
    80003b60:	00001097          	auipc	ra,0x1
    80003b64:	c06080e7          	jalr	-1018(ra) # 80004766 <log_write>
  brelse(bp);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	980080e7          	jalr	-1664(ra) # 800034ea <brelse>
}
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	64a2                	ld	s1,8(sp)
    80003b78:	6902                	ld	s2,0(sp)
    80003b7a:	6105                	addi	sp,sp,32
    80003b7c:	8082                	ret

0000000080003b7e <idup>:
{
    80003b7e:	1101                	addi	sp,sp,-32
    80003b80:	ec06                	sd	ra,24(sp)
    80003b82:	e822                	sd	s0,16(sp)
    80003b84:	e426                	sd	s1,8(sp)
    80003b86:	1000                	addi	s0,sp,32
    80003b88:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b8a:	0001c517          	auipc	a0,0x1c
    80003b8e:	63e50513          	addi	a0,a0,1598 # 800201c8 <itable>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	052080e7          	jalr	82(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b9a:	449c                	lw	a5,8(s1)
    80003b9c:	2785                	addiw	a5,a5,1
    80003b9e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ba0:	0001c517          	auipc	a0,0x1c
    80003ba4:	62850513          	addi	a0,a0,1576 # 800201c8 <itable>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	0f0080e7          	jalr	240(ra) # 80000c98 <release>
}
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	60e2                	ld	ra,24(sp)
    80003bb4:	6442                	ld	s0,16(sp)
    80003bb6:	64a2                	ld	s1,8(sp)
    80003bb8:	6105                	addi	sp,sp,32
    80003bba:	8082                	ret

0000000080003bbc <ilock>:
{
    80003bbc:	1101                	addi	sp,sp,-32
    80003bbe:	ec06                	sd	ra,24(sp)
    80003bc0:	e822                	sd	s0,16(sp)
    80003bc2:	e426                	sd	s1,8(sp)
    80003bc4:	e04a                	sd	s2,0(sp)
    80003bc6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bc8:	c115                	beqz	a0,80003bec <ilock+0x30>
    80003bca:	84aa                	mv	s1,a0
    80003bcc:	451c                	lw	a5,8(a0)
    80003bce:	00f05f63          	blez	a5,80003bec <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bd2:	0541                	addi	a0,a0,16
    80003bd4:	00001097          	auipc	ra,0x1
    80003bd8:	cb2080e7          	jalr	-846(ra) # 80004886 <acquiresleep>
  if(ip->valid == 0){
    80003bdc:	40bc                	lw	a5,64(s1)
    80003bde:	cf99                	beqz	a5,80003bfc <ilock+0x40>
}
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6902                	ld	s2,0(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret
    panic("ilock");
    80003bec:	00005517          	auipc	a0,0x5
    80003bf0:	ae450513          	addi	a0,a0,-1308 # 800086d0 <syscalls+0x198>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	94a080e7          	jalr	-1718(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bfc:	40dc                	lw	a5,4(s1)
    80003bfe:	0047d79b          	srliw	a5,a5,0x4
    80003c02:	0001c597          	auipc	a1,0x1c
    80003c06:	5be5a583          	lw	a1,1470(a1) # 800201c0 <sb+0x18>
    80003c0a:	9dbd                	addw	a1,a1,a5
    80003c0c:	4088                	lw	a0,0(s1)
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	7ac080e7          	jalr	1964(ra) # 800033ba <bread>
    80003c16:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c18:	05850593          	addi	a1,a0,88
    80003c1c:	40dc                	lw	a5,4(s1)
    80003c1e:	8bbd                	andi	a5,a5,15
    80003c20:	079a                	slli	a5,a5,0x6
    80003c22:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c24:	00059783          	lh	a5,0(a1)
    80003c28:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c2c:	00259783          	lh	a5,2(a1)
    80003c30:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c34:	00459783          	lh	a5,4(a1)
    80003c38:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c3c:	00659783          	lh	a5,6(a1)
    80003c40:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c44:	459c                	lw	a5,8(a1)
    80003c46:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c48:	03400613          	li	a2,52
    80003c4c:	05b1                	addi	a1,a1,12
    80003c4e:	05048513          	addi	a0,s1,80
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	0ee080e7          	jalr	238(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c5a:	854a                	mv	a0,s2
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	88e080e7          	jalr	-1906(ra) # 800034ea <brelse>
    ip->valid = 1;
    80003c64:	4785                	li	a5,1
    80003c66:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c68:	04449783          	lh	a5,68(s1)
    80003c6c:	fbb5                	bnez	a5,80003be0 <ilock+0x24>
      panic("ilock: no type");
    80003c6e:	00005517          	auipc	a0,0x5
    80003c72:	a6a50513          	addi	a0,a0,-1430 # 800086d8 <syscalls+0x1a0>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>

0000000080003c7e <iunlock>:
{
    80003c7e:	1101                	addi	sp,sp,-32
    80003c80:	ec06                	sd	ra,24(sp)
    80003c82:	e822                	sd	s0,16(sp)
    80003c84:	e426                	sd	s1,8(sp)
    80003c86:	e04a                	sd	s2,0(sp)
    80003c88:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c8a:	c905                	beqz	a0,80003cba <iunlock+0x3c>
    80003c8c:	84aa                	mv	s1,a0
    80003c8e:	01050913          	addi	s2,a0,16
    80003c92:	854a                	mv	a0,s2
    80003c94:	00001097          	auipc	ra,0x1
    80003c98:	c8c080e7          	jalr	-884(ra) # 80004920 <holdingsleep>
    80003c9c:	cd19                	beqz	a0,80003cba <iunlock+0x3c>
    80003c9e:	449c                	lw	a5,8(s1)
    80003ca0:	00f05d63          	blez	a5,80003cba <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	00001097          	auipc	ra,0x1
    80003caa:	c36080e7          	jalr	-970(ra) # 800048dc <releasesleep>
}
    80003cae:	60e2                	ld	ra,24(sp)
    80003cb0:	6442                	ld	s0,16(sp)
    80003cb2:	64a2                	ld	s1,8(sp)
    80003cb4:	6902                	ld	s2,0(sp)
    80003cb6:	6105                	addi	sp,sp,32
    80003cb8:	8082                	ret
    panic("iunlock");
    80003cba:	00005517          	auipc	a0,0x5
    80003cbe:	a2e50513          	addi	a0,a0,-1490 # 800086e8 <syscalls+0x1b0>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	87c080e7          	jalr	-1924(ra) # 8000053e <panic>

0000000080003cca <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cca:	7179                	addi	sp,sp,-48
    80003ccc:	f406                	sd	ra,40(sp)
    80003cce:	f022                	sd	s0,32(sp)
    80003cd0:	ec26                	sd	s1,24(sp)
    80003cd2:	e84a                	sd	s2,16(sp)
    80003cd4:	e44e                	sd	s3,8(sp)
    80003cd6:	e052                	sd	s4,0(sp)
    80003cd8:	1800                	addi	s0,sp,48
    80003cda:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cdc:	05050493          	addi	s1,a0,80
    80003ce0:	08050913          	addi	s2,a0,128
    80003ce4:	a021                	j	80003cec <itrunc+0x22>
    80003ce6:	0491                	addi	s1,s1,4
    80003ce8:	01248d63          	beq	s1,s2,80003d02 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cec:	408c                	lw	a1,0(s1)
    80003cee:	dde5                	beqz	a1,80003ce6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cf0:	0009a503          	lw	a0,0(s3)
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	90c080e7          	jalr	-1780(ra) # 80003600 <bfree>
      ip->addrs[i] = 0;
    80003cfc:	0004a023          	sw	zero,0(s1)
    80003d00:	b7dd                	j	80003ce6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d02:	0809a583          	lw	a1,128(s3)
    80003d06:	e185                	bnez	a1,80003d26 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d08:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d0c:	854e                	mv	a0,s3
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	de4080e7          	jalr	-540(ra) # 80003af2 <iupdate>
}
    80003d16:	70a2                	ld	ra,40(sp)
    80003d18:	7402                	ld	s0,32(sp)
    80003d1a:	64e2                	ld	s1,24(sp)
    80003d1c:	6942                	ld	s2,16(sp)
    80003d1e:	69a2                	ld	s3,8(sp)
    80003d20:	6a02                	ld	s4,0(sp)
    80003d22:	6145                	addi	sp,sp,48
    80003d24:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d26:	0009a503          	lw	a0,0(s3)
    80003d2a:	fffff097          	auipc	ra,0xfffff
    80003d2e:	690080e7          	jalr	1680(ra) # 800033ba <bread>
    80003d32:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d34:	05850493          	addi	s1,a0,88
    80003d38:	45850913          	addi	s2,a0,1112
    80003d3c:	a811                	j	80003d50 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d3e:	0009a503          	lw	a0,0(s3)
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	8be080e7          	jalr	-1858(ra) # 80003600 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d4a:	0491                	addi	s1,s1,4
    80003d4c:	01248563          	beq	s1,s2,80003d56 <itrunc+0x8c>
      if(a[j])
    80003d50:	408c                	lw	a1,0(s1)
    80003d52:	dde5                	beqz	a1,80003d4a <itrunc+0x80>
    80003d54:	b7ed                	j	80003d3e <itrunc+0x74>
    brelse(bp);
    80003d56:	8552                	mv	a0,s4
    80003d58:	fffff097          	auipc	ra,0xfffff
    80003d5c:	792080e7          	jalr	1938(ra) # 800034ea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d60:	0809a583          	lw	a1,128(s3)
    80003d64:	0009a503          	lw	a0,0(s3)
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	898080e7          	jalr	-1896(ra) # 80003600 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d70:	0809a023          	sw	zero,128(s3)
    80003d74:	bf51                	j	80003d08 <itrunc+0x3e>

0000000080003d76 <iput>:
{
    80003d76:	1101                	addi	sp,sp,-32
    80003d78:	ec06                	sd	ra,24(sp)
    80003d7a:	e822                	sd	s0,16(sp)
    80003d7c:	e426                	sd	s1,8(sp)
    80003d7e:	e04a                	sd	s2,0(sp)
    80003d80:	1000                	addi	s0,sp,32
    80003d82:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d84:	0001c517          	auipc	a0,0x1c
    80003d88:	44450513          	addi	a0,a0,1092 # 800201c8 <itable>
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	e58080e7          	jalr	-424(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d94:	4498                	lw	a4,8(s1)
    80003d96:	4785                	li	a5,1
    80003d98:	02f70363          	beq	a4,a5,80003dbe <iput+0x48>
  ip->ref--;
    80003d9c:	449c                	lw	a5,8(s1)
    80003d9e:	37fd                	addiw	a5,a5,-1
    80003da0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003da2:	0001c517          	auipc	a0,0x1c
    80003da6:	42650513          	addi	a0,a0,1062 # 800201c8 <itable>
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	eee080e7          	jalr	-274(ra) # 80000c98 <release>
}
    80003db2:	60e2                	ld	ra,24(sp)
    80003db4:	6442                	ld	s0,16(sp)
    80003db6:	64a2                	ld	s1,8(sp)
    80003db8:	6902                	ld	s2,0(sp)
    80003dba:	6105                	addi	sp,sp,32
    80003dbc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dbe:	40bc                	lw	a5,64(s1)
    80003dc0:	dff1                	beqz	a5,80003d9c <iput+0x26>
    80003dc2:	04a49783          	lh	a5,74(s1)
    80003dc6:	fbf9                	bnez	a5,80003d9c <iput+0x26>
    acquiresleep(&ip->lock);
    80003dc8:	01048913          	addi	s2,s1,16
    80003dcc:	854a                	mv	a0,s2
    80003dce:	00001097          	auipc	ra,0x1
    80003dd2:	ab8080e7          	jalr	-1352(ra) # 80004886 <acquiresleep>
    release(&itable.lock);
    80003dd6:	0001c517          	auipc	a0,0x1c
    80003dda:	3f250513          	addi	a0,a0,1010 # 800201c8 <itable>
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	eba080e7          	jalr	-326(ra) # 80000c98 <release>
    itrunc(ip);
    80003de6:	8526                	mv	a0,s1
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	ee2080e7          	jalr	-286(ra) # 80003cca <itrunc>
    ip->type = 0;
    80003df0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003df4:	8526                	mv	a0,s1
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	cfc080e7          	jalr	-772(ra) # 80003af2 <iupdate>
    ip->valid = 0;
    80003dfe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e02:	854a                	mv	a0,s2
    80003e04:	00001097          	auipc	ra,0x1
    80003e08:	ad8080e7          	jalr	-1320(ra) # 800048dc <releasesleep>
    acquire(&itable.lock);
    80003e0c:	0001c517          	auipc	a0,0x1c
    80003e10:	3bc50513          	addi	a0,a0,956 # 800201c8 <itable>
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	dd0080e7          	jalr	-560(ra) # 80000be4 <acquire>
    80003e1c:	b741                	j	80003d9c <iput+0x26>

0000000080003e1e <iunlockput>:
{
    80003e1e:	1101                	addi	sp,sp,-32
    80003e20:	ec06                	sd	ra,24(sp)
    80003e22:	e822                	sd	s0,16(sp)
    80003e24:	e426                	sd	s1,8(sp)
    80003e26:	1000                	addi	s0,sp,32
    80003e28:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	e54080e7          	jalr	-428(ra) # 80003c7e <iunlock>
  iput(ip);
    80003e32:	8526                	mv	a0,s1
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	f42080e7          	jalr	-190(ra) # 80003d76 <iput>
}
    80003e3c:	60e2                	ld	ra,24(sp)
    80003e3e:	6442                	ld	s0,16(sp)
    80003e40:	64a2                	ld	s1,8(sp)
    80003e42:	6105                	addi	sp,sp,32
    80003e44:	8082                	ret

0000000080003e46 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e46:	1141                	addi	sp,sp,-16
    80003e48:	e422                	sd	s0,8(sp)
    80003e4a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e4c:	411c                	lw	a5,0(a0)
    80003e4e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e50:	415c                	lw	a5,4(a0)
    80003e52:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e54:	04451783          	lh	a5,68(a0)
    80003e58:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e5c:	04a51783          	lh	a5,74(a0)
    80003e60:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e64:	04c56783          	lwu	a5,76(a0)
    80003e68:	e99c                	sd	a5,16(a1)
}
    80003e6a:	6422                	ld	s0,8(sp)
    80003e6c:	0141                	addi	sp,sp,16
    80003e6e:	8082                	ret

0000000080003e70 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e70:	457c                	lw	a5,76(a0)
    80003e72:	0ed7e963          	bltu	a5,a3,80003f64 <readi+0xf4>
{
    80003e76:	7159                	addi	sp,sp,-112
    80003e78:	f486                	sd	ra,104(sp)
    80003e7a:	f0a2                	sd	s0,96(sp)
    80003e7c:	eca6                	sd	s1,88(sp)
    80003e7e:	e8ca                	sd	s2,80(sp)
    80003e80:	e4ce                	sd	s3,72(sp)
    80003e82:	e0d2                	sd	s4,64(sp)
    80003e84:	fc56                	sd	s5,56(sp)
    80003e86:	f85a                	sd	s6,48(sp)
    80003e88:	f45e                	sd	s7,40(sp)
    80003e8a:	f062                	sd	s8,32(sp)
    80003e8c:	ec66                	sd	s9,24(sp)
    80003e8e:	e86a                	sd	s10,16(sp)
    80003e90:	e46e                	sd	s11,8(sp)
    80003e92:	1880                	addi	s0,sp,112
    80003e94:	8baa                	mv	s7,a0
    80003e96:	8c2e                	mv	s8,a1
    80003e98:	8ab2                	mv	s5,a2
    80003e9a:	84b6                	mv	s1,a3
    80003e9c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e9e:	9f35                	addw	a4,a4,a3
    return 0;
    80003ea0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ea2:	0ad76063          	bltu	a4,a3,80003f42 <readi+0xd2>
  if(off + n > ip->size)
    80003ea6:	00e7f463          	bgeu	a5,a4,80003eae <readi+0x3e>
    n = ip->size - off;
    80003eaa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eae:	0a0b0963          	beqz	s6,80003f60 <readi+0xf0>
    80003eb2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eb8:	5cfd                	li	s9,-1
    80003eba:	a82d                	j	80003ef4 <readi+0x84>
    80003ebc:	020a1d93          	slli	s11,s4,0x20
    80003ec0:	020ddd93          	srli	s11,s11,0x20
    80003ec4:	05890613          	addi	a2,s2,88
    80003ec8:	86ee                	mv	a3,s11
    80003eca:	963a                	add	a2,a2,a4
    80003ecc:	85d6                	mv	a1,s5
    80003ece:	8562                	mv	a0,s8
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	878080e7          	jalr	-1928(ra) # 80002748 <either_copyout>
    80003ed8:	05950d63          	beq	a0,s9,80003f32 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003edc:	854a                	mv	a0,s2
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	60c080e7          	jalr	1548(ra) # 800034ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee6:	013a09bb          	addw	s3,s4,s3
    80003eea:	009a04bb          	addw	s1,s4,s1
    80003eee:	9aee                	add	s5,s5,s11
    80003ef0:	0569f763          	bgeu	s3,s6,80003f3e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ef4:	000ba903          	lw	s2,0(s7)
    80003ef8:	00a4d59b          	srliw	a1,s1,0xa
    80003efc:	855e                	mv	a0,s7
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	8b0080e7          	jalr	-1872(ra) # 800037ae <bmap>
    80003f06:	0005059b          	sext.w	a1,a0
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	4ae080e7          	jalr	1198(ra) # 800033ba <bread>
    80003f14:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f16:	3ff4f713          	andi	a4,s1,1023
    80003f1a:	40ed07bb          	subw	a5,s10,a4
    80003f1e:	413b06bb          	subw	a3,s6,s3
    80003f22:	8a3e                	mv	s4,a5
    80003f24:	2781                	sext.w	a5,a5
    80003f26:	0006861b          	sext.w	a2,a3
    80003f2a:	f8f679e3          	bgeu	a2,a5,80003ebc <readi+0x4c>
    80003f2e:	8a36                	mv	s4,a3
    80003f30:	b771                	j	80003ebc <readi+0x4c>
      brelse(bp);
    80003f32:	854a                	mv	a0,s2
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	5b6080e7          	jalr	1462(ra) # 800034ea <brelse>
      tot = -1;
    80003f3c:	59fd                	li	s3,-1
  }
  return tot;
    80003f3e:	0009851b          	sext.w	a0,s3
}
    80003f42:	70a6                	ld	ra,104(sp)
    80003f44:	7406                	ld	s0,96(sp)
    80003f46:	64e6                	ld	s1,88(sp)
    80003f48:	6946                	ld	s2,80(sp)
    80003f4a:	69a6                	ld	s3,72(sp)
    80003f4c:	6a06                	ld	s4,64(sp)
    80003f4e:	7ae2                	ld	s5,56(sp)
    80003f50:	7b42                	ld	s6,48(sp)
    80003f52:	7ba2                	ld	s7,40(sp)
    80003f54:	7c02                	ld	s8,32(sp)
    80003f56:	6ce2                	ld	s9,24(sp)
    80003f58:	6d42                	ld	s10,16(sp)
    80003f5a:	6da2                	ld	s11,8(sp)
    80003f5c:	6165                	addi	sp,sp,112
    80003f5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f60:	89da                	mv	s3,s6
    80003f62:	bff1                	j	80003f3e <readi+0xce>
    return 0;
    80003f64:	4501                	li	a0,0
}
    80003f66:	8082                	ret

0000000080003f68 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f68:	457c                	lw	a5,76(a0)
    80003f6a:	10d7e863          	bltu	a5,a3,8000407a <writei+0x112>
{
    80003f6e:	7159                	addi	sp,sp,-112
    80003f70:	f486                	sd	ra,104(sp)
    80003f72:	f0a2                	sd	s0,96(sp)
    80003f74:	eca6                	sd	s1,88(sp)
    80003f76:	e8ca                	sd	s2,80(sp)
    80003f78:	e4ce                	sd	s3,72(sp)
    80003f7a:	e0d2                	sd	s4,64(sp)
    80003f7c:	fc56                	sd	s5,56(sp)
    80003f7e:	f85a                	sd	s6,48(sp)
    80003f80:	f45e                	sd	s7,40(sp)
    80003f82:	f062                	sd	s8,32(sp)
    80003f84:	ec66                	sd	s9,24(sp)
    80003f86:	e86a                	sd	s10,16(sp)
    80003f88:	e46e                	sd	s11,8(sp)
    80003f8a:	1880                	addi	s0,sp,112
    80003f8c:	8b2a                	mv	s6,a0
    80003f8e:	8c2e                	mv	s8,a1
    80003f90:	8ab2                	mv	s5,a2
    80003f92:	8936                	mv	s2,a3
    80003f94:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f96:	00e687bb          	addw	a5,a3,a4
    80003f9a:	0ed7e263          	bltu	a5,a3,8000407e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f9e:	00043737          	lui	a4,0x43
    80003fa2:	0ef76063          	bltu	a4,a5,80004082 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa6:	0c0b8863          	beqz	s7,80004076 <writei+0x10e>
    80003faa:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fac:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fb0:	5cfd                	li	s9,-1
    80003fb2:	a091                	j	80003ff6 <writei+0x8e>
    80003fb4:	02099d93          	slli	s11,s3,0x20
    80003fb8:	020ddd93          	srli	s11,s11,0x20
    80003fbc:	05848513          	addi	a0,s1,88
    80003fc0:	86ee                	mv	a3,s11
    80003fc2:	8656                	mv	a2,s5
    80003fc4:	85e2                	mv	a1,s8
    80003fc6:	953a                	add	a0,a0,a4
    80003fc8:	ffffe097          	auipc	ra,0xffffe
    80003fcc:	7d6080e7          	jalr	2006(ra) # 8000279e <either_copyin>
    80003fd0:	07950263          	beq	a0,s9,80004034 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fd4:	8526                	mv	a0,s1
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	790080e7          	jalr	1936(ra) # 80004766 <log_write>
    brelse(bp);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	50a080e7          	jalr	1290(ra) # 800034ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fe8:	01498a3b          	addw	s4,s3,s4
    80003fec:	0129893b          	addw	s2,s3,s2
    80003ff0:	9aee                	add	s5,s5,s11
    80003ff2:	057a7663          	bgeu	s4,s7,8000403e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ff6:	000b2483          	lw	s1,0(s6)
    80003ffa:	00a9559b          	srliw	a1,s2,0xa
    80003ffe:	855a                	mv	a0,s6
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	7ae080e7          	jalr	1966(ra) # 800037ae <bmap>
    80004008:	0005059b          	sext.w	a1,a0
    8000400c:	8526                	mv	a0,s1
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	3ac080e7          	jalr	940(ra) # 800033ba <bread>
    80004016:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004018:	3ff97713          	andi	a4,s2,1023
    8000401c:	40ed07bb          	subw	a5,s10,a4
    80004020:	414b86bb          	subw	a3,s7,s4
    80004024:	89be                	mv	s3,a5
    80004026:	2781                	sext.w	a5,a5
    80004028:	0006861b          	sext.w	a2,a3
    8000402c:	f8f674e3          	bgeu	a2,a5,80003fb4 <writei+0x4c>
    80004030:	89b6                	mv	s3,a3
    80004032:	b749                	j	80003fb4 <writei+0x4c>
      brelse(bp);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	4b4080e7          	jalr	1204(ra) # 800034ea <brelse>
  }

  if(off > ip->size)
    8000403e:	04cb2783          	lw	a5,76(s6)
    80004042:	0127f463          	bgeu	a5,s2,8000404a <writei+0xe2>
    ip->size = off;
    80004046:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000404a:	855a                	mv	a0,s6
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	aa6080e7          	jalr	-1370(ra) # 80003af2 <iupdate>

  return tot;
    80004054:	000a051b          	sext.w	a0,s4
}
    80004058:	70a6                	ld	ra,104(sp)
    8000405a:	7406                	ld	s0,96(sp)
    8000405c:	64e6                	ld	s1,88(sp)
    8000405e:	6946                	ld	s2,80(sp)
    80004060:	69a6                	ld	s3,72(sp)
    80004062:	6a06                	ld	s4,64(sp)
    80004064:	7ae2                	ld	s5,56(sp)
    80004066:	7b42                	ld	s6,48(sp)
    80004068:	7ba2                	ld	s7,40(sp)
    8000406a:	7c02                	ld	s8,32(sp)
    8000406c:	6ce2                	ld	s9,24(sp)
    8000406e:	6d42                	ld	s10,16(sp)
    80004070:	6da2                	ld	s11,8(sp)
    80004072:	6165                	addi	sp,sp,112
    80004074:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004076:	8a5e                	mv	s4,s7
    80004078:	bfc9                	j	8000404a <writei+0xe2>
    return -1;
    8000407a:	557d                	li	a0,-1
}
    8000407c:	8082                	ret
    return -1;
    8000407e:	557d                	li	a0,-1
    80004080:	bfe1                	j	80004058 <writei+0xf0>
    return -1;
    80004082:	557d                	li	a0,-1
    80004084:	bfd1                	j	80004058 <writei+0xf0>

0000000080004086 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004086:	1141                	addi	sp,sp,-16
    80004088:	e406                	sd	ra,8(sp)
    8000408a:	e022                	sd	s0,0(sp)
    8000408c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000408e:	4639                	li	a2,14
    80004090:	ffffd097          	auipc	ra,0xffffd
    80004094:	d28080e7          	jalr	-728(ra) # 80000db8 <strncmp>
}
    80004098:	60a2                	ld	ra,8(sp)
    8000409a:	6402                	ld	s0,0(sp)
    8000409c:	0141                	addi	sp,sp,16
    8000409e:	8082                	ret

00000000800040a0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040a0:	7139                	addi	sp,sp,-64
    800040a2:	fc06                	sd	ra,56(sp)
    800040a4:	f822                	sd	s0,48(sp)
    800040a6:	f426                	sd	s1,40(sp)
    800040a8:	f04a                	sd	s2,32(sp)
    800040aa:	ec4e                	sd	s3,24(sp)
    800040ac:	e852                	sd	s4,16(sp)
    800040ae:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040b0:	04451703          	lh	a4,68(a0)
    800040b4:	4785                	li	a5,1
    800040b6:	00f71a63          	bne	a4,a5,800040ca <dirlookup+0x2a>
    800040ba:	892a                	mv	s2,a0
    800040bc:	89ae                	mv	s3,a1
    800040be:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c0:	457c                	lw	a5,76(a0)
    800040c2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040c4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c6:	e79d                	bnez	a5,800040f4 <dirlookup+0x54>
    800040c8:	a8a5                	j	80004140 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040ca:	00004517          	auipc	a0,0x4
    800040ce:	62650513          	addi	a0,a0,1574 # 800086f0 <syscalls+0x1b8>
    800040d2:	ffffc097          	auipc	ra,0xffffc
    800040d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040da:	00004517          	auipc	a0,0x4
    800040de:	62e50513          	addi	a0,a0,1582 # 80008708 <syscalls+0x1d0>
    800040e2:	ffffc097          	auipc	ra,0xffffc
    800040e6:	45c080e7          	jalr	1116(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ea:	24c1                	addiw	s1,s1,16
    800040ec:	04c92783          	lw	a5,76(s2)
    800040f0:	04f4f763          	bgeu	s1,a5,8000413e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f4:	4741                	li	a4,16
    800040f6:	86a6                	mv	a3,s1
    800040f8:	fc040613          	addi	a2,s0,-64
    800040fc:	4581                	li	a1,0
    800040fe:	854a                	mv	a0,s2
    80004100:	00000097          	auipc	ra,0x0
    80004104:	d70080e7          	jalr	-656(ra) # 80003e70 <readi>
    80004108:	47c1                	li	a5,16
    8000410a:	fcf518e3          	bne	a0,a5,800040da <dirlookup+0x3a>
    if(de.inum == 0)
    8000410e:	fc045783          	lhu	a5,-64(s0)
    80004112:	dfe1                	beqz	a5,800040ea <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004114:	fc240593          	addi	a1,s0,-62
    80004118:	854e                	mv	a0,s3
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	f6c080e7          	jalr	-148(ra) # 80004086 <namecmp>
    80004122:	f561                	bnez	a0,800040ea <dirlookup+0x4a>
      if(poff)
    80004124:	000a0463          	beqz	s4,8000412c <dirlookup+0x8c>
        *poff = off;
    80004128:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000412c:	fc045583          	lhu	a1,-64(s0)
    80004130:	00092503          	lw	a0,0(s2)
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	754080e7          	jalr	1876(ra) # 80003888 <iget>
    8000413c:	a011                	j	80004140 <dirlookup+0xa0>
  return 0;
    8000413e:	4501                	li	a0,0
}
    80004140:	70e2                	ld	ra,56(sp)
    80004142:	7442                	ld	s0,48(sp)
    80004144:	74a2                	ld	s1,40(sp)
    80004146:	7902                	ld	s2,32(sp)
    80004148:	69e2                	ld	s3,24(sp)
    8000414a:	6a42                	ld	s4,16(sp)
    8000414c:	6121                	addi	sp,sp,64
    8000414e:	8082                	ret

0000000080004150 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004150:	711d                	addi	sp,sp,-96
    80004152:	ec86                	sd	ra,88(sp)
    80004154:	e8a2                	sd	s0,80(sp)
    80004156:	e4a6                	sd	s1,72(sp)
    80004158:	e0ca                	sd	s2,64(sp)
    8000415a:	fc4e                	sd	s3,56(sp)
    8000415c:	f852                	sd	s4,48(sp)
    8000415e:	f456                	sd	s5,40(sp)
    80004160:	f05a                	sd	s6,32(sp)
    80004162:	ec5e                	sd	s7,24(sp)
    80004164:	e862                	sd	s8,16(sp)
    80004166:	e466                	sd	s9,8(sp)
    80004168:	1080                	addi	s0,sp,96
    8000416a:	84aa                	mv	s1,a0
    8000416c:	8b2e                	mv	s6,a1
    8000416e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004170:	00054703          	lbu	a4,0(a0)
    80004174:	02f00793          	li	a5,47
    80004178:	02f70363          	beq	a4,a5,8000419e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000417c:	ffffe097          	auipc	ra,0xffffe
    80004180:	834080e7          	jalr	-1996(ra) # 800019b0 <myproc>
    80004184:	15053503          	ld	a0,336(a0)
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	9f6080e7          	jalr	-1546(ra) # 80003b7e <idup>
    80004190:	89aa                	mv	s3,a0
  while(*path == '/')
    80004192:	02f00913          	li	s2,47
  len = path - s;
    80004196:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004198:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000419a:	4c05                	li	s8,1
    8000419c:	a865                	j	80004254 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000419e:	4585                	li	a1,1
    800041a0:	4505                	li	a0,1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	6e6080e7          	jalr	1766(ra) # 80003888 <iget>
    800041aa:	89aa                	mv	s3,a0
    800041ac:	b7dd                	j	80004192 <namex+0x42>
      iunlockput(ip);
    800041ae:	854e                	mv	a0,s3
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	c6e080e7          	jalr	-914(ra) # 80003e1e <iunlockput>
      return 0;
    800041b8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041ba:	854e                	mv	a0,s3
    800041bc:	60e6                	ld	ra,88(sp)
    800041be:	6446                	ld	s0,80(sp)
    800041c0:	64a6                	ld	s1,72(sp)
    800041c2:	6906                	ld	s2,64(sp)
    800041c4:	79e2                	ld	s3,56(sp)
    800041c6:	7a42                	ld	s4,48(sp)
    800041c8:	7aa2                	ld	s5,40(sp)
    800041ca:	7b02                	ld	s6,32(sp)
    800041cc:	6be2                	ld	s7,24(sp)
    800041ce:	6c42                	ld	s8,16(sp)
    800041d0:	6ca2                	ld	s9,8(sp)
    800041d2:	6125                	addi	sp,sp,96
    800041d4:	8082                	ret
      iunlock(ip);
    800041d6:	854e                	mv	a0,s3
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	aa6080e7          	jalr	-1370(ra) # 80003c7e <iunlock>
      return ip;
    800041e0:	bfe9                	j	800041ba <namex+0x6a>
      iunlockput(ip);
    800041e2:	854e                	mv	a0,s3
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	c3a080e7          	jalr	-966(ra) # 80003e1e <iunlockput>
      return 0;
    800041ec:	89d2                	mv	s3,s4
    800041ee:	b7f1                	j	800041ba <namex+0x6a>
  len = path - s;
    800041f0:	40b48633          	sub	a2,s1,a1
    800041f4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041f8:	094cd463          	bge	s9,s4,80004280 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041fc:	4639                	li	a2,14
    800041fe:	8556                	mv	a0,s5
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	b40080e7          	jalr	-1216(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	01279763          	bne	a5,s2,8000421a <namex+0xca>
    path++;
    80004210:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004212:	0004c783          	lbu	a5,0(s1)
    80004216:	ff278de3          	beq	a5,s2,80004210 <namex+0xc0>
    ilock(ip);
    8000421a:	854e                	mv	a0,s3
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	9a0080e7          	jalr	-1632(ra) # 80003bbc <ilock>
    if(ip->type != T_DIR){
    80004224:	04499783          	lh	a5,68(s3)
    80004228:	f98793e3          	bne	a5,s8,800041ae <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000422c:	000b0563          	beqz	s6,80004236 <namex+0xe6>
    80004230:	0004c783          	lbu	a5,0(s1)
    80004234:	d3cd                	beqz	a5,800041d6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004236:	865e                	mv	a2,s7
    80004238:	85d6                	mv	a1,s5
    8000423a:	854e                	mv	a0,s3
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	e64080e7          	jalr	-412(ra) # 800040a0 <dirlookup>
    80004244:	8a2a                	mv	s4,a0
    80004246:	dd51                	beqz	a0,800041e2 <namex+0x92>
    iunlockput(ip);
    80004248:	854e                	mv	a0,s3
    8000424a:	00000097          	auipc	ra,0x0
    8000424e:	bd4080e7          	jalr	-1068(ra) # 80003e1e <iunlockput>
    ip = next;
    80004252:	89d2                	mv	s3,s4
  while(*path == '/')
    80004254:	0004c783          	lbu	a5,0(s1)
    80004258:	05279763          	bne	a5,s2,800042a6 <namex+0x156>
    path++;
    8000425c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000425e:	0004c783          	lbu	a5,0(s1)
    80004262:	ff278de3          	beq	a5,s2,8000425c <namex+0x10c>
  if(*path == 0)
    80004266:	c79d                	beqz	a5,80004294 <namex+0x144>
    path++;
    80004268:	85a6                	mv	a1,s1
  len = path - s;
    8000426a:	8a5e                	mv	s4,s7
    8000426c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000426e:	01278963          	beq	a5,s2,80004280 <namex+0x130>
    80004272:	dfbd                	beqz	a5,800041f0 <namex+0xa0>
    path++;
    80004274:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004276:	0004c783          	lbu	a5,0(s1)
    8000427a:	ff279ce3          	bne	a5,s2,80004272 <namex+0x122>
    8000427e:	bf8d                	j	800041f0 <namex+0xa0>
    memmove(name, s, len);
    80004280:	2601                	sext.w	a2,a2
    80004282:	8556                	mv	a0,s5
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	abc080e7          	jalr	-1348(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000428c:	9a56                	add	s4,s4,s5
    8000428e:	000a0023          	sb	zero,0(s4)
    80004292:	bf9d                	j	80004208 <namex+0xb8>
  if(nameiparent){
    80004294:	f20b03e3          	beqz	s6,800041ba <namex+0x6a>
    iput(ip);
    80004298:	854e                	mv	a0,s3
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	adc080e7          	jalr	-1316(ra) # 80003d76 <iput>
    return 0;
    800042a2:	4981                	li	s3,0
    800042a4:	bf19                	j	800041ba <namex+0x6a>
  if(*path == 0)
    800042a6:	d7fd                	beqz	a5,80004294 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042a8:	0004c783          	lbu	a5,0(s1)
    800042ac:	85a6                	mv	a1,s1
    800042ae:	b7d1                	j	80004272 <namex+0x122>

00000000800042b0 <dirlink>:
{
    800042b0:	7139                	addi	sp,sp,-64
    800042b2:	fc06                	sd	ra,56(sp)
    800042b4:	f822                	sd	s0,48(sp)
    800042b6:	f426                	sd	s1,40(sp)
    800042b8:	f04a                	sd	s2,32(sp)
    800042ba:	ec4e                	sd	s3,24(sp)
    800042bc:	e852                	sd	s4,16(sp)
    800042be:	0080                	addi	s0,sp,64
    800042c0:	892a                	mv	s2,a0
    800042c2:	8a2e                	mv	s4,a1
    800042c4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042c6:	4601                	li	a2,0
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	dd8080e7          	jalr	-552(ra) # 800040a0 <dirlookup>
    800042d0:	e93d                	bnez	a0,80004346 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d2:	04c92483          	lw	s1,76(s2)
    800042d6:	c49d                	beqz	s1,80004304 <dirlink+0x54>
    800042d8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042da:	4741                	li	a4,16
    800042dc:	86a6                	mv	a3,s1
    800042de:	fc040613          	addi	a2,s0,-64
    800042e2:	4581                	li	a1,0
    800042e4:	854a                	mv	a0,s2
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	b8a080e7          	jalr	-1142(ra) # 80003e70 <readi>
    800042ee:	47c1                	li	a5,16
    800042f0:	06f51163          	bne	a0,a5,80004352 <dirlink+0xa2>
    if(de.inum == 0)
    800042f4:	fc045783          	lhu	a5,-64(s0)
    800042f8:	c791                	beqz	a5,80004304 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042fa:	24c1                	addiw	s1,s1,16
    800042fc:	04c92783          	lw	a5,76(s2)
    80004300:	fcf4ede3          	bltu	s1,a5,800042da <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004304:	4639                	li	a2,14
    80004306:	85d2                	mv	a1,s4
    80004308:	fc240513          	addi	a0,s0,-62
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	ae8080e7          	jalr	-1304(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004314:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004318:	4741                	li	a4,16
    8000431a:	86a6                	mv	a3,s1
    8000431c:	fc040613          	addi	a2,s0,-64
    80004320:	4581                	li	a1,0
    80004322:	854a                	mv	a0,s2
    80004324:	00000097          	auipc	ra,0x0
    80004328:	c44080e7          	jalr	-956(ra) # 80003f68 <writei>
    8000432c:	872a                	mv	a4,a0
    8000432e:	47c1                	li	a5,16
  return 0;
    80004330:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004332:	02f71863          	bne	a4,a5,80004362 <dirlink+0xb2>
}
    80004336:	70e2                	ld	ra,56(sp)
    80004338:	7442                	ld	s0,48(sp)
    8000433a:	74a2                	ld	s1,40(sp)
    8000433c:	7902                	ld	s2,32(sp)
    8000433e:	69e2                	ld	s3,24(sp)
    80004340:	6a42                	ld	s4,16(sp)
    80004342:	6121                	addi	sp,sp,64
    80004344:	8082                	ret
    iput(ip);
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	a30080e7          	jalr	-1488(ra) # 80003d76 <iput>
    return -1;
    8000434e:	557d                	li	a0,-1
    80004350:	b7dd                	j	80004336 <dirlink+0x86>
      panic("dirlink read");
    80004352:	00004517          	auipc	a0,0x4
    80004356:	3c650513          	addi	a0,a0,966 # 80008718 <syscalls+0x1e0>
    8000435a:	ffffc097          	auipc	ra,0xffffc
    8000435e:	1e4080e7          	jalr	484(ra) # 8000053e <panic>
    panic("dirlink");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	4be50513          	addi	a0,a0,1214 # 80008820 <syscalls+0x2e8>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>

0000000080004372 <namei>:

struct inode*
namei(char *path)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000437a:	fe040613          	addi	a2,s0,-32
    8000437e:	4581                	li	a1,0
    80004380:	00000097          	auipc	ra,0x0
    80004384:	dd0080e7          	jalr	-560(ra) # 80004150 <namex>
}
    80004388:	60e2                	ld	ra,24(sp)
    8000438a:	6442                	ld	s0,16(sp)
    8000438c:	6105                	addi	sp,sp,32
    8000438e:	8082                	ret

0000000080004390 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004390:	1141                	addi	sp,sp,-16
    80004392:	e406                	sd	ra,8(sp)
    80004394:	e022                	sd	s0,0(sp)
    80004396:	0800                	addi	s0,sp,16
    80004398:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000439a:	4585                	li	a1,1
    8000439c:	00000097          	auipc	ra,0x0
    800043a0:	db4080e7          	jalr	-588(ra) # 80004150 <namex>
}
    800043a4:	60a2                	ld	ra,8(sp)
    800043a6:	6402                	ld	s0,0(sp)
    800043a8:	0141                	addi	sp,sp,16
    800043aa:	8082                	ret

00000000800043ac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043ac:	1101                	addi	sp,sp,-32
    800043ae:	ec06                	sd	ra,24(sp)
    800043b0:	e822                	sd	s0,16(sp)
    800043b2:	e426                	sd	s1,8(sp)
    800043b4:	e04a                	sd	s2,0(sp)
    800043b6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043b8:	0001e917          	auipc	s2,0x1e
    800043bc:	8b890913          	addi	s2,s2,-1864 # 80021c70 <log>
    800043c0:	01892583          	lw	a1,24(s2)
    800043c4:	02892503          	lw	a0,40(s2)
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	ff2080e7          	jalr	-14(ra) # 800033ba <bread>
    800043d0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043d2:	02c92683          	lw	a3,44(s2)
    800043d6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043d8:	02d05763          	blez	a3,80004406 <write_head+0x5a>
    800043dc:	0001e797          	auipc	a5,0x1e
    800043e0:	8c478793          	addi	a5,a5,-1852 # 80021ca0 <log+0x30>
    800043e4:	05c50713          	addi	a4,a0,92
    800043e8:	36fd                	addiw	a3,a3,-1
    800043ea:	1682                	slli	a3,a3,0x20
    800043ec:	9281                	srli	a3,a3,0x20
    800043ee:	068a                	slli	a3,a3,0x2
    800043f0:	0001e617          	auipc	a2,0x1e
    800043f4:	8b460613          	addi	a2,a2,-1868 # 80021ca4 <log+0x34>
    800043f8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043fa:	4390                	lw	a2,0(a5)
    800043fc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043fe:	0791                	addi	a5,a5,4
    80004400:	0711                	addi	a4,a4,4
    80004402:	fed79ce3          	bne	a5,a3,800043fa <write_head+0x4e>
  }
  bwrite(buf);
    80004406:	8526                	mv	a0,s1
    80004408:	fffff097          	auipc	ra,0xfffff
    8000440c:	0a4080e7          	jalr	164(ra) # 800034ac <bwrite>
  brelse(buf);
    80004410:	8526                	mv	a0,s1
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	0d8080e7          	jalr	216(ra) # 800034ea <brelse>
}
    8000441a:	60e2                	ld	ra,24(sp)
    8000441c:	6442                	ld	s0,16(sp)
    8000441e:	64a2                	ld	s1,8(sp)
    80004420:	6902                	ld	s2,0(sp)
    80004422:	6105                	addi	sp,sp,32
    80004424:	8082                	ret

0000000080004426 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004426:	0001e797          	auipc	a5,0x1e
    8000442a:	8767a783          	lw	a5,-1930(a5) # 80021c9c <log+0x2c>
    8000442e:	0af05d63          	blez	a5,800044e8 <install_trans+0xc2>
{
    80004432:	7139                	addi	sp,sp,-64
    80004434:	fc06                	sd	ra,56(sp)
    80004436:	f822                	sd	s0,48(sp)
    80004438:	f426                	sd	s1,40(sp)
    8000443a:	f04a                	sd	s2,32(sp)
    8000443c:	ec4e                	sd	s3,24(sp)
    8000443e:	e852                	sd	s4,16(sp)
    80004440:	e456                	sd	s5,8(sp)
    80004442:	e05a                	sd	s6,0(sp)
    80004444:	0080                	addi	s0,sp,64
    80004446:	8b2a                	mv	s6,a0
    80004448:	0001ea97          	auipc	s5,0x1e
    8000444c:	858a8a93          	addi	s5,s5,-1960 # 80021ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004450:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004452:	0001e997          	auipc	s3,0x1e
    80004456:	81e98993          	addi	s3,s3,-2018 # 80021c70 <log>
    8000445a:	a035                	j	80004486 <install_trans+0x60>
      bunpin(dbuf);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	166080e7          	jalr	358(ra) # 800035c4 <bunpin>
    brelse(lbuf);
    80004466:	854a                	mv	a0,s2
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	082080e7          	jalr	130(ra) # 800034ea <brelse>
    brelse(dbuf);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	078080e7          	jalr	120(ra) # 800034ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447a:	2a05                	addiw	s4,s4,1
    8000447c:	0a91                	addi	s5,s5,4
    8000447e:	02c9a783          	lw	a5,44(s3)
    80004482:	04fa5963          	bge	s4,a5,800044d4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004486:	0189a583          	lw	a1,24(s3)
    8000448a:	014585bb          	addw	a1,a1,s4
    8000448e:	2585                	addiw	a1,a1,1
    80004490:	0289a503          	lw	a0,40(s3)
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	f26080e7          	jalr	-218(ra) # 800033ba <bread>
    8000449c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000449e:	000aa583          	lw	a1,0(s5)
    800044a2:	0289a503          	lw	a0,40(s3)
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	f14080e7          	jalr	-236(ra) # 800033ba <bread>
    800044ae:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044b0:	40000613          	li	a2,1024
    800044b4:	05890593          	addi	a1,s2,88
    800044b8:	05850513          	addi	a0,a0,88
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	884080e7          	jalr	-1916(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044c4:	8526                	mv	a0,s1
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	fe6080e7          	jalr	-26(ra) # 800034ac <bwrite>
    if(recovering == 0)
    800044ce:	f80b1ce3          	bnez	s6,80004466 <install_trans+0x40>
    800044d2:	b769                	j	8000445c <install_trans+0x36>
}
    800044d4:	70e2                	ld	ra,56(sp)
    800044d6:	7442                	ld	s0,48(sp)
    800044d8:	74a2                	ld	s1,40(sp)
    800044da:	7902                	ld	s2,32(sp)
    800044dc:	69e2                	ld	s3,24(sp)
    800044de:	6a42                	ld	s4,16(sp)
    800044e0:	6aa2                	ld	s5,8(sp)
    800044e2:	6b02                	ld	s6,0(sp)
    800044e4:	6121                	addi	sp,sp,64
    800044e6:	8082                	ret
    800044e8:	8082                	ret

00000000800044ea <initlog>:
{
    800044ea:	7179                	addi	sp,sp,-48
    800044ec:	f406                	sd	ra,40(sp)
    800044ee:	f022                	sd	s0,32(sp)
    800044f0:	ec26                	sd	s1,24(sp)
    800044f2:	e84a                	sd	s2,16(sp)
    800044f4:	e44e                	sd	s3,8(sp)
    800044f6:	1800                	addi	s0,sp,48
    800044f8:	892a                	mv	s2,a0
    800044fa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044fc:	0001d497          	auipc	s1,0x1d
    80004500:	77448493          	addi	s1,s1,1908 # 80021c70 <log>
    80004504:	00004597          	auipc	a1,0x4
    80004508:	22458593          	addi	a1,a1,548 # 80008728 <syscalls+0x1f0>
    8000450c:	8526                	mv	a0,s1
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	646080e7          	jalr	1606(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004516:	0149a583          	lw	a1,20(s3)
    8000451a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000451c:	0109a783          	lw	a5,16(s3)
    80004520:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004522:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004526:	854a                	mv	a0,s2
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	e92080e7          	jalr	-366(ra) # 800033ba <bread>
  log.lh.n = lh->n;
    80004530:	4d3c                	lw	a5,88(a0)
    80004532:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004534:	02f05563          	blez	a5,8000455e <initlog+0x74>
    80004538:	05c50713          	addi	a4,a0,92
    8000453c:	0001d697          	auipc	a3,0x1d
    80004540:	76468693          	addi	a3,a3,1892 # 80021ca0 <log+0x30>
    80004544:	37fd                	addiw	a5,a5,-1
    80004546:	1782                	slli	a5,a5,0x20
    80004548:	9381                	srli	a5,a5,0x20
    8000454a:	078a                	slli	a5,a5,0x2
    8000454c:	06050613          	addi	a2,a0,96
    80004550:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004552:	4310                	lw	a2,0(a4)
    80004554:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004556:	0711                	addi	a4,a4,4
    80004558:	0691                	addi	a3,a3,4
    8000455a:	fef71ce3          	bne	a4,a5,80004552 <initlog+0x68>
  brelse(buf);
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	f8c080e7          	jalr	-116(ra) # 800034ea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004566:	4505                	li	a0,1
    80004568:	00000097          	auipc	ra,0x0
    8000456c:	ebe080e7          	jalr	-322(ra) # 80004426 <install_trans>
  log.lh.n = 0;
    80004570:	0001d797          	auipc	a5,0x1d
    80004574:	7207a623          	sw	zero,1836(a5) # 80021c9c <log+0x2c>
  write_head(); // clear the log
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	e34080e7          	jalr	-460(ra) # 800043ac <write_head>
}
    80004580:	70a2                	ld	ra,40(sp)
    80004582:	7402                	ld	s0,32(sp)
    80004584:	64e2                	ld	s1,24(sp)
    80004586:	6942                	ld	s2,16(sp)
    80004588:	69a2                	ld	s3,8(sp)
    8000458a:	6145                	addi	sp,sp,48
    8000458c:	8082                	ret

000000008000458e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	e04a                	sd	s2,0(sp)
    80004598:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000459a:	0001d517          	auipc	a0,0x1d
    8000459e:	6d650513          	addi	a0,a0,1750 # 80021c70 <log>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	642080e7          	jalr	1602(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045aa:	0001d497          	auipc	s1,0x1d
    800045ae:	6c648493          	addi	s1,s1,1734 # 80021c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045b2:	4979                	li	s2,30
    800045b4:	a039                	j	800045c2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045b6:	85a6                	mv	a1,s1
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffe097          	auipc	ra,0xffffe
    800045be:	c72080e7          	jalr	-910(ra) # 8000222c <sleep>
    if(log.committing){
    800045c2:	50dc                	lw	a5,36(s1)
    800045c4:	fbed                	bnez	a5,800045b6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045c6:	509c                	lw	a5,32(s1)
    800045c8:	0017871b          	addiw	a4,a5,1
    800045cc:	0007069b          	sext.w	a3,a4
    800045d0:	0027179b          	slliw	a5,a4,0x2
    800045d4:	9fb9                	addw	a5,a5,a4
    800045d6:	0017979b          	slliw	a5,a5,0x1
    800045da:	54d8                	lw	a4,44(s1)
    800045dc:	9fb9                	addw	a5,a5,a4
    800045de:	00f95963          	bge	s2,a5,800045f0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045e2:	85a6                	mv	a1,s1
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffe097          	auipc	ra,0xffffe
    800045ea:	c46080e7          	jalr	-954(ra) # 8000222c <sleep>
    800045ee:	bfd1                	j	800045c2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045f0:	0001d517          	auipc	a0,0x1d
    800045f4:	68050513          	addi	a0,a0,1664 # 80021c70 <log>
    800045f8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	69e080e7          	jalr	1694(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004602:	60e2                	ld	ra,24(sp)
    80004604:	6442                	ld	s0,16(sp)
    80004606:	64a2                	ld	s1,8(sp)
    80004608:	6902                	ld	s2,0(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret

000000008000460e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000460e:	7139                	addi	sp,sp,-64
    80004610:	fc06                	sd	ra,56(sp)
    80004612:	f822                	sd	s0,48(sp)
    80004614:	f426                	sd	s1,40(sp)
    80004616:	f04a                	sd	s2,32(sp)
    80004618:	ec4e                	sd	s3,24(sp)
    8000461a:	e852                	sd	s4,16(sp)
    8000461c:	e456                	sd	s5,8(sp)
    8000461e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004620:	0001d497          	auipc	s1,0x1d
    80004624:	65048493          	addi	s1,s1,1616 # 80021c70 <log>
    80004628:	8526                	mv	a0,s1
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	5ba080e7          	jalr	1466(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004632:	509c                	lw	a5,32(s1)
    80004634:	37fd                	addiw	a5,a5,-1
    80004636:	0007891b          	sext.w	s2,a5
    8000463a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000463c:	50dc                	lw	a5,36(s1)
    8000463e:	efb9                	bnez	a5,8000469c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004640:	06091663          	bnez	s2,800046ac <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004644:	0001d497          	auipc	s1,0x1d
    80004648:	62c48493          	addi	s1,s1,1580 # 80021c70 <log>
    8000464c:	4785                	li	a5,1
    8000464e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004650:	8526                	mv	a0,s1
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000465a:	54dc                	lw	a5,44(s1)
    8000465c:	06f04763          	bgtz	a5,800046ca <end_op+0xbc>
    acquire(&log.lock);
    80004660:	0001d497          	auipc	s1,0x1d
    80004664:	61048493          	addi	s1,s1,1552 # 80021c70 <log>
    80004668:	8526                	mv	a0,s1
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004672:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004676:	8526                	mv	a0,s1
    80004678:	ffffe097          	auipc	ra,0xffffe
    8000467c:	e8c080e7          	jalr	-372(ra) # 80002504 <wakeup>
    release(&log.lock);
    80004680:	8526                	mv	a0,s1
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
}
    8000468a:	70e2                	ld	ra,56(sp)
    8000468c:	7442                	ld	s0,48(sp)
    8000468e:	74a2                	ld	s1,40(sp)
    80004690:	7902                	ld	s2,32(sp)
    80004692:	69e2                	ld	s3,24(sp)
    80004694:	6a42                	ld	s4,16(sp)
    80004696:	6aa2                	ld	s5,8(sp)
    80004698:	6121                	addi	sp,sp,64
    8000469a:	8082                	ret
    panic("log.committing");
    8000469c:	00004517          	auipc	a0,0x4
    800046a0:	09450513          	addi	a0,a0,148 # 80008730 <syscalls+0x1f8>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	e9a080e7          	jalr	-358(ra) # 8000053e <panic>
    wakeup(&log);
    800046ac:	0001d497          	auipc	s1,0x1d
    800046b0:	5c448493          	addi	s1,s1,1476 # 80021c70 <log>
    800046b4:	8526                	mv	a0,s1
    800046b6:	ffffe097          	auipc	ra,0xffffe
    800046ba:	e4e080e7          	jalr	-434(ra) # 80002504 <wakeup>
  release(&log.lock);
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
  if(do_commit){
    800046c8:	b7c9                	j	8000468a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ca:	0001da97          	auipc	s5,0x1d
    800046ce:	5d6a8a93          	addi	s5,s5,1494 # 80021ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046d2:	0001da17          	auipc	s4,0x1d
    800046d6:	59ea0a13          	addi	s4,s4,1438 # 80021c70 <log>
    800046da:	018a2583          	lw	a1,24(s4)
    800046de:	012585bb          	addw	a1,a1,s2
    800046e2:	2585                	addiw	a1,a1,1
    800046e4:	028a2503          	lw	a0,40(s4)
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	cd2080e7          	jalr	-814(ra) # 800033ba <bread>
    800046f0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046f2:	000aa583          	lw	a1,0(s5)
    800046f6:	028a2503          	lw	a0,40(s4)
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	cc0080e7          	jalr	-832(ra) # 800033ba <bread>
    80004702:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004704:	40000613          	li	a2,1024
    80004708:	05850593          	addi	a1,a0,88
    8000470c:	05848513          	addi	a0,s1,88
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	630080e7          	jalr	1584(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004718:	8526                	mv	a0,s1
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	d92080e7          	jalr	-622(ra) # 800034ac <bwrite>
    brelse(from);
    80004722:	854e                	mv	a0,s3
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	dc6080e7          	jalr	-570(ra) # 800034ea <brelse>
    brelse(to);
    8000472c:	8526                	mv	a0,s1
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	dbc080e7          	jalr	-580(ra) # 800034ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004736:	2905                	addiw	s2,s2,1
    80004738:	0a91                	addi	s5,s5,4
    8000473a:	02ca2783          	lw	a5,44(s4)
    8000473e:	f8f94ee3          	blt	s2,a5,800046da <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004742:	00000097          	auipc	ra,0x0
    80004746:	c6a080e7          	jalr	-918(ra) # 800043ac <write_head>
    install_trans(0); // Now install writes to home locations
    8000474a:	4501                	li	a0,0
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	cda080e7          	jalr	-806(ra) # 80004426 <install_trans>
    log.lh.n = 0;
    80004754:	0001d797          	auipc	a5,0x1d
    80004758:	5407a423          	sw	zero,1352(a5) # 80021c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	c50080e7          	jalr	-944(ra) # 800043ac <write_head>
    80004764:	bdf5                	j	80004660 <end_op+0x52>

0000000080004766 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004766:	1101                	addi	sp,sp,-32
    80004768:	ec06                	sd	ra,24(sp)
    8000476a:	e822                	sd	s0,16(sp)
    8000476c:	e426                	sd	s1,8(sp)
    8000476e:	e04a                	sd	s2,0(sp)
    80004770:	1000                	addi	s0,sp,32
    80004772:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004774:	0001d917          	auipc	s2,0x1d
    80004778:	4fc90913          	addi	s2,s2,1276 # 80021c70 <log>
    8000477c:	854a                	mv	a0,s2
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	466080e7          	jalr	1126(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004786:	02c92603          	lw	a2,44(s2)
    8000478a:	47f5                	li	a5,29
    8000478c:	06c7c563          	blt	a5,a2,800047f6 <log_write+0x90>
    80004790:	0001d797          	auipc	a5,0x1d
    80004794:	4fc7a783          	lw	a5,1276(a5) # 80021c8c <log+0x1c>
    80004798:	37fd                	addiw	a5,a5,-1
    8000479a:	04f65e63          	bge	a2,a5,800047f6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000479e:	0001d797          	auipc	a5,0x1d
    800047a2:	4f27a783          	lw	a5,1266(a5) # 80021c90 <log+0x20>
    800047a6:	06f05063          	blez	a5,80004806 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047aa:	4781                	li	a5,0
    800047ac:	06c05563          	blez	a2,80004816 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047b0:	44cc                	lw	a1,12(s1)
    800047b2:	0001d717          	auipc	a4,0x1d
    800047b6:	4ee70713          	addi	a4,a4,1262 # 80021ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047ba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047bc:	4314                	lw	a3,0(a4)
    800047be:	04b68c63          	beq	a3,a1,80004816 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047c2:	2785                	addiw	a5,a5,1
    800047c4:	0711                	addi	a4,a4,4
    800047c6:	fef61be3          	bne	a2,a5,800047bc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047ca:	0621                	addi	a2,a2,8
    800047cc:	060a                	slli	a2,a2,0x2
    800047ce:	0001d797          	auipc	a5,0x1d
    800047d2:	4a278793          	addi	a5,a5,1186 # 80021c70 <log>
    800047d6:	963e                	add	a2,a2,a5
    800047d8:	44dc                	lw	a5,12(s1)
    800047da:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047dc:	8526                	mv	a0,s1
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	daa080e7          	jalr	-598(ra) # 80003588 <bpin>
    log.lh.n++;
    800047e6:	0001d717          	auipc	a4,0x1d
    800047ea:	48a70713          	addi	a4,a4,1162 # 80021c70 <log>
    800047ee:	575c                	lw	a5,44(a4)
    800047f0:	2785                	addiw	a5,a5,1
    800047f2:	d75c                	sw	a5,44(a4)
    800047f4:	a835                	j	80004830 <log_write+0xca>
    panic("too big a transaction");
    800047f6:	00004517          	auipc	a0,0x4
    800047fa:	f4a50513          	addi	a0,a0,-182 # 80008740 <syscalls+0x208>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004806:	00004517          	auipc	a0,0x4
    8000480a:	f5250513          	addi	a0,a0,-174 # 80008758 <syscalls+0x220>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004816:	00878713          	addi	a4,a5,8
    8000481a:	00271693          	slli	a3,a4,0x2
    8000481e:	0001d717          	auipc	a4,0x1d
    80004822:	45270713          	addi	a4,a4,1106 # 80021c70 <log>
    80004826:	9736                	add	a4,a4,a3
    80004828:	44d4                	lw	a3,12(s1)
    8000482a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000482c:	faf608e3          	beq	a2,a5,800047dc <log_write+0x76>
  }
  release(&log.lock);
    80004830:	0001d517          	auipc	a0,0x1d
    80004834:	44050513          	addi	a0,a0,1088 # 80021c70 <log>
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	460080e7          	jalr	1120(ra) # 80000c98 <release>
}
    80004840:	60e2                	ld	ra,24(sp)
    80004842:	6442                	ld	s0,16(sp)
    80004844:	64a2                	ld	s1,8(sp)
    80004846:	6902                	ld	s2,0(sp)
    80004848:	6105                	addi	sp,sp,32
    8000484a:	8082                	ret

000000008000484c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000484c:	1101                	addi	sp,sp,-32
    8000484e:	ec06                	sd	ra,24(sp)
    80004850:	e822                	sd	s0,16(sp)
    80004852:	e426                	sd	s1,8(sp)
    80004854:	e04a                	sd	s2,0(sp)
    80004856:	1000                	addi	s0,sp,32
    80004858:	84aa                	mv	s1,a0
    8000485a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000485c:	00004597          	auipc	a1,0x4
    80004860:	f1c58593          	addi	a1,a1,-228 # 80008778 <syscalls+0x240>
    80004864:	0521                	addi	a0,a0,8
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	2ee080e7          	jalr	750(ra) # 80000b54 <initlock>
  lk->name = name;
    8000486e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004872:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004876:	0204a423          	sw	zero,40(s1)
}
    8000487a:	60e2                	ld	ra,24(sp)
    8000487c:	6442                	ld	s0,16(sp)
    8000487e:	64a2                	ld	s1,8(sp)
    80004880:	6902                	ld	s2,0(sp)
    80004882:	6105                	addi	sp,sp,32
    80004884:	8082                	ret

0000000080004886 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004886:	1101                	addi	sp,sp,-32
    80004888:	ec06                	sd	ra,24(sp)
    8000488a:	e822                	sd	s0,16(sp)
    8000488c:	e426                	sd	s1,8(sp)
    8000488e:	e04a                	sd	s2,0(sp)
    80004890:	1000                	addi	s0,sp,32
    80004892:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004894:	00850913          	addi	s2,a0,8
    80004898:	854a                	mv	a0,s2
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	34a080e7          	jalr	842(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048a2:	409c                	lw	a5,0(s1)
    800048a4:	cb89                	beqz	a5,800048b6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048a6:	85ca                	mv	a1,s2
    800048a8:	8526                	mv	a0,s1
    800048aa:	ffffe097          	auipc	ra,0xffffe
    800048ae:	982080e7          	jalr	-1662(ra) # 8000222c <sleep>
  while (lk->locked) {
    800048b2:	409c                	lw	a5,0(s1)
    800048b4:	fbed                	bnez	a5,800048a6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048b6:	4785                	li	a5,1
    800048b8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048ba:	ffffd097          	auipc	ra,0xffffd
    800048be:	0f6080e7          	jalr	246(ra) # 800019b0 <myproc>
    800048c2:	591c                	lw	a5,48(a0)
    800048c4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048c6:	854a                	mv	a0,s2
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	3d0080e7          	jalr	976(ra) # 80000c98 <release>
}
    800048d0:	60e2                	ld	ra,24(sp)
    800048d2:	6442                	ld	s0,16(sp)
    800048d4:	64a2                	ld	s1,8(sp)
    800048d6:	6902                	ld	s2,0(sp)
    800048d8:	6105                	addi	sp,sp,32
    800048da:	8082                	ret

00000000800048dc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048dc:	1101                	addi	sp,sp,-32
    800048de:	ec06                	sd	ra,24(sp)
    800048e0:	e822                	sd	s0,16(sp)
    800048e2:	e426                	sd	s1,8(sp)
    800048e4:	e04a                	sd	s2,0(sp)
    800048e6:	1000                	addi	s0,sp,32
    800048e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ea:	00850913          	addi	s2,a0,8
    800048ee:	854a                	mv	a0,s2
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	2f4080e7          	jalr	756(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048fc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004900:	8526                	mv	a0,s1
    80004902:	ffffe097          	auipc	ra,0xffffe
    80004906:	c02080e7          	jalr	-1022(ra) # 80002504 <wakeup>
  release(&lk->lk);
    8000490a:	854a                	mv	a0,s2
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	38c080e7          	jalr	908(ra) # 80000c98 <release>
}
    80004914:	60e2                	ld	ra,24(sp)
    80004916:	6442                	ld	s0,16(sp)
    80004918:	64a2                	ld	s1,8(sp)
    8000491a:	6902                	ld	s2,0(sp)
    8000491c:	6105                	addi	sp,sp,32
    8000491e:	8082                	ret

0000000080004920 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004920:	7179                	addi	sp,sp,-48
    80004922:	f406                	sd	ra,40(sp)
    80004924:	f022                	sd	s0,32(sp)
    80004926:	ec26                	sd	s1,24(sp)
    80004928:	e84a                	sd	s2,16(sp)
    8000492a:	e44e                	sd	s3,8(sp)
    8000492c:	1800                	addi	s0,sp,48
    8000492e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004930:	00850913          	addi	s2,a0,8
    80004934:	854a                	mv	a0,s2
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	2ae080e7          	jalr	686(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000493e:	409c                	lw	a5,0(s1)
    80004940:	ef99                	bnez	a5,8000495e <holdingsleep+0x3e>
    80004942:	4481                	li	s1,0
  release(&lk->lk);
    80004944:	854a                	mv	a0,s2
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	352080e7          	jalr	850(ra) # 80000c98 <release>
  return r;
}
    8000494e:	8526                	mv	a0,s1
    80004950:	70a2                	ld	ra,40(sp)
    80004952:	7402                	ld	s0,32(sp)
    80004954:	64e2                	ld	s1,24(sp)
    80004956:	6942                	ld	s2,16(sp)
    80004958:	69a2                	ld	s3,8(sp)
    8000495a:	6145                	addi	sp,sp,48
    8000495c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000495e:	0284a983          	lw	s3,40(s1)
    80004962:	ffffd097          	auipc	ra,0xffffd
    80004966:	04e080e7          	jalr	78(ra) # 800019b0 <myproc>
    8000496a:	5904                	lw	s1,48(a0)
    8000496c:	413484b3          	sub	s1,s1,s3
    80004970:	0014b493          	seqz	s1,s1
    80004974:	bfc1                	j	80004944 <holdingsleep+0x24>

0000000080004976 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004976:	1141                	addi	sp,sp,-16
    80004978:	e406                	sd	ra,8(sp)
    8000497a:	e022                	sd	s0,0(sp)
    8000497c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000497e:	00004597          	auipc	a1,0x4
    80004982:	e0a58593          	addi	a1,a1,-502 # 80008788 <syscalls+0x250>
    80004986:	0001d517          	auipc	a0,0x1d
    8000498a:	43250513          	addi	a0,a0,1074 # 80021db8 <ftable>
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	1c6080e7          	jalr	454(ra) # 80000b54 <initlock>
}
    80004996:	60a2                	ld	ra,8(sp)
    80004998:	6402                	ld	s0,0(sp)
    8000499a:	0141                	addi	sp,sp,16
    8000499c:	8082                	ret

000000008000499e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000499e:	1101                	addi	sp,sp,-32
    800049a0:	ec06                	sd	ra,24(sp)
    800049a2:	e822                	sd	s0,16(sp)
    800049a4:	e426                	sd	s1,8(sp)
    800049a6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049a8:	0001d517          	auipc	a0,0x1d
    800049ac:	41050513          	addi	a0,a0,1040 # 80021db8 <ftable>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	234080e7          	jalr	564(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049b8:	0001d497          	auipc	s1,0x1d
    800049bc:	41848493          	addi	s1,s1,1048 # 80021dd0 <ftable+0x18>
    800049c0:	0001e717          	auipc	a4,0x1e
    800049c4:	3b070713          	addi	a4,a4,944 # 80022d70 <ftable+0xfb8>
    if(f->ref == 0){
    800049c8:	40dc                	lw	a5,4(s1)
    800049ca:	cf99                	beqz	a5,800049e8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049cc:	02848493          	addi	s1,s1,40
    800049d0:	fee49ce3          	bne	s1,a4,800049c8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049d4:	0001d517          	auipc	a0,0x1d
    800049d8:	3e450513          	addi	a0,a0,996 # 80021db8 <ftable>
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	2bc080e7          	jalr	700(ra) # 80000c98 <release>
  return 0;
    800049e4:	4481                	li	s1,0
    800049e6:	a819                	j	800049fc <filealloc+0x5e>
      f->ref = 1;
    800049e8:	4785                	li	a5,1
    800049ea:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049ec:	0001d517          	auipc	a0,0x1d
    800049f0:	3cc50513          	addi	a0,a0,972 # 80021db8 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	2a4080e7          	jalr	676(ra) # 80000c98 <release>
}
    800049fc:	8526                	mv	a0,s1
    800049fe:	60e2                	ld	ra,24(sp)
    80004a00:	6442                	ld	s0,16(sp)
    80004a02:	64a2                	ld	s1,8(sp)
    80004a04:	6105                	addi	sp,sp,32
    80004a06:	8082                	ret

0000000080004a08 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a08:	1101                	addi	sp,sp,-32
    80004a0a:	ec06                	sd	ra,24(sp)
    80004a0c:	e822                	sd	s0,16(sp)
    80004a0e:	e426                	sd	s1,8(sp)
    80004a10:	1000                	addi	s0,sp,32
    80004a12:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a14:	0001d517          	auipc	a0,0x1d
    80004a18:	3a450513          	addi	a0,a0,932 # 80021db8 <ftable>
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	1c8080e7          	jalr	456(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a24:	40dc                	lw	a5,4(s1)
    80004a26:	02f05263          	blez	a5,80004a4a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a2a:	2785                	addiw	a5,a5,1
    80004a2c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a2e:	0001d517          	auipc	a0,0x1d
    80004a32:	38a50513          	addi	a0,a0,906 # 80021db8 <ftable>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	262080e7          	jalr	610(ra) # 80000c98 <release>
  return f;
}
    80004a3e:	8526                	mv	a0,s1
    80004a40:	60e2                	ld	ra,24(sp)
    80004a42:	6442                	ld	s0,16(sp)
    80004a44:	64a2                	ld	s1,8(sp)
    80004a46:	6105                	addi	sp,sp,32
    80004a48:	8082                	ret
    panic("filedup");
    80004a4a:	00004517          	auipc	a0,0x4
    80004a4e:	d4650513          	addi	a0,a0,-698 # 80008790 <syscalls+0x258>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>

0000000080004a5a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a5a:	7139                	addi	sp,sp,-64
    80004a5c:	fc06                	sd	ra,56(sp)
    80004a5e:	f822                	sd	s0,48(sp)
    80004a60:	f426                	sd	s1,40(sp)
    80004a62:	f04a                	sd	s2,32(sp)
    80004a64:	ec4e                	sd	s3,24(sp)
    80004a66:	e852                	sd	s4,16(sp)
    80004a68:	e456                	sd	s5,8(sp)
    80004a6a:	0080                	addi	s0,sp,64
    80004a6c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a6e:	0001d517          	auipc	a0,0x1d
    80004a72:	34a50513          	addi	a0,a0,842 # 80021db8 <ftable>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	16e080e7          	jalr	366(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a7e:	40dc                	lw	a5,4(s1)
    80004a80:	06f05163          	blez	a5,80004ae2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a84:	37fd                	addiw	a5,a5,-1
    80004a86:	0007871b          	sext.w	a4,a5
    80004a8a:	c0dc                	sw	a5,4(s1)
    80004a8c:	06e04363          	bgtz	a4,80004af2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a90:	0004a903          	lw	s2,0(s1)
    80004a94:	0094ca83          	lbu	s5,9(s1)
    80004a98:	0104ba03          	ld	s4,16(s1)
    80004a9c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004aa0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004aa4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004aa8:	0001d517          	auipc	a0,0x1d
    80004aac:	31050513          	addi	a0,a0,784 # 80021db8 <ftable>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1e8080e7          	jalr	488(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ab8:	4785                	li	a5,1
    80004aba:	04f90d63          	beq	s2,a5,80004b14 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004abe:	3979                	addiw	s2,s2,-2
    80004ac0:	4785                	li	a5,1
    80004ac2:	0527e063          	bltu	a5,s2,80004b02 <fileclose+0xa8>
    begin_op();
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	ac8080e7          	jalr	-1336(ra) # 8000458e <begin_op>
    iput(ff.ip);
    80004ace:	854e                	mv	a0,s3
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	2a6080e7          	jalr	678(ra) # 80003d76 <iput>
    end_op();
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	b36080e7          	jalr	-1226(ra) # 8000460e <end_op>
    80004ae0:	a00d                	j	80004b02 <fileclose+0xa8>
    panic("fileclose");
    80004ae2:	00004517          	auipc	a0,0x4
    80004ae6:	cb650513          	addi	a0,a0,-842 # 80008798 <syscalls+0x260>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	a54080e7          	jalr	-1452(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004af2:	0001d517          	auipc	a0,0x1d
    80004af6:	2c650513          	addi	a0,a0,710 # 80021db8 <ftable>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	19e080e7          	jalr	414(ra) # 80000c98 <release>
  }
}
    80004b02:	70e2                	ld	ra,56(sp)
    80004b04:	7442                	ld	s0,48(sp)
    80004b06:	74a2                	ld	s1,40(sp)
    80004b08:	7902                	ld	s2,32(sp)
    80004b0a:	69e2                	ld	s3,24(sp)
    80004b0c:	6a42                	ld	s4,16(sp)
    80004b0e:	6aa2                	ld	s5,8(sp)
    80004b10:	6121                	addi	sp,sp,64
    80004b12:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b14:	85d6                	mv	a1,s5
    80004b16:	8552                	mv	a0,s4
    80004b18:	00000097          	auipc	ra,0x0
    80004b1c:	34c080e7          	jalr	844(ra) # 80004e64 <pipeclose>
    80004b20:	b7cd                	j	80004b02 <fileclose+0xa8>

0000000080004b22 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b22:	715d                	addi	sp,sp,-80
    80004b24:	e486                	sd	ra,72(sp)
    80004b26:	e0a2                	sd	s0,64(sp)
    80004b28:	fc26                	sd	s1,56(sp)
    80004b2a:	f84a                	sd	s2,48(sp)
    80004b2c:	f44e                	sd	s3,40(sp)
    80004b2e:	0880                	addi	s0,sp,80
    80004b30:	84aa                	mv	s1,a0
    80004b32:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	e7c080e7          	jalr	-388(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b3c:	409c                	lw	a5,0(s1)
    80004b3e:	37f9                	addiw	a5,a5,-2
    80004b40:	4705                	li	a4,1
    80004b42:	04f76763          	bltu	a4,a5,80004b90 <filestat+0x6e>
    80004b46:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b48:	6c88                	ld	a0,24(s1)
    80004b4a:	fffff097          	auipc	ra,0xfffff
    80004b4e:	072080e7          	jalr	114(ra) # 80003bbc <ilock>
    stati(f->ip, &st);
    80004b52:	fb840593          	addi	a1,s0,-72
    80004b56:	6c88                	ld	a0,24(s1)
    80004b58:	fffff097          	auipc	ra,0xfffff
    80004b5c:	2ee080e7          	jalr	750(ra) # 80003e46 <stati>
    iunlock(f->ip);
    80004b60:	6c88                	ld	a0,24(s1)
    80004b62:	fffff097          	auipc	ra,0xfffff
    80004b66:	11c080e7          	jalr	284(ra) # 80003c7e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b6a:	46e1                	li	a3,24
    80004b6c:	fb840613          	addi	a2,s0,-72
    80004b70:	85ce                	mv	a1,s3
    80004b72:	05093503          	ld	a0,80(s2)
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	afc080e7          	jalr	-1284(ra) # 80001672 <copyout>
    80004b7e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b82:	60a6                	ld	ra,72(sp)
    80004b84:	6406                	ld	s0,64(sp)
    80004b86:	74e2                	ld	s1,56(sp)
    80004b88:	7942                	ld	s2,48(sp)
    80004b8a:	79a2                	ld	s3,40(sp)
    80004b8c:	6161                	addi	sp,sp,80
    80004b8e:	8082                	ret
  return -1;
    80004b90:	557d                	li	a0,-1
    80004b92:	bfc5                	j	80004b82 <filestat+0x60>

0000000080004b94 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b94:	7179                	addi	sp,sp,-48
    80004b96:	f406                	sd	ra,40(sp)
    80004b98:	f022                	sd	s0,32(sp)
    80004b9a:	ec26                	sd	s1,24(sp)
    80004b9c:	e84a                	sd	s2,16(sp)
    80004b9e:	e44e                	sd	s3,8(sp)
    80004ba0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ba2:	00854783          	lbu	a5,8(a0)
    80004ba6:	c3d5                	beqz	a5,80004c4a <fileread+0xb6>
    80004ba8:	84aa                	mv	s1,a0
    80004baa:	89ae                	mv	s3,a1
    80004bac:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bae:	411c                	lw	a5,0(a0)
    80004bb0:	4705                	li	a4,1
    80004bb2:	04e78963          	beq	a5,a4,80004c04 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bb6:	470d                	li	a4,3
    80004bb8:	04e78d63          	beq	a5,a4,80004c12 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bbc:	4709                	li	a4,2
    80004bbe:	06e79e63          	bne	a5,a4,80004c3a <fileread+0xa6>
    ilock(f->ip);
    80004bc2:	6d08                	ld	a0,24(a0)
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	ff8080e7          	jalr	-8(ra) # 80003bbc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bcc:	874a                	mv	a4,s2
    80004bce:	5094                	lw	a3,32(s1)
    80004bd0:	864e                	mv	a2,s3
    80004bd2:	4585                	li	a1,1
    80004bd4:	6c88                	ld	a0,24(s1)
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	29a080e7          	jalr	666(ra) # 80003e70 <readi>
    80004bde:	892a                	mv	s2,a0
    80004be0:	00a05563          	blez	a0,80004bea <fileread+0x56>
      f->off += r;
    80004be4:	509c                	lw	a5,32(s1)
    80004be6:	9fa9                	addw	a5,a5,a0
    80004be8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bea:	6c88                	ld	a0,24(s1)
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	092080e7          	jalr	146(ra) # 80003c7e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bf4:	854a                	mv	a0,s2
    80004bf6:	70a2                	ld	ra,40(sp)
    80004bf8:	7402                	ld	s0,32(sp)
    80004bfa:	64e2                	ld	s1,24(sp)
    80004bfc:	6942                	ld	s2,16(sp)
    80004bfe:	69a2                	ld	s3,8(sp)
    80004c00:	6145                	addi	sp,sp,48
    80004c02:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c04:	6908                	ld	a0,16(a0)
    80004c06:	00000097          	auipc	ra,0x0
    80004c0a:	3c8080e7          	jalr	968(ra) # 80004fce <piperead>
    80004c0e:	892a                	mv	s2,a0
    80004c10:	b7d5                	j	80004bf4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c12:	02451783          	lh	a5,36(a0)
    80004c16:	03079693          	slli	a3,a5,0x30
    80004c1a:	92c1                	srli	a3,a3,0x30
    80004c1c:	4725                	li	a4,9
    80004c1e:	02d76863          	bltu	a4,a3,80004c4e <fileread+0xba>
    80004c22:	0792                	slli	a5,a5,0x4
    80004c24:	0001d717          	auipc	a4,0x1d
    80004c28:	0f470713          	addi	a4,a4,244 # 80021d18 <devsw>
    80004c2c:	97ba                	add	a5,a5,a4
    80004c2e:	639c                	ld	a5,0(a5)
    80004c30:	c38d                	beqz	a5,80004c52 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c32:	4505                	li	a0,1
    80004c34:	9782                	jalr	a5
    80004c36:	892a                	mv	s2,a0
    80004c38:	bf75                	j	80004bf4 <fileread+0x60>
    panic("fileread");
    80004c3a:	00004517          	auipc	a0,0x4
    80004c3e:	b6e50513          	addi	a0,a0,-1170 # 800087a8 <syscalls+0x270>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	8fc080e7          	jalr	-1796(ra) # 8000053e <panic>
    return -1;
    80004c4a:	597d                	li	s2,-1
    80004c4c:	b765                	j	80004bf4 <fileread+0x60>
      return -1;
    80004c4e:	597d                	li	s2,-1
    80004c50:	b755                	j	80004bf4 <fileread+0x60>
    80004c52:	597d                	li	s2,-1
    80004c54:	b745                	j	80004bf4 <fileread+0x60>

0000000080004c56 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c56:	715d                	addi	sp,sp,-80
    80004c58:	e486                	sd	ra,72(sp)
    80004c5a:	e0a2                	sd	s0,64(sp)
    80004c5c:	fc26                	sd	s1,56(sp)
    80004c5e:	f84a                	sd	s2,48(sp)
    80004c60:	f44e                	sd	s3,40(sp)
    80004c62:	f052                	sd	s4,32(sp)
    80004c64:	ec56                	sd	s5,24(sp)
    80004c66:	e85a                	sd	s6,16(sp)
    80004c68:	e45e                	sd	s7,8(sp)
    80004c6a:	e062                	sd	s8,0(sp)
    80004c6c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c6e:	00954783          	lbu	a5,9(a0)
    80004c72:	10078663          	beqz	a5,80004d7e <filewrite+0x128>
    80004c76:	892a                	mv	s2,a0
    80004c78:	8aae                	mv	s5,a1
    80004c7a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c7c:	411c                	lw	a5,0(a0)
    80004c7e:	4705                	li	a4,1
    80004c80:	02e78263          	beq	a5,a4,80004ca4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c84:	470d                	li	a4,3
    80004c86:	02e78663          	beq	a5,a4,80004cb2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c8a:	4709                	li	a4,2
    80004c8c:	0ee79163          	bne	a5,a4,80004d6e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c90:	0ac05d63          	blez	a2,80004d4a <filewrite+0xf4>
    int i = 0;
    80004c94:	4981                	li	s3,0
    80004c96:	6b05                	lui	s6,0x1
    80004c98:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c9c:	6b85                	lui	s7,0x1
    80004c9e:	c00b8b9b          	addiw	s7,s7,-1024
    80004ca2:	a861                	j	80004d3a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ca4:	6908                	ld	a0,16(a0)
    80004ca6:	00000097          	auipc	ra,0x0
    80004caa:	22e080e7          	jalr	558(ra) # 80004ed4 <pipewrite>
    80004cae:	8a2a                	mv	s4,a0
    80004cb0:	a045                	j	80004d50 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cb2:	02451783          	lh	a5,36(a0)
    80004cb6:	03079693          	slli	a3,a5,0x30
    80004cba:	92c1                	srli	a3,a3,0x30
    80004cbc:	4725                	li	a4,9
    80004cbe:	0cd76263          	bltu	a4,a3,80004d82 <filewrite+0x12c>
    80004cc2:	0792                	slli	a5,a5,0x4
    80004cc4:	0001d717          	auipc	a4,0x1d
    80004cc8:	05470713          	addi	a4,a4,84 # 80021d18 <devsw>
    80004ccc:	97ba                	add	a5,a5,a4
    80004cce:	679c                	ld	a5,8(a5)
    80004cd0:	cbdd                	beqz	a5,80004d86 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cd2:	4505                	li	a0,1
    80004cd4:	9782                	jalr	a5
    80004cd6:	8a2a                	mv	s4,a0
    80004cd8:	a8a5                	j	80004d50 <filewrite+0xfa>
    80004cda:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	8b0080e7          	jalr	-1872(ra) # 8000458e <begin_op>
      ilock(f->ip);
    80004ce6:	01893503          	ld	a0,24(s2)
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	ed2080e7          	jalr	-302(ra) # 80003bbc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cf2:	8762                	mv	a4,s8
    80004cf4:	02092683          	lw	a3,32(s2)
    80004cf8:	01598633          	add	a2,s3,s5
    80004cfc:	4585                	li	a1,1
    80004cfe:	01893503          	ld	a0,24(s2)
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	266080e7          	jalr	614(ra) # 80003f68 <writei>
    80004d0a:	84aa                	mv	s1,a0
    80004d0c:	00a05763          	blez	a0,80004d1a <filewrite+0xc4>
        f->off += r;
    80004d10:	02092783          	lw	a5,32(s2)
    80004d14:	9fa9                	addw	a5,a5,a0
    80004d16:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d1a:	01893503          	ld	a0,24(s2)
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	f60080e7          	jalr	-160(ra) # 80003c7e <iunlock>
      end_op();
    80004d26:	00000097          	auipc	ra,0x0
    80004d2a:	8e8080e7          	jalr	-1816(ra) # 8000460e <end_op>

      if(r != n1){
    80004d2e:	009c1f63          	bne	s8,s1,80004d4c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d32:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d36:	0149db63          	bge	s3,s4,80004d4c <filewrite+0xf6>
      int n1 = n - i;
    80004d3a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d3e:	84be                	mv	s1,a5
    80004d40:	2781                	sext.w	a5,a5
    80004d42:	f8fb5ce3          	bge	s6,a5,80004cda <filewrite+0x84>
    80004d46:	84de                	mv	s1,s7
    80004d48:	bf49                	j	80004cda <filewrite+0x84>
    int i = 0;
    80004d4a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d4c:	013a1f63          	bne	s4,s3,80004d6a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d50:	8552                	mv	a0,s4
    80004d52:	60a6                	ld	ra,72(sp)
    80004d54:	6406                	ld	s0,64(sp)
    80004d56:	74e2                	ld	s1,56(sp)
    80004d58:	7942                	ld	s2,48(sp)
    80004d5a:	79a2                	ld	s3,40(sp)
    80004d5c:	7a02                	ld	s4,32(sp)
    80004d5e:	6ae2                	ld	s5,24(sp)
    80004d60:	6b42                	ld	s6,16(sp)
    80004d62:	6ba2                	ld	s7,8(sp)
    80004d64:	6c02                	ld	s8,0(sp)
    80004d66:	6161                	addi	sp,sp,80
    80004d68:	8082                	ret
    ret = (i == n ? n : -1);
    80004d6a:	5a7d                	li	s4,-1
    80004d6c:	b7d5                	j	80004d50 <filewrite+0xfa>
    panic("filewrite");
    80004d6e:	00004517          	auipc	a0,0x4
    80004d72:	a4a50513          	addi	a0,a0,-1462 # 800087b8 <syscalls+0x280>
    80004d76:	ffffb097          	auipc	ra,0xffffb
    80004d7a:	7c8080e7          	jalr	1992(ra) # 8000053e <panic>
    return -1;
    80004d7e:	5a7d                	li	s4,-1
    80004d80:	bfc1                	j	80004d50 <filewrite+0xfa>
      return -1;
    80004d82:	5a7d                	li	s4,-1
    80004d84:	b7f1                	j	80004d50 <filewrite+0xfa>
    80004d86:	5a7d                	li	s4,-1
    80004d88:	b7e1                	j	80004d50 <filewrite+0xfa>

0000000080004d8a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d8a:	7179                	addi	sp,sp,-48
    80004d8c:	f406                	sd	ra,40(sp)
    80004d8e:	f022                	sd	s0,32(sp)
    80004d90:	ec26                	sd	s1,24(sp)
    80004d92:	e84a                	sd	s2,16(sp)
    80004d94:	e44e                	sd	s3,8(sp)
    80004d96:	e052                	sd	s4,0(sp)
    80004d98:	1800                	addi	s0,sp,48
    80004d9a:	84aa                	mv	s1,a0
    80004d9c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d9e:	0005b023          	sd	zero,0(a1)
    80004da2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004da6:	00000097          	auipc	ra,0x0
    80004daa:	bf8080e7          	jalr	-1032(ra) # 8000499e <filealloc>
    80004dae:	e088                	sd	a0,0(s1)
    80004db0:	c551                	beqz	a0,80004e3c <pipealloc+0xb2>
    80004db2:	00000097          	auipc	ra,0x0
    80004db6:	bec080e7          	jalr	-1044(ra) # 8000499e <filealloc>
    80004dba:	00aa3023          	sd	a0,0(s4)
    80004dbe:	c92d                	beqz	a0,80004e30 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	d34080e7          	jalr	-716(ra) # 80000af4 <kalloc>
    80004dc8:	892a                	mv	s2,a0
    80004dca:	c125                	beqz	a0,80004e2a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dcc:	4985                	li	s3,1
    80004dce:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004dd2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dd6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dda:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dde:	00003597          	auipc	a1,0x3
    80004de2:	69a58593          	addi	a1,a1,1690 # 80008478 <states.1756+0x1b8>
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	d6e080e7          	jalr	-658(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dee:	609c                	ld	a5,0(s1)
    80004df0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004df4:	609c                	ld	a5,0(s1)
    80004df6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dfa:	609c                	ld	a5,0(s1)
    80004dfc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e00:	609c                	ld	a5,0(s1)
    80004e02:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e06:	000a3783          	ld	a5,0(s4)
    80004e0a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e0e:	000a3783          	ld	a5,0(s4)
    80004e12:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e16:	000a3783          	ld	a5,0(s4)
    80004e1a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e1e:	000a3783          	ld	a5,0(s4)
    80004e22:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e26:	4501                	li	a0,0
    80004e28:	a025                	j	80004e50 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e2a:	6088                	ld	a0,0(s1)
    80004e2c:	e501                	bnez	a0,80004e34 <pipealloc+0xaa>
    80004e2e:	a039                	j	80004e3c <pipealloc+0xb2>
    80004e30:	6088                	ld	a0,0(s1)
    80004e32:	c51d                	beqz	a0,80004e60 <pipealloc+0xd6>
    fileclose(*f0);
    80004e34:	00000097          	auipc	ra,0x0
    80004e38:	c26080e7          	jalr	-986(ra) # 80004a5a <fileclose>
  if(*f1)
    80004e3c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e40:	557d                	li	a0,-1
  if(*f1)
    80004e42:	c799                	beqz	a5,80004e50 <pipealloc+0xc6>
    fileclose(*f1);
    80004e44:	853e                	mv	a0,a5
    80004e46:	00000097          	auipc	ra,0x0
    80004e4a:	c14080e7          	jalr	-1004(ra) # 80004a5a <fileclose>
  return -1;
    80004e4e:	557d                	li	a0,-1
}
    80004e50:	70a2                	ld	ra,40(sp)
    80004e52:	7402                	ld	s0,32(sp)
    80004e54:	64e2                	ld	s1,24(sp)
    80004e56:	6942                	ld	s2,16(sp)
    80004e58:	69a2                	ld	s3,8(sp)
    80004e5a:	6a02                	ld	s4,0(sp)
    80004e5c:	6145                	addi	sp,sp,48
    80004e5e:	8082                	ret
  return -1;
    80004e60:	557d                	li	a0,-1
    80004e62:	b7fd                	j	80004e50 <pipealloc+0xc6>

0000000080004e64 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e64:	1101                	addi	sp,sp,-32
    80004e66:	ec06                	sd	ra,24(sp)
    80004e68:	e822                	sd	s0,16(sp)
    80004e6a:	e426                	sd	s1,8(sp)
    80004e6c:	e04a                	sd	s2,0(sp)
    80004e6e:	1000                	addi	s0,sp,32
    80004e70:	84aa                	mv	s1,a0
    80004e72:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  if(writable){
    80004e7c:	02090d63          	beqz	s2,80004eb6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e80:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e84:	21848513          	addi	a0,s1,536
    80004e88:	ffffd097          	auipc	ra,0xffffd
    80004e8c:	67c080e7          	jalr	1660(ra) # 80002504 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e90:	2204b783          	ld	a5,544(s1)
    80004e94:	eb95                	bnez	a5,80004ec8 <pipeclose+0x64>
    release(&pi->lock);
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	e00080e7          	jalr	-512(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ea0:	8526                	mv	a0,s1
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	b56080e7          	jalr	-1194(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004eaa:	60e2                	ld	ra,24(sp)
    80004eac:	6442                	ld	s0,16(sp)
    80004eae:	64a2                	ld	s1,8(sp)
    80004eb0:	6902                	ld	s2,0(sp)
    80004eb2:	6105                	addi	sp,sp,32
    80004eb4:	8082                	ret
    pi->readopen = 0;
    80004eb6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004eba:	21c48513          	addi	a0,s1,540
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	646080e7          	jalr	1606(ra) # 80002504 <wakeup>
    80004ec6:	b7e9                	j	80004e90 <pipeclose+0x2c>
    release(&pi->lock);
    80004ec8:	8526                	mv	a0,s1
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
}
    80004ed2:	bfe1                	j	80004eaa <pipeclose+0x46>

0000000080004ed4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ed4:	7159                	addi	sp,sp,-112
    80004ed6:	f486                	sd	ra,104(sp)
    80004ed8:	f0a2                	sd	s0,96(sp)
    80004eda:	eca6                	sd	s1,88(sp)
    80004edc:	e8ca                	sd	s2,80(sp)
    80004ede:	e4ce                	sd	s3,72(sp)
    80004ee0:	e0d2                	sd	s4,64(sp)
    80004ee2:	fc56                	sd	s5,56(sp)
    80004ee4:	f85a                	sd	s6,48(sp)
    80004ee6:	f45e                	sd	s7,40(sp)
    80004ee8:	f062                	sd	s8,32(sp)
    80004eea:	ec66                	sd	s9,24(sp)
    80004eec:	1880                	addi	s0,sp,112
    80004eee:	84aa                	mv	s1,a0
    80004ef0:	8aae                	mv	s5,a1
    80004ef2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	abc080e7          	jalr	-1348(ra) # 800019b0 <myproc>
    80004efc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004efe:	8526                	mv	a0,s1
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
  while(i < n){
    80004f08:	0d405163          	blez	s4,80004fca <pipewrite+0xf6>
    80004f0c:	8ba6                	mv	s7,s1
  int i = 0;
    80004f0e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f10:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f12:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f16:	21c48c13          	addi	s8,s1,540
    80004f1a:	a08d                	j	80004f7c <pipewrite+0xa8>
      release(&pi->lock);
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	d7a080e7          	jalr	-646(ra) # 80000c98 <release>
      return -1;
    80004f26:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f28:	854a                	mv	a0,s2
    80004f2a:	70a6                	ld	ra,104(sp)
    80004f2c:	7406                	ld	s0,96(sp)
    80004f2e:	64e6                	ld	s1,88(sp)
    80004f30:	6946                	ld	s2,80(sp)
    80004f32:	69a6                	ld	s3,72(sp)
    80004f34:	6a06                	ld	s4,64(sp)
    80004f36:	7ae2                	ld	s5,56(sp)
    80004f38:	7b42                	ld	s6,48(sp)
    80004f3a:	7ba2                	ld	s7,40(sp)
    80004f3c:	7c02                	ld	s8,32(sp)
    80004f3e:	6ce2                	ld	s9,24(sp)
    80004f40:	6165                	addi	sp,sp,112
    80004f42:	8082                	ret
      wakeup(&pi->nread);
    80004f44:	8566                	mv	a0,s9
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	5be080e7          	jalr	1470(ra) # 80002504 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f4e:	85de                	mv	a1,s7
    80004f50:	8562                	mv	a0,s8
    80004f52:	ffffd097          	auipc	ra,0xffffd
    80004f56:	2da080e7          	jalr	730(ra) # 8000222c <sleep>
    80004f5a:	a839                	j	80004f78 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f5c:	21c4a783          	lw	a5,540(s1)
    80004f60:	0017871b          	addiw	a4,a5,1
    80004f64:	20e4ae23          	sw	a4,540(s1)
    80004f68:	1ff7f793          	andi	a5,a5,511
    80004f6c:	97a6                	add	a5,a5,s1
    80004f6e:	f9f44703          	lbu	a4,-97(s0)
    80004f72:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f76:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f78:	03495d63          	bge	s2,s4,80004fb2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f7c:	2204a783          	lw	a5,544(s1)
    80004f80:	dfd1                	beqz	a5,80004f1c <pipewrite+0x48>
    80004f82:	0289a783          	lw	a5,40(s3)
    80004f86:	fbd9                	bnez	a5,80004f1c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f88:	2184a783          	lw	a5,536(s1)
    80004f8c:	21c4a703          	lw	a4,540(s1)
    80004f90:	2007879b          	addiw	a5,a5,512
    80004f94:	faf708e3          	beq	a4,a5,80004f44 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f98:	4685                	li	a3,1
    80004f9a:	01590633          	add	a2,s2,s5
    80004f9e:	f9f40593          	addi	a1,s0,-97
    80004fa2:	0509b503          	ld	a0,80(s3)
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	758080e7          	jalr	1880(ra) # 800016fe <copyin>
    80004fae:	fb6517e3          	bne	a0,s6,80004f5c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004fb2:	21848513          	addi	a0,s1,536
    80004fb6:	ffffd097          	auipc	ra,0xffffd
    80004fba:	54e080e7          	jalr	1358(ra) # 80002504 <wakeup>
  release(&pi->lock);
    80004fbe:	8526                	mv	a0,s1
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	cd8080e7          	jalr	-808(ra) # 80000c98 <release>
  return i;
    80004fc8:	b785                	j	80004f28 <pipewrite+0x54>
  int i = 0;
    80004fca:	4901                	li	s2,0
    80004fcc:	b7dd                	j	80004fb2 <pipewrite+0xde>

0000000080004fce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fce:	715d                	addi	sp,sp,-80
    80004fd0:	e486                	sd	ra,72(sp)
    80004fd2:	e0a2                	sd	s0,64(sp)
    80004fd4:	fc26                	sd	s1,56(sp)
    80004fd6:	f84a                	sd	s2,48(sp)
    80004fd8:	f44e                	sd	s3,40(sp)
    80004fda:	f052                	sd	s4,32(sp)
    80004fdc:	ec56                	sd	s5,24(sp)
    80004fde:	e85a                	sd	s6,16(sp)
    80004fe0:	0880                	addi	s0,sp,80
    80004fe2:	84aa                	mv	s1,a0
    80004fe4:	892e                	mv	s2,a1
    80004fe6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	9c8080e7          	jalr	-1592(ra) # 800019b0 <myproc>
    80004ff0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ff2:	8b26                	mv	s6,s1
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	bee080e7          	jalr	-1042(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ffe:	2184a703          	lw	a4,536(s1)
    80005002:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005006:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000500a:	02f71463          	bne	a4,a5,80005032 <piperead+0x64>
    8000500e:	2244a783          	lw	a5,548(s1)
    80005012:	c385                	beqz	a5,80005032 <piperead+0x64>
    if(pr->killed){
    80005014:	028a2783          	lw	a5,40(s4)
    80005018:	ebc1                	bnez	a5,800050a8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000501a:	85da                	mv	a1,s6
    8000501c:	854e                	mv	a0,s3
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	20e080e7          	jalr	526(ra) # 8000222c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005026:	2184a703          	lw	a4,536(s1)
    8000502a:	21c4a783          	lw	a5,540(s1)
    8000502e:	fef700e3          	beq	a4,a5,8000500e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005032:	09505263          	blez	s5,800050b6 <piperead+0xe8>
    80005036:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005038:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000503a:	2184a783          	lw	a5,536(s1)
    8000503e:	21c4a703          	lw	a4,540(s1)
    80005042:	02f70d63          	beq	a4,a5,8000507c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005046:	0017871b          	addiw	a4,a5,1
    8000504a:	20e4ac23          	sw	a4,536(s1)
    8000504e:	1ff7f793          	andi	a5,a5,511
    80005052:	97a6                	add	a5,a5,s1
    80005054:	0187c783          	lbu	a5,24(a5)
    80005058:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000505c:	4685                	li	a3,1
    8000505e:	fbf40613          	addi	a2,s0,-65
    80005062:	85ca                	mv	a1,s2
    80005064:	050a3503          	ld	a0,80(s4)
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	60a080e7          	jalr	1546(ra) # 80001672 <copyout>
    80005070:	01650663          	beq	a0,s6,8000507c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005074:	2985                	addiw	s3,s3,1
    80005076:	0905                	addi	s2,s2,1
    80005078:	fd3a91e3          	bne	s5,s3,8000503a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000507c:	21c48513          	addi	a0,s1,540
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	484080e7          	jalr	1156(ra) # 80002504 <wakeup>
  release(&pi->lock);
    80005088:	8526                	mv	a0,s1
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	c0e080e7          	jalr	-1010(ra) # 80000c98 <release>
  return i;
}
    80005092:	854e                	mv	a0,s3
    80005094:	60a6                	ld	ra,72(sp)
    80005096:	6406                	ld	s0,64(sp)
    80005098:	74e2                	ld	s1,56(sp)
    8000509a:	7942                	ld	s2,48(sp)
    8000509c:	79a2                	ld	s3,40(sp)
    8000509e:	7a02                	ld	s4,32(sp)
    800050a0:	6ae2                	ld	s5,24(sp)
    800050a2:	6b42                	ld	s6,16(sp)
    800050a4:	6161                	addi	sp,sp,80
    800050a6:	8082                	ret
      release(&pi->lock);
    800050a8:	8526                	mv	a0,s1
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	bee080e7          	jalr	-1042(ra) # 80000c98 <release>
      return -1;
    800050b2:	59fd                	li	s3,-1
    800050b4:	bff9                	j	80005092 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050b6:	4981                	li	s3,0
    800050b8:	b7d1                	j	8000507c <piperead+0xae>

00000000800050ba <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050ba:	df010113          	addi	sp,sp,-528
    800050be:	20113423          	sd	ra,520(sp)
    800050c2:	20813023          	sd	s0,512(sp)
    800050c6:	ffa6                	sd	s1,504(sp)
    800050c8:	fbca                	sd	s2,496(sp)
    800050ca:	f7ce                	sd	s3,488(sp)
    800050cc:	f3d2                	sd	s4,480(sp)
    800050ce:	efd6                	sd	s5,472(sp)
    800050d0:	ebda                	sd	s6,464(sp)
    800050d2:	e7de                	sd	s7,456(sp)
    800050d4:	e3e2                	sd	s8,448(sp)
    800050d6:	ff66                	sd	s9,440(sp)
    800050d8:	fb6a                	sd	s10,432(sp)
    800050da:	f76e                	sd	s11,424(sp)
    800050dc:	0c00                	addi	s0,sp,528
    800050de:	84aa                	mv	s1,a0
    800050e0:	dea43c23          	sd	a0,-520(s0)
    800050e4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	8c8080e7          	jalr	-1848(ra) # 800019b0 <myproc>
    800050f0:	892a                	mv	s2,a0

  begin_op();
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	49c080e7          	jalr	1180(ra) # 8000458e <begin_op>

  if((ip = namei(path)) == 0){
    800050fa:	8526                	mv	a0,s1
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	276080e7          	jalr	630(ra) # 80004372 <namei>
    80005104:	c92d                	beqz	a0,80005176 <exec+0xbc>
    80005106:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	ab4080e7          	jalr	-1356(ra) # 80003bbc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005110:	04000713          	li	a4,64
    80005114:	4681                	li	a3,0
    80005116:	e5040613          	addi	a2,s0,-432
    8000511a:	4581                	li	a1,0
    8000511c:	8526                	mv	a0,s1
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	d52080e7          	jalr	-686(ra) # 80003e70 <readi>
    80005126:	04000793          	li	a5,64
    8000512a:	00f51a63          	bne	a0,a5,8000513e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000512e:	e5042703          	lw	a4,-432(s0)
    80005132:	464c47b7          	lui	a5,0x464c4
    80005136:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000513a:	04f70463          	beq	a4,a5,80005182 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000513e:	8526                	mv	a0,s1
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	cde080e7          	jalr	-802(ra) # 80003e1e <iunlockput>
    end_op();
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	4c6080e7          	jalr	1222(ra) # 8000460e <end_op>
  }
  return -1;
    80005150:	557d                	li	a0,-1
}
    80005152:	20813083          	ld	ra,520(sp)
    80005156:	20013403          	ld	s0,512(sp)
    8000515a:	74fe                	ld	s1,504(sp)
    8000515c:	795e                	ld	s2,496(sp)
    8000515e:	79be                	ld	s3,488(sp)
    80005160:	7a1e                	ld	s4,480(sp)
    80005162:	6afe                	ld	s5,472(sp)
    80005164:	6b5e                	ld	s6,464(sp)
    80005166:	6bbe                	ld	s7,456(sp)
    80005168:	6c1e                	ld	s8,448(sp)
    8000516a:	7cfa                	ld	s9,440(sp)
    8000516c:	7d5a                	ld	s10,432(sp)
    8000516e:	7dba                	ld	s11,424(sp)
    80005170:	21010113          	addi	sp,sp,528
    80005174:	8082                	ret
    end_op();
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	498080e7          	jalr	1176(ra) # 8000460e <end_op>
    return -1;
    8000517e:	557d                	li	a0,-1
    80005180:	bfc9                	j	80005152 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005182:	854a                	mv	a0,s2
    80005184:	ffffd097          	auipc	ra,0xffffd
    80005188:	8f0080e7          	jalr	-1808(ra) # 80001a74 <proc_pagetable>
    8000518c:	8baa                	mv	s7,a0
    8000518e:	d945                	beqz	a0,8000513e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005190:	e7042983          	lw	s3,-400(s0)
    80005194:	e8845783          	lhu	a5,-376(s0)
    80005198:	c7ad                	beqz	a5,80005202 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000519a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000519c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000519e:	6c85                	lui	s9,0x1
    800051a0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051a4:	def43823          	sd	a5,-528(s0)
    800051a8:	a42d                	j	800053d2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051aa:	00003517          	auipc	a0,0x3
    800051ae:	61e50513          	addi	a0,a0,1566 # 800087c8 <syscalls+0x290>
    800051b2:	ffffb097          	auipc	ra,0xffffb
    800051b6:	38c080e7          	jalr	908(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051ba:	8756                	mv	a4,s5
    800051bc:	012d86bb          	addw	a3,s11,s2
    800051c0:	4581                	li	a1,0
    800051c2:	8526                	mv	a0,s1
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	cac080e7          	jalr	-852(ra) # 80003e70 <readi>
    800051cc:	2501                	sext.w	a0,a0
    800051ce:	1aaa9963          	bne	s5,a0,80005380 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051d2:	6785                	lui	a5,0x1
    800051d4:	0127893b          	addw	s2,a5,s2
    800051d8:	77fd                	lui	a5,0xfffff
    800051da:	01478a3b          	addw	s4,a5,s4
    800051de:	1f897163          	bgeu	s2,s8,800053c0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051e2:	02091593          	slli	a1,s2,0x20
    800051e6:	9181                	srli	a1,a1,0x20
    800051e8:	95ea                	add	a1,a1,s10
    800051ea:	855e                	mv	a0,s7
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	e82080e7          	jalr	-382(ra) # 8000106e <walkaddr>
    800051f4:	862a                	mv	a2,a0
    if(pa == 0)
    800051f6:	d955                	beqz	a0,800051aa <exec+0xf0>
      n = PGSIZE;
    800051f8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051fa:	fd9a70e3          	bgeu	s4,s9,800051ba <exec+0x100>
      n = sz - i;
    800051fe:	8ad2                	mv	s5,s4
    80005200:	bf6d                	j	800051ba <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005202:	4901                	li	s2,0
  iunlockput(ip);
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	c18080e7          	jalr	-1000(ra) # 80003e1e <iunlockput>
  end_op();
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	400080e7          	jalr	1024(ra) # 8000460e <end_op>
  p = myproc();
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	79a080e7          	jalr	1946(ra) # 800019b0 <myproc>
    8000521e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005220:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005224:	6785                	lui	a5,0x1
    80005226:	17fd                	addi	a5,a5,-1
    80005228:	993e                	add	s2,s2,a5
    8000522a:	757d                	lui	a0,0xfffff
    8000522c:	00a977b3          	and	a5,s2,a0
    80005230:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005234:	6609                	lui	a2,0x2
    80005236:	963e                	add	a2,a2,a5
    80005238:	85be                	mv	a1,a5
    8000523a:	855e                	mv	a0,s7
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	1e6080e7          	jalr	486(ra) # 80001422 <uvmalloc>
    80005244:	8b2a                	mv	s6,a0
  ip = 0;
    80005246:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005248:	12050c63          	beqz	a0,80005380 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000524c:	75f9                	lui	a1,0xffffe
    8000524e:	95aa                	add	a1,a1,a0
    80005250:	855e                	mv	a0,s7
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	3ee080e7          	jalr	1006(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000525a:	7c7d                	lui	s8,0xfffff
    8000525c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000525e:	e0043783          	ld	a5,-512(s0)
    80005262:	6388                	ld	a0,0(a5)
    80005264:	c535                	beqz	a0,800052d0 <exec+0x216>
    80005266:	e9040993          	addi	s3,s0,-368
    8000526a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000526e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	bf4080e7          	jalr	-1036(ra) # 80000e64 <strlen>
    80005278:	2505                	addiw	a0,a0,1
    8000527a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000527e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005282:	13896363          	bltu	s2,s8,800053a8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005286:	e0043d83          	ld	s11,-512(s0)
    8000528a:	000dba03          	ld	s4,0(s11)
    8000528e:	8552                	mv	a0,s4
    80005290:	ffffc097          	auipc	ra,0xffffc
    80005294:	bd4080e7          	jalr	-1068(ra) # 80000e64 <strlen>
    80005298:	0015069b          	addiw	a3,a0,1
    8000529c:	8652                	mv	a2,s4
    8000529e:	85ca                	mv	a1,s2
    800052a0:	855e                	mv	a0,s7
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	3d0080e7          	jalr	976(ra) # 80001672 <copyout>
    800052aa:	10054363          	bltz	a0,800053b0 <exec+0x2f6>
    ustack[argc] = sp;
    800052ae:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052b2:	0485                	addi	s1,s1,1
    800052b4:	008d8793          	addi	a5,s11,8
    800052b8:	e0f43023          	sd	a5,-512(s0)
    800052bc:	008db503          	ld	a0,8(s11)
    800052c0:	c911                	beqz	a0,800052d4 <exec+0x21a>
    if(argc >= MAXARG)
    800052c2:	09a1                	addi	s3,s3,8
    800052c4:	fb3c96e3          	bne	s9,s3,80005270 <exec+0x1b6>
  sz = sz1;
    800052c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052cc:	4481                	li	s1,0
    800052ce:	a84d                	j	80005380 <exec+0x2c6>
  sp = sz;
    800052d0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052d2:	4481                	li	s1,0
  ustack[argc] = 0;
    800052d4:	00349793          	slli	a5,s1,0x3
    800052d8:	f9040713          	addi	a4,s0,-112
    800052dc:	97ba                	add	a5,a5,a4
    800052de:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052e2:	00148693          	addi	a3,s1,1
    800052e6:	068e                	slli	a3,a3,0x3
    800052e8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052ec:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052f0:	01897663          	bgeu	s2,s8,800052fc <exec+0x242>
  sz = sz1;
    800052f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052f8:	4481                	li	s1,0
    800052fa:	a059                	j	80005380 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052fc:	e9040613          	addi	a2,s0,-368
    80005300:	85ca                	mv	a1,s2
    80005302:	855e                	mv	a0,s7
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	36e080e7          	jalr	878(ra) # 80001672 <copyout>
    8000530c:	0a054663          	bltz	a0,800053b8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005310:	058ab783          	ld	a5,88(s5)
    80005314:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005318:	df843783          	ld	a5,-520(s0)
    8000531c:	0007c703          	lbu	a4,0(a5)
    80005320:	cf11                	beqz	a4,8000533c <exec+0x282>
    80005322:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005324:	02f00693          	li	a3,47
    80005328:	a039                	j	80005336 <exec+0x27c>
      last = s+1;
    8000532a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000532e:	0785                	addi	a5,a5,1
    80005330:	fff7c703          	lbu	a4,-1(a5)
    80005334:	c701                	beqz	a4,8000533c <exec+0x282>
    if(*s == '/')
    80005336:	fed71ce3          	bne	a4,a3,8000532e <exec+0x274>
    8000533a:	bfc5                	j	8000532a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000533c:	4641                	li	a2,16
    8000533e:	df843583          	ld	a1,-520(s0)
    80005342:	158a8513          	addi	a0,s5,344
    80005346:	ffffc097          	auipc	ra,0xffffc
    8000534a:	aec080e7          	jalr	-1300(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000534e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005352:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005356:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000535a:	058ab783          	ld	a5,88(s5)
    8000535e:	e6843703          	ld	a4,-408(s0)
    80005362:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005364:	058ab783          	ld	a5,88(s5)
    80005368:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000536c:	85ea                	mv	a1,s10
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	7a2080e7          	jalr	1954(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005376:	0004851b          	sext.w	a0,s1
    8000537a:	bbe1                	j	80005152 <exec+0x98>
    8000537c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005380:	e0843583          	ld	a1,-504(s0)
    80005384:	855e                	mv	a0,s7
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	78a080e7          	jalr	1930(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    8000538e:	da0498e3          	bnez	s1,8000513e <exec+0x84>
  return -1;
    80005392:	557d                	li	a0,-1
    80005394:	bb7d                	j	80005152 <exec+0x98>
    80005396:	e1243423          	sd	s2,-504(s0)
    8000539a:	b7dd                	j	80005380 <exec+0x2c6>
    8000539c:	e1243423          	sd	s2,-504(s0)
    800053a0:	b7c5                	j	80005380 <exec+0x2c6>
    800053a2:	e1243423          	sd	s2,-504(s0)
    800053a6:	bfe9                	j	80005380 <exec+0x2c6>
  sz = sz1;
    800053a8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ac:	4481                	li	s1,0
    800053ae:	bfc9                	j	80005380 <exec+0x2c6>
  sz = sz1;
    800053b0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053b4:	4481                	li	s1,0
    800053b6:	b7e9                	j	80005380 <exec+0x2c6>
  sz = sz1;
    800053b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053bc:	4481                	li	s1,0
    800053be:	b7c9                	j	80005380 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053c0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c4:	2b05                	addiw	s6,s6,1
    800053c6:	0389899b          	addiw	s3,s3,56
    800053ca:	e8845783          	lhu	a5,-376(s0)
    800053ce:	e2fb5be3          	bge	s6,a5,80005204 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053d2:	2981                	sext.w	s3,s3
    800053d4:	03800713          	li	a4,56
    800053d8:	86ce                	mv	a3,s3
    800053da:	e1840613          	addi	a2,s0,-488
    800053de:	4581                	li	a1,0
    800053e0:	8526                	mv	a0,s1
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	a8e080e7          	jalr	-1394(ra) # 80003e70 <readi>
    800053ea:	03800793          	li	a5,56
    800053ee:	f8f517e3          	bne	a0,a5,8000537c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053f2:	e1842783          	lw	a5,-488(s0)
    800053f6:	4705                	li	a4,1
    800053f8:	fce796e3          	bne	a5,a4,800053c4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053fc:	e4043603          	ld	a2,-448(s0)
    80005400:	e3843783          	ld	a5,-456(s0)
    80005404:	f8f669e3          	bltu	a2,a5,80005396 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005408:	e2843783          	ld	a5,-472(s0)
    8000540c:	963e                	add	a2,a2,a5
    8000540e:	f8f667e3          	bltu	a2,a5,8000539c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005412:	85ca                	mv	a1,s2
    80005414:	855e                	mv	a0,s7
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	00c080e7          	jalr	12(ra) # 80001422 <uvmalloc>
    8000541e:	e0a43423          	sd	a0,-504(s0)
    80005422:	d141                	beqz	a0,800053a2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005424:	e2843d03          	ld	s10,-472(s0)
    80005428:	df043783          	ld	a5,-528(s0)
    8000542c:	00fd77b3          	and	a5,s10,a5
    80005430:	fba1                	bnez	a5,80005380 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005432:	e2042d83          	lw	s11,-480(s0)
    80005436:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000543a:	f80c03e3          	beqz	s8,800053c0 <exec+0x306>
    8000543e:	8a62                	mv	s4,s8
    80005440:	4901                	li	s2,0
    80005442:	b345                	j	800051e2 <exec+0x128>

0000000080005444 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005444:	7179                	addi	sp,sp,-48
    80005446:	f406                	sd	ra,40(sp)
    80005448:	f022                	sd	s0,32(sp)
    8000544a:	ec26                	sd	s1,24(sp)
    8000544c:	e84a                	sd	s2,16(sp)
    8000544e:	1800                	addi	s0,sp,48
    80005450:	892e                	mv	s2,a1
    80005452:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005454:	fdc40593          	addi	a1,s0,-36
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	9a8080e7          	jalr	-1624(ra) # 80002e00 <argint>
    80005460:	04054063          	bltz	a0,800054a0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005464:	fdc42703          	lw	a4,-36(s0)
    80005468:	47bd                	li	a5,15
    8000546a:	02e7ed63          	bltu	a5,a4,800054a4 <argfd+0x60>
    8000546e:	ffffc097          	auipc	ra,0xffffc
    80005472:	542080e7          	jalr	1346(ra) # 800019b0 <myproc>
    80005476:	fdc42703          	lw	a4,-36(s0)
    8000547a:	01a70793          	addi	a5,a4,26
    8000547e:	078e                	slli	a5,a5,0x3
    80005480:	953e                	add	a0,a0,a5
    80005482:	611c                	ld	a5,0(a0)
    80005484:	c395                	beqz	a5,800054a8 <argfd+0x64>
    return -1;
  if(pfd)
    80005486:	00090463          	beqz	s2,8000548e <argfd+0x4a>
    *pfd = fd;
    8000548a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000548e:	4501                	li	a0,0
  if(pf)
    80005490:	c091                	beqz	s1,80005494 <argfd+0x50>
    *pf = f;
    80005492:	e09c                	sd	a5,0(s1)
}
    80005494:	70a2                	ld	ra,40(sp)
    80005496:	7402                	ld	s0,32(sp)
    80005498:	64e2                	ld	s1,24(sp)
    8000549a:	6942                	ld	s2,16(sp)
    8000549c:	6145                	addi	sp,sp,48
    8000549e:	8082                	ret
    return -1;
    800054a0:	557d                	li	a0,-1
    800054a2:	bfcd                	j	80005494 <argfd+0x50>
    return -1;
    800054a4:	557d                	li	a0,-1
    800054a6:	b7fd                	j	80005494 <argfd+0x50>
    800054a8:	557d                	li	a0,-1
    800054aa:	b7ed                	j	80005494 <argfd+0x50>

00000000800054ac <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054ac:	1101                	addi	sp,sp,-32
    800054ae:	ec06                	sd	ra,24(sp)
    800054b0:	e822                	sd	s0,16(sp)
    800054b2:	e426                	sd	s1,8(sp)
    800054b4:	1000                	addi	s0,sp,32
    800054b6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054b8:	ffffc097          	auipc	ra,0xffffc
    800054bc:	4f8080e7          	jalr	1272(ra) # 800019b0 <myproc>
    800054c0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054c2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800054c6:	4501                	li	a0,0
    800054c8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054ca:	6398                	ld	a4,0(a5)
    800054cc:	cb19                	beqz	a4,800054e2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054ce:	2505                	addiw	a0,a0,1
    800054d0:	07a1                	addi	a5,a5,8
    800054d2:	fed51ce3          	bne	a0,a3,800054ca <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054d6:	557d                	li	a0,-1
}
    800054d8:	60e2                	ld	ra,24(sp)
    800054da:	6442                	ld	s0,16(sp)
    800054dc:	64a2                	ld	s1,8(sp)
    800054de:	6105                	addi	sp,sp,32
    800054e0:	8082                	ret
      p->ofile[fd] = f;
    800054e2:	01a50793          	addi	a5,a0,26
    800054e6:	078e                	slli	a5,a5,0x3
    800054e8:	963e                	add	a2,a2,a5
    800054ea:	e204                	sd	s1,0(a2)
      return fd;
    800054ec:	b7f5                	j	800054d8 <fdalloc+0x2c>

00000000800054ee <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054ee:	715d                	addi	sp,sp,-80
    800054f0:	e486                	sd	ra,72(sp)
    800054f2:	e0a2                	sd	s0,64(sp)
    800054f4:	fc26                	sd	s1,56(sp)
    800054f6:	f84a                	sd	s2,48(sp)
    800054f8:	f44e                	sd	s3,40(sp)
    800054fa:	f052                	sd	s4,32(sp)
    800054fc:	ec56                	sd	s5,24(sp)
    800054fe:	0880                	addi	s0,sp,80
    80005500:	89ae                	mv	s3,a1
    80005502:	8ab2                	mv	s5,a2
    80005504:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005506:	fb040593          	addi	a1,s0,-80
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	e86080e7          	jalr	-378(ra) # 80004390 <nameiparent>
    80005512:	892a                	mv	s2,a0
    80005514:	12050f63          	beqz	a0,80005652 <create+0x164>
    return 0;

  ilock(dp);
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	6a4080e7          	jalr	1700(ra) # 80003bbc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005520:	4601                	li	a2,0
    80005522:	fb040593          	addi	a1,s0,-80
    80005526:	854a                	mv	a0,s2
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	b78080e7          	jalr	-1160(ra) # 800040a0 <dirlookup>
    80005530:	84aa                	mv	s1,a0
    80005532:	c921                	beqz	a0,80005582 <create+0x94>
    iunlockput(dp);
    80005534:	854a                	mv	a0,s2
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	8e8080e7          	jalr	-1816(ra) # 80003e1e <iunlockput>
    ilock(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	67c080e7          	jalr	1660(ra) # 80003bbc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005548:	2981                	sext.w	s3,s3
    8000554a:	4789                	li	a5,2
    8000554c:	02f99463          	bne	s3,a5,80005574 <create+0x86>
    80005550:	0444d783          	lhu	a5,68(s1)
    80005554:	37f9                	addiw	a5,a5,-2
    80005556:	17c2                	slli	a5,a5,0x30
    80005558:	93c1                	srli	a5,a5,0x30
    8000555a:	4705                	li	a4,1
    8000555c:	00f76c63          	bltu	a4,a5,80005574 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005560:	8526                	mv	a0,s1
    80005562:	60a6                	ld	ra,72(sp)
    80005564:	6406                	ld	s0,64(sp)
    80005566:	74e2                	ld	s1,56(sp)
    80005568:	7942                	ld	s2,48(sp)
    8000556a:	79a2                	ld	s3,40(sp)
    8000556c:	7a02                	ld	s4,32(sp)
    8000556e:	6ae2                	ld	s5,24(sp)
    80005570:	6161                	addi	sp,sp,80
    80005572:	8082                	ret
    iunlockput(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	8a8080e7          	jalr	-1880(ra) # 80003e1e <iunlockput>
    return 0;
    8000557e:	4481                	li	s1,0
    80005580:	b7c5                	j	80005560 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005582:	85ce                	mv	a1,s3
    80005584:	00092503          	lw	a0,0(s2)
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	49c080e7          	jalr	1180(ra) # 80003a24 <ialloc>
    80005590:	84aa                	mv	s1,a0
    80005592:	c529                	beqz	a0,800055dc <create+0xee>
  ilock(ip);
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	628080e7          	jalr	1576(ra) # 80003bbc <ilock>
  ip->major = major;
    8000559c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055a0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055a4:	4785                	li	a5,1
    800055a6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	546080e7          	jalr	1350(ra) # 80003af2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055b4:	2981                	sext.w	s3,s3
    800055b6:	4785                	li	a5,1
    800055b8:	02f98a63          	beq	s3,a5,800055ec <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055bc:	40d0                	lw	a2,4(s1)
    800055be:	fb040593          	addi	a1,s0,-80
    800055c2:	854a                	mv	a0,s2
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	cec080e7          	jalr	-788(ra) # 800042b0 <dirlink>
    800055cc:	06054b63          	bltz	a0,80005642 <create+0x154>
  iunlockput(dp);
    800055d0:	854a                	mv	a0,s2
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	84c080e7          	jalr	-1972(ra) # 80003e1e <iunlockput>
  return ip;
    800055da:	b759                	j	80005560 <create+0x72>
    panic("create: ialloc");
    800055dc:	00003517          	auipc	a0,0x3
    800055e0:	20c50513          	addi	a0,a0,524 # 800087e8 <syscalls+0x2b0>
    800055e4:	ffffb097          	auipc	ra,0xffffb
    800055e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055ec:	04a95783          	lhu	a5,74(s2)
    800055f0:	2785                	addiw	a5,a5,1
    800055f2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055f6:	854a                	mv	a0,s2
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	4fa080e7          	jalr	1274(ra) # 80003af2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005600:	40d0                	lw	a2,4(s1)
    80005602:	00003597          	auipc	a1,0x3
    80005606:	1f658593          	addi	a1,a1,502 # 800087f8 <syscalls+0x2c0>
    8000560a:	8526                	mv	a0,s1
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	ca4080e7          	jalr	-860(ra) # 800042b0 <dirlink>
    80005614:	00054f63          	bltz	a0,80005632 <create+0x144>
    80005618:	00492603          	lw	a2,4(s2)
    8000561c:	00003597          	auipc	a1,0x3
    80005620:	1e458593          	addi	a1,a1,484 # 80008800 <syscalls+0x2c8>
    80005624:	8526                	mv	a0,s1
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	c8a080e7          	jalr	-886(ra) # 800042b0 <dirlink>
    8000562e:	f80557e3          	bgez	a0,800055bc <create+0xce>
      panic("create dots");
    80005632:	00003517          	auipc	a0,0x3
    80005636:	1d650513          	addi	a0,a0,470 # 80008808 <syscalls+0x2d0>
    8000563a:	ffffb097          	auipc	ra,0xffffb
    8000563e:	f04080e7          	jalr	-252(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005642:	00003517          	auipc	a0,0x3
    80005646:	1d650513          	addi	a0,a0,470 # 80008818 <syscalls+0x2e0>
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	ef4080e7          	jalr	-268(ra) # 8000053e <panic>
    return 0;
    80005652:	84aa                	mv	s1,a0
    80005654:	b731                	j	80005560 <create+0x72>

0000000080005656 <sys_dup>:
{
    80005656:	7179                	addi	sp,sp,-48
    80005658:	f406                	sd	ra,40(sp)
    8000565a:	f022                	sd	s0,32(sp)
    8000565c:	ec26                	sd	s1,24(sp)
    8000565e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005660:	fd840613          	addi	a2,s0,-40
    80005664:	4581                	li	a1,0
    80005666:	4501                	li	a0,0
    80005668:	00000097          	auipc	ra,0x0
    8000566c:	ddc080e7          	jalr	-548(ra) # 80005444 <argfd>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005672:	02054363          	bltz	a0,80005698 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005676:	fd843503          	ld	a0,-40(s0)
    8000567a:	00000097          	auipc	ra,0x0
    8000567e:	e32080e7          	jalr	-462(ra) # 800054ac <fdalloc>
    80005682:	84aa                	mv	s1,a0
    return -1;
    80005684:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005686:	00054963          	bltz	a0,80005698 <sys_dup+0x42>
  filedup(f);
    8000568a:	fd843503          	ld	a0,-40(s0)
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	37a080e7          	jalr	890(ra) # 80004a08 <filedup>
  return fd;
    80005696:	87a6                	mv	a5,s1
}
    80005698:	853e                	mv	a0,a5
    8000569a:	70a2                	ld	ra,40(sp)
    8000569c:	7402                	ld	s0,32(sp)
    8000569e:	64e2                	ld	s1,24(sp)
    800056a0:	6145                	addi	sp,sp,48
    800056a2:	8082                	ret

00000000800056a4 <sys_read>:
{
    800056a4:	7179                	addi	sp,sp,-48
    800056a6:	f406                	sd	ra,40(sp)
    800056a8:	f022                	sd	s0,32(sp)
    800056aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ac:	fe840613          	addi	a2,s0,-24
    800056b0:	4581                	li	a1,0
    800056b2:	4501                	li	a0,0
    800056b4:	00000097          	auipc	ra,0x0
    800056b8:	d90080e7          	jalr	-624(ra) # 80005444 <argfd>
    return -1;
    800056bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056be:	04054163          	bltz	a0,80005700 <sys_read+0x5c>
    800056c2:	fe440593          	addi	a1,s0,-28
    800056c6:	4509                	li	a0,2
    800056c8:	ffffd097          	auipc	ra,0xffffd
    800056cc:	738080e7          	jalr	1848(ra) # 80002e00 <argint>
    return -1;
    800056d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d2:	02054763          	bltz	a0,80005700 <sys_read+0x5c>
    800056d6:	fd840593          	addi	a1,s0,-40
    800056da:	4505                	li	a0,1
    800056dc:	ffffd097          	auipc	ra,0xffffd
    800056e0:	746080e7          	jalr	1862(ra) # 80002e22 <argaddr>
    return -1;
    800056e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e6:	00054d63          	bltz	a0,80005700 <sys_read+0x5c>
  return fileread(f, p, n);
    800056ea:	fe442603          	lw	a2,-28(s0)
    800056ee:	fd843583          	ld	a1,-40(s0)
    800056f2:	fe843503          	ld	a0,-24(s0)
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	49e080e7          	jalr	1182(ra) # 80004b94 <fileread>
    800056fe:	87aa                	mv	a5,a0
}
    80005700:	853e                	mv	a0,a5
    80005702:	70a2                	ld	ra,40(sp)
    80005704:	7402                	ld	s0,32(sp)
    80005706:	6145                	addi	sp,sp,48
    80005708:	8082                	ret

000000008000570a <sys_write>:
{
    8000570a:	7179                	addi	sp,sp,-48
    8000570c:	f406                	sd	ra,40(sp)
    8000570e:	f022                	sd	s0,32(sp)
    80005710:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005712:	fe840613          	addi	a2,s0,-24
    80005716:	4581                	li	a1,0
    80005718:	4501                	li	a0,0
    8000571a:	00000097          	auipc	ra,0x0
    8000571e:	d2a080e7          	jalr	-726(ra) # 80005444 <argfd>
    return -1;
    80005722:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005724:	04054163          	bltz	a0,80005766 <sys_write+0x5c>
    80005728:	fe440593          	addi	a1,s0,-28
    8000572c:	4509                	li	a0,2
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	6d2080e7          	jalr	1746(ra) # 80002e00 <argint>
    return -1;
    80005736:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005738:	02054763          	bltz	a0,80005766 <sys_write+0x5c>
    8000573c:	fd840593          	addi	a1,s0,-40
    80005740:	4505                	li	a0,1
    80005742:	ffffd097          	auipc	ra,0xffffd
    80005746:	6e0080e7          	jalr	1760(ra) # 80002e22 <argaddr>
    return -1;
    8000574a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000574c:	00054d63          	bltz	a0,80005766 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005750:	fe442603          	lw	a2,-28(s0)
    80005754:	fd843583          	ld	a1,-40(s0)
    80005758:	fe843503          	ld	a0,-24(s0)
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	4fa080e7          	jalr	1274(ra) # 80004c56 <filewrite>
    80005764:	87aa                	mv	a5,a0
}
    80005766:	853e                	mv	a0,a5
    80005768:	70a2                	ld	ra,40(sp)
    8000576a:	7402                	ld	s0,32(sp)
    8000576c:	6145                	addi	sp,sp,48
    8000576e:	8082                	ret

0000000080005770 <sys_close>:
{
    80005770:	1101                	addi	sp,sp,-32
    80005772:	ec06                	sd	ra,24(sp)
    80005774:	e822                	sd	s0,16(sp)
    80005776:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005778:	fe040613          	addi	a2,s0,-32
    8000577c:	fec40593          	addi	a1,s0,-20
    80005780:	4501                	li	a0,0
    80005782:	00000097          	auipc	ra,0x0
    80005786:	cc2080e7          	jalr	-830(ra) # 80005444 <argfd>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000578c:	02054463          	bltz	a0,800057b4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005790:	ffffc097          	auipc	ra,0xffffc
    80005794:	220080e7          	jalr	544(ra) # 800019b0 <myproc>
    80005798:	fec42783          	lw	a5,-20(s0)
    8000579c:	07e9                	addi	a5,a5,26
    8000579e:	078e                	slli	a5,a5,0x3
    800057a0:	97aa                	add	a5,a5,a0
    800057a2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057a6:	fe043503          	ld	a0,-32(s0)
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	2b0080e7          	jalr	688(ra) # 80004a5a <fileclose>
  return 0;
    800057b2:	4781                	li	a5,0
}
    800057b4:	853e                	mv	a0,a5
    800057b6:	60e2                	ld	ra,24(sp)
    800057b8:	6442                	ld	s0,16(sp)
    800057ba:	6105                	addi	sp,sp,32
    800057bc:	8082                	ret

00000000800057be <sys_fstat>:
{
    800057be:	1101                	addi	sp,sp,-32
    800057c0:	ec06                	sd	ra,24(sp)
    800057c2:	e822                	sd	s0,16(sp)
    800057c4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057c6:	fe840613          	addi	a2,s0,-24
    800057ca:	4581                	li	a1,0
    800057cc:	4501                	li	a0,0
    800057ce:	00000097          	auipc	ra,0x0
    800057d2:	c76080e7          	jalr	-906(ra) # 80005444 <argfd>
    return -1;
    800057d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057d8:	02054563          	bltz	a0,80005802 <sys_fstat+0x44>
    800057dc:	fe040593          	addi	a1,s0,-32
    800057e0:	4505                	li	a0,1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	640080e7          	jalr	1600(ra) # 80002e22 <argaddr>
    return -1;
    800057ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057ec:	00054b63          	bltz	a0,80005802 <sys_fstat+0x44>
  return filestat(f, st);
    800057f0:	fe043583          	ld	a1,-32(s0)
    800057f4:	fe843503          	ld	a0,-24(s0)
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	32a080e7          	jalr	810(ra) # 80004b22 <filestat>
    80005800:	87aa                	mv	a5,a0
}
    80005802:	853e                	mv	a0,a5
    80005804:	60e2                	ld	ra,24(sp)
    80005806:	6442                	ld	s0,16(sp)
    80005808:	6105                	addi	sp,sp,32
    8000580a:	8082                	ret

000000008000580c <sys_link>:
{
    8000580c:	7169                	addi	sp,sp,-304
    8000580e:	f606                	sd	ra,296(sp)
    80005810:	f222                	sd	s0,288(sp)
    80005812:	ee26                	sd	s1,280(sp)
    80005814:	ea4a                	sd	s2,272(sp)
    80005816:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005818:	08000613          	li	a2,128
    8000581c:	ed040593          	addi	a1,s0,-304
    80005820:	4501                	li	a0,0
    80005822:	ffffd097          	auipc	ra,0xffffd
    80005826:	622080e7          	jalr	1570(ra) # 80002e44 <argstr>
    return -1;
    8000582a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000582c:	10054e63          	bltz	a0,80005948 <sys_link+0x13c>
    80005830:	08000613          	li	a2,128
    80005834:	f5040593          	addi	a1,s0,-176
    80005838:	4505                	li	a0,1
    8000583a:	ffffd097          	auipc	ra,0xffffd
    8000583e:	60a080e7          	jalr	1546(ra) # 80002e44 <argstr>
    return -1;
    80005842:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005844:	10054263          	bltz	a0,80005948 <sys_link+0x13c>
  begin_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	d46080e7          	jalr	-698(ra) # 8000458e <begin_op>
  if((ip = namei(old)) == 0){
    80005850:	ed040513          	addi	a0,s0,-304
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	b1e080e7          	jalr	-1250(ra) # 80004372 <namei>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	c551                	beqz	a0,800058ea <sys_link+0xde>
  ilock(ip);
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	35c080e7          	jalr	860(ra) # 80003bbc <ilock>
  if(ip->type == T_DIR){
    80005868:	04449703          	lh	a4,68(s1)
    8000586c:	4785                	li	a5,1
    8000586e:	08f70463          	beq	a4,a5,800058f6 <sys_link+0xea>
  ip->nlink++;
    80005872:	04a4d783          	lhu	a5,74(s1)
    80005876:	2785                	addiw	a5,a5,1
    80005878:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	274080e7          	jalr	628(ra) # 80003af2 <iupdate>
  iunlock(ip);
    80005886:	8526                	mv	a0,s1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	3f6080e7          	jalr	1014(ra) # 80003c7e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005890:	fd040593          	addi	a1,s0,-48
    80005894:	f5040513          	addi	a0,s0,-176
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	af8080e7          	jalr	-1288(ra) # 80004390 <nameiparent>
    800058a0:	892a                	mv	s2,a0
    800058a2:	c935                	beqz	a0,80005916 <sys_link+0x10a>
  ilock(dp);
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	318080e7          	jalr	792(ra) # 80003bbc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058ac:	00092703          	lw	a4,0(s2)
    800058b0:	409c                	lw	a5,0(s1)
    800058b2:	04f71d63          	bne	a4,a5,8000590c <sys_link+0x100>
    800058b6:	40d0                	lw	a2,4(s1)
    800058b8:	fd040593          	addi	a1,s0,-48
    800058bc:	854a                	mv	a0,s2
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	9f2080e7          	jalr	-1550(ra) # 800042b0 <dirlink>
    800058c6:	04054363          	bltz	a0,8000590c <sys_link+0x100>
  iunlockput(dp);
    800058ca:	854a                	mv	a0,s2
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	552080e7          	jalr	1362(ra) # 80003e1e <iunlockput>
  iput(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	4a0080e7          	jalr	1184(ra) # 80003d76 <iput>
  end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	d30080e7          	jalr	-720(ra) # 8000460e <end_op>
  return 0;
    800058e6:	4781                	li	a5,0
    800058e8:	a085                	j	80005948 <sys_link+0x13c>
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	d24080e7          	jalr	-732(ra) # 8000460e <end_op>
    return -1;
    800058f2:	57fd                	li	a5,-1
    800058f4:	a891                	j	80005948 <sys_link+0x13c>
    iunlockput(ip);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	526080e7          	jalr	1318(ra) # 80003e1e <iunlockput>
    end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	d0e080e7          	jalr	-754(ra) # 8000460e <end_op>
    return -1;
    80005908:	57fd                	li	a5,-1
    8000590a:	a83d                	j	80005948 <sys_link+0x13c>
    iunlockput(dp);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	510080e7          	jalr	1296(ra) # 80003e1e <iunlockput>
  ilock(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	2a4080e7          	jalr	676(ra) # 80003bbc <ilock>
  ip->nlink--;
    80005920:	04a4d783          	lhu	a5,74(s1)
    80005924:	37fd                	addiw	a5,a5,-1
    80005926:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	1c6080e7          	jalr	454(ra) # 80003af2 <iupdate>
  iunlockput(ip);
    80005934:	8526                	mv	a0,s1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	4e8080e7          	jalr	1256(ra) # 80003e1e <iunlockput>
  end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	cd0080e7          	jalr	-816(ra) # 8000460e <end_op>
  return -1;
    80005946:	57fd                	li	a5,-1
}
    80005948:	853e                	mv	a0,a5
    8000594a:	70b2                	ld	ra,296(sp)
    8000594c:	7412                	ld	s0,288(sp)
    8000594e:	64f2                	ld	s1,280(sp)
    80005950:	6952                	ld	s2,272(sp)
    80005952:	6155                	addi	sp,sp,304
    80005954:	8082                	ret

0000000080005956 <sys_unlink>:
{
    80005956:	7151                	addi	sp,sp,-240
    80005958:	f586                	sd	ra,232(sp)
    8000595a:	f1a2                	sd	s0,224(sp)
    8000595c:	eda6                	sd	s1,216(sp)
    8000595e:	e9ca                	sd	s2,208(sp)
    80005960:	e5ce                	sd	s3,200(sp)
    80005962:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005964:	08000613          	li	a2,128
    80005968:	f3040593          	addi	a1,s0,-208
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	4d6080e7          	jalr	1238(ra) # 80002e44 <argstr>
    80005976:	18054163          	bltz	a0,80005af8 <sys_unlink+0x1a2>
  begin_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	c14080e7          	jalr	-1004(ra) # 8000458e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005982:	fb040593          	addi	a1,s0,-80
    80005986:	f3040513          	addi	a0,s0,-208
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	a06080e7          	jalr	-1530(ra) # 80004390 <nameiparent>
    80005992:	84aa                	mv	s1,a0
    80005994:	c979                	beqz	a0,80005a6a <sys_unlink+0x114>
  ilock(dp);
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	226080e7          	jalr	550(ra) # 80003bbc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000599e:	00003597          	auipc	a1,0x3
    800059a2:	e5a58593          	addi	a1,a1,-422 # 800087f8 <syscalls+0x2c0>
    800059a6:	fb040513          	addi	a0,s0,-80
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	6dc080e7          	jalr	1756(ra) # 80004086 <namecmp>
    800059b2:	14050a63          	beqz	a0,80005b06 <sys_unlink+0x1b0>
    800059b6:	00003597          	auipc	a1,0x3
    800059ba:	e4a58593          	addi	a1,a1,-438 # 80008800 <syscalls+0x2c8>
    800059be:	fb040513          	addi	a0,s0,-80
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	6c4080e7          	jalr	1732(ra) # 80004086 <namecmp>
    800059ca:	12050e63          	beqz	a0,80005b06 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059ce:	f2c40613          	addi	a2,s0,-212
    800059d2:	fb040593          	addi	a1,s0,-80
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	6c8080e7          	jalr	1736(ra) # 800040a0 <dirlookup>
    800059e0:	892a                	mv	s2,a0
    800059e2:	12050263          	beqz	a0,80005b06 <sys_unlink+0x1b0>
  ilock(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	1d6080e7          	jalr	470(ra) # 80003bbc <ilock>
  if(ip->nlink < 1)
    800059ee:	04a91783          	lh	a5,74(s2)
    800059f2:	08f05263          	blez	a5,80005a76 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059f6:	04491703          	lh	a4,68(s2)
    800059fa:	4785                	li	a5,1
    800059fc:	08f70563          	beq	a4,a5,80005a86 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a00:	4641                	li	a2,16
    80005a02:	4581                	li	a1,0
    80005a04:	fc040513          	addi	a0,s0,-64
    80005a08:	ffffb097          	auipc	ra,0xffffb
    80005a0c:	2d8080e7          	jalr	728(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a10:	4741                	li	a4,16
    80005a12:	f2c42683          	lw	a3,-212(s0)
    80005a16:	fc040613          	addi	a2,s0,-64
    80005a1a:	4581                	li	a1,0
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	54a080e7          	jalr	1354(ra) # 80003f68 <writei>
    80005a26:	47c1                	li	a5,16
    80005a28:	0af51563          	bne	a0,a5,80005ad2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a2c:	04491703          	lh	a4,68(s2)
    80005a30:	4785                	li	a5,1
    80005a32:	0af70863          	beq	a4,a5,80005ae2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	3e6080e7          	jalr	998(ra) # 80003e1e <iunlockput>
  ip->nlink--;
    80005a40:	04a95783          	lhu	a5,74(s2)
    80005a44:	37fd                	addiw	a5,a5,-1
    80005a46:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	0a6080e7          	jalr	166(ra) # 80003af2 <iupdate>
  iunlockput(ip);
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	3c8080e7          	jalr	968(ra) # 80003e1e <iunlockput>
  end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	bb0080e7          	jalr	-1104(ra) # 8000460e <end_op>
  return 0;
    80005a66:	4501                	li	a0,0
    80005a68:	a84d                	j	80005b1a <sys_unlink+0x1c4>
    end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	ba4080e7          	jalr	-1116(ra) # 8000460e <end_op>
    return -1;
    80005a72:	557d                	li	a0,-1
    80005a74:	a05d                	j	80005b1a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a76:	00003517          	auipc	a0,0x3
    80005a7a:	db250513          	addi	a0,a0,-590 # 80008828 <syscalls+0x2f0>
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a86:	04c92703          	lw	a4,76(s2)
    80005a8a:	02000793          	li	a5,32
    80005a8e:	f6e7f9e3          	bgeu	a5,a4,80005a00 <sys_unlink+0xaa>
    80005a92:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a96:	4741                	li	a4,16
    80005a98:	86ce                	mv	a3,s3
    80005a9a:	f1840613          	addi	a2,s0,-232
    80005a9e:	4581                	li	a1,0
    80005aa0:	854a                	mv	a0,s2
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	3ce080e7          	jalr	974(ra) # 80003e70 <readi>
    80005aaa:	47c1                	li	a5,16
    80005aac:	00f51b63          	bne	a0,a5,80005ac2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ab0:	f1845783          	lhu	a5,-232(s0)
    80005ab4:	e7a1                	bnez	a5,80005afc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ab6:	29c1                	addiw	s3,s3,16
    80005ab8:	04c92783          	lw	a5,76(s2)
    80005abc:	fcf9ede3          	bltu	s3,a5,80005a96 <sys_unlink+0x140>
    80005ac0:	b781                	j	80005a00 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ac2:	00003517          	auipc	a0,0x3
    80005ac6:	d7e50513          	addi	a0,a0,-642 # 80008840 <syscalls+0x308>
    80005aca:	ffffb097          	auipc	ra,0xffffb
    80005ace:	a74080e7          	jalr	-1420(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ad2:	00003517          	auipc	a0,0x3
    80005ad6:	d8650513          	addi	a0,a0,-634 # 80008858 <syscalls+0x320>
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	a64080e7          	jalr	-1436(ra) # 8000053e <panic>
    dp->nlink--;
    80005ae2:	04a4d783          	lhu	a5,74(s1)
    80005ae6:	37fd                	addiw	a5,a5,-1
    80005ae8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005aec:	8526                	mv	a0,s1
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	004080e7          	jalr	4(ra) # 80003af2 <iupdate>
    80005af6:	b781                	j	80005a36 <sys_unlink+0xe0>
    return -1;
    80005af8:	557d                	li	a0,-1
    80005afa:	a005                	j	80005b1a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005afc:	854a                	mv	a0,s2
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	320080e7          	jalr	800(ra) # 80003e1e <iunlockput>
  iunlockput(dp);
    80005b06:	8526                	mv	a0,s1
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	316080e7          	jalr	790(ra) # 80003e1e <iunlockput>
  end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	afe080e7          	jalr	-1282(ra) # 8000460e <end_op>
  return -1;
    80005b18:	557d                	li	a0,-1
}
    80005b1a:	70ae                	ld	ra,232(sp)
    80005b1c:	740e                	ld	s0,224(sp)
    80005b1e:	64ee                	ld	s1,216(sp)
    80005b20:	694e                	ld	s2,208(sp)
    80005b22:	69ae                	ld	s3,200(sp)
    80005b24:	616d                	addi	sp,sp,240
    80005b26:	8082                	ret

0000000080005b28 <sys_open>:

uint64
sys_open(void)
{
    80005b28:	7131                	addi	sp,sp,-192
    80005b2a:	fd06                	sd	ra,184(sp)
    80005b2c:	f922                	sd	s0,176(sp)
    80005b2e:	f526                	sd	s1,168(sp)
    80005b30:	f14a                	sd	s2,160(sp)
    80005b32:	ed4e                	sd	s3,152(sp)
    80005b34:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b36:	08000613          	li	a2,128
    80005b3a:	f5040593          	addi	a1,s0,-176
    80005b3e:	4501                	li	a0,0
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	304080e7          	jalr	772(ra) # 80002e44 <argstr>
    return -1;
    80005b48:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b4a:	0c054163          	bltz	a0,80005c0c <sys_open+0xe4>
    80005b4e:	f4c40593          	addi	a1,s0,-180
    80005b52:	4505                	li	a0,1
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	2ac080e7          	jalr	684(ra) # 80002e00 <argint>
    80005b5c:	0a054863          	bltz	a0,80005c0c <sys_open+0xe4>

  begin_op();
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	a2e080e7          	jalr	-1490(ra) # 8000458e <begin_op>

  if(omode & O_CREATE){
    80005b68:	f4c42783          	lw	a5,-180(s0)
    80005b6c:	2007f793          	andi	a5,a5,512
    80005b70:	cbdd                	beqz	a5,80005c26 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b72:	4681                	li	a3,0
    80005b74:	4601                	li	a2,0
    80005b76:	4589                	li	a1,2
    80005b78:	f5040513          	addi	a0,s0,-176
    80005b7c:	00000097          	auipc	ra,0x0
    80005b80:	972080e7          	jalr	-1678(ra) # 800054ee <create>
    80005b84:	892a                	mv	s2,a0
    if(ip == 0){
    80005b86:	c959                	beqz	a0,80005c1c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b88:	04491703          	lh	a4,68(s2)
    80005b8c:	478d                	li	a5,3
    80005b8e:	00f71763          	bne	a4,a5,80005b9c <sys_open+0x74>
    80005b92:	04695703          	lhu	a4,70(s2)
    80005b96:	47a5                	li	a5,9
    80005b98:	0ce7ec63          	bltu	a5,a4,80005c70 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	e02080e7          	jalr	-510(ra) # 8000499e <filealloc>
    80005ba4:	89aa                	mv	s3,a0
    80005ba6:	10050263          	beqz	a0,80005caa <sys_open+0x182>
    80005baa:	00000097          	auipc	ra,0x0
    80005bae:	902080e7          	jalr	-1790(ra) # 800054ac <fdalloc>
    80005bb2:	84aa                	mv	s1,a0
    80005bb4:	0e054663          	bltz	a0,80005ca0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bb8:	04491703          	lh	a4,68(s2)
    80005bbc:	478d                	li	a5,3
    80005bbe:	0cf70463          	beq	a4,a5,80005c86 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bc2:	4789                	li	a5,2
    80005bc4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bc8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bcc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bd0:	f4c42783          	lw	a5,-180(s0)
    80005bd4:	0017c713          	xori	a4,a5,1
    80005bd8:	8b05                	andi	a4,a4,1
    80005bda:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bde:	0037f713          	andi	a4,a5,3
    80005be2:	00e03733          	snez	a4,a4
    80005be6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bea:	4007f793          	andi	a5,a5,1024
    80005bee:	c791                	beqz	a5,80005bfa <sys_open+0xd2>
    80005bf0:	04491703          	lh	a4,68(s2)
    80005bf4:	4789                	li	a5,2
    80005bf6:	08f70f63          	beq	a4,a5,80005c94 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bfa:	854a                	mv	a0,s2
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	082080e7          	jalr	130(ra) # 80003c7e <iunlock>
  end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	a0a080e7          	jalr	-1526(ra) # 8000460e <end_op>

  return fd;
}
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	70ea                	ld	ra,184(sp)
    80005c10:	744a                	ld	s0,176(sp)
    80005c12:	74aa                	ld	s1,168(sp)
    80005c14:	790a                	ld	s2,160(sp)
    80005c16:	69ea                	ld	s3,152(sp)
    80005c18:	6129                	addi	sp,sp,192
    80005c1a:	8082                	ret
      end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	9f2080e7          	jalr	-1550(ra) # 8000460e <end_op>
      return -1;
    80005c24:	b7e5                	j	80005c0c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c26:	f5040513          	addi	a0,s0,-176
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	748080e7          	jalr	1864(ra) # 80004372 <namei>
    80005c32:	892a                	mv	s2,a0
    80005c34:	c905                	beqz	a0,80005c64 <sys_open+0x13c>
    ilock(ip);
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	f86080e7          	jalr	-122(ra) # 80003bbc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c3e:	04491703          	lh	a4,68(s2)
    80005c42:	4785                	li	a5,1
    80005c44:	f4f712e3          	bne	a4,a5,80005b88 <sys_open+0x60>
    80005c48:	f4c42783          	lw	a5,-180(s0)
    80005c4c:	dba1                	beqz	a5,80005b9c <sys_open+0x74>
      iunlockput(ip);
    80005c4e:	854a                	mv	a0,s2
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	1ce080e7          	jalr	462(ra) # 80003e1e <iunlockput>
      end_op();
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	9b6080e7          	jalr	-1610(ra) # 8000460e <end_op>
      return -1;
    80005c60:	54fd                	li	s1,-1
    80005c62:	b76d                	j	80005c0c <sys_open+0xe4>
      end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	9aa080e7          	jalr	-1622(ra) # 8000460e <end_op>
      return -1;
    80005c6c:	54fd                	li	s1,-1
    80005c6e:	bf79                	j	80005c0c <sys_open+0xe4>
    iunlockput(ip);
    80005c70:	854a                	mv	a0,s2
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	1ac080e7          	jalr	428(ra) # 80003e1e <iunlockput>
    end_op();
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	994080e7          	jalr	-1644(ra) # 8000460e <end_op>
    return -1;
    80005c82:	54fd                	li	s1,-1
    80005c84:	b761                	j	80005c0c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c86:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c8a:	04691783          	lh	a5,70(s2)
    80005c8e:	02f99223          	sh	a5,36(s3)
    80005c92:	bf2d                	j	80005bcc <sys_open+0xa4>
    itrunc(ip);
    80005c94:	854a                	mv	a0,s2
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	034080e7          	jalr	52(ra) # 80003cca <itrunc>
    80005c9e:	bfb1                	j	80005bfa <sys_open+0xd2>
      fileclose(f);
    80005ca0:	854e                	mv	a0,s3
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	db8080e7          	jalr	-584(ra) # 80004a5a <fileclose>
    iunlockput(ip);
    80005caa:	854a                	mv	a0,s2
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	172080e7          	jalr	370(ra) # 80003e1e <iunlockput>
    end_op();
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	95a080e7          	jalr	-1702(ra) # 8000460e <end_op>
    return -1;
    80005cbc:	54fd                	li	s1,-1
    80005cbe:	b7b9                	j	80005c0c <sys_open+0xe4>

0000000080005cc0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cc0:	7175                	addi	sp,sp,-144
    80005cc2:	e506                	sd	ra,136(sp)
    80005cc4:	e122                	sd	s0,128(sp)
    80005cc6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	8c6080e7          	jalr	-1850(ra) # 8000458e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cd0:	08000613          	li	a2,128
    80005cd4:	f7040593          	addi	a1,s0,-144
    80005cd8:	4501                	li	a0,0
    80005cda:	ffffd097          	auipc	ra,0xffffd
    80005cde:	16a080e7          	jalr	362(ra) # 80002e44 <argstr>
    80005ce2:	02054963          	bltz	a0,80005d14 <sys_mkdir+0x54>
    80005ce6:	4681                	li	a3,0
    80005ce8:	4601                	li	a2,0
    80005cea:	4585                	li	a1,1
    80005cec:	f7040513          	addi	a0,s0,-144
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	7fe080e7          	jalr	2046(ra) # 800054ee <create>
    80005cf8:	cd11                	beqz	a0,80005d14 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	124080e7          	jalr	292(ra) # 80003e1e <iunlockput>
  end_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	90c080e7          	jalr	-1780(ra) # 8000460e <end_op>
  return 0;
    80005d0a:	4501                	li	a0,0
}
    80005d0c:	60aa                	ld	ra,136(sp)
    80005d0e:	640a                	ld	s0,128(sp)
    80005d10:	6149                	addi	sp,sp,144
    80005d12:	8082                	ret
    end_op();
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	8fa080e7          	jalr	-1798(ra) # 8000460e <end_op>
    return -1;
    80005d1c:	557d                	li	a0,-1
    80005d1e:	b7fd                	j	80005d0c <sys_mkdir+0x4c>

0000000080005d20 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d20:	7135                	addi	sp,sp,-160
    80005d22:	ed06                	sd	ra,152(sp)
    80005d24:	e922                	sd	s0,144(sp)
    80005d26:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	866080e7          	jalr	-1946(ra) # 8000458e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d30:	08000613          	li	a2,128
    80005d34:	f7040593          	addi	a1,s0,-144
    80005d38:	4501                	li	a0,0
    80005d3a:	ffffd097          	auipc	ra,0xffffd
    80005d3e:	10a080e7          	jalr	266(ra) # 80002e44 <argstr>
    80005d42:	04054a63          	bltz	a0,80005d96 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d46:	f6c40593          	addi	a1,s0,-148
    80005d4a:	4505                	li	a0,1
    80005d4c:	ffffd097          	auipc	ra,0xffffd
    80005d50:	0b4080e7          	jalr	180(ra) # 80002e00 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d54:	04054163          	bltz	a0,80005d96 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d58:	f6840593          	addi	a1,s0,-152
    80005d5c:	4509                	li	a0,2
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	0a2080e7          	jalr	162(ra) # 80002e00 <argint>
     argint(1, &major) < 0 ||
    80005d66:	02054863          	bltz	a0,80005d96 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d6a:	f6841683          	lh	a3,-152(s0)
    80005d6e:	f6c41603          	lh	a2,-148(s0)
    80005d72:	458d                	li	a1,3
    80005d74:	f7040513          	addi	a0,s0,-144
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	776080e7          	jalr	1910(ra) # 800054ee <create>
     argint(2, &minor) < 0 ||
    80005d80:	c919                	beqz	a0,80005d96 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	09c080e7          	jalr	156(ra) # 80003e1e <iunlockput>
  end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	884080e7          	jalr	-1916(ra) # 8000460e <end_op>
  return 0;
    80005d92:	4501                	li	a0,0
    80005d94:	a031                	j	80005da0 <sys_mknod+0x80>
    end_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	878080e7          	jalr	-1928(ra) # 8000460e <end_op>
    return -1;
    80005d9e:	557d                	li	a0,-1
}
    80005da0:	60ea                	ld	ra,152(sp)
    80005da2:	644a                	ld	s0,144(sp)
    80005da4:	610d                	addi	sp,sp,160
    80005da6:	8082                	ret

0000000080005da8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005da8:	7135                	addi	sp,sp,-160
    80005daa:	ed06                	sd	ra,152(sp)
    80005dac:	e922                	sd	s0,144(sp)
    80005dae:	e526                	sd	s1,136(sp)
    80005db0:	e14a                	sd	s2,128(sp)
    80005db2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005db4:	ffffc097          	auipc	ra,0xffffc
    80005db8:	bfc080e7          	jalr	-1028(ra) # 800019b0 <myproc>
    80005dbc:	892a                	mv	s2,a0
  
  begin_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	7d0080e7          	jalr	2000(ra) # 8000458e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dc6:	08000613          	li	a2,128
    80005dca:	f6040593          	addi	a1,s0,-160
    80005dce:	4501                	li	a0,0
    80005dd0:	ffffd097          	auipc	ra,0xffffd
    80005dd4:	074080e7          	jalr	116(ra) # 80002e44 <argstr>
    80005dd8:	04054b63          	bltz	a0,80005e2e <sys_chdir+0x86>
    80005ddc:	f6040513          	addi	a0,s0,-160
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	592080e7          	jalr	1426(ra) # 80004372 <namei>
    80005de8:	84aa                	mv	s1,a0
    80005dea:	c131                	beqz	a0,80005e2e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	dd0080e7          	jalr	-560(ra) # 80003bbc <ilock>
  if(ip->type != T_DIR){
    80005df4:	04449703          	lh	a4,68(s1)
    80005df8:	4785                	li	a5,1
    80005dfa:	04f71063          	bne	a4,a5,80005e3a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	e7e080e7          	jalr	-386(ra) # 80003c7e <iunlock>
  iput(p->cwd);
    80005e08:	15093503          	ld	a0,336(s2)
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	f6a080e7          	jalr	-150(ra) # 80003d76 <iput>
  end_op();
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	7fa080e7          	jalr	2042(ra) # 8000460e <end_op>
  p->cwd = ip;
    80005e1c:	14993823          	sd	s1,336(s2)
  return 0;
    80005e20:	4501                	li	a0,0
}
    80005e22:	60ea                	ld	ra,152(sp)
    80005e24:	644a                	ld	s0,144(sp)
    80005e26:	64aa                	ld	s1,136(sp)
    80005e28:	690a                	ld	s2,128(sp)
    80005e2a:	610d                	addi	sp,sp,160
    80005e2c:	8082                	ret
    end_op();
    80005e2e:	ffffe097          	auipc	ra,0xffffe
    80005e32:	7e0080e7          	jalr	2016(ra) # 8000460e <end_op>
    return -1;
    80005e36:	557d                	li	a0,-1
    80005e38:	b7ed                	j	80005e22 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e3a:	8526                	mv	a0,s1
    80005e3c:	ffffe097          	auipc	ra,0xffffe
    80005e40:	fe2080e7          	jalr	-30(ra) # 80003e1e <iunlockput>
    end_op();
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	7ca080e7          	jalr	1994(ra) # 8000460e <end_op>
    return -1;
    80005e4c:	557d                	li	a0,-1
    80005e4e:	bfd1                	j	80005e22 <sys_chdir+0x7a>

0000000080005e50 <sys_exec>:

uint64
sys_exec(void)
{
    80005e50:	7145                	addi	sp,sp,-464
    80005e52:	e786                	sd	ra,456(sp)
    80005e54:	e3a2                	sd	s0,448(sp)
    80005e56:	ff26                	sd	s1,440(sp)
    80005e58:	fb4a                	sd	s2,432(sp)
    80005e5a:	f74e                	sd	s3,424(sp)
    80005e5c:	f352                	sd	s4,416(sp)
    80005e5e:	ef56                	sd	s5,408(sp)
    80005e60:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e62:	08000613          	li	a2,128
    80005e66:	f4040593          	addi	a1,s0,-192
    80005e6a:	4501                	li	a0,0
    80005e6c:	ffffd097          	auipc	ra,0xffffd
    80005e70:	fd8080e7          	jalr	-40(ra) # 80002e44 <argstr>
    return -1;
    80005e74:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e76:	0c054a63          	bltz	a0,80005f4a <sys_exec+0xfa>
    80005e7a:	e3840593          	addi	a1,s0,-456
    80005e7e:	4505                	li	a0,1
    80005e80:	ffffd097          	auipc	ra,0xffffd
    80005e84:	fa2080e7          	jalr	-94(ra) # 80002e22 <argaddr>
    80005e88:	0c054163          	bltz	a0,80005f4a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e8c:	10000613          	li	a2,256
    80005e90:	4581                	li	a1,0
    80005e92:	e4040513          	addi	a0,s0,-448
    80005e96:	ffffb097          	auipc	ra,0xffffb
    80005e9a:	e4a080e7          	jalr	-438(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e9e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ea2:	89a6                	mv	s3,s1
    80005ea4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ea6:	02000a13          	li	s4,32
    80005eaa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005eae:	00391513          	slli	a0,s2,0x3
    80005eb2:	e3040593          	addi	a1,s0,-464
    80005eb6:	e3843783          	ld	a5,-456(s0)
    80005eba:	953e                	add	a0,a0,a5
    80005ebc:	ffffd097          	auipc	ra,0xffffd
    80005ec0:	eaa080e7          	jalr	-342(ra) # 80002d66 <fetchaddr>
    80005ec4:	02054a63          	bltz	a0,80005ef8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ec8:	e3043783          	ld	a5,-464(s0)
    80005ecc:	c3b9                	beqz	a5,80005f12 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	c26080e7          	jalr	-986(ra) # 80000af4 <kalloc>
    80005ed6:	85aa                	mv	a1,a0
    80005ed8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005edc:	cd11                	beqz	a0,80005ef8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ede:	6605                	lui	a2,0x1
    80005ee0:	e3043503          	ld	a0,-464(s0)
    80005ee4:	ffffd097          	auipc	ra,0xffffd
    80005ee8:	ed4080e7          	jalr	-300(ra) # 80002db8 <fetchstr>
    80005eec:	00054663          	bltz	a0,80005ef8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ef0:	0905                	addi	s2,s2,1
    80005ef2:	09a1                	addi	s3,s3,8
    80005ef4:	fb491be3          	bne	s2,s4,80005eaa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef8:	10048913          	addi	s2,s1,256
    80005efc:	6088                	ld	a0,0(s1)
    80005efe:	c529                	beqz	a0,80005f48 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	af8080e7          	jalr	-1288(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f08:	04a1                	addi	s1,s1,8
    80005f0a:	ff2499e3          	bne	s1,s2,80005efc <sys_exec+0xac>
  return -1;
    80005f0e:	597d                	li	s2,-1
    80005f10:	a82d                	j	80005f4a <sys_exec+0xfa>
      argv[i] = 0;
    80005f12:	0a8e                	slli	s5,s5,0x3
    80005f14:	fc040793          	addi	a5,s0,-64
    80005f18:	9abe                	add	s5,s5,a5
    80005f1a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f1e:	e4040593          	addi	a1,s0,-448
    80005f22:	f4040513          	addi	a0,s0,-192
    80005f26:	fffff097          	auipc	ra,0xfffff
    80005f2a:	194080e7          	jalr	404(ra) # 800050ba <exec>
    80005f2e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f30:	10048993          	addi	s3,s1,256
    80005f34:	6088                	ld	a0,0(s1)
    80005f36:	c911                	beqz	a0,80005f4a <sys_exec+0xfa>
    kfree(argv[i]);
    80005f38:	ffffb097          	auipc	ra,0xffffb
    80005f3c:	ac0080e7          	jalr	-1344(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f40:	04a1                	addi	s1,s1,8
    80005f42:	ff3499e3          	bne	s1,s3,80005f34 <sys_exec+0xe4>
    80005f46:	a011                	j	80005f4a <sys_exec+0xfa>
  return -1;
    80005f48:	597d                	li	s2,-1
}
    80005f4a:	854a                	mv	a0,s2
    80005f4c:	60be                	ld	ra,456(sp)
    80005f4e:	641e                	ld	s0,448(sp)
    80005f50:	74fa                	ld	s1,440(sp)
    80005f52:	795a                	ld	s2,432(sp)
    80005f54:	79ba                	ld	s3,424(sp)
    80005f56:	7a1a                	ld	s4,416(sp)
    80005f58:	6afa                	ld	s5,408(sp)
    80005f5a:	6179                	addi	sp,sp,464
    80005f5c:	8082                	ret

0000000080005f5e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f5e:	7139                	addi	sp,sp,-64
    80005f60:	fc06                	sd	ra,56(sp)
    80005f62:	f822                	sd	s0,48(sp)
    80005f64:	f426                	sd	s1,40(sp)
    80005f66:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	a48080e7          	jalr	-1464(ra) # 800019b0 <myproc>
    80005f70:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f72:	fd840593          	addi	a1,s0,-40
    80005f76:	4501                	li	a0,0
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	eaa080e7          	jalr	-342(ra) # 80002e22 <argaddr>
    return -1;
    80005f80:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f82:	0e054063          	bltz	a0,80006062 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f86:	fc840593          	addi	a1,s0,-56
    80005f8a:	fd040513          	addi	a0,s0,-48
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	dfc080e7          	jalr	-516(ra) # 80004d8a <pipealloc>
    return -1;
    80005f96:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f98:	0c054563          	bltz	a0,80006062 <sys_pipe+0x104>
  fd0 = -1;
    80005f9c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fa0:	fd043503          	ld	a0,-48(s0)
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	508080e7          	jalr	1288(ra) # 800054ac <fdalloc>
    80005fac:	fca42223          	sw	a0,-60(s0)
    80005fb0:	08054c63          	bltz	a0,80006048 <sys_pipe+0xea>
    80005fb4:	fc843503          	ld	a0,-56(s0)
    80005fb8:	fffff097          	auipc	ra,0xfffff
    80005fbc:	4f4080e7          	jalr	1268(ra) # 800054ac <fdalloc>
    80005fc0:	fca42023          	sw	a0,-64(s0)
    80005fc4:	06054863          	bltz	a0,80006034 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fc8:	4691                	li	a3,4
    80005fca:	fc440613          	addi	a2,s0,-60
    80005fce:	fd843583          	ld	a1,-40(s0)
    80005fd2:	68a8                	ld	a0,80(s1)
    80005fd4:	ffffb097          	auipc	ra,0xffffb
    80005fd8:	69e080e7          	jalr	1694(ra) # 80001672 <copyout>
    80005fdc:	02054063          	bltz	a0,80005ffc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fe0:	4691                	li	a3,4
    80005fe2:	fc040613          	addi	a2,s0,-64
    80005fe6:	fd843583          	ld	a1,-40(s0)
    80005fea:	0591                	addi	a1,a1,4
    80005fec:	68a8                	ld	a0,80(s1)
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	684080e7          	jalr	1668(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ff6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ff8:	06055563          	bgez	a0,80006062 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ffc:	fc442783          	lw	a5,-60(s0)
    80006000:	07e9                	addi	a5,a5,26
    80006002:	078e                	slli	a5,a5,0x3
    80006004:	97a6                	add	a5,a5,s1
    80006006:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000600a:	fc042503          	lw	a0,-64(s0)
    8000600e:	0569                	addi	a0,a0,26
    80006010:	050e                	slli	a0,a0,0x3
    80006012:	9526                	add	a0,a0,s1
    80006014:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006018:	fd043503          	ld	a0,-48(s0)
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	a3e080e7          	jalr	-1474(ra) # 80004a5a <fileclose>
    fileclose(wf);
    80006024:	fc843503          	ld	a0,-56(s0)
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	a32080e7          	jalr	-1486(ra) # 80004a5a <fileclose>
    return -1;
    80006030:	57fd                	li	a5,-1
    80006032:	a805                	j	80006062 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006034:	fc442783          	lw	a5,-60(s0)
    80006038:	0007c863          	bltz	a5,80006048 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000603c:	01a78513          	addi	a0,a5,26
    80006040:	050e                	slli	a0,a0,0x3
    80006042:	9526                	add	a0,a0,s1
    80006044:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006048:	fd043503          	ld	a0,-48(s0)
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	a0e080e7          	jalr	-1522(ra) # 80004a5a <fileclose>
    fileclose(wf);
    80006054:	fc843503          	ld	a0,-56(s0)
    80006058:	fffff097          	auipc	ra,0xfffff
    8000605c:	a02080e7          	jalr	-1534(ra) # 80004a5a <fileclose>
    return -1;
    80006060:	57fd                	li	a5,-1
}
    80006062:	853e                	mv	a0,a5
    80006064:	70e2                	ld	ra,56(sp)
    80006066:	7442                	ld	s0,48(sp)
    80006068:	74a2                	ld	s1,40(sp)
    8000606a:	6121                	addi	sp,sp,64
    8000606c:	8082                	ret
	...

0000000080006070 <kernelvec>:
    80006070:	7111                	addi	sp,sp,-256
    80006072:	e006                	sd	ra,0(sp)
    80006074:	e40a                	sd	sp,8(sp)
    80006076:	e80e                	sd	gp,16(sp)
    80006078:	ec12                	sd	tp,24(sp)
    8000607a:	f016                	sd	t0,32(sp)
    8000607c:	f41a                	sd	t1,40(sp)
    8000607e:	f81e                	sd	t2,48(sp)
    80006080:	fc22                	sd	s0,56(sp)
    80006082:	e0a6                	sd	s1,64(sp)
    80006084:	e4aa                	sd	a0,72(sp)
    80006086:	e8ae                	sd	a1,80(sp)
    80006088:	ecb2                	sd	a2,88(sp)
    8000608a:	f0b6                	sd	a3,96(sp)
    8000608c:	f4ba                	sd	a4,104(sp)
    8000608e:	f8be                	sd	a5,112(sp)
    80006090:	fcc2                	sd	a6,120(sp)
    80006092:	e146                	sd	a7,128(sp)
    80006094:	e54a                	sd	s2,136(sp)
    80006096:	e94e                	sd	s3,144(sp)
    80006098:	ed52                	sd	s4,152(sp)
    8000609a:	f156                	sd	s5,160(sp)
    8000609c:	f55a                	sd	s6,168(sp)
    8000609e:	f95e                	sd	s7,176(sp)
    800060a0:	fd62                	sd	s8,184(sp)
    800060a2:	e1e6                	sd	s9,192(sp)
    800060a4:	e5ea                	sd	s10,200(sp)
    800060a6:	e9ee                	sd	s11,208(sp)
    800060a8:	edf2                	sd	t3,216(sp)
    800060aa:	f1f6                	sd	t4,224(sp)
    800060ac:	f5fa                	sd	t5,232(sp)
    800060ae:	f9fe                	sd	t6,240(sp)
    800060b0:	badfc0ef          	jal	ra,80002c5c <kerneltrap>
    800060b4:	6082                	ld	ra,0(sp)
    800060b6:	6122                	ld	sp,8(sp)
    800060b8:	61c2                	ld	gp,16(sp)
    800060ba:	7282                	ld	t0,32(sp)
    800060bc:	7322                	ld	t1,40(sp)
    800060be:	73c2                	ld	t2,48(sp)
    800060c0:	7462                	ld	s0,56(sp)
    800060c2:	6486                	ld	s1,64(sp)
    800060c4:	6526                	ld	a0,72(sp)
    800060c6:	65c6                	ld	a1,80(sp)
    800060c8:	6666                	ld	a2,88(sp)
    800060ca:	7686                	ld	a3,96(sp)
    800060cc:	7726                	ld	a4,104(sp)
    800060ce:	77c6                	ld	a5,112(sp)
    800060d0:	7866                	ld	a6,120(sp)
    800060d2:	688a                	ld	a7,128(sp)
    800060d4:	692a                	ld	s2,136(sp)
    800060d6:	69ca                	ld	s3,144(sp)
    800060d8:	6a6a                	ld	s4,152(sp)
    800060da:	7a8a                	ld	s5,160(sp)
    800060dc:	7b2a                	ld	s6,168(sp)
    800060de:	7bca                	ld	s7,176(sp)
    800060e0:	7c6a                	ld	s8,184(sp)
    800060e2:	6c8e                	ld	s9,192(sp)
    800060e4:	6d2e                	ld	s10,200(sp)
    800060e6:	6dce                	ld	s11,208(sp)
    800060e8:	6e6e                	ld	t3,216(sp)
    800060ea:	7e8e                	ld	t4,224(sp)
    800060ec:	7f2e                	ld	t5,232(sp)
    800060ee:	7fce                	ld	t6,240(sp)
    800060f0:	6111                	addi	sp,sp,256
    800060f2:	10200073          	sret
    800060f6:	00000013          	nop
    800060fa:	00000013          	nop
    800060fe:	0001                	nop

0000000080006100 <timervec>:
    80006100:	34051573          	csrrw	a0,mscratch,a0
    80006104:	e10c                	sd	a1,0(a0)
    80006106:	e510                	sd	a2,8(a0)
    80006108:	e914                	sd	a3,16(a0)
    8000610a:	6d0c                	ld	a1,24(a0)
    8000610c:	7110                	ld	a2,32(a0)
    8000610e:	6194                	ld	a3,0(a1)
    80006110:	96b2                	add	a3,a3,a2
    80006112:	e194                	sd	a3,0(a1)
    80006114:	4589                	li	a1,2
    80006116:	14459073          	csrw	sip,a1
    8000611a:	6914                	ld	a3,16(a0)
    8000611c:	6510                	ld	a2,8(a0)
    8000611e:	610c                	ld	a1,0(a0)
    80006120:	34051573          	csrrw	a0,mscratch,a0
    80006124:	30200073          	mret
	...

000000008000612a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000612a:	1141                	addi	sp,sp,-16
    8000612c:	e422                	sd	s0,8(sp)
    8000612e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006130:	0c0007b7          	lui	a5,0xc000
    80006134:	4705                	li	a4,1
    80006136:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006138:	c3d8                	sw	a4,4(a5)
}
    8000613a:	6422                	ld	s0,8(sp)
    8000613c:	0141                	addi	sp,sp,16
    8000613e:	8082                	ret

0000000080006140 <plicinithart>:

void
plicinithart(void)
{
    80006140:	1141                	addi	sp,sp,-16
    80006142:	e406                	sd	ra,8(sp)
    80006144:	e022                	sd	s0,0(sp)
    80006146:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	83c080e7          	jalr	-1988(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006150:	0085171b          	slliw	a4,a0,0x8
    80006154:	0c0027b7          	lui	a5,0xc002
    80006158:	97ba                	add	a5,a5,a4
    8000615a:	40200713          	li	a4,1026
    8000615e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006162:	00d5151b          	slliw	a0,a0,0xd
    80006166:	0c2017b7          	lui	a5,0xc201
    8000616a:	953e                	add	a0,a0,a5
    8000616c:	00052023          	sw	zero,0(a0)
}
    80006170:	60a2                	ld	ra,8(sp)
    80006172:	6402                	ld	s0,0(sp)
    80006174:	0141                	addi	sp,sp,16
    80006176:	8082                	ret

0000000080006178 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006178:	1141                	addi	sp,sp,-16
    8000617a:	e406                	sd	ra,8(sp)
    8000617c:	e022                	sd	s0,0(sp)
    8000617e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006180:	ffffc097          	auipc	ra,0xffffc
    80006184:	804080e7          	jalr	-2044(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006188:	00d5179b          	slliw	a5,a0,0xd
    8000618c:	0c201537          	lui	a0,0xc201
    80006190:	953e                	add	a0,a0,a5
  return irq;
}
    80006192:	4148                	lw	a0,4(a0)
    80006194:	60a2                	ld	ra,8(sp)
    80006196:	6402                	ld	s0,0(sp)
    80006198:	0141                	addi	sp,sp,16
    8000619a:	8082                	ret

000000008000619c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000619c:	1101                	addi	sp,sp,-32
    8000619e:	ec06                	sd	ra,24(sp)
    800061a0:	e822                	sd	s0,16(sp)
    800061a2:	e426                	sd	s1,8(sp)
    800061a4:	1000                	addi	s0,sp,32
    800061a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	7dc080e7          	jalr	2012(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061b0:	00d5151b          	slliw	a0,a0,0xd
    800061b4:	0c2017b7          	lui	a5,0xc201
    800061b8:	97aa                	add	a5,a5,a0
    800061ba:	c3c4                	sw	s1,4(a5)
}
    800061bc:	60e2                	ld	ra,24(sp)
    800061be:	6442                	ld	s0,16(sp)
    800061c0:	64a2                	ld	s1,8(sp)
    800061c2:	6105                	addi	sp,sp,32
    800061c4:	8082                	ret

00000000800061c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061c6:	1141                	addi	sp,sp,-16
    800061c8:	e406                	sd	ra,8(sp)
    800061ca:	e022                	sd	s0,0(sp)
    800061cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ce:	479d                	li	a5,7
    800061d0:	06a7c963          	blt	a5,a0,80006242 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061d4:	0001d797          	auipc	a5,0x1d
    800061d8:	e2c78793          	addi	a5,a5,-468 # 80023000 <disk>
    800061dc:	00a78733          	add	a4,a5,a0
    800061e0:	6789                	lui	a5,0x2
    800061e2:	97ba                	add	a5,a5,a4
    800061e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061e8:	e7ad                	bnez	a5,80006252 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061ea:	00451793          	slli	a5,a0,0x4
    800061ee:	0001f717          	auipc	a4,0x1f
    800061f2:	e1270713          	addi	a4,a4,-494 # 80025000 <disk+0x2000>
    800061f6:	6314                	ld	a3,0(a4)
    800061f8:	96be                	add	a3,a3,a5
    800061fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061fe:	6314                	ld	a3,0(a4)
    80006200:	96be                	add	a3,a3,a5
    80006202:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006206:	6314                	ld	a3,0(a4)
    80006208:	96be                	add	a3,a3,a5
    8000620a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000620e:	6318                	ld	a4,0(a4)
    80006210:	97ba                	add	a5,a5,a4
    80006212:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006216:	0001d797          	auipc	a5,0x1d
    8000621a:	dea78793          	addi	a5,a5,-534 # 80023000 <disk>
    8000621e:	97aa                	add	a5,a5,a0
    80006220:	6509                	lui	a0,0x2
    80006222:	953e                	add	a0,a0,a5
    80006224:	4785                	li	a5,1
    80006226:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000622a:	0001f517          	auipc	a0,0x1f
    8000622e:	dee50513          	addi	a0,a0,-530 # 80025018 <disk+0x2018>
    80006232:	ffffc097          	auipc	ra,0xffffc
    80006236:	2d2080e7          	jalr	722(ra) # 80002504 <wakeup>
}
    8000623a:	60a2                	ld	ra,8(sp)
    8000623c:	6402                	ld	s0,0(sp)
    8000623e:	0141                	addi	sp,sp,16
    80006240:	8082                	ret
    panic("free_desc 1");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	62650513          	addi	a0,a0,1574 # 80008868 <syscalls+0x330>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f4080e7          	jalr	756(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	62650513          	addi	a0,a0,1574 # 80008878 <syscalls+0x340>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e4080e7          	jalr	740(ra) # 8000053e <panic>

0000000080006262 <virtio_disk_init>:
{
    80006262:	1101                	addi	sp,sp,-32
    80006264:	ec06                	sd	ra,24(sp)
    80006266:	e822                	sd	s0,16(sp)
    80006268:	e426                	sd	s1,8(sp)
    8000626a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000626c:	00002597          	auipc	a1,0x2
    80006270:	61c58593          	addi	a1,a1,1564 # 80008888 <syscalls+0x350>
    80006274:	0001f517          	auipc	a0,0x1f
    80006278:	eb450513          	addi	a0,a0,-332 # 80025128 <disk+0x2128>
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	8d8080e7          	jalr	-1832(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006284:	100017b7          	lui	a5,0x10001
    80006288:	4398                	lw	a4,0(a5)
    8000628a:	2701                	sext.w	a4,a4
    8000628c:	747277b7          	lui	a5,0x74727
    80006290:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006294:	0ef71163          	bne	a4,a5,80006376 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006298:	100017b7          	lui	a5,0x10001
    8000629c:	43dc                	lw	a5,4(a5)
    8000629e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062a0:	4705                	li	a4,1
    800062a2:	0ce79a63          	bne	a5,a4,80006376 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062a6:	100017b7          	lui	a5,0x10001
    800062aa:	479c                	lw	a5,8(a5)
    800062ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062ae:	4709                	li	a4,2
    800062b0:	0ce79363          	bne	a5,a4,80006376 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062b4:	100017b7          	lui	a5,0x10001
    800062b8:	47d8                	lw	a4,12(a5)
    800062ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062bc:	554d47b7          	lui	a5,0x554d4
    800062c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062c4:	0af71963          	bne	a4,a5,80006376 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c8:	100017b7          	lui	a5,0x10001
    800062cc:	4705                	li	a4,1
    800062ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062d0:	470d                	li	a4,3
    800062d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062d6:	c7ffe737          	lui	a4,0xc7ffe
    800062da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800062de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062e0:	2701                	sext.w	a4,a4
    800062e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062e4:	472d                	li	a4,11
    800062e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062e8:	473d                	li	a4,15
    800062ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062ec:	6705                	lui	a4,0x1
    800062ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062f4:	5bdc                	lw	a5,52(a5)
    800062f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062f8:	c7d9                	beqz	a5,80006386 <virtio_disk_init+0x124>
  if(max < NUM)
    800062fa:	471d                	li	a4,7
    800062fc:	08f77d63          	bgeu	a4,a5,80006396 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006300:	100014b7          	lui	s1,0x10001
    80006304:	47a1                	li	a5,8
    80006306:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006308:	6609                	lui	a2,0x2
    8000630a:	4581                	li	a1,0
    8000630c:	0001d517          	auipc	a0,0x1d
    80006310:	cf450513          	addi	a0,a0,-780 # 80023000 <disk>
    80006314:	ffffb097          	auipc	ra,0xffffb
    80006318:	9cc080e7          	jalr	-1588(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000631c:	0001d717          	auipc	a4,0x1d
    80006320:	ce470713          	addi	a4,a4,-796 # 80023000 <disk>
    80006324:	00c75793          	srli	a5,a4,0xc
    80006328:	2781                	sext.w	a5,a5
    8000632a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000632c:	0001f797          	auipc	a5,0x1f
    80006330:	cd478793          	addi	a5,a5,-812 # 80025000 <disk+0x2000>
    80006334:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006336:	0001d717          	auipc	a4,0x1d
    8000633a:	d4a70713          	addi	a4,a4,-694 # 80023080 <disk+0x80>
    8000633e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006340:	0001e717          	auipc	a4,0x1e
    80006344:	cc070713          	addi	a4,a4,-832 # 80024000 <disk+0x1000>
    80006348:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000634a:	4705                	li	a4,1
    8000634c:	00e78c23          	sb	a4,24(a5)
    80006350:	00e78ca3          	sb	a4,25(a5)
    80006354:	00e78d23          	sb	a4,26(a5)
    80006358:	00e78da3          	sb	a4,27(a5)
    8000635c:	00e78e23          	sb	a4,28(a5)
    80006360:	00e78ea3          	sb	a4,29(a5)
    80006364:	00e78f23          	sb	a4,30(a5)
    80006368:	00e78fa3          	sb	a4,31(a5)
}
    8000636c:	60e2                	ld	ra,24(sp)
    8000636e:	6442                	ld	s0,16(sp)
    80006370:	64a2                	ld	s1,8(sp)
    80006372:	6105                	addi	sp,sp,32
    80006374:	8082                	ret
    panic("could not find virtio disk");
    80006376:	00002517          	auipc	a0,0x2
    8000637a:	52250513          	addi	a0,a0,1314 # 80008898 <syscalls+0x360>
    8000637e:	ffffa097          	auipc	ra,0xffffa
    80006382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006386:	00002517          	auipc	a0,0x2
    8000638a:	53250513          	addi	a0,a0,1330 # 800088b8 <syscalls+0x380>
    8000638e:	ffffa097          	auipc	ra,0xffffa
    80006392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006396:	00002517          	auipc	a0,0x2
    8000639a:	54250513          	addi	a0,a0,1346 # 800088d8 <syscalls+0x3a0>
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	1a0080e7          	jalr	416(ra) # 8000053e <panic>

00000000800063a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063a6:	7159                	addi	sp,sp,-112
    800063a8:	f486                	sd	ra,104(sp)
    800063aa:	f0a2                	sd	s0,96(sp)
    800063ac:	eca6                	sd	s1,88(sp)
    800063ae:	e8ca                	sd	s2,80(sp)
    800063b0:	e4ce                	sd	s3,72(sp)
    800063b2:	e0d2                	sd	s4,64(sp)
    800063b4:	fc56                	sd	s5,56(sp)
    800063b6:	f85a                	sd	s6,48(sp)
    800063b8:	f45e                	sd	s7,40(sp)
    800063ba:	f062                	sd	s8,32(sp)
    800063bc:	ec66                	sd	s9,24(sp)
    800063be:	e86a                	sd	s10,16(sp)
    800063c0:	1880                	addi	s0,sp,112
    800063c2:	892a                	mv	s2,a0
    800063c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063c6:	00c52c83          	lw	s9,12(a0)
    800063ca:	001c9c9b          	slliw	s9,s9,0x1
    800063ce:	1c82                	slli	s9,s9,0x20
    800063d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063d4:	0001f517          	auipc	a0,0x1f
    800063d8:	d5450513          	addi	a0,a0,-684 # 80025128 <disk+0x2128>
    800063dc:	ffffb097          	auipc	ra,0xffffb
    800063e0:	808080e7          	jalr	-2040(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063e8:	0001db97          	auipc	s7,0x1d
    800063ec:	c18b8b93          	addi	s7,s7,-1000 # 80023000 <disk>
    800063f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063f4:	8a4e                	mv	s4,s3
    800063f6:	a051                	j	8000647a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063f8:	00fb86b3          	add	a3,s7,a5
    800063fc:	96da                	add	a3,a3,s6
    800063fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006402:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006404:	0207c563          	bltz	a5,8000642e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006408:	2485                	addiw	s1,s1,1
    8000640a:	0711                	addi	a4,a4,4
    8000640c:	25548063          	beq	s1,s5,8000664c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006410:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006412:	0001f697          	auipc	a3,0x1f
    80006416:	c0668693          	addi	a3,a3,-1018 # 80025018 <disk+0x2018>
    8000641a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000641c:	0006c583          	lbu	a1,0(a3)
    80006420:	fde1                	bnez	a1,800063f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006422:	2785                	addiw	a5,a5,1
    80006424:	0685                	addi	a3,a3,1
    80006426:	ff879be3          	bne	a5,s8,8000641c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000642a:	57fd                	li	a5,-1
    8000642c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000642e:	02905a63          	blez	s1,80006462 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006432:	f9042503          	lw	a0,-112(s0)
    80006436:	00000097          	auipc	ra,0x0
    8000643a:	d90080e7          	jalr	-624(ra) # 800061c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000643e:	4785                	li	a5,1
    80006440:	0297d163          	bge	a5,s1,80006462 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006444:	f9442503          	lw	a0,-108(s0)
    80006448:	00000097          	auipc	ra,0x0
    8000644c:	d7e080e7          	jalr	-642(ra) # 800061c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006450:	4789                	li	a5,2
    80006452:	0097d863          	bge	a5,s1,80006462 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006456:	f9842503          	lw	a0,-104(s0)
    8000645a:	00000097          	auipc	ra,0x0
    8000645e:	d6c080e7          	jalr	-660(ra) # 800061c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006462:	0001f597          	auipc	a1,0x1f
    80006466:	cc658593          	addi	a1,a1,-826 # 80025128 <disk+0x2128>
    8000646a:	0001f517          	auipc	a0,0x1f
    8000646e:	bae50513          	addi	a0,a0,-1106 # 80025018 <disk+0x2018>
    80006472:	ffffc097          	auipc	ra,0xffffc
    80006476:	dba080e7          	jalr	-582(ra) # 8000222c <sleep>
  for(int i = 0; i < 3; i++){
    8000647a:	f9040713          	addi	a4,s0,-112
    8000647e:	84ce                	mv	s1,s3
    80006480:	bf41                	j	80006410 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006482:	20058713          	addi	a4,a1,512
    80006486:	00471693          	slli	a3,a4,0x4
    8000648a:	0001d717          	auipc	a4,0x1d
    8000648e:	b7670713          	addi	a4,a4,-1162 # 80023000 <disk>
    80006492:	9736                	add	a4,a4,a3
    80006494:	4685                	li	a3,1
    80006496:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000649a:	20058713          	addi	a4,a1,512
    8000649e:	00471693          	slli	a3,a4,0x4
    800064a2:	0001d717          	auipc	a4,0x1d
    800064a6:	b5e70713          	addi	a4,a4,-1186 # 80023000 <disk>
    800064aa:	9736                	add	a4,a4,a3
    800064ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064b4:	7679                	lui	a2,0xffffe
    800064b6:	963e                	add	a2,a2,a5
    800064b8:	0001f697          	auipc	a3,0x1f
    800064bc:	b4868693          	addi	a3,a3,-1208 # 80025000 <disk+0x2000>
    800064c0:	6298                	ld	a4,0(a3)
    800064c2:	9732                	add	a4,a4,a2
    800064c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064c6:	6298                	ld	a4,0(a3)
    800064c8:	9732                	add	a4,a4,a2
    800064ca:	4541                	li	a0,16
    800064cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064ce:	6298                	ld	a4,0(a3)
    800064d0:	9732                	add	a4,a4,a2
    800064d2:	4505                	li	a0,1
    800064d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064d8:	f9442703          	lw	a4,-108(s0)
    800064dc:	6288                	ld	a0,0(a3)
    800064de:	962a                	add	a2,a2,a0
    800064e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064e4:	0712                	slli	a4,a4,0x4
    800064e6:	6290                	ld	a2,0(a3)
    800064e8:	963a                	add	a2,a2,a4
    800064ea:	05890513          	addi	a0,s2,88
    800064ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064f0:	6294                	ld	a3,0(a3)
    800064f2:	96ba                	add	a3,a3,a4
    800064f4:	40000613          	li	a2,1024
    800064f8:	c690                	sw	a2,8(a3)
  if(write)
    800064fa:	140d0063          	beqz	s10,8000663a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064fe:	0001f697          	auipc	a3,0x1f
    80006502:	b026b683          	ld	a3,-1278(a3) # 80025000 <disk+0x2000>
    80006506:	96ba                	add	a3,a3,a4
    80006508:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000650c:	0001d817          	auipc	a6,0x1d
    80006510:	af480813          	addi	a6,a6,-1292 # 80023000 <disk>
    80006514:	0001f517          	auipc	a0,0x1f
    80006518:	aec50513          	addi	a0,a0,-1300 # 80025000 <disk+0x2000>
    8000651c:	6114                	ld	a3,0(a0)
    8000651e:	96ba                	add	a3,a3,a4
    80006520:	00c6d603          	lhu	a2,12(a3)
    80006524:	00166613          	ori	a2,a2,1
    80006528:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000652c:	f9842683          	lw	a3,-104(s0)
    80006530:	6110                	ld	a2,0(a0)
    80006532:	9732                	add	a4,a4,a2
    80006534:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006538:	20058613          	addi	a2,a1,512
    8000653c:	0612                	slli	a2,a2,0x4
    8000653e:	9642                	add	a2,a2,a6
    80006540:	577d                	li	a4,-1
    80006542:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006546:	00469713          	slli	a4,a3,0x4
    8000654a:	6114                	ld	a3,0(a0)
    8000654c:	96ba                	add	a3,a3,a4
    8000654e:	03078793          	addi	a5,a5,48
    80006552:	97c2                	add	a5,a5,a6
    80006554:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006556:	611c                	ld	a5,0(a0)
    80006558:	97ba                	add	a5,a5,a4
    8000655a:	4685                	li	a3,1
    8000655c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000655e:	611c                	ld	a5,0(a0)
    80006560:	97ba                	add	a5,a5,a4
    80006562:	4809                	li	a6,2
    80006564:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006568:	611c                	ld	a5,0(a0)
    8000656a:	973e                	add	a4,a4,a5
    8000656c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006570:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006574:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006578:	6518                	ld	a4,8(a0)
    8000657a:	00275783          	lhu	a5,2(a4)
    8000657e:	8b9d                	andi	a5,a5,7
    80006580:	0786                	slli	a5,a5,0x1
    80006582:	97ba                	add	a5,a5,a4
    80006584:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006588:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000658c:	6518                	ld	a4,8(a0)
    8000658e:	00275783          	lhu	a5,2(a4)
    80006592:	2785                	addiw	a5,a5,1
    80006594:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006598:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000659c:	100017b7          	lui	a5,0x10001
    800065a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065a4:	00492703          	lw	a4,4(s2)
    800065a8:	4785                	li	a5,1
    800065aa:	02f71163          	bne	a4,a5,800065cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065ae:	0001f997          	auipc	s3,0x1f
    800065b2:	b7a98993          	addi	s3,s3,-1158 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800065b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065b8:	85ce                	mv	a1,s3
    800065ba:	854a                	mv	a0,s2
    800065bc:	ffffc097          	auipc	ra,0xffffc
    800065c0:	c70080e7          	jalr	-912(ra) # 8000222c <sleep>
  while(b->disk == 1) {
    800065c4:	00492783          	lw	a5,4(s2)
    800065c8:	fe9788e3          	beq	a5,s1,800065b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065cc:	f9042903          	lw	s2,-112(s0)
    800065d0:	20090793          	addi	a5,s2,512
    800065d4:	00479713          	slli	a4,a5,0x4
    800065d8:	0001d797          	auipc	a5,0x1d
    800065dc:	a2878793          	addi	a5,a5,-1496 # 80023000 <disk>
    800065e0:	97ba                	add	a5,a5,a4
    800065e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065e6:	0001f997          	auipc	s3,0x1f
    800065ea:	a1a98993          	addi	s3,s3,-1510 # 80025000 <disk+0x2000>
    800065ee:	00491713          	slli	a4,s2,0x4
    800065f2:	0009b783          	ld	a5,0(s3)
    800065f6:	97ba                	add	a5,a5,a4
    800065f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065fc:	854a                	mv	a0,s2
    800065fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006602:	00000097          	auipc	ra,0x0
    80006606:	bc4080e7          	jalr	-1084(ra) # 800061c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000660a:	8885                	andi	s1,s1,1
    8000660c:	f0ed                	bnez	s1,800065ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000660e:	0001f517          	auipc	a0,0x1f
    80006612:	b1a50513          	addi	a0,a0,-1254 # 80025128 <disk+0x2128>
    80006616:	ffffa097          	auipc	ra,0xffffa
    8000661a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
}
    8000661e:	70a6                	ld	ra,104(sp)
    80006620:	7406                	ld	s0,96(sp)
    80006622:	64e6                	ld	s1,88(sp)
    80006624:	6946                	ld	s2,80(sp)
    80006626:	69a6                	ld	s3,72(sp)
    80006628:	6a06                	ld	s4,64(sp)
    8000662a:	7ae2                	ld	s5,56(sp)
    8000662c:	7b42                	ld	s6,48(sp)
    8000662e:	7ba2                	ld	s7,40(sp)
    80006630:	7c02                	ld	s8,32(sp)
    80006632:	6ce2                	ld	s9,24(sp)
    80006634:	6d42                	ld	s10,16(sp)
    80006636:	6165                	addi	sp,sp,112
    80006638:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000663a:	0001f697          	auipc	a3,0x1f
    8000663e:	9c66b683          	ld	a3,-1594(a3) # 80025000 <disk+0x2000>
    80006642:	96ba                	add	a3,a3,a4
    80006644:	4609                	li	a2,2
    80006646:	00c69623          	sh	a2,12(a3)
    8000664a:	b5c9                	j	8000650c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000664c:	f9042583          	lw	a1,-112(s0)
    80006650:	20058793          	addi	a5,a1,512
    80006654:	0792                	slli	a5,a5,0x4
    80006656:	0001d517          	auipc	a0,0x1d
    8000665a:	a5250513          	addi	a0,a0,-1454 # 800230a8 <disk+0xa8>
    8000665e:	953e                	add	a0,a0,a5
  if(write)
    80006660:	e20d11e3          	bnez	s10,80006482 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006664:	20058713          	addi	a4,a1,512
    80006668:	00471693          	slli	a3,a4,0x4
    8000666c:	0001d717          	auipc	a4,0x1d
    80006670:	99470713          	addi	a4,a4,-1644 # 80023000 <disk>
    80006674:	9736                	add	a4,a4,a3
    80006676:	0a072423          	sw	zero,168(a4)
    8000667a:	b505                	j	8000649a <virtio_disk_rw+0xf4>

000000008000667c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000667c:	1101                	addi	sp,sp,-32
    8000667e:	ec06                	sd	ra,24(sp)
    80006680:	e822                	sd	s0,16(sp)
    80006682:	e426                	sd	s1,8(sp)
    80006684:	e04a                	sd	s2,0(sp)
    80006686:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006688:	0001f517          	auipc	a0,0x1f
    8000668c:	aa050513          	addi	a0,a0,-1376 # 80025128 <disk+0x2128>
    80006690:	ffffa097          	auipc	ra,0xffffa
    80006694:	554080e7          	jalr	1364(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006698:	10001737          	lui	a4,0x10001
    8000669c:	533c                	lw	a5,96(a4)
    8000669e:	8b8d                	andi	a5,a5,3
    800066a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066a6:	0001f797          	auipc	a5,0x1f
    800066aa:	95a78793          	addi	a5,a5,-1702 # 80025000 <disk+0x2000>
    800066ae:	6b94                	ld	a3,16(a5)
    800066b0:	0207d703          	lhu	a4,32(a5)
    800066b4:	0026d783          	lhu	a5,2(a3)
    800066b8:	06f70163          	beq	a4,a5,8000671a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066bc:	0001d917          	auipc	s2,0x1d
    800066c0:	94490913          	addi	s2,s2,-1724 # 80023000 <disk>
    800066c4:	0001f497          	auipc	s1,0x1f
    800066c8:	93c48493          	addi	s1,s1,-1732 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800066cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066d0:	6898                	ld	a4,16(s1)
    800066d2:	0204d783          	lhu	a5,32(s1)
    800066d6:	8b9d                	andi	a5,a5,7
    800066d8:	078e                	slli	a5,a5,0x3
    800066da:	97ba                	add	a5,a5,a4
    800066dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066de:	20078713          	addi	a4,a5,512
    800066e2:	0712                	slli	a4,a4,0x4
    800066e4:	974a                	add	a4,a4,s2
    800066e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066ea:	e731                	bnez	a4,80006736 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066ec:	20078793          	addi	a5,a5,512
    800066f0:	0792                	slli	a5,a5,0x4
    800066f2:	97ca                	add	a5,a5,s2
    800066f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066fa:	ffffc097          	auipc	ra,0xffffc
    800066fe:	e0a080e7          	jalr	-502(ra) # 80002504 <wakeup>

    disk.used_idx += 1;
    80006702:	0204d783          	lhu	a5,32(s1)
    80006706:	2785                	addiw	a5,a5,1
    80006708:	17c2                	slli	a5,a5,0x30
    8000670a:	93c1                	srli	a5,a5,0x30
    8000670c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006710:	6898                	ld	a4,16(s1)
    80006712:	00275703          	lhu	a4,2(a4)
    80006716:	faf71be3          	bne	a4,a5,800066cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000671a:	0001f517          	auipc	a0,0x1f
    8000671e:	a0e50513          	addi	a0,a0,-1522 # 80025128 <disk+0x2128>
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	576080e7          	jalr	1398(ra) # 80000c98 <release>
}
    8000672a:	60e2                	ld	ra,24(sp)
    8000672c:	6442                	ld	s0,16(sp)
    8000672e:	64a2                	ld	s1,8(sp)
    80006730:	6902                	ld	s2,0(sp)
    80006732:	6105                	addi	sp,sp,32
    80006734:	8082                	ret
      panic("virtio_disk_intr status");
    80006736:	00002517          	auipc	a0,0x2
    8000673a:	1c250513          	addi	a0,a0,450 # 800088f8 <syscalls+0x3c0>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>
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
