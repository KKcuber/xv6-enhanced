
user/_init:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

char *argv[] = { "sh", 0 };

int
main(void)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
   c:	4589                	li	a1,2
   e:	00001517          	auipc	a0,0x1
  12:	89250513          	addi	a0,a0,-1902 # 8a0 <malloc+0xe4>
  16:	00000097          	auipc	ra,0x0
  1a:	398080e7          	jalr	920(ra) # 3ae <open>
  1e:	06054363          	bltz	a0,84 <main+0x84>
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  22:	4501                	li	a0,0
  24:	00000097          	auipc	ra,0x0
  28:	3c2080e7          	jalr	962(ra) # 3e6 <dup>
  dup(0);  // stderr
  2c:	4501                	li	a0,0
  2e:	00000097          	auipc	ra,0x0
  32:	3b8080e7          	jalr	952(ra) # 3e6 <dup>

  for(;;){
    printf("init: starting sh\n");
  36:	00001917          	auipc	s2,0x1
  3a:	87290913          	addi	s2,s2,-1934 # 8a8 <malloc+0xec>
  3e:	854a                	mv	a0,s2
  40:	00000097          	auipc	ra,0x0
  44:	6be080e7          	jalr	1726(ra) # 6fe <printf>
    pid = fork();
  48:	00000097          	auipc	ra,0x0
  4c:	31e080e7          	jalr	798(ra) # 366 <fork>
  50:	84aa                	mv	s1,a0
    if(pid < 0){
  52:	04054d63          	bltz	a0,ac <main+0xac>
      printf("init: fork failed\n");
      exit(1);
    }
    if(pid == 0){
  56:	c925                	beqz	a0,c6 <main+0xc6>
    }

    for(;;){
      // this call to wait() returns if the shell exits,
      // or if a parentless process exits.
      wpid = wait((int *) 0);
  58:	4501                	li	a0,0
  5a:	00000097          	auipc	ra,0x0
  5e:	31c080e7          	jalr	796(ra) # 376 <wait>
      if(wpid == pid){
  62:	fca48ee3          	beq	s1,a0,3e <main+0x3e>
        // the shell exited; restart it.
        break;
      } else if(wpid < 0){
  66:	fe0559e3          	bgez	a0,58 <main+0x58>
        printf("init: wait returned an error\n");
  6a:	00001517          	auipc	a0,0x1
  6e:	88e50513          	addi	a0,a0,-1906 # 8f8 <malloc+0x13c>
  72:	00000097          	auipc	ra,0x0
  76:	68c080e7          	jalr	1676(ra) # 6fe <printf>
        exit(1);
  7a:	4505                	li	a0,1
  7c:	00000097          	auipc	ra,0x0
  80:	2f2080e7          	jalr	754(ra) # 36e <exit>
    mknod("console", CONSOLE, 0);
  84:	4601                	li	a2,0
  86:	4585                	li	a1,1
  88:	00001517          	auipc	a0,0x1
  8c:	81850513          	addi	a0,a0,-2024 # 8a0 <malloc+0xe4>
  90:	00000097          	auipc	ra,0x0
  94:	326080e7          	jalr	806(ra) # 3b6 <mknod>
    open("console", O_RDWR);
  98:	4589                	li	a1,2
  9a:	00001517          	auipc	a0,0x1
  9e:	80650513          	addi	a0,a0,-2042 # 8a0 <malloc+0xe4>
  a2:	00000097          	auipc	ra,0x0
  a6:	30c080e7          	jalr	780(ra) # 3ae <open>
  aa:	bfa5                	j	22 <main+0x22>
      printf("init: fork failed\n");
  ac:	00001517          	auipc	a0,0x1
  b0:	81450513          	addi	a0,a0,-2028 # 8c0 <malloc+0x104>
  b4:	00000097          	auipc	ra,0x0
  b8:	64a080e7          	jalr	1610(ra) # 6fe <printf>
      exit(1);
  bc:	4505                	li	a0,1
  be:	00000097          	auipc	ra,0x0
  c2:	2b0080e7          	jalr	688(ra) # 36e <exit>
      exec("sh", argv);
  c6:	00001597          	auipc	a1,0x1
  ca:	87258593          	addi	a1,a1,-1934 # 938 <argv>
  ce:	00001517          	auipc	a0,0x1
  d2:	80a50513          	addi	a0,a0,-2038 # 8d8 <malloc+0x11c>
  d6:	00000097          	auipc	ra,0x0
  da:	2d0080e7          	jalr	720(ra) # 3a6 <exec>
      printf("init: exec sh failed\n");
  de:	00001517          	auipc	a0,0x1
  e2:	80250513          	addi	a0,a0,-2046 # 8e0 <malloc+0x124>
  e6:	00000097          	auipc	ra,0x0
  ea:	618080e7          	jalr	1560(ra) # 6fe <printf>
      exit(1);
  ee:	4505                	li	a0,1
  f0:	00000097          	auipc	ra,0x0
  f4:	27e080e7          	jalr	638(ra) # 36e <exit>

00000000000000f8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  fe:	87aa                	mv	a5,a0
 100:	0585                	addi	a1,a1,1
 102:	0785                	addi	a5,a5,1
 104:	fff5c703          	lbu	a4,-1(a1)
 108:	fee78fa3          	sb	a4,-1(a5)
 10c:	fb75                	bnez	a4,100 <strcpy+0x8>
    ;
  return os;
}
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret

0000000000000114 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cb91                	beqz	a5,132 <strcmp+0x1e>
 120:	0005c703          	lbu	a4,0(a1)
 124:	00f71763          	bne	a4,a5,132 <strcmp+0x1e>
    p++, q++;
 128:	0505                	addi	a0,a0,1
 12a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 12c:	00054783          	lbu	a5,0(a0)
 130:	fbe5                	bnez	a5,120 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 132:	0005c503          	lbu	a0,0(a1)
}
 136:	40a7853b          	subw	a0,a5,a0
 13a:	6422                	ld	s0,8(sp)
 13c:	0141                	addi	sp,sp,16
 13e:	8082                	ret

0000000000000140 <strlen>:

uint
strlen(const char *s)
{
 140:	1141                	addi	sp,sp,-16
 142:	e422                	sd	s0,8(sp)
 144:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 146:	00054783          	lbu	a5,0(a0)
 14a:	cf91                	beqz	a5,166 <strlen+0x26>
 14c:	0505                	addi	a0,a0,1
 14e:	87aa                	mv	a5,a0
 150:	4685                	li	a3,1
 152:	9e89                	subw	a3,a3,a0
 154:	00f6853b          	addw	a0,a3,a5
 158:	0785                	addi	a5,a5,1
 15a:	fff7c703          	lbu	a4,-1(a5)
 15e:	fb7d                	bnez	a4,154 <strlen+0x14>
    ;
  return n;
}
 160:	6422                	ld	s0,8(sp)
 162:	0141                	addi	sp,sp,16
 164:	8082                	ret
  for(n = 0; s[n]; n++)
 166:	4501                	li	a0,0
 168:	bfe5                	j	160 <strlen+0x20>

000000000000016a <memset>:

void*
memset(void *dst, int c, uint n)
{
 16a:	1141                	addi	sp,sp,-16
 16c:	e422                	sd	s0,8(sp)
 16e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 170:	ce09                	beqz	a2,18a <memset+0x20>
 172:	87aa                	mv	a5,a0
 174:	fff6071b          	addiw	a4,a2,-1
 178:	1702                	slli	a4,a4,0x20
 17a:	9301                	srli	a4,a4,0x20
 17c:	0705                	addi	a4,a4,1
 17e:	972a                	add	a4,a4,a0
    cdst[i] = c;
 180:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 184:	0785                	addi	a5,a5,1
 186:	fee79de3          	bne	a5,a4,180 <memset+0x16>
  }
  return dst;
}
 18a:	6422                	ld	s0,8(sp)
 18c:	0141                	addi	sp,sp,16
 18e:	8082                	ret

