
user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:


#define NFORK 10
#define IO 5

int main() {
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	addi	s0,sp,64
  int n, pid;
  int wtime, rtime;
  int twtime=0, trtime=0;
  for(n=0; n < NFORK;n++) {
   e:	4481                	li	s1,0
  10:	4929                	li	s2,10
      pid = fork();
  12:	00000097          	auipc	ra,0x0
  16:	34a080e7          	jalr	842(ra) # 35c <fork>
  1a:	85aa                	mv	a1,a0
      if (pid < 0)
  1c:	06054d63          	bltz	a0,96 <main+0x96>
          break;
      if (pid == 0) {
  20:	cd09                	beqz	a0,3a <main+0x3a>
#endif
          printf("Process %d finished", n);
          exit(0);
      } else {
#ifdef PBS
        set_priority(80, pid); // Will only matter for PBS, set lower priority for IO bound processes 
  22:	05000513          	li	a0,80
  26:	00000097          	auipc	ra,0x0
  2a:	3ee080e7          	jalr	1006(ra) # 414 <set_priority>
  for(n=0; n < NFORK;n++) {
  2e:	2485                	addiw	s1,s1,1
  30:	ff2491e3          	bne	s1,s2,12 <main+0x12>
  34:	4901                	li	s2,0
  36:	4981                	li	s3,0
  38:	a079                	j	c6 <main+0xc6>
          if (n < IO) {
  3a:	4791                	li	a5,4
  3c:	0497d663          	bge	a5,s1,88 <main+0x88>
            for (volatile int i = 0; i < 1000000000; i++) {} // CPU bound process 
  40:	fc042223          	sw	zero,-60(s0)
  44:	fc442703          	lw	a4,-60(s0)
  48:	2701                	sext.w	a4,a4
  4a:	3b9ad7b7          	lui	a5,0x3b9ad
  4e:	9ff78793          	addi	a5,a5,-1537 # 3b9ac9ff <__global_pointer$+0x3b9ab916>
  52:	00e7cd63          	blt	a5,a4,6c <main+0x6c>
  56:	873e                	mv	a4,a5
  58:	fc442783          	lw	a5,-60(s0)
  5c:	2785                	addiw	a5,a5,1
  5e:	fcf42223          	sw	a5,-60(s0)
  62:	fc442783          	lw	a5,-60(s0)
  66:	2781                	sext.w	a5,a5
  68:	fef758e3          	bge	a4,a5,58 <main+0x58>
          printf("Process %d finished", n);
  6c:	85a6                	mv	a1,s1
  6e:	00001517          	auipc	a0,0x1
  72:	82a50513          	addi	a0,a0,-2006 # 898 <malloc+0xe6>
  76:	00000097          	auipc	ra,0x0
  7a:	67e080e7          	jalr	1662(ra) # 6f4 <printf>
          exit(0);
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	2e4080e7          	jalr	740(ra) # 364 <exit>
            sleep(200); // IO bound processes
  88:	0c800513          	li	a0,200
  8c:	00000097          	auipc	ra,0x0
  90:	368080e7          	jalr	872(ra) # 3f4 <sleep>
  94:	bfe1                	j	6c <main+0x6c>
#endif
      }
  }
  for(;n > 0; n--) {
  96:	f8904fe3          	bgtz	s1,34 <main+0x34>
  9a:	4901                	li	s2,0
  9c:	4981                	li	s3,0
      if(waitx(0,&wtime,&rtime) >= 0) {
          trtime += rtime;
          twtime += wtime;
      } 
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  9e:	45a9                	li	a1,10
  a0:	02b9c63b          	divw	a2,s3,a1
  a4:	02b945bb          	divw	a1,s2,a1
  a8:	00001517          	auipc	a0,0x1
  ac:	80850513          	addi	a0,a0,-2040 # 8b0 <malloc+0xfe>
  b0:	00000097          	auipc	ra,0x0
  b4:	644080e7          	jalr	1604(ra) # 6f4 <printf>
  exit(0);
  b8:	4501                	li	a0,0
  ba:	00000097          	auipc	ra,0x0
  be:	2aa080e7          	jalr	682(ra) # 364 <exit>
  for(;n > 0; n--) {
  c2:	34fd                	addiw	s1,s1,-1
  c4:	dce9                	beqz	s1,9e <main+0x9e>
      if(waitx(0,&wtime,&rtime) >= 0) {
  c6:	fc840613          	addi	a2,s0,-56
  ca:	fcc40593          	addi	a1,s0,-52
  ce:	4501                	li	a0,0
  d0:	00000097          	auipc	ra,0x0
  d4:	33c080e7          	jalr	828(ra) # 40c <waitx>
  d8:	fe0545e3          	bltz	a0,c2 <main+0xc2>
          trtime += rtime;
  dc:	fc842783          	lw	a5,-56(s0)
  e0:	0127893b          	addw	s2,a5,s2
          twtime += wtime;
  e4:	fcc42783          	lw	a5,-52(s0)
  e8:	013789bb          	addw	s3,a5,s3
  ec:	bfd9                	j	c2 <main+0xc2>

00000000000000ee <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  ee:	1141                	addi	sp,sp,-16
  f0:	e422                	sd	s0,8(sp)
  f2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  f4:	87aa                	mv	a5,a0
  f6:	0585                	addi	a1,a1,1
  f8:	0785                	addi	a5,a5,1
  fa:	fff5c703          	lbu	a4,-1(a1)
  fe:	fee78fa3          	sb	a4,-1(a5)
 102:	fb75                	bnez	a4,f6 <strcpy+0x8>
    ;
  return os;
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	addi	sp,sp,16
 108:	8082                	ret

000000000000010a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 10a:	1141                	addi	sp,sp,-16
 10c:	e422                	sd	s0,8(sp)
 10e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 110:	00054783          	lbu	a5,0(a0)
 114:	cb91                	beqz	a5,128 <strcmp+0x1e>
 116:	0005c703          	lbu	a4,0(a1)
 11a:	00f71763          	bne	a4,a5,128 <strcmp+0x1e>
    p++, q++;
 11e:	0505                	addi	a0,a0,1
 120:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 122:	00054783          	lbu	a5,0(a0)
 126:	fbe5                	bnez	a5,116 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 128:	0005c503          	lbu	a0,0(a1)
}
 12c:	40a7853b          	subw	a0,a5,a0
 130:	6422                	ld	s0,8(sp)
 132:	0141                	addi	sp,sp,16
 134:	8082                	ret

0000000000000136 <strlen>:

uint
strlen(const char *s)
{
 136:	1141                	addi	sp,sp,-16
 138:	e422                	sd	s0,8(sp)
 13a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 13c:	00054783          	lbu	a5,0(a0)
 140:	cf91                	beqz	a5,15c <strlen+0x26>
 142:	0505                	addi	a0,a0,1
 144:	87aa                	mv	a5,a0
 146:	4685                	li	a3,1
 148:	9e89                	subw	a3,a3,a0
 14a:	00f6853b          	addw	a0,a3,a5
 14e:	0785                	addi	a5,a5,1
 150:	fff7c703          	lbu	a4,-1(a5)
 154:	fb7d                	bnez	a4,14a <strlen+0x14>
    ;
  return n;
}
 156:	6422                	ld	s0,8(sp)
 158:	0141                	addi	sp,sp,16
 15a:	8082                	ret
  for(n = 0; s[n]; n++)
 15c:	4501                	li	a0,0
 15e:	bfe5                	j	156 <strlen+0x20>

0000000000000160 <memset>:

void*
memset(void *dst, int c, uint n)
{
 160:	1141                	addi	sp,sp,-16
 162:	e422                	sd	s0,8(sp)
 164:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 166:	ce09                	beqz	a2,180 <memset+0x20>
 168:	87aa                	mv	a5,a0
 16a:	fff6071b          	addiw	a4,a2,-1
 16e:	1702                	slli	a4,a4,0x20
 170:	9301                	srli	a4,a4,0x20
 172:	0705                	addi	a4,a4,1
 174:	972a                	add	a4,a4,a0
    cdst[i] = c;
 176:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 17a:	0785                	addi	a5,a5,1
 17c:	fee79de3          	bne	a5,a4,176 <memset+0x16>
  }
  return dst;
}
 180:	6422                	ld	s0,8(sp)
 182:	0141                	addi	sp,sp,16
 184:	8082                	ret

0000000000000186 <strchr>:

char*
strchr(const char *s, char c)
{
 186:	1141                	addi	sp,sp,-16
 188:	e422                	sd	s0,8(sp)
 18a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 18c:	00054783          	lbu	a5,0(a0)
 190:	cb99                	beqz	a5,1a6 <strchr+0x20>
    if(*s == c)
 192:	00f58763          	beq	a1,a5,1a0 <strchr+0x1a>
  for(; *s; s++)
 196:	0505                	addi	a0,a0,1
 198:	00054783          	lbu	a5,0(a0)
 19c:	fbfd                	bnez	a5,192 <strchr+0xc>
      return (char*)s;
  return 0;
 19e:	4501                	li	a0,0
}
 1a0:	6422                	ld	s0,8(sp)
 1a2:	0141                	addi	sp,sp,16
 1a4:	8082                	ret
  return 0;
 1a6:	4501                	li	a0,0
 1a8:	bfe5                	j	1a0 <strchr+0x1a>

00000000000001aa <gets>:

char*
gets(char *buf, int max)
{
 1aa:	711d                	addi	sp,sp,-96
 1ac:	ec86                	sd	ra,88(sp)
 1ae:	e8a2                	sd	s0,80(sp)
 1b0:	e4a6                	sd	s1,72(sp)
 1b2:	e0ca                	sd	s2,64(sp)
 1b4:	fc4e                	sd	s3,56(sp)
 1b6:	f852                	sd	s4,48(sp)
 1b8:	f456                	sd	s5,40(sp)
 1ba:	f05a                	sd	s6,32(sp)
 1bc:	ec5e                	sd	s7,24(sp)
 1be:	1080                	addi	s0,sp,96
 1c0:	8baa                	mv	s7,a0
 1c2:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1c4:	892a                	mv	s2,a0
 1c6:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1c8:	4aa9                	li	s5,10
 1ca:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1cc:	89a6                	mv	s3,s1
 1ce:	2485                	addiw	s1,s1,1
 1d0:	0344d863          	bge	s1,s4,200 <gets+0x56>
    cc = read(0, &c, 1);
 1d4:	4605                	li	a2,1
 1d6:	faf40593          	addi	a1,s0,-81
 1da:	4501                	li	a0,0
 1dc:	00000097          	auipc	ra,0x0
 1e0:	1a0080e7          	jalr	416(ra) # 37c <read>
    if(cc < 1)
 1e4:	00a05e63          	blez	a0,200 <gets+0x56>
    buf[i++] = c;
 1e8:	faf44783          	lbu	a5,-81(s0)
 1ec:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1f0:	01578763          	beq	a5,s5,1fe <gets+0x54>
 1f4:	0905                	addi	s2,s2,1
 1f6:	fd679be3          	bne	a5,s6,1cc <gets+0x22>
  for(i=0; i+1 < max; ){
 1fa:	89a6                	mv	s3,s1
 1fc:	a011                	j	200 <gets+0x56>
 1fe:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 200:	99de                	add	s3,s3,s7
 202:	00098023          	sb	zero,0(s3)
  return buf;
}
 206:	855e                	mv	a0,s7
 208:	60e6                	ld	ra,88(sp)
 20a:	6446                	ld	s0,80(sp)
 20c:	64a6                	ld	s1,72(sp)
 20e:	6906                	ld	s2,64(sp)
 210:	79e2                	ld	s3,56(sp)
 212:	7a42                	ld	s4,48(sp)
 214:	7aa2                	ld	s5,40(sp)
 216:	7b02                	ld	s6,32(sp)
 218:	6be2                	ld	s7,24(sp)
 21a:	6125                	addi	sp,sp,96
 21c:	8082                	ret

000000000000021e <stat>:

int
stat(const char *n, struct stat *st)
{
 21e:	1101                	addi	sp,sp,-32
 220:	ec06                	sd	ra,24(sp)
 222:	e822                	sd	s0,16(sp)
 224:	e426                	sd	s1,8(sp)
 226:	e04a                	sd	s2,0(sp)
 228:	1000                	addi	s0,sp,32
 22a:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 22c:	4581                	li	a1,0
 22e:	00000097          	auipc	ra,0x0
 232:	176080e7          	jalr	374(ra) # 3a4 <open>
  if(fd < 0)
 236:	02054563          	bltz	a0,260 <stat+0x42>
 23a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 23c:	85ca                	mv	a1,s2
 23e:	00000097          	auipc	ra,0x0
 242:	17e080e7          	jalr	382(ra) # 3bc <fstat>
 246:	892a                	mv	s2,a0
  close(fd);
 248:	8526                	mv	a0,s1
 24a:	00000097          	auipc	ra,0x0
 24e:	142080e7          	jalr	322(ra) # 38c <close>
  return r;
}
 252:	854a                	mv	a0,s2
 254:	60e2                	ld	ra,24(sp)
 256:	6442                	ld	s0,16(sp)
 258:	64a2                	ld	s1,8(sp)
 25a:	6902                	ld	s2,0(sp)
 25c:	6105                	addi	sp,sp,32
 25e:	8082                	ret
    return -1;
 260:	597d                	li	s2,-1
 262:	bfc5                	j	252 <stat+0x34>

0000000000000264 <atoi>:

int
atoi(const char *s)
{
 264:	1141                	addi	sp,sp,-16
 266:	e422                	sd	s0,8(sp)
 268:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 26a:	00054603          	lbu	a2,0(a0)
 26e:	fd06079b          	addiw	a5,a2,-48
 272:	0ff7f793          	andi	a5,a5,255
 276:	4725                	li	a4,9
 278:	02f76963          	bltu	a4,a5,2aa <atoi+0x46>
 27c:	86aa                	mv	a3,a0
  n = 0;
 27e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 280:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 282:	0685                	addi	a3,a3,1
 284:	0025179b          	slliw	a5,a0,0x2
 288:	9fa9                	addw	a5,a5,a0
 28a:	0017979b          	slliw	a5,a5,0x1
 28e:	9fb1                	addw	a5,a5,a2
 290:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 294:	0006c603          	lbu	a2,0(a3)
 298:	fd06071b          	addiw	a4,a2,-48
 29c:	0ff77713          	andi	a4,a4,255
 2a0:	fee5f1e3          	bgeu	a1,a4,282 <atoi+0x1e>
  return n;
}
 2a4:	6422                	ld	s0,8(sp)
 2a6:	0141                	addi	sp,sp,16
 2a8:	8082                	ret
  n = 0;
 2aa:	4501                	li	a0,0
 2ac:	bfe5                	j	2a4 <atoi+0x40>

00000000000002ae <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ae:	1141                	addi	sp,sp,-16
 2b0:	e422                	sd	s0,8(sp)
 2b2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2b4:	02b57663          	bgeu	a0,a1,2e0 <memmove+0x32>
    while(n-- > 0)
 2b8:	02c05163          	blez	a2,2da <memmove+0x2c>
 2bc:	fff6079b          	addiw	a5,a2,-1
 2c0:	1782                	slli	a5,a5,0x20
 2c2:	9381                	srli	a5,a5,0x20
 2c4:	0785                	addi	a5,a5,1
 2c6:	97aa                	add	a5,a5,a0
  dst = vdst;
 2c8:	872a                	mv	a4,a0
      *dst++ = *src++;
 2ca:	0585                	addi	a1,a1,1
 2cc:	0705                	addi	a4,a4,1
 2ce:	fff5c683          	lbu	a3,-1(a1)
 2d2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2d6:	fee79ae3          	bne	a5,a4,2ca <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2da:	6422                	ld	s0,8(sp)
 2dc:	0141                	addi	sp,sp,16
 2de:	8082                	ret
    dst += n;
 2e0:	00c50733          	add	a4,a0,a2
    src += n;
 2e4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2e6:	fec05ae3          	blez	a2,2da <memmove+0x2c>
 2ea:	fff6079b          	addiw	a5,a2,-1
 2ee:	1782                	slli	a5,a5,0x20
 2f0:	9381                	srli	a5,a5,0x20
 2f2:	fff7c793          	not	a5,a5
 2f6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2f8:	15fd                	addi	a1,a1,-1
 2fa:	177d                	addi	a4,a4,-1
 2fc:	0005c683          	lbu	a3,0(a1)
 300:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 304:	fee79ae3          	bne	a5,a4,2f8 <memmove+0x4a>
 308:	bfc9                	j	2da <memmove+0x2c>

000000000000030a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e422                	sd	s0,8(sp)
 30e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 310:	ca05                	beqz	a2,340 <memcmp+0x36>
 312:	fff6069b          	addiw	a3,a2,-1
 316:	1682                	slli	a3,a3,0x20
 318:	9281                	srli	a3,a3,0x20
 31a:	0685                	addi	a3,a3,1
 31c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 31e:	00054783          	lbu	a5,0(a0)
 322:	0005c703          	lbu	a4,0(a1)
 326:	00e79863          	bne	a5,a4,336 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 32a:	0505                	addi	a0,a0,1
    p2++;
 32c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 32e:	fed518e3          	bne	a0,a3,31e <memcmp+0x14>
  }
  return 0;
 332:	4501                	li	a0,0
 334:	a019                	j	33a <memcmp+0x30>
      return *p1 - *p2;
 336:	40e7853b          	subw	a0,a5,a4
}
 33a:	6422                	ld	s0,8(sp)
 33c:	0141                	addi	sp,sp,16
 33e:	8082                	ret
  return 0;
 340:	4501                	li	a0,0
 342:	bfe5                	j	33a <memcmp+0x30>

0000000000000344 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 344:	1141                	addi	sp,sp,-16
 346:	e406                	sd	ra,8(sp)
 348:	e022                	sd	s0,0(sp)
 34a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 34c:	00000097          	auipc	ra,0x0
 350:	f62080e7          	jalr	-158(ra) # 2ae <memmove>
}
 354:	60a2                	ld	ra,8(sp)
 356:	6402                	ld	s0,0(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret

000000000000035c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 35c:	4885                	li	a7,1
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <exit>:
.global exit
exit:
 li a7, SYS_exit
 364:	4889                	li	a7,2
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <wait>:
.global wait
wait:
 li a7, SYS_wait
 36c:	488d                	li	a7,3
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 374:	4891                	li	a7,4
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <read>:
.global read
read:
 li a7, SYS_read
 37c:	4895                	li	a7,5
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <write>:
.global write
write:
 li a7, SYS_write
 384:	48c1                	li	a7,16
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <close>:
.global close
close:
 li a7, SYS_close
 38c:	48d5                	li	a7,21
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <kill>:
.global kill
kill:
 li a7, SYS_kill
 394:	4899                	li	a7,6
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <exec>:
.global exec
exec:
 li a7, SYS_exec
 39c:	489d                	li	a7,7
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <open>:
.global open
open:
 li a7, SYS_open
 3a4:	48bd                	li	a7,15
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3ac:	48c5                	li	a7,17
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3b4:	48c9                	li	a7,18
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3bc:	48a1                	li	a7,8
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <link>:
.global link
link:
 li a7, SYS_link
 3c4:	48cd                	li	a7,19
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3cc:	48d1                	li	a7,20
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3d4:	48a5                	li	a7,9
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <dup>:
.global dup
dup:
 li a7, SYS_dup
 3dc:	48a9                	li	a7,10
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3e4:	48ad                	li	a7,11
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ec:	48b1                	li	a7,12
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3f4:	48b5                	li	a7,13
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3fc:	48b9                	li	a7,14
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <trace>:
.global trace
trace:
 li a7, SYS_trace
 404:	48d9                	li	a7,22
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 40c:	48dd                	li	a7,23
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 414:	48e1                	li	a7,24
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 41c:	1101                	addi	sp,sp,-32
 41e:	ec06                	sd	ra,24(sp)
 420:	e822                	sd	s0,16(sp)
 422:	1000                	addi	s0,sp,32
 424:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 428:	4605                	li	a2,1
 42a:	fef40593          	addi	a1,s0,-17
 42e:	00000097          	auipc	ra,0x0
 432:	f56080e7          	jalr	-170(ra) # 384 <write>
}
 436:	60e2                	ld	ra,24(sp)
 438:	6442                	ld	s0,16(sp)
 43a:	6105                	addi	sp,sp,32
 43c:	8082                	ret

000000000000043e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 43e:	7139                	addi	sp,sp,-64
 440:	fc06                	sd	ra,56(sp)
 442:	f822                	sd	s0,48(sp)
 444:	f426                	sd	s1,40(sp)
 446:	f04a                	sd	s2,32(sp)
 448:	ec4e                	sd	s3,24(sp)
 44a:	0080                	addi	s0,sp,64
 44c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 44e:	c299                	beqz	a3,454 <printint+0x16>
 450:	0805c863          	bltz	a1,4e0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 454:	2581                	sext.w	a1,a1
  neg = 0;
 456:	4881                	li	a7,0
 458:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 45c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 45e:	2601                	sext.w	a2,a2
 460:	00000517          	auipc	a0,0x0
 464:	47850513          	addi	a0,a0,1144 # 8d8 <digits>
 468:	883a                	mv	a6,a4
 46a:	2705                	addiw	a4,a4,1
 46c:	02c5f7bb          	remuw	a5,a1,a2
 470:	1782                	slli	a5,a5,0x20
 472:	9381                	srli	a5,a5,0x20
 474:	97aa                	add	a5,a5,a0
 476:	0007c783          	lbu	a5,0(a5)
 47a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 47e:	0005879b          	sext.w	a5,a1
 482:	02c5d5bb          	divuw	a1,a1,a2
 486:	0685                	addi	a3,a3,1
 488:	fec7f0e3          	bgeu	a5,a2,468 <printint+0x2a>
  if(neg)
 48c:	00088b63          	beqz	a7,4a2 <printint+0x64>
    buf[i++] = '-';
 490:	fd040793          	addi	a5,s0,-48
 494:	973e                	add	a4,a4,a5
 496:	02d00793          	li	a5,45
 49a:	fef70823          	sb	a5,-16(a4)
 49e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4a2:	02e05863          	blez	a4,4d2 <printint+0x94>
 4a6:	fc040793          	addi	a5,s0,-64
 4aa:	00e78933          	add	s2,a5,a4
 4ae:	fff78993          	addi	s3,a5,-1
 4b2:	99ba                	add	s3,s3,a4
 4b4:	377d                	addiw	a4,a4,-1
 4b6:	1702                	slli	a4,a4,0x20
 4b8:	9301                	srli	a4,a4,0x20
 4ba:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4be:	fff94583          	lbu	a1,-1(s2)
 4c2:	8526                	mv	a0,s1
 4c4:	00000097          	auipc	ra,0x0
 4c8:	f58080e7          	jalr	-168(ra) # 41c <putc>
  while(--i >= 0)
 4cc:	197d                	addi	s2,s2,-1
 4ce:	ff3918e3          	bne	s2,s3,4be <printint+0x80>
}
 4d2:	70e2                	ld	ra,56(sp)
 4d4:	7442                	ld	s0,48(sp)
 4d6:	74a2                	ld	s1,40(sp)
 4d8:	7902                	ld	s2,32(sp)
 4da:	69e2                	ld	s3,24(sp)
 4dc:	6121                	addi	sp,sp,64
 4de:	8082                	ret
    x = -xx;
 4e0:	40b005bb          	negw	a1,a1
    neg = 1;
 4e4:	4885                	li	a7,1
    x = -xx;
 4e6:	bf8d                	j	458 <printint+0x1a>

00000000000004e8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4e8:	7119                	addi	sp,sp,-128
 4ea:	fc86                	sd	ra,120(sp)
 4ec:	f8a2                	sd	s0,112(sp)
 4ee:	f4a6                	sd	s1,104(sp)
 4f0:	f0ca                	sd	s2,96(sp)
 4f2:	ecce                	sd	s3,88(sp)
 4f4:	e8d2                	sd	s4,80(sp)
 4f6:	e4d6                	sd	s5,72(sp)
 4f8:	e0da                	sd	s6,64(sp)
 4fa:	fc5e                	sd	s7,56(sp)
 4fc:	f862                	sd	s8,48(sp)
 4fe:	f466                	sd	s9,40(sp)
 500:	f06a                	sd	s10,32(sp)
 502:	ec6e                	sd	s11,24(sp)
 504:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 506:	0005c903          	lbu	s2,0(a1)
 50a:	18090f63          	beqz	s2,6a8 <vprintf+0x1c0>
 50e:	8aaa                	mv	s5,a0
 510:	8b32                	mv	s6,a2
 512:	00158493          	addi	s1,a1,1
  state = 0;
 516:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 518:	02500a13          	li	s4,37
      if(c == 'd'){
 51c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 520:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 524:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 528:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 52c:	00000b97          	auipc	s7,0x0
 530:	3acb8b93          	addi	s7,s7,940 # 8d8 <digits>
 534:	a839                	j	552 <vprintf+0x6a>
        putc(fd, c);
 536:	85ca                	mv	a1,s2
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	ee2080e7          	jalr	-286(ra) # 41c <putc>
 542:	a019                	j	548 <vprintf+0x60>
    } else if(state == '%'){
 544:	01498f63          	beq	s3,s4,562 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 548:	0485                	addi	s1,s1,1
 54a:	fff4c903          	lbu	s2,-1(s1)
 54e:	14090d63          	beqz	s2,6a8 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 552:	0009079b          	sext.w	a5,s2
    if(state == 0){
 556:	fe0997e3          	bnez	s3,544 <vprintf+0x5c>
      if(c == '%'){
 55a:	fd479ee3          	bne	a5,s4,536 <vprintf+0x4e>
        state = '%';
 55e:	89be                	mv	s3,a5
 560:	b7e5                	j	548 <vprintf+0x60>
      if(c == 'd'){
 562:	05878063          	beq	a5,s8,5a2 <vprintf+0xba>
      } else if(c == 'l') {
 566:	05978c63          	beq	a5,s9,5be <vprintf+0xd6>
      } else if(c == 'x') {
 56a:	07a78863          	beq	a5,s10,5da <vprintf+0xf2>
      } else if(c == 'p') {
 56e:	09b78463          	beq	a5,s11,5f6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 572:	07300713          	li	a4,115
 576:	0ce78663          	beq	a5,a4,642 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 57a:	06300713          	li	a4,99
 57e:	0ee78e63          	beq	a5,a4,67a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 582:	11478863          	beq	a5,s4,692 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 586:	85d2                	mv	a1,s4
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	e92080e7          	jalr	-366(ra) # 41c <putc>
        putc(fd, c);
 592:	85ca                	mv	a1,s2
 594:	8556                	mv	a0,s5
 596:	00000097          	auipc	ra,0x0
 59a:	e86080e7          	jalr	-378(ra) # 41c <putc>
      }
      state = 0;
 59e:	4981                	li	s3,0
 5a0:	b765                	j	548 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5a2:	008b0913          	addi	s2,s6,8
 5a6:	4685                	li	a3,1
 5a8:	4629                	li	a2,10
 5aa:	000b2583          	lw	a1,0(s6)
 5ae:	8556                	mv	a0,s5
 5b0:	00000097          	auipc	ra,0x0
 5b4:	e8e080e7          	jalr	-370(ra) # 43e <printint>
 5b8:	8b4a                	mv	s6,s2
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	b771                	j	548 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5be:	008b0913          	addi	s2,s6,8
 5c2:	4681                	li	a3,0
 5c4:	4629                	li	a2,10
 5c6:	000b2583          	lw	a1,0(s6)
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	e72080e7          	jalr	-398(ra) # 43e <printint>
 5d4:	8b4a                	mv	s6,s2
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	bf85                	j	548 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5da:	008b0913          	addi	s2,s6,8
 5de:	4681                	li	a3,0
 5e0:	4641                	li	a2,16
 5e2:	000b2583          	lw	a1,0(s6)
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	e56080e7          	jalr	-426(ra) # 43e <printint>
 5f0:	8b4a                	mv	s6,s2
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	bf91                	j	548 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5f6:	008b0793          	addi	a5,s6,8
 5fa:	f8f43423          	sd	a5,-120(s0)
 5fe:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 602:	03000593          	li	a1,48
 606:	8556                	mv	a0,s5
 608:	00000097          	auipc	ra,0x0
 60c:	e14080e7          	jalr	-492(ra) # 41c <putc>
  putc(fd, 'x');
 610:	85ea                	mv	a1,s10
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	e08080e7          	jalr	-504(ra) # 41c <putc>
 61c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 61e:	03c9d793          	srli	a5,s3,0x3c
 622:	97de                	add	a5,a5,s7
 624:	0007c583          	lbu	a1,0(a5)
 628:	8556                	mv	a0,s5
 62a:	00000097          	auipc	ra,0x0
 62e:	df2080e7          	jalr	-526(ra) # 41c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 632:	0992                	slli	s3,s3,0x4
 634:	397d                	addiw	s2,s2,-1
 636:	fe0914e3          	bnez	s2,61e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 63a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 63e:	4981                	li	s3,0
 640:	b721                	j	548 <vprintf+0x60>
        s = va_arg(ap, char*);
 642:	008b0993          	addi	s3,s6,8
 646:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 64a:	02090163          	beqz	s2,66c <vprintf+0x184>
        while(*s != 0){
 64e:	00094583          	lbu	a1,0(s2)
 652:	c9a1                	beqz	a1,6a2 <vprintf+0x1ba>
          putc(fd, *s);
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	dc6080e7          	jalr	-570(ra) # 41c <putc>
          s++;
 65e:	0905                	addi	s2,s2,1
        while(*s != 0){
 660:	00094583          	lbu	a1,0(s2)
 664:	f9e5                	bnez	a1,654 <vprintf+0x16c>
        s = va_arg(ap, char*);
 666:	8b4e                	mv	s6,s3
      state = 0;
 668:	4981                	li	s3,0
 66a:	bdf9                	j	548 <vprintf+0x60>
          s = "(null)";
 66c:	00000917          	auipc	s2,0x0
 670:	26490913          	addi	s2,s2,612 # 8d0 <malloc+0x11e>
        while(*s != 0){
 674:	02800593          	li	a1,40
 678:	bff1                	j	654 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 67a:	008b0913          	addi	s2,s6,8
 67e:	000b4583          	lbu	a1,0(s6)
 682:	8556                	mv	a0,s5
 684:	00000097          	auipc	ra,0x0
 688:	d98080e7          	jalr	-616(ra) # 41c <putc>
 68c:	8b4a                	mv	s6,s2
      state = 0;
 68e:	4981                	li	s3,0
 690:	bd65                	j	548 <vprintf+0x60>
        putc(fd, c);
 692:	85d2                	mv	a1,s4
 694:	8556                	mv	a0,s5
 696:	00000097          	auipc	ra,0x0
 69a:	d86080e7          	jalr	-634(ra) # 41c <putc>
      state = 0;
 69e:	4981                	li	s3,0
 6a0:	b565                	j	548 <vprintf+0x60>
        s = va_arg(ap, char*);
 6a2:	8b4e                	mv	s6,s3
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	b54d                	j	548 <vprintf+0x60>
    }
  }
}
 6a8:	70e6                	ld	ra,120(sp)
 6aa:	7446                	ld	s0,112(sp)
 6ac:	74a6                	ld	s1,104(sp)
 6ae:	7906                	ld	s2,96(sp)
 6b0:	69e6                	ld	s3,88(sp)
 6b2:	6a46                	ld	s4,80(sp)
 6b4:	6aa6                	ld	s5,72(sp)
 6b6:	6b06                	ld	s6,64(sp)
 6b8:	7be2                	ld	s7,56(sp)
 6ba:	7c42                	ld	s8,48(sp)
 6bc:	7ca2                	ld	s9,40(sp)
 6be:	7d02                	ld	s10,32(sp)
 6c0:	6de2                	ld	s11,24(sp)
 6c2:	6109                	addi	sp,sp,128
 6c4:	8082                	ret

00000000000006c6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6c6:	715d                	addi	sp,sp,-80
 6c8:	ec06                	sd	ra,24(sp)
 6ca:	e822                	sd	s0,16(sp)
 6cc:	1000                	addi	s0,sp,32
 6ce:	e010                	sd	a2,0(s0)
 6d0:	e414                	sd	a3,8(s0)
 6d2:	e818                	sd	a4,16(s0)
 6d4:	ec1c                	sd	a5,24(s0)
 6d6:	03043023          	sd	a6,32(s0)
 6da:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6de:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6e2:	8622                	mv	a2,s0
 6e4:	00000097          	auipc	ra,0x0
 6e8:	e04080e7          	jalr	-508(ra) # 4e8 <vprintf>
}
 6ec:	60e2                	ld	ra,24(sp)
 6ee:	6442                	ld	s0,16(sp)
 6f0:	6161                	addi	sp,sp,80
 6f2:	8082                	ret

00000000000006f4 <printf>:

void
printf(const char *fmt, ...)
{
 6f4:	711d                	addi	sp,sp,-96
 6f6:	ec06                	sd	ra,24(sp)
 6f8:	e822                	sd	s0,16(sp)
 6fa:	1000                	addi	s0,sp,32
 6fc:	e40c                	sd	a1,8(s0)
 6fe:	e810                	sd	a2,16(s0)
 700:	ec14                	sd	a3,24(s0)
 702:	f018                	sd	a4,32(s0)
 704:	f41c                	sd	a5,40(s0)
 706:	03043823          	sd	a6,48(s0)
 70a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 70e:	00840613          	addi	a2,s0,8
 712:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 716:	85aa                	mv	a1,a0
 718:	4505                	li	a0,1
 71a:	00000097          	auipc	ra,0x0
 71e:	dce080e7          	jalr	-562(ra) # 4e8 <vprintf>
}
 722:	60e2                	ld	ra,24(sp)
 724:	6442                	ld	s0,16(sp)
 726:	6125                	addi	sp,sp,96
 728:	8082                	ret

000000000000072a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 72a:	1141                	addi	sp,sp,-16
 72c:	e422                	sd	s0,8(sp)
 72e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 730:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 734:	00000797          	auipc	a5,0x0
 738:	1bc7b783          	ld	a5,444(a5) # 8f0 <freep>
 73c:	a805                	j	76c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 73e:	4618                	lw	a4,8(a2)
 740:	9db9                	addw	a1,a1,a4
 742:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 746:	6398                	ld	a4,0(a5)
 748:	6318                	ld	a4,0(a4)
 74a:	fee53823          	sd	a4,-16(a0)
 74e:	a091                	j	792 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 750:	ff852703          	lw	a4,-8(a0)
 754:	9e39                	addw	a2,a2,a4
 756:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 758:	ff053703          	ld	a4,-16(a0)
 75c:	e398                	sd	a4,0(a5)
 75e:	a099                	j	7a4 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 760:	6398                	ld	a4,0(a5)
 762:	00e7e463          	bltu	a5,a4,76a <free+0x40>
 766:	00e6ea63          	bltu	a3,a4,77a <free+0x50>
{
 76a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 76c:	fed7fae3          	bgeu	a5,a3,760 <free+0x36>
 770:	6398                	ld	a4,0(a5)
 772:	00e6e463          	bltu	a3,a4,77a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 776:	fee7eae3          	bltu	a5,a4,76a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 77a:	ff852583          	lw	a1,-8(a0)
 77e:	6390                	ld	a2,0(a5)
 780:	02059713          	slli	a4,a1,0x20
 784:	9301                	srli	a4,a4,0x20
 786:	0712                	slli	a4,a4,0x4
 788:	9736                	add	a4,a4,a3
 78a:	fae60ae3          	beq	a2,a4,73e <free+0x14>
    bp->s.ptr = p->s.ptr;
 78e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 792:	4790                	lw	a2,8(a5)
 794:	02061713          	slli	a4,a2,0x20
 798:	9301                	srli	a4,a4,0x20
 79a:	0712                	slli	a4,a4,0x4
 79c:	973e                	add	a4,a4,a5
 79e:	fae689e3          	beq	a3,a4,750 <free+0x26>
  } else
    p->s.ptr = bp;
 7a2:	e394                	sd	a3,0(a5)
  freep = p;
 7a4:	00000717          	auipc	a4,0x0
 7a8:	14f73623          	sd	a5,332(a4) # 8f0 <freep>
}
 7ac:	6422                	ld	s0,8(sp)
 7ae:	0141                	addi	sp,sp,16
 7b0:	8082                	ret

00000000000007b2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7b2:	7139                	addi	sp,sp,-64
 7b4:	fc06                	sd	ra,56(sp)
 7b6:	f822                	sd	s0,48(sp)
 7b8:	f426                	sd	s1,40(sp)
 7ba:	f04a                	sd	s2,32(sp)
 7bc:	ec4e                	sd	s3,24(sp)
 7be:	e852                	sd	s4,16(sp)
 7c0:	e456                	sd	s5,8(sp)
 7c2:	e05a                	sd	s6,0(sp)
 7c4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7c6:	02051493          	slli	s1,a0,0x20
 7ca:	9081                	srli	s1,s1,0x20
 7cc:	04bd                	addi	s1,s1,15
 7ce:	8091                	srli	s1,s1,0x4
 7d0:	0014899b          	addiw	s3,s1,1
 7d4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7d6:	00000517          	auipc	a0,0x0
 7da:	11a53503          	ld	a0,282(a0) # 8f0 <freep>
 7de:	c515                	beqz	a0,80a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e2:	4798                	lw	a4,8(a5)
 7e4:	02977f63          	bgeu	a4,s1,822 <malloc+0x70>
 7e8:	8a4e                	mv	s4,s3
 7ea:	0009871b          	sext.w	a4,s3
 7ee:	6685                	lui	a3,0x1
 7f0:	00d77363          	bgeu	a4,a3,7f6 <malloc+0x44>
 7f4:	6a05                	lui	s4,0x1
 7f6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7fa:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7fe:	00000917          	auipc	s2,0x0
 802:	0f290913          	addi	s2,s2,242 # 8f0 <freep>
  if(p == (char*)-1)
 806:	5afd                	li	s5,-1
 808:	a88d                	j	87a <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 80a:	00000797          	auipc	a5,0x0
 80e:	0ee78793          	addi	a5,a5,238 # 8f8 <base>
 812:	00000717          	auipc	a4,0x0
 816:	0cf73f23          	sd	a5,222(a4) # 8f0 <freep>
 81a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 81c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 820:	b7e1                	j	7e8 <malloc+0x36>
      if(p->s.size == nunits)
 822:	02e48b63          	beq	s1,a4,858 <malloc+0xa6>
        p->s.size -= nunits;
 826:	4137073b          	subw	a4,a4,s3
 82a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 82c:	1702                	slli	a4,a4,0x20
 82e:	9301                	srli	a4,a4,0x20
 830:	0712                	slli	a4,a4,0x4
 832:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 834:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 838:	00000717          	auipc	a4,0x0
 83c:	0aa73c23          	sd	a0,184(a4) # 8f0 <freep>
      return (void*)(p + 1);
 840:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 844:	70e2                	ld	ra,56(sp)
 846:	7442                	ld	s0,48(sp)
 848:	74a2                	ld	s1,40(sp)
 84a:	7902                	ld	s2,32(sp)
 84c:	69e2                	ld	s3,24(sp)
 84e:	6a42                	ld	s4,16(sp)
 850:	6aa2                	ld	s5,8(sp)
 852:	6b02                	ld	s6,0(sp)
 854:	6121                	addi	sp,sp,64
 856:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 858:	6398                	ld	a4,0(a5)
 85a:	e118                	sd	a4,0(a0)
 85c:	bff1                	j	838 <malloc+0x86>
  hp->s.size = nu;
 85e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 862:	0541                	addi	a0,a0,16
 864:	00000097          	auipc	ra,0x0
 868:	ec6080e7          	jalr	-314(ra) # 72a <free>
  return freep;
 86c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 870:	d971                	beqz	a0,844 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 872:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 874:	4798                	lw	a4,8(a5)
 876:	fa9776e3          	bgeu	a4,s1,822 <malloc+0x70>
    if(p == freep)
 87a:	00093703          	ld	a4,0(s2)
 87e:	853e                	mv	a0,a5
 880:	fef719e3          	bne	a4,a5,872 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 884:	8552                	mv	a0,s4
 886:	00000097          	auipc	ra,0x0
 88a:	b66080e7          	jalr	-1178(ra) # 3ec <sbrk>
  if(p == (char*)-1)
 88e:	fd5518e3          	bne	a0,s5,85e <malloc+0xac>
        return 0;
 892:	4501                	li	a0,0
 894:	bf45                	j	844 <malloc+0x92>
