
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/stat.h"
#include "user.h"
#include "../kernel/fcntl.h"

int main(int argc, char **argv)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
   c:	892a                	mv	s2,a0
   e:	84ae                	mv	s1,a1

    strace(atoi(argv[1]));
  10:	6588                	ld	a0,8(a1)
  12:	00000097          	auipc	ra,0x0
  16:	1c4080e7          	jalr	452(ra) # 1d6 <atoi>
  1a:	00000097          	auipc	ra,0x0
  1e:	356080e7          	jalr	854(ra) # 370 <strace>
    if (argc == 1)
  22:	4785                	li	a5,1
  24:	02f90663          	beq	s2,a5,50 <main+0x50>
        sleep(10);
        exit(0);
    }
    else
    {
        exec(argv[2], argv + 2);
  28:	01048593          	addi	a1,s1,16
  2c:	6888                	ld	a0,16(s1)
  2e:	00000097          	auipc	ra,0x0
  32:	2da080e7          	jalr	730(ra) # 308 <exec>
        printf("exec(): failed\n");
  36:	00000517          	auipc	a0,0x0
  3a:	7ca50513          	addi	a0,a0,1994 # 800 <malloc+0xe6>
  3e:	00000097          	auipc	ra,0x0
  42:	624080e7          	jalr	1572(ra) # 662 <printf>
        exit(1);
  46:	4505                	li	a0,1
  48:	00000097          	auipc	ra,0x0
  4c:	288080e7          	jalr	648(ra) # 2d0 <exit>
        sleep(10);
  50:	4529                	li	a0,10
  52:	00000097          	auipc	ra,0x0
  56:	30e080e7          	jalr	782(ra) # 360 <sleep>
        exit(0);
  5a:	4501                	li	a0,0
  5c:	00000097          	auipc	ra,0x0
  60:	274080e7          	jalr	628(ra) # 2d0 <exit>

0000000000000064 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  64:	1141                	addi	sp,sp,-16
  66:	e422                	sd	s0,8(sp)
  68:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  6a:	87aa                	mv	a5,a0
  6c:	0585                	addi	a1,a1,1
  6e:	0785                	addi	a5,a5,1
  70:	fff5c703          	lbu	a4,-1(a1)
  74:	fee78fa3          	sb	a4,-1(a5)
  78:	fb75                	bnez	a4,6c <strcpy+0x8>
    ;
  return os;
}
  7a:	6422                	ld	s0,8(sp)
  7c:	0141                	addi	sp,sp,16
  7e:	8082                	ret

0000000000000080 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80:	1141                	addi	sp,sp,-16
  82:	e422                	sd	s0,8(sp)
  84:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  86:	00054783          	lbu	a5,0(a0)
  8a:	cb91                	beqz	a5,9e <strcmp+0x1e>
  8c:	0005c703          	lbu	a4,0(a1)
  90:	00f71763          	bne	a4,a5,9e <strcmp+0x1e>
    p++, q++;
  94:	0505                	addi	a0,a0,1
  96:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  98:	00054783          	lbu	a5,0(a0)
  9c:	fbe5                	bnez	a5,8c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  9e:	0005c503          	lbu	a0,0(a1)
}
  a2:	40a7853b          	subw	a0,a5,a0
  a6:	6422                	ld	s0,8(sp)
  a8:	0141                	addi	sp,sp,16
  aa:	8082                	ret

00000000000000ac <strlen>:

uint
strlen(const char *s)
{
  ac:	1141                	addi	sp,sp,-16
  ae:	e422                	sd	s0,8(sp)
  b0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  b2:	00054783          	lbu	a5,0(a0)
  b6:	cf91                	beqz	a5,d2 <strlen+0x26>
  b8:	0505                	addi	a0,a0,1
  ba:	87aa                	mv	a5,a0
  bc:	4685                	li	a3,1
  be:	9e89                	subw	a3,a3,a0
  c0:	00f6853b          	addw	a0,a3,a5
  c4:	0785                	addi	a5,a5,1
  c6:	fff7c703          	lbu	a4,-1(a5)
  ca:	fb7d                	bnez	a4,c0 <strlen+0x14>
    ;
  return n;
}
  cc:	6422                	ld	s0,8(sp)
  ce:	0141                	addi	sp,sp,16
  d0:	8082                	ret
  for(n = 0; s[n]; n++)
  d2:	4501                	li	a0,0
  d4:	bfe5                	j	cc <strlen+0x20>

00000000000000d6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  d6:	1141                	addi	sp,sp,-16
  d8:	e422                	sd	s0,8(sp)
  da:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  dc:	ca19                	beqz	a2,f2 <memset+0x1c>
  de:	87aa                	mv	a5,a0
  e0:	1602                	slli	a2,a2,0x20
  e2:	9201                	srli	a2,a2,0x20
  e4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  e8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  ec:	0785                	addi	a5,a5,1
  ee:	fee79de3          	bne	a5,a4,e8 <memset+0x12>
  }
  return dst;
}
  f2:	6422                	ld	s0,8(sp)
  f4:	0141                	addi	sp,sp,16
  f6:	8082                	ret