0000000000000190 <strchr>:

char*
strchr(const char *s, char c)
{
 190:	1141                	addi	sp,sp,-16
 192:	e422                	sd	s0,8(sp)
 194:	0800                	addi	s0,sp,16
  for(; *s; s++)
 196:	00054783          	lbu	a5,0(a0)
 19a:	cb99                	beqz	a5,1b0 <strchr+0x20>
    if(*s == c)
 19c:	00f58763          	beq	a1,a5,1aa <strchr+0x1a>
  for(; *s; s++)
 1a0:	0505                	addi	a0,a0,1
 1a2:	00054783          	lbu	a5,0(a0)
 1a6:	fbfd                	bnez	a5,19c <strchr+0xc>
      return (char*)s;
  return 0;
 1a8:	4501                	li	a0,0
}
 1aa:	6422                	ld	s0,8(sp)
 1ac:	0141                	addi	sp,sp,16
 1ae:	8082                	ret
  return 0;
 1b0:	4501                	li	a0,0
 1b2:	bfe5                	j	1aa <strchr+0x1a>

00000000000001b4 <gets>:

char*
gets(char *buf, int max)
{
 1b4:	711d                	addi	sp,sp,-96
 1b6:	ec86                	sd	ra,88(sp)
 1b8:	e8a2                	sd	s0,80(sp)
 1ba:	e4a6                	sd	s1,72(sp)
 1bc:	e0ca                	sd	s2,64(sp)
 1be:	fc4e                	sd	s3,56(sp)
 1c0:	f852                	sd	s4,48(sp)
 1c2:	f456                	sd	s5,40(sp)
 1c4:	f05a                	sd	s6,32(sp)
 1c6:	ec5e                	sd	s7,24(sp)
 1c8:	1080                	addi	s0,sp,96
 1ca:	8baa                	mv	s7,a0
 1cc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ce:	892a                	mv	s2,a0
 1d0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1d2:	4aa9                	li	s5,10
 1d4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1d6:	89a6                	mv	s3,s1
 1d8:	2485                	addiw	s1,s1,1
 1da:	0344d863          	bge	s1,s4,20a <gets+0x56>
    cc = read(0, &c, 1);
 1de:	4605                	li	a2,1
 1e0:	faf40593          	addi	a1,s0,-81
 1e4:	4501                	li	a0,0
 1e6:	00000097          	auipc	ra,0x0
 1ea:	1a0080e7          	jalr	416(ra) # 386 <read>
    if(cc < 1)
 1ee:	00a05e63          	blez	a0,20a <gets+0x56>
    buf[i++] = c;
 1f2:	faf44783          	lbu	a5,-81(s0)
 1f6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1fa:	01578763          	beq	a5,s5,208 <gets+0x54>
 1fe:	0905                	addi	s2,s2,1
 200:	fd679be3          	bne	a5,s6,1d6 <gets+0x22>
  for(i=0; i+1 < max; ){
 204:	89a6                	mv	s3,s1
 206:	a011                	j	20a <gets+0x56>
 208:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 20a:	99de                	add	s3,s3,s7
 20c:	00098023          	sb	zero,0(s3)
  return buf;
}
 210:	855e                	mv	a0,s7
 212:	60e6                	ld	ra,88(sp)
 214:	6446                	ld	s0,80(sp)
 216:	64a6                	ld	s1,72(sp)
 218:	6906                	ld	s2,64(sp)
 21a:	79e2                	ld	s3,56(sp)
 21c:	7a42                	ld	s4,48(sp)
 21e:	7aa2                	ld	s5,40(sp)
 220:	7b02                	ld	s6,32(sp)
 222:	6be2                	ld	s7,24(sp)
 224:	6125                	addi	sp,sp,96
 226:	8082                	ret

0000000000000228 <stat>:

int
stat(const char *n, struct stat *st)
{
 228:	1101                	addi	sp,sp,-32
 22a:	ec06                	sd	ra,24(sp)
 22c:	e822                	sd	s0,16(sp)
 22e:	e426                	sd	s1,8(sp)
 230:	e04a                	sd	s2,0(sp)
 232:	1000                	addi	s0,sp,32
 234:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 236:	4581                	li	a1,0
 238:	00000097          	auipc	ra,0x0
 23c:	176080e7          	jalr	374(ra) # 3ae <open>
  if(fd < 0)
 240:	02054563          	bltz	a0,26a <stat+0x42>
 244:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 246:	85ca                	mv	a1,s2
 248:	00000097          	auipc	ra,0x0
 24c:	17e080e7          	jalr	382(ra) # 3c6 <fstat>
 250:	892a                	mv	s2,a0
  close(fd);
 252:	8526                	mv	a0,s1
 254:	00000097          	auipc	ra,0x0
 258:	142080e7          	jalr	322(ra) # 396 <close>
  return r;
}
 25c:	854a                	mv	a0,s2
 25e:	60e2                	ld	ra,24(sp)
 260:	6442                	ld	s0,16(sp)
 262:	64a2                	ld	s1,8(sp)
 264:	6902                	ld	s2,0(sp)
 266:	6105                	addi	sp,sp,32
 268:	8082                	ret
    return -1;
 26a:	597d                	li	s2,-1
 26c:	bfc5                	j	25c <stat+0x34>

000000000000026e <atoi>:

int
atoi(const char *s)
{
 26e:	1141                	addi	sp,sp,-16
 270:	e422                	sd	s0,8(sp)
 272:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 274:	00054603          	lbu	a2,0(a0)
 278:	fd06079b          	addiw	a5,a2,-48
 27c:	0ff7f793          	andi	a5,a5,255
 280:	4725                	li	a4,9
 282:	02f76963          	bltu	a4,a5,2b4 <atoi+0x46>
 286:	86aa                	mv	a3,a0
  n = 0;
 288:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 28a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 28c:	0685                	addi	a3,a3,1
 28e:	0025179b          	slliw	a5,a0,0x2
 292:	9fa9                	addw	a5,a5,a0
 294:	0017979b          	slliw	a5,a5,0x1
 298:	9fb1                	addw	a5,a5,a2
 29a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 29e:	0006c603          	lbu	a2,0(a3)
 2a2:	fd06071b          	addiw	a4,a2,-48
 2a6:	0ff77713          	andi	a4,a4,255
 2aa:	fee5f1e3          	bgeu	a1,a4,28c <atoi+0x1e>
  return n;
}
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret
  n = 0;
 2b4:	4501                	li	a0,0
 2b6:	bfe5                	j	2ae <atoi+0x40>

00000000000002b8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2b8:	1141                	addi	sp,sp,-16
 2ba:	e422                	sd	s0,8(sp)
 2bc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2be:	02b57663          	bgeu	a0,a1,2ea <memmove+0x32>
    while(n-- > 0)
 2c2:	02c05163          	blez	a2,2e4 <memmove+0x2c>
 2c6:	fff6079b          	addiw	a5,a2,-1
 2ca:	1782                	slli	a5,a5,0x20
 2cc:	9381                	srli	a5,a5,0x20
 2ce:	0785                	addi	a5,a5,1
 2d0:	97aa                	add	a5,a5,a0
  dst = vdst;
 2d2:	872a                	mv	a4,a0
      *dst++ = *src++;
 2d4:	0585                	addi	a1,a1,1
 2d6:	0705                	addi	a4,a4,1
 2d8:	fff5c683          	lbu	a3,-1(a1)
 2dc:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2e0:	fee79ae3          	bne	a5,a4,2d4 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2e4:	6422                	ld	s0,8(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret
    dst += n;
 2ea:	00c50733          	add	a4,a0,a2
    src += n;
 2ee:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2f0:	fec05ae3          	blez	a2,2e4 <memmove+0x2c>
 2f4:	fff6079b          	addiw	a5,a2,-1
 2f8:	1782                	slli	a5,a5,0x20
 2fa:	9381                	srli	a5,a5,0x20
 2fc:	fff7c793          	not	a5,a5
 300:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 302:	15fd                	addi	a1,a1,-1
 304:	177d                	addi	a4,a4,-1
 306:	0005c683          	lbu	a3,0(a1)
 30a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 30e:	fee79ae3          	bne	a5,a4,302 <memmove+0x4a>
 312:	bfc9                	j	2e4 <memmove+0x2c>

0000000000000314 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 314:	1141                	addi	sp,sp,-16
 316:	e422                	sd	s0,8(sp)
 318:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 31a:	ca05                	beqz	a2,34a <memcmp+0x36>
 31c:	fff6069b          	addiw	a3,a2,-1
 320:	1682                	slli	a3,a3,0x20
 322:	9281                	srli	a3,a3,0x20
 324:	0685                	addi	a3,a3,1
 326:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 328:	00054783          	lbu	a5,0(a0)
 32c:	0005c703          	lbu	a4,0(a1)
 330:	00e79863          	bne	a5,a4,340 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 334:	0505                	addi	a0,a0,1
    p2++;
 336:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 338:	fed518e3          	bne	a0,a3,328 <memcmp+0x14>
  }
  return 0;
 33c:	4501                	li	a0,0
 33e:	a019                	j	344 <memcmp+0x30>
      return *p1 - *p2;
 340:	40e7853b          	subw	a0,a5,a4
}
 344:	6422                	ld	s0,8(sp)
 346:	0141                	addi	sp,sp,16
 348:	8082                	ret
  return 0;
 34a:	4501                	li	a0,0
 34c:	bfe5                	j	344 <memcmp+0x30>

