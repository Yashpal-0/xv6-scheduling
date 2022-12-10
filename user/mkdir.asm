
user/_mkdir:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  int i;

  if(argc < 2){
   e:	4785                	li	a5,1
  10:	02a7d763          	bge	a5,a0,3e <main+0x3e>
  14:	00858493          	addi	s1,a1,8
  18:	ffe5091b          	addiw	s2,a0,-2
  1c:	02091793          	slli	a5,s2,0x20
  20:	01d7d913          	srli	s2,a5,0x1d
  24:	05c1                	addi	a1,a1,16
  26:	992e                	add	s2,s2,a1
    fprintf(2, "Usage: mkdir files...\n");
    exit(1);
  }

  for(i = 1; i < argc; i++){
    if(mkdir(argv[i]) < 0){
  28:	6088                	ld	a0,0(s1)
  2a:	00000097          	auipc	ra,0x0
  2e:	322080e7          	jalr	802(ra) # 34c <mkdir>
  32:	02054463          	bltz	a0,5a <main+0x5a>
  for(i = 1; i < argc; i++){
  36:	04a1                	addi	s1,s1,8
  38:	ff2498e3          	bne	s1,s2,28 <main+0x28>
  3c:	a80d                	j	6e <main+0x6e>
    fprintf(2, "Usage: mkdir files...\n");
  3e:	00000597          	auipc	a1,0x0
  42:	7da58593          	addi	a1,a1,2010 # 818 <malloc+0xea>
  46:	4509                	li	a0,2
  48:	00000097          	auipc	ra,0x0
  4c:	600080e7          	jalr	1536(ra) # 648 <fprintf>
    exit(1);
  50:	4505                	li	a0,1
  52:	00000097          	auipc	ra,0x0
  56:	292080e7          	jalr	658(ra) # 2e4 <exit>
      fprintf(2, "mkdir: %s failed to create\n", argv[i]);
  5a:	6090                	ld	a2,0(s1)
  5c:	00000597          	auipc	a1,0x0
  60:	7d458593          	addi	a1,a1,2004 # 830 <malloc+0x102>
  64:	4509                	li	a0,2
  66:	00000097          	auipc	ra,0x0
  6a:	5e2080e7          	jalr	1506(ra) # 648 <fprintf>
      break;
    }
  }

  exit(0);
  6e:	4501                	li	a0,0
  70:	00000097          	auipc	ra,0x0
  74:	274080e7          	jalr	628(ra) # 2e4 <exit>

0000000000000078 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  78:	1141                	addi	sp,sp,-16
  7a:	e422                	sd	s0,8(sp)
  7c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  7e:	87aa                	mv	a5,a0
  80:	0585                	addi	a1,a1,1
  82:	0785                	addi	a5,a5,1
  84:	fff5c703          	lbu	a4,-1(a1)
  88:	fee78fa3          	sb	a4,-1(a5)
  8c:	fb75                	bnez	a4,80 <strcpy+0x8>
    ;
  return os;
}
  8e:	6422                	ld	s0,8(sp)
  90:	0141                	addi	sp,sp,16
  92:	8082                	ret

0000000000000094 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  9a:	00054783          	lbu	a5,0(a0)
  9e:	cb91                	beqz	a5,b2 <strcmp+0x1e>
  a0:	0005c703          	lbu	a4,0(a1)
  a4:	00f71763          	bne	a4,a5,b2 <strcmp+0x1e>
    p++, q++;
  a8:	0505                	addi	a0,a0,1
  aa:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  ac:	00054783          	lbu	a5,0(a0)
  b0:	fbe5                	bnez	a5,a0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  b2:	0005c503          	lbu	a0,0(a1)
}
  b6:	40a7853b          	subw	a0,a5,a0
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	addi	sp,sp,16
  be:	8082                	ret

00000000000000c0 <strlen>:

uint
strlen(const char *s)
{
  c0:	1141                	addi	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	cf91                	beqz	a5,e6 <strlen+0x26>
  cc:	0505                	addi	a0,a0,1
  ce:	87aa                	mv	a5,a0
  d0:	4685                	li	a3,1
  d2:	9e89                	subw	a3,a3,a0
  d4:	00f6853b          	addw	a0,a3,a5
  d8:	0785                	addi	a5,a5,1
  da:	fff7c703          	lbu	a4,-1(a5)
  de:	fb7d                	bnez	a4,d4 <strlen+0x14>
    ;
  return n;
}
  e0:	6422                	ld	s0,8(sp)
  e2:	0141                	addi	sp,sp,16
  e4:	8082                	ret
  for(n = 0; s[n]; n++)
  e6:	4501                	li	a0,0
  e8:	bfe5                	j	e0 <strlen+0x20>

00000000000000ea <memset>:

void*
memset(void *dst, int c, uint n)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f0:	ca19                	beqz	a2,106 <memset+0x1c>
  f2:	87aa                	mv	a5,a0
  f4:	1602                	slli	a2,a2,0x20
  f6:	9201                	srli	a2,a2,0x20
  f8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  fc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 100:	0785                	addi	a5,a5,1
 102:	fee79de3          	bne	a5,a4,fc <memset+0x12>
  }
  return dst;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	addi	sp,sp,16
 10a:	8082                	ret

000000000000010c <strchr>:

char*
strchr(const char *s, char c)
{
 10c:	1141                	addi	sp,sp,-16
 10e:	e422                	sd	s0,8(sp)
 110:	0800                	addi	s0,sp,16
  for(; *s; s++)
 112:	00054783          	lbu	a5,0(a0)
 116:	cb99                	beqz	a5,12c <strchr+0x20>
    if(*s == c)
 118:	00f58763          	beq	a1,a5,126 <strchr+0x1a>
  for(; *s; s++)
 11c:	0505                	addi	a0,a0,1
 11e:	00054783          	lbu	a5,0(a0)
 122:	fbfd                	bnez	a5,118 <strchr+0xc>
      return (char*)s;
  return 0;
 124:	4501                	li	a0,0
}
 126:	6422                	ld	s0,8(sp)
 128:	0141                	addi	sp,sp,16
 12a:	8082                	ret
  return 0;
 12c:	4501                	li	a0,0
 12e:	bfe5                	j	126 <strchr+0x1a>

0000000000000130 <gets>:

char*
gets(char *buf, int max)
{
 130:	711d                	addi	sp,sp,-96
 132:	ec86                	sd	ra,88(sp)
 134:	e8a2                	sd	s0,80(sp)
 136:	e4a6                	sd	s1,72(sp)
 138:	e0ca                	sd	s2,64(sp)
 13a:	fc4e                	sd	s3,56(sp)
 13c:	f852                	sd	s4,48(sp)
 13e:	f456                	sd	s5,40(sp)
 140:	f05a                	sd	s6,32(sp)
 142:	ec5e                	sd	s7,24(sp)
 144:	1080                	addi	s0,sp,96
 146:	8baa                	mv	s7,a0
 148:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 14a:	892a                	mv	s2,a0
 14c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 14e:	4aa9                	li	s5,10
 150:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 152:	89a6                	mv	s3,s1
 154:	2485                	addiw	s1,s1,1
 156:	0344d863          	bge	s1,s4,186 <gets+0x56>
    cc = read(0, &c, 1);
 15a:	4605                	li	a2,1
 15c:	faf40593          	addi	a1,s0,-81
 160:	4501                	li	a0,0
 162:	00000097          	auipc	ra,0x0
 166:	19a080e7          	jalr	410(ra) # 2fc <read>
    if(cc < 1)
 16a:	00a05e63          	blez	a0,186 <gets+0x56>
    buf[i++] = c;
 16e:	faf44783          	lbu	a5,-81(s0)
 172:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 176:	01578763          	beq	a5,s5,184 <gets+0x54>
 17a:	0905                	addi	s2,s2,1
 17c:	fd679be3          	bne	a5,s6,152 <gets+0x22>
  for(i=0; i+1 < max; ){
 180:	89a6                	mv	s3,s1
 182:	a011                	j	186 <gets+0x56>
 184:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 186:	99de                	add	s3,s3,s7
 188:	00098023          	sb	zero,0(s3)
  return buf;
}
 18c:	855e                	mv	a0,s7
 18e:	60e6                	ld	ra,88(sp)
 190:	6446                	ld	s0,80(sp)
 192:	64a6                	ld	s1,72(sp)
 194:	6906                	ld	s2,64(sp)
 196:	79e2                	ld	s3,56(sp)
 198:	7a42                	ld	s4,48(sp)
 19a:	7aa2                	ld	s5,40(sp)
 19c:	7b02                	ld	s6,32(sp)
 19e:	6be2                	ld	s7,24(sp)
 1a0:	6125                	addi	sp,sp,96
 1a2:	8082                	ret

00000000000001a4 <stat>:

int
stat(const char *n, struct stat *st)
{
 1a4:	1101                	addi	sp,sp,-32
 1a6:	ec06                	sd	ra,24(sp)
 1a8:	e822                	sd	s0,16(sp)
 1aa:	e426                	sd	s1,8(sp)
 1ac:	e04a                	sd	s2,0(sp)
 1ae:	1000                	addi	s0,sp,32
 1b0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1b2:	4581                	li	a1,0
 1b4:	00000097          	auipc	ra,0x0
 1b8:	170080e7          	jalr	368(ra) # 324 <open>
  if(fd < 0)
 1bc:	02054563          	bltz	a0,1e6 <stat+0x42>
 1c0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1c2:	85ca                	mv	a1,s2
 1c4:	00000097          	auipc	ra,0x0
 1c8:	178080e7          	jalr	376(ra) # 33c <fstat>
 1cc:	892a                	mv	s2,a0
  close(fd);
 1ce:	8526                	mv	a0,s1
 1d0:	00000097          	auipc	ra,0x0
 1d4:	13c080e7          	jalr	316(ra) # 30c <close>
  return r;
}
 1d8:	854a                	mv	a0,s2
 1da:	60e2                	ld	ra,24(sp)
 1dc:	6442                	ld	s0,16(sp)
 1de:	64a2                	ld	s1,8(sp)
 1e0:	6902                	ld	s2,0(sp)
 1e2:	6105                	addi	sp,sp,32
 1e4:	8082                	ret
    return -1;
 1e6:	597d                	li	s2,-1
 1e8:	bfc5                	j	1d8 <stat+0x34>

00000000000001ea <atoi>:

int
atoi(const char *s)
{
 1ea:	1141                	addi	sp,sp,-16
 1ec:	e422                	sd	s0,8(sp)
 1ee:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f0:	00054683          	lbu	a3,0(a0)
 1f4:	fd06879b          	addiw	a5,a3,-48
 1f8:	0ff7f793          	zext.b	a5,a5
 1fc:	4625                	li	a2,9
 1fe:	02f66863          	bltu	a2,a5,22e <atoi+0x44>
 202:	872a                	mv	a4,a0
  n = 0;
 204:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 206:	0705                	addi	a4,a4,1
 208:	0025179b          	slliw	a5,a0,0x2
 20c:	9fa9                	addw	a5,a5,a0
 20e:	0017979b          	slliw	a5,a5,0x1
 212:	9fb5                	addw	a5,a5,a3
 214:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 218:	00074683          	lbu	a3,0(a4)
 21c:	fd06879b          	addiw	a5,a3,-48
 220:	0ff7f793          	zext.b	a5,a5
 224:	fef671e3          	bgeu	a2,a5,206 <atoi+0x1c>
  return n;
}
 228:	6422                	ld	s0,8(sp)
 22a:	0141                	addi	sp,sp,16
 22c:	8082                	ret
  n = 0;
 22e:	4501                	li	a0,0
 230:	bfe5                	j	228 <atoi+0x3e>

0000000000000232 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 232:	1141                	addi	sp,sp,-16
 234:	e422                	sd	s0,8(sp)
 236:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 238:	02b57463          	bgeu	a0,a1,260 <memmove+0x2e>
    while(n-- > 0)
 23c:	00c05f63          	blez	a2,25a <memmove+0x28>
 240:	1602                	slli	a2,a2,0x20
 242:	9201                	srli	a2,a2,0x20
 244:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 248:	872a                	mv	a4,a0
      *dst++ = *src++;
 24a:	0585                	addi	a1,a1,1
 24c:	0705                	addi	a4,a4,1
 24e:	fff5c683          	lbu	a3,-1(a1)
 252:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 256:	fee79ae3          	bne	a5,a4,24a <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 25a:	6422                	ld	s0,8(sp)
 25c:	0141                	addi	sp,sp,16
 25e:	8082                	ret
    dst += n;
 260:	00c50733          	add	a4,a0,a2
    src += n;
 264:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 266:	fec05ae3          	blez	a2,25a <memmove+0x28>
 26a:	fff6079b          	addiw	a5,a2,-1
 26e:	1782                	slli	a5,a5,0x20
 270:	9381                	srli	a5,a5,0x20
 272:	fff7c793          	not	a5,a5
 276:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 278:	15fd                	addi	a1,a1,-1
 27a:	177d                	addi	a4,a4,-1
 27c:	0005c683          	lbu	a3,0(a1)
 280:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 284:	fee79ae3          	bne	a5,a4,278 <memmove+0x46>
 288:	bfc9                	j	25a <memmove+0x28>

000000000000028a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 28a:	1141                	addi	sp,sp,-16
 28c:	e422                	sd	s0,8(sp)
 28e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 290:	ca05                	beqz	a2,2c0 <memcmp+0x36>
 292:	fff6069b          	addiw	a3,a2,-1
 296:	1682                	slli	a3,a3,0x20
 298:	9281                	srli	a3,a3,0x20
 29a:	0685                	addi	a3,a3,1
 29c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 29e:	00054783          	lbu	a5,0(a0)
 2a2:	0005c703          	lbu	a4,0(a1)
 2a6:	00e79863          	bne	a5,a4,2b6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2aa:	0505                	addi	a0,a0,1
    p2++;
 2ac:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2ae:	fed518e3          	bne	a0,a3,29e <memcmp+0x14>
  }
  return 0;
 2b2:	4501                	li	a0,0
 2b4:	a019                	j	2ba <memcmp+0x30>
      return *p1 - *p2;
 2b6:	40e7853b          	subw	a0,a5,a4
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret
  return 0;
 2c0:	4501                	li	a0,0
 2c2:	bfe5                	j	2ba <memcmp+0x30>