00000000000000f8 <strchr>:

char*
strchr(const char *s, char c)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  for(; *s; s++)
  fe:	00054783          	lbu	a5,0(a0)
 102:	cb99                	beqz	a5,118 <strchr+0x20>
    if(*s == c)
 104:	00f58763          	beq	a1,a5,112 <strchr+0x1a>
  for(; *s; s++)
 108:	0505                	addi	a0,a0,1
 10a:	00054783          	lbu	a5,0(a0)
 10e:	fbfd                	bnez	a5,104 <strchr+0xc>
      return (char*)s;
  return 0;
 110:	4501                	li	a0,0
}
 112:	6422                	ld	s0,8(sp)
 114:	0141                	addi	sp,sp,16
 116:	8082                	ret
  return 0;
 118:	4501                	li	a0,0
 11a:	bfe5                	j	112 <strchr+0x1a>

000000000000011c <gets>:

char*
gets(char *buf, int max)
{
 11c:	711d                	addi	sp,sp,-96
 11e:	ec86                	sd	ra,88(sp)
 120:	e8a2                	sd	s0,80(sp)
 122:	e4a6                	sd	s1,72(sp)
 124:	e0ca                	sd	s2,64(sp)
 126:	fc4e                	sd	s3,56(sp)
 128:	f852                	sd	s4,48(sp)
 12a:	f456                	sd	s5,40(sp)
 12c:	f05a                	sd	s6,32(sp)
 12e:	ec5e                	sd	s7,24(sp)
 130:	1080                	addi	s0,sp,96
 132:	8baa                	mv	s7,a0
 134:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 136:	892a                	mv	s2,a0
 138:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 13a:	4aa9                	li	s5,10
 13c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 13e:	89a6                	mv	s3,s1
 140:	2485                	addiw	s1,s1,1
 142:	0344d863          	bge	s1,s4,172 <gets+0x56>
    cc = read(0, &c, 1);
 146:	4605                	li	a2,1
 148:	faf40593          	addi	a1,s0,-81
 14c:	4501                	li	a0,0
 14e:	00000097          	auipc	ra,0x0
 152:	19a080e7          	jalr	410(ra) # 2e8 <read>
    if(cc < 1)
 156:	00a05e63          	blez	a0,172 <gets+0x56>
    buf[i++] = c;
 15a:	faf44783          	lbu	a5,-81(s0)
 15e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 162:	01578763          	beq	a5,s5,170 <gets+0x54>
 166:	0905                	addi	s2,s2,1
 168:	fd679be3          	bne	a5,s6,13e <gets+0x22>
  for(i=0; i+1 < max; ){
 16c:	89a6                	mv	s3,s1
 16e:	a011                	j	172 <gets+0x56>
 170:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 172:	99de                	add	s3,s3,s7
 174:	00098023          	sb	zero,0(s3)
  return buf;
}
 178:	855e                	mv	a0,s7
 17a:	60e6                	ld	ra,88(sp)
 17c:	6446                	ld	s0,80(sp)
 17e:	64a6                	ld	s1,72(sp)
 180:	6906                	ld	s2,64(sp)
 182:	79e2                	ld	s3,56(sp)
 184:	7a42                	ld	s4,48(sp)
 186:	7aa2                	ld	s5,40(sp)
 188:	7b02                	ld	s6,32(sp)
 18a:	6be2                	ld	s7,24(sp)
 18c:	6125                	addi	sp,sp,96
 18e:	8082                	ret

0000000000000190 <stat>:

int
stat(const char *n, struct stat *st)
{
 190:	1101                	addi	sp,sp,-32
 192:	ec06                	sd	ra,24(sp)
 194:	e822                	sd	s0,16(sp)
 196:	e426                	sd	s1,8(sp)
 198:	e04a                	sd	s2,0(sp)
 19a:	1000                	addi	s0,sp,32
 19c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 19e:	4581                	li	a1,0
 1a0:	00000097          	auipc	ra,0x0
 1a4:	170080e7          	jalr	368(ra) # 310 <open>
  if(fd < 0)
 1a8:	02054563          	bltz	a0,1d2 <stat+0x42>
 1ac:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ae:	85ca                	mv	a1,s2
 1b0:	00000097          	auipc	ra,0x0
 1b4:	178080e7          	jalr	376(ra) # 328 <fstat>
 1b8:	892a                	mv	s2,a0
  close(fd);
 1ba:	8526                	mv	a0,s1
 1bc:	00000097          	auipc	ra,0x0
 1c0:	13c080e7          	jalr	316(ra) # 2f8 <close>
  return r;
}
 1c4:	854a                	mv	a0,s2
 1c6:	60e2                	ld	ra,24(sp)
 1c8:	6442                	ld	s0,16(sp)
 1ca:	64a2                	ld	s1,8(sp)
 1cc:	6902                	ld	s2,0(sp)
 1ce:	6105                	addi	sp,sp,32
 1d0:	8082                	ret
    return -1;
 1d2:	597d                	li	s2,-1
 1d4:	bfc5                	j	1c4 <stat+0x34>

00000000000001d6 <atoi>:

int
atoi(const char *s)
{
 1d6:	1141                	addi	sp,sp,-16
 1d8:	e422                	sd	s0,8(sp)
 1da:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1dc:	00054683          	lbu	a3,0(a0)
 1e0:	fd06879b          	addiw	a5,a3,-48
 1e4:	0ff7f793          	zext.b	a5,a5
 1e8:	4625                	li	a2,9
 1ea:	02f66863          	bltu	a2,a5,21a <atoi+0x44>
 1ee:	872a                	mv	a4,a0
  n = 0;
 1f0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1f2:	0705                	addi	a4,a4,1
 1f4:	0025179b          	slliw	a5,a0,0x2
 1f8:	9fa9                	addw	a5,a5,a0
 1fa:	0017979b          	slliw	a5,a5,0x1
 1fe:	9fb5                	addw	a5,a5,a3
 200:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 204:	00074683          	lbu	a3,0(a4)
 208:	fd06879b          	addiw	a5,a3,-48
 20c:	0ff7f793          	zext.b	a5,a5
 210:	fef671e3          	bgeu	a2,a5,1f2 <atoi+0x1c>
  return n;
}
 214:	6422                	ld	s0,8(sp)
 216:	0141                	addi	sp,sp,16
 218:	8082                	ret
  n = 0;
 21a:	4501                	li	a0,0
 21c:	bfe5                	j	214 <atoi+0x3e>

000000000000021e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 21e:	1141                	addi	sp,sp,-16
 220:	e422                	sd	s0,8(sp)
 222:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 224:	02b57463          	bgeu	a0,a1,24c <memmove+0x2e>
    while(n-- > 0)
 228:	00c05f63          	blez	a2,246 <memmove+0x28>
 22c:	1602                	slli	a2,a2,0x20
 22e:	9201                	srli	a2,a2,0x20
 230:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 234:	872a                	mv	a4,a0
      *dst++ = *src++;
 236:	0585                	addi	a1,a1,1
 238:	0705                	addi	a4,a4,1
 23a:	fff5c683          	lbu	a3,-1(a1)
 23e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 242:	fee79ae3          	bne	a5,a4,236 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 246:	6422                	ld	s0,8(sp)
 248:	0141                	addi	sp,sp,16
 24a:	8082                	ret
    dst += n;
 24c:	00c50733          	add	a4,a0,a2
    src += n;
 250:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 252:	fec05ae3          	blez	a2,246 <memmove+0x28>
 256:	fff6079b          	addiw	a5,a2,-1
 25a:	1782                	slli	a5,a5,0x20
 25c:	9381                	srli	a5,a5,0x20
 25e:	fff7c793          	not	a5,a5
 262:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 264:	15fd                	addi	a1,a1,-1
 266:	177d                	addi	a4,a4,-1
 268:	0005c683          	lbu	a3,0(a1)
 26c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 270:	fee79ae3          	bne	a5,a4,264 <memmove+0x46>
 274:	bfc9                	j	246 <memmove+0x28>

0000000000000276 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 276:	1141                	addi	sp,sp,-16
 278:	e422                	sd	s0,8(sp)
 27a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 27c:	ca05                	beqz	a2,2ac <memcmp+0x36>
 27e:	fff6069b          	addiw	a3,a2,-1
 282:	1682                	slli	a3,a3,0x20
 284:	9281                	srli	a3,a3,0x20
 286:	0685                	addi	a3,a3,1
 288:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 28a:	00054783          	lbu	a5,0(a0)
 28e:	0005c703          	lbu	a4,0(a1)
 292:	00e79863          	bne	a5,a4,2a2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 296:	0505                	addi	a0,a0,1
    p2++;
 298:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 29a:	fed518e3          	bne	a0,a3,28a <memcmp+0x14>
  }
  return 0;
 29e:	4501                	li	a0,0
 2a0:	a019                	j	2a6 <memcmp+0x30>
      return *p1 - *p2;
 2a2:	40e7853b          	subw	a0,a5,a4
}
 2a6:	6422                	ld	s0,8(sp)
 2a8:	0141                	addi	sp,sp,16
 2aa:	8082                	ret
  return 0;
 2ac:	4501                	li	a0,0
 2ae:	bfe5                	j	2a6 <memcmp+0x30>