000000000000034e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 34e:	1141                	addi	sp,sp,-16
 350:	e406                	sd	ra,8(sp)
 352:	e022                	sd	s0,0(sp)
 354:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 356:	00000097          	auipc	ra,0x0
 35a:	f62080e7          	jalr	-158(ra) # 2b8 <memmove>
}
 35e:	60a2                	ld	ra,8(sp)
 360:	6402                	ld	s0,0(sp)
 362:	0141                	addi	sp,sp,16
 364:	8082                	ret

0000000000000366 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 366:	4885                	li	a7,1
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <exit>:
.global exit
exit:
 li a7, SYS_exit
 36e:	4889                	li	a7,2
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <wait>:
.global wait
wait:
 li a7, SYS_wait
 376:	488d                	li	a7,3
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 37e:	4891                	li	a7,4
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <read>:
.global read
read:
 li a7, SYS_read
 386:	4895                	li	a7,5
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <write>:
.global write
write:
 li a7, SYS_write
 38e:	48c1                	li	a7,16
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <close>:
.global close
close:
 li a7, SYS_close
 396:	48d5                	li	a7,21
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <kill>:
.global kill
kill:
 li a7, SYS_kill
 39e:	4899                	li	a7,6
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a6:	489d                	li	a7,7
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <open>:
.global open
open:
 li a7, SYS_open
 3ae:	48bd                	li	a7,15
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b6:	48c5                	li	a7,17
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3be:	48c9                	li	a7,18
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c6:	48a1                	li	a7,8
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <link>:
.global link
link:
 li a7, SYS_link
 3ce:	48cd                	li	a7,19
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d6:	48d1                	li	a7,20
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3de:	48a5                	li	a7,9
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e6:	48a9                	li	a7,10
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3ee:	48ad                	li	a7,11
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3f6:	48b1                	li	a7,12
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3fe:	48b5                	li	a7,13
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 406:	48b9                	li	a7,14
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <trace>:
.global trace
trace:
 li a7, SYS_trace
 40e:	48d9                	li	a7,22
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 416:	48dd                	li	a7,23
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 41e:	48e1                	li	a7,24
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 426:	1101                	addi	sp,sp,-32
 428:	ec06                	sd	ra,24(sp)
 42a:	e822                	sd	s0,16(sp)
 42c:	1000                	addi	s0,sp,32
 42e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 432:	4605                	li	a2,1
 434:	fef40593          	addi	a1,s0,-17
 438:	00000097          	auipc	ra,0x0
 43c:	f56080e7          	jalr	-170(ra) # 38e <write>
}
 440:	60e2                	ld	ra,24(sp)
 442:	6442                	ld	s0,16(sp)
 444:	6105                	addi	sp,sp,32
 446:	8082                	ret