00000000000002c4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2c4:	1141                	addi	sp,sp,-16
 2c6:	e406                	sd	ra,8(sp)
 2c8:	e022                	sd	s0,0(sp)
 2ca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2cc:	00000097          	auipc	ra,0x0
 2d0:	f66080e7          	jalr	-154(ra) # 232 <memmove>
}
 2d4:	60a2                	ld	ra,8(sp)
 2d6:	6402                	ld	s0,0(sp)
 2d8:	0141                	addi	sp,sp,16
 2da:	8082                	ret

00000000000002dc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2dc:	4885                	li	a7,1
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2e4:	4889                	li	a7,2
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ec:	488d                	li	a7,3
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2f4:	4891                	li	a7,4
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <read>:
.global read
read:
 li a7, SYS_read
 2fc:	4895                	li	a7,5
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <write>:
.global write
write:
 li a7, SYS_write
 304:	48c1                	li	a7,16
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <close>:
.global close
close:
 li a7, SYS_close
 30c:	48d5                	li	a7,21
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <kill>:
.global kill
kill:
 li a7, SYS_kill
 314:	4899                	li	a7,6
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <exec>:
.global exec
exec:
 li a7, SYS_exec
 31c:	489d                	li	a7,7
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <open>:
.global open
open:
 li a7, SYS_open
 324:	48bd                	li	a7,15
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 32c:	48c5                	li	a7,17
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 334:	48c9                	li	a7,18
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 33c:	48a1                	li	a7,8
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <link>:
.global link
link:
 li a7, SYS_link
 344:	48cd                	li	a7,19
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 34c:	48d1                	li	a7,20
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 354:	48a5                	li	a7,9
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <dup>:
.global dup
dup:
 li a7, SYS_dup
 35c:	48a9                	li	a7,10
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 364:	48ad                	li	a7,11
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 36c:	48b1                	li	a7,12
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 374:	48b5                	li	a7,13
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 37c:	48b9                	li	a7,14
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <strace>:
.global strace
strace:
 li a7, SYS_strace
 384:	48d9                	li	a7,22
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 38c:	48dd                	li	a7,23
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <setpriority>:
.global setpriority
setpriority:
 li a7, SYS_setpriority
 394:	48e1                	li	a7,24
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 39c:	1101                	addi	sp,sp,-32
 39e:	ec06                	sd	ra,24(sp)
 3a0:	e822                	sd	s0,16(sp)
 3a2:	1000                	addi	s0,sp,32
 3a4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3a8:	4605                	li	a2,1
 3aa:	fef40593          	addi	a1,s0,-17
 3ae:	00000097          	auipc	ra,0x0
 3b2:	f56080e7          	jalr	-170(ra) # 304 <write>
}
 3b6:	60e2                	ld	ra,24(sp)
 3b8:	6442                	ld	s0,16(sp)
 3ba:	6105                	addi	sp,sp,32
 3bc:	8082                	ret

00000000000003be <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3be:	7139                	addi	sp,sp,-64
 3c0:	fc06                	sd	ra,56(sp)
 3c2:	f822                	sd	s0,48(sp)
 3c4:	f426                	sd	s1,40(sp)
 3c6:	f04a                	sd	s2,32(sp)
 3c8:	ec4e                	sd	s3,24(sp)
 3ca:	0080                	addi	s0,sp,64
 3cc:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ce:	c299                	beqz	a3,3d4 <printint+0x16>
 3d0:	0805c963          	bltz	a1,462 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3d4:	2581                	sext.w	a1,a1
  neg = 0;
 3d6:	4881                	li	a7,0
 3d8:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3dc:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3de:	2601                	sext.w	a2,a2
 3e0:	00000517          	auipc	a0,0x0
 3e4:	4d050513          	addi	a0,a0,1232 # 8b0 <digits>
 3e8:	883a                	mv	a6,a4
 3ea:	2705                	addiw	a4,a4,1
 3ec:	02c5f7bb          	remuw	a5,a1,a2
 3f0:	1782                	slli	a5,a5,0x20
 3f2:	9381                	srli	a5,a5,0x20
 3f4:	97aa                	add	a5,a5,a0
 3f6:	0007c783          	lbu	a5,0(a5)
 3fa:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3fe:	0005879b          	sext.w	a5,a1
 402:	02c5d5bb          	divuw	a1,a1,a2
 406:	0685                	addi	a3,a3,1
 408:	fec7f0e3          	bgeu	a5,a2,3e8 <printint+0x2a>
  if(neg)
 40c:	00088c63          	beqz	a7,424 <printint+0x66>
    buf[i++] = '-';
 410:	fd070793          	addi	a5,a4,-48
 414:	00878733          	add	a4,a5,s0
 418:	02d00793          	li	a5,45
 41c:	fef70823          	sb	a5,-16(a4)
 420:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 424:	02e05863          	blez	a4,454 <printint+0x96>
 428:	fc040793          	addi	a5,s0,-64
 42c:	00e78933          	add	s2,a5,a4
 430:	fff78993          	addi	s3,a5,-1
 434:	99ba                	add	s3,s3,a4
 436:	377d                	addiw	a4,a4,-1
 438:	1702                	slli	a4,a4,0x20
 43a:	9301                	srli	a4,a4,0x20
 43c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 440:	fff94583          	lbu	a1,-1(s2)
 444:	8526                	mv	a0,s1
 446:	00000097          	auipc	ra,0x0
 44a:	f56080e7          	jalr	-170(ra) # 39c <putc>
  while(--i >= 0)
 44e:	197d                	addi	s2,s2,-1
 450:	ff3918e3          	bne	s2,s3,440 <printint+0x82>
}
 454:	70e2                	ld	ra,56(sp)
 456:	7442                	ld	s0,48(sp)
 458:	74a2                	ld	s1,40(sp)
 45a:	7902                	ld	s2,32(sp)
 45c:	69e2                	ld	s3,24(sp)
 45e:	6121                	addi	sp,sp,64
 460:	8082                	ret
    x = -xx;
 462:	40b005bb          	negw	a1,a1
    neg = 1;
 466:	4885                	li	a7,1
    x = -xx;
 468:	bf85                	j	3d8 <printint+0x1a>