00000000000002b0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2b0:	1141                	addi	sp,sp,-16
 2b2:	e406                	sd	ra,8(sp)
 2b4:	e022                	sd	s0,0(sp)
 2b6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2b8:	00000097          	auipc	ra,0x0
 2bc:	f66080e7          	jalr	-154(ra) # 21e <memmove>
}
 2c0:	60a2                	ld	ra,8(sp)
 2c2:	6402                	ld	s0,0(sp)
 2c4:	0141                	addi	sp,sp,16
 2c6:	8082                	ret

00000000000002c8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2c8:	4885                	li	a7,1
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2d0:	4889                	li	a7,2
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2d8:	488d                	li	a7,3
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2e0:	4891                	li	a7,4
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <read>:
.global read
read:
 li a7, SYS_read
 2e8:	4895                	li	a7,5
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <write>:
.global write
write:
 li a7, SYS_write
 2f0:	48c1                	li	a7,16
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <close>:
.global close
close:
 li a7, SYS_close
 2f8:	48d5                	li	a7,21
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <kill>:
.global kill
kill:
 li a7, SYS_kill
 300:	4899                	li	a7,6
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <exec>:
.global exec
exec:
 li a7, SYS_exec
 308:	489d                	li	a7,7
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <open>:
.global open
open:
 li a7, SYS_open
 310:	48bd                	li	a7,15
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 318:	48c5                	li	a7,17
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 320:	48c9                	li	a7,18
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 328:	48a1                	li	a7,8
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <link>:
.global link
link:
 li a7, SYS_link
 330:	48cd                	li	a7,19
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 338:	48d1                	li	a7,20
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 340:	48a5                	li	a7,9
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <dup>:
.global dup
dup:
 li a7, SYS_dup
 348:	48a9                	li	a7,10
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 350:	48ad                	li	a7,11
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 358:	48b1                	li	a7,12
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 360:	48b5                	li	a7,13
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 368:	48b9                	li	a7,14
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <strace>:
.global strace
strace:
 li a7, SYS_strace
 370:	48d9                	li	a7,22
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 378:	48dd                	li	a7,23
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <setpriority>:
.global setpriority
setpriority:
 li a7, SYS_setpriority
 380:	48e1                	li	a7,24
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 388:	1101                	addi	sp,sp,-32
 38a:	ec06                	sd	ra,24(sp)
 38c:	e822                	sd	s0,16(sp)
 38e:	1000                	addi	s0,sp,32
 390:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 394:	4605                	li	a2,1
 396:	fef40593          	addi	a1,s0,-17
 39a:	00000097          	auipc	ra,0x0
 39e:	f56080e7          	jalr	-170(ra) # 2f0 <write>
}
 3a2:	60e2                	ld	ra,24(sp)
 3a4:	6442                	ld	s0,16(sp)
 3a6:	6105                	addi	sp,sp,32
 3a8:	8082                	ret

