
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b1013103          	ld	sp,-1264(sp) # 80008b10 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	18c78793          	addi	a5,a5,396 # 800061f0 <timervec>
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
    80000130:	716080e7          	jalr	1814(ra) # 80002842 <either_copyin>
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
    800001c8:	938080e7          	jalr	-1736(ra) # 80001afc <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	11c080e7          	jalr	284(ra) # 800022f0 <sleep>
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
    80000214:	5dc080e7          	jalr	1500(ra) # 800027ec <either_copyout>
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
    800002f6:	5a6080e7          	jalr	1446(ra) # 80002898 <procdump>
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
    8000044a:	182080e7          	jalr	386(ra) # 800025c8 <wakeup>
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
    80000570:	ee450513          	addi	a0,a0,-284 # 80008450 <states.1811+0x160>
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
    800008a4:	d28080e7          	jalr	-728(ra) # 800025c8 <wakeup>
    
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
    80000930:	9c4080e7          	jalr	-1596(ra) # 800022f0 <sleep>
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
    80000b82:	f62080e7          	jalr	-158(ra) # 80001ae0 <mycpu>
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
    80000bb4:	f30080e7          	jalr	-208(ra) # 80001ae0 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f24080e7          	jalr	-220(ra) # 80001ae0 <mycpu>
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
    80000bd8:	f0c080e7          	jalr	-244(ra) # 80001ae0 <mycpu>
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
    80000c18:	ecc080e7          	jalr	-308(ra) # 80001ae0 <mycpu>
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
    80000c44:	ea0080e7          	jalr	-352(ra) # 80001ae0 <mycpu>
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
    80000e9a:	c3a080e7          	jalr	-966(ra) # 80001ad0 <cpuid>
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
    80000eb6:	c1e080e7          	jalr	-994(ra) # 80001ad0 <cpuid>
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
    80000ed8:	baa080e7          	jalr	-1110(ra) # 80002a7e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	354080e7          	jalr	852(ra) # 80006230 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	25a080e7          	jalr	602(ra) # 8000213e <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	55450513          	addi	a0,a0,1364 # 80008450 <states.1811+0x160>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	53450513          	addi	a0,a0,1332 # 80008450 <states.1811+0x160>
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
    80000f48:	adc080e7          	jalr	-1316(ra) # 80001a20 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	b0a080e7          	jalr	-1270(ra) # 80002a56 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	b2a080e7          	jalr	-1238(ra) # 80002a7e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	2be080e7          	jalr	702(ra) # 8000621a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	2cc080e7          	jalr	716(ra) # 80006230 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	4ac080e7          	jalr	1196(ra) # 80003418 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	b3c080e7          	jalr	-1220(ra) # 80003ab0 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	ae6080e7          	jalr	-1306(ra) # 80004a62 <fileinit>
    pinit();         // process table for mlfq
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	9d6080e7          	jalr	-1578(ra) # 8000195a <pinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	3c6080e7          	jalr	966(ra) # 80006352 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e68080e7          	jalr	-408(ra) # 80001dfc <userinit>
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
    8000124c:	742080e7          	jalr	1858(ra) # 8000198a <proc_mapstacks>
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
struct Queue milfq[5];

void
push (struct Queue *list, struct proc *element)
{
  if (list->size == NPROC) {
    80001846:	21052703          	lw	a4,528(a0)
    8000184a:	04000793          	li	a5,64
    8000184e:	02f70363          	beq	a4,a5,80001874 <push+0x2e>
    panic("Proccess limit exceeded");
  }  

  list->array[list->tail] = element;
    80001852:	415c                	lw	a5,4(a0)
    80001854:	00379693          	slli	a3,a5,0x3
    80001858:	96aa                	add	a3,a3,a0
    8000185a:	e68c                	sd	a1,8(a3)
  list->tail++;
    8000185c:	2785                	addiw	a5,a5,1
    8000185e:	0007861b          	sext.w	a2,a5
  if (list->tail == NPROC + 1) {
    80001862:	04100693          	li	a3,65
    80001866:	02d60363          	beq	a2,a3,8000188c <push+0x46>
  list->tail++;
    8000186a:	c15c                	sw	a5,4(a0)
    list->tail = 0;
  }
  list->size++;
    8000186c:	2705                	addiw	a4,a4,1
    8000186e:	20e52823          	sw	a4,528(a0)
    80001872:	8082                	ret
{
    80001874:	1141                	addi	sp,sp,-16
    80001876:	e406                	sd	ra,8(sp)
    80001878:	e022                	sd	s0,0(sp)
    8000187a:	0800                	addi	s0,sp,16
    panic("Proccess limit exceeded");
    8000187c:	00007517          	auipc	a0,0x7
    80001880:	95c50513          	addi	a0,a0,-1700 # 800081d8 <digits+0x198>
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	cba080e7          	jalr	-838(ra) # 8000053e <panic>
    list->tail = 0;
    8000188c:	00052223          	sw	zero,4(a0)
    80001890:	bff1                	j	8000186c <push+0x26>

0000000080001892 <pop>:
}

void
pop(struct Queue *list)
{
  if (list->size == 0) {
    80001892:	21052783          	lw	a5,528(a0)
    80001896:	cf91                	beqz	a5,800018b2 <pop+0x20>
    panic("Poping from empty queue");
  }

  list->head++;
    80001898:	4118                	lw	a4,0(a0)
    8000189a:	2705                	addiw	a4,a4,1
    8000189c:	0007061b          	sext.w	a2,a4
  if (list->head == NPROC + 1) {
    800018a0:	04100693          	li	a3,65
    800018a4:	02d60363          	beq	a2,a3,800018ca <pop+0x38>
  list->head++;
    800018a8:	c118                	sw	a4,0(a0)
    list->head = 0;
  }

  list->size--;
    800018aa:	37fd                	addiw	a5,a5,-1
    800018ac:	20f52823          	sw	a5,528(a0)
    800018b0:	8082                	ret
{
    800018b2:	1141                	addi	sp,sp,-16
    800018b4:	e406                	sd	ra,8(sp)
    800018b6:	e022                	sd	s0,0(sp)
    800018b8:	0800                	addi	s0,sp,16
    panic("Poping from empty queue");
    800018ba:	00007517          	auipc	a0,0x7
    800018be:	93650513          	addi	a0,a0,-1738 # 800081f0 <digits+0x1b0>
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	c7c080e7          	jalr	-900(ra) # 8000053e <panic>
    list->head = 0;
    800018ca:	00052023          	sw	zero,0(a0)
    800018ce:	bff1                	j	800018aa <pop+0x18>

00000000800018d0 <front>:
}

struct proc*
front(struct Queue *list)
{
    800018d0:	1141                	addi	sp,sp,-16
    800018d2:	e422                	sd	s0,8(sp)
    800018d4:	0800                	addi	s0,sp,16
  if (list->head == list->tail) {
    800018d6:	411c                	lw	a5,0(a0)
    800018d8:	4158                	lw	a4,4(a0)
    800018da:	00f70863          	beq	a4,a5,800018ea <front+0x1a>
    return 0;
  } 
  return list->array[list->head];
    800018de:	078e                	slli	a5,a5,0x3
    800018e0:	953e                	add	a0,a0,a5
    800018e2:	6508                	ld	a0,8(a0)
}
    800018e4:	6422                	ld	s0,8(sp)
    800018e6:	0141                	addi	sp,sp,16
    800018e8:	8082                	ret
    return 0;
    800018ea:	4501                	li	a0,0
    800018ec:	bfe5                	j	800018e4 <front+0x14>

00000000800018ee <qerase>:

void 
qerase(struct Queue *list, int pid) 
{
    800018ee:	1141                	addi	sp,sp,-16
    800018f0:	e422                	sd	s0,8(sp)
    800018f2:	0800                	addi	s0,sp,16
  for (int curr = list->head; curr != list->tail; curr = (curr + 1) % (NPROC + 1)) {
    800018f4:	411c                	lw	a5,0(a0)
    800018f6:	00452803          	lw	a6,4(a0)
    800018fa:	03078d63          	beq	a5,a6,80001934 <qerase+0x46>
    if (list->array[curr]->pid == pid) {
      struct proc *temp = list->array[curr];
      list->array[curr] = list->array[(curr + 1) % (NPROC + 1)];
    800018fe:	04100893          	li	a7,65
    80001902:	a031                	j	8000190e <qerase+0x20>
  for (int curr = list->head; curr != list->tail; curr = (curr + 1) % (NPROC + 1)) {
    80001904:	2785                	addiw	a5,a5,1
    80001906:	0317e7bb          	remw	a5,a5,a7
    8000190a:	03078563          	beq	a5,a6,80001934 <qerase+0x46>
    if (list->array[curr]->pid == pid) {
    8000190e:	00379713          	slli	a4,a5,0x3
    80001912:	972a                	add	a4,a4,a0
    80001914:	6710                	ld	a2,8(a4)
    80001916:	5a14                	lw	a3,48(a2)
    80001918:	feb696e3          	bne	a3,a1,80001904 <qerase+0x16>
      list->array[curr] = list->array[(curr + 1) % (NPROC + 1)];
    8000191c:	0017869b          	addiw	a3,a5,1
    80001920:	0316e6bb          	remw	a3,a3,a7
    80001924:	068e                	slli	a3,a3,0x3
    80001926:	96aa                	add	a3,a3,a0
    80001928:	0086b303          	ld	t1,8(a3) # 1008 <_entry-0x7fffeff8>
    8000192c:	00673423          	sd	t1,8(a4)
      list->array[(curr + 1) % (NPROC + 1)] = temp;
    80001930:	e690                	sd	a2,8(a3)
    80001932:	bfc9                	j	80001904 <qerase+0x16>
    } 
  }

  list->tail--;
    80001934:	387d                	addiw	a6,a6,-1
    80001936:	01052223          	sw	a6,4(a0)
  list->size--;
    8000193a:	21052783          	lw	a5,528(a0)
    8000193e:	37fd                	addiw	a5,a5,-1
    80001940:	20f52823          	sw	a5,528(a0)
  if (list->tail < 0) {
    80001944:	02081793          	slli	a5,a6,0x20
    80001948:	0007c563          	bltz	a5,80001952 <qerase+0x64>
    list->tail = NPROC;
  }
}
    8000194c:	6422                	ld	s0,8(sp)
    8000194e:	0141                	addi	sp,sp,16
    80001950:	8082                	ret
    list->tail = NPROC;
    80001952:	04000793          	li	a5,64
    80001956:	c15c                	sw	a5,4(a0)
}
    80001958:	bfd5                	j	8000194c <qerase+0x5e>

000000008000195a <pinit>:

void
pinit(void)
{
    8000195a:	1141                	addi	sp,sp,-16
    8000195c:	e422                	sd	s0,8(sp)
    8000195e:	0800                	addi	s0,sp,16
  for (int i = 0; i < 5; i++) {
    80001960:	00010797          	auipc	a5,0x10
    80001964:	d7078793          	addi	a5,a5,-656 # 800116d0 <milfq>
    80001968:	00010717          	auipc	a4,0x10
    8000196c:	7e070713          	addi	a4,a4,2016 # 80012148 <proc>
    milfq[i].size = 0;
    80001970:	2007a823          	sw	zero,528(a5)
    milfq[i].head = 0;
    80001974:	0007a023          	sw	zero,0(a5)
    milfq[i].tail = 0;
    80001978:	0007a223          	sw	zero,4(a5)
  for (int i = 0; i < 5; i++) {
    8000197c:	21878793          	addi	a5,a5,536
    80001980:	fee798e3          	bne	a5,a4,80001970 <pinit+0x16>
  }
}
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000198a:	7139                	addi	sp,sp,-64
    8000198c:	fc06                	sd	ra,56(sp)
    8000198e:	f822                	sd	s0,48(sp)
    80001990:	f426                	sd	s1,40(sp)
    80001992:	f04a                	sd	s2,32(sp)
    80001994:	ec4e                	sd	s3,24(sp)
    80001996:	e852                	sd	s4,16(sp)
    80001998:	e456                	sd	s5,8(sp)
    8000199a:	e05a                	sd	s6,0(sp)
    8000199c:	0080                	addi	s0,sp,64
    8000199e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	00010497          	auipc	s1,0x10
    800019a4:	7a848493          	addi	s1,s1,1960 # 80012148 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a8:	8b26                	mv	s6,s1
    800019aa:	00006a97          	auipc	s5,0x6
    800019ae:	656a8a93          	addi	s5,s5,1622 # 80008000 <etext>
    800019b2:	04000937          	lui	s2,0x4000
    800019b6:	197d                	addi	s2,s2,-1
    800019b8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	00017a17          	auipc	s4,0x17
    800019be:	58ea0a13          	addi	s4,s4,1422 # 80018f48 <tickslock>
    char *pa = kalloc();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	132080e7          	jalr	306(ra) # 80000af4 <kalloc>
    800019ca:	862a                	mv	a2,a0
    if(pa == 0)
    800019cc:	c131                	beqz	a0,80001a10 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019ce:	416485b3          	sub	a1,s1,s6
    800019d2:	858d                	srai	a1,a1,0x3
    800019d4:	000ab783          	ld	a5,0(s5)
    800019d8:	02f585b3          	mul	a1,a1,a5
    800019dc:	2585                	addiw	a1,a1,1
    800019de:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e2:	4719                	li	a4,6
    800019e4:	6685                	lui	a3,0x1
    800019e6:	40b905b3          	sub	a1,s2,a1
    800019ea:	854e                	mv	a0,s3
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	76c080e7          	jalr	1900(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	1b848493          	addi	s1,s1,440
    800019f8:	fd4495e3          	bne	s1,s4,800019c2 <proc_mapstacks+0x38>
  }
}
    800019fc:	70e2                	ld	ra,56(sp)
    800019fe:	7442                	ld	s0,48(sp)
    80001a00:	74a2                	ld	s1,40(sp)
    80001a02:	7902                	ld	s2,32(sp)
    80001a04:	69e2                	ld	s3,24(sp)
    80001a06:	6a42                	ld	s4,16(sp)
    80001a08:	6aa2                	ld	s5,8(sp)
    80001a0a:	6b02                	ld	s6,0(sp)
    80001a0c:	6121                	addi	sp,sp,64
    80001a0e:	8082                	ret
      panic("kalloc");
    80001a10:	00006517          	auipc	a0,0x6
    80001a14:	7f850513          	addi	a0,a0,2040 # 80008208 <digits+0x1c8>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080001a20 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a20:	7139                	addi	sp,sp,-64
    80001a22:	fc06                	sd	ra,56(sp)
    80001a24:	f822                	sd	s0,48(sp)
    80001a26:	f426                	sd	s1,40(sp)
    80001a28:	f04a                	sd	s2,32(sp)
    80001a2a:	ec4e                	sd	s3,24(sp)
    80001a2c:	e852                	sd	s4,16(sp)
    80001a2e:	e456                	sd	s5,8(sp)
    80001a30:	e05a                	sd	s6,0(sp)
    80001a32:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a34:	00006597          	auipc	a1,0x6
    80001a38:	7dc58593          	addi	a1,a1,2012 # 80008210 <digits+0x1d0>
    80001a3c:	00010517          	auipc	a0,0x10
    80001a40:	86450513          	addi	a0,a0,-1948 # 800112a0 <pid_lock>
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	110080e7          	jalr	272(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a4c:	00006597          	auipc	a1,0x6
    80001a50:	7cc58593          	addi	a1,a1,1996 # 80008218 <digits+0x1d8>
    80001a54:	00010517          	auipc	a0,0x10
    80001a58:	86450513          	addi	a0,a0,-1948 # 800112b8 <wait_lock>
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	0f8080e7          	jalr	248(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a64:	00010497          	auipc	s1,0x10
    80001a68:	6e448493          	addi	s1,s1,1764 # 80012148 <proc>
      initlock(&p->lock, "proc");
    80001a6c:	00006b17          	auipc	s6,0x6
    80001a70:	7bcb0b13          	addi	s6,s6,1980 # 80008228 <digits+0x1e8>
      p->kstack = KSTACK((int) (p - proc));
    80001a74:	8aa6                	mv	s5,s1
    80001a76:	00006a17          	auipc	s4,0x6
    80001a7a:	58aa0a13          	addi	s4,s4,1418 # 80008000 <etext>
    80001a7e:	04000937          	lui	s2,0x4000
    80001a82:	197d                	addi	s2,s2,-1
    80001a84:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a86:	00017997          	auipc	s3,0x17
    80001a8a:	4c298993          	addi	s3,s3,1218 # 80018f48 <tickslock>
      initlock(&p->lock, "proc");
    80001a8e:	85da                	mv	a1,s6
    80001a90:	8526                	mv	a0,s1
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	0c2080e7          	jalr	194(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a9a:	415487b3          	sub	a5,s1,s5
    80001a9e:	878d                	srai	a5,a5,0x3
    80001aa0:	000a3703          	ld	a4,0(s4)
    80001aa4:	02e787b3          	mul	a5,a5,a4
    80001aa8:	2785                	addiw	a5,a5,1
    80001aaa:	00d7979b          	slliw	a5,a5,0xd
    80001aae:	40f907b3          	sub	a5,s2,a5
    80001ab2:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab4:	1b848493          	addi	s1,s1,440
    80001ab8:	fd349be3          	bne	s1,s3,80001a8e <procinit+0x6e>
  }
}
    80001abc:	70e2                	ld	ra,56(sp)
    80001abe:	7442                	ld	s0,48(sp)
    80001ac0:	74a2                	ld	s1,40(sp)
    80001ac2:	7902                	ld	s2,32(sp)
    80001ac4:	69e2                	ld	s3,24(sp)
    80001ac6:	6a42                	ld	s4,16(sp)
    80001ac8:	6aa2                	ld	s5,8(sp)
    80001aca:	6b02                	ld	s6,0(sp)
    80001acc:	6121                	addi	sp,sp,64
    80001ace:	8082                	ret

0000000080001ad0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ad0:	1141                	addi	sp,sp,-16
    80001ad2:	e422                	sd	s0,8(sp)
    80001ad4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ad8:	2501                	sext.w	a0,a0
    80001ada:	6422                	ld	s0,8(sp)
    80001adc:	0141                	addi	sp,sp,16
    80001ade:	8082                	ret

0000000080001ae0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ae0:	1141                	addi	sp,sp,-16
    80001ae2:	e422                	sd	s0,8(sp)
    80001ae4:	0800                	addi	s0,sp,16
    80001ae6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aec:	0000f517          	auipc	a0,0xf
    80001af0:	7e450513          	addi	a0,a0,2020 # 800112d0 <cpus>
    80001af4:	953e                	add	a0,a0,a5
    80001af6:	6422                	ld	s0,8(sp)
    80001af8:	0141                	addi	sp,sp,16
    80001afa:	8082                	ret

0000000080001afc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001afc:	1101                	addi	sp,sp,-32
    80001afe:	ec06                	sd	ra,24(sp)
    80001b00:	e822                	sd	s0,16(sp)
    80001b02:	e426                	sd	s1,8(sp)
    80001b04:	1000                	addi	s0,sp,32
  push_off();
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	092080e7          	jalr	146(ra) # 80000b98 <push_off>
    80001b0e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b10:	2781                	sext.w	a5,a5
    80001b12:	079e                	slli	a5,a5,0x7
    80001b14:	0000f717          	auipc	a4,0xf
    80001b18:	78c70713          	addi	a4,a4,1932 # 800112a0 <pid_lock>
    80001b1c:	97ba                	add	a5,a5,a4
    80001b1e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	118080e7          	jalr	280(ra) # 80000c38 <pop_off>
  return p;
}
    80001b28:	8526                	mv	a0,s1
    80001b2a:	60e2                	ld	ra,24(sp)
    80001b2c:	6442                	ld	s0,16(sp)
    80001b2e:	64a2                	ld	s1,8(sp)
    80001b30:	6105                	addi	sp,sp,32
    80001b32:	8082                	ret

0000000080001b34 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b34:	1141                	addi	sp,sp,-16
    80001b36:	e406                	sd	ra,8(sp)
    80001b38:	e022                	sd	s0,0(sp)
    80001b3a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	fc0080e7          	jalr	-64(ra) # 80001afc <myproc>
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	154080e7          	jalr	340(ra) # 80000c98 <release>

  if (first) {
    80001b4c:	00007797          	auipc	a5,0x7
    80001b50:	df47a783          	lw	a5,-524(a5) # 80008940 <first.1774>
    80001b54:	eb89                	bnez	a5,80001b66 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b56:	00001097          	auipc	ra,0x1
    80001b5a:	f40080e7          	jalr	-192(ra) # 80002a96 <usertrapret>
}
    80001b5e:	60a2                	ld	ra,8(sp)
    80001b60:	6402                	ld	s0,0(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret
    first = 0;
    80001b66:	00007797          	auipc	a5,0x7
    80001b6a:	dc07ad23          	sw	zero,-550(a5) # 80008940 <first.1774>
    fsinit(ROOTDEV);
    80001b6e:	4505                	li	a0,1
    80001b70:	00002097          	auipc	ra,0x2
    80001b74:	ec0080e7          	jalr	-320(ra) # 80003a30 <fsinit>
    80001b78:	bff9                	j	80001b56 <forkret+0x22>

0000000080001b7a <allocpid>:
allocpid() {
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	e04a                	sd	s2,0(sp)
    80001b84:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b86:	0000f917          	auipc	s2,0xf
    80001b8a:	71a90913          	addi	s2,s2,1818 # 800112a0 <pid_lock>
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	054080e7          	jalr	84(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	dac78793          	addi	a5,a5,-596 # 80008944 <nextpid>
    80001ba0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba2:	0014871b          	addiw	a4,s1,1
    80001ba6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba8:	854a                	mv	a0,s2
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
}
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <proc_pagetable>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	e04a                	sd	s2,0(sp)
    80001bca:	1000                	addi	s0,sp,32
    80001bcc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	774080e7          	jalr	1908(ra) # 80001342 <uvmcreate>
    80001bd6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd8:	c121                	beqz	a0,80001c18 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bda:	4729                	li	a4,10
    80001bdc:	00005697          	auipc	a3,0x5
    80001be0:	42468693          	addi	a3,a3,1060 # 80007000 <_trampoline>
    80001be4:	6605                	lui	a2,0x1
    80001be6:	040005b7          	lui	a1,0x4000
    80001bea:	15fd                	addi	a1,a1,-1
    80001bec:	05b2                	slli	a1,a1,0xc
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	4ca080e7          	jalr	1226(ra) # 800010b8 <mappages>
    80001bf6:	02054863          	bltz	a0,80001c26 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bfa:	4719                	li	a4,6
    80001bfc:	05893683          	ld	a3,88(s2)
    80001c00:	6605                	lui	a2,0x1
    80001c02:	020005b7          	lui	a1,0x2000
    80001c06:	15fd                	addi	a1,a1,-1
    80001c08:	05b6                	slli	a1,a1,0xd
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	4ac080e7          	jalr	1196(ra) # 800010b8 <mappages>
    80001c14:	02054163          	bltz	a0,80001c36 <proc_pagetable+0x76>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret
    uvmfree(pagetable, 0);
    80001c26:	4581                	li	a1,0
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	914080e7          	jalr	-1772(ra) # 8000153e <uvmfree>
    return 0;
    80001c32:	4481                	li	s1,0
    80001c34:	b7d5                	j	80001c18 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c36:	4681                	li	a3,0
    80001c38:	4605                	li	a2,1
    80001c3a:	040005b7          	lui	a1,0x4000
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05b2                	slli	a1,a1,0xc
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	63a080e7          	jalr	1594(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001c4c:	4581                	li	a1,0
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	8ee080e7          	jalr	-1810(ra) # 8000153e <uvmfree>
    return 0;
    80001c58:	4481                	li	s1,0
    80001c5a:	bf7d                	j	80001c18 <proc_pagetable+0x58>

0000000080001c5c <proc_freepagetable>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
    80001c68:	84aa                	mv	s1,a0
    80001c6a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c6c:	4681                	li	a3,0
    80001c6e:	4605                	li	a2,1
    80001c70:	040005b7          	lui	a1,0x4000
    80001c74:	15fd                	addi	a1,a1,-1
    80001c76:	05b2                	slli	a1,a1,0xc
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	606080e7          	jalr	1542(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c80:	4681                	li	a3,0
    80001c82:	4605                	li	a2,1
    80001c84:	020005b7          	lui	a1,0x2000
    80001c88:	15fd                	addi	a1,a1,-1
    80001c8a:	05b6                	slli	a1,a1,0xd
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	5f0080e7          	jalr	1520(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c96:	85ca                	mv	a1,s2
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	8a4080e7          	jalr	-1884(ra) # 8000153e <uvmfree>
}
    80001ca2:	60e2                	ld	ra,24(sp)
    80001ca4:	6442                	ld	s0,16(sp)
    80001ca6:	64a2                	ld	s1,8(sp)
    80001ca8:	6902                	ld	s2,0(sp)
    80001caa:	6105                	addi	sp,sp,32
    80001cac:	8082                	ret

0000000080001cae <freeproc>:
{
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	1000                	addi	s0,sp,32
    80001cb8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cba:	6d28                	ld	a0,88(a0)
    80001cbc:	c509                	beqz	a0,80001cc6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	d3a080e7          	jalr	-710(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001cc6:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cca:	68a8                	ld	a0,80(s1)
    80001ccc:	c511                	beqz	a0,80001cd8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cce:	64ac                	ld	a1,72(s1)
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	f8c080e7          	jalr	-116(ra) # 80001c5c <proc_freepagetable>
  p->pagetable = 0;
    80001cd8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cdc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ce0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ce8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cec:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cf0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cf4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cf8:	0004ac23          	sw	zero,24(s1)
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <allocproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d12:	00010497          	auipc	s1,0x10
    80001d16:	43648493          	addi	s1,s1,1078 # 80012148 <proc>
    80001d1a:	00017917          	auipc	s2,0x17
    80001d1e:	22e90913          	addi	s2,s2,558 # 80018f48 <tickslock>
    acquire(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	ec0080e7          	jalr	-320(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d2c:	4c9c                	lw	a5,24(s1)
    80001d2e:	cf81                	beqz	a5,80001d46 <allocproc+0x40>
      release(&p->lock);
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	f66080e7          	jalr	-154(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d3a:	1b848493          	addi	s1,s1,440
    80001d3e:	ff2492e3          	bne	s1,s2,80001d22 <allocproc+0x1c>
  return 0;
    80001d42:	4481                	li	s1,0
    80001d44:	a8ad                	j	80001dbe <allocproc+0xb8>
  p->pid = allocpid();
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	e34080e7          	jalr	-460(ra) # 80001b7a <allocpid>
    80001d4e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d50:	4785                	li	a5,1
    80001d52:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	da0080e7          	jalr	-608(ra) # 80000af4 <kalloc>
    80001d5c:	892a                	mv	s2,a0
    80001d5e:	eca8                	sd	a0,88(s1)
    80001d60:	c535                	beqz	a0,80001dcc <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001d62:	8526                	mv	a0,s1
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	e5c080e7          	jalr	-420(ra) # 80001bc0 <proc_pagetable>
    80001d6c:	892a                	mv	s2,a0
    80001d6e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d70:	c935                	beqz	a0,80001de4 <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001d72:	07000613          	li	a2,112
    80001d76:	4581                	li	a1,0
    80001d78:	06048513          	addi	a0,s1,96
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f64080e7          	jalr	-156(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d84:	00000797          	auipc	a5,0x0
    80001d88:	db078793          	addi	a5,a5,-592 # 80001b34 <forkret>
    80001d8c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d8e:	60bc                	ld	a5,64(s1)
    80001d90:	6705                	lui	a4,0x1
    80001d92:	97ba                	add	a5,a5,a4
    80001d94:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001d96:	1604a623          	sw	zero,364(s1)
  p->etime = 0;
    80001d9a:	1604aa23          	sw	zero,372(s1)
  p->ctime = ticks;
    80001d9e:	00007797          	auipc	a5,0x7
    80001da2:	2927a783          	lw	a5,658(a5) # 80009030 <ticks>
    80001da6:	16f4a823          	sw	a5,368(s1)
    p->q[i] = 0;
    80001daa:	1a04a023          	sw	zero,416(s1)
    80001dae:	1a04a223          	sw	zero,420(s1)
    80001db2:	1a04a423          	sw	zero,424(s1)
    80001db6:	1a04a623          	sw	zero,428(s1)
    80001dba:	1a04a823          	sw	zero,432(s1)
}
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6902                	ld	s2,0(sp)
    80001dc8:	6105                	addi	sp,sp,32
    80001dca:	8082                	ret
    freeproc(p);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	ee0080e7          	jalr	-288(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	ec0080e7          	jalr	-320(ra) # 80000c98 <release>
    return 0;
    80001de0:	84ca                	mv	s1,s2
    80001de2:	bff1                	j	80001dbe <allocproc+0xb8>
    freeproc(p);
    80001de4:	8526                	mv	a0,s1
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	ec8080e7          	jalr	-312(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001dee:	8526                	mv	a0,s1
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	ea8080e7          	jalr	-344(ra) # 80000c98 <release>
    return 0;
    80001df8:	84ca                	mv	s1,s2
    80001dfa:	b7d1                	j	80001dbe <allocproc+0xb8>

0000000080001dfc <userinit>:
{
    80001dfc:	1101                	addi	sp,sp,-32
    80001dfe:	ec06                	sd	ra,24(sp)
    80001e00:	e822                	sd	s0,16(sp)
    80001e02:	e426                	sd	s1,8(sp)
    80001e04:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	f00080e7          	jalr	-256(ra) # 80001d06 <allocproc>
    80001e0e:	84aa                	mv	s1,a0
  initproc = p;
    80001e10:	00007797          	auipc	a5,0x7
    80001e14:	20a7bc23          	sd	a0,536(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e18:	03400613          	li	a2,52
    80001e1c:	00007597          	auipc	a1,0x7
    80001e20:	b3458593          	addi	a1,a1,-1228 # 80008950 <initcode>
    80001e24:	6928                	ld	a0,80(a0)
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	54a080e7          	jalr	1354(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001e2e:	6785                	lui	a5,0x1
    80001e30:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e32:	6cb8                	ld	a4,88(s1)
    80001e34:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e38:	6cb8                	ld	a4,88(s1)
    80001e3a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e3c:	4641                	li	a2,16
    80001e3e:	00006597          	auipc	a1,0x6
    80001e42:	3f258593          	addi	a1,a1,1010 # 80008230 <digits+0x1f0>
    80001e46:	15848513          	addi	a0,s1,344
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	fe8080e7          	jalr	-24(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e52:	00006517          	auipc	a0,0x6
    80001e56:	3ee50513          	addi	a0,a0,1006 # 80008240 <digits+0x200>
    80001e5a:	00002097          	auipc	ra,0x2
    80001e5e:	604080e7          	jalr	1540(ra) # 8000445e <namei>
    80001e62:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e66:	478d                	li	a5,3
    80001e68:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e2c080e7          	jalr	-468(ra) # 80000c98 <release>
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6105                	addi	sp,sp,32
    80001e7c:	8082                	ret

0000000080001e7e <growproc>:
{
    80001e7e:	1101                	addi	sp,sp,-32
    80001e80:	ec06                	sd	ra,24(sp)
    80001e82:	e822                	sd	s0,16(sp)
    80001e84:	e426                	sd	s1,8(sp)
    80001e86:	e04a                	sd	s2,0(sp)
    80001e88:	1000                	addi	s0,sp,32
    80001e8a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	c70080e7          	jalr	-912(ra) # 80001afc <myproc>
    80001e94:	892a                	mv	s2,a0
  sz = p->sz;
    80001e96:	652c                	ld	a1,72(a0)
    80001e98:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e9c:	00904f63          	bgtz	s1,80001eba <growproc+0x3c>
  } else if(n < 0){
    80001ea0:	0204cc63          	bltz	s1,80001ed8 <growproc+0x5a>
  p->sz = sz;
    80001ea4:	1602                	slli	a2,a2,0x20
    80001ea6:	9201                	srli	a2,a2,0x20
    80001ea8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001eac:	4501                	li	a0,0
}
    80001eae:	60e2                	ld	ra,24(sp)
    80001eb0:	6442                	ld	s0,16(sp)
    80001eb2:	64a2                	ld	s1,8(sp)
    80001eb4:	6902                	ld	s2,0(sp)
    80001eb6:	6105                	addi	sp,sp,32
    80001eb8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001eba:	9e25                	addw	a2,a2,s1
    80001ebc:	1602                	slli	a2,a2,0x20
    80001ebe:	9201                	srli	a2,a2,0x20
    80001ec0:	1582                	slli	a1,a1,0x20
    80001ec2:	9181                	srli	a1,a1,0x20
    80001ec4:	6928                	ld	a0,80(a0)
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	564080e7          	jalr	1380(ra) # 8000142a <uvmalloc>
    80001ece:	0005061b          	sext.w	a2,a0
    80001ed2:	fa69                	bnez	a2,80001ea4 <growproc+0x26>
      return -1;
    80001ed4:	557d                	li	a0,-1
    80001ed6:	bfe1                	j	80001eae <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ed8:	9e25                	addw	a2,a2,s1
    80001eda:	1602                	slli	a2,a2,0x20
    80001edc:	9201                	srli	a2,a2,0x20
    80001ede:	1582                	slli	a1,a1,0x20
    80001ee0:	9181                	srli	a1,a1,0x20
    80001ee2:	6928                	ld	a0,80(a0)
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	4fe080e7          	jalr	1278(ra) # 800013e2 <uvmdealloc>
    80001eec:	0005061b          	sext.w	a2,a0
    80001ef0:	bf55                	j	80001ea4 <growproc+0x26>

0000000080001ef2 <fork>:
{
    80001ef2:	7179                	addi	sp,sp,-48
    80001ef4:	f406                	sd	ra,40(sp)
    80001ef6:	f022                	sd	s0,32(sp)
    80001ef8:	ec26                	sd	s1,24(sp)
    80001efa:	e84a                	sd	s2,16(sp)
    80001efc:	e44e                	sd	s3,8(sp)
    80001efe:	e052                	sd	s4,0(sp)
    80001f00:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	bfa080e7          	jalr	-1030(ra) # 80001afc <myproc>
    80001f0a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	dfa080e7          	jalr	-518(ra) # 80001d06 <allocproc>
    80001f14:	10050f63          	beqz	a0,80002032 <fork+0x140>
    80001f18:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f1a:	04893603          	ld	a2,72(s2)
    80001f1e:	692c                	ld	a1,80(a0)
    80001f20:	05093503          	ld	a0,80(s2)
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	652080e7          	jalr	1618(ra) # 80001576 <uvmcopy>
    80001f2c:	04054a63          	bltz	a0,80001f80 <fork+0x8e>
  np->trace_mask = p->trace_mask;
    80001f30:	16892783          	lw	a5,360(s2)
    80001f34:	16f9a423          	sw	a5,360(s3)
  np->sz = p->sz;
    80001f38:	04893783          	ld	a5,72(s2)
    80001f3c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f40:	05893683          	ld	a3,88(s2)
    80001f44:	87b6                	mv	a5,a3
    80001f46:	0589b703          	ld	a4,88(s3)
    80001f4a:	12068693          	addi	a3,a3,288
    80001f4e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f52:	6788                	ld	a0,8(a5)
    80001f54:	6b8c                	ld	a1,16(a5)
    80001f56:	6f90                	ld	a2,24(a5)
    80001f58:	01073023          	sd	a6,0(a4)
    80001f5c:	e708                	sd	a0,8(a4)
    80001f5e:	eb0c                	sd	a1,16(a4)
    80001f60:	ef10                	sd	a2,24(a4)
    80001f62:	02078793          	addi	a5,a5,32
    80001f66:	02070713          	addi	a4,a4,32
    80001f6a:	fed792e3          	bne	a5,a3,80001f4e <fork+0x5c>
  np->trapframe->a0 = 0;
    80001f6e:	0589b783          	ld	a5,88(s3)
    80001f72:	0607b823          	sd	zero,112(a5)
    80001f76:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f7a:	15000a13          	li	s4,336
    80001f7e:	a03d                	j	80001fac <fork+0xba>
    freeproc(np);
    80001f80:	854e                	mv	a0,s3
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	d2c080e7          	jalr	-724(ra) # 80001cae <freeproc>
    release(&np->lock);
    80001f8a:	854e                	mv	a0,s3
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	d0c080e7          	jalr	-756(ra) # 80000c98 <release>
    return -1;
    80001f94:	5a7d                	li	s4,-1
    80001f96:	a069                	j	80002020 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f98:	00003097          	auipc	ra,0x3
    80001f9c:	b5c080e7          	jalr	-1188(ra) # 80004af4 <filedup>
    80001fa0:	009987b3          	add	a5,s3,s1
    80001fa4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fa6:	04a1                	addi	s1,s1,8
    80001fa8:	01448763          	beq	s1,s4,80001fb6 <fork+0xc4>
    if(p->ofile[i])
    80001fac:	009907b3          	add	a5,s2,s1
    80001fb0:	6388                	ld	a0,0(a5)
    80001fb2:	f17d                	bnez	a0,80001f98 <fork+0xa6>
    80001fb4:	bfcd                	j	80001fa6 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001fb6:	15093503          	ld	a0,336(s2)
    80001fba:	00002097          	auipc	ra,0x2
    80001fbe:	cb0080e7          	jalr	-848(ra) # 80003c6a <idup>
    80001fc2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fc6:	4641                	li	a2,16
    80001fc8:	15890593          	addi	a1,s2,344
    80001fcc:	15898513          	addi	a0,s3,344
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	e62080e7          	jalr	-414(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001fd8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001fdc:	854e                	mv	a0,s3
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	cba080e7          	jalr	-838(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001fe6:	0000f497          	auipc	s1,0xf
    80001fea:	2d248493          	addi	s1,s1,722 # 800112b8 <wait_lock>
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	bf4080e7          	jalr	-1036(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ff8:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	c9a080e7          	jalr	-870(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002006:	854e                	mv	a0,s3
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	bdc080e7          	jalr	-1060(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002010:	478d                	li	a5,3
    80002012:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002016:	854e                	mv	a0,s3
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	c80080e7          	jalr	-896(ra) # 80000c98 <release>
}
    80002020:	8552                	mv	a0,s4
    80002022:	70a2                	ld	ra,40(sp)
    80002024:	7402                	ld	s0,32(sp)
    80002026:	64e2                	ld	s1,24(sp)
    80002028:	6942                	ld	s2,16(sp)
    8000202a:	69a2                	ld	s3,8(sp)
    8000202c:	6a02                	ld	s4,0(sp)
    8000202e:	6145                	addi	sp,sp,48
    80002030:	8082                	ret
    return -1;
    80002032:	5a7d                	li	s4,-1
    80002034:	b7f5                	j	80002020 <fork+0x12e>

0000000080002036 <update_time>:
{
    80002036:	7179                	addi	sp,sp,-48
    80002038:	f406                	sd	ra,40(sp)
    8000203a:	f022                	sd	s0,32(sp)
    8000203c:	ec26                	sd	s1,24(sp)
    8000203e:	e84a                	sd	s2,16(sp)
    80002040:	e44e                	sd	s3,8(sp)
    80002042:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {
    80002044:	00010497          	auipc	s1,0x10
    80002048:	10448493          	addi	s1,s1,260 # 80012148 <proc>
    if (p->state == RUNNING) {
    8000204c:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    8000204e:	00017917          	auipc	s2,0x17
    80002052:	efa90913          	addi	s2,s2,-262 # 80018f48 <tickslock>
    80002056:	a811                	j	8000206a <update_time+0x34>
    release(&p->lock); 
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c3e080e7          	jalr	-962(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002062:	1b848493          	addi	s1,s1,440
    80002066:	03248063          	beq	s1,s2,80002086 <update_time+0x50>
    acquire(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
    if (p->state == RUNNING) {
    80002074:	4c9c                	lw	a5,24(s1)
    80002076:	ff3791e3          	bne	a5,s3,80002058 <update_time+0x22>
      p->rtime++;
    8000207a:	16c4a783          	lw	a5,364(s1)
    8000207e:	2785                	addiw	a5,a5,1
    80002080:	16f4a623          	sw	a5,364(s1)
    80002084:	bfd1                	j	80002058 <update_time+0x22>
}
    80002086:	70a2                	ld	ra,40(sp)
    80002088:	7402                	ld	s0,32(sp)
    8000208a:	64e2                	ld	s1,24(sp)
    8000208c:	6942                	ld	s2,16(sp)
    8000208e:	69a2                	ld	s3,8(sp)
    80002090:	6145                	addi	sp,sp,48
    80002092:	8082                	ret

0000000080002094 <ageing>:
{
    80002094:	715d                	addi	sp,sp,-80
    80002096:	e486                	sd	ra,72(sp)
    80002098:	e0a2                	sd	s0,64(sp)
    8000209a:	fc26                	sd	s1,56(sp)
    8000209c:	f84a                	sd	s2,48(sp)
    8000209e:	f44e                	sd	s3,40(sp)
    800020a0:	f052                	sd	s4,32(sp)
    800020a2:	ec56                	sd	s5,24(sp)
    800020a4:	e85a                	sd	s6,16(sp)
    800020a6:	e45e                	sd	s7,8(sp)
    800020a8:	0880                	addi	s0,sp,80
  for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    800020aa:	00010497          	auipc	s1,0x10
    800020ae:	09e48493          	addi	s1,s1,158 # 80012148 <proc>
    if (p->state == RUNNABLE && ticks - p->q_enter >= 128) {
    800020b2:	498d                	li	s3,3
    800020b4:	00007a17          	auipc	s4,0x7
    800020b8:	f7ca0a13          	addi	s4,s4,-132 # 80009030 <ticks>
    800020bc:	07f00a93          	li	s5,127
        qerase(&milfq[p->level], p->pid);
    800020c0:	21800b93          	li	s7,536
    800020c4:	0000fb17          	auipc	s6,0xf
    800020c8:	60cb0b13          	addi	s6,s6,1548 # 800116d0 <milfq>
  for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    800020cc:	00017917          	auipc	s2,0x17
    800020d0:	e7c90913          	addi	s2,s2,-388 # 80018f48 <tickslock>
    800020d4:	a035                	j	80002100 <ageing+0x6c>
        qerase(&milfq[p->level], p->pid);
    800020d6:	1904a503          	lw	a0,400(s1)
    800020da:	03750533          	mul	a0,a0,s7
    800020de:	588c                	lw	a1,48(s1)
    800020e0:	955a                	add	a0,a0,s6
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	80c080e7          	jalr	-2036(ra) # 800018ee <qerase>
        p->in_queue = 0;
    800020ea:	1804aa23          	sw	zero,404(s1)
    800020ee:	a035                	j	8000211a <ageing+0x86>
      p->q_enter = ticks;
    800020f0:	000a2783          	lw	a5,0(s4)
    800020f4:	18f4ae23          	sw	a5,412(s1)
  for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    800020f8:	1b848493          	addi	s1,s1,440
    800020fc:	03248663          	beq	s1,s2,80002128 <ageing+0x94>
    if (p->state == RUNNABLE && ticks - p->q_enter >= 128) {
    80002100:	4c9c                	lw	a5,24(s1)
    80002102:	ff379be3          	bne	a5,s3,800020f8 <ageing+0x64>
    80002106:	000a2783          	lw	a5,0(s4)
    8000210a:	19c4a703          	lw	a4,412(s1)
    8000210e:	9f99                	subw	a5,a5,a4
    80002110:	fefaf4e3          	bgeu	s5,a5,800020f8 <ageing+0x64>
      if (p->in_queue) {
    80002114:	1944a783          	lw	a5,404(s1)
    80002118:	ffdd                	bnez	a5,800020d6 <ageing+0x42>
      if (p->level != 0) {
    8000211a:	1904a783          	lw	a5,400(s1)
    8000211e:	dbe9                	beqz	a5,800020f0 <ageing+0x5c>
        p->level--;
    80002120:	37fd                	addiw	a5,a5,-1
    80002122:	18f4a823          	sw	a5,400(s1)
    80002126:	b7e9                	j	800020f0 <ageing+0x5c>
}
    80002128:	60a6                	ld	ra,72(sp)
    8000212a:	6406                	ld	s0,64(sp)
    8000212c:	74e2                	ld	s1,56(sp)
    8000212e:	7942                	ld	s2,48(sp)
    80002130:	79a2                	ld	s3,40(sp)
    80002132:	7a02                	ld	s4,32(sp)
    80002134:	6ae2                	ld	s5,24(sp)
    80002136:	6b42                	ld	s6,16(sp)
    80002138:	6ba2                	ld	s7,8(sp)
    8000213a:	6161                	addi	sp,sp,80
    8000213c:	8082                	ret

000000008000213e <scheduler>:
{
    8000213e:	7139                	addi	sp,sp,-64
    80002140:	fc06                	sd	ra,56(sp)
    80002142:	f822                	sd	s0,48(sp)
    80002144:	f426                	sd	s1,40(sp)
    80002146:	f04a                	sd	s2,32(sp)
    80002148:	ec4e                	sd	s3,24(sp)
    8000214a:	e852                	sd	s4,16(sp)
    8000214c:	e456                	sd	s5,8(sp)
    8000214e:	e05a                	sd	s6,0(sp)
    80002150:	0080                	addi	s0,sp,64
    80002152:	8792                	mv	a5,tp
  int id = r_tp();
    80002154:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002156:	00779a93          	slli	s5,a5,0x7
    8000215a:	0000f717          	auipc	a4,0xf
    8000215e:	14670713          	addi	a4,a4,326 # 800112a0 <pid_lock>
    80002162:	9756                	add	a4,a4,s5
    80002164:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002168:	0000f717          	auipc	a4,0xf
    8000216c:	17070713          	addi	a4,a4,368 # 800112d8 <cpus+0x8>
    80002170:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002172:	498d                	li	s3,3
        p->state = RUNNING;
    80002174:	4b11                	li	s6,4
        c->proc = p;
    80002176:	079e                	slli	a5,a5,0x7
    80002178:	0000fa17          	auipc	s4,0xf
    8000217c:	128a0a13          	addi	s4,s4,296 # 800112a0 <pid_lock>
    80002180:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002182:	00017917          	auipc	s2,0x17
    80002186:	dc690913          	addi	s2,s2,-570 # 80018f48 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000218a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000218e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002192:	10079073          	csrw	sstatus,a5
    80002196:	00010497          	auipc	s1,0x10
    8000219a:	fb248493          	addi	s1,s1,-78 # 80012148 <proc>
    8000219e:	a03d                	j	800021cc <scheduler+0x8e>
        p->state = RUNNING;
    800021a0:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800021a4:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800021a8:	06048593          	addi	a1,s1,96
    800021ac:	8556                	mv	a0,s5
    800021ae:	00001097          	auipc	ra,0x1
    800021b2:	83e080e7          	jalr	-1986(ra) # 800029ec <swtch>
        c->proc = 0;
    800021b6:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	adc080e7          	jalr	-1316(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021c4:	1b848493          	addi	s1,s1,440
    800021c8:	fd2481e3          	beq	s1,s2,8000218a <scheduler+0x4c>
      acquire(&p->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a16080e7          	jalr	-1514(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    800021d6:	4c9c                	lw	a5,24(s1)
    800021d8:	ff3791e3          	bne	a5,s3,800021ba <scheduler+0x7c>
    800021dc:	b7d1                	j	800021a0 <scheduler+0x62>

00000000800021de <sched>:
{
    800021de:	7179                	addi	sp,sp,-48
    800021e0:	f406                	sd	ra,40(sp)
    800021e2:	f022                	sd	s0,32(sp)
    800021e4:	ec26                	sd	s1,24(sp)
    800021e6:	e84a                	sd	s2,16(sp)
    800021e8:	e44e                	sd	s3,8(sp)
    800021ea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	910080e7          	jalr	-1776(ra) # 80001afc <myproc>
    800021f4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	974080e7          	jalr	-1676(ra) # 80000b6a <holding>
    800021fe:	c93d                	beqz	a0,80002274 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002200:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002202:	2781                	sext.w	a5,a5
    80002204:	079e                	slli	a5,a5,0x7
    80002206:	0000f717          	auipc	a4,0xf
    8000220a:	09a70713          	addi	a4,a4,154 # 800112a0 <pid_lock>
    8000220e:	97ba                	add	a5,a5,a4
    80002210:	0a87a703          	lw	a4,168(a5)
    80002214:	4785                	li	a5,1
    80002216:	06f71763          	bne	a4,a5,80002284 <sched+0xa6>
  if(p->state == RUNNING)
    8000221a:	4c98                	lw	a4,24(s1)
    8000221c:	4791                	li	a5,4
    8000221e:	06f70b63          	beq	a4,a5,80002294 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002222:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002226:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002228:	efb5                	bnez	a5,800022a4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000222a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000222c:	0000f917          	auipc	s2,0xf
    80002230:	07490913          	addi	s2,s2,116 # 800112a0 <pid_lock>
    80002234:	2781                	sext.w	a5,a5
    80002236:	079e                	slli	a5,a5,0x7
    80002238:	97ca                	add	a5,a5,s2
    8000223a:	0ac7a983          	lw	s3,172(a5)
    8000223e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002240:	2781                	sext.w	a5,a5
    80002242:	079e                	slli	a5,a5,0x7
    80002244:	0000f597          	auipc	a1,0xf
    80002248:	09458593          	addi	a1,a1,148 # 800112d8 <cpus+0x8>
    8000224c:	95be                	add	a1,a1,a5
    8000224e:	06048513          	addi	a0,s1,96
    80002252:	00000097          	auipc	ra,0x0
    80002256:	79a080e7          	jalr	1946(ra) # 800029ec <swtch>
    8000225a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000225c:	2781                	sext.w	a5,a5
    8000225e:	079e                	slli	a5,a5,0x7
    80002260:	97ca                	add	a5,a5,s2
    80002262:	0b37a623          	sw	s3,172(a5)
}
    80002266:	70a2                	ld	ra,40(sp)
    80002268:	7402                	ld	s0,32(sp)
    8000226a:	64e2                	ld	s1,24(sp)
    8000226c:	6942                	ld	s2,16(sp)
    8000226e:	69a2                	ld	s3,8(sp)
    80002270:	6145                	addi	sp,sp,48
    80002272:	8082                	ret
    panic("sched p->lock");
    80002274:	00006517          	auipc	a0,0x6
    80002278:	fd450513          	addi	a0,a0,-44 # 80008248 <digits+0x208>
    8000227c:	ffffe097          	auipc	ra,0xffffe
    80002280:	2c2080e7          	jalr	706(ra) # 8000053e <panic>
    panic("sched locks");
    80002284:	00006517          	auipc	a0,0x6
    80002288:	fd450513          	addi	a0,a0,-44 # 80008258 <digits+0x218>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2b2080e7          	jalr	690(ra) # 8000053e <panic>
    panic("sched running");
    80002294:	00006517          	auipc	a0,0x6
    80002298:	fd450513          	addi	a0,a0,-44 # 80008268 <digits+0x228>
    8000229c:	ffffe097          	auipc	ra,0xffffe
    800022a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022a4:	00006517          	auipc	a0,0x6
    800022a8:	fd450513          	addi	a0,a0,-44 # 80008278 <digits+0x238>
    800022ac:	ffffe097          	auipc	ra,0xffffe
    800022b0:	292080e7          	jalr	658(ra) # 8000053e <panic>

00000000800022b4 <yield>:
{
    800022b4:	1101                	addi	sp,sp,-32
    800022b6:	ec06                	sd	ra,24(sp)
    800022b8:	e822                	sd	s0,16(sp)
    800022ba:	e426                	sd	s1,8(sp)
    800022bc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	83e080e7          	jalr	-1986(ra) # 80001afc <myproc>
    800022c6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	91c080e7          	jalr	-1764(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022d0:	478d                	li	a5,3
    800022d2:	cc9c                	sw	a5,24(s1)
  sched();
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	f0a080e7          	jalr	-246(ra) # 800021de <sched>
  release(&p->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9ba080e7          	jalr	-1606(ra) # 80000c98 <release>
}
    800022e6:	60e2                	ld	ra,24(sp)
    800022e8:	6442                	ld	s0,16(sp)
    800022ea:	64a2                	ld	s1,8(sp)
    800022ec:	6105                	addi	sp,sp,32
    800022ee:	8082                	ret

00000000800022f0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022f0:	7179                	addi	sp,sp,-48
    800022f2:	f406                	sd	ra,40(sp)
    800022f4:	f022                	sd	s0,32(sp)
    800022f6:	ec26                	sd	s1,24(sp)
    800022f8:	e84a                	sd	s2,16(sp)
    800022fa:	e44e                	sd	s3,8(sp)
    800022fc:	1800                	addi	s0,sp,48
    800022fe:	89aa                	mv	s3,a0
    80002300:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	7fa080e7          	jalr	2042(ra) # 80001afc <myproc>
    8000230a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8d8080e7          	jalr	-1832(ra) # 80000be4 <acquire>
  release(lk);
    80002314:	854a                	mv	a0,s2
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000231e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002322:	4789                	li	a5,2
    80002324:	cc9c                	sw	a5,24(s1)

  sched();
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	eb8080e7          	jalr	-328(ra) # 800021de <sched>

  // Tidy up.
  p->chan = 0;
    8000232e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	964080e7          	jalr	-1692(ra) # 80000c98 <release>
  acquire(lk);
    8000233c:	854a                	mv	a0,s2
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	8a6080e7          	jalr	-1882(ra) # 80000be4 <acquire>
}
    80002346:	70a2                	ld	ra,40(sp)
    80002348:	7402                	ld	s0,32(sp)
    8000234a:	64e2                	ld	s1,24(sp)
    8000234c:	6942                	ld	s2,16(sp)
    8000234e:	69a2                	ld	s3,8(sp)
    80002350:	6145                	addi	sp,sp,48
    80002352:	8082                	ret

0000000080002354 <wait>:
{
    80002354:	715d                	addi	sp,sp,-80
    80002356:	e486                	sd	ra,72(sp)
    80002358:	e0a2                	sd	s0,64(sp)
    8000235a:	fc26                	sd	s1,56(sp)
    8000235c:	f84a                	sd	s2,48(sp)
    8000235e:	f44e                	sd	s3,40(sp)
    80002360:	f052                	sd	s4,32(sp)
    80002362:	ec56                	sd	s5,24(sp)
    80002364:	e85a                	sd	s6,16(sp)
    80002366:	e45e                	sd	s7,8(sp)
    80002368:	e062                	sd	s8,0(sp)
    8000236a:	0880                	addi	s0,sp,80
    8000236c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	78e080e7          	jalr	1934(ra) # 80001afc <myproc>
    80002376:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002378:	0000f517          	auipc	a0,0xf
    8000237c:	f4050513          	addi	a0,a0,-192 # 800112b8 <wait_lock>
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	864080e7          	jalr	-1948(ra) # 80000be4 <acquire>
    havekids = 0;
    80002388:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000238a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000238c:	00017997          	auipc	s3,0x17
    80002390:	bbc98993          	addi	s3,s3,-1092 # 80018f48 <tickslock>
        havekids = 1;
    80002394:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002396:	0000fc17          	auipc	s8,0xf
    8000239a:	f22c0c13          	addi	s8,s8,-222 # 800112b8 <wait_lock>
    havekids = 0;
    8000239e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023a0:	00010497          	auipc	s1,0x10
    800023a4:	da848493          	addi	s1,s1,-600 # 80012148 <proc>
    800023a8:	a0bd                	j	80002416 <wait+0xc2>
          pid = np->pid;
    800023aa:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023ae:	000b0e63          	beqz	s6,800023ca <wait+0x76>
    800023b2:	4691                	li	a3,4
    800023b4:	02c48613          	addi	a2,s1,44
    800023b8:	85da                	mv	a1,s6
    800023ba:	05093503          	ld	a0,80(s2)
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	2bc080e7          	jalr	700(ra) # 8000167a <copyout>
    800023c6:	02054563          	bltz	a0,800023f0 <wait+0x9c>
          freeproc(np);
    800023ca:	8526                	mv	a0,s1
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	8e2080e7          	jalr	-1822(ra) # 80001cae <freeproc>
          release(&np->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8c2080e7          	jalr	-1854(ra) # 80000c98 <release>
          release(&wait_lock);
    800023de:	0000f517          	auipc	a0,0xf
    800023e2:	eda50513          	addi	a0,a0,-294 # 800112b8 <wait_lock>
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
          return pid;
    800023ee:	a09d                	j	80002454 <wait+0x100>
            release(&np->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
            release(&wait_lock);
    800023fa:	0000f517          	auipc	a0,0xf
    800023fe:	ebe50513          	addi	a0,a0,-322 # 800112b8 <wait_lock>
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
            return -1;
    8000240a:	59fd                	li	s3,-1
    8000240c:	a0a1                	j	80002454 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000240e:	1b848493          	addi	s1,s1,440
    80002412:	03348463          	beq	s1,s3,8000243a <wait+0xe6>
      if(np->parent == p){
    80002416:	7c9c                	ld	a5,56(s1)
    80002418:	ff279be3          	bne	a5,s2,8000240e <wait+0xba>
        acquire(&np->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7c6080e7          	jalr	1990(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002426:	4c9c                	lw	a5,24(s1)
    80002428:	f94781e3          	beq	a5,s4,800023aa <wait+0x56>
        release(&np->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	86a080e7          	jalr	-1942(ra) # 80000c98 <release>
        havekids = 1;
    80002436:	8756                	mv	a4,s5
    80002438:	bfd9                	j	8000240e <wait+0xba>
    if(!havekids || p->killed){
    8000243a:	c701                	beqz	a4,80002442 <wait+0xee>
    8000243c:	02892783          	lw	a5,40(s2)
    80002440:	c79d                	beqz	a5,8000246e <wait+0x11a>
      release(&wait_lock);
    80002442:	0000f517          	auipc	a0,0xf
    80002446:	e7650513          	addi	a0,a0,-394 # 800112b8 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
      return -1;
    80002452:	59fd                	li	s3,-1
}
    80002454:	854e                	mv	a0,s3
    80002456:	60a6                	ld	ra,72(sp)
    80002458:	6406                	ld	s0,64(sp)
    8000245a:	74e2                	ld	s1,56(sp)
    8000245c:	7942                	ld	s2,48(sp)
    8000245e:	79a2                	ld	s3,40(sp)
    80002460:	7a02                	ld	s4,32(sp)
    80002462:	6ae2                	ld	s5,24(sp)
    80002464:	6b42                	ld	s6,16(sp)
    80002466:	6ba2                	ld	s7,8(sp)
    80002468:	6c02                	ld	s8,0(sp)
    8000246a:	6161                	addi	sp,sp,80
    8000246c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000246e:	85e2                	mv	a1,s8
    80002470:	854a                	mv	a0,s2
    80002472:	00000097          	auipc	ra,0x0
    80002476:	e7e080e7          	jalr	-386(ra) # 800022f0 <sleep>
    havekids = 0;
    8000247a:	b715                	j	8000239e <wait+0x4a>

000000008000247c <waitx>:
{
    8000247c:	711d                	addi	sp,sp,-96
    8000247e:	ec86                	sd	ra,88(sp)
    80002480:	e8a2                	sd	s0,80(sp)
    80002482:	e4a6                	sd	s1,72(sp)
    80002484:	e0ca                	sd	s2,64(sp)
    80002486:	fc4e                	sd	s3,56(sp)
    80002488:	f852                	sd	s4,48(sp)
    8000248a:	f456                	sd	s5,40(sp)
    8000248c:	f05a                	sd	s6,32(sp)
    8000248e:	ec5e                	sd	s7,24(sp)
    80002490:	e862                	sd	s8,16(sp)
    80002492:	e466                	sd	s9,8(sp)
    80002494:	e06a                	sd	s10,0(sp)
    80002496:	1080                	addi	s0,sp,96
    80002498:	8b2a                	mv	s6,a0
    8000249a:	8c2e                	mv	s8,a1
    8000249c:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	65e080e7          	jalr	1630(ra) # 80001afc <myproc>
    800024a6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024a8:	0000f517          	auipc	a0,0xf
    800024ac:	e1050513          	addi	a0,a0,-496 # 800112b8 <wait_lock>
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	734080e7          	jalr	1844(ra) # 80000be4 <acquire>
    havekids = 0;
    800024b8:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800024ba:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800024bc:	00017997          	auipc	s3,0x17
    800024c0:	a8c98993          	addi	s3,s3,-1396 # 80018f48 <tickslock>
        havekids = 1;
    800024c4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c6:	0000fd17          	auipc	s10,0xf
    800024ca:	df2d0d13          	addi	s10,s10,-526 # 800112b8 <wait_lock>
    havekids = 0;
    800024ce:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800024d0:	00010497          	auipc	s1,0x10
    800024d4:	c7848493          	addi	s1,s1,-904 # 80012148 <proc>
    800024d8:	a059                	j	8000255e <waitx+0xe2>
          pid = np->pid;
    800024da:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800024de:	16c4a703          	lw	a4,364(s1)
    800024e2:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800024e6:	1704a783          	lw	a5,368(s1)
    800024ea:	9f3d                	addw	a4,a4,a5
    800024ec:	1744a783          	lw	a5,372(s1)
    800024f0:	9f99                	subw	a5,a5,a4
    800024f2:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024f6:	000b0e63          	beqz	s6,80002512 <waitx+0x96>
    800024fa:	4691                	li	a3,4
    800024fc:	02c48613          	addi	a2,s1,44
    80002500:	85da                	mv	a1,s6
    80002502:	05093503          	ld	a0,80(s2)
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	174080e7          	jalr	372(ra) # 8000167a <copyout>
    8000250e:	02054563          	bltz	a0,80002538 <waitx+0xbc>
          freeproc(np);
    80002512:	8526                	mv	a0,s1
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	79a080e7          	jalr	1946(ra) # 80001cae <freeproc>
          release(&np->lock);
    8000251c:	8526                	mv	a0,s1
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	77a080e7          	jalr	1914(ra) # 80000c98 <release>
          release(&wait_lock);
    80002526:	0000f517          	auipc	a0,0xf
    8000252a:	d9250513          	addi	a0,a0,-622 # 800112b8 <wait_lock>
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	76a080e7          	jalr	1898(ra) # 80000c98 <release>
          return pid;
    80002536:	a09d                	j	8000259c <waitx+0x120>
            release(&np->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	75e080e7          	jalr	1886(ra) # 80000c98 <release>
            release(&wait_lock);
    80002542:	0000f517          	auipc	a0,0xf
    80002546:	d7650513          	addi	a0,a0,-650 # 800112b8 <wait_lock>
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	74e080e7          	jalr	1870(ra) # 80000c98 <release>
            return -1;
    80002552:	59fd                	li	s3,-1
    80002554:	a0a1                	j	8000259c <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002556:	1b848493          	addi	s1,s1,440
    8000255a:	03348463          	beq	s1,s3,80002582 <waitx+0x106>
      if(np->parent == p){
    8000255e:	7c9c                	ld	a5,56(s1)
    80002560:	ff279be3          	bne	a5,s2,80002556 <waitx+0xda>
        acquire(&np->lock);
    80002564:	8526                	mv	a0,s1
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	67e080e7          	jalr	1662(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000256e:	4c9c                	lw	a5,24(s1)
    80002570:	f74785e3          	beq	a5,s4,800024da <waitx+0x5e>
        release(&np->lock);
    80002574:	8526                	mv	a0,s1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	722080e7          	jalr	1826(ra) # 80000c98 <release>
        havekids = 1;
    8000257e:	8756                	mv	a4,s5
    80002580:	bfd9                	j	80002556 <waitx+0xda>
    if(!havekids || p->killed){
    80002582:	c701                	beqz	a4,8000258a <waitx+0x10e>
    80002584:	02892783          	lw	a5,40(s2)
    80002588:	cb8d                	beqz	a5,800025ba <waitx+0x13e>
      release(&wait_lock);
    8000258a:	0000f517          	auipc	a0,0xf
    8000258e:	d2e50513          	addi	a0,a0,-722 # 800112b8 <wait_lock>
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	706080e7          	jalr	1798(ra) # 80000c98 <release>
      return -1;
    8000259a:	59fd                	li	s3,-1
}
    8000259c:	854e                	mv	a0,s3
    8000259e:	60e6                	ld	ra,88(sp)
    800025a0:	6446                	ld	s0,80(sp)
    800025a2:	64a6                	ld	s1,72(sp)
    800025a4:	6906                	ld	s2,64(sp)
    800025a6:	79e2                	ld	s3,56(sp)
    800025a8:	7a42                	ld	s4,48(sp)
    800025aa:	7aa2                	ld	s5,40(sp)
    800025ac:	7b02                	ld	s6,32(sp)
    800025ae:	6be2                	ld	s7,24(sp)
    800025b0:	6c42                	ld	s8,16(sp)
    800025b2:	6ca2                	ld	s9,8(sp)
    800025b4:	6d02                	ld	s10,0(sp)
    800025b6:	6125                	addi	sp,sp,96
    800025b8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025ba:	85ea                	mv	a1,s10
    800025bc:	854a                	mv	a0,s2
    800025be:	00000097          	auipc	ra,0x0
    800025c2:	d32080e7          	jalr	-718(ra) # 800022f0 <sleep>
    havekids = 0;
    800025c6:	b721                	j	800024ce <waitx+0x52>

00000000800025c8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025c8:	7139                	addi	sp,sp,-64
    800025ca:	fc06                	sd	ra,56(sp)
    800025cc:	f822                	sd	s0,48(sp)
    800025ce:	f426                	sd	s1,40(sp)
    800025d0:	f04a                	sd	s2,32(sp)
    800025d2:	ec4e                	sd	s3,24(sp)
    800025d4:	e852                	sd	s4,16(sp)
    800025d6:	e456                	sd	s5,8(sp)
    800025d8:	0080                	addi	s0,sp,64
    800025da:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800025dc:	00010497          	auipc	s1,0x10
    800025e0:	b6c48493          	addi	s1,s1,-1172 # 80012148 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800025e4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025e6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800025e8:	00017917          	auipc	s2,0x17
    800025ec:	96090913          	addi	s2,s2,-1696 # 80018f48 <tickslock>
    800025f0:	a821                	j	80002608 <wakeup+0x40>
        p->state = RUNNABLE;
    800025f2:	0154ac23          	sw	s5,24(s1)
        #ifdef PBS
        p->sched_end = ticks;
        #endif
      }
      release(&p->lock);
    800025f6:	8526                	mv	a0,s1
    800025f8:	ffffe097          	auipc	ra,0xffffe
    800025fc:	6a0080e7          	jalr	1696(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002600:	1b848493          	addi	s1,s1,440
    80002604:	03248463          	beq	s1,s2,8000262c <wakeup+0x64>
    if(p != myproc()){
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	4f4080e7          	jalr	1268(ra) # 80001afc <myproc>
    80002610:	fea488e3          	beq	s1,a0,80002600 <wakeup+0x38>
      acquire(&p->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	5ce080e7          	jalr	1486(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000261e:	4c9c                	lw	a5,24(s1)
    80002620:	fd379be3          	bne	a5,s3,800025f6 <wakeup+0x2e>
    80002624:	709c                	ld	a5,32(s1)
    80002626:	fd4798e3          	bne	a5,s4,800025f6 <wakeup+0x2e>
    8000262a:	b7e1                	j	800025f2 <wakeup+0x2a>
    }
  }
}
    8000262c:	70e2                	ld	ra,56(sp)
    8000262e:	7442                	ld	s0,48(sp)
    80002630:	74a2                	ld	s1,40(sp)
    80002632:	7902                	ld	s2,32(sp)
    80002634:	69e2                	ld	s3,24(sp)
    80002636:	6a42                	ld	s4,16(sp)
    80002638:	6aa2                	ld	s5,8(sp)
    8000263a:	6121                	addi	sp,sp,64
    8000263c:	8082                	ret

000000008000263e <reparent>:
{
    8000263e:	7179                	addi	sp,sp,-48
    80002640:	f406                	sd	ra,40(sp)
    80002642:	f022                	sd	s0,32(sp)
    80002644:	ec26                	sd	s1,24(sp)
    80002646:	e84a                	sd	s2,16(sp)
    80002648:	e44e                	sd	s3,8(sp)
    8000264a:	e052                	sd	s4,0(sp)
    8000264c:	1800                	addi	s0,sp,48
    8000264e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002650:	00010497          	auipc	s1,0x10
    80002654:	af848493          	addi	s1,s1,-1288 # 80012148 <proc>
      pp->parent = initproc;
    80002658:	00007a17          	auipc	s4,0x7
    8000265c:	9d0a0a13          	addi	s4,s4,-1584 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002660:	00017997          	auipc	s3,0x17
    80002664:	8e898993          	addi	s3,s3,-1816 # 80018f48 <tickslock>
    80002668:	a029                	j	80002672 <reparent+0x34>
    8000266a:	1b848493          	addi	s1,s1,440
    8000266e:	01348d63          	beq	s1,s3,80002688 <reparent+0x4a>
    if(pp->parent == p){
    80002672:	7c9c                	ld	a5,56(s1)
    80002674:	ff279be3          	bne	a5,s2,8000266a <reparent+0x2c>
      pp->parent = initproc;
    80002678:	000a3503          	ld	a0,0(s4)
    8000267c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	f4a080e7          	jalr	-182(ra) # 800025c8 <wakeup>
    80002686:	b7d5                	j	8000266a <reparent+0x2c>
}
    80002688:	70a2                	ld	ra,40(sp)
    8000268a:	7402                	ld	s0,32(sp)
    8000268c:	64e2                	ld	s1,24(sp)
    8000268e:	6942                	ld	s2,16(sp)
    80002690:	69a2                	ld	s3,8(sp)
    80002692:	6a02                	ld	s4,0(sp)
    80002694:	6145                	addi	sp,sp,48
    80002696:	8082                	ret

0000000080002698 <exit>:
{
    80002698:	7179                	addi	sp,sp,-48
    8000269a:	f406                	sd	ra,40(sp)
    8000269c:	f022                	sd	s0,32(sp)
    8000269e:	ec26                	sd	s1,24(sp)
    800026a0:	e84a                	sd	s2,16(sp)
    800026a2:	e44e                	sd	s3,8(sp)
    800026a4:	e052                	sd	s4,0(sp)
    800026a6:	1800                	addi	s0,sp,48
    800026a8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	452080e7          	jalr	1106(ra) # 80001afc <myproc>
    800026b2:	89aa                	mv	s3,a0
  if(p == initproc)
    800026b4:	00007797          	auipc	a5,0x7
    800026b8:	9747b783          	ld	a5,-1676(a5) # 80009028 <initproc>
    800026bc:	0d050493          	addi	s1,a0,208
    800026c0:	15050913          	addi	s2,a0,336
    800026c4:	02a79363          	bne	a5,a0,800026ea <exit+0x52>
    panic("init exiting");
    800026c8:	00006517          	auipc	a0,0x6
    800026cc:	bc850513          	addi	a0,a0,-1080 # 80008290 <digits+0x250>
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>
      fileclose(f);
    800026d8:	00002097          	auipc	ra,0x2
    800026dc:	46e080e7          	jalr	1134(ra) # 80004b46 <fileclose>
      p->ofile[fd] = 0;
    800026e0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026e4:	04a1                	addi	s1,s1,8
    800026e6:	01248563          	beq	s1,s2,800026f0 <exit+0x58>
    if(p->ofile[fd]){
    800026ea:	6088                	ld	a0,0(s1)
    800026ec:	f575                	bnez	a0,800026d8 <exit+0x40>
    800026ee:	bfdd                	j	800026e4 <exit+0x4c>
  begin_op();
    800026f0:	00002097          	auipc	ra,0x2
    800026f4:	f8a080e7          	jalr	-118(ra) # 8000467a <begin_op>
  iput(p->cwd);
    800026f8:	1509b503          	ld	a0,336(s3)
    800026fc:	00001097          	auipc	ra,0x1
    80002700:	766080e7          	jalr	1894(ra) # 80003e62 <iput>
  end_op();
    80002704:	00002097          	auipc	ra,0x2
    80002708:	ff6080e7          	jalr	-10(ra) # 800046fa <end_op>
  p->cwd = 0;
    8000270c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002710:	0000f497          	auipc	s1,0xf
    80002714:	ba848493          	addi	s1,s1,-1112 # 800112b8 <wait_lock>
    80002718:	8526                	mv	a0,s1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	4ca080e7          	jalr	1226(ra) # 80000be4 <acquire>
  reparent(p);
    80002722:	854e                	mv	a0,s3
    80002724:	00000097          	auipc	ra,0x0
    80002728:	f1a080e7          	jalr	-230(ra) # 8000263e <reparent>
  wakeup(p->parent);
    8000272c:	0389b503          	ld	a0,56(s3)
    80002730:	00000097          	auipc	ra,0x0
    80002734:	e98080e7          	jalr	-360(ra) # 800025c8 <wakeup>
  acquire(&p->lock);
    80002738:	854e                	mv	a0,s3
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	4aa080e7          	jalr	1194(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002742:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002746:	4795                	li	a5,5
    80002748:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000274c:	00007797          	auipc	a5,0x7
    80002750:	8e47a783          	lw	a5,-1820(a5) # 80009030 <ticks>
    80002754:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	53e080e7          	jalr	1342(ra) # 80000c98 <release>
  sched();
    80002762:	00000097          	auipc	ra,0x0
    80002766:	a7c080e7          	jalr	-1412(ra) # 800021de <sched>
  panic("zombie exit");
    8000276a:	00006517          	auipc	a0,0x6
    8000276e:	b3650513          	addi	a0,a0,-1226 # 800082a0 <digits+0x260>
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>

000000008000277a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000277a:	7179                	addi	sp,sp,-48
    8000277c:	f406                	sd	ra,40(sp)
    8000277e:	f022                	sd	s0,32(sp)
    80002780:	ec26                	sd	s1,24(sp)
    80002782:	e84a                	sd	s2,16(sp)
    80002784:	e44e                	sd	s3,8(sp)
    80002786:	1800                	addi	s0,sp,48
    80002788:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000278a:	00010497          	auipc	s1,0x10
    8000278e:	9be48493          	addi	s1,s1,-1602 # 80012148 <proc>
    80002792:	00016997          	auipc	s3,0x16
    80002796:	7b698993          	addi	s3,s3,1974 # 80018f48 <tickslock>
    acquire(&p->lock);
    8000279a:	8526                	mv	a0,s1
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	448080e7          	jalr	1096(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800027a4:	589c                	lw	a5,48(s1)
    800027a6:	01278d63          	beq	a5,s2,800027c0 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4ec080e7          	jalr	1260(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b4:	1b848493          	addi	s1,s1,440
    800027b8:	ff3491e3          	bne	s1,s3,8000279a <kill+0x20>
  }
  return -1;
    800027bc:	557d                	li	a0,-1
    800027be:	a829                	j	800027d8 <kill+0x5e>
      p->killed = 1;
    800027c0:	4785                	li	a5,1
    800027c2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027c4:	4c98                	lw	a4,24(s1)
    800027c6:	4789                	li	a5,2
    800027c8:	00f70f63          	beq	a4,a5,800027e6 <kill+0x6c>
      release(&p->lock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4ca080e7          	jalr	1226(ra) # 80000c98 <release>
      return 0;
    800027d6:	4501                	li	a0,0
}
    800027d8:	70a2                	ld	ra,40(sp)
    800027da:	7402                	ld	s0,32(sp)
    800027dc:	64e2                	ld	s1,24(sp)
    800027de:	6942                	ld	s2,16(sp)
    800027e0:	69a2                	ld	s3,8(sp)
    800027e2:	6145                	addi	sp,sp,48
    800027e4:	8082                	ret
        p->state = RUNNABLE;
    800027e6:	478d                	li	a5,3
    800027e8:	cc9c                	sw	a5,24(s1)
    800027ea:	b7cd                	j	800027cc <kill+0x52>

00000000800027ec <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ec:	7179                	addi	sp,sp,-48
    800027ee:	f406                	sd	ra,40(sp)
    800027f0:	f022                	sd	s0,32(sp)
    800027f2:	ec26                	sd	s1,24(sp)
    800027f4:	e84a                	sd	s2,16(sp)
    800027f6:	e44e                	sd	s3,8(sp)
    800027f8:	e052                	sd	s4,0(sp)
    800027fa:	1800                	addi	s0,sp,48
    800027fc:	84aa                	mv	s1,a0
    800027fe:	892e                	mv	s2,a1
    80002800:	89b2                	mv	s3,a2
    80002802:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	2f8080e7          	jalr	760(ra) # 80001afc <myproc>
  if(user_dst){
    8000280c:	c08d                	beqz	s1,8000282e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000280e:	86d2                	mv	a3,s4
    80002810:	864e                	mv	a2,s3
    80002812:	85ca                	mv	a1,s2
    80002814:	6928                	ld	a0,80(a0)
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	e64080e7          	jalr	-412(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000281e:	70a2                	ld	ra,40(sp)
    80002820:	7402                	ld	s0,32(sp)
    80002822:	64e2                	ld	s1,24(sp)
    80002824:	6942                	ld	s2,16(sp)
    80002826:	69a2                	ld	s3,8(sp)
    80002828:	6a02                	ld	s4,0(sp)
    8000282a:	6145                	addi	sp,sp,48
    8000282c:	8082                	ret
    memmove((char *)dst, src, len);
    8000282e:	000a061b          	sext.w	a2,s4
    80002832:	85ce                	mv	a1,s3
    80002834:	854a                	mv	a0,s2
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	50a080e7          	jalr	1290(ra) # 80000d40 <memmove>
    return 0;
    8000283e:	8526                	mv	a0,s1
    80002840:	bff9                	j	8000281e <either_copyout+0x32>

0000000080002842 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002842:	7179                	addi	sp,sp,-48
    80002844:	f406                	sd	ra,40(sp)
    80002846:	f022                	sd	s0,32(sp)
    80002848:	ec26                	sd	s1,24(sp)
    8000284a:	e84a                	sd	s2,16(sp)
    8000284c:	e44e                	sd	s3,8(sp)
    8000284e:	e052                	sd	s4,0(sp)
    80002850:	1800                	addi	s0,sp,48
    80002852:	892a                	mv	s2,a0
    80002854:	84ae                	mv	s1,a1
    80002856:	89b2                	mv	s3,a2
    80002858:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	2a2080e7          	jalr	674(ra) # 80001afc <myproc>
  if(user_src){
    80002862:	c08d                	beqz	s1,80002884 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002864:	86d2                	mv	a3,s4
    80002866:	864e                	mv	a2,s3
    80002868:	85ca                	mv	a1,s2
    8000286a:	6928                	ld	a0,80(a0)
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	e9a080e7          	jalr	-358(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002874:	70a2                	ld	ra,40(sp)
    80002876:	7402                	ld	s0,32(sp)
    80002878:	64e2                	ld	s1,24(sp)
    8000287a:	6942                	ld	s2,16(sp)
    8000287c:	69a2                	ld	s3,8(sp)
    8000287e:	6a02                	ld	s4,0(sp)
    80002880:	6145                	addi	sp,sp,48
    80002882:	8082                	ret
    memmove(dst, (char*)src, len);
    80002884:	000a061b          	sext.w	a2,s4
    80002888:	85ce                	mv	a1,s3
    8000288a:	854a                	mv	a0,s2
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	4b4080e7          	jalr	1204(ra) # 80000d40 <memmove>
    return 0;
    80002894:	8526                	mv	a0,s1
    80002896:	bff9                	j	80002874 <either_copyin+0x32>

0000000080002898 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002898:	715d                	addi	sp,sp,-80
    8000289a:	e486                	sd	ra,72(sp)
    8000289c:	e0a2                	sd	s0,64(sp)
    8000289e:	fc26                	sd	s1,56(sp)
    800028a0:	f84a                	sd	s2,48(sp)
    800028a2:	f44e                	sd	s3,40(sp)
    800028a4:	f052                	sd	s4,32(sp)
    800028a6:	ec56                	sd	s5,24(sp)
    800028a8:	e85a                	sd	s6,16(sp)
    800028aa:	e45e                	sd	s7,8(sp)
    800028ac:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	ba250513          	addi	a0,a0,-1118 # 80008450 <states.1811+0x160>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	cd2080e7          	jalr	-814(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028be:	00010497          	auipc	s1,0x10
    800028c2:	9e248493          	addi	s1,s1,-1566 # 800122a0 <proc+0x158>
    800028c6:	00016917          	auipc	s2,0x16
    800028ca:	7da90913          	addi	s2,s2,2010 # 800190a0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ce:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028d0:	00006997          	auipc	s3,0x6
    800028d4:	9e098993          	addi	s3,s3,-1568 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800028d8:	00006a97          	auipc	s5,0x6
    800028dc:	9e0a8a93          	addi	s5,s5,-1568 # 800082b8 <digits+0x278>
    printf("\n");
    800028e0:	00006a17          	auipc	s4,0x6
    800028e4:	b70a0a13          	addi	s4,s4,-1168 # 80008450 <states.1811+0x160>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e8:	00006b97          	auipc	s7,0x6
    800028ec:	a08b8b93          	addi	s7,s7,-1528 # 800082f0 <states.1811>
    800028f0:	a00d                	j	80002912 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028f2:	ed86a583          	lw	a1,-296(a3)
    800028f6:	8556                	mv	a0,s5
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c90080e7          	jalr	-880(ra) # 80000588 <printf>
    printf("\n");
    80002900:	8552                	mv	a0,s4
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	c86080e7          	jalr	-890(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000290a:	1b848493          	addi	s1,s1,440
    8000290e:	03248163          	beq	s1,s2,80002930 <procdump+0x98>
    if(p->state == UNUSED)
    80002912:	86a6                	mv	a3,s1
    80002914:	ec04a783          	lw	a5,-320(s1)
    80002918:	dbed                	beqz	a5,8000290a <procdump+0x72>
      state = "???";
    8000291a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000291c:	fcfb6be3          	bltu	s6,a5,800028f2 <procdump+0x5a>
    80002920:	1782                	slli	a5,a5,0x20
    80002922:	9381                	srli	a5,a5,0x20
    80002924:	078e                	slli	a5,a5,0x3
    80002926:	97de                	add	a5,a5,s7
    80002928:	6390                	ld	a2,0(a5)
    8000292a:	f661                	bnez	a2,800028f2 <procdump+0x5a>
      state = "???";
    8000292c:	864e                	mv	a2,s3
    8000292e:	b7d1                	j	800028f2 <procdump+0x5a>
  }
}
    80002930:	60a6                	ld	ra,72(sp)
    80002932:	6406                	ld	s0,64(sp)
    80002934:	74e2                	ld	s1,56(sp)
    80002936:	7942                	ld	s2,48(sp)
    80002938:	79a2                	ld	s3,40(sp)
    8000293a:	7a02                	ld	s4,32(sp)
    8000293c:	6ae2                	ld	s5,24(sp)
    8000293e:	6b42                	ld	s6,16(sp)
    80002940:	6ba2                	ld	s7,8(sp)
    80002942:	6161                	addi	sp,sp,80
    80002944:	8082                	ret

0000000080002946 <trace>:

// enabling tracing for the current process
void
trace(int trace_mask)
{
    80002946:	1101                	addi	sp,sp,-32
    80002948:	ec06                	sd	ra,24(sp)
    8000294a:	e822                	sd	s0,16(sp)
    8000294c:	e426                	sd	s1,8(sp)
    8000294e:	1000                	addi	s0,sp,32
    80002950:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	1aa080e7          	jalr	426(ra) # 80001afc <myproc>
  p->trace_mask = trace_mask;
    8000295a:	16952423          	sw	s1,360(a0)
}
    8000295e:	60e2                	ld	ra,24(sp)
    80002960:	6442                	ld	s0,16(sp)
    80002962:	64a2                	ld	s1,8(sp)
    80002964:	6105                	addi	sp,sp,32
    80002966:	8082                	ret

0000000080002968 <set_priority>:


// Change the priority of the given process with pid to new_priority
int set_priority(int new_priority,int pid)
{
    80002968:	7179                	addi	sp,sp,-48
    8000296a:	f406                	sd	ra,40(sp)
    8000296c:	f022                	sd	s0,32(sp)
    8000296e:	ec26                	sd	s1,24(sp)
    80002970:	e84a                	sd	s2,16(sp)
    80002972:	e44e                	sd	s3,8(sp)
    80002974:	e052                	sd	s4,0(sp)
    80002976:	1800                	addi	s0,sp,48
    80002978:	8a2a                	mv	s4,a0
    8000297a:	892e                	mv	s2,a1
  struct proc *p;
  int old_priority = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    8000297c:	0000f497          	auipc	s1,0xf
    80002980:	7cc48493          	addi	s1,s1,1996 # 80012148 <proc>
    80002984:	00016997          	auipc	s3,0x16
    80002988:	5c498993          	addi	s3,s3,1476 # 80018f48 <tickslock>
    acquire(&p->lock);
    8000298c:	8526                	mv	a0,s1
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002996:	589c                	lw	a5,48(s1)
    80002998:	03278163          	beq	a5,s2,800029ba <set_priority+0x52>
      p->new_proc = 1;
      release(&p->lock);
      yield();
      return old_priority;
    }
    release(&p->lock);
    8000299c:	8526                	mv	a0,s1
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	2fa080e7          	jalr	762(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800029a6:	1b848493          	addi	s1,s1,440
    800029aa:	ff3491e3          	bne	s1,s3,8000298c <set_priority+0x24>
  }
  yield();
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	906080e7          	jalr	-1786(ra) # 800022b4 <yield>
  return old_priority;
    800029b6:	4901                	li	s2,0
    800029b8:	a00d                	j	800029da <set_priority+0x72>
      old_priority = p->static_priority;
    800029ba:	1784a903          	lw	s2,376(s1)
      p->static_priority = new_priority;
    800029be:	1744ac23          	sw	s4,376(s1)
      p->new_proc = 1;
    800029c2:	4785                	li	a5,1
    800029c4:	18f4a623          	sw	a5,396(s1)
      release(&p->lock);
    800029c8:	8526                	mv	a0,s1
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	2ce080e7          	jalr	718(ra) # 80000c98 <release>
      yield();
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	8e2080e7          	jalr	-1822(ra) # 800022b4 <yield>
}
    800029da:	854a                	mv	a0,s2
    800029dc:	70a2                	ld	ra,40(sp)
    800029de:	7402                	ld	s0,32(sp)
    800029e0:	64e2                	ld	s1,24(sp)
    800029e2:	6942                	ld	s2,16(sp)
    800029e4:	69a2                	ld	s3,8(sp)
    800029e6:	6a02                	ld	s4,0(sp)
    800029e8:	6145                	addi	sp,sp,48
    800029ea:	8082                	ret

00000000800029ec <swtch>:
    800029ec:	00153023          	sd	ra,0(a0)
    800029f0:	00253423          	sd	sp,8(a0)
    800029f4:	e900                	sd	s0,16(a0)
    800029f6:	ed04                	sd	s1,24(a0)
    800029f8:	03253023          	sd	s2,32(a0)
    800029fc:	03353423          	sd	s3,40(a0)
    80002a00:	03453823          	sd	s4,48(a0)
    80002a04:	03553c23          	sd	s5,56(a0)
    80002a08:	05653023          	sd	s6,64(a0)
    80002a0c:	05753423          	sd	s7,72(a0)
    80002a10:	05853823          	sd	s8,80(a0)
    80002a14:	05953c23          	sd	s9,88(a0)
    80002a18:	07a53023          	sd	s10,96(a0)
    80002a1c:	07b53423          	sd	s11,104(a0)
    80002a20:	0005b083          	ld	ra,0(a1)
    80002a24:	0085b103          	ld	sp,8(a1)
    80002a28:	6980                	ld	s0,16(a1)
    80002a2a:	6d84                	ld	s1,24(a1)
    80002a2c:	0205b903          	ld	s2,32(a1)
    80002a30:	0285b983          	ld	s3,40(a1)
    80002a34:	0305ba03          	ld	s4,48(a1)
    80002a38:	0385ba83          	ld	s5,56(a1)
    80002a3c:	0405bb03          	ld	s6,64(a1)
    80002a40:	0485bb83          	ld	s7,72(a1)
    80002a44:	0505bc03          	ld	s8,80(a1)
    80002a48:	0585bc83          	ld	s9,88(a1)
    80002a4c:	0605bd03          	ld	s10,96(a1)
    80002a50:	0685bd83          	ld	s11,104(a1)
    80002a54:	8082                	ret

0000000080002a56 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a56:	1141                	addi	sp,sp,-16
    80002a58:	e406                	sd	ra,8(sp)
    80002a5a:	e022                	sd	s0,0(sp)
    80002a5c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a5e:	00006597          	auipc	a1,0x6
    80002a62:	8c258593          	addi	a1,a1,-1854 # 80008320 <states.1811+0x30>
    80002a66:	00016517          	auipc	a0,0x16
    80002a6a:	4e250513          	addi	a0,a0,1250 # 80018f48 <tickslock>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	0e6080e7          	jalr	230(ra) # 80000b54 <initlock>
}
    80002a76:	60a2                	ld	ra,8(sp)
    80002a78:	6402                	ld	s0,0(sp)
    80002a7a:	0141                	addi	sp,sp,16
    80002a7c:	8082                	ret

0000000080002a7e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a7e:	1141                	addi	sp,sp,-16
    80002a80:	e422                	sd	s0,8(sp)
    80002a82:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a84:	00003797          	auipc	a5,0x3
    80002a88:	6dc78793          	addi	a5,a5,1756 # 80006160 <kernelvec>
    80002a8c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a90:	6422                	ld	s0,8(sp)
    80002a92:	0141                	addi	sp,sp,16
    80002a94:	8082                	ret

0000000080002a96 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a96:	1141                	addi	sp,sp,-16
    80002a98:	e406                	sd	ra,8(sp)
    80002a9a:	e022                	sd	s0,0(sp)
    80002a9c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	05e080e7          	jalr	94(ra) # 80001afc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002aaa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aac:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ab0:	00004617          	auipc	a2,0x4
    80002ab4:	55060613          	addi	a2,a2,1360 # 80007000 <_trampoline>
    80002ab8:	00004697          	auipc	a3,0x4
    80002abc:	54868693          	addi	a3,a3,1352 # 80007000 <_trampoline>
    80002ac0:	8e91                	sub	a3,a3,a2
    80002ac2:	040007b7          	lui	a5,0x4000
    80002ac6:	17fd                	addi	a5,a5,-1
    80002ac8:	07b2                	slli	a5,a5,0xc
    80002aca:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002acc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ad0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ad2:	180026f3          	csrr	a3,satp
    80002ad6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ad8:	6d38                	ld	a4,88(a0)
    80002ada:	6134                	ld	a3,64(a0)
    80002adc:	6585                	lui	a1,0x1
    80002ade:	96ae                	add	a3,a3,a1
    80002ae0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ae2:	6d38                	ld	a4,88(a0)
    80002ae4:	00000697          	auipc	a3,0x0
    80002ae8:	14668693          	addi	a3,a3,326 # 80002c2a <usertrap>
    80002aec:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002aee:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002af0:	8692                	mv	a3,tp
    80002af2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002af8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002afc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b00:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b04:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b06:	6f18                	ld	a4,24(a4)
    80002b08:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b0c:	692c                	ld	a1,80(a0)
    80002b0e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b10:	00004717          	auipc	a4,0x4
    80002b14:	58070713          	addi	a4,a4,1408 # 80007090 <userret>
    80002b18:	8f11                	sub	a4,a4,a2
    80002b1a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b1c:	577d                	li	a4,-1
    80002b1e:	177e                	slli	a4,a4,0x3f
    80002b20:	8dd9                	or	a1,a1,a4
    80002b22:	02000537          	lui	a0,0x2000
    80002b26:	157d                	addi	a0,a0,-1
    80002b28:	0536                	slli	a0,a0,0xd
    80002b2a:	9782                	jalr	a5
}
    80002b2c:	60a2                	ld	ra,8(sp)
    80002b2e:	6402                	ld	s0,0(sp)
    80002b30:	0141                	addi	sp,sp,16
    80002b32:	8082                	ret

0000000080002b34 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b34:	1101                	addi	sp,sp,-32
    80002b36:	ec06                	sd	ra,24(sp)
    80002b38:	e822                	sd	s0,16(sp)
    80002b3a:	e426                	sd	s1,8(sp)
    80002b3c:	e04a                	sd	s2,0(sp)
    80002b3e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b40:	00016917          	auipc	s2,0x16
    80002b44:	40890913          	addi	s2,s2,1032 # 80018f48 <tickslock>
    80002b48:	854a                	mv	a0,s2
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
  ticks++;
    80002b52:	00006497          	auipc	s1,0x6
    80002b56:	4de48493          	addi	s1,s1,1246 # 80009030 <ticks>
    80002b5a:	409c                	lw	a5,0(s1)
    80002b5c:	2785                	addiw	a5,a5,1
    80002b5e:	c09c                	sw	a5,0(s1)
  update_time();
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	4d6080e7          	jalr	1238(ra) # 80002036 <update_time>
  wakeup(&ticks);
    80002b68:	8526                	mv	a0,s1
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	a5e080e7          	jalr	-1442(ra) # 800025c8 <wakeup>
  release(&tickslock);
    80002b72:	854a                	mv	a0,s2
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
}
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6902                	ld	s2,0(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret

0000000080002b88 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b88:	1101                	addi	sp,sp,-32
    80002b8a:	ec06                	sd	ra,24(sp)
    80002b8c:	e822                	sd	s0,16(sp)
    80002b8e:	e426                	sd	s1,8(sp)
    80002b90:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b92:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b96:	00074d63          	bltz	a4,80002bb0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b9a:	57fd                	li	a5,-1
    80002b9c:	17fe                	slli	a5,a5,0x3f
    80002b9e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ba0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ba2:	06f70363          	beq	a4,a5,80002c08 <devintr+0x80>
  }
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret
     (scause & 0xff) == 9){
    80002bb0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002bb4:	46a5                	li	a3,9
    80002bb6:	fed792e3          	bne	a5,a3,80002b9a <devintr+0x12>
    int irq = plic_claim();
    80002bba:	00003097          	auipc	ra,0x3
    80002bbe:	6ae080e7          	jalr	1710(ra) # 80006268 <plic_claim>
    80002bc2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bc4:	47a9                	li	a5,10
    80002bc6:	02f50763          	beq	a0,a5,80002bf4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bca:	4785                	li	a5,1
    80002bcc:	02f50963          	beq	a0,a5,80002bfe <devintr+0x76>
    return 1;
    80002bd0:	4505                	li	a0,1
    } else if(irq){
    80002bd2:	d8f1                	beqz	s1,80002ba6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bd4:	85a6                	mv	a1,s1
    80002bd6:	00005517          	auipc	a0,0x5
    80002bda:	75250513          	addi	a0,a0,1874 # 80008328 <states.1811+0x38>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9aa080e7          	jalr	-1622(ra) # 80000588 <printf>
      plic_complete(irq);
    80002be6:	8526                	mv	a0,s1
    80002be8:	00003097          	auipc	ra,0x3
    80002bec:	6a4080e7          	jalr	1700(ra) # 8000628c <plic_complete>
    return 1;
    80002bf0:	4505                	li	a0,1
    80002bf2:	bf55                	j	80002ba6 <devintr+0x1e>
      uartintr();
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	db4080e7          	jalr	-588(ra) # 800009a8 <uartintr>
    80002bfc:	b7ed                	j	80002be6 <devintr+0x5e>
      virtio_disk_intr();
    80002bfe:	00004097          	auipc	ra,0x4
    80002c02:	b6e080e7          	jalr	-1170(ra) # 8000676c <virtio_disk_intr>
    80002c06:	b7c5                	j	80002be6 <devintr+0x5e>
    if(cpuid() == 0){
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	ec8080e7          	jalr	-312(ra) # 80001ad0 <cpuid>
    80002c10:	c901                	beqz	a0,80002c20 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c12:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c18:	14479073          	csrw	sip,a5
    return 2;
    80002c1c:	4509                	li	a0,2
    80002c1e:	b761                	j	80002ba6 <devintr+0x1e>
      clockintr();
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	f14080e7          	jalr	-236(ra) # 80002b34 <clockintr>
    80002c28:	b7ed                	j	80002c12 <devintr+0x8a>

0000000080002c2a <usertrap>:
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	e04a                	sd	s2,0(sp)
    80002c34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c36:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c3a:	1007f793          	andi	a5,a5,256
    80002c3e:	e3ad                	bnez	a5,80002ca0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c40:	00003797          	auipc	a5,0x3
    80002c44:	52078793          	addi	a5,a5,1312 # 80006160 <kernelvec>
    80002c48:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	eb0080e7          	jalr	-336(ra) # 80001afc <myproc>
    80002c54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c56:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c58:	14102773          	csrr	a4,sepc
    80002c5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c62:	47a1                	li	a5,8
    80002c64:	04f71c63          	bne	a4,a5,80002cbc <usertrap+0x92>
    if(p->killed)
    80002c68:	551c                	lw	a5,40(a0)
    80002c6a:	e3b9                	bnez	a5,80002cb0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c6c:	6cb8                	ld	a4,88(s1)
    80002c6e:	6f1c                	ld	a5,24(a4)
    80002c70:	0791                	addi	a5,a5,4
    80002c72:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c78:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7c:	10079073          	csrw	sstatus,a5
    syscall();
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	2e0080e7          	jalr	736(ra) # 80002f60 <syscall>
  if(p->killed)
    80002c88:	549c                	lw	a5,40(s1)
    80002c8a:	ebc1                	bnez	a5,80002d1a <usertrap+0xf0>
  usertrapret();
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	e0a080e7          	jalr	-502(ra) # 80002a96 <usertrapret>
}
    80002c94:	60e2                	ld	ra,24(sp)
    80002c96:	6442                	ld	s0,16(sp)
    80002c98:	64a2                	ld	s1,8(sp)
    80002c9a:	6902                	ld	s2,0(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret
    panic("usertrap: not from user mode");
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	6a850513          	addi	a0,a0,1704 # 80008348 <states.1811+0x58>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	896080e7          	jalr	-1898(ra) # 8000053e <panic>
      exit(-1);
    80002cb0:	557d                	li	a0,-1
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	9e6080e7          	jalr	-1562(ra) # 80002698 <exit>
    80002cba:	bf4d                	j	80002c6c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	ecc080e7          	jalr	-308(ra) # 80002b88 <devintr>
    80002cc4:	892a                	mv	s2,a0
    80002cc6:	c501                	beqz	a0,80002cce <usertrap+0xa4>
  if(p->killed)
    80002cc8:	549c                	lw	a5,40(s1)
    80002cca:	c3a1                	beqz	a5,80002d0a <usertrap+0xe0>
    80002ccc:	a815                	j	80002d00 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cd2:	5890                	lw	a2,48(s1)
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	69450513          	addi	a0,a0,1684 # 80008368 <states.1811+0x78>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	8ac080e7          	jalr	-1876(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ce8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	6ac50513          	addi	a0,a0,1708 # 80008398 <states.1811+0xa8>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	894080e7          	jalr	-1900(ra) # 80000588 <printf>
    p->killed = 1;
    80002cfc:	4785                	li	a5,1
    80002cfe:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d00:	557d                	li	a0,-1
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	996080e7          	jalr	-1642(ra) # 80002698 <exit>
  if(which_dev == 2)
    80002d0a:	4789                	li	a5,2
    80002d0c:	f8f910e3          	bne	s2,a5,80002c8c <usertrap+0x62>
    yield();
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	5a4080e7          	jalr	1444(ra) # 800022b4 <yield>
    80002d18:	bf95                	j	80002c8c <usertrap+0x62>
  int which_dev = 0;
    80002d1a:	4901                	li	s2,0
    80002d1c:	b7d5                	j	80002d00 <usertrap+0xd6>

0000000080002d1e <kerneltrap>:
{
    80002d1e:	7179                	addi	sp,sp,-48
    80002d20:	f406                	sd	ra,40(sp)
    80002d22:	f022                	sd	s0,32(sp)
    80002d24:	ec26                	sd	s1,24(sp)
    80002d26:	e84a                	sd	s2,16(sp)
    80002d28:	e44e                	sd	s3,8(sp)
    80002d2a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d30:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d34:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d38:	1004f793          	andi	a5,s1,256
    80002d3c:	cb85                	beqz	a5,80002d6c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d42:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d44:	ef85                	bnez	a5,80002d7c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	e42080e7          	jalr	-446(ra) # 80002b88 <devintr>
    80002d4e:	cd1d                	beqz	a0,80002d8c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d50:	4789                	li	a5,2
    80002d52:	06f50a63          	beq	a0,a5,80002dc6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d56:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d5a:	10049073          	csrw	sstatus,s1
}
    80002d5e:	70a2                	ld	ra,40(sp)
    80002d60:	7402                	ld	s0,32(sp)
    80002d62:	64e2                	ld	s1,24(sp)
    80002d64:	6942                	ld	s2,16(sp)
    80002d66:	69a2                	ld	s3,8(sp)
    80002d68:	6145                	addi	sp,sp,48
    80002d6a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d6c:	00005517          	auipc	a0,0x5
    80002d70:	64c50513          	addi	a0,a0,1612 # 800083b8 <states.1811+0xc8>
    80002d74:	ffffd097          	auipc	ra,0xffffd
    80002d78:	7ca080e7          	jalr	1994(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d7c:	00005517          	auipc	a0,0x5
    80002d80:	66450513          	addi	a0,a0,1636 # 800083e0 <states.1811+0xf0>
    80002d84:	ffffd097          	auipc	ra,0xffffd
    80002d88:	7ba080e7          	jalr	1978(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002d8c:	85ce                	mv	a1,s3
    80002d8e:	00005517          	auipc	a0,0x5
    80002d92:	67250513          	addi	a0,a0,1650 # 80008400 <states.1811+0x110>
    80002d96:	ffffd097          	auipc	ra,0xffffd
    80002d9a:	7f2080e7          	jalr	2034(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d9e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002da2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002da6:	00005517          	auipc	a0,0x5
    80002daa:	66a50513          	addi	a0,a0,1642 # 80008410 <states.1811+0x120>
    80002dae:	ffffd097          	auipc	ra,0xffffd
    80002db2:	7da080e7          	jalr	2010(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002db6:	00005517          	auipc	a0,0x5
    80002dba:	67250513          	addi	a0,a0,1650 # 80008428 <states.1811+0x138>
    80002dbe:	ffffd097          	auipc	ra,0xffffd
    80002dc2:	780080e7          	jalr	1920(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	d36080e7          	jalr	-714(ra) # 80001afc <myproc>
    80002dce:	d541                	beqz	a0,80002d56 <kerneltrap+0x38>
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	d2c080e7          	jalr	-724(ra) # 80001afc <myproc>
    80002dd8:	4d18                	lw	a4,24(a0)
    80002dda:	4791                	li	a5,4
    80002ddc:	f6f71de3          	bne	a4,a5,80002d56 <kerneltrap+0x38>
    yield();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	4d4080e7          	jalr	1236(ra) # 800022b4 <yield>
    80002de8:	b7bd                	j	80002d56 <kerneltrap+0x38>

0000000080002dea <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	e426                	sd	s1,8(sp)
    80002df2:	1000                	addi	s0,sp,32
    80002df4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	d06080e7          	jalr	-762(ra) # 80001afc <myproc>
  switch (n) {
    80002dfe:	4795                	li	a5,5
    80002e00:	0497e163          	bltu	a5,s1,80002e42 <argraw+0x58>
    80002e04:	048a                	slli	s1,s1,0x2
    80002e06:	00005717          	auipc	a4,0x5
    80002e0a:	74a70713          	addi	a4,a4,1866 # 80008550 <states.1811+0x260>
    80002e0e:	94ba                	add	s1,s1,a4
    80002e10:	409c                	lw	a5,0(s1)
    80002e12:	97ba                	add	a5,a5,a4
    80002e14:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e16:	6d3c                	ld	a5,88(a0)
    80002e18:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e1a:	60e2                	ld	ra,24(sp)
    80002e1c:	6442                	ld	s0,16(sp)
    80002e1e:	64a2                	ld	s1,8(sp)
    80002e20:	6105                	addi	sp,sp,32
    80002e22:	8082                	ret
    return p->trapframe->a1;
    80002e24:	6d3c                	ld	a5,88(a0)
    80002e26:	7fa8                	ld	a0,120(a5)
    80002e28:	bfcd                	j	80002e1a <argraw+0x30>
    return p->trapframe->a2;
    80002e2a:	6d3c                	ld	a5,88(a0)
    80002e2c:	63c8                	ld	a0,128(a5)
    80002e2e:	b7f5                	j	80002e1a <argraw+0x30>
    return p->trapframe->a3;
    80002e30:	6d3c                	ld	a5,88(a0)
    80002e32:	67c8                	ld	a0,136(a5)
    80002e34:	b7dd                	j	80002e1a <argraw+0x30>
    return p->trapframe->a4;
    80002e36:	6d3c                	ld	a5,88(a0)
    80002e38:	6bc8                	ld	a0,144(a5)
    80002e3a:	b7c5                	j	80002e1a <argraw+0x30>
    return p->trapframe->a5;
    80002e3c:	6d3c                	ld	a5,88(a0)
    80002e3e:	6fc8                	ld	a0,152(a5)
    80002e40:	bfe9                	j	80002e1a <argraw+0x30>
  panic("argraw");
    80002e42:	00005517          	auipc	a0,0x5
    80002e46:	5f650513          	addi	a0,a0,1526 # 80008438 <states.1811+0x148>
    80002e4a:	ffffd097          	auipc	ra,0xffffd
    80002e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>

0000000080002e52 <fetchaddr>:
{
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	e426                	sd	s1,8(sp)
    80002e5a:	e04a                	sd	s2,0(sp)
    80002e5c:	1000                	addi	s0,sp,32
    80002e5e:	84aa                	mv	s1,a0
    80002e60:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	c9a080e7          	jalr	-870(ra) # 80001afc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e6a:	653c                	ld	a5,72(a0)
    80002e6c:	02f4f863          	bgeu	s1,a5,80002e9c <fetchaddr+0x4a>
    80002e70:	00848713          	addi	a4,s1,8
    80002e74:	02e7e663          	bltu	a5,a4,80002ea0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e78:	46a1                	li	a3,8
    80002e7a:	8626                	mv	a2,s1
    80002e7c:	85ca                	mv	a1,s2
    80002e7e:	6928                	ld	a0,80(a0)
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	886080e7          	jalr	-1914(ra) # 80001706 <copyin>
    80002e88:	00a03533          	snez	a0,a0
    80002e8c:	40a00533          	neg	a0,a0
}
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	64a2                	ld	s1,8(sp)
    80002e96:	6902                	ld	s2,0(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret
    return -1;
    80002e9c:	557d                	li	a0,-1
    80002e9e:	bfcd                	j	80002e90 <fetchaddr+0x3e>
    80002ea0:	557d                	li	a0,-1
    80002ea2:	b7fd                	j	80002e90 <fetchaddr+0x3e>

0000000080002ea4 <fetchstr>:
{
    80002ea4:	7179                	addi	sp,sp,-48
    80002ea6:	f406                	sd	ra,40(sp)
    80002ea8:	f022                	sd	s0,32(sp)
    80002eaa:	ec26                	sd	s1,24(sp)
    80002eac:	e84a                	sd	s2,16(sp)
    80002eae:	e44e                	sd	s3,8(sp)
    80002eb0:	1800                	addi	s0,sp,48
    80002eb2:	892a                	mv	s2,a0
    80002eb4:	84ae                	mv	s1,a1
    80002eb6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	c44080e7          	jalr	-956(ra) # 80001afc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ec0:	86ce                	mv	a3,s3
    80002ec2:	864a                	mv	a2,s2
    80002ec4:	85a6                	mv	a1,s1
    80002ec6:	6928                	ld	a0,80(a0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	8ca080e7          	jalr	-1846(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002ed0:	00054763          	bltz	a0,80002ede <fetchstr+0x3a>
  return strlen(buf);
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	f8e080e7          	jalr	-114(ra) # 80000e64 <strlen>
}
    80002ede:	70a2                	ld	ra,40(sp)
    80002ee0:	7402                	ld	s0,32(sp)
    80002ee2:	64e2                	ld	s1,24(sp)
    80002ee4:	6942                	ld	s2,16(sp)
    80002ee6:	69a2                	ld	s3,8(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret

0000000080002eec <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002eec:	1101                	addi	sp,sp,-32
    80002eee:	ec06                	sd	ra,24(sp)
    80002ef0:	e822                	sd	s0,16(sp)
    80002ef2:	e426                	sd	s1,8(sp)
    80002ef4:	1000                	addi	s0,sp,32
    80002ef6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	ef2080e7          	jalr	-270(ra) # 80002dea <argraw>
    80002f00:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f02:	4501                	li	a0,0
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	64a2                	ld	s1,8(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret

0000000080002f0e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f0e:	1101                	addi	sp,sp,-32
    80002f10:	ec06                	sd	ra,24(sp)
    80002f12:	e822                	sd	s0,16(sp)
    80002f14:	e426                	sd	s1,8(sp)
    80002f16:	1000                	addi	s0,sp,32
    80002f18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	ed0080e7          	jalr	-304(ra) # 80002dea <argraw>
    80002f22:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f24:	4501                	li	a0,0
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	64a2                	ld	s1,8(sp)
    80002f2c:	6105                	addi	sp,sp,32
    80002f2e:	8082                	ret

0000000080002f30 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	e426                	sd	s1,8(sp)
    80002f38:	e04a                	sd	s2,0(sp)
    80002f3a:	1000                	addi	s0,sp,32
    80002f3c:	84ae                	mv	s1,a1
    80002f3e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f40:	00000097          	auipc	ra,0x0
    80002f44:	eaa080e7          	jalr	-342(ra) # 80002dea <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f48:	864a                	mv	a2,s2
    80002f4a:	85a6                	mv	a1,s1
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	f58080e7          	jalr	-168(ra) # 80002ea4 <fetchstr>
}
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	64a2                	ld	s1,8(sp)
    80002f5a:	6902                	ld	s2,0(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret

0000000080002f60 <syscall>:
struct syscall_arg_info syscall_arg_infos[] = {{ 0, "fork" },{ 1, "exit" },{ 1, "wait" },{ 0, "pipe" },{ 3, "read" },{ 2, "kill" },{ 2, "exec" },{ 1, "fstat" },{ 1, "chdir" },{ 1, "dup" },{ 0, "getpid" },{ 1, "sbrk" },{ 1, "sleep" },{ 0, "uptime" },{ 2, "open" },{ 3, "write" },{ 3, "mknod" },{ 1, "unlink" },{ 2, "link" },{ 1, "mkdir" },{ 1, "close" },{ 1, "trace" },{ 3, "waitx" }, {2, "set_priority"},};

// this function is called from trap.c every time a syscall needs to be executed. It calls the respective syscall handler
void
syscall(void)
{
    80002f60:	711d                	addi	sp,sp,-96
    80002f62:	ec86                	sd	ra,88(sp)
    80002f64:	e8a2                	sd	s0,80(sp)
    80002f66:	e4a6                	sd	s1,72(sp)
    80002f68:	e0ca                	sd	s2,64(sp)
    80002f6a:	fc4e                	sd	s3,56(sp)
    80002f6c:	f852                	sd	s4,48(sp)
    80002f6e:	f456                	sd	s5,40(sp)
    80002f70:	f05a                	sd	s6,32(sp)
    80002f72:	ec5e                	sd	s7,24(sp)
    80002f74:	e862                	sd	s8,16(sp)
    80002f76:	e466                	sd	s9,8(sp)
    80002f78:	e06a                	sd	s10,0(sp)
    80002f7a:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	b80080e7          	jalr	-1152(ra) # 80001afc <myproc>
    80002f84:	8a2a                	mv	s4,a0
  num = p->trapframe->a7; // to get the number of the syscall that was called
    80002f86:	6d24                	ld	s1,88(a0)
    80002f88:	74dc                	ld	a5,168(s1)
    80002f8a:	00078b1b          	sext.w	s6,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f8e:	37fd                	addiw	a5,a5,-1
    80002f90:	475d                	li	a4,23
    80002f92:	06f76f63          	bltu	a4,a5,80003010 <syscall+0xb0>
    80002f96:	003b1713          	slli	a4,s6,0x3
    80002f9a:	00005797          	auipc	a5,0x5
    80002f9e:	5ce78793          	addi	a5,a5,1486 # 80008568 <syscalls>
    80002fa2:	97ba                	add	a5,a5,a4
    80002fa4:	0007bd03          	ld	s10,0(a5)
    80002fa8:	060d0463          	beqz	s10,80003010 <syscall+0xb0>
    80002fac:	8c8a                	mv	s9,sp
    int numargs = syscall_arg_infos[num-1].numargs;
    80002fae:	fffb0c1b          	addiw	s8,s6,-1
    80002fb2:	004c1713          	slli	a4,s8,0x4
    80002fb6:	00006797          	auipc	a5,0x6
    80002fba:	9d278793          	addi	a5,a5,-1582 # 80008988 <syscall_arg_infos>
    80002fbe:	97ba                	add	a5,a5,a4
    80002fc0:	0007a983          	lw	s3,0(a5)
    int syscallArgs[numargs];
    80002fc4:	00299793          	slli	a5,s3,0x2
    80002fc8:	07bd                	addi	a5,a5,15
    80002fca:	9bc1                	andi	a5,a5,-16
    80002fcc:	40f10133          	sub	sp,sp,a5
    80002fd0:	8b8a                	mv	s7,sp
    for (int i = 0; i < numargs; i++)
    80002fd2:	0f305363          	blez	s3,800030b8 <syscall+0x158>
    80002fd6:	8ade                	mv	s5,s7
    80002fd8:	895e                	mv	s2,s7
    80002fda:	4481                	li	s1,0
    {
      syscallArgs[i] = argraw(i);
    80002fdc:	8526                	mv	a0,s1
    80002fde:	00000097          	auipc	ra,0x0
    80002fe2:	e0c080e7          	jalr	-500(ra) # 80002dea <argraw>
    80002fe6:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < numargs; i++)
    80002fea:	2485                	addiw	s1,s1,1
    80002fec:	0911                	addi	s2,s2,4
    80002fee:	fe9997e3          	bne	s3,s1,80002fdc <syscall+0x7c>
    }
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    80002ff2:	058a3483          	ld	s1,88(s4)
    80002ff6:	9d02                	jalr	s10
    80002ff8:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    80002ffa:	4785                	li	a5,1
    80002ffc:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    80003000:	168a2b03          	lw	s6,360(s4)
    80003004:	0167f7b3          	and	a5,a5,s6
    80003008:	2781                	sext.w	a5,a5
    8000300a:	e7a1                	bnez	a5,80003052 <syscall+0xf2>
    8000300c:	8166                	mv	sp,s9
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000300e:	a015                	j	80003032 <syscall+0xd2>
      }
      printf("\b) -> %d\n", p->trapframe->a0);
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80003010:	86da                	mv	a3,s6
    80003012:	158a0613          	addi	a2,s4,344
    80003016:	030a2583          	lw	a1,48(s4)
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	43e50513          	addi	a0,a0,1086 # 80008458 <states.1811+0x168>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	566080e7          	jalr	1382(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000302a:	058a3783          	ld	a5,88(s4)
    8000302e:	577d                	li	a4,-1
    80003030:	fbb8                	sd	a4,112(a5)
  }
}
    80003032:	fa040113          	addi	sp,s0,-96
    80003036:	60e6                	ld	ra,88(sp)
    80003038:	6446                	ld	s0,80(sp)
    8000303a:	64a6                	ld	s1,72(sp)
    8000303c:	6906                	ld	s2,64(sp)
    8000303e:	79e2                	ld	s3,56(sp)
    80003040:	7a42                	ld	s4,48(sp)
    80003042:	7aa2                	ld	s5,40(sp)
    80003044:	7b02                	ld	s6,32(sp)
    80003046:	6be2                	ld	s7,24(sp)
    80003048:	6c42                	ld	s8,16(sp)
    8000304a:	6ca2                	ld	s9,8(sp)
    8000304c:	6d02                	ld	s10,0(sp)
    8000304e:	6125                	addi	sp,sp,96
    80003050:	8082                	ret
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    80003052:	0c12                	slli	s8,s8,0x4
    80003054:	00006797          	auipc	a5,0x6
    80003058:	93478793          	addi	a5,a5,-1740 # 80008988 <syscall_arg_infos>
    8000305c:	9c3e                	add	s8,s8,a5
    8000305e:	008c3603          	ld	a2,8(s8)
    80003062:	030a2583          	lw	a1,48(s4)
    80003066:	00005517          	auipc	a0,0x5
    8000306a:	41250513          	addi	a0,a0,1042 # 80008478 <states.1811+0x188>
    8000306e:	ffffd097          	auipc	ra,0xffffd
    80003072:	51a080e7          	jalr	1306(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    80003076:	fff9879b          	addiw	a5,s3,-1
    8000307a:	1782                	slli	a5,a5,0x20
    8000307c:	9381                	srli	a5,a5,0x20
    8000307e:	0785                	addi	a5,a5,1
    80003080:	078a                	slli	a5,a5,0x2
    80003082:	9bbe                	add	s7,s7,a5
        printf("%d ",syscallArgs[i]);
    80003084:	00005497          	auipc	s1,0x5
    80003088:	3bc48493          	addi	s1,s1,956 # 80008440 <states.1811+0x150>
    8000308c:	000aa583          	lw	a1,0(s5)
    80003090:	8526                	mv	a0,s1
    80003092:	ffffd097          	auipc	ra,0xffffd
    80003096:	4f6080e7          	jalr	1270(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    8000309a:	0a91                	addi	s5,s5,4
    8000309c:	ff7a98e3          	bne	s5,s7,8000308c <syscall+0x12c>
      printf("\b) -> %d\n", p->trapframe->a0);
    800030a0:	058a3783          	ld	a5,88(s4)
    800030a4:	7bac                	ld	a1,112(a5)
    800030a6:	00005517          	auipc	a0,0x5
    800030aa:	3a250513          	addi	a0,a0,930 # 80008448 <states.1811+0x158>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	4da080e7          	jalr	1242(ra) # 80000588 <printf>
    800030b6:	bf99                	j	8000300c <syscall+0xac>
    p->trapframe->a0 = syscalls[num](); // this calls the respective syscall handler and stores return value in a0
    800030b8:	9d02                	jalr	s10
    800030ba:	f8a8                	sd	a0,112(s1)
    int leftshift = 1 << num; // leftshift is the mask for the syscall number
    800030bc:	4785                	li	a5,1
    800030be:	016797bb          	sllw	a5,a5,s6
    if (p->trace_mask & leftshift) // checking if the syscall needs to be traced or not
    800030c2:	168a2703          	lw	a4,360(s4)
    800030c6:	8ff9                	and	a5,a5,a4
    800030c8:	2781                	sext.w	a5,a5
    800030ca:	d3a9                	beqz	a5,8000300c <syscall+0xac>
      printf("%d: syscall %s (",p->pid,syscall_arg_infos[num-1].name);
    800030cc:	0c12                	slli	s8,s8,0x4
    800030ce:	00006797          	auipc	a5,0x6
    800030d2:	8ba78793          	addi	a5,a5,-1862 # 80008988 <syscall_arg_infos>
    800030d6:	97e2                	add	a5,a5,s8
    800030d8:	6790                	ld	a2,8(a5)
    800030da:	030a2583          	lw	a1,48(s4)
    800030de:	00005517          	auipc	a0,0x5
    800030e2:	39a50513          	addi	a0,a0,922 # 80008478 <states.1811+0x188>
    800030e6:	ffffd097          	auipc	ra,0xffffd
    800030ea:	4a2080e7          	jalr	1186(ra) # 80000588 <printf>
      for (int i = 0; i < numargs; i++)
    800030ee:	bf4d                	j	800030a0 <syscall+0x140>

00000000800030f0 <sys_exit>:
//////////// All syscall handler functions are defined here ///////////
//////////// These syscall handlers get arguments from the stack. THe arguments are stored in registers a0,a1 ... inside of the trapframe ///////////

uint64
sys_exit(void)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030f8:	fec40593          	addi	a1,s0,-20
    800030fc:	4501                	li	a0,0
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	dee080e7          	jalr	-530(ra) # 80002eec <argint>
    return -1;
    80003106:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003108:	00054963          	bltz	a0,8000311a <sys_exit+0x2a>
  exit(n);
    8000310c:	fec42503          	lw	a0,-20(s0)
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	588080e7          	jalr	1416(ra) # 80002698 <exit>
  return 0;  // not reached
    80003118:	4781                	li	a5,0
}
    8000311a:	853e                	mv	a0,a5
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret

0000000080003124 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003124:	1141                	addi	sp,sp,-16
    80003126:	e406                	sd	ra,8(sp)
    80003128:	e022                	sd	s0,0(sp)
    8000312a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	9d0080e7          	jalr	-1584(ra) # 80001afc <myproc>
}
    80003134:	5908                	lw	a0,48(a0)
    80003136:	60a2                	ld	ra,8(sp)
    80003138:	6402                	ld	s0,0(sp)
    8000313a:	0141                	addi	sp,sp,16
    8000313c:	8082                	ret

000000008000313e <sys_fork>:

uint64
sys_fork(void)
{
    8000313e:	1141                	addi	sp,sp,-16
    80003140:	e406                	sd	ra,8(sp)
    80003142:	e022                	sd	s0,0(sp)
    80003144:	0800                	addi	s0,sp,16
  return fork();
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	dac080e7          	jalr	-596(ra) # 80001ef2 <fork>
}
    8000314e:	60a2                	ld	ra,8(sp)
    80003150:	6402                	ld	s0,0(sp)
    80003152:	0141                	addi	sp,sp,16
    80003154:	8082                	ret

0000000080003156 <sys_wait>:

uint64
sys_wait(void)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000315e:	fe840593          	addi	a1,s0,-24
    80003162:	4501                	li	a0,0
    80003164:	00000097          	auipc	ra,0x0
    80003168:	daa080e7          	jalr	-598(ra) # 80002f0e <argaddr>
    8000316c:	87aa                	mv	a5,a0
    return -1;
    8000316e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003170:	0007c863          	bltz	a5,80003180 <sys_wait+0x2a>
  return wait(p);
    80003174:	fe843503          	ld	a0,-24(s0)
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	1dc080e7          	jalr	476(ra) # 80002354 <wait>
}
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret

0000000080003188 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003188:	7139                	addi	sp,sp,-64
    8000318a:	fc06                	sd	ra,56(sp)
    8000318c:	f822                	sd	s0,48(sp)
    8000318e:	f426                	sd	s1,40(sp)
    80003190:	f04a                	sd	s2,32(sp)
    80003192:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80003194:	fd840593          	addi	a1,s0,-40
    80003198:	4501                	li	a0,0
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	d74080e7          	jalr	-652(ra) # 80002f0e <argaddr>
    return -1;
    800031a2:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800031a4:	08054063          	bltz	a0,80003224 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800031a8:	fd040593          	addi	a1,s0,-48
    800031ac:	4505                	li	a0,1
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	d60080e7          	jalr	-672(ra) # 80002f0e <argaddr>
    return -1;
    800031b6:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800031b8:	06054663          	bltz	a0,80003224 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    800031bc:	fc840593          	addi	a1,s0,-56
    800031c0:	4509                	li	a0,2
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	d4c080e7          	jalr	-692(ra) # 80002f0e <argaddr>
    return -1;
    800031ca:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800031cc:	04054c63          	bltz	a0,80003224 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800031d0:	fc040613          	addi	a2,s0,-64
    800031d4:	fc440593          	addi	a1,s0,-60
    800031d8:	fd843503          	ld	a0,-40(s0)
    800031dc:	fffff097          	auipc	ra,0xfffff
    800031e0:	2a0080e7          	jalr	672(ra) # 8000247c <waitx>
    800031e4:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800031e6:	fffff097          	auipc	ra,0xfffff
    800031ea:	916080e7          	jalr	-1770(ra) # 80001afc <myproc>
    800031ee:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800031f0:	4691                	li	a3,4
    800031f2:	fc440613          	addi	a2,s0,-60
    800031f6:	fd043583          	ld	a1,-48(s0)
    800031fa:	6928                	ld	a0,80(a0)
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	47e080e7          	jalr	1150(ra) # 8000167a <copyout>
    return -1;
    80003204:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003206:	00054f63          	bltz	a0,80003224 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    8000320a:	4691                	li	a3,4
    8000320c:	fc040613          	addi	a2,s0,-64
    80003210:	fc843583          	ld	a1,-56(s0)
    80003214:	68a8                	ld	a0,80(s1)
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	464080e7          	jalr	1124(ra) # 8000167a <copyout>
    8000321e:	00054a63          	bltz	a0,80003232 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003222:	87ca                	mv	a5,s2
}
    80003224:	853e                	mv	a0,a5
    80003226:	70e2                	ld	ra,56(sp)
    80003228:	7442                	ld	s0,48(sp)
    8000322a:	74a2                	ld	s1,40(sp)
    8000322c:	7902                	ld	s2,32(sp)
    8000322e:	6121                	addi	sp,sp,64
    80003230:	8082                	ret
    return -1;
    80003232:	57fd                	li	a5,-1
    80003234:	bfc5                	j	80003224 <sys_waitx+0x9c>

0000000080003236 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003236:	7179                	addi	sp,sp,-48
    80003238:	f406                	sd	ra,40(sp)
    8000323a:	f022                	sd	s0,32(sp)
    8000323c:	ec26                	sd	s1,24(sp)
    8000323e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003240:	fdc40593          	addi	a1,s0,-36
    80003244:	4501                	li	a0,0
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	ca6080e7          	jalr	-858(ra) # 80002eec <argint>
    8000324e:	87aa                	mv	a5,a0
    return -1;
    80003250:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003252:	0207c063          	bltz	a5,80003272 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	8a6080e7          	jalr	-1882(ra) # 80001afc <myproc>
    8000325e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003260:	fdc42503          	lw	a0,-36(s0)
    80003264:	fffff097          	auipc	ra,0xfffff
    80003268:	c1a080e7          	jalr	-998(ra) # 80001e7e <growproc>
    8000326c:	00054863          	bltz	a0,8000327c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003270:	8526                	mv	a0,s1
}
    80003272:	70a2                	ld	ra,40(sp)
    80003274:	7402                	ld	s0,32(sp)
    80003276:	64e2                	ld	s1,24(sp)
    80003278:	6145                	addi	sp,sp,48
    8000327a:	8082                	ret
    return -1;
    8000327c:	557d                	li	a0,-1
    8000327e:	bfd5                	j	80003272 <sys_sbrk+0x3c>

0000000080003280 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003280:	7139                	addi	sp,sp,-64
    80003282:	fc06                	sd	ra,56(sp)
    80003284:	f822                	sd	s0,48(sp)
    80003286:	f426                	sd	s1,40(sp)
    80003288:	f04a                	sd	s2,32(sp)
    8000328a:	ec4e                	sd	s3,24(sp)
    8000328c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000328e:	fcc40593          	addi	a1,s0,-52
    80003292:	4501                	li	a0,0
    80003294:	00000097          	auipc	ra,0x0
    80003298:	c58080e7          	jalr	-936(ra) # 80002eec <argint>
    return -1;
    8000329c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000329e:	06054563          	bltz	a0,80003308 <sys_sleep+0x88>
  acquire(&tickslock);
    800032a2:	00016517          	auipc	a0,0x16
    800032a6:	ca650513          	addi	a0,a0,-858 # 80018f48 <tickslock>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	93a080e7          	jalr	-1734(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800032b2:	00006917          	auipc	s2,0x6
    800032b6:	d7e92903          	lw	s2,-642(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800032ba:	fcc42783          	lw	a5,-52(s0)
    800032be:	cf85                	beqz	a5,800032f6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032c0:	00016997          	auipc	s3,0x16
    800032c4:	c8898993          	addi	s3,s3,-888 # 80018f48 <tickslock>
    800032c8:	00006497          	auipc	s1,0x6
    800032cc:	d6848493          	addi	s1,s1,-664 # 80009030 <ticks>
    if(myproc()->killed){
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	82c080e7          	jalr	-2004(ra) # 80001afc <myproc>
    800032d8:	551c                	lw	a5,40(a0)
    800032da:	ef9d                	bnez	a5,80003318 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032dc:	85ce                	mv	a1,s3
    800032de:	8526                	mv	a0,s1
    800032e0:	fffff097          	auipc	ra,0xfffff
    800032e4:	010080e7          	jalr	16(ra) # 800022f0 <sleep>
  while(ticks - ticks0 < n){
    800032e8:	409c                	lw	a5,0(s1)
    800032ea:	412787bb          	subw	a5,a5,s2
    800032ee:	fcc42703          	lw	a4,-52(s0)
    800032f2:	fce7efe3          	bltu	a5,a4,800032d0 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032f6:	00016517          	auipc	a0,0x16
    800032fa:	c5250513          	addi	a0,a0,-942 # 80018f48 <tickslock>
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	99a080e7          	jalr	-1638(ra) # 80000c98 <release>
  return 0;
    80003306:	4781                	li	a5,0
}
    80003308:	853e                	mv	a0,a5
    8000330a:	70e2                	ld	ra,56(sp)
    8000330c:	7442                	ld	s0,48(sp)
    8000330e:	74a2                	ld	s1,40(sp)
    80003310:	7902                	ld	s2,32(sp)
    80003312:	69e2                	ld	s3,24(sp)
    80003314:	6121                	addi	sp,sp,64
    80003316:	8082                	ret
      release(&tickslock);
    80003318:	00016517          	auipc	a0,0x16
    8000331c:	c3050513          	addi	a0,a0,-976 # 80018f48 <tickslock>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	978080e7          	jalr	-1672(ra) # 80000c98 <release>
      return -1;
    80003328:	57fd                	li	a5,-1
    8000332a:	bff9                	j	80003308 <sys_sleep+0x88>

000000008000332c <sys_kill>:

uint64
sys_kill(void)
{
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003334:	fec40593          	addi	a1,s0,-20
    80003338:	4501                	li	a0,0
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	bb2080e7          	jalr	-1102(ra) # 80002eec <argint>
    80003342:	87aa                	mv	a5,a0
    return -1;
    80003344:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003346:	0007c863          	bltz	a5,80003356 <sys_kill+0x2a>
  return kill(pid);
    8000334a:	fec42503          	lw	a0,-20(s0)
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	42c080e7          	jalr	1068(ra) # 8000277a <kill>
}
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	6105                	addi	sp,sp,32
    8000335c:	8082                	ret

000000008000335e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000335e:	1101                	addi	sp,sp,-32
    80003360:	ec06                	sd	ra,24(sp)
    80003362:	e822                	sd	s0,16(sp)
    80003364:	e426                	sd	s1,8(sp)
    80003366:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003368:	00016517          	auipc	a0,0x16
    8000336c:	be050513          	addi	a0,a0,-1056 # 80018f48 <tickslock>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003378:	00006497          	auipc	s1,0x6
    8000337c:	cb84a483          	lw	s1,-840(s1) # 80009030 <ticks>
  release(&tickslock);
    80003380:	00016517          	auipc	a0,0x16
    80003384:	bc850513          	addi	a0,a0,-1080 # 80018f48 <tickslock>
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
  return xticks;
}
    80003390:	02049513          	slli	a0,s1,0x20
    80003394:	9101                	srli	a0,a0,0x20
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <sys_trace>:

// fetches syscall arguments
uint64
sys_trace(void)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n); // gets the first argument of the syscall
    800033a8:	fec40593          	addi	a1,s0,-20
    800033ac:	4501                	li	a0,0
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	b3e080e7          	jalr	-1218(ra) # 80002eec <argint>
  trace(n);
    800033b6:	fec42503          	lw	a0,-20(s0)
    800033ba:	fffff097          	auipc	ra,0xfffff
    800033be:	58c080e7          	jalr	1420(ra) # 80002946 <trace>
  return 0; // if the syscall is successful, return 0
}
    800033c2:	4501                	li	a0,0
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret

00000000800033cc <sys_set_priority>:

// to change the static priority of a process with given pid
uint64
sys_set_priority(void)
{
    800033cc:	1101                	addi	sp,sp,-32
    800033ce:	ec06                	sd	ra,24(sp)
    800033d0:	e822                	sd	s0,16(sp)
    800033d2:	1000                	addi	s0,sp,32
  int pid, new_priority;
  if(argint(0, &new_priority) < 0)
    800033d4:	fe840593          	addi	a1,s0,-24
    800033d8:	4501                	li	a0,0
    800033da:	00000097          	auipc	ra,0x0
    800033de:	b12080e7          	jalr	-1262(ra) # 80002eec <argint>
    return -1;
    800033e2:	57fd                	li	a5,-1
  if(argint(0, &new_priority) < 0)
    800033e4:	02054563          	bltz	a0,8000340e <sys_set_priority+0x42>
  if(argint(1, &pid) < 0)
    800033e8:	fec40593          	addi	a1,s0,-20
    800033ec:	4505                	li	a0,1
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	afe080e7          	jalr	-1282(ra) # 80002eec <argint>
    return -1;
    800033f6:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    800033f8:	00054b63          	bltz	a0,8000340e <sys_set_priority+0x42>
  return set_priority(new_priority, pid);
    800033fc:	fec42583          	lw	a1,-20(s0)
    80003400:	fe842503          	lw	a0,-24(s0)
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	564080e7          	jalr	1380(ra) # 80002968 <set_priority>
    8000340c:	87aa                	mv	a5,a0
    8000340e:	853e                	mv	a0,a5
    80003410:	60e2                	ld	ra,24(sp)
    80003412:	6442                	ld	s0,16(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret

0000000080003418 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	e052                	sd	s4,0(sp)
    80003426:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003428:	00005597          	auipc	a1,0x5
    8000342c:	20858593          	addi	a1,a1,520 # 80008630 <syscalls+0xc8>
    80003430:	00016517          	auipc	a0,0x16
    80003434:	b3050513          	addi	a0,a0,-1232 # 80018f60 <bcache>
    80003438:	ffffd097          	auipc	ra,0xffffd
    8000343c:	71c080e7          	jalr	1820(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003440:	0001e797          	auipc	a5,0x1e
    80003444:	b2078793          	addi	a5,a5,-1248 # 80020f60 <bcache+0x8000>
    80003448:	0001e717          	auipc	a4,0x1e
    8000344c:	d8070713          	addi	a4,a4,-640 # 800211c8 <bcache+0x8268>
    80003450:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003454:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003458:	00016497          	auipc	s1,0x16
    8000345c:	b2048493          	addi	s1,s1,-1248 # 80018f78 <bcache+0x18>
    b->next = bcache.head.next;
    80003460:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003462:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003464:	00005a17          	auipc	s4,0x5
    80003468:	1d4a0a13          	addi	s4,s4,468 # 80008638 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000346c:	2b893783          	ld	a5,696(s2)
    80003470:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003472:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003476:	85d2                	mv	a1,s4
    80003478:	01048513          	addi	a0,s1,16
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	4bc080e7          	jalr	1212(ra) # 80004938 <initsleeplock>
    bcache.head.next->prev = b;
    80003484:	2b893783          	ld	a5,696(s2)
    80003488:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000348a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000348e:	45848493          	addi	s1,s1,1112
    80003492:	fd349de3          	bne	s1,s3,8000346c <binit+0x54>
  }
}
    80003496:	70a2                	ld	ra,40(sp)
    80003498:	7402                	ld	s0,32(sp)
    8000349a:	64e2                	ld	s1,24(sp)
    8000349c:	6942                	ld	s2,16(sp)
    8000349e:	69a2                	ld	s3,8(sp)
    800034a0:	6a02                	ld	s4,0(sp)
    800034a2:	6145                	addi	sp,sp,48
    800034a4:	8082                	ret

00000000800034a6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034a6:	7179                	addi	sp,sp,-48
    800034a8:	f406                	sd	ra,40(sp)
    800034aa:	f022                	sd	s0,32(sp)
    800034ac:	ec26                	sd	s1,24(sp)
    800034ae:	e84a                	sd	s2,16(sp)
    800034b0:	e44e                	sd	s3,8(sp)
    800034b2:	1800                	addi	s0,sp,48
    800034b4:	89aa                	mv	s3,a0
    800034b6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800034b8:	00016517          	auipc	a0,0x16
    800034bc:	aa850513          	addi	a0,a0,-1368 # 80018f60 <bcache>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	724080e7          	jalr	1828(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034c8:	0001e497          	auipc	s1,0x1e
    800034cc:	d504b483          	ld	s1,-688(s1) # 80021218 <bcache+0x82b8>
    800034d0:	0001e797          	auipc	a5,0x1e
    800034d4:	cf878793          	addi	a5,a5,-776 # 800211c8 <bcache+0x8268>
    800034d8:	02f48f63          	beq	s1,a5,80003516 <bread+0x70>
    800034dc:	873e                	mv	a4,a5
    800034de:	a021                	j	800034e6 <bread+0x40>
    800034e0:	68a4                	ld	s1,80(s1)
    800034e2:	02e48a63          	beq	s1,a4,80003516 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034e6:	449c                	lw	a5,8(s1)
    800034e8:	ff379ce3          	bne	a5,s3,800034e0 <bread+0x3a>
    800034ec:	44dc                	lw	a5,12(s1)
    800034ee:	ff2799e3          	bne	a5,s2,800034e0 <bread+0x3a>
      b->refcnt++;
    800034f2:	40bc                	lw	a5,64(s1)
    800034f4:	2785                	addiw	a5,a5,1
    800034f6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034f8:	00016517          	auipc	a0,0x16
    800034fc:	a6850513          	addi	a0,a0,-1432 # 80018f60 <bcache>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	798080e7          	jalr	1944(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003508:	01048513          	addi	a0,s1,16
    8000350c:	00001097          	auipc	ra,0x1
    80003510:	466080e7          	jalr	1126(ra) # 80004972 <acquiresleep>
      return b;
    80003514:	a8b9                	j	80003572 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003516:	0001e497          	auipc	s1,0x1e
    8000351a:	cfa4b483          	ld	s1,-774(s1) # 80021210 <bcache+0x82b0>
    8000351e:	0001e797          	auipc	a5,0x1e
    80003522:	caa78793          	addi	a5,a5,-854 # 800211c8 <bcache+0x8268>
    80003526:	00f48863          	beq	s1,a5,80003536 <bread+0x90>
    8000352a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000352c:	40bc                	lw	a5,64(s1)
    8000352e:	cf81                	beqz	a5,80003546 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003530:	64a4                	ld	s1,72(s1)
    80003532:	fee49de3          	bne	s1,a4,8000352c <bread+0x86>
  panic("bget: no buffers");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	10a50513          	addi	a0,a0,266 # 80008640 <syscalls+0xd8>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	000080e7          	jalr	ra # 8000053e <panic>
      b->dev = dev;
    80003546:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000354a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000354e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003552:	4785                	li	a5,1
    80003554:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003556:	00016517          	auipc	a0,0x16
    8000355a:	a0a50513          	addi	a0,a0,-1526 # 80018f60 <bcache>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	73a080e7          	jalr	1850(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003566:	01048513          	addi	a0,s1,16
    8000356a:	00001097          	auipc	ra,0x1
    8000356e:	408080e7          	jalr	1032(ra) # 80004972 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003572:	409c                	lw	a5,0(s1)
    80003574:	cb89                	beqz	a5,80003586 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003576:	8526                	mv	a0,s1
    80003578:	70a2                	ld	ra,40(sp)
    8000357a:	7402                	ld	s0,32(sp)
    8000357c:	64e2                	ld	s1,24(sp)
    8000357e:	6942                	ld	s2,16(sp)
    80003580:	69a2                	ld	s3,8(sp)
    80003582:	6145                	addi	sp,sp,48
    80003584:	8082                	ret
    virtio_disk_rw(b, 0);
    80003586:	4581                	li	a1,0
    80003588:	8526                	mv	a0,s1
    8000358a:	00003097          	auipc	ra,0x3
    8000358e:	f0c080e7          	jalr	-244(ra) # 80006496 <virtio_disk_rw>
    b->valid = 1;
    80003592:	4785                	li	a5,1
    80003594:	c09c                	sw	a5,0(s1)
  return b;
    80003596:	b7c5                	j	80003576 <bread+0xd0>

0000000080003598 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003598:	1101                	addi	sp,sp,-32
    8000359a:	ec06                	sd	ra,24(sp)
    8000359c:	e822                	sd	s0,16(sp)
    8000359e:	e426                	sd	s1,8(sp)
    800035a0:	1000                	addi	s0,sp,32
    800035a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035a4:	0541                	addi	a0,a0,16
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	466080e7          	jalr	1126(ra) # 80004a0c <holdingsleep>
    800035ae:	cd01                	beqz	a0,800035c6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035b0:	4585                	li	a1,1
    800035b2:	8526                	mv	a0,s1
    800035b4:	00003097          	auipc	ra,0x3
    800035b8:	ee2080e7          	jalr	-286(ra) # 80006496 <virtio_disk_rw>
}
    800035bc:	60e2                	ld	ra,24(sp)
    800035be:	6442                	ld	s0,16(sp)
    800035c0:	64a2                	ld	s1,8(sp)
    800035c2:	6105                	addi	sp,sp,32
    800035c4:	8082                	ret
    panic("bwrite");
    800035c6:	00005517          	auipc	a0,0x5
    800035ca:	09250513          	addi	a0,a0,146 # 80008658 <syscalls+0xf0>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800035d6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035d6:	1101                	addi	sp,sp,-32
    800035d8:	ec06                	sd	ra,24(sp)
    800035da:	e822                	sd	s0,16(sp)
    800035dc:	e426                	sd	s1,8(sp)
    800035de:	e04a                	sd	s2,0(sp)
    800035e0:	1000                	addi	s0,sp,32
    800035e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035e4:	01050913          	addi	s2,a0,16
    800035e8:	854a                	mv	a0,s2
    800035ea:	00001097          	auipc	ra,0x1
    800035ee:	422080e7          	jalr	1058(ra) # 80004a0c <holdingsleep>
    800035f2:	c92d                	beqz	a0,80003664 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035f4:	854a                	mv	a0,s2
    800035f6:	00001097          	auipc	ra,0x1
    800035fa:	3d2080e7          	jalr	978(ra) # 800049c8 <releasesleep>

  acquire(&bcache.lock);
    800035fe:	00016517          	auipc	a0,0x16
    80003602:	96250513          	addi	a0,a0,-1694 # 80018f60 <bcache>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	5de080e7          	jalr	1502(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000360e:	40bc                	lw	a5,64(s1)
    80003610:	37fd                	addiw	a5,a5,-1
    80003612:	0007871b          	sext.w	a4,a5
    80003616:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003618:	eb05                	bnez	a4,80003648 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000361a:	68bc                	ld	a5,80(s1)
    8000361c:	64b8                	ld	a4,72(s1)
    8000361e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003620:	64bc                	ld	a5,72(s1)
    80003622:	68b8                	ld	a4,80(s1)
    80003624:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003626:	0001e797          	auipc	a5,0x1e
    8000362a:	93a78793          	addi	a5,a5,-1734 # 80020f60 <bcache+0x8000>
    8000362e:	2b87b703          	ld	a4,696(a5)
    80003632:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003634:	0001e717          	auipc	a4,0x1e
    80003638:	b9470713          	addi	a4,a4,-1132 # 800211c8 <bcache+0x8268>
    8000363c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000363e:	2b87b703          	ld	a4,696(a5)
    80003642:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003644:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003648:	00016517          	auipc	a0,0x16
    8000364c:	91850513          	addi	a0,a0,-1768 # 80018f60 <bcache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	648080e7          	jalr	1608(ra) # 80000c98 <release>
}
    80003658:	60e2                	ld	ra,24(sp)
    8000365a:	6442                	ld	s0,16(sp)
    8000365c:	64a2                	ld	s1,8(sp)
    8000365e:	6902                	ld	s2,0(sp)
    80003660:	6105                	addi	sp,sp,32
    80003662:	8082                	ret
    panic("brelse");
    80003664:	00005517          	auipc	a0,0x5
    80003668:	ffc50513          	addi	a0,a0,-4 # 80008660 <syscalls+0xf8>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>

0000000080003674 <bpin>:

void
bpin(struct buf *b) {
    80003674:	1101                	addi	sp,sp,-32
    80003676:	ec06                	sd	ra,24(sp)
    80003678:	e822                	sd	s0,16(sp)
    8000367a:	e426                	sd	s1,8(sp)
    8000367c:	1000                	addi	s0,sp,32
    8000367e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003680:	00016517          	auipc	a0,0x16
    80003684:	8e050513          	addi	a0,a0,-1824 # 80018f60 <bcache>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	55c080e7          	jalr	1372(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003690:	40bc                	lw	a5,64(s1)
    80003692:	2785                	addiw	a5,a5,1
    80003694:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003696:	00016517          	auipc	a0,0x16
    8000369a:	8ca50513          	addi	a0,a0,-1846 # 80018f60 <bcache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	5fa080e7          	jalr	1530(ra) # 80000c98 <release>
}
    800036a6:	60e2                	ld	ra,24(sp)
    800036a8:	6442                	ld	s0,16(sp)
    800036aa:	64a2                	ld	s1,8(sp)
    800036ac:	6105                	addi	sp,sp,32
    800036ae:	8082                	ret

00000000800036b0 <bunpin>:

void
bunpin(struct buf *b) {
    800036b0:	1101                	addi	sp,sp,-32
    800036b2:	ec06                	sd	ra,24(sp)
    800036b4:	e822                	sd	s0,16(sp)
    800036b6:	e426                	sd	s1,8(sp)
    800036b8:	1000                	addi	s0,sp,32
    800036ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036bc:	00016517          	auipc	a0,0x16
    800036c0:	8a450513          	addi	a0,a0,-1884 # 80018f60 <bcache>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	520080e7          	jalr	1312(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036cc:	40bc                	lw	a5,64(s1)
    800036ce:	37fd                	addiw	a5,a5,-1
    800036d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036d2:	00016517          	auipc	a0,0x16
    800036d6:	88e50513          	addi	a0,a0,-1906 # 80018f60 <bcache>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	5be080e7          	jalr	1470(ra) # 80000c98 <release>
}
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	64a2                	ld	s1,8(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret

00000000800036ec <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036fa:	00d5d59b          	srliw	a1,a1,0xd
    800036fe:	0001e797          	auipc	a5,0x1e
    80003702:	f3e7a783          	lw	a5,-194(a5) # 8002163c <sb+0x1c>
    80003706:	9dbd                	addw	a1,a1,a5
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	d9e080e7          	jalr	-610(ra) # 800034a6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003710:	0074f713          	andi	a4,s1,7
    80003714:	4785                	li	a5,1
    80003716:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000371a:	14ce                	slli	s1,s1,0x33
    8000371c:	90d9                	srli	s1,s1,0x36
    8000371e:	00950733          	add	a4,a0,s1
    80003722:	05874703          	lbu	a4,88(a4)
    80003726:	00e7f6b3          	and	a3,a5,a4
    8000372a:	c69d                	beqz	a3,80003758 <bfree+0x6c>
    8000372c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000372e:	94aa                	add	s1,s1,a0
    80003730:	fff7c793          	not	a5,a5
    80003734:	8ff9                	and	a5,a5,a4
    80003736:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000373a:	00001097          	auipc	ra,0x1
    8000373e:	118080e7          	jalr	280(ra) # 80004852 <log_write>
  brelse(bp);
    80003742:	854a                	mv	a0,s2
    80003744:	00000097          	auipc	ra,0x0
    80003748:	e92080e7          	jalr	-366(ra) # 800035d6 <brelse>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6902                	ld	s2,0(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret
    panic("freeing free block");
    80003758:	00005517          	auipc	a0,0x5
    8000375c:	f1050513          	addi	a0,a0,-240 # 80008668 <syscalls+0x100>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	dde080e7          	jalr	-546(ra) # 8000053e <panic>

0000000080003768 <balloc>:
{
    80003768:	711d                	addi	sp,sp,-96
    8000376a:	ec86                	sd	ra,88(sp)
    8000376c:	e8a2                	sd	s0,80(sp)
    8000376e:	e4a6                	sd	s1,72(sp)
    80003770:	e0ca                	sd	s2,64(sp)
    80003772:	fc4e                	sd	s3,56(sp)
    80003774:	f852                	sd	s4,48(sp)
    80003776:	f456                	sd	s5,40(sp)
    80003778:	f05a                	sd	s6,32(sp)
    8000377a:	ec5e                	sd	s7,24(sp)
    8000377c:	e862                	sd	s8,16(sp)
    8000377e:	e466                	sd	s9,8(sp)
    80003780:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003782:	0001e797          	auipc	a5,0x1e
    80003786:	ea27a783          	lw	a5,-350(a5) # 80021624 <sb+0x4>
    8000378a:	cbd1                	beqz	a5,8000381e <balloc+0xb6>
    8000378c:	8baa                	mv	s7,a0
    8000378e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003790:	0001eb17          	auipc	s6,0x1e
    80003794:	e90b0b13          	addi	s6,s6,-368 # 80021620 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003798:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000379a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000379c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000379e:	6c89                	lui	s9,0x2
    800037a0:	a831                	j	800037bc <balloc+0x54>
    brelse(bp);
    800037a2:	854a                	mv	a0,s2
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	e32080e7          	jalr	-462(ra) # 800035d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037ac:	015c87bb          	addw	a5,s9,s5
    800037b0:	00078a9b          	sext.w	s5,a5
    800037b4:	004b2703          	lw	a4,4(s6)
    800037b8:	06eaf363          	bgeu	s5,a4,8000381e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037bc:	41fad79b          	sraiw	a5,s5,0x1f
    800037c0:	0137d79b          	srliw	a5,a5,0x13
    800037c4:	015787bb          	addw	a5,a5,s5
    800037c8:	40d7d79b          	sraiw	a5,a5,0xd
    800037cc:	01cb2583          	lw	a1,28(s6)
    800037d0:	9dbd                	addw	a1,a1,a5
    800037d2:	855e                	mv	a0,s7
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	cd2080e7          	jalr	-814(ra) # 800034a6 <bread>
    800037dc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037de:	004b2503          	lw	a0,4(s6)
    800037e2:	000a849b          	sext.w	s1,s5
    800037e6:	8662                	mv	a2,s8
    800037e8:	faa4fde3          	bgeu	s1,a0,800037a2 <balloc+0x3a>
      m = 1 << (bi % 8);
    800037ec:	41f6579b          	sraiw	a5,a2,0x1f
    800037f0:	01d7d69b          	srliw	a3,a5,0x1d
    800037f4:	00c6873b          	addw	a4,a3,a2
    800037f8:	00777793          	andi	a5,a4,7
    800037fc:	9f95                	subw	a5,a5,a3
    800037fe:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003802:	4037571b          	sraiw	a4,a4,0x3
    80003806:	00e906b3          	add	a3,s2,a4
    8000380a:	0586c683          	lbu	a3,88(a3)
    8000380e:	00d7f5b3          	and	a1,a5,a3
    80003812:	cd91                	beqz	a1,8000382e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003814:	2605                	addiw	a2,a2,1
    80003816:	2485                	addiw	s1,s1,1
    80003818:	fd4618e3          	bne	a2,s4,800037e8 <balloc+0x80>
    8000381c:	b759                	j	800037a2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000381e:	00005517          	auipc	a0,0x5
    80003822:	e6250513          	addi	a0,a0,-414 # 80008680 <syscalls+0x118>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	d18080e7          	jalr	-744(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000382e:	974a                	add	a4,a4,s2
    80003830:	8fd5                	or	a5,a5,a3
    80003832:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003836:	854a                	mv	a0,s2
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	01a080e7          	jalr	26(ra) # 80004852 <log_write>
        brelse(bp);
    80003840:	854a                	mv	a0,s2
    80003842:	00000097          	auipc	ra,0x0
    80003846:	d94080e7          	jalr	-620(ra) # 800035d6 <brelse>
  bp = bread(dev, bno);
    8000384a:	85a6                	mv	a1,s1
    8000384c:	855e                	mv	a0,s7
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	c58080e7          	jalr	-936(ra) # 800034a6 <bread>
    80003856:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003858:	40000613          	li	a2,1024
    8000385c:	4581                	li	a1,0
    8000385e:	05850513          	addi	a0,a0,88
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	47e080e7          	jalr	1150(ra) # 80000ce0 <memset>
  log_write(bp);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	fe6080e7          	jalr	-26(ra) # 80004852 <log_write>
  brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	d60080e7          	jalr	-672(ra) # 800035d6 <brelse>
}
    8000387e:	8526                	mv	a0,s1
    80003880:	60e6                	ld	ra,88(sp)
    80003882:	6446                	ld	s0,80(sp)
    80003884:	64a6                	ld	s1,72(sp)
    80003886:	6906                	ld	s2,64(sp)
    80003888:	79e2                	ld	s3,56(sp)
    8000388a:	7a42                	ld	s4,48(sp)
    8000388c:	7aa2                	ld	s5,40(sp)
    8000388e:	7b02                	ld	s6,32(sp)
    80003890:	6be2                	ld	s7,24(sp)
    80003892:	6c42                	ld	s8,16(sp)
    80003894:	6ca2                	ld	s9,8(sp)
    80003896:	6125                	addi	sp,sp,96
    80003898:	8082                	ret

000000008000389a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000389a:	7179                	addi	sp,sp,-48
    8000389c:	f406                	sd	ra,40(sp)
    8000389e:	f022                	sd	s0,32(sp)
    800038a0:	ec26                	sd	s1,24(sp)
    800038a2:	e84a                	sd	s2,16(sp)
    800038a4:	e44e                	sd	s3,8(sp)
    800038a6:	e052                	sd	s4,0(sp)
    800038a8:	1800                	addi	s0,sp,48
    800038aa:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038ac:	47ad                	li	a5,11
    800038ae:	04b7fe63          	bgeu	a5,a1,8000390a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038b2:	ff45849b          	addiw	s1,a1,-12
    800038b6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038ba:	0ff00793          	li	a5,255
    800038be:	0ae7e363          	bltu	a5,a4,80003964 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038c2:	08052583          	lw	a1,128(a0)
    800038c6:	c5ad                	beqz	a1,80003930 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038c8:	00092503          	lw	a0,0(s2)
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	bda080e7          	jalr	-1062(ra) # 800034a6 <bread>
    800038d4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038d6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038da:	02049593          	slli	a1,s1,0x20
    800038de:	9181                	srli	a1,a1,0x20
    800038e0:	058a                	slli	a1,a1,0x2
    800038e2:	00b784b3          	add	s1,a5,a1
    800038e6:	0004a983          	lw	s3,0(s1)
    800038ea:	04098d63          	beqz	s3,80003944 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038ee:	8552                	mv	a0,s4
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	ce6080e7          	jalr	-794(ra) # 800035d6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038f8:	854e                	mv	a0,s3
    800038fa:	70a2                	ld	ra,40(sp)
    800038fc:	7402                	ld	s0,32(sp)
    800038fe:	64e2                	ld	s1,24(sp)
    80003900:	6942                	ld	s2,16(sp)
    80003902:	69a2                	ld	s3,8(sp)
    80003904:	6a02                	ld	s4,0(sp)
    80003906:	6145                	addi	sp,sp,48
    80003908:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000390a:	02059493          	slli	s1,a1,0x20
    8000390e:	9081                	srli	s1,s1,0x20
    80003910:	048a                	slli	s1,s1,0x2
    80003912:	94aa                	add	s1,s1,a0
    80003914:	0504a983          	lw	s3,80(s1)
    80003918:	fe0990e3          	bnez	s3,800038f8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000391c:	4108                	lw	a0,0(a0)
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	e4a080e7          	jalr	-438(ra) # 80003768 <balloc>
    80003926:	0005099b          	sext.w	s3,a0
    8000392a:	0534a823          	sw	s3,80(s1)
    8000392e:	b7e9                	j	800038f8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003930:	4108                	lw	a0,0(a0)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	e36080e7          	jalr	-458(ra) # 80003768 <balloc>
    8000393a:	0005059b          	sext.w	a1,a0
    8000393e:	08b92023          	sw	a1,128(s2)
    80003942:	b759                	j	800038c8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003944:	00092503          	lw	a0,0(s2)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	e20080e7          	jalr	-480(ra) # 80003768 <balloc>
    80003950:	0005099b          	sext.w	s3,a0
    80003954:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003958:	8552                	mv	a0,s4
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	ef8080e7          	jalr	-264(ra) # 80004852 <log_write>
    80003962:	b771                	j	800038ee <bmap+0x54>
  panic("bmap: out of range");
    80003964:	00005517          	auipc	a0,0x5
    80003968:	d3450513          	addi	a0,a0,-716 # 80008698 <syscalls+0x130>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>

0000000080003974 <iget>:
{
    80003974:	7179                	addi	sp,sp,-48
    80003976:	f406                	sd	ra,40(sp)
    80003978:	f022                	sd	s0,32(sp)
    8000397a:	ec26                	sd	s1,24(sp)
    8000397c:	e84a                	sd	s2,16(sp)
    8000397e:	e44e                	sd	s3,8(sp)
    80003980:	e052                	sd	s4,0(sp)
    80003982:	1800                	addi	s0,sp,48
    80003984:	89aa                	mv	s3,a0
    80003986:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003988:	0001e517          	auipc	a0,0x1e
    8000398c:	cb850513          	addi	a0,a0,-840 # 80021640 <itable>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  empty = 0;
    80003998:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000399a:	0001e497          	auipc	s1,0x1e
    8000399e:	cbe48493          	addi	s1,s1,-834 # 80021658 <itable+0x18>
    800039a2:	0001f697          	auipc	a3,0x1f
    800039a6:	74668693          	addi	a3,a3,1862 # 800230e8 <log>
    800039aa:	a039                	j	800039b8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039ac:	02090b63          	beqz	s2,800039e2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039b0:	08848493          	addi	s1,s1,136
    800039b4:	02d48a63          	beq	s1,a3,800039e8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039b8:	449c                	lw	a5,8(s1)
    800039ba:	fef059e3          	blez	a5,800039ac <iget+0x38>
    800039be:	4098                	lw	a4,0(s1)
    800039c0:	ff3716e3          	bne	a4,s3,800039ac <iget+0x38>
    800039c4:	40d8                	lw	a4,4(s1)
    800039c6:	ff4713e3          	bne	a4,s4,800039ac <iget+0x38>
      ip->ref++;
    800039ca:	2785                	addiw	a5,a5,1
    800039cc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039ce:	0001e517          	auipc	a0,0x1e
    800039d2:	c7250513          	addi	a0,a0,-910 # 80021640 <itable>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	2c2080e7          	jalr	706(ra) # 80000c98 <release>
      return ip;
    800039de:	8926                	mv	s2,s1
    800039e0:	a03d                	j	80003a0e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039e2:	f7f9                	bnez	a5,800039b0 <iget+0x3c>
    800039e4:	8926                	mv	s2,s1
    800039e6:	b7e9                	j	800039b0 <iget+0x3c>
  if(empty == 0)
    800039e8:	02090c63          	beqz	s2,80003a20 <iget+0xac>
  ip->dev = dev;
    800039ec:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039f0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039f4:	4785                	li	a5,1
    800039f6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039fa:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039fe:	0001e517          	auipc	a0,0x1e
    80003a02:	c4250513          	addi	a0,a0,-958 # 80021640 <itable>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	292080e7          	jalr	658(ra) # 80000c98 <release>
}
    80003a0e:	854a                	mv	a0,s2
    80003a10:	70a2                	ld	ra,40(sp)
    80003a12:	7402                	ld	s0,32(sp)
    80003a14:	64e2                	ld	s1,24(sp)
    80003a16:	6942                	ld	s2,16(sp)
    80003a18:	69a2                	ld	s3,8(sp)
    80003a1a:	6a02                	ld	s4,0(sp)
    80003a1c:	6145                	addi	sp,sp,48
    80003a1e:	8082                	ret
    panic("iget: no inodes");
    80003a20:	00005517          	auipc	a0,0x5
    80003a24:	c9050513          	addi	a0,a0,-880 # 800086b0 <syscalls+0x148>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	b16080e7          	jalr	-1258(ra) # 8000053e <panic>

0000000080003a30 <fsinit>:
fsinit(int dev) {
    80003a30:	7179                	addi	sp,sp,-48
    80003a32:	f406                	sd	ra,40(sp)
    80003a34:	f022                	sd	s0,32(sp)
    80003a36:	ec26                	sd	s1,24(sp)
    80003a38:	e84a                	sd	s2,16(sp)
    80003a3a:	e44e                	sd	s3,8(sp)
    80003a3c:	1800                	addi	s0,sp,48
    80003a3e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a40:	4585                	li	a1,1
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	a64080e7          	jalr	-1436(ra) # 800034a6 <bread>
    80003a4a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a4c:	0001e997          	auipc	s3,0x1e
    80003a50:	bd498993          	addi	s3,s3,-1068 # 80021620 <sb>
    80003a54:	02000613          	li	a2,32
    80003a58:	05850593          	addi	a1,a0,88
    80003a5c:	854e                	mv	a0,s3
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	2e2080e7          	jalr	738(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a66:	8526                	mv	a0,s1
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	b6e080e7          	jalr	-1170(ra) # 800035d6 <brelse>
  if(sb.magic != FSMAGIC)
    80003a70:	0009a703          	lw	a4,0(s3)
    80003a74:	102037b7          	lui	a5,0x10203
    80003a78:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a7c:	02f71263          	bne	a4,a5,80003aa0 <fsinit+0x70>
  initlog(dev, &sb);
    80003a80:	0001e597          	auipc	a1,0x1e
    80003a84:	ba058593          	addi	a1,a1,-1120 # 80021620 <sb>
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00001097          	auipc	ra,0x1
    80003a8e:	b4c080e7          	jalr	-1204(ra) # 800045d6 <initlog>
}
    80003a92:	70a2                	ld	ra,40(sp)
    80003a94:	7402                	ld	s0,32(sp)
    80003a96:	64e2                	ld	s1,24(sp)
    80003a98:	6942                	ld	s2,16(sp)
    80003a9a:	69a2                	ld	s3,8(sp)
    80003a9c:	6145                	addi	sp,sp,48
    80003a9e:	8082                	ret
    panic("invalid file system");
    80003aa0:	00005517          	auipc	a0,0x5
    80003aa4:	c2050513          	addi	a0,a0,-992 # 800086c0 <syscalls+0x158>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	a96080e7          	jalr	-1386(ra) # 8000053e <panic>

0000000080003ab0 <iinit>:
{
    80003ab0:	7179                	addi	sp,sp,-48
    80003ab2:	f406                	sd	ra,40(sp)
    80003ab4:	f022                	sd	s0,32(sp)
    80003ab6:	ec26                	sd	s1,24(sp)
    80003ab8:	e84a                	sd	s2,16(sp)
    80003aba:	e44e                	sd	s3,8(sp)
    80003abc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003abe:	00005597          	auipc	a1,0x5
    80003ac2:	c1a58593          	addi	a1,a1,-998 # 800086d8 <syscalls+0x170>
    80003ac6:	0001e517          	auipc	a0,0x1e
    80003aca:	b7a50513          	addi	a0,a0,-1158 # 80021640 <itable>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	086080e7          	jalr	134(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ad6:	0001e497          	auipc	s1,0x1e
    80003ada:	b9248493          	addi	s1,s1,-1134 # 80021668 <itable+0x28>
    80003ade:	0001f997          	auipc	s3,0x1f
    80003ae2:	61a98993          	addi	s3,s3,1562 # 800230f8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ae6:	00005917          	auipc	s2,0x5
    80003aea:	bfa90913          	addi	s2,s2,-1030 # 800086e0 <syscalls+0x178>
    80003aee:	85ca                	mv	a1,s2
    80003af0:	8526                	mv	a0,s1
    80003af2:	00001097          	auipc	ra,0x1
    80003af6:	e46080e7          	jalr	-442(ra) # 80004938 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003afa:	08848493          	addi	s1,s1,136
    80003afe:	ff3498e3          	bne	s1,s3,80003aee <iinit+0x3e>
}
    80003b02:	70a2                	ld	ra,40(sp)
    80003b04:	7402                	ld	s0,32(sp)
    80003b06:	64e2                	ld	s1,24(sp)
    80003b08:	6942                	ld	s2,16(sp)
    80003b0a:	69a2                	ld	s3,8(sp)
    80003b0c:	6145                	addi	sp,sp,48
    80003b0e:	8082                	ret

0000000080003b10 <ialloc>:
{
    80003b10:	715d                	addi	sp,sp,-80
    80003b12:	e486                	sd	ra,72(sp)
    80003b14:	e0a2                	sd	s0,64(sp)
    80003b16:	fc26                	sd	s1,56(sp)
    80003b18:	f84a                	sd	s2,48(sp)
    80003b1a:	f44e                	sd	s3,40(sp)
    80003b1c:	f052                	sd	s4,32(sp)
    80003b1e:	ec56                	sd	s5,24(sp)
    80003b20:	e85a                	sd	s6,16(sp)
    80003b22:	e45e                	sd	s7,8(sp)
    80003b24:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b26:	0001e717          	auipc	a4,0x1e
    80003b2a:	b0672703          	lw	a4,-1274(a4) # 8002162c <sb+0xc>
    80003b2e:	4785                	li	a5,1
    80003b30:	04e7fa63          	bgeu	a5,a4,80003b84 <ialloc+0x74>
    80003b34:	8aaa                	mv	s5,a0
    80003b36:	8bae                	mv	s7,a1
    80003b38:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b3a:	0001ea17          	auipc	s4,0x1e
    80003b3e:	ae6a0a13          	addi	s4,s4,-1306 # 80021620 <sb>
    80003b42:	00048b1b          	sext.w	s6,s1
    80003b46:	0044d593          	srli	a1,s1,0x4
    80003b4a:	018a2783          	lw	a5,24(s4)
    80003b4e:	9dbd                	addw	a1,a1,a5
    80003b50:	8556                	mv	a0,s5
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	954080e7          	jalr	-1708(ra) # 800034a6 <bread>
    80003b5a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b5c:	05850993          	addi	s3,a0,88
    80003b60:	00f4f793          	andi	a5,s1,15
    80003b64:	079a                	slli	a5,a5,0x6
    80003b66:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b68:	00099783          	lh	a5,0(s3)
    80003b6c:	c785                	beqz	a5,80003b94 <ialloc+0x84>
    brelse(bp);
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	a68080e7          	jalr	-1432(ra) # 800035d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b76:	0485                	addi	s1,s1,1
    80003b78:	00ca2703          	lw	a4,12(s4)
    80003b7c:	0004879b          	sext.w	a5,s1
    80003b80:	fce7e1e3          	bltu	a5,a4,80003b42 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b84:	00005517          	auipc	a0,0x5
    80003b88:	b6450513          	addi	a0,a0,-1180 # 800086e8 <syscalls+0x180>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	9b2080e7          	jalr	-1614(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b94:	04000613          	li	a2,64
    80003b98:	4581                	li	a1,0
    80003b9a:	854e                	mv	a0,s3
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	144080e7          	jalr	324(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ba4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ba8:	854a                	mv	a0,s2
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	ca8080e7          	jalr	-856(ra) # 80004852 <log_write>
      brelse(bp);
    80003bb2:	854a                	mv	a0,s2
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	a22080e7          	jalr	-1502(ra) # 800035d6 <brelse>
      return iget(dev, inum);
    80003bbc:	85da                	mv	a1,s6
    80003bbe:	8556                	mv	a0,s5
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	db4080e7          	jalr	-588(ra) # 80003974 <iget>
}
    80003bc8:	60a6                	ld	ra,72(sp)
    80003bca:	6406                	ld	s0,64(sp)
    80003bcc:	74e2                	ld	s1,56(sp)
    80003bce:	7942                	ld	s2,48(sp)
    80003bd0:	79a2                	ld	s3,40(sp)
    80003bd2:	7a02                	ld	s4,32(sp)
    80003bd4:	6ae2                	ld	s5,24(sp)
    80003bd6:	6b42                	ld	s6,16(sp)
    80003bd8:	6ba2                	ld	s7,8(sp)
    80003bda:	6161                	addi	sp,sp,80
    80003bdc:	8082                	ret

0000000080003bde <iupdate>:
{
    80003bde:	1101                	addi	sp,sp,-32
    80003be0:	ec06                	sd	ra,24(sp)
    80003be2:	e822                	sd	s0,16(sp)
    80003be4:	e426                	sd	s1,8(sp)
    80003be6:	e04a                	sd	s2,0(sp)
    80003be8:	1000                	addi	s0,sp,32
    80003bea:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bec:	415c                	lw	a5,4(a0)
    80003bee:	0047d79b          	srliw	a5,a5,0x4
    80003bf2:	0001e597          	auipc	a1,0x1e
    80003bf6:	a465a583          	lw	a1,-1466(a1) # 80021638 <sb+0x18>
    80003bfa:	9dbd                	addw	a1,a1,a5
    80003bfc:	4108                	lw	a0,0(a0)
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	8a8080e7          	jalr	-1880(ra) # 800034a6 <bread>
    80003c06:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c08:	05850793          	addi	a5,a0,88
    80003c0c:	40c8                	lw	a0,4(s1)
    80003c0e:	893d                	andi	a0,a0,15
    80003c10:	051a                	slli	a0,a0,0x6
    80003c12:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c14:	04449703          	lh	a4,68(s1)
    80003c18:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c1c:	04649703          	lh	a4,70(s1)
    80003c20:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c24:	04849703          	lh	a4,72(s1)
    80003c28:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c2c:	04a49703          	lh	a4,74(s1)
    80003c30:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c34:	44f8                	lw	a4,76(s1)
    80003c36:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c38:	03400613          	li	a2,52
    80003c3c:	05048593          	addi	a1,s1,80
    80003c40:	0531                	addi	a0,a0,12
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	0fe080e7          	jalr	254(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c4a:	854a                	mv	a0,s2
    80003c4c:	00001097          	auipc	ra,0x1
    80003c50:	c06080e7          	jalr	-1018(ra) # 80004852 <log_write>
  brelse(bp);
    80003c54:	854a                	mv	a0,s2
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	980080e7          	jalr	-1664(ra) # 800035d6 <brelse>
}
    80003c5e:	60e2                	ld	ra,24(sp)
    80003c60:	6442                	ld	s0,16(sp)
    80003c62:	64a2                	ld	s1,8(sp)
    80003c64:	6902                	ld	s2,0(sp)
    80003c66:	6105                	addi	sp,sp,32
    80003c68:	8082                	ret

0000000080003c6a <idup>:
{
    80003c6a:	1101                	addi	sp,sp,-32
    80003c6c:	ec06                	sd	ra,24(sp)
    80003c6e:	e822                	sd	s0,16(sp)
    80003c70:	e426                	sd	s1,8(sp)
    80003c72:	1000                	addi	s0,sp,32
    80003c74:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c76:	0001e517          	auipc	a0,0x1e
    80003c7a:	9ca50513          	addi	a0,a0,-1590 # 80021640 <itable>
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	f66080e7          	jalr	-154(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c86:	449c                	lw	a5,8(s1)
    80003c88:	2785                	addiw	a5,a5,1
    80003c8a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c8c:	0001e517          	auipc	a0,0x1e
    80003c90:	9b450513          	addi	a0,a0,-1612 # 80021640 <itable>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	004080e7          	jalr	4(ra) # 80000c98 <release>
}
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	60e2                	ld	ra,24(sp)
    80003ca0:	6442                	ld	s0,16(sp)
    80003ca2:	64a2                	ld	s1,8(sp)
    80003ca4:	6105                	addi	sp,sp,32
    80003ca6:	8082                	ret

0000000080003ca8 <ilock>:
{
    80003ca8:	1101                	addi	sp,sp,-32
    80003caa:	ec06                	sd	ra,24(sp)
    80003cac:	e822                	sd	s0,16(sp)
    80003cae:	e426                	sd	s1,8(sp)
    80003cb0:	e04a                	sd	s2,0(sp)
    80003cb2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cb4:	c115                	beqz	a0,80003cd8 <ilock+0x30>
    80003cb6:	84aa                	mv	s1,a0
    80003cb8:	451c                	lw	a5,8(a0)
    80003cba:	00f05f63          	blez	a5,80003cd8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cbe:	0541                	addi	a0,a0,16
    80003cc0:	00001097          	auipc	ra,0x1
    80003cc4:	cb2080e7          	jalr	-846(ra) # 80004972 <acquiresleep>
  if(ip->valid == 0){
    80003cc8:	40bc                	lw	a5,64(s1)
    80003cca:	cf99                	beqz	a5,80003ce8 <ilock+0x40>
}
    80003ccc:	60e2                	ld	ra,24(sp)
    80003cce:	6442                	ld	s0,16(sp)
    80003cd0:	64a2                	ld	s1,8(sp)
    80003cd2:	6902                	ld	s2,0(sp)
    80003cd4:	6105                	addi	sp,sp,32
    80003cd6:	8082                	ret
    panic("ilock");
    80003cd8:	00005517          	auipc	a0,0x5
    80003cdc:	a2850513          	addi	a0,a0,-1496 # 80008700 <syscalls+0x198>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	85e080e7          	jalr	-1954(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ce8:	40dc                	lw	a5,4(s1)
    80003cea:	0047d79b          	srliw	a5,a5,0x4
    80003cee:	0001e597          	auipc	a1,0x1e
    80003cf2:	94a5a583          	lw	a1,-1718(a1) # 80021638 <sb+0x18>
    80003cf6:	9dbd                	addw	a1,a1,a5
    80003cf8:	4088                	lw	a0,0(s1)
    80003cfa:	fffff097          	auipc	ra,0xfffff
    80003cfe:	7ac080e7          	jalr	1964(ra) # 800034a6 <bread>
    80003d02:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d04:	05850593          	addi	a1,a0,88
    80003d08:	40dc                	lw	a5,4(s1)
    80003d0a:	8bbd                	andi	a5,a5,15
    80003d0c:	079a                	slli	a5,a5,0x6
    80003d0e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d10:	00059783          	lh	a5,0(a1)
    80003d14:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d18:	00259783          	lh	a5,2(a1)
    80003d1c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d20:	00459783          	lh	a5,4(a1)
    80003d24:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d28:	00659783          	lh	a5,6(a1)
    80003d2c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d30:	459c                	lw	a5,8(a1)
    80003d32:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d34:	03400613          	li	a2,52
    80003d38:	05b1                	addi	a1,a1,12
    80003d3a:	05048513          	addi	a0,s1,80
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	002080e7          	jalr	2(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d46:	854a                	mv	a0,s2
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	88e080e7          	jalr	-1906(ra) # 800035d6 <brelse>
    ip->valid = 1;
    80003d50:	4785                	li	a5,1
    80003d52:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d54:	04449783          	lh	a5,68(s1)
    80003d58:	fbb5                	bnez	a5,80003ccc <ilock+0x24>
      panic("ilock: no type");
    80003d5a:	00005517          	auipc	a0,0x5
    80003d5e:	9ae50513          	addi	a0,a0,-1618 # 80008708 <syscalls+0x1a0>
    80003d62:	ffffc097          	auipc	ra,0xffffc
    80003d66:	7dc080e7          	jalr	2012(ra) # 8000053e <panic>

0000000080003d6a <iunlock>:
{
    80003d6a:	1101                	addi	sp,sp,-32
    80003d6c:	ec06                	sd	ra,24(sp)
    80003d6e:	e822                	sd	s0,16(sp)
    80003d70:	e426                	sd	s1,8(sp)
    80003d72:	e04a                	sd	s2,0(sp)
    80003d74:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d76:	c905                	beqz	a0,80003da6 <iunlock+0x3c>
    80003d78:	84aa                	mv	s1,a0
    80003d7a:	01050913          	addi	s2,a0,16
    80003d7e:	854a                	mv	a0,s2
    80003d80:	00001097          	auipc	ra,0x1
    80003d84:	c8c080e7          	jalr	-884(ra) # 80004a0c <holdingsleep>
    80003d88:	cd19                	beqz	a0,80003da6 <iunlock+0x3c>
    80003d8a:	449c                	lw	a5,8(s1)
    80003d8c:	00f05d63          	blez	a5,80003da6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d90:	854a                	mv	a0,s2
    80003d92:	00001097          	auipc	ra,0x1
    80003d96:	c36080e7          	jalr	-970(ra) # 800049c8 <releasesleep>
}
    80003d9a:	60e2                	ld	ra,24(sp)
    80003d9c:	6442                	ld	s0,16(sp)
    80003d9e:	64a2                	ld	s1,8(sp)
    80003da0:	6902                	ld	s2,0(sp)
    80003da2:	6105                	addi	sp,sp,32
    80003da4:	8082                	ret
    panic("iunlock");
    80003da6:	00005517          	auipc	a0,0x5
    80003daa:	97250513          	addi	a0,a0,-1678 # 80008718 <syscalls+0x1b0>
    80003dae:	ffffc097          	auipc	ra,0xffffc
    80003db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>

0000000080003db6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003db6:	7179                	addi	sp,sp,-48
    80003db8:	f406                	sd	ra,40(sp)
    80003dba:	f022                	sd	s0,32(sp)
    80003dbc:	ec26                	sd	s1,24(sp)
    80003dbe:	e84a                	sd	s2,16(sp)
    80003dc0:	e44e                	sd	s3,8(sp)
    80003dc2:	e052                	sd	s4,0(sp)
    80003dc4:	1800                	addi	s0,sp,48
    80003dc6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dc8:	05050493          	addi	s1,a0,80
    80003dcc:	08050913          	addi	s2,a0,128
    80003dd0:	a021                	j	80003dd8 <itrunc+0x22>
    80003dd2:	0491                	addi	s1,s1,4
    80003dd4:	01248d63          	beq	s1,s2,80003dee <itrunc+0x38>
    if(ip->addrs[i]){
    80003dd8:	408c                	lw	a1,0(s1)
    80003dda:	dde5                	beqz	a1,80003dd2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ddc:	0009a503          	lw	a0,0(s3)
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	90c080e7          	jalr	-1780(ra) # 800036ec <bfree>
      ip->addrs[i] = 0;
    80003de8:	0004a023          	sw	zero,0(s1)
    80003dec:	b7dd                	j	80003dd2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dee:	0809a583          	lw	a1,128(s3)
    80003df2:	e185                	bnez	a1,80003e12 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003df4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	de4080e7          	jalr	-540(ra) # 80003bde <iupdate>
}
    80003e02:	70a2                	ld	ra,40(sp)
    80003e04:	7402                	ld	s0,32(sp)
    80003e06:	64e2                	ld	s1,24(sp)
    80003e08:	6942                	ld	s2,16(sp)
    80003e0a:	69a2                	ld	s3,8(sp)
    80003e0c:	6a02                	ld	s4,0(sp)
    80003e0e:	6145                	addi	sp,sp,48
    80003e10:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e12:	0009a503          	lw	a0,0(s3)
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	690080e7          	jalr	1680(ra) # 800034a6 <bread>
    80003e1e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e20:	05850493          	addi	s1,a0,88
    80003e24:	45850913          	addi	s2,a0,1112
    80003e28:	a811                	j	80003e3c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e2a:	0009a503          	lw	a0,0(s3)
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	8be080e7          	jalr	-1858(ra) # 800036ec <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e36:	0491                	addi	s1,s1,4
    80003e38:	01248563          	beq	s1,s2,80003e42 <itrunc+0x8c>
      if(a[j])
    80003e3c:	408c                	lw	a1,0(s1)
    80003e3e:	dde5                	beqz	a1,80003e36 <itrunc+0x80>
    80003e40:	b7ed                	j	80003e2a <itrunc+0x74>
    brelse(bp);
    80003e42:	8552                	mv	a0,s4
    80003e44:	fffff097          	auipc	ra,0xfffff
    80003e48:	792080e7          	jalr	1938(ra) # 800035d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e4c:	0809a583          	lw	a1,128(s3)
    80003e50:	0009a503          	lw	a0,0(s3)
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	898080e7          	jalr	-1896(ra) # 800036ec <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e5c:	0809a023          	sw	zero,128(s3)
    80003e60:	bf51                	j	80003df4 <itrunc+0x3e>

0000000080003e62 <iput>:
{
    80003e62:	1101                	addi	sp,sp,-32
    80003e64:	ec06                	sd	ra,24(sp)
    80003e66:	e822                	sd	s0,16(sp)
    80003e68:	e426                	sd	s1,8(sp)
    80003e6a:	e04a                	sd	s2,0(sp)
    80003e6c:	1000                	addi	s0,sp,32
    80003e6e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e70:	0001d517          	auipc	a0,0x1d
    80003e74:	7d050513          	addi	a0,a0,2000 # 80021640 <itable>
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	d6c080e7          	jalr	-660(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e80:	4498                	lw	a4,8(s1)
    80003e82:	4785                	li	a5,1
    80003e84:	02f70363          	beq	a4,a5,80003eaa <iput+0x48>
  ip->ref--;
    80003e88:	449c                	lw	a5,8(s1)
    80003e8a:	37fd                	addiw	a5,a5,-1
    80003e8c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e8e:	0001d517          	auipc	a0,0x1d
    80003e92:	7b250513          	addi	a0,a0,1970 # 80021640 <itable>
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
}
    80003e9e:	60e2                	ld	ra,24(sp)
    80003ea0:	6442                	ld	s0,16(sp)
    80003ea2:	64a2                	ld	s1,8(sp)
    80003ea4:	6902                	ld	s2,0(sp)
    80003ea6:	6105                	addi	sp,sp,32
    80003ea8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eaa:	40bc                	lw	a5,64(s1)
    80003eac:	dff1                	beqz	a5,80003e88 <iput+0x26>
    80003eae:	04a49783          	lh	a5,74(s1)
    80003eb2:	fbf9                	bnez	a5,80003e88 <iput+0x26>
    acquiresleep(&ip->lock);
    80003eb4:	01048913          	addi	s2,s1,16
    80003eb8:	854a                	mv	a0,s2
    80003eba:	00001097          	auipc	ra,0x1
    80003ebe:	ab8080e7          	jalr	-1352(ra) # 80004972 <acquiresleep>
    release(&itable.lock);
    80003ec2:	0001d517          	auipc	a0,0x1d
    80003ec6:	77e50513          	addi	a0,a0,1918 # 80021640 <itable>
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
    itrunc(ip);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	ee2080e7          	jalr	-286(ra) # 80003db6 <itrunc>
    ip->type = 0;
    80003edc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	cfc080e7          	jalr	-772(ra) # 80003bde <iupdate>
    ip->valid = 0;
    80003eea:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003eee:	854a                	mv	a0,s2
    80003ef0:	00001097          	auipc	ra,0x1
    80003ef4:	ad8080e7          	jalr	-1320(ra) # 800049c8 <releasesleep>
    acquire(&itable.lock);
    80003ef8:	0001d517          	auipc	a0,0x1d
    80003efc:	74850513          	addi	a0,a0,1864 # 80021640 <itable>
    80003f00:	ffffd097          	auipc	ra,0xffffd
    80003f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
    80003f08:	b741                	j	80003e88 <iput+0x26>

0000000080003f0a <iunlockput>:
{
    80003f0a:	1101                	addi	sp,sp,-32
    80003f0c:	ec06                	sd	ra,24(sp)
    80003f0e:	e822                	sd	s0,16(sp)
    80003f10:	e426                	sd	s1,8(sp)
    80003f12:	1000                	addi	s0,sp,32
    80003f14:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	e54080e7          	jalr	-428(ra) # 80003d6a <iunlock>
  iput(ip);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	f42080e7          	jalr	-190(ra) # 80003e62 <iput>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6105                	addi	sp,sp,32
    80003f30:	8082                	ret

0000000080003f32 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f32:	1141                	addi	sp,sp,-16
    80003f34:	e422                	sd	s0,8(sp)
    80003f36:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f38:	411c                	lw	a5,0(a0)
    80003f3a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f3c:	415c                	lw	a5,4(a0)
    80003f3e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f40:	04451783          	lh	a5,68(a0)
    80003f44:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f48:	04a51783          	lh	a5,74(a0)
    80003f4c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f50:	04c56783          	lwu	a5,76(a0)
    80003f54:	e99c                	sd	a5,16(a1)
}
    80003f56:	6422                	ld	s0,8(sp)
    80003f58:	0141                	addi	sp,sp,16
    80003f5a:	8082                	ret

0000000080003f5c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f5c:	457c                	lw	a5,76(a0)
    80003f5e:	0ed7e963          	bltu	a5,a3,80004050 <readi+0xf4>
{
    80003f62:	7159                	addi	sp,sp,-112
    80003f64:	f486                	sd	ra,104(sp)
    80003f66:	f0a2                	sd	s0,96(sp)
    80003f68:	eca6                	sd	s1,88(sp)
    80003f6a:	e8ca                	sd	s2,80(sp)
    80003f6c:	e4ce                	sd	s3,72(sp)
    80003f6e:	e0d2                	sd	s4,64(sp)
    80003f70:	fc56                	sd	s5,56(sp)
    80003f72:	f85a                	sd	s6,48(sp)
    80003f74:	f45e                	sd	s7,40(sp)
    80003f76:	f062                	sd	s8,32(sp)
    80003f78:	ec66                	sd	s9,24(sp)
    80003f7a:	e86a                	sd	s10,16(sp)
    80003f7c:	e46e                	sd	s11,8(sp)
    80003f7e:	1880                	addi	s0,sp,112
    80003f80:	8baa                	mv	s7,a0
    80003f82:	8c2e                	mv	s8,a1
    80003f84:	8ab2                	mv	s5,a2
    80003f86:	84b6                	mv	s1,a3
    80003f88:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f8a:	9f35                	addw	a4,a4,a3
    return 0;
    80003f8c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f8e:	0ad76063          	bltu	a4,a3,8000402e <readi+0xd2>
  if(off + n > ip->size)
    80003f92:	00e7f463          	bgeu	a5,a4,80003f9a <readi+0x3e>
    n = ip->size - off;
    80003f96:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f9a:	0a0b0963          	beqz	s6,8000404c <readi+0xf0>
    80003f9e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fa0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fa4:	5cfd                	li	s9,-1
    80003fa6:	a82d                	j	80003fe0 <readi+0x84>
    80003fa8:	020a1d93          	slli	s11,s4,0x20
    80003fac:	020ddd93          	srli	s11,s11,0x20
    80003fb0:	05890613          	addi	a2,s2,88
    80003fb4:	86ee                	mv	a3,s11
    80003fb6:	963a                	add	a2,a2,a4
    80003fb8:	85d6                	mv	a1,s5
    80003fba:	8562                	mv	a0,s8
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	830080e7          	jalr	-2000(ra) # 800027ec <either_copyout>
    80003fc4:	05950d63          	beq	a0,s9,8000401e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fc8:	854a                	mv	a0,s2
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	60c080e7          	jalr	1548(ra) # 800035d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fd2:	013a09bb          	addw	s3,s4,s3
    80003fd6:	009a04bb          	addw	s1,s4,s1
    80003fda:	9aee                	add	s5,s5,s11
    80003fdc:	0569f763          	bgeu	s3,s6,8000402a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fe0:	000ba903          	lw	s2,0(s7)
    80003fe4:	00a4d59b          	srliw	a1,s1,0xa
    80003fe8:	855e                	mv	a0,s7
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	8b0080e7          	jalr	-1872(ra) # 8000389a <bmap>
    80003ff2:	0005059b          	sext.w	a1,a0
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	4ae080e7          	jalr	1198(ra) # 800034a6 <bread>
    80004000:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004002:	3ff4f713          	andi	a4,s1,1023
    80004006:	40ed07bb          	subw	a5,s10,a4
    8000400a:	413b06bb          	subw	a3,s6,s3
    8000400e:	8a3e                	mv	s4,a5
    80004010:	2781                	sext.w	a5,a5
    80004012:	0006861b          	sext.w	a2,a3
    80004016:	f8f679e3          	bgeu	a2,a5,80003fa8 <readi+0x4c>
    8000401a:	8a36                	mv	s4,a3
    8000401c:	b771                	j	80003fa8 <readi+0x4c>
      brelse(bp);
    8000401e:	854a                	mv	a0,s2
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	5b6080e7          	jalr	1462(ra) # 800035d6 <brelse>
      tot = -1;
    80004028:	59fd                	li	s3,-1
  }
  return tot;
    8000402a:	0009851b          	sext.w	a0,s3
}
    8000402e:	70a6                	ld	ra,104(sp)
    80004030:	7406                	ld	s0,96(sp)
    80004032:	64e6                	ld	s1,88(sp)
    80004034:	6946                	ld	s2,80(sp)
    80004036:	69a6                	ld	s3,72(sp)
    80004038:	6a06                	ld	s4,64(sp)
    8000403a:	7ae2                	ld	s5,56(sp)
    8000403c:	7b42                	ld	s6,48(sp)
    8000403e:	7ba2                	ld	s7,40(sp)
    80004040:	7c02                	ld	s8,32(sp)
    80004042:	6ce2                	ld	s9,24(sp)
    80004044:	6d42                	ld	s10,16(sp)
    80004046:	6da2                	ld	s11,8(sp)
    80004048:	6165                	addi	sp,sp,112
    8000404a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000404c:	89da                	mv	s3,s6
    8000404e:	bff1                	j	8000402a <readi+0xce>
    return 0;
    80004050:	4501                	li	a0,0
}
    80004052:	8082                	ret

0000000080004054 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004054:	457c                	lw	a5,76(a0)
    80004056:	10d7e863          	bltu	a5,a3,80004166 <writei+0x112>
{
    8000405a:	7159                	addi	sp,sp,-112
    8000405c:	f486                	sd	ra,104(sp)
    8000405e:	f0a2                	sd	s0,96(sp)
    80004060:	eca6                	sd	s1,88(sp)
    80004062:	e8ca                	sd	s2,80(sp)
    80004064:	e4ce                	sd	s3,72(sp)
    80004066:	e0d2                	sd	s4,64(sp)
    80004068:	fc56                	sd	s5,56(sp)
    8000406a:	f85a                	sd	s6,48(sp)
    8000406c:	f45e                	sd	s7,40(sp)
    8000406e:	f062                	sd	s8,32(sp)
    80004070:	ec66                	sd	s9,24(sp)
    80004072:	e86a                	sd	s10,16(sp)
    80004074:	e46e                	sd	s11,8(sp)
    80004076:	1880                	addi	s0,sp,112
    80004078:	8b2a                	mv	s6,a0
    8000407a:	8c2e                	mv	s8,a1
    8000407c:	8ab2                	mv	s5,a2
    8000407e:	8936                	mv	s2,a3
    80004080:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004082:	00e687bb          	addw	a5,a3,a4
    80004086:	0ed7e263          	bltu	a5,a3,8000416a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000408a:	00043737          	lui	a4,0x43
    8000408e:	0ef76063          	bltu	a4,a5,8000416e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004092:	0c0b8863          	beqz	s7,80004162 <writei+0x10e>
    80004096:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004098:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000409c:	5cfd                	li	s9,-1
    8000409e:	a091                	j	800040e2 <writei+0x8e>
    800040a0:	02099d93          	slli	s11,s3,0x20
    800040a4:	020ddd93          	srli	s11,s11,0x20
    800040a8:	05848513          	addi	a0,s1,88
    800040ac:	86ee                	mv	a3,s11
    800040ae:	8656                	mv	a2,s5
    800040b0:	85e2                	mv	a1,s8
    800040b2:	953a                	add	a0,a0,a4
    800040b4:	ffffe097          	auipc	ra,0xffffe
    800040b8:	78e080e7          	jalr	1934(ra) # 80002842 <either_copyin>
    800040bc:	07950263          	beq	a0,s9,80004120 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040c0:	8526                	mv	a0,s1
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	790080e7          	jalr	1936(ra) # 80004852 <log_write>
    brelse(bp);
    800040ca:	8526                	mv	a0,s1
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	50a080e7          	jalr	1290(ra) # 800035d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d4:	01498a3b          	addw	s4,s3,s4
    800040d8:	0129893b          	addw	s2,s3,s2
    800040dc:	9aee                	add	s5,s5,s11
    800040de:	057a7663          	bgeu	s4,s7,8000412a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040e2:	000b2483          	lw	s1,0(s6)
    800040e6:	00a9559b          	srliw	a1,s2,0xa
    800040ea:	855a                	mv	a0,s6
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	7ae080e7          	jalr	1966(ra) # 8000389a <bmap>
    800040f4:	0005059b          	sext.w	a1,a0
    800040f8:	8526                	mv	a0,s1
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	3ac080e7          	jalr	940(ra) # 800034a6 <bread>
    80004102:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004104:	3ff97713          	andi	a4,s2,1023
    80004108:	40ed07bb          	subw	a5,s10,a4
    8000410c:	414b86bb          	subw	a3,s7,s4
    80004110:	89be                	mv	s3,a5
    80004112:	2781                	sext.w	a5,a5
    80004114:	0006861b          	sext.w	a2,a3
    80004118:	f8f674e3          	bgeu	a2,a5,800040a0 <writei+0x4c>
    8000411c:	89b6                	mv	s3,a3
    8000411e:	b749                	j	800040a0 <writei+0x4c>
      brelse(bp);
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	4b4080e7          	jalr	1204(ra) # 800035d6 <brelse>
  }

  if(off > ip->size)
    8000412a:	04cb2783          	lw	a5,76(s6)
    8000412e:	0127f463          	bgeu	a5,s2,80004136 <writei+0xe2>
    ip->size = off;
    80004132:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004136:	855a                	mv	a0,s6
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	aa6080e7          	jalr	-1370(ra) # 80003bde <iupdate>

  return tot;
    80004140:	000a051b          	sext.w	a0,s4
}
    80004144:	70a6                	ld	ra,104(sp)
    80004146:	7406                	ld	s0,96(sp)
    80004148:	64e6                	ld	s1,88(sp)
    8000414a:	6946                	ld	s2,80(sp)
    8000414c:	69a6                	ld	s3,72(sp)
    8000414e:	6a06                	ld	s4,64(sp)
    80004150:	7ae2                	ld	s5,56(sp)
    80004152:	7b42                	ld	s6,48(sp)
    80004154:	7ba2                	ld	s7,40(sp)
    80004156:	7c02                	ld	s8,32(sp)
    80004158:	6ce2                	ld	s9,24(sp)
    8000415a:	6d42                	ld	s10,16(sp)
    8000415c:	6da2                	ld	s11,8(sp)
    8000415e:	6165                	addi	sp,sp,112
    80004160:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004162:	8a5e                	mv	s4,s7
    80004164:	bfc9                	j	80004136 <writei+0xe2>
    return -1;
    80004166:	557d                	li	a0,-1
}
    80004168:	8082                	ret
    return -1;
    8000416a:	557d                	li	a0,-1
    8000416c:	bfe1                	j	80004144 <writei+0xf0>
    return -1;
    8000416e:	557d                	li	a0,-1
    80004170:	bfd1                	j	80004144 <writei+0xf0>

0000000080004172 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004172:	1141                	addi	sp,sp,-16
    80004174:	e406                	sd	ra,8(sp)
    80004176:	e022                	sd	s0,0(sp)
    80004178:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000417a:	4639                	li	a2,14
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	c3c080e7          	jalr	-964(ra) # 80000db8 <strncmp>
}
    80004184:	60a2                	ld	ra,8(sp)
    80004186:	6402                	ld	s0,0(sp)
    80004188:	0141                	addi	sp,sp,16
    8000418a:	8082                	ret

000000008000418c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000418c:	7139                	addi	sp,sp,-64
    8000418e:	fc06                	sd	ra,56(sp)
    80004190:	f822                	sd	s0,48(sp)
    80004192:	f426                	sd	s1,40(sp)
    80004194:	f04a                	sd	s2,32(sp)
    80004196:	ec4e                	sd	s3,24(sp)
    80004198:	e852                	sd	s4,16(sp)
    8000419a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000419c:	04451703          	lh	a4,68(a0)
    800041a0:	4785                	li	a5,1
    800041a2:	00f71a63          	bne	a4,a5,800041b6 <dirlookup+0x2a>
    800041a6:	892a                	mv	s2,a0
    800041a8:	89ae                	mv	s3,a1
    800041aa:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ac:	457c                	lw	a5,76(a0)
    800041ae:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041b0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b2:	e79d                	bnez	a5,800041e0 <dirlookup+0x54>
    800041b4:	a8a5                	j	8000422c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041b6:	00004517          	auipc	a0,0x4
    800041ba:	56a50513          	addi	a0,a0,1386 # 80008720 <syscalls+0x1b8>
    800041be:	ffffc097          	auipc	ra,0xffffc
    800041c2:	380080e7          	jalr	896(ra) # 8000053e <panic>
      panic("dirlookup read");
    800041c6:	00004517          	auipc	a0,0x4
    800041ca:	57250513          	addi	a0,a0,1394 # 80008738 <syscalls+0x1d0>
    800041ce:	ffffc097          	auipc	ra,0xffffc
    800041d2:	370080e7          	jalr	880(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d6:	24c1                	addiw	s1,s1,16
    800041d8:	04c92783          	lw	a5,76(s2)
    800041dc:	04f4f763          	bgeu	s1,a5,8000422a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041e0:	4741                	li	a4,16
    800041e2:	86a6                	mv	a3,s1
    800041e4:	fc040613          	addi	a2,s0,-64
    800041e8:	4581                	li	a1,0
    800041ea:	854a                	mv	a0,s2
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	d70080e7          	jalr	-656(ra) # 80003f5c <readi>
    800041f4:	47c1                	li	a5,16
    800041f6:	fcf518e3          	bne	a0,a5,800041c6 <dirlookup+0x3a>
    if(de.inum == 0)
    800041fa:	fc045783          	lhu	a5,-64(s0)
    800041fe:	dfe1                	beqz	a5,800041d6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004200:	fc240593          	addi	a1,s0,-62
    80004204:	854e                	mv	a0,s3
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	f6c080e7          	jalr	-148(ra) # 80004172 <namecmp>
    8000420e:	f561                	bnez	a0,800041d6 <dirlookup+0x4a>
      if(poff)
    80004210:	000a0463          	beqz	s4,80004218 <dirlookup+0x8c>
        *poff = off;
    80004214:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004218:	fc045583          	lhu	a1,-64(s0)
    8000421c:	00092503          	lw	a0,0(s2)
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	754080e7          	jalr	1876(ra) # 80003974 <iget>
    80004228:	a011                	j	8000422c <dirlookup+0xa0>
  return 0;
    8000422a:	4501                	li	a0,0
}
    8000422c:	70e2                	ld	ra,56(sp)
    8000422e:	7442                	ld	s0,48(sp)
    80004230:	74a2                	ld	s1,40(sp)
    80004232:	7902                	ld	s2,32(sp)
    80004234:	69e2                	ld	s3,24(sp)
    80004236:	6a42                	ld	s4,16(sp)
    80004238:	6121                	addi	sp,sp,64
    8000423a:	8082                	ret

000000008000423c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000423c:	711d                	addi	sp,sp,-96
    8000423e:	ec86                	sd	ra,88(sp)
    80004240:	e8a2                	sd	s0,80(sp)
    80004242:	e4a6                	sd	s1,72(sp)
    80004244:	e0ca                	sd	s2,64(sp)
    80004246:	fc4e                	sd	s3,56(sp)
    80004248:	f852                	sd	s4,48(sp)
    8000424a:	f456                	sd	s5,40(sp)
    8000424c:	f05a                	sd	s6,32(sp)
    8000424e:	ec5e                	sd	s7,24(sp)
    80004250:	e862                	sd	s8,16(sp)
    80004252:	e466                	sd	s9,8(sp)
    80004254:	1080                	addi	s0,sp,96
    80004256:	84aa                	mv	s1,a0
    80004258:	8b2e                	mv	s6,a1
    8000425a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000425c:	00054703          	lbu	a4,0(a0)
    80004260:	02f00793          	li	a5,47
    80004264:	02f70363          	beq	a4,a5,8000428a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004268:	ffffe097          	auipc	ra,0xffffe
    8000426c:	894080e7          	jalr	-1900(ra) # 80001afc <myproc>
    80004270:	15053503          	ld	a0,336(a0)
    80004274:	00000097          	auipc	ra,0x0
    80004278:	9f6080e7          	jalr	-1546(ra) # 80003c6a <idup>
    8000427c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000427e:	02f00913          	li	s2,47
  len = path - s;
    80004282:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004284:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004286:	4c05                	li	s8,1
    80004288:	a865                	j	80004340 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000428a:	4585                	li	a1,1
    8000428c:	4505                	li	a0,1
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	6e6080e7          	jalr	1766(ra) # 80003974 <iget>
    80004296:	89aa                	mv	s3,a0
    80004298:	b7dd                	j	8000427e <namex+0x42>
      iunlockput(ip);
    8000429a:	854e                	mv	a0,s3
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	c6e080e7          	jalr	-914(ra) # 80003f0a <iunlockput>
      return 0;
    800042a4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042a6:	854e                	mv	a0,s3
    800042a8:	60e6                	ld	ra,88(sp)
    800042aa:	6446                	ld	s0,80(sp)
    800042ac:	64a6                	ld	s1,72(sp)
    800042ae:	6906                	ld	s2,64(sp)
    800042b0:	79e2                	ld	s3,56(sp)
    800042b2:	7a42                	ld	s4,48(sp)
    800042b4:	7aa2                	ld	s5,40(sp)
    800042b6:	7b02                	ld	s6,32(sp)
    800042b8:	6be2                	ld	s7,24(sp)
    800042ba:	6c42                	ld	s8,16(sp)
    800042bc:	6ca2                	ld	s9,8(sp)
    800042be:	6125                	addi	sp,sp,96
    800042c0:	8082                	ret
      iunlock(ip);
    800042c2:	854e                	mv	a0,s3
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	aa6080e7          	jalr	-1370(ra) # 80003d6a <iunlock>
      return ip;
    800042cc:	bfe9                	j	800042a6 <namex+0x6a>
      iunlockput(ip);
    800042ce:	854e                	mv	a0,s3
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	c3a080e7          	jalr	-966(ra) # 80003f0a <iunlockput>
      return 0;
    800042d8:	89d2                	mv	s3,s4
    800042da:	b7f1                	j	800042a6 <namex+0x6a>
  len = path - s;
    800042dc:	40b48633          	sub	a2,s1,a1
    800042e0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042e4:	094cd463          	bge	s9,s4,8000436c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042e8:	4639                	li	a2,14
    800042ea:	8556                	mv	a0,s5
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	a54080e7          	jalr	-1452(ra) # 80000d40 <memmove>
  while(*path == '/')
    800042f4:	0004c783          	lbu	a5,0(s1)
    800042f8:	01279763          	bne	a5,s2,80004306 <namex+0xca>
    path++;
    800042fc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042fe:	0004c783          	lbu	a5,0(s1)
    80004302:	ff278de3          	beq	a5,s2,800042fc <namex+0xc0>
    ilock(ip);
    80004306:	854e                	mv	a0,s3
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	9a0080e7          	jalr	-1632(ra) # 80003ca8 <ilock>
    if(ip->type != T_DIR){
    80004310:	04499783          	lh	a5,68(s3)
    80004314:	f98793e3          	bne	a5,s8,8000429a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004318:	000b0563          	beqz	s6,80004322 <namex+0xe6>
    8000431c:	0004c783          	lbu	a5,0(s1)
    80004320:	d3cd                	beqz	a5,800042c2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004322:	865e                	mv	a2,s7
    80004324:	85d6                	mv	a1,s5
    80004326:	854e                	mv	a0,s3
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	e64080e7          	jalr	-412(ra) # 8000418c <dirlookup>
    80004330:	8a2a                	mv	s4,a0
    80004332:	dd51                	beqz	a0,800042ce <namex+0x92>
    iunlockput(ip);
    80004334:	854e                	mv	a0,s3
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	bd4080e7          	jalr	-1068(ra) # 80003f0a <iunlockput>
    ip = next;
    8000433e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004340:	0004c783          	lbu	a5,0(s1)
    80004344:	05279763          	bne	a5,s2,80004392 <namex+0x156>
    path++;
    80004348:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000434a:	0004c783          	lbu	a5,0(s1)
    8000434e:	ff278de3          	beq	a5,s2,80004348 <namex+0x10c>
  if(*path == 0)
    80004352:	c79d                	beqz	a5,80004380 <namex+0x144>
    path++;
    80004354:	85a6                	mv	a1,s1
  len = path - s;
    80004356:	8a5e                	mv	s4,s7
    80004358:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000435a:	01278963          	beq	a5,s2,8000436c <namex+0x130>
    8000435e:	dfbd                	beqz	a5,800042dc <namex+0xa0>
    path++;
    80004360:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004362:	0004c783          	lbu	a5,0(s1)
    80004366:	ff279ce3          	bne	a5,s2,8000435e <namex+0x122>
    8000436a:	bf8d                	j	800042dc <namex+0xa0>
    memmove(name, s, len);
    8000436c:	2601                	sext.w	a2,a2
    8000436e:	8556                	mv	a0,s5
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	9d0080e7          	jalr	-1584(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004378:	9a56                	add	s4,s4,s5
    8000437a:	000a0023          	sb	zero,0(s4)
    8000437e:	bf9d                	j	800042f4 <namex+0xb8>
  if(nameiparent){
    80004380:	f20b03e3          	beqz	s6,800042a6 <namex+0x6a>
    iput(ip);
    80004384:	854e                	mv	a0,s3
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	adc080e7          	jalr	-1316(ra) # 80003e62 <iput>
    return 0;
    8000438e:	4981                	li	s3,0
    80004390:	bf19                	j	800042a6 <namex+0x6a>
  if(*path == 0)
    80004392:	d7fd                	beqz	a5,80004380 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004394:	0004c783          	lbu	a5,0(s1)
    80004398:	85a6                	mv	a1,s1
    8000439a:	b7d1                	j	8000435e <namex+0x122>

000000008000439c <dirlink>:
{
    8000439c:	7139                	addi	sp,sp,-64
    8000439e:	fc06                	sd	ra,56(sp)
    800043a0:	f822                	sd	s0,48(sp)
    800043a2:	f426                	sd	s1,40(sp)
    800043a4:	f04a                	sd	s2,32(sp)
    800043a6:	ec4e                	sd	s3,24(sp)
    800043a8:	e852                	sd	s4,16(sp)
    800043aa:	0080                	addi	s0,sp,64
    800043ac:	892a                	mv	s2,a0
    800043ae:	8a2e                	mv	s4,a1
    800043b0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043b2:	4601                	li	a2,0
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	dd8080e7          	jalr	-552(ra) # 8000418c <dirlookup>
    800043bc:	e93d                	bnez	a0,80004432 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043be:	04c92483          	lw	s1,76(s2)
    800043c2:	c49d                	beqz	s1,800043f0 <dirlink+0x54>
    800043c4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c6:	4741                	li	a4,16
    800043c8:	86a6                	mv	a3,s1
    800043ca:	fc040613          	addi	a2,s0,-64
    800043ce:	4581                	li	a1,0
    800043d0:	854a                	mv	a0,s2
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	b8a080e7          	jalr	-1142(ra) # 80003f5c <readi>
    800043da:	47c1                	li	a5,16
    800043dc:	06f51163          	bne	a0,a5,8000443e <dirlink+0xa2>
    if(de.inum == 0)
    800043e0:	fc045783          	lhu	a5,-64(s0)
    800043e4:	c791                	beqz	a5,800043f0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e6:	24c1                	addiw	s1,s1,16
    800043e8:	04c92783          	lw	a5,76(s2)
    800043ec:	fcf4ede3          	bltu	s1,a5,800043c6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043f0:	4639                	li	a2,14
    800043f2:	85d2                	mv	a1,s4
    800043f4:	fc240513          	addi	a0,s0,-62
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	9fc080e7          	jalr	-1540(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004400:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004404:	4741                	li	a4,16
    80004406:	86a6                	mv	a3,s1
    80004408:	fc040613          	addi	a2,s0,-64
    8000440c:	4581                	li	a1,0
    8000440e:	854a                	mv	a0,s2
    80004410:	00000097          	auipc	ra,0x0
    80004414:	c44080e7          	jalr	-956(ra) # 80004054 <writei>
    80004418:	872a                	mv	a4,a0
    8000441a:	47c1                	li	a5,16
  return 0;
    8000441c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000441e:	02f71863          	bne	a4,a5,8000444e <dirlink+0xb2>
}
    80004422:	70e2                	ld	ra,56(sp)
    80004424:	7442                	ld	s0,48(sp)
    80004426:	74a2                	ld	s1,40(sp)
    80004428:	7902                	ld	s2,32(sp)
    8000442a:	69e2                	ld	s3,24(sp)
    8000442c:	6a42                	ld	s4,16(sp)
    8000442e:	6121                	addi	sp,sp,64
    80004430:	8082                	ret
    iput(ip);
    80004432:	00000097          	auipc	ra,0x0
    80004436:	a30080e7          	jalr	-1488(ra) # 80003e62 <iput>
    return -1;
    8000443a:	557d                	li	a0,-1
    8000443c:	b7dd                	j	80004422 <dirlink+0x86>
      panic("dirlink read");
    8000443e:	00004517          	auipc	a0,0x4
    80004442:	30a50513          	addi	a0,a0,778 # 80008748 <syscalls+0x1e0>
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	0f8080e7          	jalr	248(ra) # 8000053e <panic>
    panic("dirlink");
    8000444e:	00004517          	auipc	a0,0x4
    80004452:	40250513          	addi	a0,a0,1026 # 80008850 <syscalls+0x2e8>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0e8080e7          	jalr	232(ra) # 8000053e <panic>

000000008000445e <namei>:

struct inode*
namei(char *path)
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004466:	fe040613          	addi	a2,s0,-32
    8000446a:	4581                	li	a1,0
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	dd0080e7          	jalr	-560(ra) # 8000423c <namex>
}
    80004474:	60e2                	ld	ra,24(sp)
    80004476:	6442                	ld	s0,16(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000447c:	1141                	addi	sp,sp,-16
    8000447e:	e406                	sd	ra,8(sp)
    80004480:	e022                	sd	s0,0(sp)
    80004482:	0800                	addi	s0,sp,16
    80004484:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004486:	4585                	li	a1,1
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	db4080e7          	jalr	-588(ra) # 8000423c <namex>
}
    80004490:	60a2                	ld	ra,8(sp)
    80004492:	6402                	ld	s0,0(sp)
    80004494:	0141                	addi	sp,sp,16
    80004496:	8082                	ret

0000000080004498 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004498:	1101                	addi	sp,sp,-32
    8000449a:	ec06                	sd	ra,24(sp)
    8000449c:	e822                	sd	s0,16(sp)
    8000449e:	e426                	sd	s1,8(sp)
    800044a0:	e04a                	sd	s2,0(sp)
    800044a2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044a4:	0001f917          	auipc	s2,0x1f
    800044a8:	c4490913          	addi	s2,s2,-956 # 800230e8 <log>
    800044ac:	01892583          	lw	a1,24(s2)
    800044b0:	02892503          	lw	a0,40(s2)
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	ff2080e7          	jalr	-14(ra) # 800034a6 <bread>
    800044bc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044be:	02c92683          	lw	a3,44(s2)
    800044c2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044c4:	02d05763          	blez	a3,800044f2 <write_head+0x5a>
    800044c8:	0001f797          	auipc	a5,0x1f
    800044cc:	c5078793          	addi	a5,a5,-944 # 80023118 <log+0x30>
    800044d0:	05c50713          	addi	a4,a0,92
    800044d4:	36fd                	addiw	a3,a3,-1
    800044d6:	1682                	slli	a3,a3,0x20
    800044d8:	9281                	srli	a3,a3,0x20
    800044da:	068a                	slli	a3,a3,0x2
    800044dc:	0001f617          	auipc	a2,0x1f
    800044e0:	c4060613          	addi	a2,a2,-960 # 8002311c <log+0x34>
    800044e4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044e6:	4390                	lw	a2,0(a5)
    800044e8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044ea:	0791                	addi	a5,a5,4
    800044ec:	0711                	addi	a4,a4,4
    800044ee:	fed79ce3          	bne	a5,a3,800044e6 <write_head+0x4e>
  }
  bwrite(buf);
    800044f2:	8526                	mv	a0,s1
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	0a4080e7          	jalr	164(ra) # 80003598 <bwrite>
  brelse(buf);
    800044fc:	8526                	mv	a0,s1
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	0d8080e7          	jalr	216(ra) # 800035d6 <brelse>
}
    80004506:	60e2                	ld	ra,24(sp)
    80004508:	6442                	ld	s0,16(sp)
    8000450a:	64a2                	ld	s1,8(sp)
    8000450c:	6902                	ld	s2,0(sp)
    8000450e:	6105                	addi	sp,sp,32
    80004510:	8082                	ret

0000000080004512 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004512:	0001f797          	auipc	a5,0x1f
    80004516:	c027a783          	lw	a5,-1022(a5) # 80023114 <log+0x2c>
    8000451a:	0af05d63          	blez	a5,800045d4 <install_trans+0xc2>
{
    8000451e:	7139                	addi	sp,sp,-64
    80004520:	fc06                	sd	ra,56(sp)
    80004522:	f822                	sd	s0,48(sp)
    80004524:	f426                	sd	s1,40(sp)
    80004526:	f04a                	sd	s2,32(sp)
    80004528:	ec4e                	sd	s3,24(sp)
    8000452a:	e852                	sd	s4,16(sp)
    8000452c:	e456                	sd	s5,8(sp)
    8000452e:	e05a                	sd	s6,0(sp)
    80004530:	0080                	addi	s0,sp,64
    80004532:	8b2a                	mv	s6,a0
    80004534:	0001fa97          	auipc	s5,0x1f
    80004538:	be4a8a93          	addi	s5,s5,-1052 # 80023118 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000453c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000453e:	0001f997          	auipc	s3,0x1f
    80004542:	baa98993          	addi	s3,s3,-1110 # 800230e8 <log>
    80004546:	a035                	j	80004572 <install_trans+0x60>
      bunpin(dbuf);
    80004548:	8526                	mv	a0,s1
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	166080e7          	jalr	358(ra) # 800036b0 <bunpin>
    brelse(lbuf);
    80004552:	854a                	mv	a0,s2
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	082080e7          	jalr	130(ra) # 800035d6 <brelse>
    brelse(dbuf);
    8000455c:	8526                	mv	a0,s1
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	078080e7          	jalr	120(ra) # 800035d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004566:	2a05                	addiw	s4,s4,1
    80004568:	0a91                	addi	s5,s5,4
    8000456a:	02c9a783          	lw	a5,44(s3)
    8000456e:	04fa5963          	bge	s4,a5,800045c0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004572:	0189a583          	lw	a1,24(s3)
    80004576:	014585bb          	addw	a1,a1,s4
    8000457a:	2585                	addiw	a1,a1,1
    8000457c:	0289a503          	lw	a0,40(s3)
    80004580:	fffff097          	auipc	ra,0xfffff
    80004584:	f26080e7          	jalr	-218(ra) # 800034a6 <bread>
    80004588:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000458a:	000aa583          	lw	a1,0(s5)
    8000458e:	0289a503          	lw	a0,40(s3)
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	f14080e7          	jalr	-236(ra) # 800034a6 <bread>
    8000459a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000459c:	40000613          	li	a2,1024
    800045a0:	05890593          	addi	a1,s2,88
    800045a4:	05850513          	addi	a0,a0,88
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	798080e7          	jalr	1944(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	fe6080e7          	jalr	-26(ra) # 80003598 <bwrite>
    if(recovering == 0)
    800045ba:	f80b1ce3          	bnez	s6,80004552 <install_trans+0x40>
    800045be:	b769                	j	80004548 <install_trans+0x36>
}
    800045c0:	70e2                	ld	ra,56(sp)
    800045c2:	7442                	ld	s0,48(sp)
    800045c4:	74a2                	ld	s1,40(sp)
    800045c6:	7902                	ld	s2,32(sp)
    800045c8:	69e2                	ld	s3,24(sp)
    800045ca:	6a42                	ld	s4,16(sp)
    800045cc:	6aa2                	ld	s5,8(sp)
    800045ce:	6b02                	ld	s6,0(sp)
    800045d0:	6121                	addi	sp,sp,64
    800045d2:	8082                	ret
    800045d4:	8082                	ret

00000000800045d6 <initlog>:
{
    800045d6:	7179                	addi	sp,sp,-48
    800045d8:	f406                	sd	ra,40(sp)
    800045da:	f022                	sd	s0,32(sp)
    800045dc:	ec26                	sd	s1,24(sp)
    800045de:	e84a                	sd	s2,16(sp)
    800045e0:	e44e                	sd	s3,8(sp)
    800045e2:	1800                	addi	s0,sp,48
    800045e4:	892a                	mv	s2,a0
    800045e6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045e8:	0001f497          	auipc	s1,0x1f
    800045ec:	b0048493          	addi	s1,s1,-1280 # 800230e8 <log>
    800045f0:	00004597          	auipc	a1,0x4
    800045f4:	16858593          	addi	a1,a1,360 # 80008758 <syscalls+0x1f0>
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	55a080e7          	jalr	1370(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004602:	0149a583          	lw	a1,20(s3)
    80004606:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004608:	0109a783          	lw	a5,16(s3)
    8000460c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000460e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004612:	854a                	mv	a0,s2
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	e92080e7          	jalr	-366(ra) # 800034a6 <bread>
  log.lh.n = lh->n;
    8000461c:	4d3c                	lw	a5,88(a0)
    8000461e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004620:	02f05563          	blez	a5,8000464a <initlog+0x74>
    80004624:	05c50713          	addi	a4,a0,92
    80004628:	0001f697          	auipc	a3,0x1f
    8000462c:	af068693          	addi	a3,a3,-1296 # 80023118 <log+0x30>
    80004630:	37fd                	addiw	a5,a5,-1
    80004632:	1782                	slli	a5,a5,0x20
    80004634:	9381                	srli	a5,a5,0x20
    80004636:	078a                	slli	a5,a5,0x2
    80004638:	06050613          	addi	a2,a0,96
    8000463c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000463e:	4310                	lw	a2,0(a4)
    80004640:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004642:	0711                	addi	a4,a4,4
    80004644:	0691                	addi	a3,a3,4
    80004646:	fef71ce3          	bne	a4,a5,8000463e <initlog+0x68>
  brelse(buf);
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	f8c080e7          	jalr	-116(ra) # 800035d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004652:	4505                	li	a0,1
    80004654:	00000097          	auipc	ra,0x0
    80004658:	ebe080e7          	jalr	-322(ra) # 80004512 <install_trans>
  log.lh.n = 0;
    8000465c:	0001f797          	auipc	a5,0x1f
    80004660:	aa07ac23          	sw	zero,-1352(a5) # 80023114 <log+0x2c>
  write_head(); // clear the log
    80004664:	00000097          	auipc	ra,0x0
    80004668:	e34080e7          	jalr	-460(ra) # 80004498 <write_head>
}
    8000466c:	70a2                	ld	ra,40(sp)
    8000466e:	7402                	ld	s0,32(sp)
    80004670:	64e2                	ld	s1,24(sp)
    80004672:	6942                	ld	s2,16(sp)
    80004674:	69a2                	ld	s3,8(sp)
    80004676:	6145                	addi	sp,sp,48
    80004678:	8082                	ret

000000008000467a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000467a:	1101                	addi	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	e426                	sd	s1,8(sp)
    80004682:	e04a                	sd	s2,0(sp)
    80004684:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004686:	0001f517          	auipc	a0,0x1f
    8000468a:	a6250513          	addi	a0,a0,-1438 # 800230e8 <log>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	556080e7          	jalr	1366(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004696:	0001f497          	auipc	s1,0x1f
    8000469a:	a5248493          	addi	s1,s1,-1454 # 800230e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000469e:	4979                	li	s2,30
    800046a0:	a039                	j	800046ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800046a2:	85a6                	mv	a1,s1
    800046a4:	8526                	mv	a0,s1
    800046a6:	ffffe097          	auipc	ra,0xffffe
    800046aa:	c4a080e7          	jalr	-950(ra) # 800022f0 <sleep>
    if(log.committing){
    800046ae:	50dc                	lw	a5,36(s1)
    800046b0:	fbed                	bnez	a5,800046a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046b2:	509c                	lw	a5,32(s1)
    800046b4:	0017871b          	addiw	a4,a5,1
    800046b8:	0007069b          	sext.w	a3,a4
    800046bc:	0027179b          	slliw	a5,a4,0x2
    800046c0:	9fb9                	addw	a5,a5,a4
    800046c2:	0017979b          	slliw	a5,a5,0x1
    800046c6:	54d8                	lw	a4,44(s1)
    800046c8:	9fb9                	addw	a5,a5,a4
    800046ca:	00f95963          	bge	s2,a5,800046dc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046ce:	85a6                	mv	a1,s1
    800046d0:	8526                	mv	a0,s1
    800046d2:	ffffe097          	auipc	ra,0xffffe
    800046d6:	c1e080e7          	jalr	-994(ra) # 800022f0 <sleep>
    800046da:	bfd1                	j	800046ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046dc:	0001f517          	auipc	a0,0x1f
    800046e0:	a0c50513          	addi	a0,a0,-1524 # 800230e8 <log>
    800046e4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
      break;
    }
  }
}
    800046ee:	60e2                	ld	ra,24(sp)
    800046f0:	6442                	ld	s0,16(sp)
    800046f2:	64a2                	ld	s1,8(sp)
    800046f4:	6902                	ld	s2,0(sp)
    800046f6:	6105                	addi	sp,sp,32
    800046f8:	8082                	ret

00000000800046fa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046fa:	7139                	addi	sp,sp,-64
    800046fc:	fc06                	sd	ra,56(sp)
    800046fe:	f822                	sd	s0,48(sp)
    80004700:	f426                	sd	s1,40(sp)
    80004702:	f04a                	sd	s2,32(sp)
    80004704:	ec4e                	sd	s3,24(sp)
    80004706:	e852                	sd	s4,16(sp)
    80004708:	e456                	sd	s5,8(sp)
    8000470a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000470c:	0001f497          	auipc	s1,0x1f
    80004710:	9dc48493          	addi	s1,s1,-1572 # 800230e8 <log>
    80004714:	8526                	mv	a0,s1
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	4ce080e7          	jalr	1230(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000471e:	509c                	lw	a5,32(s1)
    80004720:	37fd                	addiw	a5,a5,-1
    80004722:	0007891b          	sext.w	s2,a5
    80004726:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004728:	50dc                	lw	a5,36(s1)
    8000472a:	efb9                	bnez	a5,80004788 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000472c:	06091663          	bnez	s2,80004798 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004730:	0001f497          	auipc	s1,0x1f
    80004734:	9b848493          	addi	s1,s1,-1608 # 800230e8 <log>
    80004738:	4785                	li	a5,1
    8000473a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000473c:	8526                	mv	a0,s1
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004746:	54dc                	lw	a5,44(s1)
    80004748:	06f04763          	bgtz	a5,800047b6 <end_op+0xbc>
    acquire(&log.lock);
    8000474c:	0001f497          	auipc	s1,0x1f
    80004750:	99c48493          	addi	s1,s1,-1636 # 800230e8 <log>
    80004754:	8526                	mv	a0,s1
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	48e080e7          	jalr	1166(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000475e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004762:	8526                	mv	a0,s1
    80004764:	ffffe097          	auipc	ra,0xffffe
    80004768:	e64080e7          	jalr	-412(ra) # 800025c8 <wakeup>
    release(&log.lock);
    8000476c:	8526                	mv	a0,s1
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	52a080e7          	jalr	1322(ra) # 80000c98 <release>
}
    80004776:	70e2                	ld	ra,56(sp)
    80004778:	7442                	ld	s0,48(sp)
    8000477a:	74a2                	ld	s1,40(sp)
    8000477c:	7902                	ld	s2,32(sp)
    8000477e:	69e2                	ld	s3,24(sp)
    80004780:	6a42                	ld	s4,16(sp)
    80004782:	6aa2                	ld	s5,8(sp)
    80004784:	6121                	addi	sp,sp,64
    80004786:	8082                	ret
    panic("log.committing");
    80004788:	00004517          	auipc	a0,0x4
    8000478c:	fd850513          	addi	a0,a0,-40 # 80008760 <syscalls+0x1f8>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	dae080e7          	jalr	-594(ra) # 8000053e <panic>
    wakeup(&log);
    80004798:	0001f497          	auipc	s1,0x1f
    8000479c:	95048493          	addi	s1,s1,-1712 # 800230e8 <log>
    800047a0:	8526                	mv	a0,s1
    800047a2:	ffffe097          	auipc	ra,0xffffe
    800047a6:	e26080e7          	jalr	-474(ra) # 800025c8 <wakeup>
  release(&log.lock);
    800047aa:	8526                	mv	a0,s1
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	4ec080e7          	jalr	1260(ra) # 80000c98 <release>
  if(do_commit){
    800047b4:	b7c9                	j	80004776 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047b6:	0001fa97          	auipc	s5,0x1f
    800047ba:	962a8a93          	addi	s5,s5,-1694 # 80023118 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047be:	0001fa17          	auipc	s4,0x1f
    800047c2:	92aa0a13          	addi	s4,s4,-1750 # 800230e8 <log>
    800047c6:	018a2583          	lw	a1,24(s4)
    800047ca:	012585bb          	addw	a1,a1,s2
    800047ce:	2585                	addiw	a1,a1,1
    800047d0:	028a2503          	lw	a0,40(s4)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	cd2080e7          	jalr	-814(ra) # 800034a6 <bread>
    800047dc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047de:	000aa583          	lw	a1,0(s5)
    800047e2:	028a2503          	lw	a0,40(s4)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	cc0080e7          	jalr	-832(ra) # 800034a6 <bread>
    800047ee:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047f0:	40000613          	li	a2,1024
    800047f4:	05850593          	addi	a1,a0,88
    800047f8:	05848513          	addi	a0,s1,88
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	544080e7          	jalr	1348(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004804:	8526                	mv	a0,s1
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	d92080e7          	jalr	-622(ra) # 80003598 <bwrite>
    brelse(from);
    8000480e:	854e                	mv	a0,s3
    80004810:	fffff097          	auipc	ra,0xfffff
    80004814:	dc6080e7          	jalr	-570(ra) # 800035d6 <brelse>
    brelse(to);
    80004818:	8526                	mv	a0,s1
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	dbc080e7          	jalr	-580(ra) # 800035d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004822:	2905                	addiw	s2,s2,1
    80004824:	0a91                	addi	s5,s5,4
    80004826:	02ca2783          	lw	a5,44(s4)
    8000482a:	f8f94ee3          	blt	s2,a5,800047c6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	c6a080e7          	jalr	-918(ra) # 80004498 <write_head>
    install_trans(0); // Now install writes to home locations
    80004836:	4501                	li	a0,0
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	cda080e7          	jalr	-806(ra) # 80004512 <install_trans>
    log.lh.n = 0;
    80004840:	0001f797          	auipc	a5,0x1f
    80004844:	8c07aa23          	sw	zero,-1836(a5) # 80023114 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	c50080e7          	jalr	-944(ra) # 80004498 <write_head>
    80004850:	bdf5                	j	8000474c <end_op+0x52>

0000000080004852 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004852:	1101                	addi	sp,sp,-32
    80004854:	ec06                	sd	ra,24(sp)
    80004856:	e822                	sd	s0,16(sp)
    80004858:	e426                	sd	s1,8(sp)
    8000485a:	e04a                	sd	s2,0(sp)
    8000485c:	1000                	addi	s0,sp,32
    8000485e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004860:	0001f917          	auipc	s2,0x1f
    80004864:	88890913          	addi	s2,s2,-1912 # 800230e8 <log>
    80004868:	854a                	mv	a0,s2
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	37a080e7          	jalr	890(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004872:	02c92603          	lw	a2,44(s2)
    80004876:	47f5                	li	a5,29
    80004878:	06c7c563          	blt	a5,a2,800048e2 <log_write+0x90>
    8000487c:	0001f797          	auipc	a5,0x1f
    80004880:	8887a783          	lw	a5,-1912(a5) # 80023104 <log+0x1c>
    80004884:	37fd                	addiw	a5,a5,-1
    80004886:	04f65e63          	bge	a2,a5,800048e2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000488a:	0001f797          	auipc	a5,0x1f
    8000488e:	87e7a783          	lw	a5,-1922(a5) # 80023108 <log+0x20>
    80004892:	06f05063          	blez	a5,800048f2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004896:	4781                	li	a5,0
    80004898:	06c05563          	blez	a2,80004902 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000489c:	44cc                	lw	a1,12(s1)
    8000489e:	0001f717          	auipc	a4,0x1f
    800048a2:	87a70713          	addi	a4,a4,-1926 # 80023118 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048a6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048a8:	4314                	lw	a3,0(a4)
    800048aa:	04b68c63          	beq	a3,a1,80004902 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048ae:	2785                	addiw	a5,a5,1
    800048b0:	0711                	addi	a4,a4,4
    800048b2:	fef61be3          	bne	a2,a5,800048a8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048b6:	0621                	addi	a2,a2,8
    800048b8:	060a                	slli	a2,a2,0x2
    800048ba:	0001f797          	auipc	a5,0x1f
    800048be:	82e78793          	addi	a5,a5,-2002 # 800230e8 <log>
    800048c2:	963e                	add	a2,a2,a5
    800048c4:	44dc                	lw	a5,12(s1)
    800048c6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048c8:	8526                	mv	a0,s1
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	daa080e7          	jalr	-598(ra) # 80003674 <bpin>
    log.lh.n++;
    800048d2:	0001f717          	auipc	a4,0x1f
    800048d6:	81670713          	addi	a4,a4,-2026 # 800230e8 <log>
    800048da:	575c                	lw	a5,44(a4)
    800048dc:	2785                	addiw	a5,a5,1
    800048de:	d75c                	sw	a5,44(a4)
    800048e0:	a835                	j	8000491c <log_write+0xca>
    panic("too big a transaction");
    800048e2:	00004517          	auipc	a0,0x4
    800048e6:	e8e50513          	addi	a0,a0,-370 # 80008770 <syscalls+0x208>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048f2:	00004517          	auipc	a0,0x4
    800048f6:	e9650513          	addi	a0,a0,-362 # 80008788 <syscalls+0x220>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004902:	00878713          	addi	a4,a5,8
    80004906:	00271693          	slli	a3,a4,0x2
    8000490a:	0001e717          	auipc	a4,0x1e
    8000490e:	7de70713          	addi	a4,a4,2014 # 800230e8 <log>
    80004912:	9736                	add	a4,a4,a3
    80004914:	44d4                	lw	a3,12(s1)
    80004916:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004918:	faf608e3          	beq	a2,a5,800048c8 <log_write+0x76>
  }
  release(&log.lock);
    8000491c:	0001e517          	auipc	a0,0x1e
    80004920:	7cc50513          	addi	a0,a0,1996 # 800230e8 <log>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	374080e7          	jalr	884(ra) # 80000c98 <release>
}
    8000492c:	60e2                	ld	ra,24(sp)
    8000492e:	6442                	ld	s0,16(sp)
    80004930:	64a2                	ld	s1,8(sp)
    80004932:	6902                	ld	s2,0(sp)
    80004934:	6105                	addi	sp,sp,32
    80004936:	8082                	ret

0000000080004938 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004938:	1101                	addi	sp,sp,-32
    8000493a:	ec06                	sd	ra,24(sp)
    8000493c:	e822                	sd	s0,16(sp)
    8000493e:	e426                	sd	s1,8(sp)
    80004940:	e04a                	sd	s2,0(sp)
    80004942:	1000                	addi	s0,sp,32
    80004944:	84aa                	mv	s1,a0
    80004946:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004948:	00004597          	auipc	a1,0x4
    8000494c:	e6058593          	addi	a1,a1,-416 # 800087a8 <syscalls+0x240>
    80004950:	0521                	addi	a0,a0,8
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	202080e7          	jalr	514(ra) # 80000b54 <initlock>
  lk->name = name;
    8000495a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000495e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004962:	0204a423          	sw	zero,40(s1)
}
    80004966:	60e2                	ld	ra,24(sp)
    80004968:	6442                	ld	s0,16(sp)
    8000496a:	64a2                	ld	s1,8(sp)
    8000496c:	6902                	ld	s2,0(sp)
    8000496e:	6105                	addi	sp,sp,32
    80004970:	8082                	ret

0000000080004972 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004972:	1101                	addi	sp,sp,-32
    80004974:	ec06                	sd	ra,24(sp)
    80004976:	e822                	sd	s0,16(sp)
    80004978:	e426                	sd	s1,8(sp)
    8000497a:	e04a                	sd	s2,0(sp)
    8000497c:	1000                	addi	s0,sp,32
    8000497e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004980:	00850913          	addi	s2,a0,8
    80004984:	854a                	mv	a0,s2
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	25e080e7          	jalr	606(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000498e:	409c                	lw	a5,0(s1)
    80004990:	cb89                	beqz	a5,800049a2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004992:	85ca                	mv	a1,s2
    80004994:	8526                	mv	a0,s1
    80004996:	ffffe097          	auipc	ra,0xffffe
    8000499a:	95a080e7          	jalr	-1702(ra) # 800022f0 <sleep>
  while (lk->locked) {
    8000499e:	409c                	lw	a5,0(s1)
    800049a0:	fbed                	bnez	a5,80004992 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049a2:	4785                	li	a5,1
    800049a4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049a6:	ffffd097          	auipc	ra,0xffffd
    800049aa:	156080e7          	jalr	342(ra) # 80001afc <myproc>
    800049ae:	591c                	lw	a5,48(a0)
    800049b0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049b2:	854a                	mv	a0,s2
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
}
    800049bc:	60e2                	ld	ra,24(sp)
    800049be:	6442                	ld	s0,16(sp)
    800049c0:	64a2                	ld	s1,8(sp)
    800049c2:	6902                	ld	s2,0(sp)
    800049c4:	6105                	addi	sp,sp,32
    800049c6:	8082                	ret

00000000800049c8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049c8:	1101                	addi	sp,sp,-32
    800049ca:	ec06                	sd	ra,24(sp)
    800049cc:	e822                	sd	s0,16(sp)
    800049ce:	e426                	sd	s1,8(sp)
    800049d0:	e04a                	sd	s2,0(sp)
    800049d2:	1000                	addi	s0,sp,32
    800049d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049d6:	00850913          	addi	s2,a0,8
    800049da:	854a                	mv	a0,s2
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	208080e7          	jalr	520(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049e8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffe097          	auipc	ra,0xffffe
    800049f2:	bda080e7          	jalr	-1062(ra) # 800025c8 <wakeup>
  release(&lk->lk);
    800049f6:	854a                	mv	a0,s2
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
}
    80004a00:	60e2                	ld	ra,24(sp)
    80004a02:	6442                	ld	s0,16(sp)
    80004a04:	64a2                	ld	s1,8(sp)
    80004a06:	6902                	ld	s2,0(sp)
    80004a08:	6105                	addi	sp,sp,32
    80004a0a:	8082                	ret

0000000080004a0c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a0c:	7179                	addi	sp,sp,-48
    80004a0e:	f406                	sd	ra,40(sp)
    80004a10:	f022                	sd	s0,32(sp)
    80004a12:	ec26                	sd	s1,24(sp)
    80004a14:	e84a                	sd	s2,16(sp)
    80004a16:	e44e                	sd	s3,8(sp)
    80004a18:	1800                	addi	s0,sp,48
    80004a1a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a1c:	00850913          	addi	s2,a0,8
    80004a20:	854a                	mv	a0,s2
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	1c2080e7          	jalr	450(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a2a:	409c                	lw	a5,0(s1)
    80004a2c:	ef99                	bnez	a5,80004a4a <holdingsleep+0x3e>
    80004a2e:	4481                	li	s1,0
  release(&lk->lk);
    80004a30:	854a                	mv	a0,s2
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	266080e7          	jalr	614(ra) # 80000c98 <release>
  return r;
}
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	70a2                	ld	ra,40(sp)
    80004a3e:	7402                	ld	s0,32(sp)
    80004a40:	64e2                	ld	s1,24(sp)
    80004a42:	6942                	ld	s2,16(sp)
    80004a44:	69a2                	ld	s3,8(sp)
    80004a46:	6145                	addi	sp,sp,48
    80004a48:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a4a:	0284a983          	lw	s3,40(s1)
    80004a4e:	ffffd097          	auipc	ra,0xffffd
    80004a52:	0ae080e7          	jalr	174(ra) # 80001afc <myproc>
    80004a56:	5904                	lw	s1,48(a0)
    80004a58:	413484b3          	sub	s1,s1,s3
    80004a5c:	0014b493          	seqz	s1,s1
    80004a60:	bfc1                	j	80004a30 <holdingsleep+0x24>

0000000080004a62 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a62:	1141                	addi	sp,sp,-16
    80004a64:	e406                	sd	ra,8(sp)
    80004a66:	e022                	sd	s0,0(sp)
    80004a68:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a6a:	00004597          	auipc	a1,0x4
    80004a6e:	d4e58593          	addi	a1,a1,-690 # 800087b8 <syscalls+0x250>
    80004a72:	0001e517          	auipc	a0,0x1e
    80004a76:	7be50513          	addi	a0,a0,1982 # 80023230 <ftable>
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	0da080e7          	jalr	218(ra) # 80000b54 <initlock>
}
    80004a82:	60a2                	ld	ra,8(sp)
    80004a84:	6402                	ld	s0,0(sp)
    80004a86:	0141                	addi	sp,sp,16
    80004a88:	8082                	ret

0000000080004a8a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a8a:	1101                	addi	sp,sp,-32
    80004a8c:	ec06                	sd	ra,24(sp)
    80004a8e:	e822                	sd	s0,16(sp)
    80004a90:	e426                	sd	s1,8(sp)
    80004a92:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a94:	0001e517          	auipc	a0,0x1e
    80004a98:	79c50513          	addi	a0,a0,1948 # 80023230 <ftable>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	148080e7          	jalr	328(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aa4:	0001e497          	auipc	s1,0x1e
    80004aa8:	7a448493          	addi	s1,s1,1956 # 80023248 <ftable+0x18>
    80004aac:	0001f717          	auipc	a4,0x1f
    80004ab0:	73c70713          	addi	a4,a4,1852 # 800241e8 <ftable+0xfb8>
    if(f->ref == 0){
    80004ab4:	40dc                	lw	a5,4(s1)
    80004ab6:	cf99                	beqz	a5,80004ad4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ab8:	02848493          	addi	s1,s1,40
    80004abc:	fee49ce3          	bne	s1,a4,80004ab4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ac0:	0001e517          	auipc	a0,0x1e
    80004ac4:	77050513          	addi	a0,a0,1904 # 80023230 <ftable>
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	1d0080e7          	jalr	464(ra) # 80000c98 <release>
  return 0;
    80004ad0:	4481                	li	s1,0
    80004ad2:	a819                	j	80004ae8 <filealloc+0x5e>
      f->ref = 1;
    80004ad4:	4785                	li	a5,1
    80004ad6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ad8:	0001e517          	auipc	a0,0x1e
    80004adc:	75850513          	addi	a0,a0,1880 # 80023230 <ftable>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	1b8080e7          	jalr	440(ra) # 80000c98 <release>
}
    80004ae8:	8526                	mv	a0,s1
    80004aea:	60e2                	ld	ra,24(sp)
    80004aec:	6442                	ld	s0,16(sp)
    80004aee:	64a2                	ld	s1,8(sp)
    80004af0:	6105                	addi	sp,sp,32
    80004af2:	8082                	ret

0000000080004af4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004af4:	1101                	addi	sp,sp,-32
    80004af6:	ec06                	sd	ra,24(sp)
    80004af8:	e822                	sd	s0,16(sp)
    80004afa:	e426                	sd	s1,8(sp)
    80004afc:	1000                	addi	s0,sp,32
    80004afe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b00:	0001e517          	auipc	a0,0x1e
    80004b04:	73050513          	addi	a0,a0,1840 # 80023230 <ftable>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b10:	40dc                	lw	a5,4(s1)
    80004b12:	02f05263          	blez	a5,80004b36 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b16:	2785                	addiw	a5,a5,1
    80004b18:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b1a:	0001e517          	auipc	a0,0x1e
    80004b1e:	71650513          	addi	a0,a0,1814 # 80023230 <ftable>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	176080e7          	jalr	374(ra) # 80000c98 <release>
  return f;
}
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	60e2                	ld	ra,24(sp)
    80004b2e:	6442                	ld	s0,16(sp)
    80004b30:	64a2                	ld	s1,8(sp)
    80004b32:	6105                	addi	sp,sp,32
    80004b34:	8082                	ret
    panic("filedup");
    80004b36:	00004517          	auipc	a0,0x4
    80004b3a:	c8a50513          	addi	a0,a0,-886 # 800087c0 <syscalls+0x258>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	a00080e7          	jalr	-1536(ra) # 8000053e <panic>

0000000080004b46 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b46:	7139                	addi	sp,sp,-64
    80004b48:	fc06                	sd	ra,56(sp)
    80004b4a:	f822                	sd	s0,48(sp)
    80004b4c:	f426                	sd	s1,40(sp)
    80004b4e:	f04a                	sd	s2,32(sp)
    80004b50:	ec4e                	sd	s3,24(sp)
    80004b52:	e852                	sd	s4,16(sp)
    80004b54:	e456                	sd	s5,8(sp)
    80004b56:	0080                	addi	s0,sp,64
    80004b58:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b5a:	0001e517          	auipc	a0,0x1e
    80004b5e:	6d650513          	addi	a0,a0,1750 # 80023230 <ftable>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	082080e7          	jalr	130(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b6a:	40dc                	lw	a5,4(s1)
    80004b6c:	06f05163          	blez	a5,80004bce <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b70:	37fd                	addiw	a5,a5,-1
    80004b72:	0007871b          	sext.w	a4,a5
    80004b76:	c0dc                	sw	a5,4(s1)
    80004b78:	06e04363          	bgtz	a4,80004bde <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b7c:	0004a903          	lw	s2,0(s1)
    80004b80:	0094ca83          	lbu	s5,9(s1)
    80004b84:	0104ba03          	ld	s4,16(s1)
    80004b88:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b8c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b90:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b94:	0001e517          	auipc	a0,0x1e
    80004b98:	69c50513          	addi	a0,a0,1692 # 80023230 <ftable>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	0fc080e7          	jalr	252(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ba4:	4785                	li	a5,1
    80004ba6:	04f90d63          	beq	s2,a5,80004c00 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004baa:	3979                	addiw	s2,s2,-2
    80004bac:	4785                	li	a5,1
    80004bae:	0527e063          	bltu	a5,s2,80004bee <fileclose+0xa8>
    begin_op();
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	ac8080e7          	jalr	-1336(ra) # 8000467a <begin_op>
    iput(ff.ip);
    80004bba:	854e                	mv	a0,s3
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	2a6080e7          	jalr	678(ra) # 80003e62 <iput>
    end_op();
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	b36080e7          	jalr	-1226(ra) # 800046fa <end_op>
    80004bcc:	a00d                	j	80004bee <fileclose+0xa8>
    panic("fileclose");
    80004bce:	00004517          	auipc	a0,0x4
    80004bd2:	bfa50513          	addi	a0,a0,-1030 # 800087c8 <syscalls+0x260>
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	968080e7          	jalr	-1688(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004bde:	0001e517          	auipc	a0,0x1e
    80004be2:	65250513          	addi	a0,a0,1618 # 80023230 <ftable>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  }
}
    80004bee:	70e2                	ld	ra,56(sp)
    80004bf0:	7442                	ld	s0,48(sp)
    80004bf2:	74a2                	ld	s1,40(sp)
    80004bf4:	7902                	ld	s2,32(sp)
    80004bf6:	69e2                	ld	s3,24(sp)
    80004bf8:	6a42                	ld	s4,16(sp)
    80004bfa:	6aa2                	ld	s5,8(sp)
    80004bfc:	6121                	addi	sp,sp,64
    80004bfe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c00:	85d6                	mv	a1,s5
    80004c02:	8552                	mv	a0,s4
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	34c080e7          	jalr	844(ra) # 80004f50 <pipeclose>
    80004c0c:	b7cd                	j	80004bee <fileclose+0xa8>

0000000080004c0e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c0e:	715d                	addi	sp,sp,-80
    80004c10:	e486                	sd	ra,72(sp)
    80004c12:	e0a2                	sd	s0,64(sp)
    80004c14:	fc26                	sd	s1,56(sp)
    80004c16:	f84a                	sd	s2,48(sp)
    80004c18:	f44e                	sd	s3,40(sp)
    80004c1a:	0880                	addi	s0,sp,80
    80004c1c:	84aa                	mv	s1,a0
    80004c1e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	edc080e7          	jalr	-292(ra) # 80001afc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c28:	409c                	lw	a5,0(s1)
    80004c2a:	37f9                	addiw	a5,a5,-2
    80004c2c:	4705                	li	a4,1
    80004c2e:	04f76763          	bltu	a4,a5,80004c7c <filestat+0x6e>
    80004c32:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c34:	6c88                	ld	a0,24(s1)
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	072080e7          	jalr	114(ra) # 80003ca8 <ilock>
    stati(f->ip, &st);
    80004c3e:	fb840593          	addi	a1,s0,-72
    80004c42:	6c88                	ld	a0,24(s1)
    80004c44:	fffff097          	auipc	ra,0xfffff
    80004c48:	2ee080e7          	jalr	750(ra) # 80003f32 <stati>
    iunlock(f->ip);
    80004c4c:	6c88                	ld	a0,24(s1)
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	11c080e7          	jalr	284(ra) # 80003d6a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c56:	46e1                	li	a3,24
    80004c58:	fb840613          	addi	a2,s0,-72
    80004c5c:	85ce                	mv	a1,s3
    80004c5e:	05093503          	ld	a0,80(s2)
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	a18080e7          	jalr	-1512(ra) # 8000167a <copyout>
    80004c6a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c6e:	60a6                	ld	ra,72(sp)
    80004c70:	6406                	ld	s0,64(sp)
    80004c72:	74e2                	ld	s1,56(sp)
    80004c74:	7942                	ld	s2,48(sp)
    80004c76:	79a2                	ld	s3,40(sp)
    80004c78:	6161                	addi	sp,sp,80
    80004c7a:	8082                	ret
  return -1;
    80004c7c:	557d                	li	a0,-1
    80004c7e:	bfc5                	j	80004c6e <filestat+0x60>

0000000080004c80 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c80:	7179                	addi	sp,sp,-48
    80004c82:	f406                	sd	ra,40(sp)
    80004c84:	f022                	sd	s0,32(sp)
    80004c86:	ec26                	sd	s1,24(sp)
    80004c88:	e84a                	sd	s2,16(sp)
    80004c8a:	e44e                	sd	s3,8(sp)
    80004c8c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c8e:	00854783          	lbu	a5,8(a0)
    80004c92:	c3d5                	beqz	a5,80004d36 <fileread+0xb6>
    80004c94:	84aa                	mv	s1,a0
    80004c96:	89ae                	mv	s3,a1
    80004c98:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c9a:	411c                	lw	a5,0(a0)
    80004c9c:	4705                	li	a4,1
    80004c9e:	04e78963          	beq	a5,a4,80004cf0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ca2:	470d                	li	a4,3
    80004ca4:	04e78d63          	beq	a5,a4,80004cfe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ca8:	4709                	li	a4,2
    80004caa:	06e79e63          	bne	a5,a4,80004d26 <fileread+0xa6>
    ilock(f->ip);
    80004cae:	6d08                	ld	a0,24(a0)
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	ff8080e7          	jalr	-8(ra) # 80003ca8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cb8:	874a                	mv	a4,s2
    80004cba:	5094                	lw	a3,32(s1)
    80004cbc:	864e                	mv	a2,s3
    80004cbe:	4585                	li	a1,1
    80004cc0:	6c88                	ld	a0,24(s1)
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	29a080e7          	jalr	666(ra) # 80003f5c <readi>
    80004cca:	892a                	mv	s2,a0
    80004ccc:	00a05563          	blez	a0,80004cd6 <fileread+0x56>
      f->off += r;
    80004cd0:	509c                	lw	a5,32(s1)
    80004cd2:	9fa9                	addw	a5,a5,a0
    80004cd4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cd6:	6c88                	ld	a0,24(s1)
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	092080e7          	jalr	146(ra) # 80003d6a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ce0:	854a                	mv	a0,s2
    80004ce2:	70a2                	ld	ra,40(sp)
    80004ce4:	7402                	ld	s0,32(sp)
    80004ce6:	64e2                	ld	s1,24(sp)
    80004ce8:	6942                	ld	s2,16(sp)
    80004cea:	69a2                	ld	s3,8(sp)
    80004cec:	6145                	addi	sp,sp,48
    80004cee:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cf0:	6908                	ld	a0,16(a0)
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	3c8080e7          	jalr	968(ra) # 800050ba <piperead>
    80004cfa:	892a                	mv	s2,a0
    80004cfc:	b7d5                	j	80004ce0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cfe:	02451783          	lh	a5,36(a0)
    80004d02:	03079693          	slli	a3,a5,0x30
    80004d06:	92c1                	srli	a3,a3,0x30
    80004d08:	4725                	li	a4,9
    80004d0a:	02d76863          	bltu	a4,a3,80004d3a <fileread+0xba>
    80004d0e:	0792                	slli	a5,a5,0x4
    80004d10:	0001e717          	auipc	a4,0x1e
    80004d14:	48070713          	addi	a4,a4,1152 # 80023190 <devsw>
    80004d18:	97ba                	add	a5,a5,a4
    80004d1a:	639c                	ld	a5,0(a5)
    80004d1c:	c38d                	beqz	a5,80004d3e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d1e:	4505                	li	a0,1
    80004d20:	9782                	jalr	a5
    80004d22:	892a                	mv	s2,a0
    80004d24:	bf75                	j	80004ce0 <fileread+0x60>
    panic("fileread");
    80004d26:	00004517          	auipc	a0,0x4
    80004d2a:	ab250513          	addi	a0,a0,-1358 # 800087d8 <syscalls+0x270>
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	810080e7          	jalr	-2032(ra) # 8000053e <panic>
    return -1;
    80004d36:	597d                	li	s2,-1
    80004d38:	b765                	j	80004ce0 <fileread+0x60>
      return -1;
    80004d3a:	597d                	li	s2,-1
    80004d3c:	b755                	j	80004ce0 <fileread+0x60>
    80004d3e:	597d                	li	s2,-1
    80004d40:	b745                	j	80004ce0 <fileread+0x60>

0000000080004d42 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d42:	715d                	addi	sp,sp,-80
    80004d44:	e486                	sd	ra,72(sp)
    80004d46:	e0a2                	sd	s0,64(sp)
    80004d48:	fc26                	sd	s1,56(sp)
    80004d4a:	f84a                	sd	s2,48(sp)
    80004d4c:	f44e                	sd	s3,40(sp)
    80004d4e:	f052                	sd	s4,32(sp)
    80004d50:	ec56                	sd	s5,24(sp)
    80004d52:	e85a                	sd	s6,16(sp)
    80004d54:	e45e                	sd	s7,8(sp)
    80004d56:	e062                	sd	s8,0(sp)
    80004d58:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d5a:	00954783          	lbu	a5,9(a0)
    80004d5e:	10078663          	beqz	a5,80004e6a <filewrite+0x128>
    80004d62:	892a                	mv	s2,a0
    80004d64:	8aae                	mv	s5,a1
    80004d66:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d68:	411c                	lw	a5,0(a0)
    80004d6a:	4705                	li	a4,1
    80004d6c:	02e78263          	beq	a5,a4,80004d90 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d70:	470d                	li	a4,3
    80004d72:	02e78663          	beq	a5,a4,80004d9e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d76:	4709                	li	a4,2
    80004d78:	0ee79163          	bne	a5,a4,80004e5a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d7c:	0ac05d63          	blez	a2,80004e36 <filewrite+0xf4>
    int i = 0;
    80004d80:	4981                	li	s3,0
    80004d82:	6b05                	lui	s6,0x1
    80004d84:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d88:	6b85                	lui	s7,0x1
    80004d8a:	c00b8b9b          	addiw	s7,s7,-1024
    80004d8e:	a861                	j	80004e26 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d90:	6908                	ld	a0,16(a0)
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	22e080e7          	jalr	558(ra) # 80004fc0 <pipewrite>
    80004d9a:	8a2a                	mv	s4,a0
    80004d9c:	a045                	j	80004e3c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d9e:	02451783          	lh	a5,36(a0)
    80004da2:	03079693          	slli	a3,a5,0x30
    80004da6:	92c1                	srli	a3,a3,0x30
    80004da8:	4725                	li	a4,9
    80004daa:	0cd76263          	bltu	a4,a3,80004e6e <filewrite+0x12c>
    80004dae:	0792                	slli	a5,a5,0x4
    80004db0:	0001e717          	auipc	a4,0x1e
    80004db4:	3e070713          	addi	a4,a4,992 # 80023190 <devsw>
    80004db8:	97ba                	add	a5,a5,a4
    80004dba:	679c                	ld	a5,8(a5)
    80004dbc:	cbdd                	beqz	a5,80004e72 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004dbe:	4505                	li	a0,1
    80004dc0:	9782                	jalr	a5
    80004dc2:	8a2a                	mv	s4,a0
    80004dc4:	a8a5                	j	80004e3c <filewrite+0xfa>
    80004dc6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dca:	00000097          	auipc	ra,0x0
    80004dce:	8b0080e7          	jalr	-1872(ra) # 8000467a <begin_op>
      ilock(f->ip);
    80004dd2:	01893503          	ld	a0,24(s2)
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	ed2080e7          	jalr	-302(ra) # 80003ca8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dde:	8762                	mv	a4,s8
    80004de0:	02092683          	lw	a3,32(s2)
    80004de4:	01598633          	add	a2,s3,s5
    80004de8:	4585                	li	a1,1
    80004dea:	01893503          	ld	a0,24(s2)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	266080e7          	jalr	614(ra) # 80004054 <writei>
    80004df6:	84aa                	mv	s1,a0
    80004df8:	00a05763          	blez	a0,80004e06 <filewrite+0xc4>
        f->off += r;
    80004dfc:	02092783          	lw	a5,32(s2)
    80004e00:	9fa9                	addw	a5,a5,a0
    80004e02:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e06:	01893503          	ld	a0,24(s2)
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	f60080e7          	jalr	-160(ra) # 80003d6a <iunlock>
      end_op();
    80004e12:	00000097          	auipc	ra,0x0
    80004e16:	8e8080e7          	jalr	-1816(ra) # 800046fa <end_op>

      if(r != n1){
    80004e1a:	009c1f63          	bne	s8,s1,80004e38 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e1e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e22:	0149db63          	bge	s3,s4,80004e38 <filewrite+0xf6>
      int n1 = n - i;
    80004e26:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e2a:	84be                	mv	s1,a5
    80004e2c:	2781                	sext.w	a5,a5
    80004e2e:	f8fb5ce3          	bge	s6,a5,80004dc6 <filewrite+0x84>
    80004e32:	84de                	mv	s1,s7
    80004e34:	bf49                	j	80004dc6 <filewrite+0x84>
    int i = 0;
    80004e36:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e38:	013a1f63          	bne	s4,s3,80004e56 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e3c:	8552                	mv	a0,s4
    80004e3e:	60a6                	ld	ra,72(sp)
    80004e40:	6406                	ld	s0,64(sp)
    80004e42:	74e2                	ld	s1,56(sp)
    80004e44:	7942                	ld	s2,48(sp)
    80004e46:	79a2                	ld	s3,40(sp)
    80004e48:	7a02                	ld	s4,32(sp)
    80004e4a:	6ae2                	ld	s5,24(sp)
    80004e4c:	6b42                	ld	s6,16(sp)
    80004e4e:	6ba2                	ld	s7,8(sp)
    80004e50:	6c02                	ld	s8,0(sp)
    80004e52:	6161                	addi	sp,sp,80
    80004e54:	8082                	ret
    ret = (i == n ? n : -1);
    80004e56:	5a7d                	li	s4,-1
    80004e58:	b7d5                	j	80004e3c <filewrite+0xfa>
    panic("filewrite");
    80004e5a:	00004517          	auipc	a0,0x4
    80004e5e:	98e50513          	addi	a0,a0,-1650 # 800087e8 <syscalls+0x280>
    80004e62:	ffffb097          	auipc	ra,0xffffb
    80004e66:	6dc080e7          	jalr	1756(ra) # 8000053e <panic>
    return -1;
    80004e6a:	5a7d                	li	s4,-1
    80004e6c:	bfc1                	j	80004e3c <filewrite+0xfa>
      return -1;
    80004e6e:	5a7d                	li	s4,-1
    80004e70:	b7f1                	j	80004e3c <filewrite+0xfa>
    80004e72:	5a7d                	li	s4,-1
    80004e74:	b7e1                	j	80004e3c <filewrite+0xfa>

0000000080004e76 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e76:	7179                	addi	sp,sp,-48
    80004e78:	f406                	sd	ra,40(sp)
    80004e7a:	f022                	sd	s0,32(sp)
    80004e7c:	ec26                	sd	s1,24(sp)
    80004e7e:	e84a                	sd	s2,16(sp)
    80004e80:	e44e                	sd	s3,8(sp)
    80004e82:	e052                	sd	s4,0(sp)
    80004e84:	1800                	addi	s0,sp,48
    80004e86:	84aa                	mv	s1,a0
    80004e88:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e8a:	0005b023          	sd	zero,0(a1)
    80004e8e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e92:	00000097          	auipc	ra,0x0
    80004e96:	bf8080e7          	jalr	-1032(ra) # 80004a8a <filealloc>
    80004e9a:	e088                	sd	a0,0(s1)
    80004e9c:	c551                	beqz	a0,80004f28 <pipealloc+0xb2>
    80004e9e:	00000097          	auipc	ra,0x0
    80004ea2:	bec080e7          	jalr	-1044(ra) # 80004a8a <filealloc>
    80004ea6:	00aa3023          	sd	a0,0(s4)
    80004eaa:	c92d                	beqz	a0,80004f1c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	c48080e7          	jalr	-952(ra) # 80000af4 <kalloc>
    80004eb4:	892a                	mv	s2,a0
    80004eb6:	c125                	beqz	a0,80004f16 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004eb8:	4985                	li	s3,1
    80004eba:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ebe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ec2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ec6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eca:	00003597          	auipc	a1,0x3
    80004ece:	5de58593          	addi	a1,a1,1502 # 800084a8 <states.1811+0x1b8>
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	c82080e7          	jalr	-894(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004eda:	609c                	ld	a5,0(s1)
    80004edc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ee0:	609c                	ld	a5,0(s1)
    80004ee2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ee6:	609c                	ld	a5,0(s1)
    80004ee8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004eec:	609c                	ld	a5,0(s1)
    80004eee:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ef2:	000a3783          	ld	a5,0(s4)
    80004ef6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004efa:	000a3783          	ld	a5,0(s4)
    80004efe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f02:	000a3783          	ld	a5,0(s4)
    80004f06:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f0a:	000a3783          	ld	a5,0(s4)
    80004f0e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f12:	4501                	li	a0,0
    80004f14:	a025                	j	80004f3c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f16:	6088                	ld	a0,0(s1)
    80004f18:	e501                	bnez	a0,80004f20 <pipealloc+0xaa>
    80004f1a:	a039                	j	80004f28 <pipealloc+0xb2>
    80004f1c:	6088                	ld	a0,0(s1)
    80004f1e:	c51d                	beqz	a0,80004f4c <pipealloc+0xd6>
    fileclose(*f0);
    80004f20:	00000097          	auipc	ra,0x0
    80004f24:	c26080e7          	jalr	-986(ra) # 80004b46 <fileclose>
  if(*f1)
    80004f28:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f2c:	557d                	li	a0,-1
  if(*f1)
    80004f2e:	c799                	beqz	a5,80004f3c <pipealloc+0xc6>
    fileclose(*f1);
    80004f30:	853e                	mv	a0,a5
    80004f32:	00000097          	auipc	ra,0x0
    80004f36:	c14080e7          	jalr	-1004(ra) # 80004b46 <fileclose>
  return -1;
    80004f3a:	557d                	li	a0,-1
}
    80004f3c:	70a2                	ld	ra,40(sp)
    80004f3e:	7402                	ld	s0,32(sp)
    80004f40:	64e2                	ld	s1,24(sp)
    80004f42:	6942                	ld	s2,16(sp)
    80004f44:	69a2                	ld	s3,8(sp)
    80004f46:	6a02                	ld	s4,0(sp)
    80004f48:	6145                	addi	sp,sp,48
    80004f4a:	8082                	ret
  return -1;
    80004f4c:	557d                	li	a0,-1
    80004f4e:	b7fd                	j	80004f3c <pipealloc+0xc6>

0000000080004f50 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f50:	1101                	addi	sp,sp,-32
    80004f52:	ec06                	sd	ra,24(sp)
    80004f54:	e822                	sd	s0,16(sp)
    80004f56:	e426                	sd	s1,8(sp)
    80004f58:	e04a                	sd	s2,0(sp)
    80004f5a:	1000                	addi	s0,sp,32
    80004f5c:	84aa                	mv	s1,a0
    80004f5e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	c84080e7          	jalr	-892(ra) # 80000be4 <acquire>
  if(writable){
    80004f68:	02090d63          	beqz	s2,80004fa2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f6c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f70:	21848513          	addi	a0,s1,536
    80004f74:	ffffd097          	auipc	ra,0xffffd
    80004f78:	654080e7          	jalr	1620(ra) # 800025c8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f7c:	2204b783          	ld	a5,544(s1)
    80004f80:	eb95                	bnez	a5,80004fb4 <pipeclose+0x64>
    release(&pi->lock);
    80004f82:	8526                	mv	a0,s1
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f8c:	8526                	mv	a0,s1
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	a6a080e7          	jalr	-1430(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f96:	60e2                	ld	ra,24(sp)
    80004f98:	6442                	ld	s0,16(sp)
    80004f9a:	64a2                	ld	s1,8(sp)
    80004f9c:	6902                	ld	s2,0(sp)
    80004f9e:	6105                	addi	sp,sp,32
    80004fa0:	8082                	ret
    pi->readopen = 0;
    80004fa2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fa6:	21c48513          	addi	a0,s1,540
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	61e080e7          	jalr	1566(ra) # 800025c8 <wakeup>
    80004fb2:	b7e9                	j	80004f7c <pipeclose+0x2c>
    release(&pi->lock);
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	ce2080e7          	jalr	-798(ra) # 80000c98 <release>
}
    80004fbe:	bfe1                	j	80004f96 <pipeclose+0x46>

0000000080004fc0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fc0:	7159                	addi	sp,sp,-112
    80004fc2:	f486                	sd	ra,104(sp)
    80004fc4:	f0a2                	sd	s0,96(sp)
    80004fc6:	eca6                	sd	s1,88(sp)
    80004fc8:	e8ca                	sd	s2,80(sp)
    80004fca:	e4ce                	sd	s3,72(sp)
    80004fcc:	e0d2                	sd	s4,64(sp)
    80004fce:	fc56                	sd	s5,56(sp)
    80004fd0:	f85a                	sd	s6,48(sp)
    80004fd2:	f45e                	sd	s7,40(sp)
    80004fd4:	f062                	sd	s8,32(sp)
    80004fd6:	ec66                	sd	s9,24(sp)
    80004fd8:	1880                	addi	s0,sp,112
    80004fda:	84aa                	mv	s1,a0
    80004fdc:	8aae                	mv	s5,a1
    80004fde:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	b1c080e7          	jalr	-1252(ra) # 80001afc <myproc>
    80004fe8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	bf8080e7          	jalr	-1032(ra) # 80000be4 <acquire>
  while(i < n){
    80004ff4:	0d405163          	blez	s4,800050b6 <pipewrite+0xf6>
    80004ff8:	8ba6                	mv	s7,s1
  int i = 0;
    80004ffa:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ffc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ffe:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005002:	21c48c13          	addi	s8,s1,540
    80005006:	a08d                	j	80005068 <pipewrite+0xa8>
      release(&pi->lock);
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
      return -1;
    80005012:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005014:	854a                	mv	a0,s2
    80005016:	70a6                	ld	ra,104(sp)
    80005018:	7406                	ld	s0,96(sp)
    8000501a:	64e6                	ld	s1,88(sp)
    8000501c:	6946                	ld	s2,80(sp)
    8000501e:	69a6                	ld	s3,72(sp)
    80005020:	6a06                	ld	s4,64(sp)
    80005022:	7ae2                	ld	s5,56(sp)
    80005024:	7b42                	ld	s6,48(sp)
    80005026:	7ba2                	ld	s7,40(sp)
    80005028:	7c02                	ld	s8,32(sp)
    8000502a:	6ce2                	ld	s9,24(sp)
    8000502c:	6165                	addi	sp,sp,112
    8000502e:	8082                	ret
      wakeup(&pi->nread);
    80005030:	8566                	mv	a0,s9
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	596080e7          	jalr	1430(ra) # 800025c8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000503a:	85de                	mv	a1,s7
    8000503c:	8562                	mv	a0,s8
    8000503e:	ffffd097          	auipc	ra,0xffffd
    80005042:	2b2080e7          	jalr	690(ra) # 800022f0 <sleep>
    80005046:	a839                	j	80005064 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005048:	21c4a783          	lw	a5,540(s1)
    8000504c:	0017871b          	addiw	a4,a5,1
    80005050:	20e4ae23          	sw	a4,540(s1)
    80005054:	1ff7f793          	andi	a5,a5,511
    80005058:	97a6                	add	a5,a5,s1
    8000505a:	f9f44703          	lbu	a4,-97(s0)
    8000505e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005062:	2905                	addiw	s2,s2,1
  while(i < n){
    80005064:	03495d63          	bge	s2,s4,8000509e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005068:	2204a783          	lw	a5,544(s1)
    8000506c:	dfd1                	beqz	a5,80005008 <pipewrite+0x48>
    8000506e:	0289a783          	lw	a5,40(s3)
    80005072:	fbd9                	bnez	a5,80005008 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005074:	2184a783          	lw	a5,536(s1)
    80005078:	21c4a703          	lw	a4,540(s1)
    8000507c:	2007879b          	addiw	a5,a5,512
    80005080:	faf708e3          	beq	a4,a5,80005030 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005084:	4685                	li	a3,1
    80005086:	01590633          	add	a2,s2,s5
    8000508a:	f9f40593          	addi	a1,s0,-97
    8000508e:	0509b503          	ld	a0,80(s3)
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	674080e7          	jalr	1652(ra) # 80001706 <copyin>
    8000509a:	fb6517e3          	bne	a0,s6,80005048 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000509e:	21848513          	addi	a0,s1,536
    800050a2:	ffffd097          	auipc	ra,0xffffd
    800050a6:	526080e7          	jalr	1318(ra) # 800025c8 <wakeup>
  release(&pi->lock);
    800050aa:	8526                	mv	a0,s1
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	bec080e7          	jalr	-1044(ra) # 80000c98 <release>
  return i;
    800050b4:	b785                	j	80005014 <pipewrite+0x54>
  int i = 0;
    800050b6:	4901                	li	s2,0
    800050b8:	b7dd                	j	8000509e <pipewrite+0xde>

00000000800050ba <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050ba:	715d                	addi	sp,sp,-80
    800050bc:	e486                	sd	ra,72(sp)
    800050be:	e0a2                	sd	s0,64(sp)
    800050c0:	fc26                	sd	s1,56(sp)
    800050c2:	f84a                	sd	s2,48(sp)
    800050c4:	f44e                	sd	s3,40(sp)
    800050c6:	f052                	sd	s4,32(sp)
    800050c8:	ec56                	sd	s5,24(sp)
    800050ca:	e85a                	sd	s6,16(sp)
    800050cc:	0880                	addi	s0,sp,80
    800050ce:	84aa                	mv	s1,a0
    800050d0:	892e                	mv	s2,a1
    800050d2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	a28080e7          	jalr	-1496(ra) # 80001afc <myproc>
    800050dc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050de:	8b26                	mv	s6,s1
    800050e0:	8526                	mv	a0,s1
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ea:	2184a703          	lw	a4,536(s1)
    800050ee:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050f2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050f6:	02f71463          	bne	a4,a5,8000511e <piperead+0x64>
    800050fa:	2244a783          	lw	a5,548(s1)
    800050fe:	c385                	beqz	a5,8000511e <piperead+0x64>
    if(pr->killed){
    80005100:	028a2783          	lw	a5,40(s4)
    80005104:	ebc1                	bnez	a5,80005194 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005106:	85da                	mv	a1,s6
    80005108:	854e                	mv	a0,s3
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	1e6080e7          	jalr	486(ra) # 800022f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005112:	2184a703          	lw	a4,536(s1)
    80005116:	21c4a783          	lw	a5,540(s1)
    8000511a:	fef700e3          	beq	a4,a5,800050fa <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000511e:	09505263          	blez	s5,800051a2 <piperead+0xe8>
    80005122:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005124:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005126:	2184a783          	lw	a5,536(s1)
    8000512a:	21c4a703          	lw	a4,540(s1)
    8000512e:	02f70d63          	beq	a4,a5,80005168 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005132:	0017871b          	addiw	a4,a5,1
    80005136:	20e4ac23          	sw	a4,536(s1)
    8000513a:	1ff7f793          	andi	a5,a5,511
    8000513e:	97a6                	add	a5,a5,s1
    80005140:	0187c783          	lbu	a5,24(a5)
    80005144:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005148:	4685                	li	a3,1
    8000514a:	fbf40613          	addi	a2,s0,-65
    8000514e:	85ca                	mv	a1,s2
    80005150:	050a3503          	ld	a0,80(s4)
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	526080e7          	jalr	1318(ra) # 8000167a <copyout>
    8000515c:	01650663          	beq	a0,s6,80005168 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005160:	2985                	addiw	s3,s3,1
    80005162:	0905                	addi	s2,s2,1
    80005164:	fd3a91e3          	bne	s5,s3,80005126 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005168:	21c48513          	addi	a0,s1,540
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	45c080e7          	jalr	1116(ra) # 800025c8 <wakeup>
  release(&pi->lock);
    80005174:	8526                	mv	a0,s1
    80005176:	ffffc097          	auipc	ra,0xffffc
    8000517a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>
  return i;
}
    8000517e:	854e                	mv	a0,s3
    80005180:	60a6                	ld	ra,72(sp)
    80005182:	6406                	ld	s0,64(sp)
    80005184:	74e2                	ld	s1,56(sp)
    80005186:	7942                	ld	s2,48(sp)
    80005188:	79a2                	ld	s3,40(sp)
    8000518a:	7a02                	ld	s4,32(sp)
    8000518c:	6ae2                	ld	s5,24(sp)
    8000518e:	6b42                	ld	s6,16(sp)
    80005190:	6161                	addi	sp,sp,80
    80005192:	8082                	ret
      release(&pi->lock);
    80005194:	8526                	mv	a0,s1
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
      return -1;
    8000519e:	59fd                	li	s3,-1
    800051a0:	bff9                	j	8000517e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a2:	4981                	li	s3,0
    800051a4:	b7d1                	j	80005168 <piperead+0xae>

00000000800051a6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800051a6:	df010113          	addi	sp,sp,-528
    800051aa:	20113423          	sd	ra,520(sp)
    800051ae:	20813023          	sd	s0,512(sp)
    800051b2:	ffa6                	sd	s1,504(sp)
    800051b4:	fbca                	sd	s2,496(sp)
    800051b6:	f7ce                	sd	s3,488(sp)
    800051b8:	f3d2                	sd	s4,480(sp)
    800051ba:	efd6                	sd	s5,472(sp)
    800051bc:	ebda                	sd	s6,464(sp)
    800051be:	e7de                	sd	s7,456(sp)
    800051c0:	e3e2                	sd	s8,448(sp)
    800051c2:	ff66                	sd	s9,440(sp)
    800051c4:	fb6a                	sd	s10,432(sp)
    800051c6:	f76e                	sd	s11,424(sp)
    800051c8:	0c00                	addi	s0,sp,528
    800051ca:	84aa                	mv	s1,a0
    800051cc:	dea43c23          	sd	a0,-520(s0)
    800051d0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051d4:	ffffd097          	auipc	ra,0xffffd
    800051d8:	928080e7          	jalr	-1752(ra) # 80001afc <myproc>
    800051dc:	892a                	mv	s2,a0

  begin_op();
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	49c080e7          	jalr	1180(ra) # 8000467a <begin_op>

  if((ip = namei(path)) == 0){
    800051e6:	8526                	mv	a0,s1
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	276080e7          	jalr	630(ra) # 8000445e <namei>
    800051f0:	c92d                	beqz	a0,80005262 <exec+0xbc>
    800051f2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	ab4080e7          	jalr	-1356(ra) # 80003ca8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051fc:	04000713          	li	a4,64
    80005200:	4681                	li	a3,0
    80005202:	e5040613          	addi	a2,s0,-432
    80005206:	4581                	li	a1,0
    80005208:	8526                	mv	a0,s1
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	d52080e7          	jalr	-686(ra) # 80003f5c <readi>
    80005212:	04000793          	li	a5,64
    80005216:	00f51a63          	bne	a0,a5,8000522a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000521a:	e5042703          	lw	a4,-432(s0)
    8000521e:	464c47b7          	lui	a5,0x464c4
    80005222:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005226:	04f70463          	beq	a4,a5,8000526e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000522a:	8526                	mv	a0,s1
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	cde080e7          	jalr	-802(ra) # 80003f0a <iunlockput>
    end_op();
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	4c6080e7          	jalr	1222(ra) # 800046fa <end_op>
  }
  return -1;
    8000523c:	557d                	li	a0,-1
}
    8000523e:	20813083          	ld	ra,520(sp)
    80005242:	20013403          	ld	s0,512(sp)
    80005246:	74fe                	ld	s1,504(sp)
    80005248:	795e                	ld	s2,496(sp)
    8000524a:	79be                	ld	s3,488(sp)
    8000524c:	7a1e                	ld	s4,480(sp)
    8000524e:	6afe                	ld	s5,472(sp)
    80005250:	6b5e                	ld	s6,464(sp)
    80005252:	6bbe                	ld	s7,456(sp)
    80005254:	6c1e                	ld	s8,448(sp)
    80005256:	7cfa                	ld	s9,440(sp)
    80005258:	7d5a                	ld	s10,432(sp)
    8000525a:	7dba                	ld	s11,424(sp)
    8000525c:	21010113          	addi	sp,sp,528
    80005260:	8082                	ret
    end_op();
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	498080e7          	jalr	1176(ra) # 800046fa <end_op>
    return -1;
    8000526a:	557d                	li	a0,-1
    8000526c:	bfc9                	j	8000523e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000526e:	854a                	mv	a0,s2
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	950080e7          	jalr	-1712(ra) # 80001bc0 <proc_pagetable>
    80005278:	8baa                	mv	s7,a0
    8000527a:	d945                	beqz	a0,8000522a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000527c:	e7042983          	lw	s3,-400(s0)
    80005280:	e8845783          	lhu	a5,-376(s0)
    80005284:	c7ad                	beqz	a5,800052ee <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005286:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005288:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000528a:	6c85                	lui	s9,0x1
    8000528c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005290:	def43823          	sd	a5,-528(s0)
    80005294:	a42d                	j	800054be <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005296:	00003517          	auipc	a0,0x3
    8000529a:	56250513          	addi	a0,a0,1378 # 800087f8 <syscalls+0x290>
    8000529e:	ffffb097          	auipc	ra,0xffffb
    800052a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052a6:	8756                	mv	a4,s5
    800052a8:	012d86bb          	addw	a3,s11,s2
    800052ac:	4581                	li	a1,0
    800052ae:	8526                	mv	a0,s1
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	cac080e7          	jalr	-852(ra) # 80003f5c <readi>
    800052b8:	2501                	sext.w	a0,a0
    800052ba:	1aaa9963          	bne	s5,a0,8000546c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052be:	6785                	lui	a5,0x1
    800052c0:	0127893b          	addw	s2,a5,s2
    800052c4:	77fd                	lui	a5,0xfffff
    800052c6:	01478a3b          	addw	s4,a5,s4
    800052ca:	1f897163          	bgeu	s2,s8,800054ac <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052ce:	02091593          	slli	a1,s2,0x20
    800052d2:	9181                	srli	a1,a1,0x20
    800052d4:	95ea                	add	a1,a1,s10
    800052d6:	855e                	mv	a0,s7
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	d9e080e7          	jalr	-610(ra) # 80001076 <walkaddr>
    800052e0:	862a                	mv	a2,a0
    if(pa == 0)
    800052e2:	d955                	beqz	a0,80005296 <exec+0xf0>
      n = PGSIZE;
    800052e4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052e6:	fd9a70e3          	bgeu	s4,s9,800052a6 <exec+0x100>
      n = sz - i;
    800052ea:	8ad2                	mv	s5,s4
    800052ec:	bf6d                	j	800052a6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052ee:	4901                	li	s2,0
  iunlockput(ip);
    800052f0:	8526                	mv	a0,s1
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	c18080e7          	jalr	-1000(ra) # 80003f0a <iunlockput>
  end_op();
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	400080e7          	jalr	1024(ra) # 800046fa <end_op>
  p = myproc();
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	7fa080e7          	jalr	2042(ra) # 80001afc <myproc>
    8000530a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000530c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005310:	6785                	lui	a5,0x1
    80005312:	17fd                	addi	a5,a5,-1
    80005314:	993e                	add	s2,s2,a5
    80005316:	757d                	lui	a0,0xfffff
    80005318:	00a977b3          	and	a5,s2,a0
    8000531c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005320:	6609                	lui	a2,0x2
    80005322:	963e                	add	a2,a2,a5
    80005324:	85be                	mv	a1,a5
    80005326:	855e                	mv	a0,s7
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	102080e7          	jalr	258(ra) # 8000142a <uvmalloc>
    80005330:	8b2a                	mv	s6,a0
  ip = 0;
    80005332:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005334:	12050c63          	beqz	a0,8000546c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005338:	75f9                	lui	a1,0xffffe
    8000533a:	95aa                	add	a1,a1,a0
    8000533c:	855e                	mv	a0,s7
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	30a080e7          	jalr	778(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005346:	7c7d                	lui	s8,0xfffff
    80005348:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000534a:	e0043783          	ld	a5,-512(s0)
    8000534e:	6388                	ld	a0,0(a5)
    80005350:	c535                	beqz	a0,800053bc <exec+0x216>
    80005352:	e9040993          	addi	s3,s0,-368
    80005356:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000535a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	b08080e7          	jalr	-1272(ra) # 80000e64 <strlen>
    80005364:	2505                	addiw	a0,a0,1
    80005366:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000536a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000536e:	13896363          	bltu	s2,s8,80005494 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005372:	e0043d83          	ld	s11,-512(s0)
    80005376:	000dba03          	ld	s4,0(s11)
    8000537a:	8552                	mv	a0,s4
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	ae8080e7          	jalr	-1304(ra) # 80000e64 <strlen>
    80005384:	0015069b          	addiw	a3,a0,1
    80005388:	8652                	mv	a2,s4
    8000538a:	85ca                	mv	a1,s2
    8000538c:	855e                	mv	a0,s7
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	2ec080e7          	jalr	748(ra) # 8000167a <copyout>
    80005396:	10054363          	bltz	a0,8000549c <exec+0x2f6>
    ustack[argc] = sp;
    8000539a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000539e:	0485                	addi	s1,s1,1
    800053a0:	008d8793          	addi	a5,s11,8
    800053a4:	e0f43023          	sd	a5,-512(s0)
    800053a8:	008db503          	ld	a0,8(s11)
    800053ac:	c911                	beqz	a0,800053c0 <exec+0x21a>
    if(argc >= MAXARG)
    800053ae:	09a1                	addi	s3,s3,8
    800053b0:	fb3c96e3          	bne	s9,s3,8000535c <exec+0x1b6>
  sz = sz1;
    800053b4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053b8:	4481                	li	s1,0
    800053ba:	a84d                	j	8000546c <exec+0x2c6>
  sp = sz;
    800053bc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053be:	4481                	li	s1,0
  ustack[argc] = 0;
    800053c0:	00349793          	slli	a5,s1,0x3
    800053c4:	f9040713          	addi	a4,s0,-112
    800053c8:	97ba                	add	a5,a5,a4
    800053ca:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053ce:	00148693          	addi	a3,s1,1
    800053d2:	068e                	slli	a3,a3,0x3
    800053d4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053d8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053dc:	01897663          	bgeu	s2,s8,800053e8 <exec+0x242>
  sz = sz1;
    800053e0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053e4:	4481                	li	s1,0
    800053e6:	a059                	j	8000546c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053e8:	e9040613          	addi	a2,s0,-368
    800053ec:	85ca                	mv	a1,s2
    800053ee:	855e                	mv	a0,s7
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	28a080e7          	jalr	650(ra) # 8000167a <copyout>
    800053f8:	0a054663          	bltz	a0,800054a4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053fc:	058ab783          	ld	a5,88(s5)
    80005400:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005404:	df843783          	ld	a5,-520(s0)
    80005408:	0007c703          	lbu	a4,0(a5)
    8000540c:	cf11                	beqz	a4,80005428 <exec+0x282>
    8000540e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005410:	02f00693          	li	a3,47
    80005414:	a039                	j	80005422 <exec+0x27c>
      last = s+1;
    80005416:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000541a:	0785                	addi	a5,a5,1
    8000541c:	fff7c703          	lbu	a4,-1(a5)
    80005420:	c701                	beqz	a4,80005428 <exec+0x282>
    if(*s == '/')
    80005422:	fed71ce3          	bne	a4,a3,8000541a <exec+0x274>
    80005426:	bfc5                	j	80005416 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005428:	4641                	li	a2,16
    8000542a:	df843583          	ld	a1,-520(s0)
    8000542e:	158a8513          	addi	a0,s5,344
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	a00080e7          	jalr	-1536(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000543a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000543e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005442:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005446:	058ab783          	ld	a5,88(s5)
    8000544a:	e6843703          	ld	a4,-408(s0)
    8000544e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005450:	058ab783          	ld	a5,88(s5)
    80005454:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005458:	85ea                	mv	a1,s10
    8000545a:	ffffd097          	auipc	ra,0xffffd
    8000545e:	802080e7          	jalr	-2046(ra) # 80001c5c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005462:	0004851b          	sext.w	a0,s1
    80005466:	bbe1                	j	8000523e <exec+0x98>
    80005468:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000546c:	e0843583          	ld	a1,-504(s0)
    80005470:	855e                	mv	a0,s7
    80005472:	ffffc097          	auipc	ra,0xffffc
    80005476:	7ea080e7          	jalr	2026(ra) # 80001c5c <proc_freepagetable>
  if(ip){
    8000547a:	da0498e3          	bnez	s1,8000522a <exec+0x84>
  return -1;
    8000547e:	557d                	li	a0,-1
    80005480:	bb7d                	j	8000523e <exec+0x98>
    80005482:	e1243423          	sd	s2,-504(s0)
    80005486:	b7dd                	j	8000546c <exec+0x2c6>
    80005488:	e1243423          	sd	s2,-504(s0)
    8000548c:	b7c5                	j	8000546c <exec+0x2c6>
    8000548e:	e1243423          	sd	s2,-504(s0)
    80005492:	bfe9                	j	8000546c <exec+0x2c6>
  sz = sz1;
    80005494:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005498:	4481                	li	s1,0
    8000549a:	bfc9                	j	8000546c <exec+0x2c6>
  sz = sz1;
    8000549c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054a0:	4481                	li	s1,0
    800054a2:	b7e9                	j	8000546c <exec+0x2c6>
  sz = sz1;
    800054a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054a8:	4481                	li	s1,0
    800054aa:	b7c9                	j	8000546c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054ac:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054b0:	2b05                	addiw	s6,s6,1
    800054b2:	0389899b          	addiw	s3,s3,56
    800054b6:	e8845783          	lhu	a5,-376(s0)
    800054ba:	e2fb5be3          	bge	s6,a5,800052f0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054be:	2981                	sext.w	s3,s3
    800054c0:	03800713          	li	a4,56
    800054c4:	86ce                	mv	a3,s3
    800054c6:	e1840613          	addi	a2,s0,-488
    800054ca:	4581                	li	a1,0
    800054cc:	8526                	mv	a0,s1
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	a8e080e7          	jalr	-1394(ra) # 80003f5c <readi>
    800054d6:	03800793          	li	a5,56
    800054da:	f8f517e3          	bne	a0,a5,80005468 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054de:	e1842783          	lw	a5,-488(s0)
    800054e2:	4705                	li	a4,1
    800054e4:	fce796e3          	bne	a5,a4,800054b0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054e8:	e4043603          	ld	a2,-448(s0)
    800054ec:	e3843783          	ld	a5,-456(s0)
    800054f0:	f8f669e3          	bltu	a2,a5,80005482 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054f4:	e2843783          	ld	a5,-472(s0)
    800054f8:	963e                	add	a2,a2,a5
    800054fa:	f8f667e3          	bltu	a2,a5,80005488 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054fe:	85ca                	mv	a1,s2
    80005500:	855e                	mv	a0,s7
    80005502:	ffffc097          	auipc	ra,0xffffc
    80005506:	f28080e7          	jalr	-216(ra) # 8000142a <uvmalloc>
    8000550a:	e0a43423          	sd	a0,-504(s0)
    8000550e:	d141                	beqz	a0,8000548e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005510:	e2843d03          	ld	s10,-472(s0)
    80005514:	df043783          	ld	a5,-528(s0)
    80005518:	00fd77b3          	and	a5,s10,a5
    8000551c:	fba1                	bnez	a5,8000546c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000551e:	e2042d83          	lw	s11,-480(s0)
    80005522:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005526:	f80c03e3          	beqz	s8,800054ac <exec+0x306>
    8000552a:	8a62                	mv	s4,s8
    8000552c:	4901                	li	s2,0
    8000552e:	b345                	j	800052ce <exec+0x128>

0000000080005530 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005530:	7179                	addi	sp,sp,-48
    80005532:	f406                	sd	ra,40(sp)
    80005534:	f022                	sd	s0,32(sp)
    80005536:	ec26                	sd	s1,24(sp)
    80005538:	e84a                	sd	s2,16(sp)
    8000553a:	1800                	addi	s0,sp,48
    8000553c:	892e                	mv	s2,a1
    8000553e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005540:	fdc40593          	addi	a1,s0,-36
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	9a8080e7          	jalr	-1624(ra) # 80002eec <argint>
    8000554c:	04054063          	bltz	a0,8000558c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005550:	fdc42703          	lw	a4,-36(s0)
    80005554:	47bd                	li	a5,15
    80005556:	02e7ed63          	bltu	a5,a4,80005590 <argfd+0x60>
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	5a2080e7          	jalr	1442(ra) # 80001afc <myproc>
    80005562:	fdc42703          	lw	a4,-36(s0)
    80005566:	01a70793          	addi	a5,a4,26
    8000556a:	078e                	slli	a5,a5,0x3
    8000556c:	953e                	add	a0,a0,a5
    8000556e:	611c                	ld	a5,0(a0)
    80005570:	c395                	beqz	a5,80005594 <argfd+0x64>
    return -1;
  if(pfd)
    80005572:	00090463          	beqz	s2,8000557a <argfd+0x4a>
    *pfd = fd;
    80005576:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000557a:	4501                	li	a0,0
  if(pf)
    8000557c:	c091                	beqz	s1,80005580 <argfd+0x50>
    *pf = f;
    8000557e:	e09c                	sd	a5,0(s1)
}
    80005580:	70a2                	ld	ra,40(sp)
    80005582:	7402                	ld	s0,32(sp)
    80005584:	64e2                	ld	s1,24(sp)
    80005586:	6942                	ld	s2,16(sp)
    80005588:	6145                	addi	sp,sp,48
    8000558a:	8082                	ret
    return -1;
    8000558c:	557d                	li	a0,-1
    8000558e:	bfcd                	j	80005580 <argfd+0x50>
    return -1;
    80005590:	557d                	li	a0,-1
    80005592:	b7fd                	j	80005580 <argfd+0x50>
    80005594:	557d                	li	a0,-1
    80005596:	b7ed                	j	80005580 <argfd+0x50>

0000000080005598 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005598:	1101                	addi	sp,sp,-32
    8000559a:	ec06                	sd	ra,24(sp)
    8000559c:	e822                	sd	s0,16(sp)
    8000559e:	e426                	sd	s1,8(sp)
    800055a0:	1000                	addi	s0,sp,32
    800055a2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055a4:	ffffc097          	auipc	ra,0xffffc
    800055a8:	558080e7          	jalr	1368(ra) # 80001afc <myproc>
    800055ac:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055ae:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd70d0>
    800055b2:	4501                	li	a0,0
    800055b4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055b6:	6398                	ld	a4,0(a5)
    800055b8:	cb19                	beqz	a4,800055ce <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055ba:	2505                	addiw	a0,a0,1
    800055bc:	07a1                	addi	a5,a5,8
    800055be:	fed51ce3          	bne	a0,a3,800055b6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055c2:	557d                	li	a0,-1
}
    800055c4:	60e2                	ld	ra,24(sp)
    800055c6:	6442                	ld	s0,16(sp)
    800055c8:	64a2                	ld	s1,8(sp)
    800055ca:	6105                	addi	sp,sp,32
    800055cc:	8082                	ret
      p->ofile[fd] = f;
    800055ce:	01a50793          	addi	a5,a0,26
    800055d2:	078e                	slli	a5,a5,0x3
    800055d4:	963e                	add	a2,a2,a5
    800055d6:	e204                	sd	s1,0(a2)
      return fd;
    800055d8:	b7f5                	j	800055c4 <fdalloc+0x2c>

00000000800055da <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055da:	715d                	addi	sp,sp,-80
    800055dc:	e486                	sd	ra,72(sp)
    800055de:	e0a2                	sd	s0,64(sp)
    800055e0:	fc26                	sd	s1,56(sp)
    800055e2:	f84a                	sd	s2,48(sp)
    800055e4:	f44e                	sd	s3,40(sp)
    800055e6:	f052                	sd	s4,32(sp)
    800055e8:	ec56                	sd	s5,24(sp)
    800055ea:	0880                	addi	s0,sp,80
    800055ec:	89ae                	mv	s3,a1
    800055ee:	8ab2                	mv	s5,a2
    800055f0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055f2:	fb040593          	addi	a1,s0,-80
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	e86080e7          	jalr	-378(ra) # 8000447c <nameiparent>
    800055fe:	892a                	mv	s2,a0
    80005600:	12050f63          	beqz	a0,8000573e <create+0x164>
    return 0;

  ilock(dp);
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	6a4080e7          	jalr	1700(ra) # 80003ca8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000560c:	4601                	li	a2,0
    8000560e:	fb040593          	addi	a1,s0,-80
    80005612:	854a                	mv	a0,s2
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	b78080e7          	jalr	-1160(ra) # 8000418c <dirlookup>
    8000561c:	84aa                	mv	s1,a0
    8000561e:	c921                	beqz	a0,8000566e <create+0x94>
    iunlockput(dp);
    80005620:	854a                	mv	a0,s2
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	8e8080e7          	jalr	-1816(ra) # 80003f0a <iunlockput>
    ilock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	67c080e7          	jalr	1660(ra) # 80003ca8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005634:	2981                	sext.w	s3,s3
    80005636:	4789                	li	a5,2
    80005638:	02f99463          	bne	s3,a5,80005660 <create+0x86>
    8000563c:	0444d783          	lhu	a5,68(s1)
    80005640:	37f9                	addiw	a5,a5,-2
    80005642:	17c2                	slli	a5,a5,0x30
    80005644:	93c1                	srli	a5,a5,0x30
    80005646:	4705                	li	a4,1
    80005648:	00f76c63          	bltu	a4,a5,80005660 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000564c:	8526                	mv	a0,s1
    8000564e:	60a6                	ld	ra,72(sp)
    80005650:	6406                	ld	s0,64(sp)
    80005652:	74e2                	ld	s1,56(sp)
    80005654:	7942                	ld	s2,48(sp)
    80005656:	79a2                	ld	s3,40(sp)
    80005658:	7a02                	ld	s4,32(sp)
    8000565a:	6ae2                	ld	s5,24(sp)
    8000565c:	6161                	addi	sp,sp,80
    8000565e:	8082                	ret
    iunlockput(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	8a8080e7          	jalr	-1880(ra) # 80003f0a <iunlockput>
    return 0;
    8000566a:	4481                	li	s1,0
    8000566c:	b7c5                	j	8000564c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000566e:	85ce                	mv	a1,s3
    80005670:	00092503          	lw	a0,0(s2)
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	49c080e7          	jalr	1180(ra) # 80003b10 <ialloc>
    8000567c:	84aa                	mv	s1,a0
    8000567e:	c529                	beqz	a0,800056c8 <create+0xee>
  ilock(ip);
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	628080e7          	jalr	1576(ra) # 80003ca8 <ilock>
  ip->major = major;
    80005688:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000568c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005690:	4785                	li	a5,1
    80005692:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	546080e7          	jalr	1350(ra) # 80003bde <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056a0:	2981                	sext.w	s3,s3
    800056a2:	4785                	li	a5,1
    800056a4:	02f98a63          	beq	s3,a5,800056d8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800056a8:	40d0                	lw	a2,4(s1)
    800056aa:	fb040593          	addi	a1,s0,-80
    800056ae:	854a                	mv	a0,s2
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	cec080e7          	jalr	-788(ra) # 8000439c <dirlink>
    800056b8:	06054b63          	bltz	a0,8000572e <create+0x154>
  iunlockput(dp);
    800056bc:	854a                	mv	a0,s2
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	84c080e7          	jalr	-1972(ra) # 80003f0a <iunlockput>
  return ip;
    800056c6:	b759                	j	8000564c <create+0x72>
    panic("create: ialloc");
    800056c8:	00003517          	auipc	a0,0x3
    800056cc:	15050513          	addi	a0,a0,336 # 80008818 <syscalls+0x2b0>
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056d8:	04a95783          	lhu	a5,74(s2)
    800056dc:	2785                	addiw	a5,a5,1
    800056de:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056e2:	854a                	mv	a0,s2
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	4fa080e7          	jalr	1274(ra) # 80003bde <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056ec:	40d0                	lw	a2,4(s1)
    800056ee:	00003597          	auipc	a1,0x3
    800056f2:	13a58593          	addi	a1,a1,314 # 80008828 <syscalls+0x2c0>
    800056f6:	8526                	mv	a0,s1
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	ca4080e7          	jalr	-860(ra) # 8000439c <dirlink>
    80005700:	00054f63          	bltz	a0,8000571e <create+0x144>
    80005704:	00492603          	lw	a2,4(s2)
    80005708:	00003597          	auipc	a1,0x3
    8000570c:	12858593          	addi	a1,a1,296 # 80008830 <syscalls+0x2c8>
    80005710:	8526                	mv	a0,s1
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	c8a080e7          	jalr	-886(ra) # 8000439c <dirlink>
    8000571a:	f80557e3          	bgez	a0,800056a8 <create+0xce>
      panic("create dots");
    8000571e:	00003517          	auipc	a0,0x3
    80005722:	11a50513          	addi	a0,a0,282 # 80008838 <syscalls+0x2d0>
    80005726:	ffffb097          	auipc	ra,0xffffb
    8000572a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000572e:	00003517          	auipc	a0,0x3
    80005732:	11a50513          	addi	a0,a0,282 # 80008848 <syscalls+0x2e0>
    80005736:	ffffb097          	auipc	ra,0xffffb
    8000573a:	e08080e7          	jalr	-504(ra) # 8000053e <panic>
    return 0;
    8000573e:	84aa                	mv	s1,a0
    80005740:	b731                	j	8000564c <create+0x72>

0000000080005742 <sys_dup>:
{
    80005742:	7179                	addi	sp,sp,-48
    80005744:	f406                	sd	ra,40(sp)
    80005746:	f022                	sd	s0,32(sp)
    80005748:	ec26                	sd	s1,24(sp)
    8000574a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000574c:	fd840613          	addi	a2,s0,-40
    80005750:	4581                	li	a1,0
    80005752:	4501                	li	a0,0
    80005754:	00000097          	auipc	ra,0x0
    80005758:	ddc080e7          	jalr	-548(ra) # 80005530 <argfd>
    return -1;
    8000575c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000575e:	02054363          	bltz	a0,80005784 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005762:	fd843503          	ld	a0,-40(s0)
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	e32080e7          	jalr	-462(ra) # 80005598 <fdalloc>
    8000576e:	84aa                	mv	s1,a0
    return -1;
    80005770:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005772:	00054963          	bltz	a0,80005784 <sys_dup+0x42>
  filedup(f);
    80005776:	fd843503          	ld	a0,-40(s0)
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	37a080e7          	jalr	890(ra) # 80004af4 <filedup>
  return fd;
    80005782:	87a6                	mv	a5,s1
}
    80005784:	853e                	mv	a0,a5
    80005786:	70a2                	ld	ra,40(sp)
    80005788:	7402                	ld	s0,32(sp)
    8000578a:	64e2                	ld	s1,24(sp)
    8000578c:	6145                	addi	sp,sp,48
    8000578e:	8082                	ret

0000000080005790 <sys_read>:
{
    80005790:	7179                	addi	sp,sp,-48
    80005792:	f406                	sd	ra,40(sp)
    80005794:	f022                	sd	s0,32(sp)
    80005796:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005798:	fe840613          	addi	a2,s0,-24
    8000579c:	4581                	li	a1,0
    8000579e:	4501                	li	a0,0
    800057a0:	00000097          	auipc	ra,0x0
    800057a4:	d90080e7          	jalr	-624(ra) # 80005530 <argfd>
    return -1;
    800057a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057aa:	04054163          	bltz	a0,800057ec <sys_read+0x5c>
    800057ae:	fe440593          	addi	a1,s0,-28
    800057b2:	4509                	li	a0,2
    800057b4:	ffffd097          	auipc	ra,0xffffd
    800057b8:	738080e7          	jalr	1848(ra) # 80002eec <argint>
    return -1;
    800057bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057be:	02054763          	bltz	a0,800057ec <sys_read+0x5c>
    800057c2:	fd840593          	addi	a1,s0,-40
    800057c6:	4505                	li	a0,1
    800057c8:	ffffd097          	auipc	ra,0xffffd
    800057cc:	746080e7          	jalr	1862(ra) # 80002f0e <argaddr>
    return -1;
    800057d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057d2:	00054d63          	bltz	a0,800057ec <sys_read+0x5c>
  return fileread(f, p, n);
    800057d6:	fe442603          	lw	a2,-28(s0)
    800057da:	fd843583          	ld	a1,-40(s0)
    800057de:	fe843503          	ld	a0,-24(s0)
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	49e080e7          	jalr	1182(ra) # 80004c80 <fileread>
    800057ea:	87aa                	mv	a5,a0
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	70a2                	ld	ra,40(sp)
    800057f0:	7402                	ld	s0,32(sp)
    800057f2:	6145                	addi	sp,sp,48
    800057f4:	8082                	ret

00000000800057f6 <sys_write>:
{
    800057f6:	7179                	addi	sp,sp,-48
    800057f8:	f406                	sd	ra,40(sp)
    800057fa:	f022                	sd	s0,32(sp)
    800057fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fe:	fe840613          	addi	a2,s0,-24
    80005802:	4581                	li	a1,0
    80005804:	4501                	li	a0,0
    80005806:	00000097          	auipc	ra,0x0
    8000580a:	d2a080e7          	jalr	-726(ra) # 80005530 <argfd>
    return -1;
    8000580e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005810:	04054163          	bltz	a0,80005852 <sys_write+0x5c>
    80005814:	fe440593          	addi	a1,s0,-28
    80005818:	4509                	li	a0,2
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	6d2080e7          	jalr	1746(ra) # 80002eec <argint>
    return -1;
    80005822:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005824:	02054763          	bltz	a0,80005852 <sys_write+0x5c>
    80005828:	fd840593          	addi	a1,s0,-40
    8000582c:	4505                	li	a0,1
    8000582e:	ffffd097          	auipc	ra,0xffffd
    80005832:	6e0080e7          	jalr	1760(ra) # 80002f0e <argaddr>
    return -1;
    80005836:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005838:	00054d63          	bltz	a0,80005852 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000583c:	fe442603          	lw	a2,-28(s0)
    80005840:	fd843583          	ld	a1,-40(s0)
    80005844:	fe843503          	ld	a0,-24(s0)
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	4fa080e7          	jalr	1274(ra) # 80004d42 <filewrite>
    80005850:	87aa                	mv	a5,a0
}
    80005852:	853e                	mv	a0,a5
    80005854:	70a2                	ld	ra,40(sp)
    80005856:	7402                	ld	s0,32(sp)
    80005858:	6145                	addi	sp,sp,48
    8000585a:	8082                	ret

000000008000585c <sys_close>:
{
    8000585c:	1101                	addi	sp,sp,-32
    8000585e:	ec06                	sd	ra,24(sp)
    80005860:	e822                	sd	s0,16(sp)
    80005862:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005864:	fe040613          	addi	a2,s0,-32
    80005868:	fec40593          	addi	a1,s0,-20
    8000586c:	4501                	li	a0,0
    8000586e:	00000097          	auipc	ra,0x0
    80005872:	cc2080e7          	jalr	-830(ra) # 80005530 <argfd>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005878:	02054463          	bltz	a0,800058a0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000587c:	ffffc097          	auipc	ra,0xffffc
    80005880:	280080e7          	jalr	640(ra) # 80001afc <myproc>
    80005884:	fec42783          	lw	a5,-20(s0)
    80005888:	07e9                	addi	a5,a5,26
    8000588a:	078e                	slli	a5,a5,0x3
    8000588c:	97aa                	add	a5,a5,a0
    8000588e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005892:	fe043503          	ld	a0,-32(s0)
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	2b0080e7          	jalr	688(ra) # 80004b46 <fileclose>
  return 0;
    8000589e:	4781                	li	a5,0
}
    800058a0:	853e                	mv	a0,a5
    800058a2:	60e2                	ld	ra,24(sp)
    800058a4:	6442                	ld	s0,16(sp)
    800058a6:	6105                	addi	sp,sp,32
    800058a8:	8082                	ret

00000000800058aa <sys_fstat>:
{
    800058aa:	1101                	addi	sp,sp,-32
    800058ac:	ec06                	sd	ra,24(sp)
    800058ae:	e822                	sd	s0,16(sp)
    800058b0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058b2:	fe840613          	addi	a2,s0,-24
    800058b6:	4581                	li	a1,0
    800058b8:	4501                	li	a0,0
    800058ba:	00000097          	auipc	ra,0x0
    800058be:	c76080e7          	jalr	-906(ra) # 80005530 <argfd>
    return -1;
    800058c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058c4:	02054563          	bltz	a0,800058ee <sys_fstat+0x44>
    800058c8:	fe040593          	addi	a1,s0,-32
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	640080e7          	jalr	1600(ra) # 80002f0e <argaddr>
    return -1;
    800058d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058d8:	00054b63          	bltz	a0,800058ee <sys_fstat+0x44>
  return filestat(f, st);
    800058dc:	fe043583          	ld	a1,-32(s0)
    800058e0:	fe843503          	ld	a0,-24(s0)
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	32a080e7          	jalr	810(ra) # 80004c0e <filestat>
    800058ec:	87aa                	mv	a5,a0
}
    800058ee:	853e                	mv	a0,a5
    800058f0:	60e2                	ld	ra,24(sp)
    800058f2:	6442                	ld	s0,16(sp)
    800058f4:	6105                	addi	sp,sp,32
    800058f6:	8082                	ret

00000000800058f8 <sys_link>:
{
    800058f8:	7169                	addi	sp,sp,-304
    800058fa:	f606                	sd	ra,296(sp)
    800058fc:	f222                	sd	s0,288(sp)
    800058fe:	ee26                	sd	s1,280(sp)
    80005900:	ea4a                	sd	s2,272(sp)
    80005902:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005904:	08000613          	li	a2,128
    80005908:	ed040593          	addi	a1,s0,-304
    8000590c:	4501                	li	a0,0
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	622080e7          	jalr	1570(ra) # 80002f30 <argstr>
    return -1;
    80005916:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005918:	10054e63          	bltz	a0,80005a34 <sys_link+0x13c>
    8000591c:	08000613          	li	a2,128
    80005920:	f5040593          	addi	a1,s0,-176
    80005924:	4505                	li	a0,1
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	60a080e7          	jalr	1546(ra) # 80002f30 <argstr>
    return -1;
    8000592e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005930:	10054263          	bltz	a0,80005a34 <sys_link+0x13c>
  begin_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	d46080e7          	jalr	-698(ra) # 8000467a <begin_op>
  if((ip = namei(old)) == 0){
    8000593c:	ed040513          	addi	a0,s0,-304
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	b1e080e7          	jalr	-1250(ra) # 8000445e <namei>
    80005948:	84aa                	mv	s1,a0
    8000594a:	c551                	beqz	a0,800059d6 <sys_link+0xde>
  ilock(ip);
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	35c080e7          	jalr	860(ra) # 80003ca8 <ilock>
  if(ip->type == T_DIR){
    80005954:	04449703          	lh	a4,68(s1)
    80005958:	4785                	li	a5,1
    8000595a:	08f70463          	beq	a4,a5,800059e2 <sys_link+0xea>
  ip->nlink++;
    8000595e:	04a4d783          	lhu	a5,74(s1)
    80005962:	2785                	addiw	a5,a5,1
    80005964:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	274080e7          	jalr	628(ra) # 80003bde <iupdate>
  iunlock(ip);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	3f6080e7          	jalr	1014(ra) # 80003d6a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000597c:	fd040593          	addi	a1,s0,-48
    80005980:	f5040513          	addi	a0,s0,-176
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	af8080e7          	jalr	-1288(ra) # 8000447c <nameiparent>
    8000598c:	892a                	mv	s2,a0
    8000598e:	c935                	beqz	a0,80005a02 <sys_link+0x10a>
  ilock(dp);
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	318080e7          	jalr	792(ra) # 80003ca8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005998:	00092703          	lw	a4,0(s2)
    8000599c:	409c                	lw	a5,0(s1)
    8000599e:	04f71d63          	bne	a4,a5,800059f8 <sys_link+0x100>
    800059a2:	40d0                	lw	a2,4(s1)
    800059a4:	fd040593          	addi	a1,s0,-48
    800059a8:	854a                	mv	a0,s2
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	9f2080e7          	jalr	-1550(ra) # 8000439c <dirlink>
    800059b2:	04054363          	bltz	a0,800059f8 <sys_link+0x100>
  iunlockput(dp);
    800059b6:	854a                	mv	a0,s2
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	552080e7          	jalr	1362(ra) # 80003f0a <iunlockput>
  iput(ip);
    800059c0:	8526                	mv	a0,s1
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	4a0080e7          	jalr	1184(ra) # 80003e62 <iput>
  end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	d30080e7          	jalr	-720(ra) # 800046fa <end_op>
  return 0;
    800059d2:	4781                	li	a5,0
    800059d4:	a085                	j	80005a34 <sys_link+0x13c>
    end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	d24080e7          	jalr	-732(ra) # 800046fa <end_op>
    return -1;
    800059de:	57fd                	li	a5,-1
    800059e0:	a891                	j	80005a34 <sys_link+0x13c>
    iunlockput(ip);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	526080e7          	jalr	1318(ra) # 80003f0a <iunlockput>
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	d0e080e7          	jalr	-754(ra) # 800046fa <end_op>
    return -1;
    800059f4:	57fd                	li	a5,-1
    800059f6:	a83d                	j	80005a34 <sys_link+0x13c>
    iunlockput(dp);
    800059f8:	854a                	mv	a0,s2
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	510080e7          	jalr	1296(ra) # 80003f0a <iunlockput>
  ilock(ip);
    80005a02:	8526                	mv	a0,s1
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	2a4080e7          	jalr	676(ra) # 80003ca8 <ilock>
  ip->nlink--;
    80005a0c:	04a4d783          	lhu	a5,74(s1)
    80005a10:	37fd                	addiw	a5,a5,-1
    80005a12:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a16:	8526                	mv	a0,s1
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	1c6080e7          	jalr	454(ra) # 80003bde <iupdate>
  iunlockput(ip);
    80005a20:	8526                	mv	a0,s1
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	4e8080e7          	jalr	1256(ra) # 80003f0a <iunlockput>
  end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	cd0080e7          	jalr	-816(ra) # 800046fa <end_op>
  return -1;
    80005a32:	57fd                	li	a5,-1
}
    80005a34:	853e                	mv	a0,a5
    80005a36:	70b2                	ld	ra,296(sp)
    80005a38:	7412                	ld	s0,288(sp)
    80005a3a:	64f2                	ld	s1,280(sp)
    80005a3c:	6952                	ld	s2,272(sp)
    80005a3e:	6155                	addi	sp,sp,304
    80005a40:	8082                	ret

0000000080005a42 <sys_unlink>:
{
    80005a42:	7151                	addi	sp,sp,-240
    80005a44:	f586                	sd	ra,232(sp)
    80005a46:	f1a2                	sd	s0,224(sp)
    80005a48:	eda6                	sd	s1,216(sp)
    80005a4a:	e9ca                	sd	s2,208(sp)
    80005a4c:	e5ce                	sd	s3,200(sp)
    80005a4e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a50:	08000613          	li	a2,128
    80005a54:	f3040593          	addi	a1,s0,-208
    80005a58:	4501                	li	a0,0
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	4d6080e7          	jalr	1238(ra) # 80002f30 <argstr>
    80005a62:	18054163          	bltz	a0,80005be4 <sys_unlink+0x1a2>
  begin_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	c14080e7          	jalr	-1004(ra) # 8000467a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a6e:	fb040593          	addi	a1,s0,-80
    80005a72:	f3040513          	addi	a0,s0,-208
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	a06080e7          	jalr	-1530(ra) # 8000447c <nameiparent>
    80005a7e:	84aa                	mv	s1,a0
    80005a80:	c979                	beqz	a0,80005b56 <sys_unlink+0x114>
  ilock(dp);
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	226080e7          	jalr	550(ra) # 80003ca8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a8a:	00003597          	auipc	a1,0x3
    80005a8e:	d9e58593          	addi	a1,a1,-610 # 80008828 <syscalls+0x2c0>
    80005a92:	fb040513          	addi	a0,s0,-80
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	6dc080e7          	jalr	1756(ra) # 80004172 <namecmp>
    80005a9e:	14050a63          	beqz	a0,80005bf2 <sys_unlink+0x1b0>
    80005aa2:	00003597          	auipc	a1,0x3
    80005aa6:	d8e58593          	addi	a1,a1,-626 # 80008830 <syscalls+0x2c8>
    80005aaa:	fb040513          	addi	a0,s0,-80
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	6c4080e7          	jalr	1732(ra) # 80004172 <namecmp>
    80005ab6:	12050e63          	beqz	a0,80005bf2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aba:	f2c40613          	addi	a2,s0,-212
    80005abe:	fb040593          	addi	a1,s0,-80
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	6c8080e7          	jalr	1736(ra) # 8000418c <dirlookup>
    80005acc:	892a                	mv	s2,a0
    80005ace:	12050263          	beqz	a0,80005bf2 <sys_unlink+0x1b0>
  ilock(ip);
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	1d6080e7          	jalr	470(ra) # 80003ca8 <ilock>
  if(ip->nlink < 1)
    80005ada:	04a91783          	lh	a5,74(s2)
    80005ade:	08f05263          	blez	a5,80005b62 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ae2:	04491703          	lh	a4,68(s2)
    80005ae6:	4785                	li	a5,1
    80005ae8:	08f70563          	beq	a4,a5,80005b72 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005aec:	4641                	li	a2,16
    80005aee:	4581                	li	a1,0
    80005af0:	fc040513          	addi	a0,s0,-64
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	1ec080e7          	jalr	492(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005afc:	4741                	li	a4,16
    80005afe:	f2c42683          	lw	a3,-212(s0)
    80005b02:	fc040613          	addi	a2,s0,-64
    80005b06:	4581                	li	a1,0
    80005b08:	8526                	mv	a0,s1
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	54a080e7          	jalr	1354(ra) # 80004054 <writei>
    80005b12:	47c1                	li	a5,16
    80005b14:	0af51563          	bne	a0,a5,80005bbe <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b18:	04491703          	lh	a4,68(s2)
    80005b1c:	4785                	li	a5,1
    80005b1e:	0af70863          	beq	a4,a5,80005bce <sys_unlink+0x18c>
  iunlockput(dp);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	3e6080e7          	jalr	998(ra) # 80003f0a <iunlockput>
  ip->nlink--;
    80005b2c:	04a95783          	lhu	a5,74(s2)
    80005b30:	37fd                	addiw	a5,a5,-1
    80005b32:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b36:	854a                	mv	a0,s2
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	0a6080e7          	jalr	166(ra) # 80003bde <iupdate>
  iunlockput(ip);
    80005b40:	854a                	mv	a0,s2
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	3c8080e7          	jalr	968(ra) # 80003f0a <iunlockput>
  end_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	bb0080e7          	jalr	-1104(ra) # 800046fa <end_op>
  return 0;
    80005b52:	4501                	li	a0,0
    80005b54:	a84d                	j	80005c06 <sys_unlink+0x1c4>
    end_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	ba4080e7          	jalr	-1116(ra) # 800046fa <end_op>
    return -1;
    80005b5e:	557d                	li	a0,-1
    80005b60:	a05d                	j	80005c06 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b62:	00003517          	auipc	a0,0x3
    80005b66:	cf650513          	addi	a0,a0,-778 # 80008858 <syscalls+0x2f0>
    80005b6a:	ffffb097          	auipc	ra,0xffffb
    80005b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b72:	04c92703          	lw	a4,76(s2)
    80005b76:	02000793          	li	a5,32
    80005b7a:	f6e7f9e3          	bgeu	a5,a4,80005aec <sys_unlink+0xaa>
    80005b7e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b82:	4741                	li	a4,16
    80005b84:	86ce                	mv	a3,s3
    80005b86:	f1840613          	addi	a2,s0,-232
    80005b8a:	4581                	li	a1,0
    80005b8c:	854a                	mv	a0,s2
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	3ce080e7          	jalr	974(ra) # 80003f5c <readi>
    80005b96:	47c1                	li	a5,16
    80005b98:	00f51b63          	bne	a0,a5,80005bae <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b9c:	f1845783          	lhu	a5,-232(s0)
    80005ba0:	e7a1                	bnez	a5,80005be8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ba2:	29c1                	addiw	s3,s3,16
    80005ba4:	04c92783          	lw	a5,76(s2)
    80005ba8:	fcf9ede3          	bltu	s3,a5,80005b82 <sys_unlink+0x140>
    80005bac:	b781                	j	80005aec <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005bae:	00003517          	auipc	a0,0x3
    80005bb2:	cc250513          	addi	a0,a0,-830 # 80008870 <syscalls+0x308>
    80005bb6:	ffffb097          	auipc	ra,0xffffb
    80005bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005bbe:	00003517          	auipc	a0,0x3
    80005bc2:	cca50513          	addi	a0,a0,-822 # 80008888 <syscalls+0x320>
    80005bc6:	ffffb097          	auipc	ra,0xffffb
    80005bca:	978080e7          	jalr	-1672(ra) # 8000053e <panic>
    dp->nlink--;
    80005bce:	04a4d783          	lhu	a5,74(s1)
    80005bd2:	37fd                	addiw	a5,a5,-1
    80005bd4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	004080e7          	jalr	4(ra) # 80003bde <iupdate>
    80005be2:	b781                	j	80005b22 <sys_unlink+0xe0>
    return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	a005                	j	80005c06 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005be8:	854a                	mv	a0,s2
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	320080e7          	jalr	800(ra) # 80003f0a <iunlockput>
  iunlockput(dp);
    80005bf2:	8526                	mv	a0,s1
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	316080e7          	jalr	790(ra) # 80003f0a <iunlockput>
  end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	afe080e7          	jalr	-1282(ra) # 800046fa <end_op>
  return -1;
    80005c04:	557d                	li	a0,-1
}
    80005c06:	70ae                	ld	ra,232(sp)
    80005c08:	740e                	ld	s0,224(sp)
    80005c0a:	64ee                	ld	s1,216(sp)
    80005c0c:	694e                	ld	s2,208(sp)
    80005c0e:	69ae                	ld	s3,200(sp)
    80005c10:	616d                	addi	sp,sp,240
    80005c12:	8082                	ret

0000000080005c14 <sys_open>:

uint64
sys_open(void)
{
    80005c14:	7131                	addi	sp,sp,-192
    80005c16:	fd06                	sd	ra,184(sp)
    80005c18:	f922                	sd	s0,176(sp)
    80005c1a:	f526                	sd	s1,168(sp)
    80005c1c:	f14a                	sd	s2,160(sp)
    80005c1e:	ed4e                	sd	s3,152(sp)
    80005c20:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c22:	08000613          	li	a2,128
    80005c26:	f5040593          	addi	a1,s0,-176
    80005c2a:	4501                	li	a0,0
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	304080e7          	jalr	772(ra) # 80002f30 <argstr>
    return -1;
    80005c34:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c36:	0c054163          	bltz	a0,80005cf8 <sys_open+0xe4>
    80005c3a:	f4c40593          	addi	a1,s0,-180
    80005c3e:	4505                	li	a0,1
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	2ac080e7          	jalr	684(ra) # 80002eec <argint>
    80005c48:	0a054863          	bltz	a0,80005cf8 <sys_open+0xe4>

  begin_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	a2e080e7          	jalr	-1490(ra) # 8000467a <begin_op>

  if(omode & O_CREATE){
    80005c54:	f4c42783          	lw	a5,-180(s0)
    80005c58:	2007f793          	andi	a5,a5,512
    80005c5c:	cbdd                	beqz	a5,80005d12 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c5e:	4681                	li	a3,0
    80005c60:	4601                	li	a2,0
    80005c62:	4589                	li	a1,2
    80005c64:	f5040513          	addi	a0,s0,-176
    80005c68:	00000097          	auipc	ra,0x0
    80005c6c:	972080e7          	jalr	-1678(ra) # 800055da <create>
    80005c70:	892a                	mv	s2,a0
    if(ip == 0){
    80005c72:	c959                	beqz	a0,80005d08 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c74:	04491703          	lh	a4,68(s2)
    80005c78:	478d                	li	a5,3
    80005c7a:	00f71763          	bne	a4,a5,80005c88 <sys_open+0x74>
    80005c7e:	04695703          	lhu	a4,70(s2)
    80005c82:	47a5                	li	a5,9
    80005c84:	0ce7ec63          	bltu	a5,a4,80005d5c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	e02080e7          	jalr	-510(ra) # 80004a8a <filealloc>
    80005c90:	89aa                	mv	s3,a0
    80005c92:	10050263          	beqz	a0,80005d96 <sys_open+0x182>
    80005c96:	00000097          	auipc	ra,0x0
    80005c9a:	902080e7          	jalr	-1790(ra) # 80005598 <fdalloc>
    80005c9e:	84aa                	mv	s1,a0
    80005ca0:	0e054663          	bltz	a0,80005d8c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ca4:	04491703          	lh	a4,68(s2)
    80005ca8:	478d                	li	a5,3
    80005caa:	0cf70463          	beq	a4,a5,80005d72 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005cae:	4789                	li	a5,2
    80005cb0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005cb4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cb8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cbc:	f4c42783          	lw	a5,-180(s0)
    80005cc0:	0017c713          	xori	a4,a5,1
    80005cc4:	8b05                	andi	a4,a4,1
    80005cc6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cca:	0037f713          	andi	a4,a5,3
    80005cce:	00e03733          	snez	a4,a4
    80005cd2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cd6:	4007f793          	andi	a5,a5,1024
    80005cda:	c791                	beqz	a5,80005ce6 <sys_open+0xd2>
    80005cdc:	04491703          	lh	a4,68(s2)
    80005ce0:	4789                	li	a5,2
    80005ce2:	08f70f63          	beq	a4,a5,80005d80 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ce6:	854a                	mv	a0,s2
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	082080e7          	jalr	130(ra) # 80003d6a <iunlock>
  end_op();
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	a0a080e7          	jalr	-1526(ra) # 800046fa <end_op>

  return fd;
}
    80005cf8:	8526                	mv	a0,s1
    80005cfa:	70ea                	ld	ra,184(sp)
    80005cfc:	744a                	ld	s0,176(sp)
    80005cfe:	74aa                	ld	s1,168(sp)
    80005d00:	790a                	ld	s2,160(sp)
    80005d02:	69ea                	ld	s3,152(sp)
    80005d04:	6129                	addi	sp,sp,192
    80005d06:	8082                	ret
      end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	9f2080e7          	jalr	-1550(ra) # 800046fa <end_op>
      return -1;
    80005d10:	b7e5                	j	80005cf8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d12:	f5040513          	addi	a0,s0,-176
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	748080e7          	jalr	1864(ra) # 8000445e <namei>
    80005d1e:	892a                	mv	s2,a0
    80005d20:	c905                	beqz	a0,80005d50 <sys_open+0x13c>
    ilock(ip);
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	f86080e7          	jalr	-122(ra) # 80003ca8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d2a:	04491703          	lh	a4,68(s2)
    80005d2e:	4785                	li	a5,1
    80005d30:	f4f712e3          	bne	a4,a5,80005c74 <sys_open+0x60>
    80005d34:	f4c42783          	lw	a5,-180(s0)
    80005d38:	dba1                	beqz	a5,80005c88 <sys_open+0x74>
      iunlockput(ip);
    80005d3a:	854a                	mv	a0,s2
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	1ce080e7          	jalr	462(ra) # 80003f0a <iunlockput>
      end_op();
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	9b6080e7          	jalr	-1610(ra) # 800046fa <end_op>
      return -1;
    80005d4c:	54fd                	li	s1,-1
    80005d4e:	b76d                	j	80005cf8 <sys_open+0xe4>
      end_op();
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	9aa080e7          	jalr	-1622(ra) # 800046fa <end_op>
      return -1;
    80005d58:	54fd                	li	s1,-1
    80005d5a:	bf79                	j	80005cf8 <sys_open+0xe4>
    iunlockput(ip);
    80005d5c:	854a                	mv	a0,s2
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	1ac080e7          	jalr	428(ra) # 80003f0a <iunlockput>
    end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	994080e7          	jalr	-1644(ra) # 800046fa <end_op>
    return -1;
    80005d6e:	54fd                	li	s1,-1
    80005d70:	b761                	j	80005cf8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d72:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d76:	04691783          	lh	a5,70(s2)
    80005d7a:	02f99223          	sh	a5,36(s3)
    80005d7e:	bf2d                	j	80005cb8 <sys_open+0xa4>
    itrunc(ip);
    80005d80:	854a                	mv	a0,s2
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	034080e7          	jalr	52(ra) # 80003db6 <itrunc>
    80005d8a:	bfb1                	j	80005ce6 <sys_open+0xd2>
      fileclose(f);
    80005d8c:	854e                	mv	a0,s3
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	db8080e7          	jalr	-584(ra) # 80004b46 <fileclose>
    iunlockput(ip);
    80005d96:	854a                	mv	a0,s2
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	172080e7          	jalr	370(ra) # 80003f0a <iunlockput>
    end_op();
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	95a080e7          	jalr	-1702(ra) # 800046fa <end_op>
    return -1;
    80005da8:	54fd                	li	s1,-1
    80005daa:	b7b9                	j	80005cf8 <sys_open+0xe4>

0000000080005dac <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005dac:	7175                	addi	sp,sp,-144
    80005dae:	e506                	sd	ra,136(sp)
    80005db0:	e122                	sd	s0,128(sp)
    80005db2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	8c6080e7          	jalr	-1850(ra) # 8000467a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005dbc:	08000613          	li	a2,128
    80005dc0:	f7040593          	addi	a1,s0,-144
    80005dc4:	4501                	li	a0,0
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	16a080e7          	jalr	362(ra) # 80002f30 <argstr>
    80005dce:	02054963          	bltz	a0,80005e00 <sys_mkdir+0x54>
    80005dd2:	4681                	li	a3,0
    80005dd4:	4601                	li	a2,0
    80005dd6:	4585                	li	a1,1
    80005dd8:	f7040513          	addi	a0,s0,-144
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	7fe080e7          	jalr	2046(ra) # 800055da <create>
    80005de4:	cd11                	beqz	a0,80005e00 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	124080e7          	jalr	292(ra) # 80003f0a <iunlockput>
  end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	90c080e7          	jalr	-1780(ra) # 800046fa <end_op>
  return 0;
    80005df6:	4501                	li	a0,0
}
    80005df8:	60aa                	ld	ra,136(sp)
    80005dfa:	640a                	ld	s0,128(sp)
    80005dfc:	6149                	addi	sp,sp,144
    80005dfe:	8082                	ret
    end_op();
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	8fa080e7          	jalr	-1798(ra) # 800046fa <end_op>
    return -1;
    80005e08:	557d                	li	a0,-1
    80005e0a:	b7fd                	j	80005df8 <sys_mkdir+0x4c>

0000000080005e0c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e0c:	7135                	addi	sp,sp,-160
    80005e0e:	ed06                	sd	ra,152(sp)
    80005e10:	e922                	sd	s0,144(sp)
    80005e12:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	866080e7          	jalr	-1946(ra) # 8000467a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e1c:	08000613          	li	a2,128
    80005e20:	f7040593          	addi	a1,s0,-144
    80005e24:	4501                	li	a0,0
    80005e26:	ffffd097          	auipc	ra,0xffffd
    80005e2a:	10a080e7          	jalr	266(ra) # 80002f30 <argstr>
    80005e2e:	04054a63          	bltz	a0,80005e82 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e32:	f6c40593          	addi	a1,s0,-148
    80005e36:	4505                	li	a0,1
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	0b4080e7          	jalr	180(ra) # 80002eec <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e40:	04054163          	bltz	a0,80005e82 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e44:	f6840593          	addi	a1,s0,-152
    80005e48:	4509                	li	a0,2
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	0a2080e7          	jalr	162(ra) # 80002eec <argint>
     argint(1, &major) < 0 ||
    80005e52:	02054863          	bltz	a0,80005e82 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e56:	f6841683          	lh	a3,-152(s0)
    80005e5a:	f6c41603          	lh	a2,-148(s0)
    80005e5e:	458d                	li	a1,3
    80005e60:	f7040513          	addi	a0,s0,-144
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	776080e7          	jalr	1910(ra) # 800055da <create>
     argint(2, &minor) < 0 ||
    80005e6c:	c919                	beqz	a0,80005e82 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	09c080e7          	jalr	156(ra) # 80003f0a <iunlockput>
  end_op();
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	884080e7          	jalr	-1916(ra) # 800046fa <end_op>
  return 0;
    80005e7e:	4501                	li	a0,0
    80005e80:	a031                	j	80005e8c <sys_mknod+0x80>
    end_op();
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	878080e7          	jalr	-1928(ra) # 800046fa <end_op>
    return -1;
    80005e8a:	557d                	li	a0,-1
}
    80005e8c:	60ea                	ld	ra,152(sp)
    80005e8e:	644a                	ld	s0,144(sp)
    80005e90:	610d                	addi	sp,sp,160
    80005e92:	8082                	ret

0000000080005e94 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e94:	7135                	addi	sp,sp,-160
    80005e96:	ed06                	sd	ra,152(sp)
    80005e98:	e922                	sd	s0,144(sp)
    80005e9a:	e526                	sd	s1,136(sp)
    80005e9c:	e14a                	sd	s2,128(sp)
    80005e9e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	c5c080e7          	jalr	-932(ra) # 80001afc <myproc>
    80005ea8:	892a                	mv	s2,a0
  
  begin_op();
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	7d0080e7          	jalr	2000(ra) # 8000467a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005eb2:	08000613          	li	a2,128
    80005eb6:	f6040593          	addi	a1,s0,-160
    80005eba:	4501                	li	a0,0
    80005ebc:	ffffd097          	auipc	ra,0xffffd
    80005ec0:	074080e7          	jalr	116(ra) # 80002f30 <argstr>
    80005ec4:	04054b63          	bltz	a0,80005f1a <sys_chdir+0x86>
    80005ec8:	f6040513          	addi	a0,s0,-160
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	592080e7          	jalr	1426(ra) # 8000445e <namei>
    80005ed4:	84aa                	mv	s1,a0
    80005ed6:	c131                	beqz	a0,80005f1a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	dd0080e7          	jalr	-560(ra) # 80003ca8 <ilock>
  if(ip->type != T_DIR){
    80005ee0:	04449703          	lh	a4,68(s1)
    80005ee4:	4785                	li	a5,1
    80005ee6:	04f71063          	bne	a4,a5,80005f26 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005eea:	8526                	mv	a0,s1
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	e7e080e7          	jalr	-386(ra) # 80003d6a <iunlock>
  iput(p->cwd);
    80005ef4:	15093503          	ld	a0,336(s2)
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	f6a080e7          	jalr	-150(ra) # 80003e62 <iput>
  end_op();
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	7fa080e7          	jalr	2042(ra) # 800046fa <end_op>
  p->cwd = ip;
    80005f08:	14993823          	sd	s1,336(s2)
  return 0;
    80005f0c:	4501                	li	a0,0
}
    80005f0e:	60ea                	ld	ra,152(sp)
    80005f10:	644a                	ld	s0,144(sp)
    80005f12:	64aa                	ld	s1,136(sp)
    80005f14:	690a                	ld	s2,128(sp)
    80005f16:	610d                	addi	sp,sp,160
    80005f18:	8082                	ret
    end_op();
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	7e0080e7          	jalr	2016(ra) # 800046fa <end_op>
    return -1;
    80005f22:	557d                	li	a0,-1
    80005f24:	b7ed                	j	80005f0e <sys_chdir+0x7a>
    iunlockput(ip);
    80005f26:	8526                	mv	a0,s1
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	fe2080e7          	jalr	-30(ra) # 80003f0a <iunlockput>
    end_op();
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	7ca080e7          	jalr	1994(ra) # 800046fa <end_op>
    return -1;
    80005f38:	557d                	li	a0,-1
    80005f3a:	bfd1                	j	80005f0e <sys_chdir+0x7a>

0000000080005f3c <sys_exec>:

uint64
sys_exec(void)
{
    80005f3c:	7145                	addi	sp,sp,-464
    80005f3e:	e786                	sd	ra,456(sp)
    80005f40:	e3a2                	sd	s0,448(sp)
    80005f42:	ff26                	sd	s1,440(sp)
    80005f44:	fb4a                	sd	s2,432(sp)
    80005f46:	f74e                	sd	s3,424(sp)
    80005f48:	f352                	sd	s4,416(sp)
    80005f4a:	ef56                	sd	s5,408(sp)
    80005f4c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f4e:	08000613          	li	a2,128
    80005f52:	f4040593          	addi	a1,s0,-192
    80005f56:	4501                	li	a0,0
    80005f58:	ffffd097          	auipc	ra,0xffffd
    80005f5c:	fd8080e7          	jalr	-40(ra) # 80002f30 <argstr>
    return -1;
    80005f60:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f62:	0c054a63          	bltz	a0,80006036 <sys_exec+0xfa>
    80005f66:	e3840593          	addi	a1,s0,-456
    80005f6a:	4505                	li	a0,1
    80005f6c:	ffffd097          	auipc	ra,0xffffd
    80005f70:	fa2080e7          	jalr	-94(ra) # 80002f0e <argaddr>
    80005f74:	0c054163          	bltz	a0,80006036 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f78:	10000613          	li	a2,256
    80005f7c:	4581                	li	a1,0
    80005f7e:	e4040513          	addi	a0,s0,-448
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	d5e080e7          	jalr	-674(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f8a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f8e:	89a6                	mv	s3,s1
    80005f90:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f92:	02000a13          	li	s4,32
    80005f96:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f9a:	00391513          	slli	a0,s2,0x3
    80005f9e:	e3040593          	addi	a1,s0,-464
    80005fa2:	e3843783          	ld	a5,-456(s0)
    80005fa6:	953e                	add	a0,a0,a5
    80005fa8:	ffffd097          	auipc	ra,0xffffd
    80005fac:	eaa080e7          	jalr	-342(ra) # 80002e52 <fetchaddr>
    80005fb0:	02054a63          	bltz	a0,80005fe4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005fb4:	e3043783          	ld	a5,-464(s0)
    80005fb8:	c3b9                	beqz	a5,80005ffe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	b3a080e7          	jalr	-1222(ra) # 80000af4 <kalloc>
    80005fc2:	85aa                	mv	a1,a0
    80005fc4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fc8:	cd11                	beqz	a0,80005fe4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fca:	6605                	lui	a2,0x1
    80005fcc:	e3043503          	ld	a0,-464(s0)
    80005fd0:	ffffd097          	auipc	ra,0xffffd
    80005fd4:	ed4080e7          	jalr	-300(ra) # 80002ea4 <fetchstr>
    80005fd8:	00054663          	bltz	a0,80005fe4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fdc:	0905                	addi	s2,s2,1
    80005fde:	09a1                	addi	s3,s3,8
    80005fe0:	fb491be3          	bne	s2,s4,80005f96 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe4:	10048913          	addi	s2,s1,256
    80005fe8:	6088                	ld	a0,0(s1)
    80005fea:	c529                	beqz	a0,80006034 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	a0c080e7          	jalr	-1524(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ff4:	04a1                	addi	s1,s1,8
    80005ff6:	ff2499e3          	bne	s1,s2,80005fe8 <sys_exec+0xac>
  return -1;
    80005ffa:	597d                	li	s2,-1
    80005ffc:	a82d                	j	80006036 <sys_exec+0xfa>
      argv[i] = 0;
    80005ffe:	0a8e                	slli	s5,s5,0x3
    80006000:	fc040793          	addi	a5,s0,-64
    80006004:	9abe                	add	s5,s5,a5
    80006006:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000600a:	e4040593          	addi	a1,s0,-448
    8000600e:	f4040513          	addi	a0,s0,-192
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	194080e7          	jalr	404(ra) # 800051a6 <exec>
    8000601a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000601c:	10048993          	addi	s3,s1,256
    80006020:	6088                	ld	a0,0(s1)
    80006022:	c911                	beqz	a0,80006036 <sys_exec+0xfa>
    kfree(argv[i]);
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	9d4080e7          	jalr	-1580(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000602c:	04a1                	addi	s1,s1,8
    8000602e:	ff3499e3          	bne	s1,s3,80006020 <sys_exec+0xe4>
    80006032:	a011                	j	80006036 <sys_exec+0xfa>
  return -1;
    80006034:	597d                	li	s2,-1
}
    80006036:	854a                	mv	a0,s2
    80006038:	60be                	ld	ra,456(sp)
    8000603a:	641e                	ld	s0,448(sp)
    8000603c:	74fa                	ld	s1,440(sp)
    8000603e:	795a                	ld	s2,432(sp)
    80006040:	79ba                	ld	s3,424(sp)
    80006042:	7a1a                	ld	s4,416(sp)
    80006044:	6afa                	ld	s5,408(sp)
    80006046:	6179                	addi	sp,sp,464
    80006048:	8082                	ret

000000008000604a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000604a:	7139                	addi	sp,sp,-64
    8000604c:	fc06                	sd	ra,56(sp)
    8000604e:	f822                	sd	s0,48(sp)
    80006050:	f426                	sd	s1,40(sp)
    80006052:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006054:	ffffc097          	auipc	ra,0xffffc
    80006058:	aa8080e7          	jalr	-1368(ra) # 80001afc <myproc>
    8000605c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000605e:	fd840593          	addi	a1,s0,-40
    80006062:	4501                	li	a0,0
    80006064:	ffffd097          	auipc	ra,0xffffd
    80006068:	eaa080e7          	jalr	-342(ra) # 80002f0e <argaddr>
    return -1;
    8000606c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000606e:	0e054063          	bltz	a0,8000614e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006072:	fc840593          	addi	a1,s0,-56
    80006076:	fd040513          	addi	a0,s0,-48
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	dfc080e7          	jalr	-516(ra) # 80004e76 <pipealloc>
    return -1;
    80006082:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006084:	0c054563          	bltz	a0,8000614e <sys_pipe+0x104>
  fd0 = -1;
    80006088:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000608c:	fd043503          	ld	a0,-48(s0)
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	508080e7          	jalr	1288(ra) # 80005598 <fdalloc>
    80006098:	fca42223          	sw	a0,-60(s0)
    8000609c:	08054c63          	bltz	a0,80006134 <sys_pipe+0xea>
    800060a0:	fc843503          	ld	a0,-56(s0)
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	4f4080e7          	jalr	1268(ra) # 80005598 <fdalloc>
    800060ac:	fca42023          	sw	a0,-64(s0)
    800060b0:	06054863          	bltz	a0,80006120 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060b4:	4691                	li	a3,4
    800060b6:	fc440613          	addi	a2,s0,-60
    800060ba:	fd843583          	ld	a1,-40(s0)
    800060be:	68a8                	ld	a0,80(s1)
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	5ba080e7          	jalr	1466(ra) # 8000167a <copyout>
    800060c8:	02054063          	bltz	a0,800060e8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060cc:	4691                	li	a3,4
    800060ce:	fc040613          	addi	a2,s0,-64
    800060d2:	fd843583          	ld	a1,-40(s0)
    800060d6:	0591                	addi	a1,a1,4
    800060d8:	68a8                	ld	a0,80(s1)
    800060da:	ffffb097          	auipc	ra,0xffffb
    800060de:	5a0080e7          	jalr	1440(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060e2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060e4:	06055563          	bgez	a0,8000614e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060e8:	fc442783          	lw	a5,-60(s0)
    800060ec:	07e9                	addi	a5,a5,26
    800060ee:	078e                	slli	a5,a5,0x3
    800060f0:	97a6                	add	a5,a5,s1
    800060f2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060f6:	fc042503          	lw	a0,-64(s0)
    800060fa:	0569                	addi	a0,a0,26
    800060fc:	050e                	slli	a0,a0,0x3
    800060fe:	9526                	add	a0,a0,s1
    80006100:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006104:	fd043503          	ld	a0,-48(s0)
    80006108:	fffff097          	auipc	ra,0xfffff
    8000610c:	a3e080e7          	jalr	-1474(ra) # 80004b46 <fileclose>
    fileclose(wf);
    80006110:	fc843503          	ld	a0,-56(s0)
    80006114:	fffff097          	auipc	ra,0xfffff
    80006118:	a32080e7          	jalr	-1486(ra) # 80004b46 <fileclose>
    return -1;
    8000611c:	57fd                	li	a5,-1
    8000611e:	a805                	j	8000614e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006120:	fc442783          	lw	a5,-60(s0)
    80006124:	0007c863          	bltz	a5,80006134 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006128:	01a78513          	addi	a0,a5,26
    8000612c:	050e                	slli	a0,a0,0x3
    8000612e:	9526                	add	a0,a0,s1
    80006130:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006134:	fd043503          	ld	a0,-48(s0)
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	a0e080e7          	jalr	-1522(ra) # 80004b46 <fileclose>
    fileclose(wf);
    80006140:	fc843503          	ld	a0,-56(s0)
    80006144:	fffff097          	auipc	ra,0xfffff
    80006148:	a02080e7          	jalr	-1534(ra) # 80004b46 <fileclose>
    return -1;
    8000614c:	57fd                	li	a5,-1
}
    8000614e:	853e                	mv	a0,a5
    80006150:	70e2                	ld	ra,56(sp)
    80006152:	7442                	ld	s0,48(sp)
    80006154:	74a2                	ld	s1,40(sp)
    80006156:	6121                	addi	sp,sp,64
    80006158:	8082                	ret
    8000615a:	0000                	unimp
    8000615c:	0000                	unimp
	...

0000000080006160 <kernelvec>:
    80006160:	7111                	addi	sp,sp,-256
    80006162:	e006                	sd	ra,0(sp)
    80006164:	e40a                	sd	sp,8(sp)
    80006166:	e80e                	sd	gp,16(sp)
    80006168:	ec12                	sd	tp,24(sp)
    8000616a:	f016                	sd	t0,32(sp)
    8000616c:	f41a                	sd	t1,40(sp)
    8000616e:	f81e                	sd	t2,48(sp)
    80006170:	fc22                	sd	s0,56(sp)
    80006172:	e0a6                	sd	s1,64(sp)
    80006174:	e4aa                	sd	a0,72(sp)
    80006176:	e8ae                	sd	a1,80(sp)
    80006178:	ecb2                	sd	a2,88(sp)
    8000617a:	f0b6                	sd	a3,96(sp)
    8000617c:	f4ba                	sd	a4,104(sp)
    8000617e:	f8be                	sd	a5,112(sp)
    80006180:	fcc2                	sd	a6,120(sp)
    80006182:	e146                	sd	a7,128(sp)
    80006184:	e54a                	sd	s2,136(sp)
    80006186:	e94e                	sd	s3,144(sp)
    80006188:	ed52                	sd	s4,152(sp)
    8000618a:	f156                	sd	s5,160(sp)
    8000618c:	f55a                	sd	s6,168(sp)
    8000618e:	f95e                	sd	s7,176(sp)
    80006190:	fd62                	sd	s8,184(sp)
    80006192:	e1e6                	sd	s9,192(sp)
    80006194:	e5ea                	sd	s10,200(sp)
    80006196:	e9ee                	sd	s11,208(sp)
    80006198:	edf2                	sd	t3,216(sp)
    8000619a:	f1f6                	sd	t4,224(sp)
    8000619c:	f5fa                	sd	t5,232(sp)
    8000619e:	f9fe                	sd	t6,240(sp)
    800061a0:	b7ffc0ef          	jal	ra,80002d1e <kerneltrap>
    800061a4:	6082                	ld	ra,0(sp)
    800061a6:	6122                	ld	sp,8(sp)
    800061a8:	61c2                	ld	gp,16(sp)
    800061aa:	7282                	ld	t0,32(sp)
    800061ac:	7322                	ld	t1,40(sp)
    800061ae:	73c2                	ld	t2,48(sp)
    800061b0:	7462                	ld	s0,56(sp)
    800061b2:	6486                	ld	s1,64(sp)
    800061b4:	6526                	ld	a0,72(sp)
    800061b6:	65c6                	ld	a1,80(sp)
    800061b8:	6666                	ld	a2,88(sp)
    800061ba:	7686                	ld	a3,96(sp)
    800061bc:	7726                	ld	a4,104(sp)
    800061be:	77c6                	ld	a5,112(sp)
    800061c0:	7866                	ld	a6,120(sp)
    800061c2:	688a                	ld	a7,128(sp)
    800061c4:	692a                	ld	s2,136(sp)
    800061c6:	69ca                	ld	s3,144(sp)
    800061c8:	6a6a                	ld	s4,152(sp)
    800061ca:	7a8a                	ld	s5,160(sp)
    800061cc:	7b2a                	ld	s6,168(sp)
    800061ce:	7bca                	ld	s7,176(sp)
    800061d0:	7c6a                	ld	s8,184(sp)
    800061d2:	6c8e                	ld	s9,192(sp)
    800061d4:	6d2e                	ld	s10,200(sp)
    800061d6:	6dce                	ld	s11,208(sp)
    800061d8:	6e6e                	ld	t3,216(sp)
    800061da:	7e8e                	ld	t4,224(sp)
    800061dc:	7f2e                	ld	t5,232(sp)
    800061de:	7fce                	ld	t6,240(sp)
    800061e0:	6111                	addi	sp,sp,256
    800061e2:	10200073          	sret
    800061e6:	00000013          	nop
    800061ea:	00000013          	nop
    800061ee:	0001                	nop

00000000800061f0 <timervec>:
    800061f0:	34051573          	csrrw	a0,mscratch,a0
    800061f4:	e10c                	sd	a1,0(a0)
    800061f6:	e510                	sd	a2,8(a0)
    800061f8:	e914                	sd	a3,16(a0)
    800061fa:	6d0c                	ld	a1,24(a0)
    800061fc:	7110                	ld	a2,32(a0)
    800061fe:	6194                	ld	a3,0(a1)
    80006200:	96b2                	add	a3,a3,a2
    80006202:	e194                	sd	a3,0(a1)
    80006204:	4589                	li	a1,2
    80006206:	14459073          	csrw	sip,a1
    8000620a:	6914                	ld	a3,16(a0)
    8000620c:	6510                	ld	a2,8(a0)
    8000620e:	610c                	ld	a1,0(a0)
    80006210:	34051573          	csrrw	a0,mscratch,a0
    80006214:	30200073          	mret
	...

000000008000621a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000621a:	1141                	addi	sp,sp,-16
    8000621c:	e422                	sd	s0,8(sp)
    8000621e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006220:	0c0007b7          	lui	a5,0xc000
    80006224:	4705                	li	a4,1
    80006226:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006228:	c3d8                	sw	a4,4(a5)
}
    8000622a:	6422                	ld	s0,8(sp)
    8000622c:	0141                	addi	sp,sp,16
    8000622e:	8082                	ret

0000000080006230 <plicinithart>:

void
plicinithart(void)
{
    80006230:	1141                	addi	sp,sp,-16
    80006232:	e406                	sd	ra,8(sp)
    80006234:	e022                	sd	s0,0(sp)
    80006236:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006238:	ffffc097          	auipc	ra,0xffffc
    8000623c:	898080e7          	jalr	-1896(ra) # 80001ad0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006240:	0085171b          	slliw	a4,a0,0x8
    80006244:	0c0027b7          	lui	a5,0xc002
    80006248:	97ba                	add	a5,a5,a4
    8000624a:	40200713          	li	a4,1026
    8000624e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006252:	00d5151b          	slliw	a0,a0,0xd
    80006256:	0c2017b7          	lui	a5,0xc201
    8000625a:	953e                	add	a0,a0,a5
    8000625c:	00052023          	sw	zero,0(a0)
}
    80006260:	60a2                	ld	ra,8(sp)
    80006262:	6402                	ld	s0,0(sp)
    80006264:	0141                	addi	sp,sp,16
    80006266:	8082                	ret

0000000080006268 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006268:	1141                	addi	sp,sp,-16
    8000626a:	e406                	sd	ra,8(sp)
    8000626c:	e022                	sd	s0,0(sp)
    8000626e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006270:	ffffc097          	auipc	ra,0xffffc
    80006274:	860080e7          	jalr	-1952(ra) # 80001ad0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006278:	00d5179b          	slliw	a5,a0,0xd
    8000627c:	0c201537          	lui	a0,0xc201
    80006280:	953e                	add	a0,a0,a5
  return irq;
}
    80006282:	4148                	lw	a0,4(a0)
    80006284:	60a2                	ld	ra,8(sp)
    80006286:	6402                	ld	s0,0(sp)
    80006288:	0141                	addi	sp,sp,16
    8000628a:	8082                	ret

000000008000628c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000628c:	1101                	addi	sp,sp,-32
    8000628e:	ec06                	sd	ra,24(sp)
    80006290:	e822                	sd	s0,16(sp)
    80006292:	e426                	sd	s1,8(sp)
    80006294:	1000                	addi	s0,sp,32
    80006296:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006298:	ffffc097          	auipc	ra,0xffffc
    8000629c:	838080e7          	jalr	-1992(ra) # 80001ad0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062a0:	00d5151b          	slliw	a0,a0,0xd
    800062a4:	0c2017b7          	lui	a5,0xc201
    800062a8:	97aa                	add	a5,a5,a0
    800062aa:	c3c4                	sw	s1,4(a5)
}
    800062ac:	60e2                	ld	ra,24(sp)
    800062ae:	6442                	ld	s0,16(sp)
    800062b0:	64a2                	ld	s1,8(sp)
    800062b2:	6105                	addi	sp,sp,32
    800062b4:	8082                	ret

00000000800062b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062b6:	1141                	addi	sp,sp,-16
    800062b8:	e406                	sd	ra,8(sp)
    800062ba:	e022                	sd	s0,0(sp)
    800062bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062be:	479d                	li	a5,7
    800062c0:	06a7c963          	blt	a5,a0,80006332 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062c4:	0001f797          	auipc	a5,0x1f
    800062c8:	d3c78793          	addi	a5,a5,-708 # 80025000 <disk>
    800062cc:	00a78733          	add	a4,a5,a0
    800062d0:	6789                	lui	a5,0x2
    800062d2:	97ba                	add	a5,a5,a4
    800062d4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062d8:	e7ad                	bnez	a5,80006342 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062da:	00451793          	slli	a5,a0,0x4
    800062de:	00021717          	auipc	a4,0x21
    800062e2:	d2270713          	addi	a4,a4,-734 # 80027000 <disk+0x2000>
    800062e6:	6314                	ld	a3,0(a4)
    800062e8:	96be                	add	a3,a3,a5
    800062ea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062ee:	6314                	ld	a3,0(a4)
    800062f0:	96be                	add	a3,a3,a5
    800062f2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062f6:	6314                	ld	a3,0(a4)
    800062f8:	96be                	add	a3,a3,a5
    800062fa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062fe:	6318                	ld	a4,0(a4)
    80006300:	97ba                	add	a5,a5,a4
    80006302:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006306:	0001f797          	auipc	a5,0x1f
    8000630a:	cfa78793          	addi	a5,a5,-774 # 80025000 <disk>
    8000630e:	97aa                	add	a5,a5,a0
    80006310:	6509                	lui	a0,0x2
    80006312:	953e                	add	a0,a0,a5
    80006314:	4785                	li	a5,1
    80006316:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000631a:	00021517          	auipc	a0,0x21
    8000631e:	cfe50513          	addi	a0,a0,-770 # 80027018 <disk+0x2018>
    80006322:	ffffc097          	auipc	ra,0xffffc
    80006326:	2a6080e7          	jalr	678(ra) # 800025c8 <wakeup>
}
    8000632a:	60a2                	ld	ra,8(sp)
    8000632c:	6402                	ld	s0,0(sp)
    8000632e:	0141                	addi	sp,sp,16
    80006330:	8082                	ret
    panic("free_desc 1");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	56650513          	addi	a0,a0,1382 # 80008898 <syscalls+0x330>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	204080e7          	jalr	516(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	56650513          	addi	a0,a0,1382 # 800088a8 <syscalls+0x340>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>

0000000080006352 <virtio_disk_init>:
{
    80006352:	1101                	addi	sp,sp,-32
    80006354:	ec06                	sd	ra,24(sp)
    80006356:	e822                	sd	s0,16(sp)
    80006358:	e426                	sd	s1,8(sp)
    8000635a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000635c:	00002597          	auipc	a1,0x2
    80006360:	55c58593          	addi	a1,a1,1372 # 800088b8 <syscalls+0x350>
    80006364:	00021517          	auipc	a0,0x21
    80006368:	dc450513          	addi	a0,a0,-572 # 80027128 <disk+0x2128>
    8000636c:	ffffa097          	auipc	ra,0xffffa
    80006370:	7e8080e7          	jalr	2024(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006374:	100017b7          	lui	a5,0x10001
    80006378:	4398                	lw	a4,0(a5)
    8000637a:	2701                	sext.w	a4,a4
    8000637c:	747277b7          	lui	a5,0x74727
    80006380:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006384:	0ef71163          	bne	a4,a5,80006466 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006388:	100017b7          	lui	a5,0x10001
    8000638c:	43dc                	lw	a5,4(a5)
    8000638e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006390:	4705                	li	a4,1
    80006392:	0ce79a63          	bne	a5,a4,80006466 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006396:	100017b7          	lui	a5,0x10001
    8000639a:	479c                	lw	a5,8(a5)
    8000639c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000639e:	4709                	li	a4,2
    800063a0:	0ce79363          	bne	a5,a4,80006466 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063a4:	100017b7          	lui	a5,0x10001
    800063a8:	47d8                	lw	a4,12(a5)
    800063aa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063ac:	554d47b7          	lui	a5,0x554d4
    800063b0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063b4:	0af71963          	bne	a4,a5,80006466 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b8:	100017b7          	lui	a5,0x10001
    800063bc:	4705                	li	a4,1
    800063be:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c0:	470d                	li	a4,3
    800063c2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063c4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063c6:	c7ffe737          	lui	a4,0xc7ffe
    800063ca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    800063ce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063d0:	2701                	sext.w	a4,a4
    800063d2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d4:	472d                	li	a4,11
    800063d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d8:	473d                	li	a4,15
    800063da:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063dc:	6705                	lui	a4,0x1
    800063de:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063e4:	5bdc                	lw	a5,52(a5)
    800063e6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063e8:	c7d9                	beqz	a5,80006476 <virtio_disk_init+0x124>
  if(max < NUM)
    800063ea:	471d                	li	a4,7
    800063ec:	08f77d63          	bgeu	a4,a5,80006486 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063f0:	100014b7          	lui	s1,0x10001
    800063f4:	47a1                	li	a5,8
    800063f6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063f8:	6609                	lui	a2,0x2
    800063fa:	4581                	li	a1,0
    800063fc:	0001f517          	auipc	a0,0x1f
    80006400:	c0450513          	addi	a0,a0,-1020 # 80025000 <disk>
    80006404:	ffffb097          	auipc	ra,0xffffb
    80006408:	8dc080e7          	jalr	-1828(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000640c:	0001f717          	auipc	a4,0x1f
    80006410:	bf470713          	addi	a4,a4,-1036 # 80025000 <disk>
    80006414:	00c75793          	srli	a5,a4,0xc
    80006418:	2781                	sext.w	a5,a5
    8000641a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000641c:	00021797          	auipc	a5,0x21
    80006420:	be478793          	addi	a5,a5,-1052 # 80027000 <disk+0x2000>
    80006424:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006426:	0001f717          	auipc	a4,0x1f
    8000642a:	c5a70713          	addi	a4,a4,-934 # 80025080 <disk+0x80>
    8000642e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006430:	00020717          	auipc	a4,0x20
    80006434:	bd070713          	addi	a4,a4,-1072 # 80026000 <disk+0x1000>
    80006438:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000643a:	4705                	li	a4,1
    8000643c:	00e78c23          	sb	a4,24(a5)
    80006440:	00e78ca3          	sb	a4,25(a5)
    80006444:	00e78d23          	sb	a4,26(a5)
    80006448:	00e78da3          	sb	a4,27(a5)
    8000644c:	00e78e23          	sb	a4,28(a5)
    80006450:	00e78ea3          	sb	a4,29(a5)
    80006454:	00e78f23          	sb	a4,30(a5)
    80006458:	00e78fa3          	sb	a4,31(a5)
}
    8000645c:	60e2                	ld	ra,24(sp)
    8000645e:	6442                	ld	s0,16(sp)
    80006460:	64a2                	ld	s1,8(sp)
    80006462:	6105                	addi	sp,sp,32
    80006464:	8082                	ret
    panic("could not find virtio disk");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	46250513          	addi	a0,a0,1122 # 800088c8 <syscalls+0x360>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006476:	00002517          	auipc	a0,0x2
    8000647a:	47250513          	addi	a0,a0,1138 # 800088e8 <syscalls+0x380>
    8000647e:	ffffa097          	auipc	ra,0xffffa
    80006482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006486:	00002517          	auipc	a0,0x2
    8000648a:	48250513          	addi	a0,a0,1154 # 80008908 <syscalls+0x3a0>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>

0000000080006496 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006496:	7159                	addi	sp,sp,-112
    80006498:	f486                	sd	ra,104(sp)
    8000649a:	f0a2                	sd	s0,96(sp)
    8000649c:	eca6                	sd	s1,88(sp)
    8000649e:	e8ca                	sd	s2,80(sp)
    800064a0:	e4ce                	sd	s3,72(sp)
    800064a2:	e0d2                	sd	s4,64(sp)
    800064a4:	fc56                	sd	s5,56(sp)
    800064a6:	f85a                	sd	s6,48(sp)
    800064a8:	f45e                	sd	s7,40(sp)
    800064aa:	f062                	sd	s8,32(sp)
    800064ac:	ec66                	sd	s9,24(sp)
    800064ae:	e86a                	sd	s10,16(sp)
    800064b0:	1880                	addi	s0,sp,112
    800064b2:	892a                	mv	s2,a0
    800064b4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064b6:	00c52c83          	lw	s9,12(a0)
    800064ba:	001c9c9b          	slliw	s9,s9,0x1
    800064be:	1c82                	slli	s9,s9,0x20
    800064c0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064c4:	00021517          	auipc	a0,0x21
    800064c8:	c6450513          	addi	a0,a0,-924 # 80027128 <disk+0x2128>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	718080e7          	jalr	1816(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064d4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064d6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064d8:	0001fb97          	auipc	s7,0x1f
    800064dc:	b28b8b93          	addi	s7,s7,-1240 # 80025000 <disk>
    800064e0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064e2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064e4:	8a4e                	mv	s4,s3
    800064e6:	a051                	j	8000656a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064e8:	00fb86b3          	add	a3,s7,a5
    800064ec:	96da                	add	a3,a3,s6
    800064ee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064f2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064f4:	0207c563          	bltz	a5,8000651e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064f8:	2485                	addiw	s1,s1,1
    800064fa:	0711                	addi	a4,a4,4
    800064fc:	25548063          	beq	s1,s5,8000673c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006500:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006502:	00021697          	auipc	a3,0x21
    80006506:	b1668693          	addi	a3,a3,-1258 # 80027018 <disk+0x2018>
    8000650a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000650c:	0006c583          	lbu	a1,0(a3)
    80006510:	fde1                	bnez	a1,800064e8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006512:	2785                	addiw	a5,a5,1
    80006514:	0685                	addi	a3,a3,1
    80006516:	ff879be3          	bne	a5,s8,8000650c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000651a:	57fd                	li	a5,-1
    8000651c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000651e:	02905a63          	blez	s1,80006552 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006522:	f9042503          	lw	a0,-112(s0)
    80006526:	00000097          	auipc	ra,0x0
    8000652a:	d90080e7          	jalr	-624(ra) # 800062b6 <free_desc>
      for(int j = 0; j < i; j++)
    8000652e:	4785                	li	a5,1
    80006530:	0297d163          	bge	a5,s1,80006552 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006534:	f9442503          	lw	a0,-108(s0)
    80006538:	00000097          	auipc	ra,0x0
    8000653c:	d7e080e7          	jalr	-642(ra) # 800062b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006540:	4789                	li	a5,2
    80006542:	0097d863          	bge	a5,s1,80006552 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006546:	f9842503          	lw	a0,-104(s0)
    8000654a:	00000097          	auipc	ra,0x0
    8000654e:	d6c080e7          	jalr	-660(ra) # 800062b6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006552:	00021597          	auipc	a1,0x21
    80006556:	bd658593          	addi	a1,a1,-1066 # 80027128 <disk+0x2128>
    8000655a:	00021517          	auipc	a0,0x21
    8000655e:	abe50513          	addi	a0,a0,-1346 # 80027018 <disk+0x2018>
    80006562:	ffffc097          	auipc	ra,0xffffc
    80006566:	d8e080e7          	jalr	-626(ra) # 800022f0 <sleep>
  for(int i = 0; i < 3; i++){
    8000656a:	f9040713          	addi	a4,s0,-112
    8000656e:	84ce                	mv	s1,s3
    80006570:	bf41                	j	80006500 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006572:	20058713          	addi	a4,a1,512
    80006576:	00471693          	slli	a3,a4,0x4
    8000657a:	0001f717          	auipc	a4,0x1f
    8000657e:	a8670713          	addi	a4,a4,-1402 # 80025000 <disk>
    80006582:	9736                	add	a4,a4,a3
    80006584:	4685                	li	a3,1
    80006586:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000658a:	20058713          	addi	a4,a1,512
    8000658e:	00471693          	slli	a3,a4,0x4
    80006592:	0001f717          	auipc	a4,0x1f
    80006596:	a6e70713          	addi	a4,a4,-1426 # 80025000 <disk>
    8000659a:	9736                	add	a4,a4,a3
    8000659c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065a0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065a4:	7679                	lui	a2,0xffffe
    800065a6:	963e                	add	a2,a2,a5
    800065a8:	00021697          	auipc	a3,0x21
    800065ac:	a5868693          	addi	a3,a3,-1448 # 80027000 <disk+0x2000>
    800065b0:	6298                	ld	a4,0(a3)
    800065b2:	9732                	add	a4,a4,a2
    800065b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065b6:	6298                	ld	a4,0(a3)
    800065b8:	9732                	add	a4,a4,a2
    800065ba:	4541                	li	a0,16
    800065bc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065be:	6298                	ld	a4,0(a3)
    800065c0:	9732                	add	a4,a4,a2
    800065c2:	4505                	li	a0,1
    800065c4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065c8:	f9442703          	lw	a4,-108(s0)
    800065cc:	6288                	ld	a0,0(a3)
    800065ce:	962a                	add	a2,a2,a0
    800065d0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065d4:	0712                	slli	a4,a4,0x4
    800065d6:	6290                	ld	a2,0(a3)
    800065d8:	963a                	add	a2,a2,a4
    800065da:	05890513          	addi	a0,s2,88
    800065de:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065e0:	6294                	ld	a3,0(a3)
    800065e2:	96ba                	add	a3,a3,a4
    800065e4:	40000613          	li	a2,1024
    800065e8:	c690                	sw	a2,8(a3)
  if(write)
    800065ea:	140d0063          	beqz	s10,8000672a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ee:	00021697          	auipc	a3,0x21
    800065f2:	a126b683          	ld	a3,-1518(a3) # 80027000 <disk+0x2000>
    800065f6:	96ba                	add	a3,a3,a4
    800065f8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065fc:	0001f817          	auipc	a6,0x1f
    80006600:	a0480813          	addi	a6,a6,-1532 # 80025000 <disk>
    80006604:	00021517          	auipc	a0,0x21
    80006608:	9fc50513          	addi	a0,a0,-1540 # 80027000 <disk+0x2000>
    8000660c:	6114                	ld	a3,0(a0)
    8000660e:	96ba                	add	a3,a3,a4
    80006610:	00c6d603          	lhu	a2,12(a3)
    80006614:	00166613          	ori	a2,a2,1
    80006618:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000661c:	f9842683          	lw	a3,-104(s0)
    80006620:	6110                	ld	a2,0(a0)
    80006622:	9732                	add	a4,a4,a2
    80006624:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006628:	20058613          	addi	a2,a1,512
    8000662c:	0612                	slli	a2,a2,0x4
    8000662e:	9642                	add	a2,a2,a6
    80006630:	577d                	li	a4,-1
    80006632:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006636:	00469713          	slli	a4,a3,0x4
    8000663a:	6114                	ld	a3,0(a0)
    8000663c:	96ba                	add	a3,a3,a4
    8000663e:	03078793          	addi	a5,a5,48
    80006642:	97c2                	add	a5,a5,a6
    80006644:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006646:	611c                	ld	a5,0(a0)
    80006648:	97ba                	add	a5,a5,a4
    8000664a:	4685                	li	a3,1
    8000664c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000664e:	611c                	ld	a5,0(a0)
    80006650:	97ba                	add	a5,a5,a4
    80006652:	4809                	li	a6,2
    80006654:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006658:	611c                	ld	a5,0(a0)
    8000665a:	973e                	add	a4,a4,a5
    8000665c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006660:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006664:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006668:	6518                	ld	a4,8(a0)
    8000666a:	00275783          	lhu	a5,2(a4)
    8000666e:	8b9d                	andi	a5,a5,7
    80006670:	0786                	slli	a5,a5,0x1
    80006672:	97ba                	add	a5,a5,a4
    80006674:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006678:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000667c:	6518                	ld	a4,8(a0)
    8000667e:	00275783          	lhu	a5,2(a4)
    80006682:	2785                	addiw	a5,a5,1
    80006684:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006688:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000668c:	100017b7          	lui	a5,0x10001
    80006690:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006694:	00492703          	lw	a4,4(s2)
    80006698:	4785                	li	a5,1
    8000669a:	02f71163          	bne	a4,a5,800066bc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000669e:	00021997          	auipc	s3,0x21
    800066a2:	a8a98993          	addi	s3,s3,-1398 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800066a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066a8:	85ce                	mv	a1,s3
    800066aa:	854a                	mv	a0,s2
    800066ac:	ffffc097          	auipc	ra,0xffffc
    800066b0:	c44080e7          	jalr	-956(ra) # 800022f0 <sleep>
  while(b->disk == 1) {
    800066b4:	00492783          	lw	a5,4(s2)
    800066b8:	fe9788e3          	beq	a5,s1,800066a8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800066bc:	f9042903          	lw	s2,-112(s0)
    800066c0:	20090793          	addi	a5,s2,512
    800066c4:	00479713          	slli	a4,a5,0x4
    800066c8:	0001f797          	auipc	a5,0x1f
    800066cc:	93878793          	addi	a5,a5,-1736 # 80025000 <disk>
    800066d0:	97ba                	add	a5,a5,a4
    800066d2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066d6:	00021997          	auipc	s3,0x21
    800066da:	92a98993          	addi	s3,s3,-1750 # 80027000 <disk+0x2000>
    800066de:	00491713          	slli	a4,s2,0x4
    800066e2:	0009b783          	ld	a5,0(s3)
    800066e6:	97ba                	add	a5,a5,a4
    800066e8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066ec:	854a                	mv	a0,s2
    800066ee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066f2:	00000097          	auipc	ra,0x0
    800066f6:	bc4080e7          	jalr	-1084(ra) # 800062b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066fa:	8885                	andi	s1,s1,1
    800066fc:	f0ed                	bnez	s1,800066de <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066fe:	00021517          	auipc	a0,0x21
    80006702:	a2a50513          	addi	a0,a0,-1494 # 80027128 <disk+0x2128>
    80006706:	ffffa097          	auipc	ra,0xffffa
    8000670a:	592080e7          	jalr	1426(ra) # 80000c98 <release>
}
    8000670e:	70a6                	ld	ra,104(sp)
    80006710:	7406                	ld	s0,96(sp)
    80006712:	64e6                	ld	s1,88(sp)
    80006714:	6946                	ld	s2,80(sp)
    80006716:	69a6                	ld	s3,72(sp)
    80006718:	6a06                	ld	s4,64(sp)
    8000671a:	7ae2                	ld	s5,56(sp)
    8000671c:	7b42                	ld	s6,48(sp)
    8000671e:	7ba2                	ld	s7,40(sp)
    80006720:	7c02                	ld	s8,32(sp)
    80006722:	6ce2                	ld	s9,24(sp)
    80006724:	6d42                	ld	s10,16(sp)
    80006726:	6165                	addi	sp,sp,112
    80006728:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000672a:	00021697          	auipc	a3,0x21
    8000672e:	8d66b683          	ld	a3,-1834(a3) # 80027000 <disk+0x2000>
    80006732:	96ba                	add	a3,a3,a4
    80006734:	4609                	li	a2,2
    80006736:	00c69623          	sh	a2,12(a3)
    8000673a:	b5c9                	j	800065fc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000673c:	f9042583          	lw	a1,-112(s0)
    80006740:	20058793          	addi	a5,a1,512
    80006744:	0792                	slli	a5,a5,0x4
    80006746:	0001f517          	auipc	a0,0x1f
    8000674a:	96250513          	addi	a0,a0,-1694 # 800250a8 <disk+0xa8>
    8000674e:	953e                	add	a0,a0,a5
  if(write)
    80006750:	e20d11e3          	bnez	s10,80006572 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006754:	20058713          	addi	a4,a1,512
    80006758:	00471693          	slli	a3,a4,0x4
    8000675c:	0001f717          	auipc	a4,0x1f
    80006760:	8a470713          	addi	a4,a4,-1884 # 80025000 <disk>
    80006764:	9736                	add	a4,a4,a3
    80006766:	0a072423          	sw	zero,168(a4)
    8000676a:	b505                	j	8000658a <virtio_disk_rw+0xf4>

000000008000676c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000676c:	1101                	addi	sp,sp,-32
    8000676e:	ec06                	sd	ra,24(sp)
    80006770:	e822                	sd	s0,16(sp)
    80006772:	e426                	sd	s1,8(sp)
    80006774:	e04a                	sd	s2,0(sp)
    80006776:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006778:	00021517          	auipc	a0,0x21
    8000677c:	9b050513          	addi	a0,a0,-1616 # 80027128 <disk+0x2128>
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	464080e7          	jalr	1124(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006788:	10001737          	lui	a4,0x10001
    8000678c:	533c                	lw	a5,96(a4)
    8000678e:	8b8d                	andi	a5,a5,3
    80006790:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006792:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006796:	00021797          	auipc	a5,0x21
    8000679a:	86a78793          	addi	a5,a5,-1942 # 80027000 <disk+0x2000>
    8000679e:	6b94                	ld	a3,16(a5)
    800067a0:	0207d703          	lhu	a4,32(a5)
    800067a4:	0026d783          	lhu	a5,2(a3)
    800067a8:	06f70163          	beq	a4,a5,8000680a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067ac:	0001f917          	auipc	s2,0x1f
    800067b0:	85490913          	addi	s2,s2,-1964 # 80025000 <disk>
    800067b4:	00021497          	auipc	s1,0x21
    800067b8:	84c48493          	addi	s1,s1,-1972 # 80027000 <disk+0x2000>
    __sync_synchronize();
    800067bc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067c0:	6898                	ld	a4,16(s1)
    800067c2:	0204d783          	lhu	a5,32(s1)
    800067c6:	8b9d                	andi	a5,a5,7
    800067c8:	078e                	slli	a5,a5,0x3
    800067ca:	97ba                	add	a5,a5,a4
    800067cc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ce:	20078713          	addi	a4,a5,512
    800067d2:	0712                	slli	a4,a4,0x4
    800067d4:	974a                	add	a4,a4,s2
    800067d6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067da:	e731                	bnez	a4,80006826 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067dc:	20078793          	addi	a5,a5,512
    800067e0:	0792                	slli	a5,a5,0x4
    800067e2:	97ca                	add	a5,a5,s2
    800067e4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067e6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ea:	ffffc097          	auipc	ra,0xffffc
    800067ee:	dde080e7          	jalr	-546(ra) # 800025c8 <wakeup>

    disk.used_idx += 1;
    800067f2:	0204d783          	lhu	a5,32(s1)
    800067f6:	2785                	addiw	a5,a5,1
    800067f8:	17c2                	slli	a5,a5,0x30
    800067fa:	93c1                	srli	a5,a5,0x30
    800067fc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006800:	6898                	ld	a4,16(s1)
    80006802:	00275703          	lhu	a4,2(a4)
    80006806:	faf71be3          	bne	a4,a5,800067bc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000680a:	00021517          	auipc	a0,0x21
    8000680e:	91e50513          	addi	a0,a0,-1762 # 80027128 <disk+0x2128>
    80006812:	ffffa097          	auipc	ra,0xffffa
    80006816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
}
    8000681a:	60e2                	ld	ra,24(sp)
    8000681c:	6442                	ld	s0,16(sp)
    8000681e:	64a2                	ld	s1,8(sp)
    80006820:	6902                	ld	s2,0(sp)
    80006822:	6105                	addi	sp,sp,32
    80006824:	8082                	ret
      panic("virtio_disk_intr status");
    80006826:	00002517          	auipc	a0,0x2
    8000682a:	10250513          	addi	a0,a0,258 # 80008928 <syscalls+0x3c0>
    8000682e:	ffffa097          	auipc	ra,0xffffa
    80006832:	d10080e7          	jalr	-752(ra) # 8000053e <panic>
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