0000000000000448 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 448:	7139                	addi	sp,sp,-64
 44a:	fc06                	sd	ra,56(sp)
 44c:	f822                	sd	s0,48(sp)
 44e:	f426                	sd	s1,40(sp)
 450:	f04a                	sd	s2,32(sp)
 452:	ec4e                	sd	s3,24(sp)
 454:	0080                	addi	s0,sp,64
 456:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 458:	c299                	beqz	a3,45e <printint+0x16>
 45a:	0805c863          	bltz	a1,4ea <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 45e:	2581                	sext.w	a1,a1
  neg = 0;
 460:	4881                	li	a7,0
 462:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 466:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 468:	2601                	sext.w	a2,a2
 46a:	00000517          	auipc	a0,0x0
 46e:	4b650513          	addi	a0,a0,1206 # 920 <digits>
 472:	883a                	mv	a6,a4
 474:	2705                	addiw	a4,a4,1
 476:	02c5f7bb          	remuw	a5,a1,a2
 47a:	1782                	slli	a5,a5,0x20
 47c:	9381                	srli	a5,a5,0x20
 47e:	97aa                	add	a5,a5,a0
 480:	0007c783          	lbu	a5,0(a5)
 484:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 488:	0005879b          	sext.w	a5,a1
 48c:	02c5d5bb          	divuw	a1,a1,a2
 490:	0685                	addi	a3,a3,1
 492:	fec7f0e3          	bgeu	a5,a2,472 <printint+0x2a>
  if(neg)
 496:	00088b63          	beqz	a7,4ac <printint+0x64>
    buf[i++] = '-';
 49a:	fd040793          	addi	a5,s0,-48
 49e:	973e                	add	a4,a4,a5
 4a0:	02d00793          	li	a5,45
 4a4:	fef70823          	sb	a5,-16(a4)
 4a8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4ac:	02e05863          	blez	a4,4dc <printint+0x94>
 4b0:	fc040793          	addi	a5,s0,-64
 4b4:	00e78933          	add	s2,a5,a4
 4b8:	fff78993          	addi	s3,a5,-1
 4bc:	99ba                	add	s3,s3,a4
 4be:	377d                	addiw	a4,a4,-1
 4c0:	1702                	slli	a4,a4,0x20
 4c2:	9301                	srli	a4,a4,0x20
 4c4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4c8:	fff94583          	lbu	a1,-1(s2)
 4cc:	8526                	mv	a0,s1
 4ce:	00000097          	auipc	ra,0x0
 4d2:	f58080e7          	jalr	-168(ra) # 426 <putc>
  while(--i >= 0)
 4d6:	197d                	addi	s2,s2,-1
 4d8:	ff3918e3          	bne	s2,s3,4c8 <printint+0x80>
}
 4dc:	70e2                	ld	ra,56(sp)
 4de:	7442                	ld	s0,48(sp)
 4e0:	74a2                	ld	s1,40(sp)
 4e2:	7902                	ld	s2,32(sp)
 4e4:	69e2                	ld	s3,24(sp)
 4e6:	6121                	addi	sp,sp,64
 4e8:	8082                	ret
    x = -xx;
 4ea:	40b005bb          	negw	a1,a1
    neg = 1;
 4ee:	4885                	li	a7,1
    x = -xx;
 4f0:	bf8d                	j	462 <printint+0x1a>