000000000000046a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 46a:	7119                	addi	sp,sp,-128
 46c:	fc86                	sd	ra,120(sp)
 46e:	f8a2                	sd	s0,112(sp)
 470:	f4a6                	sd	s1,104(sp)
 472:	f0ca                	sd	s2,96(sp)
 474:	ecce                	sd	s3,88(sp)
 476:	e8d2                	sd	s4,80(sp)
 478:	e4d6                	sd	s5,72(sp)
 47a:	e0da                	sd	s6,64(sp)
 47c:	fc5e                	sd	s7,56(sp)
 47e:	f862                	sd	s8,48(sp)
 480:	f466                	sd	s9,40(sp)
 482:	f06a                	sd	s10,32(sp)
 484:	ec6e                	sd	s11,24(sp)
 486:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 488:	0005c903          	lbu	s2,0(a1)
 48c:	18090f63          	beqz	s2,62a <vprintf+0x1c0>
 490:	8aaa                	mv	s5,a0
 492:	8b32                	mv	s6,a2
 494:	00158493          	addi	s1,a1,1
  state = 0;
 498:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 49a:	02500a13          	li	s4,37
 49e:	4c55                	li	s8,21
 4a0:	00000c97          	auipc	s9,0x0
 4a4:	3b8c8c93          	addi	s9,s9,952 # 858 <malloc+0x12a>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4a8:	02800d93          	li	s11,40
  putc(fd, 'x');
 4ac:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4ae:	00000b97          	auipc	s7,0x0
 4b2:	402b8b93          	addi	s7,s7,1026 # 8b0 <digits>
 4b6:	a839                	j	4d4 <vprintf+0x6a>
        putc(fd, c);
 4b8:	85ca                	mv	a1,s2
 4ba:	8556                	mv	a0,s5
 4bc:	00000097          	auipc	ra,0x0
 4c0:	ee0080e7          	jalr	-288(ra) # 39c <putc>
 4c4:	a019                	j	4ca <vprintf+0x60>
    } else if(state == '%'){
 4c6:	01498d63          	beq	s3,s4,4e0 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4ca:	0485                	addi	s1,s1,1
 4cc:	fff4c903          	lbu	s2,-1(s1)
 4d0:	14090d63          	beqz	s2,62a <vprintf+0x1c0>
    if(state == 0){
 4d4:	fe0999e3          	bnez	s3,4c6 <vprintf+0x5c>
      if(c == '%'){
 4d8:	ff4910e3          	bne	s2,s4,4b8 <vprintf+0x4e>
        state = '%';
 4dc:	89d2                	mv	s3,s4
 4de:	b7f5                	j	4ca <vprintf+0x60>
      if(c == 'd'){
 4e0:	11490c63          	beq	s2,s4,5f8 <vprintf+0x18e>
 4e4:	f9d9079b          	addiw	a5,s2,-99
 4e8:	0ff7f793          	zext.b	a5,a5
 4ec:	10fc6e63          	bltu	s8,a5,608 <vprintf+0x19e>
 4f0:	f9d9079b          	addiw	a5,s2,-99
 4f4:	0ff7f713          	zext.b	a4,a5
 4f8:	10ec6863          	bltu	s8,a4,608 <vprintf+0x19e>
 4fc:	00271793          	slli	a5,a4,0x2
 500:	97e6                	add	a5,a5,s9
 502:	439c                	lw	a5,0(a5)
 504:	97e6                	add	a5,a5,s9
 506:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 508:	008b0913          	addi	s2,s6,8
 50c:	4685                	li	a3,1
 50e:	4629                	li	a2,10
 510:	000b2583          	lw	a1,0(s6)
 514:	8556                	mv	a0,s5
 516:	00000097          	auipc	ra,0x0
 51a:	ea8080e7          	jalr	-344(ra) # 3be <printint>
 51e:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 520:	4981                	li	s3,0
 522:	b765                	j	4ca <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 524:	008b0913          	addi	s2,s6,8
 528:	4681                	li	a3,0
 52a:	4629                	li	a2,10
 52c:	000b2583          	lw	a1,0(s6)
 530:	8556                	mv	a0,s5
 532:	00000097          	auipc	ra,0x0
 536:	e8c080e7          	jalr	-372(ra) # 3be <printint>
 53a:	8b4a                	mv	s6,s2
      state = 0;
 53c:	4981                	li	s3,0
 53e:	b771                	j	4ca <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 540:	008b0913          	addi	s2,s6,8
 544:	4681                	li	a3,0
 546:	866a                	mv	a2,s10
 548:	000b2583          	lw	a1,0(s6)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	e70080e7          	jalr	-400(ra) # 3be <printint>
 556:	8b4a                	mv	s6,s2
      state = 0;
 558:	4981                	li	s3,0
 55a:	bf85                	j	4ca <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 55c:	008b0793          	addi	a5,s6,8
 560:	f8f43423          	sd	a5,-120(s0)
 564:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 568:	03000593          	li	a1,48
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	e2e080e7          	jalr	-466(ra) # 39c <putc>
  putc(fd, 'x');
 576:	07800593          	li	a1,120
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e20080e7          	jalr	-480(ra) # 39c <putc>
 584:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 586:	03c9d793          	srli	a5,s3,0x3c
 58a:	97de                	add	a5,a5,s7
 58c:	0007c583          	lbu	a1,0(a5)
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e0a080e7          	jalr	-502(ra) # 39c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 59a:	0992                	slli	s3,s3,0x4
 59c:	397d                	addiw	s2,s2,-1
 59e:	fe0914e3          	bnez	s2,586 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5a2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5a6:	4981                	li	s3,0
 5a8:	b70d                	j	4ca <vprintf+0x60>
        s = va_arg(ap, char*);
 5aa:	008b0913          	addi	s2,s6,8
 5ae:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5b2:	02098163          	beqz	s3,5d4 <vprintf+0x16a>
        while(*s != 0){
 5b6:	0009c583          	lbu	a1,0(s3)
 5ba:	c5ad                	beqz	a1,624 <vprintf+0x1ba>
          putc(fd, *s);
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	dde080e7          	jalr	-546(ra) # 39c <putc>
          s++;
 5c6:	0985                	addi	s3,s3,1
        while(*s != 0){
 5c8:	0009c583          	lbu	a1,0(s3)
 5cc:	f9e5                	bnez	a1,5bc <vprintf+0x152>
        s = va_arg(ap, char*);
 5ce:	8b4a                	mv	s6,s2
      state = 0;
 5d0:	4981                	li	s3,0
 5d2:	bde5                	j	4ca <vprintf+0x60>
          s = "(null)";
 5d4:	00000997          	auipc	s3,0x0
 5d8:	27c98993          	addi	s3,s3,636 # 850 <malloc+0x122>
        while(*s != 0){
 5dc:	85ee                	mv	a1,s11
 5de:	bff9                	j	5bc <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5e0:	008b0913          	addi	s2,s6,8
 5e4:	000b4583          	lbu	a1,0(s6)
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	db2080e7          	jalr	-590(ra) # 39c <putc>
 5f2:	8b4a                	mv	s6,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	bdd1                	j	4ca <vprintf+0x60>
        putc(fd, c);
 5f8:	85d2                	mv	a1,s4
 5fa:	8556                	mv	a0,s5
 5fc:	00000097          	auipc	ra,0x0
 600:	da0080e7          	jalr	-608(ra) # 39c <putc>
      state = 0;
 604:	4981                	li	s3,0
 606:	b5d1                	j	4ca <vprintf+0x60>
        putc(fd, '%');
 608:	85d2                	mv	a1,s4
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	d90080e7          	jalr	-624(ra) # 39c <putc>
        putc(fd, c);
 614:	85ca                	mv	a1,s2
 616:	8556                	mv	a0,s5
 618:	00000097          	auipc	ra,0x0
 61c:	d84080e7          	jalr	-636(ra) # 39c <putc>
      state = 0;
 620:	4981                	li	s3,0
 622:	b565                	j	4ca <vprintf+0x60>
        s = va_arg(ap, char*);
 624:	8b4a                	mv	s6,s2
      state = 0;
 626:	4981                	li	s3,0
 628:	b54d                	j	4ca <vprintf+0x60>
    }
  }
}
 62a:	70e6                	ld	ra,120(sp)
 62c:	7446                	ld	s0,112(sp)
 62e:	74a6                	ld	s1,104(sp)
 630:	7906                	ld	s2,96(sp)
 632:	69e6                	ld	s3,88(sp)
 634:	6a46                	ld	s4,80(sp)
 636:	6aa6                	ld	s5,72(sp)
 638:	6b06                	ld	s6,64(sp)
 63a:	7be2                	ld	s7,56(sp)
 63c:	7c42                	ld	s8,48(sp)
 63e:	7ca2                	ld	s9,40(sp)
 640:	7d02                	ld	s10,32(sp)
 642:	6de2                	ld	s11,24(sp)
 644:	6109                	addi	sp,sp,128
 646:	8082                	ret

0000000000000648 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 648:	715d                	addi	sp,sp,-80
 64a:	ec06                	sd	ra,24(sp)
 64c:	e822                	sd	s0,16(sp)
 64e:	1000                	addi	s0,sp,32
 650:	e010                	sd	a2,0(s0)
 652:	e414                	sd	a3,8(s0)
 654:	e818                	sd	a4,16(s0)
 656:	ec1c                	sd	a5,24(s0)
 658:	03043023          	sd	a6,32(s0)
 65c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 660:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 664:	8622                	mv	a2,s0
 666:	00000097          	auipc	ra,0x0
 66a:	e04080e7          	jalr	-508(ra) # 46a <vprintf>
}
 66e:	60e2                	ld	ra,24(sp)
 670:	6442                	ld	s0,16(sp)
 672:	6161                	addi	sp,sp,80
 674:	8082                	ret

0000000000000676 <printf>:

void
printf(const char *fmt, ...)
{
 676:	711d                	addi	sp,sp,-96
 678:	ec06                	sd	ra,24(sp)
 67a:	e822                	sd	s0,16(sp)
 67c:	1000                	addi	s0,sp,32
 67e:	e40c                	sd	a1,8(s0)
 680:	e810                	sd	a2,16(s0)
 682:	ec14                	sd	a3,24(s0)
 684:	f018                	sd	a4,32(s0)
 686:	f41c                	sd	a5,40(s0)
 688:	03043823          	sd	a6,48(s0)
 68c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 690:	00840613          	addi	a2,s0,8
 694:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 698:	85aa                	mv	a1,a0
 69a:	4505                	li	a0,1
 69c:	00000097          	auipc	ra,0x0
 6a0:	dce080e7          	jalr	-562(ra) # 46a <vprintf>
}
 6a4:	60e2                	ld	ra,24(sp)
 6a6:	6442                	ld	s0,16(sp)
 6a8:	6125                	addi	sp,sp,96
 6aa:	8082                	ret

00000000000006ac <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6ac:	1141                	addi	sp,sp,-16
 6ae:	e422                	sd	s0,8(sp)
 6b0:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6b2:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b6:	00000797          	auipc	a5,0x0
 6ba:	2127b783          	ld	a5,530(a5) # 8c8 <freep>
 6be:	a02d                	j	6e8 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6c0:	4618                	lw	a4,8(a2)
 6c2:	9f2d                	addw	a4,a4,a1
 6c4:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6c8:	6398                	ld	a4,0(a5)
 6ca:	6310                	ld	a2,0(a4)
 6cc:	a83d                	j	70a <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6ce:	ff852703          	lw	a4,-8(a0)
 6d2:	9f31                	addw	a4,a4,a2
 6d4:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6d6:	ff053683          	ld	a3,-16(a0)
 6da:	a091                	j	71e <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6dc:	6398                	ld	a4,0(a5)
 6de:	00e7e463          	bltu	a5,a4,6e6 <free+0x3a>
 6e2:	00e6ea63          	bltu	a3,a4,6f6 <free+0x4a>
{
 6e6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e8:	fed7fae3          	bgeu	a5,a3,6dc <free+0x30>
 6ec:	6398                	ld	a4,0(a5)
 6ee:	00e6e463          	bltu	a3,a4,6f6 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f2:	fee7eae3          	bltu	a5,a4,6e6 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6f6:	ff852583          	lw	a1,-8(a0)
 6fa:	6390                	ld	a2,0(a5)
 6fc:	02059813          	slli	a6,a1,0x20
 700:	01c85713          	srli	a4,a6,0x1c
 704:	9736                	add	a4,a4,a3
 706:	fae60de3          	beq	a2,a4,6c0 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 70a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 70e:	4790                	lw	a2,8(a5)
 710:	02061593          	slli	a1,a2,0x20
 714:	01c5d713          	srli	a4,a1,0x1c
 718:	973e                	add	a4,a4,a5
 71a:	fae68ae3          	beq	a3,a4,6ce <free+0x22>
    p->s.ptr = bp->s.ptr;
 71e:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 720:	00000717          	auipc	a4,0x0
 724:	1af73423          	sd	a5,424(a4) # 8c8 <freep>
}
 728:	6422                	ld	s0,8(sp)
 72a:	0141                	addi	sp,sp,16
 72c:	8082                	ret

000000000000072e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 72e:	7139                	addi	sp,sp,-64
 730:	fc06                	sd	ra,56(sp)
 732:	f822                	sd	s0,48(sp)
 734:	f426                	sd	s1,40(sp)
 736:	f04a                	sd	s2,32(sp)
 738:	ec4e                	sd	s3,24(sp)
 73a:	e852                	sd	s4,16(sp)
 73c:	e456                	sd	s5,8(sp)
 73e:	e05a                	sd	s6,0(sp)
 740:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 742:	02051493          	slli	s1,a0,0x20
 746:	9081                	srli	s1,s1,0x20
 748:	04bd                	addi	s1,s1,15
 74a:	8091                	srli	s1,s1,0x4
 74c:	0014899b          	addiw	s3,s1,1
 750:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 752:	00000517          	auipc	a0,0x0
 756:	17653503          	ld	a0,374(a0) # 8c8 <freep>
 75a:	c515                	beqz	a0,786 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 75c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 75e:	4798                	lw	a4,8(a5)
 760:	02977f63          	bgeu	a4,s1,79e <malloc+0x70>
 764:	8a4e                	mv	s4,s3
 766:	0009871b          	sext.w	a4,s3
 76a:	6685                	lui	a3,0x1
 76c:	00d77363          	bgeu	a4,a3,772 <malloc+0x44>
 770:	6a05                	lui	s4,0x1
 772:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 776:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 77a:	00000917          	auipc	s2,0x0
 77e:	14e90913          	addi	s2,s2,334 # 8c8 <freep>
  if(p == (char*)-1)
 782:	5afd                	li	s5,-1
 784:	a895                	j	7f8 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 786:	00000797          	auipc	a5,0x0
 78a:	14a78793          	addi	a5,a5,330 # 8d0 <base>
 78e:	00000717          	auipc	a4,0x0
 792:	12f73d23          	sd	a5,314(a4) # 8c8 <freep>
 796:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 798:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 79c:	b7e1                	j	764 <malloc+0x36>
      if(p->s.size == nunits)
 79e:	02e48c63          	beq	s1,a4,7d6 <malloc+0xa8>
        p->s.size -= nunits;
 7a2:	4137073b          	subw	a4,a4,s3
 7a6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7a8:	02071693          	slli	a3,a4,0x20
 7ac:	01c6d713          	srli	a4,a3,0x1c
 7b0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7b2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7b6:	00000717          	auipc	a4,0x0
 7ba:	10a73923          	sd	a0,274(a4) # 8c8 <freep>
      return (void*)(p + 1);
 7be:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7c2:	70e2                	ld	ra,56(sp)
 7c4:	7442                	ld	s0,48(sp)
 7c6:	74a2                	ld	s1,40(sp)
 7c8:	7902                	ld	s2,32(sp)
 7ca:	69e2                	ld	s3,24(sp)
 7cc:	6a42                	ld	s4,16(sp)
 7ce:	6aa2                	ld	s5,8(sp)
 7d0:	6b02                	ld	s6,0(sp)
 7d2:	6121                	addi	sp,sp,64
 7d4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7d6:	6398                	ld	a4,0(a5)
 7d8:	e118                	sd	a4,0(a0)
 7da:	bff1                	j	7b6 <malloc+0x88>
  hp->s.size = nu;
 7dc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7e0:	0541                	addi	a0,a0,16
 7e2:	00000097          	auipc	ra,0x0
 7e6:	eca080e7          	jalr	-310(ra) # 6ac <free>
  return freep;
 7ea:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7ee:	d971                	beqz	a0,7c2 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7f2:	4798                	lw	a4,8(a5)
 7f4:	fa9775e3          	bgeu	a4,s1,79e <malloc+0x70>
    if(p == freep)
 7f8:	00093703          	ld	a4,0(s2)
 7fc:	853e                	mv	a0,a5
 7fe:	fef719e3          	bne	a4,a5,7f0 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 802:	8552                	mv	a0,s4
 804:	00000097          	auipc	ra,0x0
 808:	b68080e7          	jalr	-1176(ra) # 36c <sbrk>
  if(p == (char*)-1)
 80c:	fd5518e3          	bne	a0,s5,7dc <malloc+0xae>
        return 0;
 810:	4501                	li	a0,0
 812:	bf45                	j	7c2 <malloc+0x94>