00000000000003aa <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3aa:	7139                	addi	sp,sp,-64
 3ac:	fc06                	sd	ra,56(sp)
 3ae:	f822                	sd	s0,48(sp)
 3b0:	f426                	sd	s1,40(sp)
 3b2:	f04a                	sd	s2,32(sp)
 3b4:	ec4e                	sd	s3,24(sp)
 3b6:	0080                	addi	s0,sp,64
 3b8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ba:	c299                	beqz	a3,3c0 <printint+0x16>
 3bc:	0805c963          	bltz	a1,44e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3c0:	2581                	sext.w	a1,a1
  neg = 0;
 3c2:	4881                	li	a7,0
 3c4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3c8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3ca:	2601                	sext.w	a2,a2
 3cc:	00000517          	auipc	a0,0x0
 3d0:	4a450513          	addi	a0,a0,1188 # 870 <digits>
 3d4:	883a                	mv	a6,a4
 3d6:	2705                	addiw	a4,a4,1
 3d8:	02c5f7bb          	remuw	a5,a1,a2
 3dc:	1782                	slli	a5,a5,0x20
 3de:	9381                	srli	a5,a5,0x20
 3e0:	97aa                	add	a5,a5,a0
 3e2:	0007c783          	lbu	a5,0(a5)
 3e6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ea:	0005879b          	sext.w	a5,a1
 3ee:	02c5d5bb          	divuw	a1,a1,a2
 3f2:	0685                	addi	a3,a3,1
 3f4:	fec7f0e3          	bgeu	a5,a2,3d4 <printint+0x2a>
  if(neg)
 3f8:	00088c63          	beqz	a7,410 <printint+0x66>
    buf[i++] = '-';
 3fc:	fd070793          	addi	a5,a4,-48
 400:	00878733          	add	a4,a5,s0
 404:	02d00793          	li	a5,45
 408:	fef70823          	sb	a5,-16(a4)
 40c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 410:	02e05863          	blez	a4,440 <printint+0x96>
 414:	fc040793          	addi	a5,s0,-64
 418:	00e78933          	add	s2,a5,a4
 41c:	fff78993          	addi	s3,a5,-1
 420:	99ba                	add	s3,s3,a4
 422:	377d                	addiw	a4,a4,-1
 424:	1702                	slli	a4,a4,0x20
 426:	9301                	srli	a4,a4,0x20
 428:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 42c:	fff94583          	lbu	a1,-1(s2)
 430:	8526                	mv	a0,s1
 432:	00000097          	auipc	ra,0x0
 436:	f56080e7          	jalr	-170(ra) # 388 <putc>
  while(--i >= 0)
 43a:	197d                	addi	s2,s2,-1
 43c:	ff3918e3          	bne	s2,s3,42c <printint+0x82>
}
 440:	70e2                	ld	ra,56(sp)
 442:	7442                	ld	s0,48(sp)
 444:	74a2                	ld	s1,40(sp)
 446:	7902                	ld	s2,32(sp)
 448:	69e2                	ld	s3,24(sp)
 44a:	6121                	addi	sp,sp,64
 44c:	8082                	ret
    x = -xx;
 44e:	40b005bb          	negw	a1,a1
    neg = 1;
 452:	4885                	li	a7,1
    x = -xx;
 454:	bf85                	j	3c4 <printint+0x1a>