00000000000004f2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4f2:	7119                	addi	sp,sp,-128
 4f4:	fc86                	sd	ra,120(sp)
 4f6:	f8a2                	sd	s0,112(sp)
 4f8:	f4a6                	sd	s1,104(sp)
 4fa:	f0ca                	sd	s2,96(sp)
 4fc:	ecce                	sd	s3,88(sp)
 4fe:	e8d2                	sd	s4,80(sp)
 500:	e4d6                	sd	s5,72(sp)
 502:	e0da                	sd	s6,64(sp)
 504:	fc5e                	sd	s7,56(sp)
 506:	f862                	sd	s8,48(sp)
 508:	f466                	sd	s9,40(sp)
 50a:	f06a                	sd	s10,32(sp)
 50c:	ec6e                	sd	s11,24(sp)
 50e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 510:	0005c903          	lbu	s2,0(a1)
 514:	18090f63          	beqz	s2,6b2 <vprintf+0x1c0>
 518:	8aaa                	mv	s5,a0
 51a:	8b32                	mv	s6,a2
 51c:	00158493          	addi	s1,a1,1
  state = 0;
 520:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 522:	02500a13          	li	s4,37
      if(c == 'd'){
 526:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 52a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 52e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 532:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 536:	00000b97          	auipc	s7,0x0
 53a:	3eab8b93          	addi	s7,s7,1002 # 920 <digits>
 53e:	a839                	j	55c <vprintf+0x6a>
        putc(fd, c);
 540:	85ca                	mv	a1,s2
 542:	8556                	mv	a0,s5
 544:	00000097          	auipc	ra,0x0
 548:	ee2080e7          	jalr	-286(ra) # 426 <putc>
 54c:	a019                	j	552 <vprintf+0x60>
    } else if(state == '%'){
 54e:	01498f63          	beq	s3,s4,56c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 552:	0485                	addi	s1,s1,1
 554:	fff4c903          	lbu	s2,-1(s1)
 558:	14090d63          	beqz	s2,6b2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 55c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 560:	fe0997e3          	bnez	s3,54e <vprintf+0x5c>
      if(c == '%'){
 564:	fd479ee3          	bne	a5,s4,540 <vprintf+0x4e>
        state = '%';
 568:	89be                	mv	s3,a5
 56a:	b7e5                	j	552 <vprintf+0x60>
      if(c == 'd'){
 56c:	05878063          	beq	a5,s8,5ac <vprintf+0xba>
      } else if(c == 'l') {
 570:	05978c63          	beq	a5,s9,5c8 <vprintf+0xd6>
      } else if(c == 'x') {
 574:	07a78863          	beq	a5,s10,5e4 <vprintf+0xf2>
      } else if(c == 'p') {
 578:	09b78463          	beq	a5,s11,600 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 57c:	07300713          	li	a4,115
 580:	0ce78663          	beq	a5,a4,64c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 584:	06300713          	li	a4,99
 588:	0ee78e63          	beq	a5,a4,684 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 58c:	11478863          	beq	a5,s4,69c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 590:	85d2                	mv	a1,s4
 592:	8556                	mv	a0,s5
 594:	00000097          	auipc	ra,0x0
 598:	e92080e7          	jalr	-366(ra) # 426 <putc>
        putc(fd, c);
 59c:	85ca                	mv	a1,s2
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	e86080e7          	jalr	-378(ra) # 426 <putc>
      }
      state = 0;
 5a8:	4981                	li	s3,0
 5aa:	b765                	j	552 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5ac:	008b0913          	addi	s2,s6,8
 5b0:	4685                	li	a3,1
 5b2:	4629                	li	a2,10
 5b4:	000b2583          	lw	a1,0(s6)
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	e8e080e7          	jalr	-370(ra) # 448 <printint>
 5c2:	8b4a                	mv	s6,s2
      state = 0;
 5c4:	4981                	li	s3,0
 5c6:	b771                	j	552 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5c8:	008b0913          	addi	s2,s6,8
 5cc:	4681                	li	a3,0
 5ce:	4629                	li	a2,10
 5d0:	000b2583          	lw	a1,0(s6)
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e72080e7          	jalr	-398(ra) # 448 <printint>
 5de:	8b4a                	mv	s6,s2
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	bf85                	j	552 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5e4:	008b0913          	addi	s2,s6,8
 5e8:	4681                	li	a3,0
 5ea:	4641                	li	a2,16
 5ec:	000b2583          	lw	a1,0(s6)
 5f0:	8556                	mv	a0,s5
 5f2:	00000097          	auipc	ra,0x0
 5f6:	e56080e7          	jalr	-426(ra) # 448 <printint>
 5fa:	8b4a                	mv	s6,s2
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	bf91                	j	552 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 600:	008b0793          	addi	a5,s6,8
 604:	f8f43423          	sd	a5,-120(s0)
 608:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 60c:	03000593          	li	a1,48
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e14080e7          	jalr	-492(ra) # 426 <putc>
  putc(fd, 'x');
 61a:	85ea                	mv	a1,s10
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	e08080e7          	jalr	-504(ra) # 426 <putc>
 626:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 628:	03c9d793          	srli	a5,s3,0x3c
 62c:	97de                	add	a5,a5,s7
 62e:	0007c583          	lbu	a1,0(a5)
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	df2080e7          	jalr	-526(ra) # 426 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 63c:	0992                	slli	s3,s3,0x4
 63e:	397d                	addiw	s2,s2,-1
 640:	fe0914e3          	bnez	s2,628 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 644:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 648:	4981                	li	s3,0
 64a:	b721                	j	552 <vprintf+0x60>
        s = va_arg(ap, char*);
 64c:	008b0993          	addi	s3,s6,8
 650:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 654:	02090163          	beqz	s2,676 <vprintf+0x184>
        while(*s != 0){
 658:	00094583          	lbu	a1,0(s2)
 65c:	c9a1                	beqz	a1,6ac <vprintf+0x1ba>
          putc(fd, *s);
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	dc6080e7          	jalr	-570(ra) # 426 <putc>
          s++;
 668:	0905                	addi	s2,s2,1
        while(*s != 0){
 66a:	00094583          	lbu	a1,0(s2)
 66e:	f9e5                	bnez	a1,65e <vprintf+0x16c>
        s = va_arg(ap, char*);
 670:	8b4e                	mv	s6,s3
      state = 0;
 672:	4981                	li	s3,0
 674:	bdf9                	j	552 <vprintf+0x60>
          s = "(null)";
 676:	00000917          	auipc	s2,0x0
 67a:	2a290913          	addi	s2,s2,674 # 918 <malloc+0x15c>
        while(*s != 0){
 67e:	02800593          	li	a1,40
 682:	bff1                	j	65e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 684:	008b0913          	addi	s2,s6,8
 688:	000b4583          	lbu	a1,0(s6)
 68c:	8556                	mv	a0,s5
 68e:	00000097          	auipc	ra,0x0
 692:	d98080e7          	jalr	-616(ra) # 426 <putc>
 696:	8b4a                	mv	s6,s2
      state = 0;
 698:	4981                	li	s3,0
 69a:	bd65                	j	552 <vprintf+0x60>
        putc(fd, c);
 69c:	85d2                	mv	a1,s4
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	d86080e7          	jalr	-634(ra) # 426 <putc>
      state = 0;
 6a8:	4981                	li	s3,0
 6aa:	b565                	j	552 <vprintf+0x60>
        s = va_arg(ap, char*);
 6ac:	8b4e                	mv	s6,s3
      state = 0;
 6ae:	4981                	li	s3,0
 6b0:	b54d                	j	552 <vprintf+0x60>
    }
  }
}
 6b2:	70e6                	ld	ra,120(sp)
 6b4:	7446                	ld	s0,112(sp)
 6b6:	74a6                	ld	s1,104(sp)
 6b8:	7906                	ld	s2,96(sp)
 6ba:	69e6                	ld	s3,88(sp)
 6bc:	6a46                	ld	s4,80(sp)
 6be:	6aa6                	ld	s5,72(sp)
 6c0:	6b06                	ld	s6,64(sp)
 6c2:	7be2                	ld	s7,56(sp)
 6c4:	7c42                	ld	s8,48(sp)
 6c6:	7ca2                	ld	s9,40(sp)
 6c8:	7d02                	ld	s10,32(sp)
 6ca:	6de2                	ld	s11,24(sp)
 6cc:	6109                	addi	sp,sp,128
 6ce:	8082                	ret

00000000000006d0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6d0:	715d                	addi	sp,sp,-80
 6d2:	ec06                	sd	ra,24(sp)
 6d4:	e822                	sd	s0,16(sp)
 6d6:	1000                	addi	s0,sp,32
 6d8:	e010                	sd	a2,0(s0)
 6da:	e414                	sd	a3,8(s0)
 6dc:	e818                	sd	a4,16(s0)
 6de:	ec1c                	sd	a5,24(s0)
 6e0:	03043023          	sd	a6,32(s0)
 6e4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6e8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6ec:	8622                	mv	a2,s0
 6ee:	00000097          	auipc	ra,0x0
 6f2:	e04080e7          	jalr	-508(ra) # 4f2 <vprintf>
}
 6f6:	60e2                	ld	ra,24(sp)
 6f8:	6442                	ld	s0,16(sp)
 6fa:	6161                	addi	sp,sp,80
 6fc:	8082                	ret

00000000000006fe <printf>:

void
printf(const char *fmt, ...)
{
 6fe:	711d                	addi	sp,sp,-96
 700:	ec06                	sd	ra,24(sp)
 702:	e822                	sd	s0,16(sp)
 704:	1000                	addi	s0,sp,32
 706:	e40c                	sd	a1,8(s0)
 708:	e810                	sd	a2,16(s0)
 70a:	ec14                	sd	a3,24(s0)
 70c:	f018                	sd	a4,32(s0)
 70e:	f41c                	sd	a5,40(s0)
 710:	03043823          	sd	a6,48(s0)
 714:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 718:	00840613          	addi	a2,s0,8
 71c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 720:	85aa                	mv	a1,a0
 722:	4505                	li	a0,1
 724:	00000097          	auipc	ra,0x0
 728:	dce080e7          	jalr	-562(ra) # 4f2 <vprintf>
}
 72c:	60e2                	ld	ra,24(sp)
 72e:	6442                	ld	s0,16(sp)
 730:	6125                	addi	sp,sp,96
 732:	8082                	ret

0000000000000734 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 734:	1141                	addi	sp,sp,-16
 736:	e422                	sd	s0,8(sp)
 738:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 73a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 73e:	00000797          	auipc	a5,0x0
 742:	20a7b783          	ld	a5,522(a5) # 948 <freep>
 746:	a805                	j	776 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 748:	4618                	lw	a4,8(a2)
 74a:	9db9                	addw	a1,a1,a4
 74c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 750:	6398                	ld	a4,0(a5)
 752:	6318                	ld	a4,0(a4)
 754:	fee53823          	sd	a4,-16(a0)
 758:	a091                	j	79c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 75a:	ff852703          	lw	a4,-8(a0)
 75e:	9e39                	addw	a2,a2,a4
 760:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 762:	ff053703          	ld	a4,-16(a0)
 766:	e398                	sd	a4,0(a5)
 768:	a099                	j	7ae <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 76a:	6398                	ld	a4,0(a5)
 76c:	00e7e463          	bltu	a5,a4,774 <free+0x40>
 770:	00e6ea63          	bltu	a3,a4,784 <free+0x50>
{
 774:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 776:	fed7fae3          	bgeu	a5,a3,76a <free+0x36>
 77a:	6398                	ld	a4,0(a5)
 77c:	00e6e463          	bltu	a3,a4,784 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 780:	fee7eae3          	bltu	a5,a4,774 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 784:	ff852583          	lw	a1,-8(a0)
 788:	6390                	ld	a2,0(a5)
 78a:	02059713          	slli	a4,a1,0x20
 78e:	9301                	srli	a4,a4,0x20
 790:	0712                	slli	a4,a4,0x4
 792:	9736                	add	a4,a4,a3
 794:	fae60ae3          	beq	a2,a4,748 <free+0x14>
    bp->s.ptr = p->s.ptr;
 798:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 79c:	4790                	lw	a2,8(a5)
 79e:	02061713          	slli	a4,a2,0x20
 7a2:	9301                	srli	a4,a4,0x20
 7a4:	0712                	slli	a4,a4,0x4
 7a6:	973e                	add	a4,a4,a5
 7a8:	fae689e3          	beq	a3,a4,75a <free+0x26>
  } else
    p->s.ptr = bp;
 7ac:	e394                	sd	a3,0(a5)
  freep = p;
 7ae:	00000717          	auipc	a4,0x0
 7b2:	18f73d23          	sd	a5,410(a4) # 948 <freep>
}
 7b6:	6422                	ld	s0,8(sp)
 7b8:	0141                	addi	sp,sp,16
 7ba:	8082                	ret

00000000000007bc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7bc:	7139                	addi	sp,sp,-64
 7be:	fc06                	sd	ra,56(sp)
 7c0:	f822                	sd	s0,48(sp)
 7c2:	f426                	sd	s1,40(sp)
 7c4:	f04a                	sd	s2,32(sp)
 7c6:	ec4e                	sd	s3,24(sp)
 7c8:	e852                	sd	s4,16(sp)
 7ca:	e456                	sd	s5,8(sp)
 7cc:	e05a                	sd	s6,0(sp)
 7ce:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7d0:	02051493          	slli	s1,a0,0x20
 7d4:	9081                	srli	s1,s1,0x20
 7d6:	04bd                	addi	s1,s1,15
 7d8:	8091                	srli	s1,s1,0x4
 7da:	0014899b          	addiw	s3,s1,1
 7de:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7e0:	00000517          	auipc	a0,0x0
 7e4:	16853503          	ld	a0,360(a0) # 948 <freep>
 7e8:	c515                	beqz	a0,814 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ea:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ec:	4798                	lw	a4,8(a5)
 7ee:	02977f63          	bgeu	a4,s1,82c <malloc+0x70>
 7f2:	8a4e                	mv	s4,s3
 7f4:	0009871b          	sext.w	a4,s3
 7f8:	6685                	lui	a3,0x1
 7fa:	00d77363          	bgeu	a4,a3,800 <malloc+0x44>
 7fe:	6a05                	lui	s4,0x1
 800:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 804:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 808:	00000917          	auipc	s2,0x0
 80c:	14090913          	addi	s2,s2,320 # 948 <freep>
  if(p == (char*)-1)
 810:	5afd                	li	s5,-1
 812:	a88d                	j	884 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 814:	00000797          	auipc	a5,0x0
 818:	13c78793          	addi	a5,a5,316 # 950 <base>
 81c:	00000717          	auipc	a4,0x0
 820:	12f73623          	sd	a5,300(a4) # 948 <freep>
 824:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 826:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 82a:	b7e1                	j	7f2 <malloc+0x36>
      if(p->s.size == nunits)
 82c:	02e48b63          	beq	s1,a4,862 <malloc+0xa6>
        p->s.size -= nunits;
 830:	4137073b          	subw	a4,a4,s3
 834:	c798                	sw	a4,8(a5)
        p += p->s.size;
 836:	1702                	slli	a4,a4,0x20
 838:	9301                	srli	a4,a4,0x20
 83a:	0712                	slli	a4,a4,0x4
 83c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 83e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 842:	00000717          	auipc	a4,0x0
 846:	10a73323          	sd	a0,262(a4) # 948 <freep>
      return (void*)(p + 1);
 84a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 84e:	70e2                	ld	ra,56(sp)
 850:	7442                	ld	s0,48(sp)
 852:	74a2                	ld	s1,40(sp)
 854:	7902                	ld	s2,32(sp)
 856:	69e2                	ld	s3,24(sp)
 858:	6a42                	ld	s4,16(sp)
 85a:	6aa2                	ld	s5,8(sp)
 85c:	6b02                	ld	s6,0(sp)
 85e:	6121                	addi	sp,sp,64
 860:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 862:	6398                	ld	a4,0(a5)
 864:	e118                	sd	a4,0(a0)
 866:	bff1                	j	842 <malloc+0x86>
  hp->s.size = nu;
 868:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 86c:	0541                	addi	a0,a0,16
 86e:	00000097          	auipc	ra,0x0
 872:	ec6080e7          	jalr	-314(ra) # 734 <free>
  return freep;
 876:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 87a:	d971                	beqz	a0,84e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 87c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 87e:	4798                	lw	a4,8(a5)
 880:	fa9776e3          	bgeu	a4,s1,82c <malloc+0x70>
    if(p == freep)
 884:	00093703          	ld	a4,0(s2)
 888:	853e                	mv	a0,a5
 88a:	fef719e3          	bne	a4,a5,87c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 88e:	8552                	mv	a0,s4
 890:	00000097          	auipc	ra,0x0
 894:	b66080e7          	jalr	-1178(ra) # 3f6 <sbrk>
  if(p == (char*)-1)
 898:	fd5518e3          	bne	a0,s5,868 <malloc+0xac>
        return 0;
 89c:	4501                	li	a0,0
 89e:	bf45                	j	84e <malloc+0x92>