0000000000000456 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 456:	7119                	addi	sp,sp,-128
 458:	fc86                	sd	ra,120(sp)
 45a:	f8a2                	sd	s0,112(sp)
 45c:	f4a6                	sd	s1,104(sp)
 45e:	f0ca                	sd	s2,96(sp)
 460:	ecce                	sd	s3,88(sp)
 462:	e8d2                	sd	s4,80(sp)
 464:	e4d6                	sd	s5,72(sp)
 466:	e0da                	sd	s6,64(sp)
 468:	fc5e                	sd	s7,56(sp)
 46a:	f862                	sd	s8,48(sp)
 46c:	f466                	sd	s9,40(sp)
 46e:	f06a                	sd	s10,32(sp)
 470:	ec6e                	sd	s11,24(sp)
 472:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 474:	0005c903          	lbu	s2,0(a1)
 478:	18090f63          	beqz	s2,616 <vprintf+0x1c0>
 47c:	8aaa                	mv	s5,a0
 47e:	8b32                	mv	s6,a2
 480:	00158493          	addi	s1,a1,1
  state = 0;
 484:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 486:	02500a13          	li	s4,37
 48a:	4c55                	li	s8,21
 48c:	00000c97          	auipc	s9,0x0
 490:	38cc8c93          	addi	s9,s9,908 # 818 <malloc+0xfe>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 494:	02800d93          	li	s11,40
  putc(fd, 'x');
 498:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 49a:	00000b97          	auipc	s7,0x0
 49e:	3d6b8b93          	addi	s7,s7,982 # 870 <digits>
 4a2:	a839                	j	4c0 <vprintf+0x6a>
        putc(fd, c);
 4a4:	85ca                	mv	a1,s2
 4a6:	8556                	mv	a0,s5
 4a8:	00000097          	auipc	ra,0x0
 4ac:	ee0080e7          	jalr	-288(ra) # 388 <putc>
 4b0:	a019                	j	4b6 <vprintf+0x60>
    } else if(state == '%'){
 4b2:	01498d63          	beq	s3,s4,4cc <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4b6:	0485                	addi	s1,s1,1
 4b8:	fff4c903          	lbu	s2,-1(s1)
 4bc:	14090d63          	beqz	s2,616 <vprintf+0x1c0>
    if(state == 0){
 4c0:	fe0999e3          	bnez	s3,4b2 <vprintf+0x5c>
      if(c == '%'){
 4c4:	ff4910e3          	bne	s2,s4,4a4 <vprintf+0x4e>
        state = '%';
 4c8:	89d2                	mv	s3,s4
 4ca:	b7f5                	j	4b6 <vprintf+0x60>
      if(c == 'd'){
 4cc:	11490c63          	beq	s2,s4,5e4 <vprintf+0x18e>
 4d0:	f9d9079b          	addiw	a5,s2,-99
 4d4:	0ff7f793          	zext.b	a5,a5
 4d8:	10fc6e63          	bltu	s8,a5,5f4 <vprintf+0x19e>
 4dc:	f9d9079b          	addiw	a5,s2,-99
 4e0:	0ff7f713          	zext.b	a4,a5
 4e4:	10ec6863          	bltu	s8,a4,5f4 <vprintf+0x19e>
 4e8:	00271793          	slli	a5,a4,0x2
 4ec:	97e6                	add	a5,a5,s9
 4ee:	439c                	lw	a5,0(a5)
 4f0:	97e6                	add	a5,a5,s9
 4f2:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4f4:	008b0913          	addi	s2,s6,8
 4f8:	4685                	li	a3,1
 4fa:	4629                	li	a2,10
 4fc:	000b2583          	lw	a1,0(s6)
 500:	8556                	mv	a0,s5
 502:	00000097          	auipc	ra,0x0
 506:	ea8080e7          	jalr	-344(ra) # 3aa <printint>
 50a:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 50c:	4981                	li	s3,0
 50e:	b765                	j	4b6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 510:	008b0913          	addi	s2,s6,8
 514:	4681                	li	a3,0
 516:	4629                	li	a2,10
 518:	000b2583          	lw	a1,0(s6)
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	e8c080e7          	jalr	-372(ra) # 3aa <printint>
 526:	8b4a                	mv	s6,s2
      state = 0;
 528:	4981                	li	s3,0
 52a:	b771                	j	4b6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 52c:	008b0913          	addi	s2,s6,8
 530:	4681                	li	a3,0
 532:	866a                	mv	a2,s10
 534:	000b2583          	lw	a1,0(s6)
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	e70080e7          	jalr	-400(ra) # 3aa <printint>
 542:	8b4a                	mv	s6,s2
      state = 0;
 544:	4981                	li	s3,0
 546:	bf85                	j	4b6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 548:	008b0793          	addi	a5,s6,8
 54c:	f8f43423          	sd	a5,-120(s0)
 550:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 554:	03000593          	li	a1,48
 558:	8556                	mv	a0,s5
 55a:	00000097          	auipc	ra,0x0
 55e:	e2e080e7          	jalr	-466(ra) # 388 <putc>
  putc(fd, 'x');
 562:	07800593          	li	a1,120
 566:	8556                	mv	a0,s5
 568:	00000097          	auipc	ra,0x0
 56c:	e20080e7          	jalr	-480(ra) # 388 <putc>
 570:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 572:	03c9d793          	srli	a5,s3,0x3c
 576:	97de                	add	a5,a5,s7
 578:	0007c583          	lbu	a1,0(a5)
 57c:	8556                	mv	a0,s5
 57e:	00000097          	auipc	ra,0x0
 582:	e0a080e7          	jalr	-502(ra) # 388 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 586:	0992                	slli	s3,s3,0x4
 588:	397d                	addiw	s2,s2,-1
 58a:	fe0914e3          	bnez	s2,572 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 58e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 592:	4981                	li	s3,0
 594:	b70d                	j	4b6 <vprintf+0x60>
        s = va_arg(ap, char*);
 596:	008b0913          	addi	s2,s6,8
 59a:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 59e:	02098163          	beqz	s3,5c0 <vprintf+0x16a>
        while(*s != 0){
 5a2:	0009c583          	lbu	a1,0(s3)
 5a6:	c5ad                	beqz	a1,610 <vprintf+0x1ba>
          putc(fd, *s);
 5a8:	8556                	mv	a0,s5
 5aa:	00000097          	auipc	ra,0x0
 5ae:	dde080e7          	jalr	-546(ra) # 388 <putc>
          s++;
 5b2:	0985                	addi	s3,s3,1
        while(*s != 0){
 5b4:	0009c583          	lbu	a1,0(s3)
 5b8:	f9e5                	bnez	a1,5a8 <vprintf+0x152>
        s = va_arg(ap, char*);
 5ba:	8b4a                	mv	s6,s2
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	bde5                	j	4b6 <vprintf+0x60>
          s = "(null)";
 5c0:	00000997          	auipc	s3,0x0
 5c4:	25098993          	addi	s3,s3,592 # 810 <malloc+0xf6>
        while(*s != 0){
 5c8:	85ee                	mv	a1,s11
 5ca:	bff9                	j	5a8 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5cc:	008b0913          	addi	s2,s6,8
 5d0:	000b4583          	lbu	a1,0(s6)
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	db2080e7          	jalr	-590(ra) # 388 <putc>
 5de:	8b4a                	mv	s6,s2
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	bdd1                	j	4b6 <vprintf+0x60>
        putc(fd, c);
 5e4:	85d2                	mv	a1,s4
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	da0080e7          	jalr	-608(ra) # 388 <putc>
      state = 0;
 5f0:	4981                	li	s3,0
 5f2:	b5d1                	j	4b6 <vprintf+0x60>
        putc(fd, '%');
 5f4:	85d2                	mv	a1,s4
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	d90080e7          	jalr	-624(ra) # 388 <putc>
        putc(fd, c);
 600:	85ca                	mv	a1,s2
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	d84080e7          	jalr	-636(ra) # 388 <putc>
      state = 0;
 60c:	4981                	li	s3,0
 60e:	b565                	j	4b6 <vprintf+0x60>
        s = va_arg(ap, char*);
 610:	8b4a                	mv	s6,s2
      state = 0;
 612:	4981                	li	s3,0
 614:	b54d                	j	4b6 <vprintf+0x60>
    }
  }
}
 616:	70e6                	ld	ra,120(sp)
 618:	7446                	ld	s0,112(sp)
 61a:	74a6                	ld	s1,104(sp)
 61c:	7906                	ld	s2,96(sp)
 61e:	69e6                	ld	s3,88(sp)
 620:	6a46                	ld	s4,80(sp)
 622:	6aa6                	ld	s5,72(sp)
 624:	6b06                	ld	s6,64(sp)
 626:	7be2                	ld	s7,56(sp)
 628:	7c42                	ld	s8,48(sp)
 62a:	7ca2                	ld	s9,40(sp)
 62c:	7d02                	ld	s10,32(sp)
 62e:	6de2                	ld	s11,24(sp)
 630:	6109                	addi	sp,sp,128
 632:	8082                	ret

0000000000000634 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 634:	715d                	addi	sp,sp,-80
 636:	ec06                	sd	ra,24(sp)
 638:	e822                	sd	s0,16(sp)
 63a:	1000                	addi	s0,sp,32
 63c:	e010                	sd	a2,0(s0)
 63e:	e414                	sd	a3,8(s0)
 640:	e818                	sd	a4,16(s0)
 642:	ec1c                	sd	a5,24(s0)
 644:	03043023          	sd	a6,32(s0)
 648:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 64c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 650:	8622                	mv	a2,s0
 652:	00000097          	auipc	ra,0x0
 656:	e04080e7          	jalr	-508(ra) # 456 <vprintf>
}
 65a:	60e2                	ld	ra,24(sp)
 65c:	6442                	ld	s0,16(sp)
 65e:	6161                	addi	sp,sp,80
 660:	8082                	ret

0000000000000662 <printf>:

void
printf(const char *fmt, ...)
{
 662:	711d                	addi	sp,sp,-96
 664:	ec06                	sd	ra,24(sp)
 666:	e822                	sd	s0,16(sp)
 668:	1000                	addi	s0,sp,32
 66a:	e40c                	sd	a1,8(s0)
 66c:	e810                	sd	a2,16(s0)
 66e:	ec14                	sd	a3,24(s0)
 670:	f018                	sd	a4,32(s0)
 672:	f41c                	sd	a5,40(s0)
 674:	03043823          	sd	a6,48(s0)
 678:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 67c:	00840613          	addi	a2,s0,8
 680:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 684:	85aa                	mv	a1,a0
 686:	4505                	li	a0,1
 688:	00000097          	auipc	ra,0x0
 68c:	dce080e7          	jalr	-562(ra) # 456 <vprintf>
}
 690:	60e2                	ld	ra,24(sp)
 692:	6442                	ld	s0,16(sp)
 694:	6125                	addi	sp,sp,96
 696:	8082                	ret

0000000000000698 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 698:	1141                	addi	sp,sp,-16
 69a:	e422                	sd	s0,8(sp)
 69c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 69e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a2:	00000797          	auipc	a5,0x0
 6a6:	1e67b783          	ld	a5,486(a5) # 888 <freep>
 6aa:	a02d                	j	6d4 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6ac:	4618                	lw	a4,8(a2)
 6ae:	9f2d                	addw	a4,a4,a1
 6b0:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b4:	6398                	ld	a4,0(a5)
 6b6:	6310                	ld	a2,0(a4)
 6b8:	a83d                	j	6f6 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6ba:	ff852703          	lw	a4,-8(a0)
 6be:	9f31                	addw	a4,a4,a2
 6c0:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6c2:	ff053683          	ld	a3,-16(a0)
 6c6:	a091                	j	70a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6c8:	6398                	ld	a4,0(a5)
 6ca:	00e7e463          	bltu	a5,a4,6d2 <free+0x3a>
 6ce:	00e6ea63          	bltu	a3,a4,6e2 <free+0x4a>
{
 6d2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d4:	fed7fae3          	bgeu	a5,a3,6c8 <free+0x30>
 6d8:	6398                	ld	a4,0(a5)
 6da:	00e6e463          	bltu	a3,a4,6e2 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6de:	fee7eae3          	bltu	a5,a4,6d2 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6e2:	ff852583          	lw	a1,-8(a0)
 6e6:	6390                	ld	a2,0(a5)
 6e8:	02059813          	slli	a6,a1,0x20
 6ec:	01c85713          	srli	a4,a6,0x1c
 6f0:	9736                	add	a4,a4,a3
 6f2:	fae60de3          	beq	a2,a4,6ac <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6f6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6fa:	4790                	lw	a2,8(a5)
 6fc:	02061593          	slli	a1,a2,0x20
 700:	01c5d713          	srli	a4,a1,0x1c
 704:	973e                	add	a4,a4,a5
 706:	fae68ae3          	beq	a3,a4,6ba <free+0x22>
    p->s.ptr = bp->s.ptr;
 70a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 70c:	00000717          	auipc	a4,0x0
 710:	16f73e23          	sd	a5,380(a4) # 888 <freep>
}
 714:	6422                	ld	s0,8(sp)
 716:	0141                	addi	sp,sp,16
 718:	8082                	ret

000000000000071a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 71a:	7139                	addi	sp,sp,-64
 71c:	fc06                	sd	ra,56(sp)
 71e:	f822                	sd	s0,48(sp)
 720:	f426                	sd	s1,40(sp)
 722:	f04a                	sd	s2,32(sp)
 724:	ec4e                	sd	s3,24(sp)
 726:	e852                	sd	s4,16(sp)
 728:	e456                	sd	s5,8(sp)
 72a:	e05a                	sd	s6,0(sp)
 72c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 72e:	02051493          	slli	s1,a0,0x20
 732:	9081                	srli	s1,s1,0x20
 734:	04bd                	addi	s1,s1,15
 736:	8091                	srli	s1,s1,0x4
 738:	0014899b          	addiw	s3,s1,1
 73c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 73e:	00000517          	auipc	a0,0x0
 742:	14a53503          	ld	a0,330(a0) # 888 <freep>
 746:	c515                	beqz	a0,772 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 748:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 74a:	4798                	lw	a4,8(a5)
 74c:	02977f63          	bgeu	a4,s1,78a <malloc+0x70>
 750:	8a4e                	mv	s4,s3
 752:	0009871b          	sext.w	a4,s3
 756:	6685                	lui	a3,0x1
 758:	00d77363          	bgeu	a4,a3,75e <malloc+0x44>
 75c:	6a05                	lui	s4,0x1
 75e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 762:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 766:	00000917          	auipc	s2,0x0
 76a:	12290913          	addi	s2,s2,290 # 888 <freep>
  if(p == (char*)-1)
 76e:	5afd                	li	s5,-1
 770:	a895                	j	7e4 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 772:	00000797          	auipc	a5,0x0
 776:	11e78793          	addi	a5,a5,286 # 890 <base>
 77a:	00000717          	auipc	a4,0x0
 77e:	10f73723          	sd	a5,270(a4) # 888 <freep>
 782:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 784:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 788:	b7e1                	j	750 <malloc+0x36>
      if(p->s.size == nunits)
 78a:	02e48c63          	beq	s1,a4,7c2 <malloc+0xa8>
        p->s.size -= nunits;
 78e:	4137073b          	subw	a4,a4,s3
 792:	c798                	sw	a4,8(a5)
        p += p->s.size;
 794:	02071693          	slli	a3,a4,0x20
 798:	01c6d713          	srli	a4,a3,0x1c
 79c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 79e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a2:	00000717          	auipc	a4,0x0
 7a6:	0ea73323          	sd	a0,230(a4) # 888 <freep>
      return (void*)(p + 1);
 7aa:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ae:	70e2                	ld	ra,56(sp)
 7b0:	7442                	ld	s0,48(sp)
 7b2:	74a2                	ld	s1,40(sp)
 7b4:	7902                	ld	s2,32(sp)
 7b6:	69e2                	ld	s3,24(sp)
 7b8:	6a42                	ld	s4,16(sp)
 7ba:	6aa2                	ld	s5,8(sp)
 7bc:	6b02                	ld	s6,0(sp)
 7be:	6121                	addi	sp,sp,64
 7c0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c2:	6398                	ld	a4,0(a5)
 7c4:	e118                	sd	a4,0(a0)
 7c6:	bff1                	j	7a2 <malloc+0x88>
  hp->s.size = nu;
 7c8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7cc:	0541                	addi	a0,a0,16
 7ce:	00000097          	auipc	ra,0x0
 7d2:	eca080e7          	jalr	-310(ra) # 698 <free>
  return freep;
 7d6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7da:	d971                	beqz	a0,7ae <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7dc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7de:	4798                	lw	a4,8(a5)
 7e0:	fa9775e3          	bgeu	a4,s1,78a <malloc+0x70>
    if(p == freep)
 7e4:	00093703          	ld	a4,0(s2)
 7e8:	853e                	mv	a0,a5
 7ea:	fef719e3          	bne	a4,a5,7dc <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7ee:	8552                	mv	a0,s4
 7f0:	00000097          	auipc	ra,0x0
 7f4:	b68080e7          	jalr	-1176(ra) # 358 <sbrk>
  if(p == (char*)-1)
 7f8:	fd5518e3          	bne	a0,s5,7c8 <malloc+0xae>
        return 0;
 7fc:	4501                	li	a0,0
 7fe:	bf45                	j	7ae <malloc+0x94>
