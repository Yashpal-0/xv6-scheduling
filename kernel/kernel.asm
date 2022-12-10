
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ab813103          	ld	sp,-1352(sp) # 80008ab8 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	03e78793          	addi	a5,a5,62 # 800060a0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6b8080e7          	jalr	1720(ra) # 800027e2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	096080e7          	jalr	150(ra) # 80002266 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	580080e7          	jalr	1408(ra) # 8000278c <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	54c080e7          	jalr	1356(ra) # 80002838 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	10a080e7          	jalr	266(ra) # 8000254a <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00023797          	auipc	a5,0x23
    80000476:	6be78793          	addi	a5,a5,1726 # 80023b30 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	cbc080e7          	jalr	-836(ra) # 8000254a <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	94c080e7          	jalr	-1716(ra) # 80002266 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00027797          	auipc	a5,0x27
    800009fa:	60a78793          	addi	a5,a5,1546 # 80028000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00027517          	auipc	a0,0x27
    80000acc:	53850513          	addi	a0,a0,1336 # 80028000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd7001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	ab2080e7          	jalr	-1358(ra) # 8000296a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	220080e7          	jalr	544(ra) # 800060e0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	150080e7          	jalr	336(ra) # 80002018 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	a12080e7          	jalr	-1518(ra) # 80002942 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	a32080e7          	jalr	-1486(ra) # 8000296a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	18a080e7          	jalr	394(ra) # 800060ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	198080e7          	jalr	408(ra) # 800060e0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	356080e7          	jalr	854(ra) # 800032a6 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	9e4080e7          	jalr	-1564(ra) # 8000393c <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	996080e7          	jalr	-1642(ra) # 800048f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	298080e7          	jalr	664(ra) # 80006200 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d78080e7          	jalr	-648(ra) # 80001ce8 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd6ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000183a:	00011497          	auipc	s1,0x11
    8000183e:	8ae48493          	addi	s1,s1,-1874 # 800120e8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00018a17          	auipc	s4,0x18
    80001858:	094a0a13          	addi	s4,s4,148 # 800198e8 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if (pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	8595                	srai	a1,a1,0x5
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000188e:	1e048493          	addi	s1,s1,480
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	7ea48493          	addi	s1,s1,2026 # 800120e8 <proc>
  {
    initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001920:	00018997          	auipc	s3,0x18
    80001924:	fc898993          	addi	s3,s3,-56 # 800198e8 <tickslock>
    initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	8795                	srai	a5,a5,0x5
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000194e:	1e048493          	addi	s1,s1,480
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first)
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	06a7a783          	lw	a5,106(a5) # 80008a50 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	f92080e7          	jalr	-110(ra) # 80002982 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	0407a823          	sw	zero,80(a5) # 80008a50 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	eb2080e7          	jalr	-334(ra) # 800038bc <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
{
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	02278793          	addi	a5,a5,34 # 80008a54 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	7179                	addi	sp,sp,-48
    80001ba2:	f406                	sd	ra,40(sp)
    80001ba4:	f022                	sd	s0,32(sp)
    80001ba6:	ec26                	sd	s1,24(sp)
    80001ba8:	e84a                	sd	s2,16(sp)
    80001baa:	e44e                	sd	s3,8(sp)
    80001bac:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001bae:	00010497          	auipc	s1,0x10
    80001bb2:	53a48493          	addi	s1,s1,1338 # 800120e8 <proc>
    80001bb6:	00018997          	auipc	s3,0x18
    80001bba:	d3298993          	addi	s3,s3,-718 # 800198e8 <tickslock>
    acquire(&p->lock);
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	010080e7          	jalr	16(ra) # 80000bd0 <acquire>
    if (p->state == UNUSED)
    80001bc8:	4c9c                	lw	a5,24(s1)
    80001bca:	cf81                	beqz	a5,80001be2 <allocproc+0x42>
      release(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	0b6080e7          	jalr	182(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd6:	1e048493          	addi	s1,s1,480
    80001bda:	ff3492e3          	bne	s1,s3,80001bbe <allocproc+0x1e>
  return 0;
    80001bde:	4481                	li	s1,0
    80001be0:	a0e1                	j	80001ca8 <allocproc+0x108>
  p->pid = allocpid();
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	e32080e7          	jalr	-462(ra) # 80001a14 <allocpid>
    80001bea:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bec:	4785                	li	a5,1
    80001bee:	cc9c                	sw	a5,24(s1)
  p->trace_mask = 0;
    80001bf0:	1604a423          	sw	zero,360(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	eec080e7          	jalr	-276(ra) # 80000ae0 <kalloc>
    80001bfc:	89aa                	mv	s3,a0
    80001bfe:	eca8                	sd	a0,88(s1)
    80001c00:	cd45                	beqz	a0,80001cb8 <allocproc+0x118>
  p->pagetable = proc_pagetable(p);
    80001c02:	8526                	mv	a0,s1
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	e56080e7          	jalr	-426(ra) # 80001a5a <proc_pagetable>
    80001c0c:	89aa                	mv	s3,a0
    80001c0e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c10:	c161                	beqz	a0,80001cd0 <allocproc+0x130>
  memset(&p->context, 0, sizeof(p->context));
    80001c12:	07000613          	li	a2,112
    80001c16:	4581                	li	a1,0
    80001c18:	06048513          	addi	a0,s1,96
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	0b0080e7          	jalr	176(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c24:	00000797          	auipc	a5,0x0
    80001c28:	daa78793          	addi	a5,a5,-598 # 800019ce <forkret>
    80001c2c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c2e:	60bc                	ld	a5,64(s1)
    80001c30:	6705                	lui	a4,0x1
    80001c32:	97ba                	add	a5,a5,a4
    80001c34:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c36:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c3a:	00007797          	auipc	a5,0x7
    80001c3e:	3f67a783          	lw	a5,1014(a5) # 80009030 <ticks>
    80001c42:	16f4a623          	sw	a5,364(s1)
  p->etime = 0;
    80001c46:	1604aa23          	sw	zero,372(s1)
  p->stime = 0;
    80001c4a:	1604ac23          	sw	zero,376(s1)
  p->wtime = 0;
    80001c4e:	1604ae23          	sw	zero,380(s1)
  p->total_s_time = 0;
    80001c52:	1804a023          	sw	zero,384(s1)
  p->lrtime = 0;
    80001c56:	1804a823          	sw	zero,400(s1)
  p->SP = 60;
    80001c5a:	03c00793          	li	a5,60
    80001c5e:	18f4a223          	sw	a5,388(s1)
  p->niceness = 5;
    80001c62:	4795                	li	a5,5
    80001c64:	18f4a623          	sw	a5,396(s1)
  p->DP = 0;
    80001c68:	1804a423          	sw	zero,392(s1)
  p->num_sched = 0;
    80001c6c:	1804aa23          	sw	zero,404(s1)
  p->priority = 0;
    80001c70:	1804ac23          	sw	zero,408(s1)
  p->total_wtime = 0;
    80001c74:	1c04ae23          	sw	zero,476(s1)
  p->index = c[p->priority];
    80001c78:	0000f717          	auipc	a4,0xf
    80001c7c:	62870713          	addi	a4,a4,1576 # 800112a0 <pid_lock>
    80001c80:	43072783          	lw	a5,1072(a4)
    80001c84:	18f4ae23          	sw	a5,412(s1)
  c[p->priority]++;
    80001c88:	2785                	addiw	a5,a5,1
    80001c8a:	42f72823          	sw	a5,1072(a4)
  for (int i = 0; i < 5; i++)
    80001c8e:	1a048793          	addi	a5,s1,416
    80001c92:	1b448913          	addi	s2,s1,436
    p->q_rtime[i] = 0;
    80001c96:	0007aa23          	sw	zero,20(a5)
    p->q_wtime[i] = 0;
    80001c9a:	0007a023          	sw	zero,0(a5)
    p->q_wait[i] = 0;
    80001c9e:	0207a423          	sw	zero,40(a5)
  for (int i = 0; i < 5; i++)
    80001ca2:	0791                	addi	a5,a5,4
    80001ca4:	ff2799e3          	bne	a5,s2,80001c96 <allocproc+0xf6>
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	70a2                	ld	ra,40(sp)
    80001cac:	7402                	ld	s0,32(sp)
    80001cae:	64e2                	ld	s1,24(sp)
    80001cb0:	6942                	ld	s2,16(sp)
    80001cb2:	69a2                	ld	s3,8(sp)
    80001cb4:	6145                	addi	sp,sp,48
    80001cb6:	8082                	ret
    freeproc(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e8e080e7          	jalr	-370(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	fc0080e7          	jalr	-64(ra) # 80000c84 <release>
    return 0;
    80001ccc:	84ce                	mv	s1,s3
    80001cce:	bfe9                	j	80001ca8 <allocproc+0x108>
    freeproc(p);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	e76080e7          	jalr	-394(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	fa8080e7          	jalr	-88(ra) # 80000c84 <release>
    return 0;
    80001ce4:	84ce                	mv	s1,s3
    80001ce6:	b7c9                	j	80001ca8 <allocproc+0x108>

0000000080001ce8 <userinit>:
{
    80001ce8:	1101                	addi	sp,sp,-32
    80001cea:	ec06                	sd	ra,24(sp)
    80001cec:	e822                	sd	s0,16(sp)
    80001cee:	e426                	sd	s1,8(sp)
    80001cf0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf2:	00000097          	auipc	ra,0x0
    80001cf6:	eae080e7          	jalr	-338(ra) # 80001ba0 <allocproc>
    80001cfa:	84aa                	mv	s1,a0
  initproc = p;
    80001cfc:	00007797          	auipc	a5,0x7
    80001d00:	32a7b623          	sd	a0,812(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d04:	03400613          	li	a2,52
    80001d08:	00007597          	auipc	a1,0x7
    80001d0c:	d5858593          	addi	a1,a1,-680 # 80008a60 <initcode>
    80001d10:	6928                	ld	a0,80(a0)
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	63a080e7          	jalr	1594(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001d1a:	6785                	lui	a5,0x1
    80001d1c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d1e:	6cb8                	ld	a4,88(s1)
    80001d20:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d24:	6cb8                	ld	a4,88(s1)
    80001d26:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d28:	4641                	li	a2,16
    80001d2a:	00006597          	auipc	a1,0x6
    80001d2e:	4d658593          	addi	a1,a1,1238 # 80008200 <digits+0x1c0>
    80001d32:	15848513          	addi	a0,s1,344
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	0e0080e7          	jalr	224(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d3e:	00006517          	auipc	a0,0x6
    80001d42:	4d250513          	addi	a0,a0,1234 # 80008210 <digits+0x1d0>
    80001d46:	00002097          	auipc	ra,0x2
    80001d4a:	5ac080e7          	jalr	1452(ra) # 800042f2 <namei>
    80001d4e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d52:	478d                	li	a5,3
    80001d54:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	f2c080e7          	jalr	-212(ra) # 80000c84 <release>
}
    80001d60:	60e2                	ld	ra,24(sp)
    80001d62:	6442                	ld	s0,16(sp)
    80001d64:	64a2                	ld	s1,8(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret

0000000080001d6a <growproc>:
{
    80001d6a:	1101                	addi	sp,sp,-32
    80001d6c:	ec06                	sd	ra,24(sp)
    80001d6e:	e822                	sd	s0,16(sp)
    80001d70:	e426                	sd	s1,8(sp)
    80001d72:	e04a                	sd	s2,0(sp)
    80001d74:	1000                	addi	s0,sp,32
    80001d76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	c1e080e7          	jalr	-994(ra) # 80001996 <myproc>
    80001d80:	892a                	mv	s2,a0
  sz = p->sz;
    80001d82:	652c                	ld	a1,72(a0)
    80001d84:	0005879b          	sext.w	a5,a1
  if (n > 0)
    80001d88:	00904f63          	bgtz	s1,80001da6 <growproc+0x3c>
  else if (n < 0)
    80001d8c:	0204cd63          	bltz	s1,80001dc6 <growproc+0x5c>
  p->sz = sz;
    80001d90:	1782                	slli	a5,a5,0x20
    80001d92:	9381                	srli	a5,a5,0x20
    80001d94:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d98:	4501                	li	a0,0
}
    80001d9a:	60e2                	ld	ra,24(sp)
    80001d9c:	6442                	ld	s0,16(sp)
    80001d9e:	64a2                	ld	s1,8(sp)
    80001da0:	6902                	ld	s2,0(sp)
    80001da2:	6105                	addi	sp,sp,32
    80001da4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001da6:	00f4863b          	addw	a2,s1,a5
    80001daa:	1602                	slli	a2,a2,0x20
    80001dac:	9201                	srli	a2,a2,0x20
    80001dae:	1582                	slli	a1,a1,0x20
    80001db0:	9181                	srli	a1,a1,0x20
    80001db2:	6928                	ld	a0,80(a0)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	652080e7          	jalr	1618(ra) # 80001406 <uvmalloc>
    80001dbc:	0005079b          	sext.w	a5,a0
    80001dc0:	fbe1                	bnez	a5,80001d90 <growproc+0x26>
      return -1;
    80001dc2:	557d                	li	a0,-1
    80001dc4:	bfd9                	j	80001d9a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc6:	00f4863b          	addw	a2,s1,a5
    80001dca:	1602                	slli	a2,a2,0x20
    80001dcc:	9201                	srli	a2,a2,0x20
    80001dce:	1582                	slli	a1,a1,0x20
    80001dd0:	9181                	srli	a1,a1,0x20
    80001dd2:	6928                	ld	a0,80(a0)
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	5ea080e7          	jalr	1514(ra) # 800013be <uvmdealloc>
    80001ddc:	0005079b          	sext.w	a5,a0
    80001de0:	bf45                	j	80001d90 <growproc+0x26>

0000000080001de2 <fork>:
{
    80001de2:	7139                	addi	sp,sp,-64
    80001de4:	fc06                	sd	ra,56(sp)
    80001de6:	f822                	sd	s0,48(sp)
    80001de8:	f426                	sd	s1,40(sp)
    80001dea:	f04a                	sd	s2,32(sp)
    80001dec:	ec4e                	sd	s3,24(sp)
    80001dee:	e852                	sd	s4,16(sp)
    80001df0:	e456                	sd	s5,8(sp)
    80001df2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	ba2080e7          	jalr	-1118(ra) # 80001996 <myproc>
    80001dfc:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	da2080e7          	jalr	-606(ra) # 80001ba0 <allocproc>
    80001e06:	12050063          	beqz	a0,80001f26 <fork+0x144>
    80001e0a:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e0c:	048ab603          	ld	a2,72(s5)
    80001e10:	692c                	ld	a1,80(a0)
    80001e12:	050ab503          	ld	a0,80(s5)
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	740080e7          	jalr	1856(ra) # 80001556 <uvmcopy>
    80001e1e:	04054c63          	bltz	a0,80001e76 <fork+0x94>
  np->sz = p->sz;
    80001e22:	048ab783          	ld	a5,72(s5)
    80001e26:	04f9b423          	sd	a5,72(s3)
  np->trace_mask = p->trace_mask;
    80001e2a:	168aa783          	lw	a5,360(s5)
    80001e2e:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e32:	058ab683          	ld	a3,88(s5)
    80001e36:	87b6                	mv	a5,a3
    80001e38:	0589b703          	ld	a4,88(s3)
    80001e3c:	12068693          	addi	a3,a3,288
    80001e40:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e44:	6788                	ld	a0,8(a5)
    80001e46:	6b8c                	ld	a1,16(a5)
    80001e48:	6f90                	ld	a2,24(a5)
    80001e4a:	01073023          	sd	a6,0(a4)
    80001e4e:	e708                	sd	a0,8(a4)
    80001e50:	eb0c                	sd	a1,16(a4)
    80001e52:	ef10                	sd	a2,24(a4)
    80001e54:	02078793          	addi	a5,a5,32
    80001e58:	02070713          	addi	a4,a4,32
    80001e5c:	fed792e3          	bne	a5,a3,80001e40 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001e60:	0589b783          	ld	a5,88(s3)
    80001e64:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e68:	0d0a8493          	addi	s1,s5,208
    80001e6c:	0d098913          	addi	s2,s3,208
    80001e70:	150a8a13          	addi	s4,s5,336
    80001e74:	a00d                	j	80001e96 <fork+0xb4>
    freeproc(np);
    80001e76:	854e                	mv	a0,s3
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	cd0080e7          	jalr	-816(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001e80:	854e                	mv	a0,s3
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e02080e7          	jalr	-510(ra) # 80000c84 <release>
    return -1;
    80001e8a:	597d                	li	s2,-1
    80001e8c:	a059                	j	80001f12 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e8e:	04a1                	addi	s1,s1,8
    80001e90:	0921                	addi	s2,s2,8
    80001e92:	01448b63          	beq	s1,s4,80001ea8 <fork+0xc6>
    if (p->ofile[i])
    80001e96:	6088                	ld	a0,0(s1)
    80001e98:	d97d                	beqz	a0,80001e8e <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e9a:	00003097          	auipc	ra,0x3
    80001e9e:	aee080e7          	jalr	-1298(ra) # 80004988 <filedup>
    80001ea2:	00a93023          	sd	a0,0(s2)
    80001ea6:	b7e5                	j	80001e8e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ea8:	150ab503          	ld	a0,336(s5)
    80001eac:	00002097          	auipc	ra,0x2
    80001eb0:	c4c080e7          	jalr	-948(ra) # 80003af8 <idup>
    80001eb4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eb8:	4641                	li	a2,16
    80001eba:	158a8593          	addi	a1,s5,344
    80001ebe:	15898513          	addi	a0,s3,344
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	f54080e7          	jalr	-172(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001eca:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001ece:	854e                	mv	a0,s3
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	db4080e7          	jalr	-588(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001ed8:	0000f497          	auipc	s1,0xf
    80001edc:	3e048493          	addi	s1,s1,992 # 800112b8 <wait_lock>
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	cee080e7          	jalr	-786(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001eea:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	d94080e7          	jalr	-620(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001ef8:	854e                	mv	a0,s3
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	cd6080e7          	jalr	-810(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001f02:	478d                	li	a5,3
    80001f04:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f08:	854e                	mv	a0,s3
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	d7a080e7          	jalr	-646(ra) # 80000c84 <release>
}
    80001f12:	854a                	mv	a0,s2
    80001f14:	70e2                	ld	ra,56(sp)
    80001f16:	7442                	ld	s0,48(sp)
    80001f18:	74a2                	ld	s1,40(sp)
    80001f1a:	7902                	ld	s2,32(sp)
    80001f1c:	69e2                	ld	s3,24(sp)
    80001f1e:	6a42                	ld	s4,16(sp)
    80001f20:	6aa2                	ld	s5,8(sp)
    80001f22:	6121                	addi	sp,sp,64
    80001f24:	8082                	ret
    return -1;
    80001f26:	597d                	li	s2,-1
    80001f28:	b7ed                	j	80001f12 <fork+0x130>

0000000080001f2a <update_time>:
{
    80001f2a:	7179                	addi	sp,sp,-48
    80001f2c:	f406                	sd	ra,40(sp)
    80001f2e:	f022                	sd	s0,32(sp)
    80001f30:	ec26                	sd	s1,24(sp)
    80001f32:	e84a                	sd	s2,16(sp)
    80001f34:	e44e                	sd	s3,8(sp)
    80001f36:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001f38:	00010497          	auipc	s1,0x10
    80001f3c:	1b048493          	addi	s1,s1,432 # 800120e8 <proc>
    if (p->state == RUNNING)
    80001f40:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80001f42:	00018917          	auipc	s2,0x18
    80001f46:	9a690913          	addi	s2,s2,-1626 # 800198e8 <tickslock>
    80001f4a:	a839                	j	80001f68 <update_time+0x3e>
      p->rtime++;
    80001f4c:	1704a783          	lw	a5,368(s1)
    80001f50:	2785                	addiw	a5,a5,1
    80001f52:	16f4a823          	sw	a5,368(s1)
    release(&p->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	d2c080e7          	jalr	-724(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f60:	1e048493          	addi	s1,s1,480
    80001f64:	03248063          	beq	s1,s2,80001f84 <update_time+0x5a>
    acquire(&p->lock);
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	c66080e7          	jalr	-922(ra) # 80000bd0 <acquire>
    if (p->state == RUNNING)
    80001f72:	4c9c                	lw	a5,24(s1)
    80001f74:	fd378ce3          	beq	a5,s3,80001f4c <update_time+0x22>
      p->total_wtime++;
    80001f78:	1dc4a783          	lw	a5,476(s1)
    80001f7c:	2785                	addiw	a5,a5,1
    80001f7e:	1cf4ae23          	sw	a5,476(s1)
    80001f82:	bfd1                	j	80001f56 <update_time+0x2c>
}
    80001f84:	70a2                	ld	ra,40(sp)
    80001f86:	7402                	ld	s0,32(sp)
    80001f88:	64e2                	ld	s1,24(sp)
    80001f8a:	6942                	ld	s2,16(sp)
    80001f8c:	69a2                	ld	s3,8(sp)
    80001f8e:	6145                	addi	sp,sp,48
    80001f90:	8082                	ret

0000000080001f92 <strace>:
{
    80001f92:	1101                	addi	sp,sp,-32
    80001f94:	ec06                	sd	ra,24(sp)
    80001f96:	e822                	sd	s0,16(sp)
    80001f98:	e426                	sd	s1,8(sp)
    80001f9a:	e04a                	sd	s2,0(sp)
    80001f9c:	1000                	addi	s0,sp,32
    80001f9e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	9f6080e7          	jalr	-1546(ra) # 80001996 <myproc>
    80001fa8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	c26080e7          	jalr	-986(ra) # 80000bd0 <acquire>
  p->trace_mask = mask;
    80001fb2:	1724a423          	sw	s2,360(s1)
  release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ccc080e7          	jalr	-820(ra) # 80000c84 <release>
}
    80001fc0:	4501                	li	a0,0
    80001fc2:	60e2                	ld	ra,24(sp)
    80001fc4:	6442                	ld	s0,16(sp)
    80001fc6:	64a2                	ld	s1,8(sp)
    80001fc8:	6902                	ld	s2,0(sp)
    80001fca:	6105                	addi	sp,sp,32
    80001fcc:	8082                	ret

0000000080001fce <swap>:
{
    80001fce:	1141                	addi	sp,sp,-16
    80001fd0:	e422                	sd	s0,8(sp)
    80001fd2:	0800                	addi	s0,sp,16
}
    80001fd4:	6422                	ld	s0,8(sp)
    80001fd6:	0141                	addi	sp,sp,16
    80001fd8:	8082                	ret

0000000080001fda <bubbleSort>:
{
    80001fda:	1141                	addi	sp,sp,-16
    80001fdc:	e422                	sd	s0,8(sp)
    80001fde:	0800                	addi	s0,sp,16
  for (int pri = 0; pri < 5; pri++)
    80001fe0:	01458513          	addi	a0,a1,20
      for (int k = 0; k < i[pri] - j - 1; k++)
    80001fe4:	4601                	li	a2,0
    for (int j = 0; j < i[pri]; j++)
    80001fe6:	587d                	li	a6,-1
    80001fe8:	a039                	j	80001ff6 <bubbleSort+0x1c>
    80001fea:	36fd                	addiw	a3,a3,-1
    80001fec:	01069963          	bne	a3,a6,80001ffe <bubbleSort+0x24>
  for (int pri = 0; pri < 5; pri++)
    80001ff0:	0591                	addi	a1,a1,4
    80001ff2:	02b50063          	beq	a0,a1,80002012 <bubbleSort+0x38>
    for (int j = 0; j < i[pri]; j++)
    80001ff6:	4194                	lw	a3,0(a1)
    80001ff8:	fed05ce3          	blez	a3,80001ff0 <bubbleSort+0x16>
    80001ffc:	36fd                	addiw	a3,a3,-1
      for (int k = 0; k < i[pri] - j - 1; k++)
    80001ffe:	0006871b          	sext.w	a4,a3
    80002002:	87b2                	mv	a5,a2
    80002004:	fee053e3          	blez	a4,80001fea <bubbleSort+0x10>
        if (q[pri][k]->index > q[pri][k + 1]->index)
    80002008:	2785                	addiw	a5,a5,1
      for (int k = 0; k < i[pri] - j - 1; k++)
    8000200a:	fee79fe3          	bne	a5,a4,80002008 <bubbleSort+0x2e>
    for (int j = 0; j < i[pri]; j++)
    8000200e:	36fd                	addiw	a3,a3,-1
    80002010:	b7fd                	j	80001ffe <bubbleSort+0x24>
}
    80002012:	6422                	ld	s0,8(sp)
    80002014:	0141                	addi	sp,sp,16
    80002016:	8082                	ret

0000000080002018 <scheduler>:
{
    80002018:	7139                	addi	sp,sp,-64
    8000201a:	fc06                	sd	ra,56(sp)
    8000201c:	f822                	sd	s0,48(sp)
    8000201e:	f426                	sd	s1,40(sp)
    80002020:	f04a                	sd	s2,32(sp)
    80002022:	ec4e                	sd	s3,24(sp)
    80002024:	e852                	sd	s4,16(sp)
    80002026:	e456                	sd	s5,8(sp)
    80002028:	e05a                	sd	s6,0(sp)
    8000202a:	0080                	addi	s0,sp,64
    8000202c:	8792                	mv	a5,tp
  int id = r_tp();
    8000202e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002030:	00779a93          	slli	s5,a5,0x7
    80002034:	0000f717          	auipc	a4,0xf
    80002038:	26c70713          	addi	a4,a4,620 # 800112a0 <pid_lock>
    8000203c:	9756                	add	a4,a4,s5
    8000203e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002042:	0000f717          	auipc	a4,0xf
    80002046:	29670713          	addi	a4,a4,662 # 800112d8 <cpus+0x8>
    8000204a:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000204c:	498d                	li	s3,3
        p->state = RUNNING;
    8000204e:	4b11                	li	s6,4
        c->proc = p;
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	0000fa17          	auipc	s4,0xf
    80002056:	24ea0a13          	addi	s4,s4,590 # 800112a0 <pid_lock>
    8000205a:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000205c:	00018917          	auipc	s2,0x18
    80002060:	88c90913          	addi	s2,s2,-1908 # 800198e8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002064:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002068:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000206c:	10079073          	csrw	sstatus,a5
    80002070:	00010497          	auipc	s1,0x10
    80002074:	07848493          	addi	s1,s1,120 # 800120e8 <proc>
    80002078:	a811                	j	8000208c <scheduler+0x74>
      release(&p->lock);
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c08080e7          	jalr	-1016(ra) # 80000c84 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002084:	1e048493          	addi	s1,s1,480
    80002088:	fd248ee3          	beq	s1,s2,80002064 <scheduler+0x4c>
      acquire(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b42080e7          	jalr	-1214(ra) # 80000bd0 <acquire>
      if (p->state == RUNNABLE)
    80002096:	4c9c                	lw	a5,24(s1)
    80002098:	ff3791e3          	bne	a5,s3,8000207a <scheduler+0x62>
        p->state = RUNNING;
    8000209c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020a0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020a4:	06048593          	addi	a1,s1,96
    800020a8:	8556                	mv	a0,s5
    800020aa:	00001097          	auipc	ra,0x1
    800020ae:	82e080e7          	jalr	-2002(ra) # 800028d8 <swtch>
        c->proc = 0;
    800020b2:	020a3823          	sd	zero,48(s4)
    800020b6:	b7d1                	j	8000207a <scheduler+0x62>

00000000800020b8 <setpriority>:
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	892a                	mv	s2,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800020cc:	00010497          	auipc	s1,0x10
    800020d0:	01c48493          	addi	s1,s1,28 # 800120e8 <proc>
    800020d4:	00018717          	auipc	a4,0x18
    800020d8:	81470713          	addi	a4,a4,-2028 # 800198e8 <tickslock>
    if (p->pid == pid)
    800020dc:	589c                	lw	a5,48(s1)
    800020de:	00b78863          	beq	a5,a1,800020ee <setpriority+0x36>
  for (p = proc; p < &proc[NPROC]; p++)
    800020e2:	1e048493          	addi	s1,s1,480
    800020e6:	fee49be3          	bne	s1,a4,800020dc <setpriority+0x24>
  int old_SP = -1;
    800020ea:	5a7d                	li	s4,-1
    800020ec:	a0b1                	j	80002138 <setpriority+0x80>
      old_SP = p->SP;
    800020ee:	1844a983          	lw	s3,388(s1)
    800020f2:	00098a1b          	sext.w	s4,s3
      acquire(&p->lock);
    800020f6:	8aa6                	mv	s5,s1
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	ad6080e7          	jalr	-1322(ra) # 80000bd0 <acquire>
      p->SP = priority;
    80002102:	fff94793          	not	a5,s2
    80002106:	97fd                	srai	a5,a5,0x3f
    80002108:	00f97933          	and	s2,s2,a5
    8000210c:	87ca                	mv	a5,s2
    8000210e:	2901                	sext.w	s2,s2
    80002110:	06400713          	li	a4,100
    80002114:	01275463          	bge	a4,s2,8000211c <setpriority+0x64>
    80002118:	06400793          	li	a5,100
    8000211c:	18f4a223          	sw	a5,388(s1)
      p->niceness = 5;
    80002120:	4795                	li	a5,5
    80002122:	18f4a623          	sw	a5,396(s1)
      release(&p->lock);
    80002126:	8556                	mv	a0,s5
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b5c080e7          	jalr	-1188(ra) # 80000c84 <release>
      if (p->SP < old_SP)
    80002130:	1844a783          	lw	a5,388(s1)
    80002134:	0137ec63          	bltu	a5,s3,8000214c <setpriority+0x94>
}
    80002138:	8552                	mv	a0,s4
    8000213a:	70e2                	ld	ra,56(sp)
    8000213c:	7442                	ld	s0,48(sp)
    8000213e:	74a2                	ld	s1,40(sp)
    80002140:	7902                	ld	s2,32(sp)
    80002142:	69e2                	ld	s3,24(sp)
    80002144:	6a42                	ld	s4,16(sp)
    80002146:	6aa2                	ld	s5,8(sp)
    80002148:	6121                	addi	sp,sp,64
    8000214a:	8082                	ret
        scheduler();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	ecc080e7          	jalr	-308(ra) # 80002018 <scheduler>

0000000080002154 <sched>:
{
    80002154:	7179                	addi	sp,sp,-48
    80002156:	f406                	sd	ra,40(sp)
    80002158:	f022                	sd	s0,32(sp)
    8000215a:	ec26                	sd	s1,24(sp)
    8000215c:	e84a                	sd	s2,16(sp)
    8000215e:	e44e                	sd	s3,8(sp)
    80002160:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002162:	00000097          	auipc	ra,0x0
    80002166:	834080e7          	jalr	-1996(ra) # 80001996 <myproc>
    8000216a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	9ea080e7          	jalr	-1558(ra) # 80000b56 <holding>
    80002174:	c93d                	beqz	a0,800021ea <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002176:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002178:	2781                	sext.w	a5,a5
    8000217a:	079e                	slli	a5,a5,0x7
    8000217c:	0000f717          	auipc	a4,0xf
    80002180:	12470713          	addi	a4,a4,292 # 800112a0 <pid_lock>
    80002184:	97ba                	add	a5,a5,a4
    80002186:	0a87a703          	lw	a4,168(a5)
    8000218a:	4785                	li	a5,1
    8000218c:	06f71763          	bne	a4,a5,800021fa <sched+0xa6>
  if (p->state == RUNNING)
    80002190:	4c98                	lw	a4,24(s1)
    80002192:	4791                	li	a5,4
    80002194:	06f70b63          	beq	a4,a5,8000220a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002198:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000219c:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000219e:	efb5                	bnez	a5,8000221a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021a2:	0000f917          	auipc	s2,0xf
    800021a6:	0fe90913          	addi	s2,s2,254 # 800112a0 <pid_lock>
    800021aa:	2781                	sext.w	a5,a5
    800021ac:	079e                	slli	a5,a5,0x7
    800021ae:	97ca                	add	a5,a5,s2
    800021b0:	0ac7a983          	lw	s3,172(a5)
    800021b4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021b6:	2781                	sext.w	a5,a5
    800021b8:	079e                	slli	a5,a5,0x7
    800021ba:	0000f597          	auipc	a1,0xf
    800021be:	11e58593          	addi	a1,a1,286 # 800112d8 <cpus+0x8>
    800021c2:	95be                	add	a1,a1,a5
    800021c4:	06048513          	addi	a0,s1,96
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	710080e7          	jalr	1808(ra) # 800028d8 <swtch>
    800021d0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021d2:	2781                	sext.w	a5,a5
    800021d4:	079e                	slli	a5,a5,0x7
    800021d6:	993e                	add	s2,s2,a5
    800021d8:	0b392623          	sw	s3,172(s2)
}
    800021dc:	70a2                	ld	ra,40(sp)
    800021de:	7402                	ld	s0,32(sp)
    800021e0:	64e2                	ld	s1,24(sp)
    800021e2:	6942                	ld	s2,16(sp)
    800021e4:	69a2                	ld	s3,8(sp)
    800021e6:	6145                	addi	sp,sp,48
    800021e8:	8082                	ret
    panic("sched p->lock");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	02e50513          	addi	a0,a0,46 # 80008218 <digits+0x1d8>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	348080e7          	jalr	840(ra) # 8000053a <panic>
    panic("sched locks");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	02e50513          	addi	a0,a0,46 # 80008228 <digits+0x1e8>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	338080e7          	jalr	824(ra) # 8000053a <panic>
    panic("sched running");
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	02e50513          	addi	a0,a0,46 # 80008238 <digits+0x1f8>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	328080e7          	jalr	808(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000221a:	00006517          	auipc	a0,0x6
    8000221e:	02e50513          	addi	a0,a0,46 # 80008248 <digits+0x208>
    80002222:	ffffe097          	auipc	ra,0xffffe
    80002226:	318080e7          	jalr	792(ra) # 8000053a <panic>

000000008000222a <yield>:
{
    8000222a:	1101                	addi	sp,sp,-32
    8000222c:	ec06                	sd	ra,24(sp)
    8000222e:	e822                	sd	s0,16(sp)
    80002230:	e426                	sd	s1,8(sp)
    80002232:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	762080e7          	jalr	1890(ra) # 80001996 <myproc>
    8000223c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	992080e7          	jalr	-1646(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002246:	478d                	li	a5,3
    80002248:	cc9c                	sw	a5,24(s1)
  sched();
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	f0a080e7          	jalr	-246(ra) # 80002154 <sched>
  release(&p->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a30080e7          	jalr	-1488(ra) # 80000c84 <release>
}
    8000225c:	60e2                	ld	ra,24(sp)
    8000225e:	6442                	ld	s0,16(sp)
    80002260:	64a2                	ld	s1,8(sp)
    80002262:	6105                	addi	sp,sp,32
    80002264:	8082                	ret

0000000080002266 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002266:	7179                	addi	sp,sp,-48
    80002268:	f406                	sd	ra,40(sp)
    8000226a:	f022                	sd	s0,32(sp)
    8000226c:	ec26                	sd	s1,24(sp)
    8000226e:	e84a                	sd	s2,16(sp)
    80002270:	e44e                	sd	s3,8(sp)
    80002272:	1800                	addi	s0,sp,48
    80002274:	89aa                	mv	s3,a0
    80002276:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	71e080e7          	jalr	1822(ra) # 80001996 <myproc>
    80002280:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	94e080e7          	jalr	-1714(ra) # 80000bd0 <acquire>
  release(lk);
    8000228a:	854a                	mv	a0,s2
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	9f8080e7          	jalr	-1544(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002294:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002298:	4789                	li	a5,2
    8000229a:	cc9c                	sw	a5,24(s1)
  p->stime = ticks;
    8000229c:	00007797          	auipc	a5,0x7
    800022a0:	d947a783          	lw	a5,-620(a5) # 80009030 <ticks>
    800022a4:	16f4ac23          	sw	a5,376(s1)

  sched();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	eac080e7          	jalr	-340(ra) # 80002154 <sched>

  // Tidy up.
  p->chan = 0;
    800022b0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9ce080e7          	jalr	-1586(ra) # 80000c84 <release>
  acquire(lk);
    800022be:	854a                	mv	a0,s2
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	910080e7          	jalr	-1776(ra) # 80000bd0 <acquire>
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret

00000000800022d6 <wait>:
{
    800022d6:	715d                	addi	sp,sp,-80
    800022d8:	e486                	sd	ra,72(sp)
    800022da:	e0a2                	sd	s0,64(sp)
    800022dc:	fc26                	sd	s1,56(sp)
    800022de:	f84a                	sd	s2,48(sp)
    800022e0:	f44e                	sd	s3,40(sp)
    800022e2:	f052                	sd	s4,32(sp)
    800022e4:	ec56                	sd	s5,24(sp)
    800022e6:	e85a                	sd	s6,16(sp)
    800022e8:	e45e                	sd	s7,8(sp)
    800022ea:	e062                	sd	s8,0(sp)
    800022ec:	0880                	addi	s0,sp,80
    800022ee:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	6a6080e7          	jalr	1702(ra) # 80001996 <myproc>
    800022f8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022fa:	0000f517          	auipc	a0,0xf
    800022fe:	fbe50513          	addi	a0,a0,-66 # 800112b8 <wait_lock>
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	8ce080e7          	jalr	-1842(ra) # 80000bd0 <acquire>
    havekids = 0;
    8000230a:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000230c:	4a15                	li	s4,5
        havekids = 1;
    8000230e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002310:	00017997          	auipc	s3,0x17
    80002314:	5d898993          	addi	s3,s3,1496 # 800198e8 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002318:	0000fc17          	auipc	s8,0xf
    8000231c:	fa0c0c13          	addi	s8,s8,-96 # 800112b8 <wait_lock>
    havekids = 0;
    80002320:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002322:	00010497          	auipc	s1,0x10
    80002326:	dc648493          	addi	s1,s1,-570 # 800120e8 <proc>
    8000232a:	a0bd                	j	80002398 <wait+0xc2>
          pid = np->pid;
    8000232c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002330:	000b0e63          	beqz	s6,8000234c <wait+0x76>
    80002334:	4691                	li	a3,4
    80002336:	02c48613          	addi	a2,s1,44
    8000233a:	85da                	mv	a1,s6
    8000233c:	05093503          	ld	a0,80(s2)
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	31a080e7          	jalr	794(ra) # 8000165a <copyout>
    80002348:	02054563          	bltz	a0,80002372 <wait+0x9c>
          freeproc(np);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	7fa080e7          	jalr	2042(ra) # 80001b48 <freeproc>
          release(&np->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	92c080e7          	jalr	-1748(ra) # 80000c84 <release>
          release(&wait_lock);
    80002360:	0000f517          	auipc	a0,0xf
    80002364:	f5850513          	addi	a0,a0,-168 # 800112b8 <wait_lock>
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	91c080e7          	jalr	-1764(ra) # 80000c84 <release>
          return pid;
    80002370:	a09d                	j	800023d6 <wait+0x100>
            release(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	910080e7          	jalr	-1776(ra) # 80000c84 <release>
            release(&wait_lock);
    8000237c:	0000f517          	auipc	a0,0xf
    80002380:	f3c50513          	addi	a0,a0,-196 # 800112b8 <wait_lock>
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	900080e7          	jalr	-1792(ra) # 80000c84 <release>
            return -1;
    8000238c:	59fd                	li	s3,-1
    8000238e:	a0a1                	j	800023d6 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002390:	1e048493          	addi	s1,s1,480
    80002394:	03348463          	beq	s1,s3,800023bc <wait+0xe6>
      if (np->parent == p)
    80002398:	7c9c                	ld	a5,56(s1)
    8000239a:	ff279be3          	bne	a5,s2,80002390 <wait+0xba>
        acquire(&np->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	830080e7          	jalr	-2000(ra) # 80000bd0 <acquire>
        if (np->state == ZOMBIE)
    800023a8:	4c9c                	lw	a5,24(s1)
    800023aa:	f94781e3          	beq	a5,s4,8000232c <wait+0x56>
        release(&np->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8d4080e7          	jalr	-1836(ra) # 80000c84 <release>
        havekids = 1;
    800023b8:	8756                	mv	a4,s5
    800023ba:	bfd9                	j	80002390 <wait+0xba>
    if (!havekids || p->killed)
    800023bc:	c701                	beqz	a4,800023c4 <wait+0xee>
    800023be:	02892783          	lw	a5,40(s2)
    800023c2:	c79d                	beqz	a5,800023f0 <wait+0x11a>
      release(&wait_lock);
    800023c4:	0000f517          	auipc	a0,0xf
    800023c8:	ef450513          	addi	a0,a0,-268 # 800112b8 <wait_lock>
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8b8080e7          	jalr	-1864(ra) # 80000c84 <release>
      return -1;
    800023d4:	59fd                	li	s3,-1
}
    800023d6:	854e                	mv	a0,s3
    800023d8:	60a6                	ld	ra,72(sp)
    800023da:	6406                	ld	s0,64(sp)
    800023dc:	74e2                	ld	s1,56(sp)
    800023de:	7942                	ld	s2,48(sp)
    800023e0:	79a2                	ld	s3,40(sp)
    800023e2:	7a02                	ld	s4,32(sp)
    800023e4:	6ae2                	ld	s5,24(sp)
    800023e6:	6b42                	ld	s6,16(sp)
    800023e8:	6ba2                	ld	s7,8(sp)
    800023ea:	6c02                	ld	s8,0(sp)
    800023ec:	6161                	addi	sp,sp,80
    800023ee:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800023f0:	85e2                	mv	a1,s8
    800023f2:	854a                	mv	a0,s2
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	e72080e7          	jalr	-398(ra) # 80002266 <sleep>
    havekids = 0;
    800023fc:	b715                	j	80002320 <wait+0x4a>

00000000800023fe <waitx>:
{
    800023fe:	711d                	addi	sp,sp,-96
    80002400:	ec86                	sd	ra,88(sp)
    80002402:	e8a2                	sd	s0,80(sp)
    80002404:	e4a6                	sd	s1,72(sp)
    80002406:	e0ca                	sd	s2,64(sp)
    80002408:	fc4e                	sd	s3,56(sp)
    8000240a:	f852                	sd	s4,48(sp)
    8000240c:	f456                	sd	s5,40(sp)
    8000240e:	f05a                	sd	s6,32(sp)
    80002410:	ec5e                	sd	s7,24(sp)
    80002412:	e862                	sd	s8,16(sp)
    80002414:	e466                	sd	s9,8(sp)
    80002416:	e06a                	sd	s10,0(sp)
    80002418:	1080                	addi	s0,sp,96
    8000241a:	8b2a                	mv	s6,a0
    8000241c:	8c2e                	mv	s8,a1
    8000241e:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	576080e7          	jalr	1398(ra) # 80001996 <myproc>
    80002428:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000242a:	0000f517          	auipc	a0,0xf
    8000242e:	e8e50513          	addi	a0,a0,-370 # 800112b8 <wait_lock>
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	79e080e7          	jalr	1950(ra) # 80000bd0 <acquire>
    havekids = 0;
    8000243a:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000243c:	4a15                	li	s4,5
        havekids = 1;
    8000243e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002440:	00017997          	auipc	s3,0x17
    80002444:	4a898993          	addi	s3,s3,1192 # 800198e8 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002448:	0000fd17          	auipc	s10,0xf
    8000244c:	e70d0d13          	addi	s10,s10,-400 # 800112b8 <wait_lock>
    havekids = 0;
    80002450:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002452:	00010497          	auipc	s1,0x10
    80002456:	c9648493          	addi	s1,s1,-874 # 800120e8 <proc>
    8000245a:	a059                	j	800024e0 <waitx+0xe2>
          pid = np->pid;
    8000245c:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002460:	1704a783          	lw	a5,368(s1)
    80002464:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002468:	16c4a703          	lw	a4,364(s1)
    8000246c:	9f3d                	addw	a4,a4,a5
    8000246e:	1744a783          	lw	a5,372(s1)
    80002472:	9f99                	subw	a5,a5,a4
    80002474:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002478:	000b0e63          	beqz	s6,80002494 <waitx+0x96>
    8000247c:	4691                	li	a3,4
    8000247e:	02c48613          	addi	a2,s1,44
    80002482:	85da                	mv	a1,s6
    80002484:	05093503          	ld	a0,80(s2)
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	1d2080e7          	jalr	466(ra) # 8000165a <copyout>
    80002490:	02054563          	bltz	a0,800024ba <waitx+0xbc>
          freeproc(np);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	6b2080e7          	jalr	1714(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7e4080e7          	jalr	2020(ra) # 80000c84 <release>
          release(&wait_lock);
    800024a8:	0000f517          	auipc	a0,0xf
    800024ac:	e1050513          	addi	a0,a0,-496 # 800112b8 <wait_lock>
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7d4080e7          	jalr	2004(ra) # 80000c84 <release>
          return pid;
    800024b8:	a09d                	j	8000251e <waitx+0x120>
            release(&np->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7c8080e7          	jalr	1992(ra) # 80000c84 <release>
            release(&wait_lock);
    800024c4:	0000f517          	auipc	a0,0xf
    800024c8:	df450513          	addi	a0,a0,-524 # 800112b8 <wait_lock>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7b8080e7          	jalr	1976(ra) # 80000c84 <release>
            return -1;
    800024d4:	59fd                	li	s3,-1
    800024d6:	a0a1                	j	8000251e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800024d8:	1e048493          	addi	s1,s1,480
    800024dc:	03348463          	beq	s1,s3,80002504 <waitx+0x106>
      if (np->parent == p)
    800024e0:	7c9c                	ld	a5,56(s1)
    800024e2:	ff279be3          	bne	a5,s2,800024d8 <waitx+0xda>
        acquire(&np->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	6e8080e7          	jalr	1768(ra) # 80000bd0 <acquire>
        if (np->state == ZOMBIE)
    800024f0:	4c9c                	lw	a5,24(s1)
    800024f2:	f74785e3          	beq	a5,s4,8000245c <waitx+0x5e>
        release(&np->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	78c080e7          	jalr	1932(ra) # 80000c84 <release>
        havekids = 1;
    80002500:	8756                	mv	a4,s5
    80002502:	bfd9                	j	800024d8 <waitx+0xda>
    if (!havekids || p->killed)
    80002504:	c701                	beqz	a4,8000250c <waitx+0x10e>
    80002506:	02892783          	lw	a5,40(s2)
    8000250a:	cb8d                	beqz	a5,8000253c <waitx+0x13e>
      release(&wait_lock);
    8000250c:	0000f517          	auipc	a0,0xf
    80002510:	dac50513          	addi	a0,a0,-596 # 800112b8 <wait_lock>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	770080e7          	jalr	1904(ra) # 80000c84 <release>
      return -1;
    8000251c:	59fd                	li	s3,-1
}
    8000251e:	854e                	mv	a0,s3
    80002520:	60e6                	ld	ra,88(sp)
    80002522:	6446                	ld	s0,80(sp)
    80002524:	64a6                	ld	s1,72(sp)
    80002526:	6906                	ld	s2,64(sp)
    80002528:	79e2                	ld	s3,56(sp)
    8000252a:	7a42                	ld	s4,48(sp)
    8000252c:	7aa2                	ld	s5,40(sp)
    8000252e:	7b02                	ld	s6,32(sp)
    80002530:	6be2                	ld	s7,24(sp)
    80002532:	6c42                	ld	s8,16(sp)
    80002534:	6ca2                	ld	s9,8(sp)
    80002536:	6d02                	ld	s10,0(sp)
    80002538:	6125                	addi	sp,sp,96
    8000253a:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000253c:	85ea                	mv	a1,s10
    8000253e:	854a                	mv	a0,s2
    80002540:	00000097          	auipc	ra,0x0
    80002544:	d26080e7          	jalr	-730(ra) # 80002266 <sleep>
    havekids = 0;
    80002548:	b721                	j	80002450 <waitx+0x52>

000000008000254a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000254a:	7139                	addi	sp,sp,-64
    8000254c:	fc06                	sd	ra,56(sp)
    8000254e:	f822                	sd	s0,48(sp)
    80002550:	f426                	sd	s1,40(sp)
    80002552:	f04a                	sd	s2,32(sp)
    80002554:	ec4e                	sd	s3,24(sp)
    80002556:	e852                	sd	s4,16(sp)
    80002558:	e456                	sd	s5,8(sp)
    8000255a:	e05a                	sd	s6,0(sp)
    8000255c:	0080                	addi	s0,sp,64
    8000255e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002560:	00010497          	auipc	s1,0x10
    80002564:	b8848493          	addi	s1,s1,-1144 # 800120e8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002568:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000256a:	4b0d                	li	s6,3
        p->wtime = ticks;
    8000256c:	00007a97          	auipc	s5,0x7
    80002570:	ac4a8a93          	addi	s5,s5,-1340 # 80009030 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002574:	00017917          	auipc	s2,0x17
    80002578:	37490913          	addi	s2,s2,884 # 800198e8 <tickslock>
    8000257c:	a811                	j	80002590 <wakeup+0x46>

        p->index = c[p->priority];
        c[p->priority]++;
#endif
      }
      release(&p->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	704080e7          	jalr	1796(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002588:	1e048493          	addi	s1,s1,480
    8000258c:	03248f63          	beq	s1,s2,800025ca <wakeup+0x80>
    if (p != myproc())
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	406080e7          	jalr	1030(ra) # 80001996 <myproc>
    80002598:	fea488e3          	beq	s1,a0,80002588 <wakeup+0x3e>
      acquire(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	632080e7          	jalr	1586(ra) # 80000bd0 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800025a6:	4c9c                	lw	a5,24(s1)
    800025a8:	fd379be3          	bne	a5,s3,8000257e <wakeup+0x34>
    800025ac:	709c                	ld	a5,32(s1)
    800025ae:	fd4798e3          	bne	a5,s4,8000257e <wakeup+0x34>
        p->state = RUNNABLE;
    800025b2:	0164ac23          	sw	s6,24(s1)
        p->wtime = ticks;
    800025b6:	000aa783          	lw	a5,0(s5)
    800025ba:	16f4ae23          	sw	a5,380(s1)
        p->total_s_time = (p->wtime - p->stime);
    800025be:	1784a703          	lw	a4,376(s1)
    800025c2:	9f99                	subw	a5,a5,a4
    800025c4:	18f4a023          	sw	a5,384(s1)
    800025c8:	bf5d                	j	8000257e <wakeup+0x34>
    }
  }
}
    800025ca:	70e2                	ld	ra,56(sp)
    800025cc:	7442                	ld	s0,48(sp)
    800025ce:	74a2                	ld	s1,40(sp)
    800025d0:	7902                	ld	s2,32(sp)
    800025d2:	69e2                	ld	s3,24(sp)
    800025d4:	6a42                	ld	s4,16(sp)
    800025d6:	6aa2                	ld	s5,8(sp)
    800025d8:	6b02                	ld	s6,0(sp)
    800025da:	6121                	addi	sp,sp,64
    800025dc:	8082                	ret

00000000800025de <reparent>:
{
    800025de:	7179                	addi	sp,sp,-48
    800025e0:	f406                	sd	ra,40(sp)
    800025e2:	f022                	sd	s0,32(sp)
    800025e4:	ec26                	sd	s1,24(sp)
    800025e6:	e84a                	sd	s2,16(sp)
    800025e8:	e44e                	sd	s3,8(sp)
    800025ea:	e052                	sd	s4,0(sp)
    800025ec:	1800                	addi	s0,sp,48
    800025ee:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025f0:	00010497          	auipc	s1,0x10
    800025f4:	af848493          	addi	s1,s1,-1288 # 800120e8 <proc>
      pp->parent = initproc;
    800025f8:	00007a17          	auipc	s4,0x7
    800025fc:	a30a0a13          	addi	s4,s4,-1488 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002600:	00017997          	auipc	s3,0x17
    80002604:	2e898993          	addi	s3,s3,744 # 800198e8 <tickslock>
    80002608:	a029                	j	80002612 <reparent+0x34>
    8000260a:	1e048493          	addi	s1,s1,480
    8000260e:	01348d63          	beq	s1,s3,80002628 <reparent+0x4a>
    if (pp->parent == p)
    80002612:	7c9c                	ld	a5,56(s1)
    80002614:	ff279be3          	bne	a5,s2,8000260a <reparent+0x2c>
      pp->parent = initproc;
    80002618:	000a3503          	ld	a0,0(s4)
    8000261c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000261e:	00000097          	auipc	ra,0x0
    80002622:	f2c080e7          	jalr	-212(ra) # 8000254a <wakeup>
    80002626:	b7d5                	j	8000260a <reparent+0x2c>
}
    80002628:	70a2                	ld	ra,40(sp)
    8000262a:	7402                	ld	s0,32(sp)
    8000262c:	64e2                	ld	s1,24(sp)
    8000262e:	6942                	ld	s2,16(sp)
    80002630:	69a2                	ld	s3,8(sp)
    80002632:	6a02                	ld	s4,0(sp)
    80002634:	6145                	addi	sp,sp,48
    80002636:	8082                	ret

0000000080002638 <exit>:
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	e052                	sd	s4,0(sp)
    80002646:	1800                	addi	s0,sp,48
    80002648:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000264a:	fffff097          	auipc	ra,0xfffff
    8000264e:	34c080e7          	jalr	844(ra) # 80001996 <myproc>
    80002652:	89aa                	mv	s3,a0
  if (p == initproc)
    80002654:	00007797          	auipc	a5,0x7
    80002658:	9d47b783          	ld	a5,-1580(a5) # 80009028 <initproc>
    8000265c:	0d050493          	addi	s1,a0,208
    80002660:	15050913          	addi	s2,a0,336
    80002664:	02a79363          	bne	a5,a0,8000268a <exit+0x52>
    panic("init exiting");
    80002668:	00006517          	auipc	a0,0x6
    8000266c:	bf850513          	addi	a0,a0,-1032 # 80008260 <digits+0x220>
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	eca080e7          	jalr	-310(ra) # 8000053a <panic>
      fileclose(f);
    80002678:	00002097          	auipc	ra,0x2
    8000267c:	362080e7          	jalr	866(ra) # 800049da <fileclose>
      p->ofile[fd] = 0;
    80002680:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002684:	04a1                	addi	s1,s1,8
    80002686:	01248563          	beq	s1,s2,80002690 <exit+0x58>
    if (p->ofile[fd])
    8000268a:	6088                	ld	a0,0(s1)
    8000268c:	f575                	bnez	a0,80002678 <exit+0x40>
    8000268e:	bfdd                	j	80002684 <exit+0x4c>
  begin_op();
    80002690:	00002097          	auipc	ra,0x2
    80002694:	e82080e7          	jalr	-382(ra) # 80004512 <begin_op>
  iput(p->cwd);
    80002698:	1509b503          	ld	a0,336(s3)
    8000269c:	00001097          	auipc	ra,0x1
    800026a0:	654080e7          	jalr	1620(ra) # 80003cf0 <iput>
  end_op();
    800026a4:	00002097          	auipc	ra,0x2
    800026a8:	eec080e7          	jalr	-276(ra) # 80004590 <end_op>
  p->cwd = 0;
    800026ac:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026b0:	0000f497          	auipc	s1,0xf
    800026b4:	c0848493          	addi	s1,s1,-1016 # 800112b8 <wait_lock>
    800026b8:	8526                	mv	a0,s1
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	516080e7          	jalr	1302(ra) # 80000bd0 <acquire>
  reparent(p);
    800026c2:	854e                	mv	a0,s3
    800026c4:	00000097          	auipc	ra,0x0
    800026c8:	f1a080e7          	jalr	-230(ra) # 800025de <reparent>
  wakeup(p->parent);
    800026cc:	0389b503          	ld	a0,56(s3)
    800026d0:	00000097          	auipc	ra,0x0
    800026d4:	e7a080e7          	jalr	-390(ra) # 8000254a <wakeup>
  acquire(&p->lock);
    800026d8:	854e                	mv	a0,s3
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	4f6080e7          	jalr	1270(ra) # 80000bd0 <acquire>
  p->xstate = status;
    800026e2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026e6:	4795                	li	a5,5
    800026e8:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800026ec:	00007797          	auipc	a5,0x7
    800026f0:	9447a783          	lw	a5,-1724(a5) # 80009030 <ticks>
    800026f4:	16f9aa23          	sw	a5,372(s3)
  release(&wait_lock);
    800026f8:	8526                	mv	a0,s1
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	58a080e7          	jalr	1418(ra) # 80000c84 <release>
  sched();
    80002702:	00000097          	auipc	ra,0x0
    80002706:	a52080e7          	jalr	-1454(ra) # 80002154 <sched>
  panic("zombie exit");
    8000270a:	00006517          	auipc	a0,0x6
    8000270e:	b6650513          	addi	a0,a0,-1178 # 80008270 <digits+0x230>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	e28080e7          	jalr	-472(ra) # 8000053a <panic>

000000008000271a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000271a:	7179                	addi	sp,sp,-48
    8000271c:	f406                	sd	ra,40(sp)
    8000271e:	f022                	sd	s0,32(sp)
    80002720:	ec26                	sd	s1,24(sp)
    80002722:	e84a                	sd	s2,16(sp)
    80002724:	e44e                	sd	s3,8(sp)
    80002726:	1800                	addi	s0,sp,48
    80002728:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000272a:	00010497          	auipc	s1,0x10
    8000272e:	9be48493          	addi	s1,s1,-1602 # 800120e8 <proc>
    80002732:	00017997          	auipc	s3,0x17
    80002736:	1b698993          	addi	s3,s3,438 # 800198e8 <tickslock>
  {
    acquire(&p->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	494080e7          	jalr	1172(ra) # 80000bd0 <acquire>
    if (p->pid == pid)
    80002744:	589c                	lw	a5,48(s1)
    80002746:	01278d63          	beq	a5,s2,80002760 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	538080e7          	jalr	1336(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002754:	1e048493          	addi	s1,s1,480
    80002758:	ff3491e3          	bne	s1,s3,8000273a <kill+0x20>
  }
  return -1;
    8000275c:	557d                	li	a0,-1
    8000275e:	a829                	j	80002778 <kill+0x5e>
      p->killed = 1;
    80002760:	4785                	li	a5,1
    80002762:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002764:	4c98                	lw	a4,24(s1)
    80002766:	4789                	li	a5,2
    80002768:	00f70f63          	beq	a4,a5,80002786 <kill+0x6c>
      release(&p->lock);
    8000276c:	8526                	mv	a0,s1
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	516080e7          	jalr	1302(ra) # 80000c84 <release>
      return 0;
    80002776:	4501                	li	a0,0
}
    80002778:	70a2                	ld	ra,40(sp)
    8000277a:	7402                	ld	s0,32(sp)
    8000277c:	64e2                	ld	s1,24(sp)
    8000277e:	6942                	ld	s2,16(sp)
    80002780:	69a2                	ld	s3,8(sp)
    80002782:	6145                	addi	sp,sp,48
    80002784:	8082                	ret
        p->state = RUNNABLE;
    80002786:	478d                	li	a5,3
    80002788:	cc9c                	sw	a5,24(s1)
    8000278a:	b7cd                	j	8000276c <kill+0x52>

000000008000278c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000278c:	7179                	addi	sp,sp,-48
    8000278e:	f406                	sd	ra,40(sp)
    80002790:	f022                	sd	s0,32(sp)
    80002792:	ec26                	sd	s1,24(sp)
    80002794:	e84a                	sd	s2,16(sp)
    80002796:	e44e                	sd	s3,8(sp)
    80002798:	e052                	sd	s4,0(sp)
    8000279a:	1800                	addi	s0,sp,48
    8000279c:	84aa                	mv	s1,a0
    8000279e:	892e                	mv	s2,a1
    800027a0:	89b2                	mv	s3,a2
    800027a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027a4:	fffff097          	auipc	ra,0xfffff
    800027a8:	1f2080e7          	jalr	498(ra) # 80001996 <myproc>
  if (user_dst)
    800027ac:	c08d                	beqz	s1,800027ce <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027ae:	86d2                	mv	a3,s4
    800027b0:	864e                	mv	a2,s3
    800027b2:	85ca                	mv	a1,s2
    800027b4:	6928                	ld	a0,80(a0)
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	ea4080e7          	jalr	-348(ra) # 8000165a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027be:	70a2                	ld	ra,40(sp)
    800027c0:	7402                	ld	s0,32(sp)
    800027c2:	64e2                	ld	s1,24(sp)
    800027c4:	6942                	ld	s2,16(sp)
    800027c6:	69a2                	ld	s3,8(sp)
    800027c8:	6a02                	ld	s4,0(sp)
    800027ca:	6145                	addi	sp,sp,48
    800027cc:	8082                	ret
    memmove((char *)dst, src, len);
    800027ce:	000a061b          	sext.w	a2,s4
    800027d2:	85ce                	mv	a1,s3
    800027d4:	854a                	mv	a0,s2
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	552080e7          	jalr	1362(ra) # 80000d28 <memmove>
    return 0;
    800027de:	8526                	mv	a0,s1
    800027e0:	bff9                	j	800027be <either_copyout+0x32>

00000000800027e2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027e2:	7179                	addi	sp,sp,-48
    800027e4:	f406                	sd	ra,40(sp)
    800027e6:	f022                	sd	s0,32(sp)
    800027e8:	ec26                	sd	s1,24(sp)
    800027ea:	e84a                	sd	s2,16(sp)
    800027ec:	e44e                	sd	s3,8(sp)
    800027ee:	e052                	sd	s4,0(sp)
    800027f0:	1800                	addi	s0,sp,48
    800027f2:	892a                	mv	s2,a0
    800027f4:	84ae                	mv	s1,a1
    800027f6:	89b2                	mv	s3,a2
    800027f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027fa:	fffff097          	auipc	ra,0xfffff
    800027fe:	19c080e7          	jalr	412(ra) # 80001996 <myproc>
  if (user_src)
    80002802:	c08d                	beqz	s1,80002824 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002804:	86d2                	mv	a3,s4
    80002806:	864e                	mv	a2,s3
    80002808:	85ca                	mv	a1,s2
    8000280a:	6928                	ld	a0,80(a0)
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	eda080e7          	jalr	-294(ra) # 800016e6 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002814:	70a2                	ld	ra,40(sp)
    80002816:	7402                	ld	s0,32(sp)
    80002818:	64e2                	ld	s1,24(sp)
    8000281a:	6942                	ld	s2,16(sp)
    8000281c:	69a2                	ld	s3,8(sp)
    8000281e:	6a02                	ld	s4,0(sp)
    80002820:	6145                	addi	sp,sp,48
    80002822:	8082                	ret
    memmove(dst, (char *)src, len);
    80002824:	000a061b          	sext.w	a2,s4
    80002828:	85ce                	mv	a1,s3
    8000282a:	854a                	mv	a0,s2
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	4fc080e7          	jalr	1276(ra) # 80000d28 <memmove>
    return 0;
    80002834:	8526                	mv	a0,s1
    80002836:	bff9                	j	80002814 <either_copyin+0x32>

0000000080002838 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002838:	715d                	addi	sp,sp,-80
    8000283a:	e486                	sd	ra,72(sp)
    8000283c:	e0a2                	sd	s0,64(sp)
    8000283e:	fc26                	sd	s1,56(sp)
    80002840:	f84a                	sd	s2,48(sp)
    80002842:	f44e                	sd	s3,40(sp)
    80002844:	f052                	sd	s4,32(sp)
    80002846:	ec56                	sd	s5,24(sp)
    80002848:	e85a                	sd	s6,16(sp)
    8000284a:	e45e                	sd	s7,8(sp)
    8000284c:	0880                	addi	s0,sp,80
  printf("\nPID \t Priority \t State \t\t rtime \t wtime \t nrun\n");
#endif
#ifdef MLFQ
  printf("\nPID \t Priority \t State \t\t rtime \t wtime \t nrun \t q0 \t q1 \t q2 \t q3 \t q4\n");
#endif
  for (p = proc; p < &proc[NPROC]; p++)
    8000284e:	00010497          	auipc	s1,0x10
    80002852:	9f248493          	addi	s1,s1,-1550 # 80012240 <proc+0x158>
    80002856:	00017917          	auipc	s2,0x17
    8000285a:	1ea90913          	addi	s2,s2,490 # 80019a40 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002860:	00006997          	auipc	s3,0x6
    80002864:	a2098993          	addi	s3,s3,-1504 # 80008280 <digits+0x240>
#ifdef RR
    printf("\n%d %s %s", p->pid, state, p->name);
    80002868:	00006a97          	auipc	s5,0x6
    8000286c:	a20a8a93          	addi	s5,s5,-1504 # 80008288 <digits+0x248>
    printf("\n");
    80002870:	00006a17          	auipc	s4,0x6
    80002874:	858a0a13          	addi	s4,s4,-1960 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002878:	00006b97          	auipc	s7,0x6
    8000287c:	a50b8b93          	addi	s7,s7,-1456 # 800082c8 <states.0>
    80002880:	a00d                	j	800028a2 <procdump+0x6a>
    printf("\n%d %s %s", p->pid, state, p->name);
    80002882:	ed86a583          	lw	a1,-296(a3)
    80002886:	8556                	mv	a0,s5
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	cfc080e7          	jalr	-772(ra) # 80000584 <printf>
    printf("\n");
    80002890:	8552                	mv	a0,s4
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	cf2080e7          	jalr	-782(ra) # 80000584 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000289a:	1e048493          	addi	s1,s1,480
    8000289e:	03248263          	beq	s1,s2,800028c2 <procdump+0x8a>
    if (p->state == UNUSED)
    800028a2:	86a6                	mv	a3,s1
    800028a4:	ec04a783          	lw	a5,-320(s1)
    800028a8:	dbed                	beqz	a5,8000289a <procdump+0x62>
      state = "???";
    800028aa:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ac:	fcfb6be3          	bltu	s6,a5,80002882 <procdump+0x4a>
    800028b0:	02079713          	slli	a4,a5,0x20
    800028b4:	01d75793          	srli	a5,a4,0x1d
    800028b8:	97de                	add	a5,a5,s7
    800028ba:	6390                	ld	a2,0(a5)
    800028bc:	f279                	bnez	a2,80002882 <procdump+0x4a>
      state = "???";
    800028be:	864e                	mv	a2,s3
    800028c0:	b7c9                	j	80002882 <procdump+0x4a>
#ifdef MLFQ
    printf("%d \t %d \t\t %s \t %d \t %d \t %d \t %d \t %d \t %d \t %d \t %d", p->pid, p->priority, state, p->rtime, p->q_wtime[p->priority], p->num_sched, p->q_wait[0], p->q_wait[1], p->q_wait[2], p->q_wait[3], p->q_wait[4]);
    printf("\n");
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

00000000800028d8 <swtch>:
    800028d8:	00153023          	sd	ra,0(a0)
    800028dc:	00253423          	sd	sp,8(a0)
    800028e0:	e900                	sd	s0,16(a0)
    800028e2:	ed04                	sd	s1,24(a0)
    800028e4:	03253023          	sd	s2,32(a0)
    800028e8:	03353423          	sd	s3,40(a0)
    800028ec:	03453823          	sd	s4,48(a0)
    800028f0:	03553c23          	sd	s5,56(a0)
    800028f4:	05653023          	sd	s6,64(a0)
    800028f8:	05753423          	sd	s7,72(a0)
    800028fc:	05853823          	sd	s8,80(a0)
    80002900:	05953c23          	sd	s9,88(a0)
    80002904:	07a53023          	sd	s10,96(a0)
    80002908:	07b53423          	sd	s11,104(a0)
    8000290c:	0005b083          	ld	ra,0(a1)
    80002910:	0085b103          	ld	sp,8(a1)
    80002914:	6980                	ld	s0,16(a1)
    80002916:	6d84                	ld	s1,24(a1)
    80002918:	0205b903          	ld	s2,32(a1)
    8000291c:	0285b983          	ld	s3,40(a1)
    80002920:	0305ba03          	ld	s4,48(a1)
    80002924:	0385ba83          	ld	s5,56(a1)
    80002928:	0405bb03          	ld	s6,64(a1)
    8000292c:	0485bb83          	ld	s7,72(a1)
    80002930:	0505bc03          	ld	s8,80(a1)
    80002934:	0585bc83          	ld	s9,88(a1)
    80002938:	0605bd03          	ld	s10,96(a1)
    8000293c:	0685bd83          	ld	s11,104(a1)
    80002940:	8082                	ret

0000000080002942 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002942:	1141                	addi	sp,sp,-16
    80002944:	e406                	sd	ra,8(sp)
    80002946:	e022                	sd	s0,0(sp)
    80002948:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000294a:	00006597          	auipc	a1,0x6
    8000294e:	9ae58593          	addi	a1,a1,-1618 # 800082f8 <states.0+0x30>
    80002952:	00017517          	auipc	a0,0x17
    80002956:	f9650513          	addi	a0,a0,-106 # 800198e8 <tickslock>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	1e6080e7          	jalr	486(ra) # 80000b40 <initlock>
}
    80002962:	60a2                	ld	ra,8(sp)
    80002964:	6402                	ld	s0,0(sp)
    80002966:	0141                	addi	sp,sp,16
    80002968:	8082                	ret

000000008000296a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000296a:	1141                	addi	sp,sp,-16
    8000296c:	e422                	sd	s0,8(sp)
    8000296e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002970:	00003797          	auipc	a5,0x3
    80002974:	6a078793          	addi	a5,a5,1696 # 80006010 <kernelvec>
    80002978:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000297c:	6422                	ld	s0,8(sp)
    8000297e:	0141                	addi	sp,sp,16
    80002980:	8082                	ret

0000000080002982 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002982:	1141                	addi	sp,sp,-16
    80002984:	e406                	sd	ra,8(sp)
    80002986:	e022                	sd	s0,0(sp)
    80002988:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	00c080e7          	jalr	12(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002996:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002998:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000299c:	00004697          	auipc	a3,0x4
    800029a0:	66468693          	addi	a3,a3,1636 # 80007000 <_trampoline>
    800029a4:	00004717          	auipc	a4,0x4
    800029a8:	65c70713          	addi	a4,a4,1628 # 80007000 <_trampoline>
    800029ac:	8f15                	sub	a4,a4,a3
    800029ae:	040007b7          	lui	a5,0x4000
    800029b2:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029b4:	07b2                	slli	a5,a5,0xc
    800029b6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b8:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029be:	18002673          	csrr	a2,satp
    800029c2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c4:	6d30                	ld	a2,88(a0)
    800029c6:	6138                	ld	a4,64(a0)
    800029c8:	6585                	lui	a1,0x1
    800029ca:	972e                	add	a4,a4,a1
    800029cc:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ce:	6d38                	ld	a4,88(a0)
    800029d0:	00000617          	auipc	a2,0x0
    800029d4:	14660613          	addi	a2,a2,326 # 80002b16 <usertrap>
    800029d8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800029da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029dc:	8612                	mv	a2,tp
    800029de:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e0:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e4:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029e8:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f2:	6f18                	ld	a4,24(a4)
    800029f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029f8:	692c                	ld	a1,80(a0)
    800029fa:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029fc:	00004717          	auipc	a4,0x4
    80002a00:	69470713          	addi	a4,a4,1684 # 80007090 <userret>
    80002a04:	8f15                	sub	a4,a4,a3
    80002a06:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002a08:	577d                	li	a4,-1
    80002a0a:	177e                	slli	a4,a4,0x3f
    80002a0c:	8dd9                	or	a1,a1,a4
    80002a0e:	02000537          	lui	a0,0x2000
    80002a12:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a14:	0536                	slli	a0,a0,0xd
    80002a16:	9782                	jalr	a5
}
    80002a18:	60a2                	ld	ra,8(sp)
    80002a1a:	6402                	ld	s0,0(sp)
    80002a1c:	0141                	addi	sp,sp,16
    80002a1e:	8082                	ret

0000000080002a20 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	e04a                	sd	s2,0(sp)
    80002a2a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2c:	00017917          	auipc	s2,0x17
    80002a30:	ebc90913          	addi	s2,s2,-324 # 800198e8 <tickslock>
    80002a34:	854a                	mv	a0,s2
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	19a080e7          	jalr	410(ra) # 80000bd0 <acquire>
  ticks++;
    80002a3e:	00006497          	auipc	s1,0x6
    80002a42:	5f248493          	addi	s1,s1,1522 # 80009030 <ticks>
    80002a46:	409c                	lw	a5,0(s1)
    80002a48:	2785                	addiw	a5,a5,1
    80002a4a:	c09c                	sw	a5,0(s1)
  update_time();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	4de080e7          	jalr	1246(ra) # 80001f2a <update_time>
  wakeup(&ticks);
    80002a54:	8526                	mv	a0,s1
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	af4080e7          	jalr	-1292(ra) # 8000254a <wakeup>
  release(&tickslock);
    80002a5e:	854a                	mv	a0,s2
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	224080e7          	jalr	548(ra) # 80000c84 <release>
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6902                	ld	s2,0(sp)
    80002a70:	6105                	addi	sp,sp,32
    80002a72:	8082                	ret

0000000080002a74 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002a74:	1101                	addi	sp,sp,-32
    80002a76:	ec06                	sd	ra,24(sp)
    80002a78:	e822                	sd	s0,16(sp)
    80002a7a:	e426                	sd	s1,8(sp)
    80002a7c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a7e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a82:	00074d63          	bltz	a4,80002a9c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a86:	57fd                	li	a5,-1
    80002a88:	17fe                	slli	a5,a5,0x3f
    80002a8a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a8c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a8e:	06f70363          	beq	a4,a5,80002af4 <devintr+0x80>
  }
}
    80002a92:	60e2                	ld	ra,24(sp)
    80002a94:	6442                	ld	s0,16(sp)
    80002a96:	64a2                	ld	s1,8(sp)
    80002a98:	6105                	addi	sp,sp,32
    80002a9a:	8082                	ret
      (scause & 0xff) == 9)
    80002a9c:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002aa0:	46a5                	li	a3,9
    80002aa2:	fed792e3          	bne	a5,a3,80002a86 <devintr+0x12>
    int irq = plic_claim();
    80002aa6:	00003097          	auipc	ra,0x3
    80002aaa:	672080e7          	jalr	1650(ra) # 80006118 <plic_claim>
    80002aae:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ab0:	47a9                	li	a5,10
    80002ab2:	02f50763          	beq	a0,a5,80002ae0 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ab6:	4785                	li	a5,1
    80002ab8:	02f50963          	beq	a0,a5,80002aea <devintr+0x76>
    return 1;
    80002abc:	4505                	li	a0,1
    else if (irq)
    80002abe:	d8f1                	beqz	s1,80002a92 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ac0:	85a6                	mv	a1,s1
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	83e50513          	addi	a0,a0,-1986 # 80008300 <states.0+0x38>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	aba080e7          	jalr	-1350(ra) # 80000584 <printf>
      plic_complete(irq);
    80002ad2:	8526                	mv	a0,s1
    80002ad4:	00003097          	auipc	ra,0x3
    80002ad8:	668080e7          	jalr	1640(ra) # 8000613c <plic_complete>
    return 1;
    80002adc:	4505                	li	a0,1
    80002ade:	bf55                	j	80002a92 <devintr+0x1e>
      uartintr();
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	eb2080e7          	jalr	-334(ra) # 80000992 <uartintr>
    80002ae8:	b7ed                	j	80002ad2 <devintr+0x5e>
      virtio_disk_intr();
    80002aea:	00004097          	auipc	ra,0x4
    80002aee:	ade080e7          	jalr	-1314(ra) # 800065c8 <virtio_disk_intr>
    80002af2:	b7c5                	j	80002ad2 <devintr+0x5e>
    if (cpuid() == 0)
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	e76080e7          	jalr	-394(ra) # 8000196a <cpuid>
    80002afc:	c901                	beqz	a0,80002b0c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002afe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b02:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b04:	14479073          	csrw	sip,a5
    return 2;
    80002b08:	4509                	li	a0,2
    80002b0a:	b761                	j	80002a92 <devintr+0x1e>
      clockintr();
    80002b0c:	00000097          	auipc	ra,0x0
    80002b10:	f14080e7          	jalr	-236(ra) # 80002a20 <clockintr>
    80002b14:	b7ed                	j	80002afe <devintr+0x8a>

0000000080002b16 <usertrap>:
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b22:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b26:	1007f793          	andi	a5,a5,256
    80002b2a:	e3ad                	bnez	a5,80002b8c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b2c:	00003797          	auipc	a5,0x3
    80002b30:	4e478793          	addi	a5,a5,1252 # 80006010 <kernelvec>
    80002b34:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	e5e080e7          	jalr	-418(ra) # 80001996 <myproc>
    80002b40:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b42:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b44:	14102773          	csrr	a4,sepc
    80002b48:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4a:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b4e:	47a1                	li	a5,8
    80002b50:	04f71c63          	bne	a4,a5,80002ba8 <usertrap+0x92>
    if (p->killed)
    80002b54:	551c                	lw	a5,40(a0)
    80002b56:	e3b9                	bnez	a5,80002b9c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b58:	6cb8                	ld	a4,88(s1)
    80002b5a:	6f1c                	ld	a5,24(a4)
    80002b5c:	0791                	addi	a5,a5,4
    80002b5e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b68:	10079073          	csrw	sstatus,a5
    syscall();
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	2e0080e7          	jalr	736(ra) # 80002e4c <syscall>
  if (p->killed)
    80002b74:	549c                	lw	a5,40(s1)
    80002b76:	ebc1                	bnez	a5,80002c06 <usertrap+0xf0>
  usertrapret();
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	e0a080e7          	jalr	-502(ra) # 80002982 <usertrapret>
}
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	64a2                	ld	s1,8(sp)
    80002b86:	6902                	ld	s2,0(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret
    panic("usertrap: not from user mode");
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	79450513          	addi	a0,a0,1940 # 80008320 <states.0+0x58>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9a6080e7          	jalr	-1626(ra) # 8000053a <panic>
      exit(-1);
    80002b9c:	557d                	li	a0,-1
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	a9a080e7          	jalr	-1382(ra) # 80002638 <exit>
    80002ba6:	bf4d                	j	80002b58 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	ecc080e7          	jalr	-308(ra) # 80002a74 <devintr>
    80002bb0:	892a                	mv	s2,a0
    80002bb2:	c501                	beqz	a0,80002bba <usertrap+0xa4>
  if (p->killed)
    80002bb4:	549c                	lw	a5,40(s1)
    80002bb6:	c3a1                	beqz	a5,80002bf6 <usertrap+0xe0>
    80002bb8:	a815                	j	80002bec <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bba:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bbe:	5890                	lw	a2,48(s1)
    80002bc0:	00005517          	auipc	a0,0x5
    80002bc4:	78050513          	addi	a0,a0,1920 # 80008340 <states.0+0x78>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	9bc080e7          	jalr	-1604(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bd8:	00005517          	auipc	a0,0x5
    80002bdc:	79850513          	addi	a0,a0,1944 # 80008370 <states.0+0xa8>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	9a4080e7          	jalr	-1628(ra) # 80000584 <printf>
    p->killed = 1;
    80002be8:	4785                	li	a5,1
    80002bea:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bec:	557d                	li	a0,-1
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	a4a080e7          	jalr	-1462(ra) # 80002638 <exit>
  if (which_dev == 2)
    80002bf6:	4789                	li	a5,2
    80002bf8:	f8f910e3          	bne	s2,a5,80002b78 <usertrap+0x62>
    yield();
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	62e080e7          	jalr	1582(ra) # 8000222a <yield>
    80002c04:	bf95                	j	80002b78 <usertrap+0x62>
  int which_dev = 0;
    80002c06:	4901                	li	s2,0
    80002c08:	b7d5                	j	80002bec <usertrap+0xd6>

0000000080002c0a <kerneltrap>:
{
    80002c0a:	7179                	addi	sp,sp,-48
    80002c0c:	f406                	sd	ra,40(sp)
    80002c0e:	f022                	sd	s0,32(sp)
    80002c10:	ec26                	sd	s1,24(sp)
    80002c12:	e84a                	sd	s2,16(sp)
    80002c14:	e44e                	sd	s3,8(sp)
    80002c16:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c18:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c20:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002c24:	1004f793          	andi	a5,s1,256
    80002c28:	cb85                	beqz	a5,80002c58 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c2e:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002c30:	ef85                	bnez	a5,80002c68 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	e42080e7          	jalr	-446(ra) # 80002a74 <devintr>
    80002c3a:	cd1d                	beqz	a0,80002c78 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c3c:	4789                	li	a5,2
    80002c3e:	06f50a63          	beq	a0,a5,80002cb2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c42:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c46:	10049073          	csrw	sstatus,s1
}
    80002c4a:	70a2                	ld	ra,40(sp)
    80002c4c:	7402                	ld	s0,32(sp)
    80002c4e:	64e2                	ld	s1,24(sp)
    80002c50:	6942                	ld	s2,16(sp)
    80002c52:	69a2                	ld	s3,8(sp)
    80002c54:	6145                	addi	sp,sp,48
    80002c56:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c58:	00005517          	auipc	a0,0x5
    80002c5c:	73850513          	addi	a0,a0,1848 # 80008390 <states.0+0xc8>
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	8da080e7          	jalr	-1830(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	75050513          	addi	a0,a0,1872 # 800083b8 <states.0+0xf0>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	8ca080e7          	jalr	-1846(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002c78:	85ce                	mv	a1,s3
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	75e50513          	addi	a0,a0,1886 # 800083d8 <states.0+0x110>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	902080e7          	jalr	-1790(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c8e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	75650513          	addi	a0,a0,1878 # 800083e8 <states.0+0x120>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8ea080e7          	jalr	-1814(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	75e50513          	addi	a0,a0,1886 # 80008400 <states.0+0x138>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	890080e7          	jalr	-1904(ra) # 8000053a <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	ce4080e7          	jalr	-796(ra) # 80001996 <myproc>
    80002cba:	d541                	beqz	a0,80002c42 <kerneltrap+0x38>
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	cda080e7          	jalr	-806(ra) # 80001996 <myproc>
    80002cc4:	4d18                	lw	a4,24(a0)
    80002cc6:	4791                	li	a5,4
    80002cc8:	f6f71de3          	bne	a4,a5,80002c42 <kerneltrap+0x38>
    yield();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	55e080e7          	jalr	1374(ra) # 8000222a <yield>
    80002cd4:	b7bd                	j	80002c42 <kerneltrap+0x38>

0000000080002cd6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cd6:	1101                	addi	sp,sp,-32
    80002cd8:	ec06                	sd	ra,24(sp)
    80002cda:	e822                	sd	s0,16(sp)
    80002cdc:	e426                	sd	s1,8(sp)
    80002cde:	1000                	addi	s0,sp,32
    80002ce0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	cb4080e7          	jalr	-844(ra) # 80001996 <myproc>
  switch (n)
    80002cea:	4795                	li	a5,5
    80002cec:	0497e163          	bltu	a5,s1,80002d2e <argraw+0x58>
    80002cf0:	048a                	slli	s1,s1,0x2
    80002cf2:	00006717          	auipc	a4,0x6
    80002cf6:	83670713          	addi	a4,a4,-1994 # 80008528 <states.0+0x260>
    80002cfa:	94ba                	add	s1,s1,a4
    80002cfc:	409c                	lw	a5,0(s1)
    80002cfe:	97ba                	add	a5,a5,a4
    80002d00:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d02:	6d3c                	ld	a5,88(a0)
    80002d04:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d06:	60e2                	ld	ra,24(sp)
    80002d08:	6442                	ld	s0,16(sp)
    80002d0a:	64a2                	ld	s1,8(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret
    return p->trapframe->a1;
    80002d10:	6d3c                	ld	a5,88(a0)
    80002d12:	7fa8                	ld	a0,120(a5)
    80002d14:	bfcd                	j	80002d06 <argraw+0x30>
    return p->trapframe->a2;
    80002d16:	6d3c                	ld	a5,88(a0)
    80002d18:	63c8                	ld	a0,128(a5)
    80002d1a:	b7f5                	j	80002d06 <argraw+0x30>
    return p->trapframe->a3;
    80002d1c:	6d3c                	ld	a5,88(a0)
    80002d1e:	67c8                	ld	a0,136(a5)
    80002d20:	b7dd                	j	80002d06 <argraw+0x30>
    return p->trapframe->a4;
    80002d22:	6d3c                	ld	a5,88(a0)
    80002d24:	6bc8                	ld	a0,144(a5)
    80002d26:	b7c5                	j	80002d06 <argraw+0x30>
    return p->trapframe->a5;
    80002d28:	6d3c                	ld	a5,88(a0)
    80002d2a:	6fc8                	ld	a0,152(a5)
    80002d2c:	bfe9                	j	80002d06 <argraw+0x30>
  panic("argraw");
    80002d2e:	00005517          	auipc	a0,0x5
    80002d32:	6e250513          	addi	a0,a0,1762 # 80008410 <states.0+0x148>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	804080e7          	jalr	-2044(ra) # 8000053a <panic>

0000000080002d3e <fetchaddr>:
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	e04a                	sd	s2,0(sp)
    80002d48:	1000                	addi	s0,sp,32
    80002d4a:	84aa                	mv	s1,a0
    80002d4c:	892e                	mv	s2,a1
  struct proc *p = myproc();   
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	c48080e7          	jalr	-952(ra) # 80001996 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d56:	653c                	ld	a5,72(a0)
    80002d58:	02f4f863          	bgeu	s1,a5,80002d88 <fetchaddr+0x4a>
    80002d5c:	00848713          	addi	a4,s1,8
    80002d60:	02e7e663          	bltu	a5,a4,80002d8c <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d64:	46a1                	li	a3,8
    80002d66:	8626                	mv	a2,s1
    80002d68:	85ca                	mv	a1,s2
    80002d6a:	6928                	ld	a0,80(a0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	97a080e7          	jalr	-1670(ra) # 800016e6 <copyin>
    80002d74:	00a03533          	snez	a0,a0
    80002d78:	40a00533          	neg	a0,a0
}
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6902                	ld	s2,0(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret
    return -1;
    80002d88:	557d                	li	a0,-1
    80002d8a:	bfcd                	j	80002d7c <fetchaddr+0x3e>
    80002d8c:	557d                	li	a0,-1
    80002d8e:	b7fd                	j	80002d7c <fetchaddr+0x3e>

0000000080002d90 <fetchstr>:
{
    80002d90:	7179                	addi	sp,sp,-48
    80002d92:	f406                	sd	ra,40(sp)
    80002d94:	f022                	sd	s0,32(sp)
    80002d96:	ec26                	sd	s1,24(sp)
    80002d98:	e84a                	sd	s2,16(sp)
    80002d9a:	e44e                	sd	s3,8(sp)
    80002d9c:	1800                	addi	s0,sp,48
    80002d9e:	892a                	mv	s2,a0
    80002da0:	84ae                	mv	s1,a1
    80002da2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	bf2080e7          	jalr	-1038(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dac:	86ce                	mv	a3,s3
    80002dae:	864a                	mv	a2,s2
    80002db0:	85a6                	mv	a1,s1
    80002db2:	6928                	ld	a0,80(a0)
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	9c0080e7          	jalr	-1600(ra) # 80001774 <copyinstr>
  if (err < 0)
    80002dbc:	00054763          	bltz	a0,80002dca <fetchstr+0x3a>
  return strlen(buf);
    80002dc0:	8526                	mv	a0,s1
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	086080e7          	jalr	134(ra) # 80000e48 <strlen>
}
    80002dca:	70a2                	ld	ra,40(sp)
    80002dcc:	7402                	ld	s0,32(sp)
    80002dce:	64e2                	ld	s1,24(sp)
    80002dd0:	6942                	ld	s2,16(sp)
    80002dd2:	69a2                	ld	s3,8(sp)
    80002dd4:	6145                	addi	sp,sp,48
    80002dd6:	8082                	ret

0000000080002dd8 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	e426                	sd	s1,8(sp)
    80002de0:	1000                	addi	s0,sp,32
    80002de2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	ef2080e7          	jalr	-270(ra) # 80002cd6 <argraw>
    80002dec:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dee:	4501                	li	a0,0
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret

0000000080002dfa <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	1000                	addi	s0,sp,32
    80002e04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	ed0080e7          	jalr	-304(ra) # 80002cd6 <argraw>
    80002e0e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e10:	4501                	li	a0,0
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	64a2                	ld	s1,8(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	e04a                	sd	s2,0(sp)
    80002e26:	1000                	addi	s0,sp,32
    80002e28:	84ae                	mv	s1,a1
    80002e2a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	eaa080e7          	jalr	-342(ra) # 80002cd6 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e34:	864a                	mv	a2,s2
    80002e36:	85a6                	mv	a1,s1
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	f58080e7          	jalr	-168(ra) # 80002d90 <fetchstr>
}
    80002e40:	60e2                	ld	ra,24(sp)
    80002e42:	6442                	ld	s0,16(sp)
    80002e44:	64a2                	ld	s1,8(sp)
    80002e46:	6902                	ld	s2,0(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret

0000000080002e4c <syscall>:
    [SYS_waitx] 3,
    [SYS_setpriority] 2,
};

void syscall(void)
{
    80002e4c:	715d                	addi	sp,sp,-80
    80002e4e:	e486                	sd	ra,72(sp)
    80002e50:	e0a2                	sd	s0,64(sp)
    80002e52:	fc26                	sd	s1,56(sp)
    80002e54:	f84a                	sd	s2,48(sp)
    80002e56:	f44e                	sd	s3,40(sp)
    80002e58:	f052                	sd	s4,32(sp)
    80002e5a:	ec56                	sd	s5,24(sp)
    80002e5c:	e85a                	sd	s6,16(sp)
    80002e5e:	e45e                	sd	s7,8(sp)
    80002e60:	0880                	addi	s0,sp,80
  int num, ret_val;
  struct proc *p = myproc();
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	b34080e7          	jalr	-1228(ra) # 80001996 <myproc>
    80002e6a:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002e6c:	6d3c                	ld	a5,88(a0)
    80002e6e:	77dc                	ld	a5,168(a5)
    80002e70:	0007849b          	sext.w	s1,a5
  ret_val = p->trapframe->a0;

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e74:	37fd                	addiw	a5,a5,-1
    80002e76:	475d                	li	a4,23
    80002e78:	0cf76163          	bltu	a4,a5,80002f3a <syscall+0xee>
    80002e7c:	00349713          	slli	a4,s1,0x3
    80002e80:	00005797          	auipc	a5,0x5
    80002e84:	6c078793          	addi	a5,a5,1728 # 80008540 <syscalls>
    80002e88:	97ba                	add	a5,a5,a4
    80002e8a:	639c                	ld	a5,0(a5)
    80002e8c:	c7dd                	beqz	a5,80002f3a <syscall+0xee>
  {
    ret_val = syscalls[num]();
    80002e8e:	9782                	jalr	a5
    80002e90:	00050a1b          	sext.w	s4,a0
    //mid = p->trapframe->a0;

    if ((p->trace_mask & (1 << num)) > 0)
    80002e94:	4705                	li	a4,1
    80002e96:	0097173b          	sllw	a4,a4,s1
    80002e9a:	16892783          	lw	a5,360(s2)
    80002e9e:	8ff9                	and	a5,a5,a4
    80002ea0:	2781                	sext.w	a5,a5
    80002ea2:	00f04763          	bgtz	a5,80002eb0 <syscall+0x64>
        }
      }
      printf(") -> %d\n", ret_val);
    }

    p->trapframe->a0 = ret_val;
    80002ea6:	05893783          	ld	a5,88(s2)
    80002eaa:	0747b823          	sd	s4,112(a5)
    80002eae:	a07d                	j	80002f5c <syscall+0x110>
      printf("%d: syscall %s(", p->pid, syscallnames[num]);
    80002eb0:	00005997          	auipc	s3,0x5
    80002eb4:	69098993          	addi	s3,s3,1680 # 80008540 <syscalls>
    80002eb8:	00349793          	slli	a5,s1,0x3
    80002ebc:	97ce                	add	a5,a5,s3
    80002ebe:	67f0                	ld	a2,200(a5)
    80002ec0:	03092583          	lw	a1,48(s2)
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	55450513          	addi	a0,a0,1364 # 80008418 <states.0+0x150>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6b8080e7          	jalr	1720(ra) # 80000584 <printf>
      for (int i = 0; i < syscallargs[num]; i++)
    80002ed4:	048a                	slli	s1,s1,0x2
    80002ed6:	99a6                	add	s3,s3,s1
    80002ed8:	1909a983          	lw	s3,400(s3)
    80002edc:	05305563          	blez	s3,80002f26 <syscall+0xda>
    80002ee0:	4481                	li	s1,0
          printf("%d", arg1);
    80002ee2:	00005b17          	auipc	s6,0x5
    80002ee6:	546b0b13          	addi	s6,s6,1350 # 80008428 <states.0+0x160>
        if (i != syscallargs[num] - 1)
    80002eea:	fff98a9b          	addiw	s5,s3,-1
          printf(" ");
    80002eee:	00005b97          	auipc	s7,0x5
    80002ef2:	542b8b93          	addi	s7,s7,1346 # 80008430 <states.0+0x168>
    80002ef6:	a021                	j	80002efe <syscall+0xb2>
      for (int i = 0; i < syscallargs[num]; i++)
    80002ef8:	2485                	addiw	s1,s1,1
    80002efa:	03348663          	beq	s1,s3,80002f26 <syscall+0xda>
  *ip = argraw(n);
    80002efe:	8526                	mv	a0,s1
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	dd6080e7          	jalr	-554(ra) # 80002cd6 <argraw>
          printf("%d", arg1);
    80002f08:	0005059b          	sext.w	a1,a0
    80002f0c:	855a                	mv	a0,s6
    80002f0e:	ffffd097          	auipc	ra,0xffffd
    80002f12:	676080e7          	jalr	1654(ra) # 80000584 <printf>
        if (i != syscallargs[num] - 1)
    80002f16:	fe9a81e3          	beq	s5,s1,80002ef8 <syscall+0xac>
          printf(" ");
    80002f1a:	855e                	mv	a0,s7
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	668080e7          	jalr	1640(ra) # 80000584 <printf>
    80002f24:	bfd1                	j	80002ef8 <syscall+0xac>
      printf(") -> %d\n", ret_val);
    80002f26:	85d2                	mv	a1,s4
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	51050513          	addi	a0,a0,1296 # 80008438 <states.0+0x170>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	654080e7          	jalr	1620(ra) # 80000584 <printf>
    80002f38:	b7bd                	j	80002ea6 <syscall+0x5a>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002f3a:	86a6                	mv	a3,s1
    80002f3c:	15890613          	addi	a2,s2,344
    80002f40:	03092583          	lw	a1,48(s2)
    80002f44:	00005517          	auipc	a0,0x5
    80002f48:	50450513          	addi	a0,a0,1284 # 80008448 <states.0+0x180>
    80002f4c:	ffffd097          	auipc	ra,0xffffd
    80002f50:	638080e7          	jalr	1592(ra) # 80000584 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f54:	05893783          	ld	a5,88(s2)
    80002f58:	577d                	li	a4,-1
    80002f5a:	fbb8                	sd	a4,112(a5)
  }
}
    80002f5c:	60a6                	ld	ra,72(sp)
    80002f5e:	6406                	ld	s0,64(sp)
    80002f60:	74e2                	ld	s1,56(sp)
    80002f62:	7942                	ld	s2,48(sp)
    80002f64:	79a2                	ld	s3,40(sp)
    80002f66:	7a02                	ld	s4,32(sp)
    80002f68:	6ae2                	ld	s5,24(sp)
    80002f6a:	6b42                	ld	s6,16(sp)
    80002f6c:	6ba2                	ld	s7,8(sp)
    80002f6e:	6161                	addi	sp,sp,80
    80002f70:	8082                	ret

0000000080002f72 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f72:	1101                	addi	sp,sp,-32
    80002f74:	ec06                	sd	ra,24(sp)
    80002f76:	e822                	sd	s0,16(sp)
    80002f78:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002f7a:	fec40593          	addi	a1,s0,-20
    80002f7e:	4501                	li	a0,0
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	e58080e7          	jalr	-424(ra) # 80002dd8 <argint>
    return -1;
    80002f88:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002f8a:	00054963          	bltz	a0,80002f9c <sys_exit+0x2a>
  exit(n);
    80002f8e:	fec42503          	lw	a0,-20(s0)
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	6a6080e7          	jalr	1702(ra) # 80002638 <exit>
  return 0; // not reached
    80002f9a:	4781                	li	a5,0
}
    80002f9c:	853e                	mv	a0,a5
    80002f9e:	60e2                	ld	ra,24(sp)
    80002fa0:	6442                	ld	s0,16(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret

0000000080002fa6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fa6:	1141                	addi	sp,sp,-16
    80002fa8:	e406                	sd	ra,8(sp)
    80002faa:	e022                	sd	s0,0(sp)
    80002fac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	9e8080e7          	jalr	-1560(ra) # 80001996 <myproc>
}
    80002fb6:	5908                	lw	a0,48(a0)
    80002fb8:	60a2                	ld	ra,8(sp)
    80002fba:	6402                	ld	s0,0(sp)
    80002fbc:	0141                	addi	sp,sp,16
    80002fbe:	8082                	ret

0000000080002fc0 <sys_fork>:

uint64
sys_fork(void)
{
    80002fc0:	1141                	addi	sp,sp,-16
    80002fc2:	e406                	sd	ra,8(sp)
    80002fc4:	e022                	sd	s0,0(sp)
    80002fc6:	0800                	addi	s0,sp,16
  return fork();
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	e1a080e7          	jalr	-486(ra) # 80001de2 <fork>
}     
    80002fd0:	60a2                	ld	ra,8(sp)
    80002fd2:	6402                	ld	s0,0(sp)
    80002fd4:	0141                	addi	sp,sp,16
    80002fd6:	8082                	ret

0000000080002fd8 <sys_strace>:
uint64
sys_strace(void)
{
    80002fd8:	1101                	addi	sp,sp,-32
    80002fda:	ec06                	sd	ra,24(sp)
    80002fdc:	e822                	sd	s0,16(sp)
    80002fde:	1000                	addi	s0,sp,32
  int mask = 0;
  uint64 addr;
  if (argaddr(0, &addr) < 0)
    80002fe0:	fe840593          	addi	a1,s0,-24
    80002fe4:	4501                	li	a0,0
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	e14080e7          	jalr	-492(ra) # 80002dfa <argaddr>
    80002fee:	87aa                	mv	a5,a0
    return -1;
    80002ff0:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80002ff2:	0007c863          	bltz	a5,80003002 <sys_strace+0x2a>
  mask = addr;
  return strace(mask);
    80002ff6:	fe842503          	lw	a0,-24(s0)
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	f98080e7          	jalr	-104(ra) # 80001f92 <strace>
}
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	6105                	addi	sp,sp,32
    80003008:	8082                	ret

000000008000300a <sys_wait>:
uint64
sys_wait(void)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80003012:	fe840593          	addi	a1,s0,-24
    80003016:	4501                	li	a0,0
    80003018:	00000097          	auipc	ra,0x0
    8000301c:	de2080e7          	jalr	-542(ra) # 80002dfa <argaddr>
    80003020:	87aa                	mv	a5,a0
    return -1;
    80003022:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80003024:	0007c863          	bltz	a5,80003034 <sys_wait+0x2a>
  return wait(p);
    80003028:	fe843503          	ld	a0,-24(s0)
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	2aa080e7          	jalr	682(ra) # 800022d6 <wait>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	6105                	addi	sp,sp,32
    8000303a:	8082                	ret

000000008000303c <sys_set_priority>:

int sys_set_priority(void)
{
    8000303c:	7179                	addi	sp,sp,-48
    8000303e:	f406                	sd	ra,40(sp)
    80003040:	f022                	sd	s0,32(sp)
    80003042:	ec26                	sd	s1,24(sp)
    80003044:	1800                	addi	s0,sp,48
  uint64 addr, addr1;
  int priority, pid;
  if (argaddr(0, &addr) < 0)
    80003046:	fd840593          	addi	a1,s0,-40
    8000304a:	4501                	li	a0,0
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	dae080e7          	jalr	-594(ra) # 80002dfa <argaddr>
    80003054:	02054963          	bltz	a0,80003086 <sys_set_priority+0x4a>
    return -1;
  priority = addr;
    80003058:	fd842483          	lw	s1,-40(s0)
  if (argaddr(1, &addr1) < 0)
    8000305c:	fd040593          	addi	a1,s0,-48
    80003060:	4505                	li	a0,1
    80003062:	00000097          	auipc	ra,0x0
    80003066:	d98080e7          	jalr	-616(ra) # 80002dfa <argaddr>
    8000306a:	02054063          	bltz	a0,8000308a <sys_set_priority+0x4e>
    return -1;
  pid = addr1;
  return setpriority(priority, pid);
    8000306e:	fd042583          	lw	a1,-48(s0)
    80003072:	8526                	mv	a0,s1
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	044080e7          	jalr	68(ra) # 800020b8 <setpriority>
}
    8000307c:	70a2                	ld	ra,40(sp)
    8000307e:	7402                	ld	s0,32(sp)
    80003080:	64e2                	ld	s1,24(sp)
    80003082:	6145                	addi	sp,sp,48
    80003084:	8082                	ret
    return -1;
    80003086:	557d                	li	a0,-1
    80003088:	bfd5                	j	8000307c <sys_set_priority+0x40>
    return -1;
    8000308a:	557d                	li	a0,-1
    8000308c:	bfc5                	j	8000307c <sys_set_priority+0x40>

000000008000308e <sys_waitx>:

uint64
sys_waitx(void)
{
    8000308e:	7139                	addi	sp,sp,-64
    80003090:	fc06                	sd	ra,56(sp)
    80003092:	f822                	sd	s0,48(sp)
    80003094:	f426                	sd	s1,40(sp)
    80003096:	f04a                	sd	s2,32(sp)
    80003098:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if (argaddr(0, &addr) < 0)
    8000309a:	fd840593          	addi	a1,s0,-40
    8000309e:	4501                	li	a0,0
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	d5a080e7          	jalr	-678(ra) # 80002dfa <argaddr>
    return -1;
    800030a8:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0)
    800030aa:	08054063          	bltz	a0,8000312a <sys_waitx+0x9c>
  if (argaddr(1, &addr1) < 0)
    800030ae:	fd040593          	addi	a1,s0,-48
    800030b2:	4505                	li	a0,1
    800030b4:	00000097          	auipc	ra,0x0
    800030b8:	d46080e7          	jalr	-698(ra) # 80002dfa <argaddr>
    return -1;
    800030bc:	57fd                	li	a5,-1
  if (argaddr(1, &addr1) < 0)
    800030be:	06054663          	bltz	a0,8000312a <sys_waitx+0x9c>
  if (argaddr(2, &addr2) < 0)
    800030c2:	fc840593          	addi	a1,s0,-56
    800030c6:	4509                	li	a0,2
    800030c8:	00000097          	auipc	ra,0x0
    800030cc:	d32080e7          	jalr	-718(ra) # 80002dfa <argaddr>
    return -1;
    800030d0:	57fd                	li	a5,-1
  if (argaddr(2, &addr2) < 0)
    800030d2:	04054c63          	bltz	a0,8000312a <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800030d6:	fc040613          	addi	a2,s0,-64
    800030da:	fc440593          	addi	a1,s0,-60
    800030de:	fd843503          	ld	a0,-40(s0)
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	31c080e7          	jalr	796(ra) # 800023fe <waitx>
    800030ea:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	8aa080e7          	jalr	-1878(ra) # 80001996 <myproc>
    800030f4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030f6:	4691                	li	a3,4
    800030f8:	fc440613          	addi	a2,s0,-60
    800030fc:	fd043583          	ld	a1,-48(s0)
    80003100:	6928                	ld	a0,80(a0)
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	558080e7          	jalr	1368(ra) # 8000165a <copyout>
    return -1;
    8000310a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000310c:	00054f63          	bltz	a0,8000312a <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003110:	4691                	li	a3,4
    80003112:	fc040613          	addi	a2,s0,-64
    80003116:	fc843583          	ld	a1,-56(s0)
    8000311a:	68a8                	ld	a0,80(s1)
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	53e080e7          	jalr	1342(ra) # 8000165a <copyout>
    80003124:	00054a63          	bltz	a0,80003138 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003128:	87ca                	mv	a5,s2
}
    8000312a:	853e                	mv	a0,a5
    8000312c:	70e2                	ld	ra,56(sp)
    8000312e:	7442                	ld	s0,48(sp)
    80003130:	74a2                	ld	s1,40(sp)
    80003132:	7902                	ld	s2,32(sp)
    80003134:	6121                	addi	sp,sp,64
    80003136:	8082                	ret
    return -1;
    80003138:	57fd                	li	a5,-1
    8000313a:	bfc5                	j	8000312a <sys_waitx+0x9c>

000000008000313c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000313c:	7179                	addi	sp,sp,-48
    8000313e:	f406                	sd	ra,40(sp)
    80003140:	f022                	sd	s0,32(sp)
    80003142:	ec26                	sd	s1,24(sp)
    80003144:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80003146:	fdc40593          	addi	a1,s0,-36
    8000314a:	4501                	li	a0,0
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	c8c080e7          	jalr	-884(ra) # 80002dd8 <argint>
    80003154:	87aa                	mv	a5,a0
    return -1;
    80003156:	557d                	li	a0,-1
  if (argint(0, &n) < 0)
    80003158:	0207c063          	bltz	a5,80003178 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	83a080e7          	jalr	-1990(ra) # 80001996 <myproc>
    80003164:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    80003166:	fdc42503          	lw	a0,-36(s0)
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	c00080e7          	jalr	-1024(ra) # 80001d6a <growproc>
    80003172:	00054863          	bltz	a0,80003182 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003176:	8526                	mv	a0,s1
}
    80003178:	70a2                	ld	ra,40(sp)
    8000317a:	7402                	ld	s0,32(sp)
    8000317c:	64e2                	ld	s1,24(sp)
    8000317e:	6145                	addi	sp,sp,48
    80003180:	8082                	ret
    return -1;
    80003182:	557d                	li	a0,-1
    80003184:	bfd5                	j	80003178 <sys_sbrk+0x3c>

0000000080003186 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003186:	7139                	addi	sp,sp,-64
    80003188:	fc06                	sd	ra,56(sp)
    8000318a:	f822                	sd	s0,48(sp)
    8000318c:	f426                	sd	s1,40(sp)
    8000318e:	f04a                	sd	s2,32(sp)
    80003190:	ec4e                	sd	s3,24(sp)
    80003192:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80003194:	fcc40593          	addi	a1,s0,-52
    80003198:	4501                	li	a0,0
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	c3e080e7          	jalr	-962(ra) # 80002dd8 <argint>
    return -1;
    800031a2:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    800031a4:	06054563          	bltz	a0,8000320e <sys_sleep+0x88>
  acquire(&tickslock);
    800031a8:	00016517          	auipc	a0,0x16
    800031ac:	74050513          	addi	a0,a0,1856 # 800198e8 <tickslock>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	a20080e7          	jalr	-1504(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    800031b8:	00006917          	auipc	s2,0x6
    800031bc:	e7892903          	lw	s2,-392(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    800031c0:	fcc42783          	lw	a5,-52(s0)
    800031c4:	cf85                	beqz	a5,800031fc <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031c6:	00016997          	auipc	s3,0x16
    800031ca:	72298993          	addi	s3,s3,1826 # 800198e8 <tickslock>
    800031ce:	00006497          	auipc	s1,0x6
    800031d2:	e6248493          	addi	s1,s1,-414 # 80009030 <ticks>
    if (myproc()->killed)
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	7c0080e7          	jalr	1984(ra) # 80001996 <myproc>
    800031de:	551c                	lw	a5,40(a0)
    800031e0:	ef9d                	bnez	a5,8000321e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031e2:	85ce                	mv	a1,s3
    800031e4:	8526                	mv	a0,s1
    800031e6:	fffff097          	auipc	ra,0xfffff
    800031ea:	080080e7          	jalr	128(ra) # 80002266 <sleep>
  while (ticks - ticks0 < n)
    800031ee:	409c                	lw	a5,0(s1)
    800031f0:	412787bb          	subw	a5,a5,s2
    800031f4:	fcc42703          	lw	a4,-52(s0)
    800031f8:	fce7efe3          	bltu	a5,a4,800031d6 <sys_sleep+0x50>
  }
  release(&tickslock);
    800031fc:	00016517          	auipc	a0,0x16
    80003200:	6ec50513          	addi	a0,a0,1772 # 800198e8 <tickslock>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	a80080e7          	jalr	-1408(ra) # 80000c84 <release>
  return 0;
    8000320c:	4781                	li	a5,0
}
    8000320e:	853e                	mv	a0,a5
    80003210:	70e2                	ld	ra,56(sp)
    80003212:	7442                	ld	s0,48(sp)
    80003214:	74a2                	ld	s1,40(sp)
    80003216:	7902                	ld	s2,32(sp)
    80003218:	69e2                	ld	s3,24(sp)
    8000321a:	6121                	addi	sp,sp,64
    8000321c:	8082                	ret
      release(&tickslock);
    8000321e:	00016517          	auipc	a0,0x16
    80003222:	6ca50513          	addi	a0,a0,1738 # 800198e8 <tickslock>
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	a5e080e7          	jalr	-1442(ra) # 80000c84 <release>
      return -1;
    8000322e:	57fd                	li	a5,-1
    80003230:	bff9                	j	8000320e <sys_sleep+0x88>

0000000080003232 <sys_kill>:

uint64
sys_kill(void)
{
    80003232:	1101                	addi	sp,sp,-32
    80003234:	ec06                	sd	ra,24(sp)
    80003236:	e822                	sd	s0,16(sp)
    80003238:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    8000323a:	fec40593          	addi	a1,s0,-20
    8000323e:	4501                	li	a0,0
    80003240:	00000097          	auipc	ra,0x0
    80003244:	b98080e7          	jalr	-1128(ra) # 80002dd8 <argint>
    80003248:	87aa                	mv	a5,a0
    return -1;
    8000324a:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    8000324c:	0007c863          	bltz	a5,8000325c <sys_kill+0x2a>
  return kill(pid);
    80003250:	fec42503          	lw	a0,-20(s0)
    80003254:	fffff097          	auipc	ra,0xfffff
    80003258:	4c6080e7          	jalr	1222(ra) # 8000271a <kill>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	6105                	addi	sp,sp,32
    80003262:	8082                	ret

0000000080003264 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003264:	1101                	addi	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	e426                	sd	s1,8(sp)
    8000326c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000326e:	00016517          	auipc	a0,0x16
    80003272:	67a50513          	addi	a0,a0,1658 # 800198e8 <tickslock>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	95a080e7          	jalr	-1702(ra) # 80000bd0 <acquire>
  xticks = ticks;
    8000327e:	00006497          	auipc	s1,0x6
    80003282:	db24a483          	lw	s1,-590(s1) # 80009030 <ticks>
  release(&tickslock);
    80003286:	00016517          	auipc	a0,0x16
    8000328a:	66250513          	addi	a0,a0,1634 # 800198e8 <tickslock>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	9f6080e7          	jalr	-1546(ra) # 80000c84 <release>
  return xticks;
}
    80003296:	02049513          	slli	a0,s1,0x20
    8000329a:	9101                	srli	a0,a0,0x20
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret

00000000800032a6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032a6:	7179                	addi	sp,sp,-48
    800032a8:	f406                	sd	ra,40(sp)
    800032aa:	f022                	sd	s0,32(sp)
    800032ac:	ec26                	sd	s1,24(sp)
    800032ae:	e84a                	sd	s2,16(sp)
    800032b0:	e44e                	sd	s3,8(sp)
    800032b2:	e052                	sd	s4,0(sp)
    800032b4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032b6:	00005597          	auipc	a1,0x5
    800032ba:	48258593          	addi	a1,a1,1154 # 80008738 <syscallargs+0x68>
    800032be:	00016517          	auipc	a0,0x16
    800032c2:	64250513          	addi	a0,a0,1602 # 80019900 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	87a080e7          	jalr	-1926(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032ce:	0001e797          	auipc	a5,0x1e
    800032d2:	63278793          	addi	a5,a5,1586 # 80021900 <bcache+0x8000>
    800032d6:	0001f717          	auipc	a4,0x1f
    800032da:	89270713          	addi	a4,a4,-1902 # 80021b68 <bcache+0x8268>
    800032de:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032e2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032e6:	00016497          	auipc	s1,0x16
    800032ea:	63248493          	addi	s1,s1,1586 # 80019918 <bcache+0x18>
    b->next = bcache.head.next;
    800032ee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032f0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032f2:	00005a17          	auipc	s4,0x5
    800032f6:	44ea0a13          	addi	s4,s4,1102 # 80008740 <syscallargs+0x70>
    b->next = bcache.head.next;
    800032fa:	2b893783          	ld	a5,696(s2)
    800032fe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003300:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003304:	85d2                	mv	a1,s4
    80003306:	01048513          	addi	a0,s1,16
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	4c2080e7          	jalr	1218(ra) # 800047cc <initsleeplock>
    bcache.head.next->prev = b;
    80003312:	2b893783          	ld	a5,696(s2)
    80003316:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003318:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000331c:	45848493          	addi	s1,s1,1112
    80003320:	fd349de3          	bne	s1,s3,800032fa <binit+0x54>
  }
}
    80003324:	70a2                	ld	ra,40(sp)
    80003326:	7402                	ld	s0,32(sp)
    80003328:	64e2                	ld	s1,24(sp)
    8000332a:	6942                	ld	s2,16(sp)
    8000332c:	69a2                	ld	s3,8(sp)
    8000332e:	6a02                	ld	s4,0(sp)
    80003330:	6145                	addi	sp,sp,48
    80003332:	8082                	ret

0000000080003334 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003334:	7179                	addi	sp,sp,-48
    80003336:	f406                	sd	ra,40(sp)
    80003338:	f022                	sd	s0,32(sp)
    8000333a:	ec26                	sd	s1,24(sp)
    8000333c:	e84a                	sd	s2,16(sp)
    8000333e:	e44e                	sd	s3,8(sp)
    80003340:	1800                	addi	s0,sp,48
    80003342:	892a                	mv	s2,a0
    80003344:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003346:	00016517          	auipc	a0,0x16
    8000334a:	5ba50513          	addi	a0,a0,1466 # 80019900 <bcache>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	882080e7          	jalr	-1918(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003356:	0001f497          	auipc	s1,0x1f
    8000335a:	8624b483          	ld	s1,-1950(s1) # 80021bb8 <bcache+0x82b8>
    8000335e:	0001f797          	auipc	a5,0x1f
    80003362:	80a78793          	addi	a5,a5,-2038 # 80021b68 <bcache+0x8268>
    80003366:	02f48f63          	beq	s1,a5,800033a4 <bread+0x70>
    8000336a:	873e                	mv	a4,a5
    8000336c:	a021                	j	80003374 <bread+0x40>
    8000336e:	68a4                	ld	s1,80(s1)
    80003370:	02e48a63          	beq	s1,a4,800033a4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003374:	449c                	lw	a5,8(s1)
    80003376:	ff279ce3          	bne	a5,s2,8000336e <bread+0x3a>
    8000337a:	44dc                	lw	a5,12(s1)
    8000337c:	ff3799e3          	bne	a5,s3,8000336e <bread+0x3a>
      b->refcnt++;
    80003380:	40bc                	lw	a5,64(s1)
    80003382:	2785                	addiw	a5,a5,1
    80003384:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003386:	00016517          	auipc	a0,0x16
    8000338a:	57a50513          	addi	a0,a0,1402 # 80019900 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	8f6080e7          	jalr	-1802(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003396:	01048513          	addi	a0,s1,16
    8000339a:	00001097          	auipc	ra,0x1
    8000339e:	46c080e7          	jalr	1132(ra) # 80004806 <acquiresleep>
      return b;
    800033a2:	a8b9                	j	80003400 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033a4:	0001f497          	auipc	s1,0x1f
    800033a8:	80c4b483          	ld	s1,-2036(s1) # 80021bb0 <bcache+0x82b0>
    800033ac:	0001e797          	auipc	a5,0x1e
    800033b0:	7bc78793          	addi	a5,a5,1980 # 80021b68 <bcache+0x8268>
    800033b4:	00f48863          	beq	s1,a5,800033c4 <bread+0x90>
    800033b8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033ba:	40bc                	lw	a5,64(s1)
    800033bc:	cf81                	beqz	a5,800033d4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033be:	64a4                	ld	s1,72(s1)
    800033c0:	fee49de3          	bne	s1,a4,800033ba <bread+0x86>
  panic("bget: no buffers");
    800033c4:	00005517          	auipc	a0,0x5
    800033c8:	38450513          	addi	a0,a0,900 # 80008748 <syscallargs+0x78>
    800033cc:	ffffd097          	auipc	ra,0xffffd
    800033d0:	16e080e7          	jalr	366(ra) # 8000053a <panic>
      b->dev = dev;
    800033d4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033d8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033dc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033e0:	4785                	li	a5,1
    800033e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033e4:	00016517          	auipc	a0,0x16
    800033e8:	51c50513          	addi	a0,a0,1308 # 80019900 <bcache>
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	898080e7          	jalr	-1896(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800033f4:	01048513          	addi	a0,s1,16
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	40e080e7          	jalr	1038(ra) # 80004806 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003400:	409c                	lw	a5,0(s1)
    80003402:	cb89                	beqz	a5,80003414 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003404:	8526                	mv	a0,s1
    80003406:	70a2                	ld	ra,40(sp)
    80003408:	7402                	ld	s0,32(sp)
    8000340a:	64e2                	ld	s1,24(sp)
    8000340c:	6942                	ld	s2,16(sp)
    8000340e:	69a2                	ld	s3,8(sp)
    80003410:	6145                	addi	sp,sp,48
    80003412:	8082                	ret
    virtio_disk_rw(b, 0);
    80003414:	4581                	li	a1,0
    80003416:	8526                	mv	a0,s1
    80003418:	00003097          	auipc	ra,0x3
    8000341c:	f2a080e7          	jalr	-214(ra) # 80006342 <virtio_disk_rw>
    b->valid = 1;
    80003420:	4785                	li	a5,1
    80003422:	c09c                	sw	a5,0(s1)
  return b;
    80003424:	b7c5                	j	80003404 <bread+0xd0>

0000000080003426 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003426:	1101                	addi	sp,sp,-32
    80003428:	ec06                	sd	ra,24(sp)
    8000342a:	e822                	sd	s0,16(sp)
    8000342c:	e426                	sd	s1,8(sp)
    8000342e:	1000                	addi	s0,sp,32
    80003430:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003432:	0541                	addi	a0,a0,16
    80003434:	00001097          	auipc	ra,0x1
    80003438:	46c080e7          	jalr	1132(ra) # 800048a0 <holdingsleep>
    8000343c:	cd01                	beqz	a0,80003454 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000343e:	4585                	li	a1,1
    80003440:	8526                	mv	a0,s1
    80003442:	00003097          	auipc	ra,0x3
    80003446:	f00080e7          	jalr	-256(ra) # 80006342 <virtio_disk_rw>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	64a2                	ld	s1,8(sp)
    80003450:	6105                	addi	sp,sp,32
    80003452:	8082                	ret
    panic("bwrite");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	30c50513          	addi	a0,a0,780 # 80008760 <syscallargs+0x90>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0de080e7          	jalr	222(ra) # 8000053a <panic>

0000000080003464 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003464:	1101                	addi	sp,sp,-32
    80003466:	ec06                	sd	ra,24(sp)
    80003468:	e822                	sd	s0,16(sp)
    8000346a:	e426                	sd	s1,8(sp)
    8000346c:	e04a                	sd	s2,0(sp)
    8000346e:	1000                	addi	s0,sp,32
    80003470:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003472:	01050913          	addi	s2,a0,16
    80003476:	854a                	mv	a0,s2
    80003478:	00001097          	auipc	ra,0x1
    8000347c:	428080e7          	jalr	1064(ra) # 800048a0 <holdingsleep>
    80003480:	c92d                	beqz	a0,800034f2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003482:	854a                	mv	a0,s2
    80003484:	00001097          	auipc	ra,0x1
    80003488:	3d8080e7          	jalr	984(ra) # 8000485c <releasesleep>

  acquire(&bcache.lock);
    8000348c:	00016517          	auipc	a0,0x16
    80003490:	47450513          	addi	a0,a0,1140 # 80019900 <bcache>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	73c080e7          	jalr	1852(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000349c:	40bc                	lw	a5,64(s1)
    8000349e:	37fd                	addiw	a5,a5,-1
    800034a0:	0007871b          	sext.w	a4,a5
    800034a4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034a6:	eb05                	bnez	a4,800034d6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034a8:	68bc                	ld	a5,80(s1)
    800034aa:	64b8                	ld	a4,72(s1)
    800034ac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034ae:	64bc                	ld	a5,72(s1)
    800034b0:	68b8                	ld	a4,80(s1)
    800034b2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034b4:	0001e797          	auipc	a5,0x1e
    800034b8:	44c78793          	addi	a5,a5,1100 # 80021900 <bcache+0x8000>
    800034bc:	2b87b703          	ld	a4,696(a5)
    800034c0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034c2:	0001e717          	auipc	a4,0x1e
    800034c6:	6a670713          	addi	a4,a4,1702 # 80021b68 <bcache+0x8268>
    800034ca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034cc:	2b87b703          	ld	a4,696(a5)
    800034d0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034d2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034d6:	00016517          	auipc	a0,0x16
    800034da:	42a50513          	addi	a0,a0,1066 # 80019900 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7a6080e7          	jalr	1958(ra) # 80000c84 <release>
}
    800034e6:	60e2                	ld	ra,24(sp)
    800034e8:	6442                	ld	s0,16(sp)
    800034ea:	64a2                	ld	s1,8(sp)
    800034ec:	6902                	ld	s2,0(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret
    panic("brelse");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	27650513          	addi	a0,a0,630 # 80008768 <syscallargs+0x98>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	040080e7          	jalr	64(ra) # 8000053a <panic>

0000000080003502 <bpin>:

void
bpin(struct buf *b) {
    80003502:	1101                	addi	sp,sp,-32
    80003504:	ec06                	sd	ra,24(sp)
    80003506:	e822                	sd	s0,16(sp)
    80003508:	e426                	sd	s1,8(sp)
    8000350a:	1000                	addi	s0,sp,32
    8000350c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000350e:	00016517          	auipc	a0,0x16
    80003512:	3f250513          	addi	a0,a0,1010 # 80019900 <bcache>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	6ba080e7          	jalr	1722(ra) # 80000bd0 <acquire>
  b->refcnt++;
    8000351e:	40bc                	lw	a5,64(s1)
    80003520:	2785                	addiw	a5,a5,1
    80003522:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003524:	00016517          	auipc	a0,0x16
    80003528:	3dc50513          	addi	a0,a0,988 # 80019900 <bcache>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	758080e7          	jalr	1880(ra) # 80000c84 <release>
}
    80003534:	60e2                	ld	ra,24(sp)
    80003536:	6442                	ld	s0,16(sp)
    80003538:	64a2                	ld	s1,8(sp)
    8000353a:	6105                	addi	sp,sp,32
    8000353c:	8082                	ret

000000008000353e <bunpin>:

void
bunpin(struct buf *b) {
    8000353e:	1101                	addi	sp,sp,-32
    80003540:	ec06                	sd	ra,24(sp)
    80003542:	e822                	sd	s0,16(sp)
    80003544:	e426                	sd	s1,8(sp)
    80003546:	1000                	addi	s0,sp,32
    80003548:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000354a:	00016517          	auipc	a0,0x16
    8000354e:	3b650513          	addi	a0,a0,950 # 80019900 <bcache>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	67e080e7          	jalr	1662(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000355a:	40bc                	lw	a5,64(s1)
    8000355c:	37fd                	addiw	a5,a5,-1
    8000355e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003560:	00016517          	auipc	a0,0x16
    80003564:	3a050513          	addi	a0,a0,928 # 80019900 <bcache>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	71c080e7          	jalr	1820(ra) # 80000c84 <release>
}
    80003570:	60e2                	ld	ra,24(sp)
    80003572:	6442                	ld	s0,16(sp)
    80003574:	64a2                	ld	s1,8(sp)
    80003576:	6105                	addi	sp,sp,32
    80003578:	8082                	ret

000000008000357a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000357a:	1101                	addi	sp,sp,-32
    8000357c:	ec06                	sd	ra,24(sp)
    8000357e:	e822                	sd	s0,16(sp)
    80003580:	e426                	sd	s1,8(sp)
    80003582:	e04a                	sd	s2,0(sp)
    80003584:	1000                	addi	s0,sp,32
    80003586:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003588:	00d5d59b          	srliw	a1,a1,0xd
    8000358c:	0001f797          	auipc	a5,0x1f
    80003590:	a507a783          	lw	a5,-1456(a5) # 80021fdc <sb+0x1c>
    80003594:	9dbd                	addw	a1,a1,a5
    80003596:	00000097          	auipc	ra,0x0
    8000359a:	d9e080e7          	jalr	-610(ra) # 80003334 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000359e:	0074f713          	andi	a4,s1,7
    800035a2:	4785                	li	a5,1
    800035a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035a8:	14ce                	slli	s1,s1,0x33
    800035aa:	90d9                	srli	s1,s1,0x36
    800035ac:	00950733          	add	a4,a0,s1
    800035b0:	05874703          	lbu	a4,88(a4)
    800035b4:	00e7f6b3          	and	a3,a5,a4
    800035b8:	c69d                	beqz	a3,800035e6 <bfree+0x6c>
    800035ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035bc:	94aa                	add	s1,s1,a0
    800035be:	fff7c793          	not	a5,a5
    800035c2:	8f7d                	and	a4,a4,a5
    800035c4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800035c8:	00001097          	auipc	ra,0x1
    800035cc:	120080e7          	jalr	288(ra) # 800046e8 <log_write>
  brelse(bp);
    800035d0:	854a                	mv	a0,s2
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e92080e7          	jalr	-366(ra) # 80003464 <brelse>
}
    800035da:	60e2                	ld	ra,24(sp)
    800035dc:	6442                	ld	s0,16(sp)
    800035de:	64a2                	ld	s1,8(sp)
    800035e0:	6902                	ld	s2,0(sp)
    800035e2:	6105                	addi	sp,sp,32
    800035e4:	8082                	ret
    panic("freeing free block");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	18a50513          	addi	a0,a0,394 # 80008770 <syscallargs+0xa0>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f4c080e7          	jalr	-180(ra) # 8000053a <panic>

00000000800035f6 <balloc>:
{
    800035f6:	711d                	addi	sp,sp,-96
    800035f8:	ec86                	sd	ra,88(sp)
    800035fa:	e8a2                	sd	s0,80(sp)
    800035fc:	e4a6                	sd	s1,72(sp)
    800035fe:	e0ca                	sd	s2,64(sp)
    80003600:	fc4e                	sd	s3,56(sp)
    80003602:	f852                	sd	s4,48(sp)
    80003604:	f456                	sd	s5,40(sp)
    80003606:	f05a                	sd	s6,32(sp)
    80003608:	ec5e                	sd	s7,24(sp)
    8000360a:	e862                	sd	s8,16(sp)
    8000360c:	e466                	sd	s9,8(sp)
    8000360e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003610:	0001f797          	auipc	a5,0x1f
    80003614:	9b47a783          	lw	a5,-1612(a5) # 80021fc4 <sb+0x4>
    80003618:	cbc1                	beqz	a5,800036a8 <balloc+0xb2>
    8000361a:	8baa                	mv	s7,a0
    8000361c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000361e:	0001fb17          	auipc	s6,0x1f
    80003622:	9a2b0b13          	addi	s6,s6,-1630 # 80021fc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003626:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003628:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000362a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000362c:	6c89                	lui	s9,0x2
    8000362e:	a831                	j	8000364a <balloc+0x54>
    brelse(bp);
    80003630:	854a                	mv	a0,s2
    80003632:	00000097          	auipc	ra,0x0
    80003636:	e32080e7          	jalr	-462(ra) # 80003464 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000363a:	015c87bb          	addw	a5,s9,s5
    8000363e:	00078a9b          	sext.w	s5,a5
    80003642:	004b2703          	lw	a4,4(s6)
    80003646:	06eaf163          	bgeu	s5,a4,800036a8 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000364a:	41fad79b          	sraiw	a5,s5,0x1f
    8000364e:	0137d79b          	srliw	a5,a5,0x13
    80003652:	015787bb          	addw	a5,a5,s5
    80003656:	40d7d79b          	sraiw	a5,a5,0xd
    8000365a:	01cb2583          	lw	a1,28(s6)
    8000365e:	9dbd                	addw	a1,a1,a5
    80003660:	855e                	mv	a0,s7
    80003662:	00000097          	auipc	ra,0x0
    80003666:	cd2080e7          	jalr	-814(ra) # 80003334 <bread>
    8000366a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366c:	004b2503          	lw	a0,4(s6)
    80003670:	000a849b          	sext.w	s1,s5
    80003674:	8762                	mv	a4,s8
    80003676:	faa4fde3          	bgeu	s1,a0,80003630 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000367a:	00777693          	andi	a3,a4,7
    8000367e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003682:	41f7579b          	sraiw	a5,a4,0x1f
    80003686:	01d7d79b          	srliw	a5,a5,0x1d
    8000368a:	9fb9                	addw	a5,a5,a4
    8000368c:	4037d79b          	sraiw	a5,a5,0x3
    80003690:	00f90633          	add	a2,s2,a5
    80003694:	05864603          	lbu	a2,88(a2)
    80003698:	00c6f5b3          	and	a1,a3,a2
    8000369c:	cd91                	beqz	a1,800036b8 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000369e:	2705                	addiw	a4,a4,1
    800036a0:	2485                	addiw	s1,s1,1
    800036a2:	fd471ae3          	bne	a4,s4,80003676 <balloc+0x80>
    800036a6:	b769                	j	80003630 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	0e050513          	addi	a0,a0,224 # 80008788 <syscallargs+0xb8>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	e8a080e7          	jalr	-374(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036b8:	97ca                	add	a5,a5,s2
    800036ba:	8e55                	or	a2,a2,a3
    800036bc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	026080e7          	jalr	38(ra) # 800046e8 <log_write>
        brelse(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	d98080e7          	jalr	-616(ra) # 80003464 <brelse>
  bp = bread(dev, bno);
    800036d4:	85a6                	mv	a1,s1
    800036d6:	855e                	mv	a0,s7
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	c5c080e7          	jalr	-932(ra) # 80003334 <bread>
    800036e0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036e2:	40000613          	li	a2,1024
    800036e6:	4581                	li	a1,0
    800036e8:	05850513          	addi	a0,a0,88
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	5e0080e7          	jalr	1504(ra) # 80000ccc <memset>
  log_write(bp);
    800036f4:	854a                	mv	a0,s2
    800036f6:	00001097          	auipc	ra,0x1
    800036fa:	ff2080e7          	jalr	-14(ra) # 800046e8 <log_write>
  brelse(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00000097          	auipc	ra,0x0
    80003704:	d64080e7          	jalr	-668(ra) # 80003464 <brelse>
}
    80003708:	8526                	mv	a0,s1
    8000370a:	60e6                	ld	ra,88(sp)
    8000370c:	6446                	ld	s0,80(sp)
    8000370e:	64a6                	ld	s1,72(sp)
    80003710:	6906                	ld	s2,64(sp)
    80003712:	79e2                	ld	s3,56(sp)
    80003714:	7a42                	ld	s4,48(sp)
    80003716:	7aa2                	ld	s5,40(sp)
    80003718:	7b02                	ld	s6,32(sp)
    8000371a:	6be2                	ld	s7,24(sp)
    8000371c:	6c42                	ld	s8,16(sp)
    8000371e:	6ca2                	ld	s9,8(sp)
    80003720:	6125                	addi	sp,sp,96
    80003722:	8082                	ret

0000000080003724 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003724:	7179                	addi	sp,sp,-48
    80003726:	f406                	sd	ra,40(sp)
    80003728:	f022                	sd	s0,32(sp)
    8000372a:	ec26                	sd	s1,24(sp)
    8000372c:	e84a                	sd	s2,16(sp)
    8000372e:	e44e                	sd	s3,8(sp)
    80003730:	e052                	sd	s4,0(sp)
    80003732:	1800                	addi	s0,sp,48
    80003734:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003736:	47ad                	li	a5,11
    80003738:	04b7fe63          	bgeu	a5,a1,80003794 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000373c:	ff45849b          	addiw	s1,a1,-12
    80003740:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003744:	0ff00793          	li	a5,255
    80003748:	0ae7e463          	bltu	a5,a4,800037f0 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000374c:	08052583          	lw	a1,128(a0)
    80003750:	c5b5                	beqz	a1,800037bc <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003752:	00092503          	lw	a0,0(s2)
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	bde080e7          	jalr	-1058(ra) # 80003334 <bread>
    8000375e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003760:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003764:	02049713          	slli	a4,s1,0x20
    80003768:	01e75593          	srli	a1,a4,0x1e
    8000376c:	00b784b3          	add	s1,a5,a1
    80003770:	0004a983          	lw	s3,0(s1)
    80003774:	04098e63          	beqz	s3,800037d0 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003778:	8552                	mv	a0,s4
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	cea080e7          	jalr	-790(ra) # 80003464 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003782:	854e                	mv	a0,s3
    80003784:	70a2                	ld	ra,40(sp)
    80003786:	7402                	ld	s0,32(sp)
    80003788:	64e2                	ld	s1,24(sp)
    8000378a:	6942                	ld	s2,16(sp)
    8000378c:	69a2                	ld	s3,8(sp)
    8000378e:	6a02                	ld	s4,0(sp)
    80003790:	6145                	addi	sp,sp,48
    80003792:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003794:	02059793          	slli	a5,a1,0x20
    80003798:	01e7d593          	srli	a1,a5,0x1e
    8000379c:	00b504b3          	add	s1,a0,a1
    800037a0:	0504a983          	lw	s3,80(s1)
    800037a4:	fc099fe3          	bnez	s3,80003782 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037a8:	4108                	lw	a0,0(a0)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	e4c080e7          	jalr	-436(ra) # 800035f6 <balloc>
    800037b2:	0005099b          	sext.w	s3,a0
    800037b6:	0534a823          	sw	s3,80(s1)
    800037ba:	b7e1                	j	80003782 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037bc:	4108                	lw	a0,0(a0)
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	e38080e7          	jalr	-456(ra) # 800035f6 <balloc>
    800037c6:	0005059b          	sext.w	a1,a0
    800037ca:	08b92023          	sw	a1,128(s2)
    800037ce:	b751                	j	80003752 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037d0:	00092503          	lw	a0,0(s2)
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	e22080e7          	jalr	-478(ra) # 800035f6 <balloc>
    800037dc:	0005099b          	sext.w	s3,a0
    800037e0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037e4:	8552                	mv	a0,s4
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	f02080e7          	jalr	-254(ra) # 800046e8 <log_write>
    800037ee:	b769                	j	80003778 <bmap+0x54>
  panic("bmap: out of range");
    800037f0:	00005517          	auipc	a0,0x5
    800037f4:	fb050513          	addi	a0,a0,-80 # 800087a0 <syscallargs+0xd0>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	d42080e7          	jalr	-702(ra) # 8000053a <panic>

0000000080003800 <iget>:
{
    80003800:	7179                	addi	sp,sp,-48
    80003802:	f406                	sd	ra,40(sp)
    80003804:	f022                	sd	s0,32(sp)
    80003806:	ec26                	sd	s1,24(sp)
    80003808:	e84a                	sd	s2,16(sp)
    8000380a:	e44e                	sd	s3,8(sp)
    8000380c:	e052                	sd	s4,0(sp)
    8000380e:	1800                	addi	s0,sp,48
    80003810:	89aa                	mv	s3,a0
    80003812:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003814:	0001e517          	auipc	a0,0x1e
    80003818:	7cc50513          	addi	a0,a0,1996 # 80021fe0 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3b4080e7          	jalr	948(ra) # 80000bd0 <acquire>
  empty = 0;
    80003824:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003826:	0001e497          	auipc	s1,0x1e
    8000382a:	7d248493          	addi	s1,s1,2002 # 80021ff8 <itable+0x18>
    8000382e:	00020697          	auipc	a3,0x20
    80003832:	25a68693          	addi	a3,a3,602 # 80023a88 <log>
    80003836:	a039                	j	80003844 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003838:	02090b63          	beqz	s2,8000386e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000383c:	08848493          	addi	s1,s1,136
    80003840:	02d48a63          	beq	s1,a3,80003874 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003844:	449c                	lw	a5,8(s1)
    80003846:	fef059e3          	blez	a5,80003838 <iget+0x38>
    8000384a:	4098                	lw	a4,0(s1)
    8000384c:	ff3716e3          	bne	a4,s3,80003838 <iget+0x38>
    80003850:	40d8                	lw	a4,4(s1)
    80003852:	ff4713e3          	bne	a4,s4,80003838 <iget+0x38>
      ip->ref++;
    80003856:	2785                	addiw	a5,a5,1
    80003858:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000385a:	0001e517          	auipc	a0,0x1e
    8000385e:	78650513          	addi	a0,a0,1926 # 80021fe0 <itable>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	422080e7          	jalr	1058(ra) # 80000c84 <release>
      return ip;
    8000386a:	8926                	mv	s2,s1
    8000386c:	a03d                	j	8000389a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000386e:	f7f9                	bnez	a5,8000383c <iget+0x3c>
    80003870:	8926                	mv	s2,s1
    80003872:	b7e9                	j	8000383c <iget+0x3c>
  if(empty == 0)
    80003874:	02090c63          	beqz	s2,800038ac <iget+0xac>
  ip->dev = dev;
    80003878:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000387c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003880:	4785                	li	a5,1
    80003882:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003886:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000388a:	0001e517          	auipc	a0,0x1e
    8000388e:	75650513          	addi	a0,a0,1878 # 80021fe0 <itable>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	3f2080e7          	jalr	1010(ra) # 80000c84 <release>
}
    8000389a:	854a                	mv	a0,s2
    8000389c:	70a2                	ld	ra,40(sp)
    8000389e:	7402                	ld	s0,32(sp)
    800038a0:	64e2                	ld	s1,24(sp)
    800038a2:	6942                	ld	s2,16(sp)
    800038a4:	69a2                	ld	s3,8(sp)
    800038a6:	6a02                	ld	s4,0(sp)
    800038a8:	6145                	addi	sp,sp,48
    800038aa:	8082                	ret
    panic("iget: no inodes");
    800038ac:	00005517          	auipc	a0,0x5
    800038b0:	f0c50513          	addi	a0,a0,-244 # 800087b8 <syscallargs+0xe8>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	c86080e7          	jalr	-890(ra) # 8000053a <panic>

00000000800038bc <fsinit>:
fsinit(int dev) {
    800038bc:	7179                	addi	sp,sp,-48
    800038be:	f406                	sd	ra,40(sp)
    800038c0:	f022                	sd	s0,32(sp)
    800038c2:	ec26                	sd	s1,24(sp)
    800038c4:	e84a                	sd	s2,16(sp)
    800038c6:	e44e                	sd	s3,8(sp)
    800038c8:	1800                	addi	s0,sp,48
    800038ca:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038cc:	4585                	li	a1,1
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	a66080e7          	jalr	-1434(ra) # 80003334 <bread>
    800038d6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038d8:	0001e997          	auipc	s3,0x1e
    800038dc:	6e898993          	addi	s3,s3,1768 # 80021fc0 <sb>
    800038e0:	02000613          	li	a2,32
    800038e4:	05850593          	addi	a1,a0,88
    800038e8:	854e                	mv	a0,s3
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	43e080e7          	jalr	1086(ra) # 80000d28 <memmove>
  brelse(bp);
    800038f2:	8526                	mv	a0,s1
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	b70080e7          	jalr	-1168(ra) # 80003464 <brelse>
  if(sb.magic != FSMAGIC)
    800038fc:	0009a703          	lw	a4,0(s3)
    80003900:	102037b7          	lui	a5,0x10203
    80003904:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003908:	02f71263          	bne	a4,a5,8000392c <fsinit+0x70>
  initlog(dev, &sb);
    8000390c:	0001e597          	auipc	a1,0x1e
    80003910:	6b458593          	addi	a1,a1,1716 # 80021fc0 <sb>
    80003914:	854a                	mv	a0,s2
    80003916:	00001097          	auipc	ra,0x1
    8000391a:	b56080e7          	jalr	-1194(ra) # 8000446c <initlog>
}
    8000391e:	70a2                	ld	ra,40(sp)
    80003920:	7402                	ld	s0,32(sp)
    80003922:	64e2                	ld	s1,24(sp)
    80003924:	6942                	ld	s2,16(sp)
    80003926:	69a2                	ld	s3,8(sp)
    80003928:	6145                	addi	sp,sp,48
    8000392a:	8082                	ret
    panic("invalid file system");
    8000392c:	00005517          	auipc	a0,0x5
    80003930:	e9c50513          	addi	a0,a0,-356 # 800087c8 <syscallargs+0xf8>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	c06080e7          	jalr	-1018(ra) # 8000053a <panic>

000000008000393c <iinit>:
{
    8000393c:	7179                	addi	sp,sp,-48
    8000393e:	f406                	sd	ra,40(sp)
    80003940:	f022                	sd	s0,32(sp)
    80003942:	ec26                	sd	s1,24(sp)
    80003944:	e84a                	sd	s2,16(sp)
    80003946:	e44e                	sd	s3,8(sp)
    80003948:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000394a:	00005597          	auipc	a1,0x5
    8000394e:	e9658593          	addi	a1,a1,-362 # 800087e0 <syscallargs+0x110>
    80003952:	0001e517          	auipc	a0,0x1e
    80003956:	68e50513          	addi	a0,a0,1678 # 80021fe0 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	1e6080e7          	jalr	486(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003962:	0001e497          	auipc	s1,0x1e
    80003966:	6a648493          	addi	s1,s1,1702 # 80022008 <itable+0x28>
    8000396a:	00020997          	auipc	s3,0x20
    8000396e:	12e98993          	addi	s3,s3,302 # 80023a98 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003972:	00005917          	auipc	s2,0x5
    80003976:	e7690913          	addi	s2,s2,-394 # 800087e8 <syscallargs+0x118>
    8000397a:	85ca                	mv	a1,s2
    8000397c:	8526                	mv	a0,s1
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	e4e080e7          	jalr	-434(ra) # 800047cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003986:	08848493          	addi	s1,s1,136
    8000398a:	ff3498e3          	bne	s1,s3,8000397a <iinit+0x3e>
}
    8000398e:	70a2                	ld	ra,40(sp)
    80003990:	7402                	ld	s0,32(sp)
    80003992:	64e2                	ld	s1,24(sp)
    80003994:	6942                	ld	s2,16(sp)
    80003996:	69a2                	ld	s3,8(sp)
    80003998:	6145                	addi	sp,sp,48
    8000399a:	8082                	ret

000000008000399c <ialloc>:
{
    8000399c:	715d                	addi	sp,sp,-80
    8000399e:	e486                	sd	ra,72(sp)
    800039a0:	e0a2                	sd	s0,64(sp)
    800039a2:	fc26                	sd	s1,56(sp)
    800039a4:	f84a                	sd	s2,48(sp)
    800039a6:	f44e                	sd	s3,40(sp)
    800039a8:	f052                	sd	s4,32(sp)
    800039aa:	ec56                	sd	s5,24(sp)
    800039ac:	e85a                	sd	s6,16(sp)
    800039ae:	e45e                	sd	s7,8(sp)
    800039b0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039b2:	0001e717          	auipc	a4,0x1e
    800039b6:	61a72703          	lw	a4,1562(a4) # 80021fcc <sb+0xc>
    800039ba:	4785                	li	a5,1
    800039bc:	04e7fa63          	bgeu	a5,a4,80003a10 <ialloc+0x74>
    800039c0:	8aaa                	mv	s5,a0
    800039c2:	8bae                	mv	s7,a1
    800039c4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039c6:	0001ea17          	auipc	s4,0x1e
    800039ca:	5faa0a13          	addi	s4,s4,1530 # 80021fc0 <sb>
    800039ce:	00048b1b          	sext.w	s6,s1
    800039d2:	0044d593          	srli	a1,s1,0x4
    800039d6:	018a2783          	lw	a5,24(s4)
    800039da:	9dbd                	addw	a1,a1,a5
    800039dc:	8556                	mv	a0,s5
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	956080e7          	jalr	-1706(ra) # 80003334 <bread>
    800039e6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039e8:	05850993          	addi	s3,a0,88
    800039ec:	00f4f793          	andi	a5,s1,15
    800039f0:	079a                	slli	a5,a5,0x6
    800039f2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039f4:	00099783          	lh	a5,0(s3)
    800039f8:	c785                	beqz	a5,80003a20 <ialloc+0x84>
    brelse(bp);
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	a6a080e7          	jalr	-1430(ra) # 80003464 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a02:	0485                	addi	s1,s1,1
    80003a04:	00ca2703          	lw	a4,12(s4)
    80003a08:	0004879b          	sext.w	a5,s1
    80003a0c:	fce7e1e3          	bltu	a5,a4,800039ce <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a10:	00005517          	auipc	a0,0x5
    80003a14:	de050513          	addi	a0,a0,-544 # 800087f0 <syscallargs+0x120>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	b22080e7          	jalr	-1246(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003a20:	04000613          	li	a2,64
    80003a24:	4581                	li	a1,0
    80003a26:	854e                	mv	a0,s3
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	2a4080e7          	jalr	676(ra) # 80000ccc <memset>
      dip->type = type;
    80003a30:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a34:	854a                	mv	a0,s2
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	cb2080e7          	jalr	-846(ra) # 800046e8 <log_write>
      brelse(bp);
    80003a3e:	854a                	mv	a0,s2
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	a24080e7          	jalr	-1500(ra) # 80003464 <brelse>
      return iget(dev, inum);
    80003a48:	85da                	mv	a1,s6
    80003a4a:	8556                	mv	a0,s5
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	db4080e7          	jalr	-588(ra) # 80003800 <iget>
}
    80003a54:	60a6                	ld	ra,72(sp)
    80003a56:	6406                	ld	s0,64(sp)
    80003a58:	74e2                	ld	s1,56(sp)
    80003a5a:	7942                	ld	s2,48(sp)
    80003a5c:	79a2                	ld	s3,40(sp)
    80003a5e:	7a02                	ld	s4,32(sp)
    80003a60:	6ae2                	ld	s5,24(sp)
    80003a62:	6b42                	ld	s6,16(sp)
    80003a64:	6ba2                	ld	s7,8(sp)
    80003a66:	6161                	addi	sp,sp,80
    80003a68:	8082                	ret

0000000080003a6a <iupdate>:
{
    80003a6a:	1101                	addi	sp,sp,-32
    80003a6c:	ec06                	sd	ra,24(sp)
    80003a6e:	e822                	sd	s0,16(sp)
    80003a70:	e426                	sd	s1,8(sp)
    80003a72:	e04a                	sd	s2,0(sp)
    80003a74:	1000                	addi	s0,sp,32
    80003a76:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a78:	415c                	lw	a5,4(a0)
    80003a7a:	0047d79b          	srliw	a5,a5,0x4
    80003a7e:	0001e597          	auipc	a1,0x1e
    80003a82:	55a5a583          	lw	a1,1370(a1) # 80021fd8 <sb+0x18>
    80003a86:	9dbd                	addw	a1,a1,a5
    80003a88:	4108                	lw	a0,0(a0)
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	8aa080e7          	jalr	-1878(ra) # 80003334 <bread>
    80003a92:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a94:	05850793          	addi	a5,a0,88
    80003a98:	40d8                	lw	a4,4(s1)
    80003a9a:	8b3d                	andi	a4,a4,15
    80003a9c:	071a                	slli	a4,a4,0x6
    80003a9e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003aa0:	04449703          	lh	a4,68(s1)
    80003aa4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003aa8:	04649703          	lh	a4,70(s1)
    80003aac:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003ab0:	04849703          	lh	a4,72(s1)
    80003ab4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ab8:	04a49703          	lh	a4,74(s1)
    80003abc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ac0:	44f8                	lw	a4,76(s1)
    80003ac2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ac4:	03400613          	li	a2,52
    80003ac8:	05048593          	addi	a1,s1,80
    80003acc:	00c78513          	addi	a0,a5,12
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	258080e7          	jalr	600(ra) # 80000d28 <memmove>
  log_write(bp);
    80003ad8:	854a                	mv	a0,s2
    80003ada:	00001097          	auipc	ra,0x1
    80003ade:	c0e080e7          	jalr	-1010(ra) # 800046e8 <log_write>
  brelse(bp);
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	980080e7          	jalr	-1664(ra) # 80003464 <brelse>
}
    80003aec:	60e2                	ld	ra,24(sp)
    80003aee:	6442                	ld	s0,16(sp)
    80003af0:	64a2                	ld	s1,8(sp)
    80003af2:	6902                	ld	s2,0(sp)
    80003af4:	6105                	addi	sp,sp,32
    80003af6:	8082                	ret

0000000080003af8 <idup>:
{
    80003af8:	1101                	addi	sp,sp,-32
    80003afa:	ec06                	sd	ra,24(sp)
    80003afc:	e822                	sd	s0,16(sp)
    80003afe:	e426                	sd	s1,8(sp)
    80003b00:	1000                	addi	s0,sp,32
    80003b02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b04:	0001e517          	auipc	a0,0x1e
    80003b08:	4dc50513          	addi	a0,a0,1244 # 80021fe0 <itable>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	0c4080e7          	jalr	196(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003b14:	449c                	lw	a5,8(s1)
    80003b16:	2785                	addiw	a5,a5,1
    80003b18:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b1a:	0001e517          	auipc	a0,0x1e
    80003b1e:	4c650513          	addi	a0,a0,1222 # 80021fe0 <itable>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	162080e7          	jalr	354(ra) # 80000c84 <release>
}
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	60e2                	ld	ra,24(sp)
    80003b2e:	6442                	ld	s0,16(sp)
    80003b30:	64a2                	ld	s1,8(sp)
    80003b32:	6105                	addi	sp,sp,32
    80003b34:	8082                	ret

0000000080003b36 <ilock>:
{
    80003b36:	1101                	addi	sp,sp,-32
    80003b38:	ec06                	sd	ra,24(sp)
    80003b3a:	e822                	sd	s0,16(sp)
    80003b3c:	e426                	sd	s1,8(sp)
    80003b3e:	e04a                	sd	s2,0(sp)
    80003b40:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b42:	c115                	beqz	a0,80003b66 <ilock+0x30>
    80003b44:	84aa                	mv	s1,a0
    80003b46:	451c                	lw	a5,8(a0)
    80003b48:	00f05f63          	blez	a5,80003b66 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b4c:	0541                	addi	a0,a0,16
    80003b4e:	00001097          	auipc	ra,0x1
    80003b52:	cb8080e7          	jalr	-840(ra) # 80004806 <acquiresleep>
  if(ip->valid == 0){
    80003b56:	40bc                	lw	a5,64(s1)
    80003b58:	cf99                	beqz	a5,80003b76 <ilock+0x40>
}
    80003b5a:	60e2                	ld	ra,24(sp)
    80003b5c:	6442                	ld	s0,16(sp)
    80003b5e:	64a2                	ld	s1,8(sp)
    80003b60:	6902                	ld	s2,0(sp)
    80003b62:	6105                	addi	sp,sp,32
    80003b64:	8082                	ret
    panic("ilock");
    80003b66:	00005517          	auipc	a0,0x5
    80003b6a:	ca250513          	addi	a0,a0,-862 # 80008808 <syscallargs+0x138>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	9cc080e7          	jalr	-1588(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b76:	40dc                	lw	a5,4(s1)
    80003b78:	0047d79b          	srliw	a5,a5,0x4
    80003b7c:	0001e597          	auipc	a1,0x1e
    80003b80:	45c5a583          	lw	a1,1116(a1) # 80021fd8 <sb+0x18>
    80003b84:	9dbd                	addw	a1,a1,a5
    80003b86:	4088                	lw	a0,0(s1)
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	7ac080e7          	jalr	1964(ra) # 80003334 <bread>
    80003b90:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b92:	05850593          	addi	a1,a0,88
    80003b96:	40dc                	lw	a5,4(s1)
    80003b98:	8bbd                	andi	a5,a5,15
    80003b9a:	079a                	slli	a5,a5,0x6
    80003b9c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b9e:	00059783          	lh	a5,0(a1)
    80003ba2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ba6:	00259783          	lh	a5,2(a1)
    80003baa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bae:	00459783          	lh	a5,4(a1)
    80003bb2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bb6:	00659783          	lh	a5,6(a1)
    80003bba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bbe:	459c                	lw	a5,8(a1)
    80003bc0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bc2:	03400613          	li	a2,52
    80003bc6:	05b1                	addi	a1,a1,12
    80003bc8:	05048513          	addi	a0,s1,80
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	15c080e7          	jalr	348(ra) # 80000d28 <memmove>
    brelse(bp);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	88e080e7          	jalr	-1906(ra) # 80003464 <brelse>
    ip->valid = 1;
    80003bde:	4785                	li	a5,1
    80003be0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003be2:	04449783          	lh	a5,68(s1)
    80003be6:	fbb5                	bnez	a5,80003b5a <ilock+0x24>
      panic("ilock: no type");
    80003be8:	00005517          	auipc	a0,0x5
    80003bec:	c2850513          	addi	a0,a0,-984 # 80008810 <syscallargs+0x140>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	94a080e7          	jalr	-1718(ra) # 8000053a <panic>

0000000080003bf8 <iunlock>:
{
    80003bf8:	1101                	addi	sp,sp,-32
    80003bfa:	ec06                	sd	ra,24(sp)
    80003bfc:	e822                	sd	s0,16(sp)
    80003bfe:	e426                	sd	s1,8(sp)
    80003c00:	e04a                	sd	s2,0(sp)
    80003c02:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c04:	c905                	beqz	a0,80003c34 <iunlock+0x3c>
    80003c06:	84aa                	mv	s1,a0
    80003c08:	01050913          	addi	s2,a0,16
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00001097          	auipc	ra,0x1
    80003c12:	c92080e7          	jalr	-878(ra) # 800048a0 <holdingsleep>
    80003c16:	cd19                	beqz	a0,80003c34 <iunlock+0x3c>
    80003c18:	449c                	lw	a5,8(s1)
    80003c1a:	00f05d63          	blez	a5,80003c34 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c1e:	854a                	mv	a0,s2
    80003c20:	00001097          	auipc	ra,0x1
    80003c24:	c3c080e7          	jalr	-964(ra) # 8000485c <releasesleep>
}
    80003c28:	60e2                	ld	ra,24(sp)
    80003c2a:	6442                	ld	s0,16(sp)
    80003c2c:	64a2                	ld	s1,8(sp)
    80003c2e:	6902                	ld	s2,0(sp)
    80003c30:	6105                	addi	sp,sp,32
    80003c32:	8082                	ret
    panic("iunlock");
    80003c34:	00005517          	auipc	a0,0x5
    80003c38:	bec50513          	addi	a0,a0,-1044 # 80008820 <syscallargs+0x150>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	8fe080e7          	jalr	-1794(ra) # 8000053a <panic>

0000000080003c44 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c44:	7179                	addi	sp,sp,-48
    80003c46:	f406                	sd	ra,40(sp)
    80003c48:	f022                	sd	s0,32(sp)
    80003c4a:	ec26                	sd	s1,24(sp)
    80003c4c:	e84a                	sd	s2,16(sp)
    80003c4e:	e44e                	sd	s3,8(sp)
    80003c50:	e052                	sd	s4,0(sp)
    80003c52:	1800                	addi	s0,sp,48
    80003c54:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c56:	05050493          	addi	s1,a0,80
    80003c5a:	08050913          	addi	s2,a0,128
    80003c5e:	a021                	j	80003c66 <itrunc+0x22>
    80003c60:	0491                	addi	s1,s1,4
    80003c62:	01248d63          	beq	s1,s2,80003c7c <itrunc+0x38>
    if(ip->addrs[i]){
    80003c66:	408c                	lw	a1,0(s1)
    80003c68:	dde5                	beqz	a1,80003c60 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c6a:	0009a503          	lw	a0,0(s3)
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	90c080e7          	jalr	-1780(ra) # 8000357a <bfree>
      ip->addrs[i] = 0;
    80003c76:	0004a023          	sw	zero,0(s1)
    80003c7a:	b7dd                	j	80003c60 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c7c:	0809a583          	lw	a1,128(s3)
    80003c80:	e185                	bnez	a1,80003ca0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c82:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c86:	854e                	mv	a0,s3
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	de2080e7          	jalr	-542(ra) # 80003a6a <iupdate>
}
    80003c90:	70a2                	ld	ra,40(sp)
    80003c92:	7402                	ld	s0,32(sp)
    80003c94:	64e2                	ld	s1,24(sp)
    80003c96:	6942                	ld	s2,16(sp)
    80003c98:	69a2                	ld	s3,8(sp)
    80003c9a:	6a02                	ld	s4,0(sp)
    80003c9c:	6145                	addi	sp,sp,48
    80003c9e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ca0:	0009a503          	lw	a0,0(s3)
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	690080e7          	jalr	1680(ra) # 80003334 <bread>
    80003cac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cae:	05850493          	addi	s1,a0,88
    80003cb2:	45850913          	addi	s2,a0,1112
    80003cb6:	a021                	j	80003cbe <itrunc+0x7a>
    80003cb8:	0491                	addi	s1,s1,4
    80003cba:	01248b63          	beq	s1,s2,80003cd0 <itrunc+0x8c>
      if(a[j])
    80003cbe:	408c                	lw	a1,0(s1)
    80003cc0:	dde5                	beqz	a1,80003cb8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003cc2:	0009a503          	lw	a0,0(s3)
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	8b4080e7          	jalr	-1868(ra) # 8000357a <bfree>
    80003cce:	b7ed                	j	80003cb8 <itrunc+0x74>
    brelse(bp);
    80003cd0:	8552                	mv	a0,s4
    80003cd2:	fffff097          	auipc	ra,0xfffff
    80003cd6:	792080e7          	jalr	1938(ra) # 80003464 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cda:	0809a583          	lw	a1,128(s3)
    80003cde:	0009a503          	lw	a0,0(s3)
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	898080e7          	jalr	-1896(ra) # 8000357a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cea:	0809a023          	sw	zero,128(s3)
    80003cee:	bf51                	j	80003c82 <itrunc+0x3e>

0000000080003cf0 <iput>:
{
    80003cf0:	1101                	addi	sp,sp,-32
    80003cf2:	ec06                	sd	ra,24(sp)
    80003cf4:	e822                	sd	s0,16(sp)
    80003cf6:	e426                	sd	s1,8(sp)
    80003cf8:	e04a                	sd	s2,0(sp)
    80003cfa:	1000                	addi	s0,sp,32
    80003cfc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cfe:	0001e517          	auipc	a0,0x1e
    80003d02:	2e250513          	addi	a0,a0,738 # 80021fe0 <itable>
    80003d06:	ffffd097          	auipc	ra,0xffffd
    80003d0a:	eca080e7          	jalr	-310(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d0e:	4498                	lw	a4,8(s1)
    80003d10:	4785                	li	a5,1
    80003d12:	02f70363          	beq	a4,a5,80003d38 <iput+0x48>
  ip->ref--;
    80003d16:	449c                	lw	a5,8(s1)
    80003d18:	37fd                	addiw	a5,a5,-1
    80003d1a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d1c:	0001e517          	auipc	a0,0x1e
    80003d20:	2c450513          	addi	a0,a0,708 # 80021fe0 <itable>
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	f60080e7          	jalr	-160(ra) # 80000c84 <release>
}
    80003d2c:	60e2                	ld	ra,24(sp)
    80003d2e:	6442                	ld	s0,16(sp)
    80003d30:	64a2                	ld	s1,8(sp)
    80003d32:	6902                	ld	s2,0(sp)
    80003d34:	6105                	addi	sp,sp,32
    80003d36:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d38:	40bc                	lw	a5,64(s1)
    80003d3a:	dff1                	beqz	a5,80003d16 <iput+0x26>
    80003d3c:	04a49783          	lh	a5,74(s1)
    80003d40:	fbf9                	bnez	a5,80003d16 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d42:	01048913          	addi	s2,s1,16
    80003d46:	854a                	mv	a0,s2
    80003d48:	00001097          	auipc	ra,0x1
    80003d4c:	abe080e7          	jalr	-1346(ra) # 80004806 <acquiresleep>
    release(&itable.lock);
    80003d50:	0001e517          	auipc	a0,0x1e
    80003d54:	29050513          	addi	a0,a0,656 # 80021fe0 <itable>
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	f2c080e7          	jalr	-212(ra) # 80000c84 <release>
    itrunc(ip);
    80003d60:	8526                	mv	a0,s1
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	ee2080e7          	jalr	-286(ra) # 80003c44 <itrunc>
    ip->type = 0;
    80003d6a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d6e:	8526                	mv	a0,s1
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	cfa080e7          	jalr	-774(ra) # 80003a6a <iupdate>
    ip->valid = 0;
    80003d78:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d7c:	854a                	mv	a0,s2
    80003d7e:	00001097          	auipc	ra,0x1
    80003d82:	ade080e7          	jalr	-1314(ra) # 8000485c <releasesleep>
    acquire(&itable.lock);
    80003d86:	0001e517          	auipc	a0,0x1e
    80003d8a:	25a50513          	addi	a0,a0,602 # 80021fe0 <itable>
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	e42080e7          	jalr	-446(ra) # 80000bd0 <acquire>
    80003d96:	b741                	j	80003d16 <iput+0x26>

0000000080003d98 <iunlockput>:
{
    80003d98:	1101                	addi	sp,sp,-32
    80003d9a:	ec06                	sd	ra,24(sp)
    80003d9c:	e822                	sd	s0,16(sp)
    80003d9e:	e426                	sd	s1,8(sp)
    80003da0:	1000                	addi	s0,sp,32
    80003da2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	e54080e7          	jalr	-428(ra) # 80003bf8 <iunlock>
  iput(ip);
    80003dac:	8526                	mv	a0,s1
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	f42080e7          	jalr	-190(ra) # 80003cf0 <iput>
}
    80003db6:	60e2                	ld	ra,24(sp)
    80003db8:	6442                	ld	s0,16(sp)
    80003dba:	64a2                	ld	s1,8(sp)
    80003dbc:	6105                	addi	sp,sp,32
    80003dbe:	8082                	ret

0000000080003dc0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dc0:	1141                	addi	sp,sp,-16
    80003dc2:	e422                	sd	s0,8(sp)
    80003dc4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003dc6:	411c                	lw	a5,0(a0)
    80003dc8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dca:	415c                	lw	a5,4(a0)
    80003dcc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dce:	04451783          	lh	a5,68(a0)
    80003dd2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003dd6:	04a51783          	lh	a5,74(a0)
    80003dda:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dde:	04c56783          	lwu	a5,76(a0)
    80003de2:	e99c                	sd	a5,16(a1)
}
    80003de4:	6422                	ld	s0,8(sp)
    80003de6:	0141                	addi	sp,sp,16
    80003de8:	8082                	ret

0000000080003dea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dea:	457c                	lw	a5,76(a0)
    80003dec:	0ed7e963          	bltu	a5,a3,80003ede <readi+0xf4>
{
    80003df0:	7159                	addi	sp,sp,-112
    80003df2:	f486                	sd	ra,104(sp)
    80003df4:	f0a2                	sd	s0,96(sp)
    80003df6:	eca6                	sd	s1,88(sp)
    80003df8:	e8ca                	sd	s2,80(sp)
    80003dfa:	e4ce                	sd	s3,72(sp)
    80003dfc:	e0d2                	sd	s4,64(sp)
    80003dfe:	fc56                	sd	s5,56(sp)
    80003e00:	f85a                	sd	s6,48(sp)
    80003e02:	f45e                	sd	s7,40(sp)
    80003e04:	f062                	sd	s8,32(sp)
    80003e06:	ec66                	sd	s9,24(sp)
    80003e08:	e86a                	sd	s10,16(sp)
    80003e0a:	e46e                	sd	s11,8(sp)
    80003e0c:	1880                	addi	s0,sp,112
    80003e0e:	8baa                	mv	s7,a0
    80003e10:	8c2e                	mv	s8,a1
    80003e12:	8ab2                	mv	s5,a2
    80003e14:	84b6                	mv	s1,a3
    80003e16:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e18:	9f35                	addw	a4,a4,a3
    return 0;
    80003e1a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e1c:	0ad76063          	bltu	a4,a3,80003ebc <readi+0xd2>
  if(off + n > ip->size)
    80003e20:	00e7f463          	bgeu	a5,a4,80003e28 <readi+0x3e>
    n = ip->size - off;
    80003e24:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e28:	0a0b0963          	beqz	s6,80003eda <readi+0xf0>
    80003e2c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e2e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e32:	5cfd                	li	s9,-1
    80003e34:	a82d                	j	80003e6e <readi+0x84>
    80003e36:	020a1d93          	slli	s11,s4,0x20
    80003e3a:	020ddd93          	srli	s11,s11,0x20
    80003e3e:	05890613          	addi	a2,s2,88
    80003e42:	86ee                	mv	a3,s11
    80003e44:	963a                	add	a2,a2,a4
    80003e46:	85d6                	mv	a1,s5
    80003e48:	8562                	mv	a0,s8
    80003e4a:	fffff097          	auipc	ra,0xfffff
    80003e4e:	942080e7          	jalr	-1726(ra) # 8000278c <either_copyout>
    80003e52:	05950d63          	beq	a0,s9,80003eac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e56:	854a                	mv	a0,s2
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	60c080e7          	jalr	1548(ra) # 80003464 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e60:	013a09bb          	addw	s3,s4,s3
    80003e64:	009a04bb          	addw	s1,s4,s1
    80003e68:	9aee                	add	s5,s5,s11
    80003e6a:	0569f763          	bgeu	s3,s6,80003eb8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e6e:	000ba903          	lw	s2,0(s7)
    80003e72:	00a4d59b          	srliw	a1,s1,0xa
    80003e76:	855e                	mv	a0,s7
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	8ac080e7          	jalr	-1876(ra) # 80003724 <bmap>
    80003e80:	0005059b          	sext.w	a1,a0
    80003e84:	854a                	mv	a0,s2
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	4ae080e7          	jalr	1198(ra) # 80003334 <bread>
    80003e8e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e90:	3ff4f713          	andi	a4,s1,1023
    80003e94:	40ed07bb          	subw	a5,s10,a4
    80003e98:	413b06bb          	subw	a3,s6,s3
    80003e9c:	8a3e                	mv	s4,a5
    80003e9e:	2781                	sext.w	a5,a5
    80003ea0:	0006861b          	sext.w	a2,a3
    80003ea4:	f8f679e3          	bgeu	a2,a5,80003e36 <readi+0x4c>
    80003ea8:	8a36                	mv	s4,a3
    80003eaa:	b771                	j	80003e36 <readi+0x4c>
      brelse(bp);
    80003eac:	854a                	mv	a0,s2
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	5b6080e7          	jalr	1462(ra) # 80003464 <brelse>
      tot = -1;
    80003eb6:	59fd                	li	s3,-1
  }
  return tot;
    80003eb8:	0009851b          	sext.w	a0,s3
}
    80003ebc:	70a6                	ld	ra,104(sp)
    80003ebe:	7406                	ld	s0,96(sp)
    80003ec0:	64e6                	ld	s1,88(sp)
    80003ec2:	6946                	ld	s2,80(sp)
    80003ec4:	69a6                	ld	s3,72(sp)
    80003ec6:	6a06                	ld	s4,64(sp)
    80003ec8:	7ae2                	ld	s5,56(sp)
    80003eca:	7b42                	ld	s6,48(sp)
    80003ecc:	7ba2                	ld	s7,40(sp)
    80003ece:	7c02                	ld	s8,32(sp)
    80003ed0:	6ce2                	ld	s9,24(sp)
    80003ed2:	6d42                	ld	s10,16(sp)
    80003ed4:	6da2                	ld	s11,8(sp)
    80003ed6:	6165                	addi	sp,sp,112
    80003ed8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eda:	89da                	mv	s3,s6
    80003edc:	bff1                	j	80003eb8 <readi+0xce>
    return 0;
    80003ede:	4501                	li	a0,0
}
    80003ee0:	8082                	ret

0000000080003ee2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ee2:	457c                	lw	a5,76(a0)
    80003ee4:	10d7e863          	bltu	a5,a3,80003ff4 <writei+0x112>
{
    80003ee8:	7159                	addi	sp,sp,-112
    80003eea:	f486                	sd	ra,104(sp)
    80003eec:	f0a2                	sd	s0,96(sp)
    80003eee:	eca6                	sd	s1,88(sp)
    80003ef0:	e8ca                	sd	s2,80(sp)
    80003ef2:	e4ce                	sd	s3,72(sp)
    80003ef4:	e0d2                	sd	s4,64(sp)
    80003ef6:	fc56                	sd	s5,56(sp)
    80003ef8:	f85a                	sd	s6,48(sp)
    80003efa:	f45e                	sd	s7,40(sp)
    80003efc:	f062                	sd	s8,32(sp)
    80003efe:	ec66                	sd	s9,24(sp)
    80003f00:	e86a                	sd	s10,16(sp)
    80003f02:	e46e                	sd	s11,8(sp)
    80003f04:	1880                	addi	s0,sp,112
    80003f06:	8b2a                	mv	s6,a0
    80003f08:	8c2e                	mv	s8,a1
    80003f0a:	8ab2                	mv	s5,a2
    80003f0c:	8936                	mv	s2,a3
    80003f0e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f10:	00e687bb          	addw	a5,a3,a4
    80003f14:	0ed7e263          	bltu	a5,a3,80003ff8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f18:	00043737          	lui	a4,0x43
    80003f1c:	0ef76063          	bltu	a4,a5,80003ffc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f20:	0c0b8863          	beqz	s7,80003ff0 <writei+0x10e>
    80003f24:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f26:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f2a:	5cfd                	li	s9,-1
    80003f2c:	a091                	j	80003f70 <writei+0x8e>
    80003f2e:	02099d93          	slli	s11,s3,0x20
    80003f32:	020ddd93          	srli	s11,s11,0x20
    80003f36:	05848513          	addi	a0,s1,88
    80003f3a:	86ee                	mv	a3,s11
    80003f3c:	8656                	mv	a2,s5
    80003f3e:	85e2                	mv	a1,s8
    80003f40:	953a                	add	a0,a0,a4
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	8a0080e7          	jalr	-1888(ra) # 800027e2 <either_copyin>
    80003f4a:	07950263          	beq	a0,s9,80003fae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	798080e7          	jalr	1944(ra) # 800046e8 <log_write>
    brelse(bp);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	50a080e7          	jalr	1290(ra) # 80003464 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f62:	01498a3b          	addw	s4,s3,s4
    80003f66:	0129893b          	addw	s2,s3,s2
    80003f6a:	9aee                	add	s5,s5,s11
    80003f6c:	057a7663          	bgeu	s4,s7,80003fb8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f70:	000b2483          	lw	s1,0(s6)
    80003f74:	00a9559b          	srliw	a1,s2,0xa
    80003f78:	855a                	mv	a0,s6
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	7aa080e7          	jalr	1962(ra) # 80003724 <bmap>
    80003f82:	0005059b          	sext.w	a1,a0
    80003f86:	8526                	mv	a0,s1
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	3ac080e7          	jalr	940(ra) # 80003334 <bread>
    80003f90:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f92:	3ff97713          	andi	a4,s2,1023
    80003f96:	40ed07bb          	subw	a5,s10,a4
    80003f9a:	414b86bb          	subw	a3,s7,s4
    80003f9e:	89be                	mv	s3,a5
    80003fa0:	2781                	sext.w	a5,a5
    80003fa2:	0006861b          	sext.w	a2,a3
    80003fa6:	f8f674e3          	bgeu	a2,a5,80003f2e <writei+0x4c>
    80003faa:	89b6                	mv	s3,a3
    80003fac:	b749                	j	80003f2e <writei+0x4c>
      brelse(bp);
    80003fae:	8526                	mv	a0,s1
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	4b4080e7          	jalr	1204(ra) # 80003464 <brelse>
  }

  if(off > ip->size)
    80003fb8:	04cb2783          	lw	a5,76(s6)
    80003fbc:	0127f463          	bgeu	a5,s2,80003fc4 <writei+0xe2>
    ip->size = off;
    80003fc0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fc4:	855a                	mv	a0,s6
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	aa4080e7          	jalr	-1372(ra) # 80003a6a <iupdate>

  return tot;
    80003fce:	000a051b          	sext.w	a0,s4
}
    80003fd2:	70a6                	ld	ra,104(sp)
    80003fd4:	7406                	ld	s0,96(sp)
    80003fd6:	64e6                	ld	s1,88(sp)
    80003fd8:	6946                	ld	s2,80(sp)
    80003fda:	69a6                	ld	s3,72(sp)
    80003fdc:	6a06                	ld	s4,64(sp)
    80003fde:	7ae2                	ld	s5,56(sp)
    80003fe0:	7b42                	ld	s6,48(sp)
    80003fe2:	7ba2                	ld	s7,40(sp)
    80003fe4:	7c02                	ld	s8,32(sp)
    80003fe6:	6ce2                	ld	s9,24(sp)
    80003fe8:	6d42                	ld	s10,16(sp)
    80003fea:	6da2                	ld	s11,8(sp)
    80003fec:	6165                	addi	sp,sp,112
    80003fee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ff0:	8a5e                	mv	s4,s7
    80003ff2:	bfc9                	j	80003fc4 <writei+0xe2>
    return -1;
    80003ff4:	557d                	li	a0,-1
}
    80003ff6:	8082                	ret
    return -1;
    80003ff8:	557d                	li	a0,-1
    80003ffa:	bfe1                	j	80003fd2 <writei+0xf0>
    return -1;
    80003ffc:	557d                	li	a0,-1
    80003ffe:	bfd1                	j	80003fd2 <writei+0xf0>

0000000080004000 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004000:	1141                	addi	sp,sp,-16
    80004002:	e406                	sd	ra,8(sp)
    80004004:	e022                	sd	s0,0(sp)
    80004006:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004008:	4639                	li	a2,14
    8000400a:	ffffd097          	auipc	ra,0xffffd
    8000400e:	d92080e7          	jalr	-622(ra) # 80000d9c <strncmp>
}
    80004012:	60a2                	ld	ra,8(sp)
    80004014:	6402                	ld	s0,0(sp)
    80004016:	0141                	addi	sp,sp,16
    80004018:	8082                	ret

000000008000401a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000401a:	7139                	addi	sp,sp,-64
    8000401c:	fc06                	sd	ra,56(sp)
    8000401e:	f822                	sd	s0,48(sp)
    80004020:	f426                	sd	s1,40(sp)
    80004022:	f04a                	sd	s2,32(sp)
    80004024:	ec4e                	sd	s3,24(sp)
    80004026:	e852                	sd	s4,16(sp)
    80004028:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000402a:	04451703          	lh	a4,68(a0)
    8000402e:	4785                	li	a5,1
    80004030:	00f71a63          	bne	a4,a5,80004044 <dirlookup+0x2a>
    80004034:	892a                	mv	s2,a0
    80004036:	89ae                	mv	s3,a1
    80004038:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403a:	457c                	lw	a5,76(a0)
    8000403c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000403e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004040:	e79d                	bnez	a5,8000406e <dirlookup+0x54>
    80004042:	a8a5                	j	800040ba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004044:	00004517          	auipc	a0,0x4
    80004048:	7e450513          	addi	a0,a0,2020 # 80008828 <syscallargs+0x158>
    8000404c:	ffffc097          	auipc	ra,0xffffc
    80004050:	4ee080e7          	jalr	1262(ra) # 8000053a <panic>
      panic("dirlookup read");
    80004054:	00004517          	auipc	a0,0x4
    80004058:	7ec50513          	addi	a0,a0,2028 # 80008840 <syscallargs+0x170>
    8000405c:	ffffc097          	auipc	ra,0xffffc
    80004060:	4de080e7          	jalr	1246(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004064:	24c1                	addiw	s1,s1,16
    80004066:	04c92783          	lw	a5,76(s2)
    8000406a:	04f4f763          	bgeu	s1,a5,800040b8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406e:	4741                	li	a4,16
    80004070:	86a6                	mv	a3,s1
    80004072:	fc040613          	addi	a2,s0,-64
    80004076:	4581                	li	a1,0
    80004078:	854a                	mv	a0,s2
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	d70080e7          	jalr	-656(ra) # 80003dea <readi>
    80004082:	47c1                	li	a5,16
    80004084:	fcf518e3          	bne	a0,a5,80004054 <dirlookup+0x3a>
    if(de.inum == 0)
    80004088:	fc045783          	lhu	a5,-64(s0)
    8000408c:	dfe1                	beqz	a5,80004064 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000408e:	fc240593          	addi	a1,s0,-62
    80004092:	854e                	mv	a0,s3
    80004094:	00000097          	auipc	ra,0x0
    80004098:	f6c080e7          	jalr	-148(ra) # 80004000 <namecmp>
    8000409c:	f561                	bnez	a0,80004064 <dirlookup+0x4a>
      if(poff)
    8000409e:	000a0463          	beqz	s4,800040a6 <dirlookup+0x8c>
        *poff = off;
    800040a2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040a6:	fc045583          	lhu	a1,-64(s0)
    800040aa:	00092503          	lw	a0,0(s2)
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	752080e7          	jalr	1874(ra) # 80003800 <iget>
    800040b6:	a011                	j	800040ba <dirlookup+0xa0>
  return 0;
    800040b8:	4501                	li	a0,0
}
    800040ba:	70e2                	ld	ra,56(sp)
    800040bc:	7442                	ld	s0,48(sp)
    800040be:	74a2                	ld	s1,40(sp)
    800040c0:	7902                	ld	s2,32(sp)
    800040c2:	69e2                	ld	s3,24(sp)
    800040c4:	6a42                	ld	s4,16(sp)
    800040c6:	6121                	addi	sp,sp,64
    800040c8:	8082                	ret

00000000800040ca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040ca:	711d                	addi	sp,sp,-96
    800040cc:	ec86                	sd	ra,88(sp)
    800040ce:	e8a2                	sd	s0,80(sp)
    800040d0:	e4a6                	sd	s1,72(sp)
    800040d2:	e0ca                	sd	s2,64(sp)
    800040d4:	fc4e                	sd	s3,56(sp)
    800040d6:	f852                	sd	s4,48(sp)
    800040d8:	f456                	sd	s5,40(sp)
    800040da:	f05a                	sd	s6,32(sp)
    800040dc:	ec5e                	sd	s7,24(sp)
    800040de:	e862                	sd	s8,16(sp)
    800040e0:	e466                	sd	s9,8(sp)
    800040e2:	e06a                	sd	s10,0(sp)
    800040e4:	1080                	addi	s0,sp,96
    800040e6:	84aa                	mv	s1,a0
    800040e8:	8b2e                	mv	s6,a1
    800040ea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040ec:	00054703          	lbu	a4,0(a0)
    800040f0:	02f00793          	li	a5,47
    800040f4:	02f70363          	beq	a4,a5,8000411a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040f8:	ffffe097          	auipc	ra,0xffffe
    800040fc:	89e080e7          	jalr	-1890(ra) # 80001996 <myproc>
    80004100:	15053503          	ld	a0,336(a0)
    80004104:	00000097          	auipc	ra,0x0
    80004108:	9f4080e7          	jalr	-1548(ra) # 80003af8 <idup>
    8000410c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000410e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004112:	4cb5                	li	s9,13
  len = path - s;
    80004114:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004116:	4c05                	li	s8,1
    80004118:	a87d                	j	800041d6 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000411a:	4585                	li	a1,1
    8000411c:	4505                	li	a0,1
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	6e2080e7          	jalr	1762(ra) # 80003800 <iget>
    80004126:	8a2a                	mv	s4,a0
    80004128:	b7dd                	j	8000410e <namex+0x44>
      iunlockput(ip);
    8000412a:	8552                	mv	a0,s4
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	c6c080e7          	jalr	-916(ra) # 80003d98 <iunlockput>
      return 0;
    80004134:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004136:	8552                	mv	a0,s4
    80004138:	60e6                	ld	ra,88(sp)
    8000413a:	6446                	ld	s0,80(sp)
    8000413c:	64a6                	ld	s1,72(sp)
    8000413e:	6906                	ld	s2,64(sp)
    80004140:	79e2                	ld	s3,56(sp)
    80004142:	7a42                	ld	s4,48(sp)
    80004144:	7aa2                	ld	s5,40(sp)
    80004146:	7b02                	ld	s6,32(sp)
    80004148:	6be2                	ld	s7,24(sp)
    8000414a:	6c42                	ld	s8,16(sp)
    8000414c:	6ca2                	ld	s9,8(sp)
    8000414e:	6d02                	ld	s10,0(sp)
    80004150:	6125                	addi	sp,sp,96
    80004152:	8082                	ret
      iunlock(ip);
    80004154:	8552                	mv	a0,s4
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	aa2080e7          	jalr	-1374(ra) # 80003bf8 <iunlock>
      return ip;
    8000415e:	bfe1                	j	80004136 <namex+0x6c>
      iunlockput(ip);
    80004160:	8552                	mv	a0,s4
    80004162:	00000097          	auipc	ra,0x0
    80004166:	c36080e7          	jalr	-970(ra) # 80003d98 <iunlockput>
      return 0;
    8000416a:	8a4e                	mv	s4,s3
    8000416c:	b7e9                	j	80004136 <namex+0x6c>
  len = path - s;
    8000416e:	40998633          	sub	a2,s3,s1
    80004172:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004176:	09acd863          	bge	s9,s10,80004206 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000417a:	4639                	li	a2,14
    8000417c:	85a6                	mv	a1,s1
    8000417e:	8556                	mv	a0,s5
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	ba8080e7          	jalr	-1112(ra) # 80000d28 <memmove>
    80004188:	84ce                	mv	s1,s3
  while(*path == '/')
    8000418a:	0004c783          	lbu	a5,0(s1)
    8000418e:	01279763          	bne	a5,s2,8000419c <namex+0xd2>
    path++;
    80004192:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004194:	0004c783          	lbu	a5,0(s1)
    80004198:	ff278de3          	beq	a5,s2,80004192 <namex+0xc8>
    ilock(ip);
    8000419c:	8552                	mv	a0,s4
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	998080e7          	jalr	-1640(ra) # 80003b36 <ilock>
    if(ip->type != T_DIR){
    800041a6:	044a1783          	lh	a5,68(s4)
    800041aa:	f98790e3          	bne	a5,s8,8000412a <namex+0x60>
    if(nameiparent && *path == '\0'){
    800041ae:	000b0563          	beqz	s6,800041b8 <namex+0xee>
    800041b2:	0004c783          	lbu	a5,0(s1)
    800041b6:	dfd9                	beqz	a5,80004154 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041b8:	865e                	mv	a2,s7
    800041ba:	85d6                	mv	a1,s5
    800041bc:	8552                	mv	a0,s4
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	e5c080e7          	jalr	-420(ra) # 8000401a <dirlookup>
    800041c6:	89aa                	mv	s3,a0
    800041c8:	dd41                	beqz	a0,80004160 <namex+0x96>
    iunlockput(ip);
    800041ca:	8552                	mv	a0,s4
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	bcc080e7          	jalr	-1076(ra) # 80003d98 <iunlockput>
    ip = next;
    800041d4:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041d6:	0004c783          	lbu	a5,0(s1)
    800041da:	01279763          	bne	a5,s2,800041e8 <namex+0x11e>
    path++;
    800041de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041e0:	0004c783          	lbu	a5,0(s1)
    800041e4:	ff278de3          	beq	a5,s2,800041de <namex+0x114>
  if(*path == 0)
    800041e8:	cb9d                	beqz	a5,8000421e <namex+0x154>
  while(*path != '/' && *path != 0)
    800041ea:	0004c783          	lbu	a5,0(s1)
    800041ee:	89a6                	mv	s3,s1
  len = path - s;
    800041f0:	8d5e                	mv	s10,s7
    800041f2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041f4:	01278963          	beq	a5,s2,80004206 <namex+0x13c>
    800041f8:	dbbd                	beqz	a5,8000416e <namex+0xa4>
    path++;
    800041fa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041fc:	0009c783          	lbu	a5,0(s3)
    80004200:	ff279ce3          	bne	a5,s2,800041f8 <namex+0x12e>
    80004204:	b7ad                	j	8000416e <namex+0xa4>
    memmove(name, s, len);
    80004206:	2601                	sext.w	a2,a2
    80004208:	85a6                	mv	a1,s1
    8000420a:	8556                	mv	a0,s5
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	b1c080e7          	jalr	-1252(ra) # 80000d28 <memmove>
    name[len] = 0;
    80004214:	9d56                	add	s10,s10,s5
    80004216:	000d0023          	sb	zero,0(s10)
    8000421a:	84ce                	mv	s1,s3
    8000421c:	b7bd                	j	8000418a <namex+0xc0>
  if(nameiparent){
    8000421e:	f00b0ce3          	beqz	s6,80004136 <namex+0x6c>
    iput(ip);
    80004222:	8552                	mv	a0,s4
    80004224:	00000097          	auipc	ra,0x0
    80004228:	acc080e7          	jalr	-1332(ra) # 80003cf0 <iput>
    return 0;
    8000422c:	4a01                	li	s4,0
    8000422e:	b721                	j	80004136 <namex+0x6c>

0000000080004230 <dirlink>:
{
    80004230:	7139                	addi	sp,sp,-64
    80004232:	fc06                	sd	ra,56(sp)
    80004234:	f822                	sd	s0,48(sp)
    80004236:	f426                	sd	s1,40(sp)
    80004238:	f04a                	sd	s2,32(sp)
    8000423a:	ec4e                	sd	s3,24(sp)
    8000423c:	e852                	sd	s4,16(sp)
    8000423e:	0080                	addi	s0,sp,64
    80004240:	892a                	mv	s2,a0
    80004242:	8a2e                	mv	s4,a1
    80004244:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004246:	4601                	li	a2,0
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	dd2080e7          	jalr	-558(ra) # 8000401a <dirlookup>
    80004250:	e93d                	bnez	a0,800042c6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004252:	04c92483          	lw	s1,76(s2)
    80004256:	c49d                	beqz	s1,80004284 <dirlink+0x54>
    80004258:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000425a:	4741                	li	a4,16
    8000425c:	86a6                	mv	a3,s1
    8000425e:	fc040613          	addi	a2,s0,-64
    80004262:	4581                	li	a1,0
    80004264:	854a                	mv	a0,s2
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	b84080e7          	jalr	-1148(ra) # 80003dea <readi>
    8000426e:	47c1                	li	a5,16
    80004270:	06f51163          	bne	a0,a5,800042d2 <dirlink+0xa2>
    if(de.inum == 0)
    80004274:	fc045783          	lhu	a5,-64(s0)
    80004278:	c791                	beqz	a5,80004284 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427a:	24c1                	addiw	s1,s1,16
    8000427c:	04c92783          	lw	a5,76(s2)
    80004280:	fcf4ede3          	bltu	s1,a5,8000425a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004284:	4639                	li	a2,14
    80004286:	85d2                	mv	a1,s4
    80004288:	fc240513          	addi	a0,s0,-62
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	b4c080e7          	jalr	-1204(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80004294:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004298:	4741                	li	a4,16
    8000429a:	86a6                	mv	a3,s1
    8000429c:	fc040613          	addi	a2,s0,-64
    800042a0:	4581                	li	a1,0
    800042a2:	854a                	mv	a0,s2
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	c3e080e7          	jalr	-962(ra) # 80003ee2 <writei>
    800042ac:	872a                	mv	a4,a0
    800042ae:	47c1                	li	a5,16
  return 0;
    800042b0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b2:	02f71863          	bne	a4,a5,800042e2 <dirlink+0xb2>
}
    800042b6:	70e2                	ld	ra,56(sp)
    800042b8:	7442                	ld	s0,48(sp)
    800042ba:	74a2                	ld	s1,40(sp)
    800042bc:	7902                	ld	s2,32(sp)
    800042be:	69e2                	ld	s3,24(sp)
    800042c0:	6a42                	ld	s4,16(sp)
    800042c2:	6121                	addi	sp,sp,64
    800042c4:	8082                	ret
    iput(ip);
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	a2a080e7          	jalr	-1494(ra) # 80003cf0 <iput>
    return -1;
    800042ce:	557d                	li	a0,-1
    800042d0:	b7dd                	j	800042b6 <dirlink+0x86>
      panic("dirlink read");
    800042d2:	00004517          	auipc	a0,0x4
    800042d6:	57e50513          	addi	a0,a0,1406 # 80008850 <syscallargs+0x180>
    800042da:	ffffc097          	auipc	ra,0xffffc
    800042de:	260080e7          	jalr	608(ra) # 8000053a <panic>
    panic("dirlink");
    800042e2:	00004517          	auipc	a0,0x4
    800042e6:	67650513          	addi	a0,a0,1654 # 80008958 <syscallargs+0x288>
    800042ea:	ffffc097          	auipc	ra,0xffffc
    800042ee:	250080e7          	jalr	592(ra) # 8000053a <panic>

00000000800042f2 <namei>:

struct inode*
namei(char *path)
{
    800042f2:	1101                	addi	sp,sp,-32
    800042f4:	ec06                	sd	ra,24(sp)
    800042f6:	e822                	sd	s0,16(sp)
    800042f8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042fa:	fe040613          	addi	a2,s0,-32
    800042fe:	4581                	li	a1,0
    80004300:	00000097          	auipc	ra,0x0
    80004304:	dca080e7          	jalr	-566(ra) # 800040ca <namex>
}
    80004308:	60e2                	ld	ra,24(sp)
    8000430a:	6442                	ld	s0,16(sp)
    8000430c:	6105                	addi	sp,sp,32
    8000430e:	8082                	ret

0000000080004310 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004310:	1141                	addi	sp,sp,-16
    80004312:	e406                	sd	ra,8(sp)
    80004314:	e022                	sd	s0,0(sp)
    80004316:	0800                	addi	s0,sp,16
    80004318:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000431a:	4585                	li	a1,1
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	dae080e7          	jalr	-594(ra) # 800040ca <namex>
}
    80004324:	60a2                	ld	ra,8(sp)
    80004326:	6402                	ld	s0,0(sp)
    80004328:	0141                	addi	sp,sp,16
    8000432a:	8082                	ret

000000008000432c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000432c:	1101                	addi	sp,sp,-32
    8000432e:	ec06                	sd	ra,24(sp)
    80004330:	e822                	sd	s0,16(sp)
    80004332:	e426                	sd	s1,8(sp)
    80004334:	e04a                	sd	s2,0(sp)
    80004336:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004338:	0001f917          	auipc	s2,0x1f
    8000433c:	75090913          	addi	s2,s2,1872 # 80023a88 <log>
    80004340:	01892583          	lw	a1,24(s2)
    80004344:	02892503          	lw	a0,40(s2)
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	fec080e7          	jalr	-20(ra) # 80003334 <bread>
    80004350:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004352:	02c92683          	lw	a3,44(s2)
    80004356:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004358:	02d05863          	blez	a3,80004388 <write_head+0x5c>
    8000435c:	0001f797          	auipc	a5,0x1f
    80004360:	75c78793          	addi	a5,a5,1884 # 80023ab8 <log+0x30>
    80004364:	05c50713          	addi	a4,a0,92
    80004368:	36fd                	addiw	a3,a3,-1
    8000436a:	02069613          	slli	a2,a3,0x20
    8000436e:	01e65693          	srli	a3,a2,0x1e
    80004372:	0001f617          	auipc	a2,0x1f
    80004376:	74a60613          	addi	a2,a2,1866 # 80023abc <log+0x34>
    8000437a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000437c:	4390                	lw	a2,0(a5)
    8000437e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004380:	0791                	addi	a5,a5,4
    80004382:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004384:	fed79ce3          	bne	a5,a3,8000437c <write_head+0x50>
  }
  bwrite(buf);
    80004388:	8526                	mv	a0,s1
    8000438a:	fffff097          	auipc	ra,0xfffff
    8000438e:	09c080e7          	jalr	156(ra) # 80003426 <bwrite>
  brelse(buf);
    80004392:	8526                	mv	a0,s1
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	0d0080e7          	jalr	208(ra) # 80003464 <brelse>
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	64a2                	ld	s1,8(sp)
    800043a2:	6902                	ld	s2,0(sp)
    800043a4:	6105                	addi	sp,sp,32
    800043a6:	8082                	ret

00000000800043a8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a8:	0001f797          	auipc	a5,0x1f
    800043ac:	70c7a783          	lw	a5,1804(a5) # 80023ab4 <log+0x2c>
    800043b0:	0af05d63          	blez	a5,8000446a <install_trans+0xc2>
{
    800043b4:	7139                	addi	sp,sp,-64
    800043b6:	fc06                	sd	ra,56(sp)
    800043b8:	f822                	sd	s0,48(sp)
    800043ba:	f426                	sd	s1,40(sp)
    800043bc:	f04a                	sd	s2,32(sp)
    800043be:	ec4e                	sd	s3,24(sp)
    800043c0:	e852                	sd	s4,16(sp)
    800043c2:	e456                	sd	s5,8(sp)
    800043c4:	e05a                	sd	s6,0(sp)
    800043c6:	0080                	addi	s0,sp,64
    800043c8:	8b2a                	mv	s6,a0
    800043ca:	0001fa97          	auipc	s5,0x1f
    800043ce:	6eea8a93          	addi	s5,s5,1774 # 80023ab8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d4:	0001f997          	auipc	s3,0x1f
    800043d8:	6b498993          	addi	s3,s3,1716 # 80023a88 <log>
    800043dc:	a00d                	j	800043fe <install_trans+0x56>
    brelse(lbuf);
    800043de:	854a                	mv	a0,s2
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	084080e7          	jalr	132(ra) # 80003464 <brelse>
    brelse(dbuf);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	07a080e7          	jalr	122(ra) # 80003464 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f2:	2a05                	addiw	s4,s4,1
    800043f4:	0a91                	addi	s5,s5,4
    800043f6:	02c9a783          	lw	a5,44(s3)
    800043fa:	04fa5e63          	bge	s4,a5,80004456 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043fe:	0189a583          	lw	a1,24(s3)
    80004402:	014585bb          	addw	a1,a1,s4
    80004406:	2585                	addiw	a1,a1,1
    80004408:	0289a503          	lw	a0,40(s3)
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	f28080e7          	jalr	-216(ra) # 80003334 <bread>
    80004414:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004416:	000aa583          	lw	a1,0(s5)
    8000441a:	0289a503          	lw	a0,40(s3)
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	f16080e7          	jalr	-234(ra) # 80003334 <bread>
    80004426:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004428:	40000613          	li	a2,1024
    8000442c:	05890593          	addi	a1,s2,88
    80004430:	05850513          	addi	a0,a0,88
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	8f4080e7          	jalr	-1804(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000443c:	8526                	mv	a0,s1
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	fe8080e7          	jalr	-24(ra) # 80003426 <bwrite>
    if(recovering == 0)
    80004446:	f80b1ce3          	bnez	s6,800043de <install_trans+0x36>
      bunpin(dbuf);
    8000444a:	8526                	mv	a0,s1
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	0f2080e7          	jalr	242(ra) # 8000353e <bunpin>
    80004454:	b769                	j	800043de <install_trans+0x36>
}
    80004456:	70e2                	ld	ra,56(sp)
    80004458:	7442                	ld	s0,48(sp)
    8000445a:	74a2                	ld	s1,40(sp)
    8000445c:	7902                	ld	s2,32(sp)
    8000445e:	69e2                	ld	s3,24(sp)
    80004460:	6a42                	ld	s4,16(sp)
    80004462:	6aa2                	ld	s5,8(sp)
    80004464:	6b02                	ld	s6,0(sp)
    80004466:	6121                	addi	sp,sp,64
    80004468:	8082                	ret
    8000446a:	8082                	ret

000000008000446c <initlog>:
{
    8000446c:	7179                	addi	sp,sp,-48
    8000446e:	f406                	sd	ra,40(sp)
    80004470:	f022                	sd	s0,32(sp)
    80004472:	ec26                	sd	s1,24(sp)
    80004474:	e84a                	sd	s2,16(sp)
    80004476:	e44e                	sd	s3,8(sp)
    80004478:	1800                	addi	s0,sp,48
    8000447a:	892a                	mv	s2,a0
    8000447c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000447e:	0001f497          	auipc	s1,0x1f
    80004482:	60a48493          	addi	s1,s1,1546 # 80023a88 <log>
    80004486:	00004597          	auipc	a1,0x4
    8000448a:	3da58593          	addi	a1,a1,986 # 80008860 <syscallargs+0x190>
    8000448e:	8526                	mv	a0,s1
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	6b0080e7          	jalr	1712(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004498:	0149a583          	lw	a1,20(s3)
    8000449c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000449e:	0109a783          	lw	a5,16(s3)
    800044a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044a8:	854a                	mv	a0,s2
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	e8a080e7          	jalr	-374(ra) # 80003334 <bread>
  log.lh.n = lh->n;
    800044b2:	4d34                	lw	a3,88(a0)
    800044b4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044b6:	02d05663          	blez	a3,800044e2 <initlog+0x76>
    800044ba:	05c50793          	addi	a5,a0,92
    800044be:	0001f717          	auipc	a4,0x1f
    800044c2:	5fa70713          	addi	a4,a4,1530 # 80023ab8 <log+0x30>
    800044c6:	36fd                	addiw	a3,a3,-1
    800044c8:	02069613          	slli	a2,a3,0x20
    800044cc:	01e65693          	srli	a3,a2,0x1e
    800044d0:	06050613          	addi	a2,a0,96
    800044d4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044d6:	4390                	lw	a2,0(a5)
    800044d8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044da:	0791                	addi	a5,a5,4
    800044dc:	0711                	addi	a4,a4,4
    800044de:	fed79ce3          	bne	a5,a3,800044d6 <initlog+0x6a>
  brelse(buf);
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	f82080e7          	jalr	-126(ra) # 80003464 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044ea:	4505                	li	a0,1
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	ebc080e7          	jalr	-324(ra) # 800043a8 <install_trans>
  log.lh.n = 0;
    800044f4:	0001f797          	auipc	a5,0x1f
    800044f8:	5c07a023          	sw	zero,1472(a5) # 80023ab4 <log+0x2c>
  write_head(); // clear the log
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	e30080e7          	jalr	-464(ra) # 8000432c <write_head>
}
    80004504:	70a2                	ld	ra,40(sp)
    80004506:	7402                	ld	s0,32(sp)
    80004508:	64e2                	ld	s1,24(sp)
    8000450a:	6942                	ld	s2,16(sp)
    8000450c:	69a2                	ld	s3,8(sp)
    8000450e:	6145                	addi	sp,sp,48
    80004510:	8082                	ret

0000000080004512 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004512:	1101                	addi	sp,sp,-32
    80004514:	ec06                	sd	ra,24(sp)
    80004516:	e822                	sd	s0,16(sp)
    80004518:	e426                	sd	s1,8(sp)
    8000451a:	e04a                	sd	s2,0(sp)
    8000451c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000451e:	0001f517          	auipc	a0,0x1f
    80004522:	56a50513          	addi	a0,a0,1386 # 80023a88 <log>
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	6aa080e7          	jalr	1706(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    8000452e:	0001f497          	auipc	s1,0x1f
    80004532:	55a48493          	addi	s1,s1,1370 # 80023a88 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004536:	4979                	li	s2,30
    80004538:	a039                	j	80004546 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000453a:	85a6                	mv	a1,s1
    8000453c:	8526                	mv	a0,s1
    8000453e:	ffffe097          	auipc	ra,0xffffe
    80004542:	d28080e7          	jalr	-728(ra) # 80002266 <sleep>
    if(log.committing){
    80004546:	50dc                	lw	a5,36(s1)
    80004548:	fbed                	bnez	a5,8000453a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000454a:	5098                	lw	a4,32(s1)
    8000454c:	2705                	addiw	a4,a4,1
    8000454e:	0007069b          	sext.w	a3,a4
    80004552:	0027179b          	slliw	a5,a4,0x2
    80004556:	9fb9                	addw	a5,a5,a4
    80004558:	0017979b          	slliw	a5,a5,0x1
    8000455c:	54d8                	lw	a4,44(s1)
    8000455e:	9fb9                	addw	a5,a5,a4
    80004560:	00f95963          	bge	s2,a5,80004572 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004564:	85a6                	mv	a1,s1
    80004566:	8526                	mv	a0,s1
    80004568:	ffffe097          	auipc	ra,0xffffe
    8000456c:	cfe080e7          	jalr	-770(ra) # 80002266 <sleep>
    80004570:	bfd9                	j	80004546 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004572:	0001f517          	auipc	a0,0x1f
    80004576:	51650513          	addi	a0,a0,1302 # 80023a88 <log>
    8000457a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	708080e7          	jalr	1800(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6902                	ld	s2,0(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret

0000000080004590 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004590:	7139                	addi	sp,sp,-64
    80004592:	fc06                	sd	ra,56(sp)
    80004594:	f822                	sd	s0,48(sp)
    80004596:	f426                	sd	s1,40(sp)
    80004598:	f04a                	sd	s2,32(sp)
    8000459a:	ec4e                	sd	s3,24(sp)
    8000459c:	e852                	sd	s4,16(sp)
    8000459e:	e456                	sd	s5,8(sp)
    800045a0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045a2:	0001f497          	auipc	s1,0x1f
    800045a6:	4e648493          	addi	s1,s1,1254 # 80023a88 <log>
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	624080e7          	jalr	1572(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800045b4:	509c                	lw	a5,32(s1)
    800045b6:	37fd                	addiw	a5,a5,-1
    800045b8:	0007891b          	sext.w	s2,a5
    800045bc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045be:	50dc                	lw	a5,36(s1)
    800045c0:	e7b9                	bnez	a5,8000460e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045c2:	04091e63          	bnez	s2,8000461e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045c6:	0001f497          	auipc	s1,0x1f
    800045ca:	4c248493          	addi	s1,s1,1218 # 80023a88 <log>
    800045ce:	4785                	li	a5,1
    800045d0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6b0080e7          	jalr	1712(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045dc:	54dc                	lw	a5,44(s1)
    800045de:	06f04763          	bgtz	a5,8000464c <end_op+0xbc>
    acquire(&log.lock);
    800045e2:	0001f497          	auipc	s1,0x1f
    800045e6:	4a648493          	addi	s1,s1,1190 # 80023a88 <log>
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	5e4080e7          	jalr	1508(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800045f4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffe097          	auipc	ra,0xffffe
    800045fe:	f50080e7          	jalr	-176(ra) # 8000254a <wakeup>
    release(&log.lock);
    80004602:	8526                	mv	a0,s1
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	680080e7          	jalr	1664(ra) # 80000c84 <release>
}
    8000460c:	a03d                	j	8000463a <end_op+0xaa>
    panic("log.committing");
    8000460e:	00004517          	auipc	a0,0x4
    80004612:	25a50513          	addi	a0,a0,602 # 80008868 <syscallargs+0x198>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	f24080e7          	jalr	-220(ra) # 8000053a <panic>
    wakeup(&log);
    8000461e:	0001f497          	auipc	s1,0x1f
    80004622:	46a48493          	addi	s1,s1,1130 # 80023a88 <log>
    80004626:	8526                	mv	a0,s1
    80004628:	ffffe097          	auipc	ra,0xffffe
    8000462c:	f22080e7          	jalr	-222(ra) # 8000254a <wakeup>
  release(&log.lock);
    80004630:	8526                	mv	a0,s1
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	652080e7          	jalr	1618(ra) # 80000c84 <release>
}
    8000463a:	70e2                	ld	ra,56(sp)
    8000463c:	7442                	ld	s0,48(sp)
    8000463e:	74a2                	ld	s1,40(sp)
    80004640:	7902                	ld	s2,32(sp)
    80004642:	69e2                	ld	s3,24(sp)
    80004644:	6a42                	ld	s4,16(sp)
    80004646:	6aa2                	ld	s5,8(sp)
    80004648:	6121                	addi	sp,sp,64
    8000464a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000464c:	0001fa97          	auipc	s5,0x1f
    80004650:	46ca8a93          	addi	s5,s5,1132 # 80023ab8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004654:	0001fa17          	auipc	s4,0x1f
    80004658:	434a0a13          	addi	s4,s4,1076 # 80023a88 <log>
    8000465c:	018a2583          	lw	a1,24(s4)
    80004660:	012585bb          	addw	a1,a1,s2
    80004664:	2585                	addiw	a1,a1,1
    80004666:	028a2503          	lw	a0,40(s4)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	cca080e7          	jalr	-822(ra) # 80003334 <bread>
    80004672:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004674:	000aa583          	lw	a1,0(s5)
    80004678:	028a2503          	lw	a0,40(s4)
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	cb8080e7          	jalr	-840(ra) # 80003334 <bread>
    80004684:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004686:	40000613          	li	a2,1024
    8000468a:	05850593          	addi	a1,a0,88
    8000468e:	05848513          	addi	a0,s1,88
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	696080e7          	jalr	1686(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	d8a080e7          	jalr	-630(ra) # 80003426 <bwrite>
    brelse(from);
    800046a4:	854e                	mv	a0,s3
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	dbe080e7          	jalr	-578(ra) # 80003464 <brelse>
    brelse(to);
    800046ae:	8526                	mv	a0,s1
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	db4080e7          	jalr	-588(ra) # 80003464 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b8:	2905                	addiw	s2,s2,1
    800046ba:	0a91                	addi	s5,s5,4
    800046bc:	02ca2783          	lw	a5,44(s4)
    800046c0:	f8f94ee3          	blt	s2,a5,8000465c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	c68080e7          	jalr	-920(ra) # 8000432c <write_head>
    install_trans(0); // Now install writes to home locations
    800046cc:	4501                	li	a0,0
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	cda080e7          	jalr	-806(ra) # 800043a8 <install_trans>
    log.lh.n = 0;
    800046d6:	0001f797          	auipc	a5,0x1f
    800046da:	3c07af23          	sw	zero,990(a5) # 80023ab4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	c4e080e7          	jalr	-946(ra) # 8000432c <write_head>
    800046e6:	bdf5                	j	800045e2 <end_op+0x52>

00000000800046e8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046e8:	1101                	addi	sp,sp,-32
    800046ea:	ec06                	sd	ra,24(sp)
    800046ec:	e822                	sd	s0,16(sp)
    800046ee:	e426                	sd	s1,8(sp)
    800046f0:	e04a                	sd	s2,0(sp)
    800046f2:	1000                	addi	s0,sp,32
    800046f4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046f6:	0001f917          	auipc	s2,0x1f
    800046fa:	39290913          	addi	s2,s2,914 # 80023a88 <log>
    800046fe:	854a                	mv	a0,s2
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	4d0080e7          	jalr	1232(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004708:	02c92603          	lw	a2,44(s2)
    8000470c:	47f5                	li	a5,29
    8000470e:	06c7c563          	blt	a5,a2,80004778 <log_write+0x90>
    80004712:	0001f797          	auipc	a5,0x1f
    80004716:	3927a783          	lw	a5,914(a5) # 80023aa4 <log+0x1c>
    8000471a:	37fd                	addiw	a5,a5,-1
    8000471c:	04f65e63          	bge	a2,a5,80004778 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004720:	0001f797          	auipc	a5,0x1f
    80004724:	3887a783          	lw	a5,904(a5) # 80023aa8 <log+0x20>
    80004728:	06f05063          	blez	a5,80004788 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000472c:	4781                	li	a5,0
    8000472e:	06c05563          	blez	a2,80004798 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004732:	44cc                	lw	a1,12(s1)
    80004734:	0001f717          	auipc	a4,0x1f
    80004738:	38470713          	addi	a4,a4,900 # 80023ab8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000473c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000473e:	4314                	lw	a3,0(a4)
    80004740:	04b68c63          	beq	a3,a1,80004798 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004744:	2785                	addiw	a5,a5,1
    80004746:	0711                	addi	a4,a4,4
    80004748:	fef61be3          	bne	a2,a5,8000473e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000474c:	0621                	addi	a2,a2,8
    8000474e:	060a                	slli	a2,a2,0x2
    80004750:	0001f797          	auipc	a5,0x1f
    80004754:	33878793          	addi	a5,a5,824 # 80023a88 <log>
    80004758:	97b2                	add	a5,a5,a2
    8000475a:	44d8                	lw	a4,12(s1)
    8000475c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000475e:	8526                	mv	a0,s1
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	da2080e7          	jalr	-606(ra) # 80003502 <bpin>
    log.lh.n++;
    80004768:	0001f717          	auipc	a4,0x1f
    8000476c:	32070713          	addi	a4,a4,800 # 80023a88 <log>
    80004770:	575c                	lw	a5,44(a4)
    80004772:	2785                	addiw	a5,a5,1
    80004774:	d75c                	sw	a5,44(a4)
    80004776:	a82d                	j	800047b0 <log_write+0xc8>
    panic("too big a transaction");
    80004778:	00004517          	auipc	a0,0x4
    8000477c:	10050513          	addi	a0,a0,256 # 80008878 <syscallargs+0x1a8>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	dba080e7          	jalr	-582(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004788:	00004517          	auipc	a0,0x4
    8000478c:	10850513          	addi	a0,a0,264 # 80008890 <syscallargs+0x1c0>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	daa080e7          	jalr	-598(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004798:	00878693          	addi	a3,a5,8
    8000479c:	068a                	slli	a3,a3,0x2
    8000479e:	0001f717          	auipc	a4,0x1f
    800047a2:	2ea70713          	addi	a4,a4,746 # 80023a88 <log>
    800047a6:	9736                	add	a4,a4,a3
    800047a8:	44d4                	lw	a3,12(s1)
    800047aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047ac:	faf609e3          	beq	a2,a5,8000475e <log_write+0x76>
  }
  release(&log.lock);
    800047b0:	0001f517          	auipc	a0,0x1f
    800047b4:	2d850513          	addi	a0,a0,728 # 80023a88 <log>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4cc080e7          	jalr	1228(ra) # 80000c84 <release>
}
    800047c0:	60e2                	ld	ra,24(sp)
    800047c2:	6442                	ld	s0,16(sp)
    800047c4:	64a2                	ld	s1,8(sp)
    800047c6:	6902                	ld	s2,0(sp)
    800047c8:	6105                	addi	sp,sp,32
    800047ca:	8082                	ret

00000000800047cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	e04a                	sd	s2,0(sp)
    800047d6:	1000                	addi	s0,sp,32
    800047d8:	84aa                	mv	s1,a0
    800047da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047dc:	00004597          	auipc	a1,0x4
    800047e0:	0d458593          	addi	a1,a1,212 # 800088b0 <syscallargs+0x1e0>
    800047e4:	0521                	addi	a0,a0,8
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	35a080e7          	jalr	858(ra) # 80000b40 <initlock>
  lk->name = name;
    800047ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f6:	0204a423          	sw	zero,40(s1)
}
    800047fa:	60e2                	ld	ra,24(sp)
    800047fc:	6442                	ld	s0,16(sp)
    800047fe:	64a2                	ld	s1,8(sp)
    80004800:	6902                	ld	s2,0(sp)
    80004802:	6105                	addi	sp,sp,32
    80004804:	8082                	ret

0000000080004806 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004806:	1101                	addi	sp,sp,-32
    80004808:	ec06                	sd	ra,24(sp)
    8000480a:	e822                	sd	s0,16(sp)
    8000480c:	e426                	sd	s1,8(sp)
    8000480e:	e04a                	sd	s2,0(sp)
    80004810:	1000                	addi	s0,sp,32
    80004812:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004814:	00850913          	addi	s2,a0,8
    80004818:	854a                	mv	a0,s2
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	3b6080e7          	jalr	950(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    80004822:	409c                	lw	a5,0(s1)
    80004824:	cb89                	beqz	a5,80004836 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004826:	85ca                	mv	a1,s2
    80004828:	8526                	mv	a0,s1
    8000482a:	ffffe097          	auipc	ra,0xffffe
    8000482e:	a3c080e7          	jalr	-1476(ra) # 80002266 <sleep>
  while (lk->locked) {
    80004832:	409c                	lw	a5,0(s1)
    80004834:	fbed                	bnez	a5,80004826 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004836:	4785                	li	a5,1
    80004838:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000483a:	ffffd097          	auipc	ra,0xffffd
    8000483e:	15c080e7          	jalr	348(ra) # 80001996 <myproc>
    80004842:	591c                	lw	a5,48(a0)
    80004844:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004846:	854a                	mv	a0,s2
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	43c080e7          	jalr	1084(ra) # 80000c84 <release>
}
    80004850:	60e2                	ld	ra,24(sp)
    80004852:	6442                	ld	s0,16(sp)
    80004854:	64a2                	ld	s1,8(sp)
    80004856:	6902                	ld	s2,0(sp)
    80004858:	6105                	addi	sp,sp,32
    8000485a:	8082                	ret

000000008000485c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000485c:	1101                	addi	sp,sp,-32
    8000485e:	ec06                	sd	ra,24(sp)
    80004860:	e822                	sd	s0,16(sp)
    80004862:	e426                	sd	s1,8(sp)
    80004864:	e04a                	sd	s2,0(sp)
    80004866:	1000                	addi	s0,sp,32
    80004868:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000486a:	00850913          	addi	s2,a0,8
    8000486e:	854a                	mv	a0,s2
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	360080e7          	jalr	864(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004878:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000487c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004880:	8526                	mv	a0,s1
    80004882:	ffffe097          	auipc	ra,0xffffe
    80004886:	cc8080e7          	jalr	-824(ra) # 8000254a <wakeup>
  release(&lk->lk);
    8000488a:	854a                	mv	a0,s2
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	3f8080e7          	jalr	1016(ra) # 80000c84 <release>
}
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	6902                	ld	s2,0(sp)
    8000489c:	6105                	addi	sp,sp,32
    8000489e:	8082                	ret

00000000800048a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048a0:	7179                	addi	sp,sp,-48
    800048a2:	f406                	sd	ra,40(sp)
    800048a4:	f022                	sd	s0,32(sp)
    800048a6:	ec26                	sd	s1,24(sp)
    800048a8:	e84a                	sd	s2,16(sp)
    800048aa:	e44e                	sd	s3,8(sp)
    800048ac:	1800                	addi	s0,sp,48
    800048ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048b0:	00850913          	addi	s2,a0,8
    800048b4:	854a                	mv	a0,s2
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	31a080e7          	jalr	794(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048be:	409c                	lw	a5,0(s1)
    800048c0:	ef99                	bnez	a5,800048de <holdingsleep+0x3e>
    800048c2:	4481                	li	s1,0
  release(&lk->lk);
    800048c4:	854a                	mv	a0,s2
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	3be080e7          	jalr	958(ra) # 80000c84 <release>
  return r;
}
    800048ce:	8526                	mv	a0,s1
    800048d0:	70a2                	ld	ra,40(sp)
    800048d2:	7402                	ld	s0,32(sp)
    800048d4:	64e2                	ld	s1,24(sp)
    800048d6:	6942                	ld	s2,16(sp)
    800048d8:	69a2                	ld	s3,8(sp)
    800048da:	6145                	addi	sp,sp,48
    800048dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048de:	0284a983          	lw	s3,40(s1)
    800048e2:	ffffd097          	auipc	ra,0xffffd
    800048e6:	0b4080e7          	jalr	180(ra) # 80001996 <myproc>
    800048ea:	5904                	lw	s1,48(a0)
    800048ec:	413484b3          	sub	s1,s1,s3
    800048f0:	0014b493          	seqz	s1,s1
    800048f4:	bfc1                	j	800048c4 <holdingsleep+0x24>

00000000800048f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048f6:	1141                	addi	sp,sp,-16
    800048f8:	e406                	sd	ra,8(sp)
    800048fa:	e022                	sd	s0,0(sp)
    800048fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048fe:	00004597          	auipc	a1,0x4
    80004902:	fc258593          	addi	a1,a1,-62 # 800088c0 <syscallargs+0x1f0>
    80004906:	0001f517          	auipc	a0,0x1f
    8000490a:	2ca50513          	addi	a0,a0,714 # 80023bd0 <ftable>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	232080e7          	jalr	562(ra) # 80000b40 <initlock>
}
    80004916:	60a2                	ld	ra,8(sp)
    80004918:	6402                	ld	s0,0(sp)
    8000491a:	0141                	addi	sp,sp,16
    8000491c:	8082                	ret

000000008000491e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000491e:	1101                	addi	sp,sp,-32
    80004920:	ec06                	sd	ra,24(sp)
    80004922:	e822                	sd	s0,16(sp)
    80004924:	e426                	sd	s1,8(sp)
    80004926:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004928:	0001f517          	auipc	a0,0x1f
    8000492c:	2a850513          	addi	a0,a0,680 # 80023bd0 <ftable>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	2a0080e7          	jalr	672(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004938:	0001f497          	auipc	s1,0x1f
    8000493c:	2b048493          	addi	s1,s1,688 # 80023be8 <ftable+0x18>
    80004940:	00020717          	auipc	a4,0x20
    80004944:	24870713          	addi	a4,a4,584 # 80024b88 <ftable+0xfb8>
    if(f->ref == 0){
    80004948:	40dc                	lw	a5,4(s1)
    8000494a:	cf99                	beqz	a5,80004968 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000494c:	02848493          	addi	s1,s1,40
    80004950:	fee49ce3          	bne	s1,a4,80004948 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004954:	0001f517          	auipc	a0,0x1f
    80004958:	27c50513          	addi	a0,a0,636 # 80023bd0 <ftable>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	328080e7          	jalr	808(ra) # 80000c84 <release>
  return 0;
    80004964:	4481                	li	s1,0
    80004966:	a819                	j	8000497c <filealloc+0x5e>
      f->ref = 1;
    80004968:	4785                	li	a5,1
    8000496a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000496c:	0001f517          	auipc	a0,0x1f
    80004970:	26450513          	addi	a0,a0,612 # 80023bd0 <ftable>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	310080e7          	jalr	784(ra) # 80000c84 <release>
}
    8000497c:	8526                	mv	a0,s1
    8000497e:	60e2                	ld	ra,24(sp)
    80004980:	6442                	ld	s0,16(sp)
    80004982:	64a2                	ld	s1,8(sp)
    80004984:	6105                	addi	sp,sp,32
    80004986:	8082                	ret

0000000080004988 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004988:	1101                	addi	sp,sp,-32
    8000498a:	ec06                	sd	ra,24(sp)
    8000498c:	e822                	sd	s0,16(sp)
    8000498e:	e426                	sd	s1,8(sp)
    80004990:	1000                	addi	s0,sp,32
    80004992:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004994:	0001f517          	auipc	a0,0x1f
    80004998:	23c50513          	addi	a0,a0,572 # 80023bd0 <ftable>
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	234080e7          	jalr	564(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800049a4:	40dc                	lw	a5,4(s1)
    800049a6:	02f05263          	blez	a5,800049ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049aa:	2785                	addiw	a5,a5,1
    800049ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049ae:	0001f517          	auipc	a0,0x1f
    800049b2:	22250513          	addi	a0,a0,546 # 80023bd0 <ftable>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	2ce080e7          	jalr	718(ra) # 80000c84 <release>
  return f;
}
    800049be:	8526                	mv	a0,s1
    800049c0:	60e2                	ld	ra,24(sp)
    800049c2:	6442                	ld	s0,16(sp)
    800049c4:	64a2                	ld	s1,8(sp)
    800049c6:	6105                	addi	sp,sp,32
    800049c8:	8082                	ret
    panic("filedup");
    800049ca:	00004517          	auipc	a0,0x4
    800049ce:	efe50513          	addi	a0,a0,-258 # 800088c8 <syscallargs+0x1f8>
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	b68080e7          	jalr	-1176(ra) # 8000053a <panic>

00000000800049da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049da:	7139                	addi	sp,sp,-64
    800049dc:	fc06                	sd	ra,56(sp)
    800049de:	f822                	sd	s0,48(sp)
    800049e0:	f426                	sd	s1,40(sp)
    800049e2:	f04a                	sd	s2,32(sp)
    800049e4:	ec4e                	sd	s3,24(sp)
    800049e6:	e852                	sd	s4,16(sp)
    800049e8:	e456                	sd	s5,8(sp)
    800049ea:	0080                	addi	s0,sp,64
    800049ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049ee:	0001f517          	auipc	a0,0x1f
    800049f2:	1e250513          	addi	a0,a0,482 # 80023bd0 <ftable>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	1da080e7          	jalr	474(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800049fe:	40dc                	lw	a5,4(s1)
    80004a00:	06f05163          	blez	a5,80004a62 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a04:	37fd                	addiw	a5,a5,-1
    80004a06:	0007871b          	sext.w	a4,a5
    80004a0a:	c0dc                	sw	a5,4(s1)
    80004a0c:	06e04363          	bgtz	a4,80004a72 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a10:	0004a903          	lw	s2,0(s1)
    80004a14:	0094ca83          	lbu	s5,9(s1)
    80004a18:	0104ba03          	ld	s4,16(s1)
    80004a1c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a20:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a24:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a28:	0001f517          	auipc	a0,0x1f
    80004a2c:	1a850513          	addi	a0,a0,424 # 80023bd0 <ftable>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	254080e7          	jalr	596(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004a38:	4785                	li	a5,1
    80004a3a:	04f90d63          	beq	s2,a5,80004a94 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a3e:	3979                	addiw	s2,s2,-2
    80004a40:	4785                	li	a5,1
    80004a42:	0527e063          	bltu	a5,s2,80004a82 <fileclose+0xa8>
    begin_op();
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	acc080e7          	jalr	-1332(ra) # 80004512 <begin_op>
    iput(ff.ip);
    80004a4e:	854e                	mv	a0,s3
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	2a0080e7          	jalr	672(ra) # 80003cf0 <iput>
    end_op();
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	b38080e7          	jalr	-1224(ra) # 80004590 <end_op>
    80004a60:	a00d                	j	80004a82 <fileclose+0xa8>
    panic("fileclose");
    80004a62:	00004517          	auipc	a0,0x4
    80004a66:	e6e50513          	addi	a0,a0,-402 # 800088d0 <syscallargs+0x200>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	ad0080e7          	jalr	-1328(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004a72:	0001f517          	auipc	a0,0x1f
    80004a76:	15e50513          	addi	a0,a0,350 # 80023bd0 <ftable>
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	20a080e7          	jalr	522(ra) # 80000c84 <release>
  }
}
    80004a82:	70e2                	ld	ra,56(sp)
    80004a84:	7442                	ld	s0,48(sp)
    80004a86:	74a2                	ld	s1,40(sp)
    80004a88:	7902                	ld	s2,32(sp)
    80004a8a:	69e2                	ld	s3,24(sp)
    80004a8c:	6a42                	ld	s4,16(sp)
    80004a8e:	6aa2                	ld	s5,8(sp)
    80004a90:	6121                	addi	sp,sp,64
    80004a92:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a94:	85d6                	mv	a1,s5
    80004a96:	8552                	mv	a0,s4
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	34c080e7          	jalr	844(ra) # 80004de4 <pipeclose>
    80004aa0:	b7cd                	j	80004a82 <fileclose+0xa8>

0000000080004aa2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004aa2:	715d                	addi	sp,sp,-80
    80004aa4:	e486                	sd	ra,72(sp)
    80004aa6:	e0a2                	sd	s0,64(sp)
    80004aa8:	fc26                	sd	s1,56(sp)
    80004aaa:	f84a                	sd	s2,48(sp)
    80004aac:	f44e                	sd	s3,40(sp)
    80004aae:	0880                	addi	s0,sp,80
    80004ab0:	84aa                	mv	s1,a0
    80004ab2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	ee2080e7          	jalr	-286(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004abc:	409c                	lw	a5,0(s1)
    80004abe:	37f9                	addiw	a5,a5,-2
    80004ac0:	4705                	li	a4,1
    80004ac2:	04f76763          	bltu	a4,a5,80004b10 <filestat+0x6e>
    80004ac6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ac8:	6c88                	ld	a0,24(s1)
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	06c080e7          	jalr	108(ra) # 80003b36 <ilock>
    stati(f->ip, &st);
    80004ad2:	fb840593          	addi	a1,s0,-72
    80004ad6:	6c88                	ld	a0,24(s1)
    80004ad8:	fffff097          	auipc	ra,0xfffff
    80004adc:	2e8080e7          	jalr	744(ra) # 80003dc0 <stati>
    iunlock(f->ip);
    80004ae0:	6c88                	ld	a0,24(s1)
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	116080e7          	jalr	278(ra) # 80003bf8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aea:	46e1                	li	a3,24
    80004aec:	fb840613          	addi	a2,s0,-72
    80004af0:	85ce                	mv	a1,s3
    80004af2:	05093503          	ld	a0,80(s2)
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	b64080e7          	jalr	-1180(ra) # 8000165a <copyout>
    80004afe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b02:	60a6                	ld	ra,72(sp)
    80004b04:	6406                	ld	s0,64(sp)
    80004b06:	74e2                	ld	s1,56(sp)
    80004b08:	7942                	ld	s2,48(sp)
    80004b0a:	79a2                	ld	s3,40(sp)
    80004b0c:	6161                	addi	sp,sp,80
    80004b0e:	8082                	ret
  return -1;
    80004b10:	557d                	li	a0,-1
    80004b12:	bfc5                	j	80004b02 <filestat+0x60>

0000000080004b14 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b14:	7179                	addi	sp,sp,-48
    80004b16:	f406                	sd	ra,40(sp)
    80004b18:	f022                	sd	s0,32(sp)
    80004b1a:	ec26                	sd	s1,24(sp)
    80004b1c:	e84a                	sd	s2,16(sp)
    80004b1e:	e44e                	sd	s3,8(sp)
    80004b20:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b22:	00854783          	lbu	a5,8(a0)
    80004b26:	c3d5                	beqz	a5,80004bca <fileread+0xb6>
    80004b28:	84aa                	mv	s1,a0
    80004b2a:	89ae                	mv	s3,a1
    80004b2c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b2e:	411c                	lw	a5,0(a0)
    80004b30:	4705                	li	a4,1
    80004b32:	04e78963          	beq	a5,a4,80004b84 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b36:	470d                	li	a4,3
    80004b38:	04e78d63          	beq	a5,a4,80004b92 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b3c:	4709                	li	a4,2
    80004b3e:	06e79e63          	bne	a5,a4,80004bba <fileread+0xa6>
    ilock(f->ip);
    80004b42:	6d08                	ld	a0,24(a0)
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	ff2080e7          	jalr	-14(ra) # 80003b36 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b4c:	874a                	mv	a4,s2
    80004b4e:	5094                	lw	a3,32(s1)
    80004b50:	864e                	mv	a2,s3
    80004b52:	4585                	li	a1,1
    80004b54:	6c88                	ld	a0,24(s1)
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	294080e7          	jalr	660(ra) # 80003dea <readi>
    80004b5e:	892a                	mv	s2,a0
    80004b60:	00a05563          	blez	a0,80004b6a <fileread+0x56>
      f->off += r;
    80004b64:	509c                	lw	a5,32(s1)
    80004b66:	9fa9                	addw	a5,a5,a0
    80004b68:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b6a:	6c88                	ld	a0,24(s1)
    80004b6c:	fffff097          	auipc	ra,0xfffff
    80004b70:	08c080e7          	jalr	140(ra) # 80003bf8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b74:	854a                	mv	a0,s2
    80004b76:	70a2                	ld	ra,40(sp)
    80004b78:	7402                	ld	s0,32(sp)
    80004b7a:	64e2                	ld	s1,24(sp)
    80004b7c:	6942                	ld	s2,16(sp)
    80004b7e:	69a2                	ld	s3,8(sp)
    80004b80:	6145                	addi	sp,sp,48
    80004b82:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b84:	6908                	ld	a0,16(a0)
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	3c0080e7          	jalr	960(ra) # 80004f46 <piperead>
    80004b8e:	892a                	mv	s2,a0
    80004b90:	b7d5                	j	80004b74 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b92:	02451783          	lh	a5,36(a0)
    80004b96:	03079693          	slli	a3,a5,0x30
    80004b9a:	92c1                	srli	a3,a3,0x30
    80004b9c:	4725                	li	a4,9
    80004b9e:	02d76863          	bltu	a4,a3,80004bce <fileread+0xba>
    80004ba2:	0792                	slli	a5,a5,0x4
    80004ba4:	0001f717          	auipc	a4,0x1f
    80004ba8:	f8c70713          	addi	a4,a4,-116 # 80023b30 <devsw>
    80004bac:	97ba                	add	a5,a5,a4
    80004bae:	639c                	ld	a5,0(a5)
    80004bb0:	c38d                	beqz	a5,80004bd2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bb2:	4505                	li	a0,1
    80004bb4:	9782                	jalr	a5
    80004bb6:	892a                	mv	s2,a0
    80004bb8:	bf75                	j	80004b74 <fileread+0x60>
    panic("fileread");
    80004bba:	00004517          	auipc	a0,0x4
    80004bbe:	d2650513          	addi	a0,a0,-730 # 800088e0 <syscallargs+0x210>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	978080e7          	jalr	-1672(ra) # 8000053a <panic>
    return -1;
    80004bca:	597d                	li	s2,-1
    80004bcc:	b765                	j	80004b74 <fileread+0x60>
      return -1;
    80004bce:	597d                	li	s2,-1
    80004bd0:	b755                	j	80004b74 <fileread+0x60>
    80004bd2:	597d                	li	s2,-1
    80004bd4:	b745                	j	80004b74 <fileread+0x60>

0000000080004bd6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bd6:	715d                	addi	sp,sp,-80
    80004bd8:	e486                	sd	ra,72(sp)
    80004bda:	e0a2                	sd	s0,64(sp)
    80004bdc:	fc26                	sd	s1,56(sp)
    80004bde:	f84a                	sd	s2,48(sp)
    80004be0:	f44e                	sd	s3,40(sp)
    80004be2:	f052                	sd	s4,32(sp)
    80004be4:	ec56                	sd	s5,24(sp)
    80004be6:	e85a                	sd	s6,16(sp)
    80004be8:	e45e                	sd	s7,8(sp)
    80004bea:	e062                	sd	s8,0(sp)
    80004bec:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bee:	00954783          	lbu	a5,9(a0)
    80004bf2:	10078663          	beqz	a5,80004cfe <filewrite+0x128>
    80004bf6:	892a                	mv	s2,a0
    80004bf8:	8b2e                	mv	s6,a1
    80004bfa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bfc:	411c                	lw	a5,0(a0)
    80004bfe:	4705                	li	a4,1
    80004c00:	02e78263          	beq	a5,a4,80004c24 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c04:	470d                	li	a4,3
    80004c06:	02e78663          	beq	a5,a4,80004c32 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c0a:	4709                	li	a4,2
    80004c0c:	0ee79163          	bne	a5,a4,80004cee <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c10:	0ac05d63          	blez	a2,80004cca <filewrite+0xf4>
    int i = 0;
    80004c14:	4981                	li	s3,0
    80004c16:	6b85                	lui	s7,0x1
    80004c18:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c1c:	6c05                	lui	s8,0x1
    80004c1e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c22:	a861                	j	80004cba <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c24:	6908                	ld	a0,16(a0)
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	22e080e7          	jalr	558(ra) # 80004e54 <pipewrite>
    80004c2e:	8a2a                	mv	s4,a0
    80004c30:	a045                	j	80004cd0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c32:	02451783          	lh	a5,36(a0)
    80004c36:	03079693          	slli	a3,a5,0x30
    80004c3a:	92c1                	srli	a3,a3,0x30
    80004c3c:	4725                	li	a4,9
    80004c3e:	0cd76263          	bltu	a4,a3,80004d02 <filewrite+0x12c>
    80004c42:	0792                	slli	a5,a5,0x4
    80004c44:	0001f717          	auipc	a4,0x1f
    80004c48:	eec70713          	addi	a4,a4,-276 # 80023b30 <devsw>
    80004c4c:	97ba                	add	a5,a5,a4
    80004c4e:	679c                	ld	a5,8(a5)
    80004c50:	cbdd                	beqz	a5,80004d06 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c52:	4505                	li	a0,1
    80004c54:	9782                	jalr	a5
    80004c56:	8a2a                	mv	s4,a0
    80004c58:	a8a5                	j	80004cd0 <filewrite+0xfa>
    80004c5a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	8b4080e7          	jalr	-1868(ra) # 80004512 <begin_op>
      ilock(f->ip);
    80004c66:	01893503          	ld	a0,24(s2)
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	ecc080e7          	jalr	-308(ra) # 80003b36 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c72:	8756                	mv	a4,s5
    80004c74:	02092683          	lw	a3,32(s2)
    80004c78:	01698633          	add	a2,s3,s6
    80004c7c:	4585                	li	a1,1
    80004c7e:	01893503          	ld	a0,24(s2)
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	260080e7          	jalr	608(ra) # 80003ee2 <writei>
    80004c8a:	84aa                	mv	s1,a0
    80004c8c:	00a05763          	blez	a0,80004c9a <filewrite+0xc4>
        f->off += r;
    80004c90:	02092783          	lw	a5,32(s2)
    80004c94:	9fa9                	addw	a5,a5,a0
    80004c96:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c9a:	01893503          	ld	a0,24(s2)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	f5a080e7          	jalr	-166(ra) # 80003bf8 <iunlock>
      end_op();
    80004ca6:	00000097          	auipc	ra,0x0
    80004caa:	8ea080e7          	jalr	-1814(ra) # 80004590 <end_op>

      if(r != n1){
    80004cae:	009a9f63          	bne	s5,s1,80004ccc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cb2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cb6:	0149db63          	bge	s3,s4,80004ccc <filewrite+0xf6>
      int n1 = n - i;
    80004cba:	413a04bb          	subw	s1,s4,s3
    80004cbe:	0004879b          	sext.w	a5,s1
    80004cc2:	f8fbdce3          	bge	s7,a5,80004c5a <filewrite+0x84>
    80004cc6:	84e2                	mv	s1,s8
    80004cc8:	bf49                	j	80004c5a <filewrite+0x84>
    int i = 0;
    80004cca:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ccc:	013a1f63          	bne	s4,s3,80004cea <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cd0:	8552                	mv	a0,s4
    80004cd2:	60a6                	ld	ra,72(sp)
    80004cd4:	6406                	ld	s0,64(sp)
    80004cd6:	74e2                	ld	s1,56(sp)
    80004cd8:	7942                	ld	s2,48(sp)
    80004cda:	79a2                	ld	s3,40(sp)
    80004cdc:	7a02                	ld	s4,32(sp)
    80004cde:	6ae2                	ld	s5,24(sp)
    80004ce0:	6b42                	ld	s6,16(sp)
    80004ce2:	6ba2                	ld	s7,8(sp)
    80004ce4:	6c02                	ld	s8,0(sp)
    80004ce6:	6161                	addi	sp,sp,80
    80004ce8:	8082                	ret
    ret = (i == n ? n : -1);
    80004cea:	5a7d                	li	s4,-1
    80004cec:	b7d5                	j	80004cd0 <filewrite+0xfa>
    panic("filewrite");
    80004cee:	00004517          	auipc	a0,0x4
    80004cf2:	c0250513          	addi	a0,a0,-1022 # 800088f0 <syscallargs+0x220>
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	844080e7          	jalr	-1980(ra) # 8000053a <panic>
    return -1;
    80004cfe:	5a7d                	li	s4,-1
    80004d00:	bfc1                	j	80004cd0 <filewrite+0xfa>
      return -1;
    80004d02:	5a7d                	li	s4,-1
    80004d04:	b7f1                	j	80004cd0 <filewrite+0xfa>
    80004d06:	5a7d                	li	s4,-1
    80004d08:	b7e1                	j	80004cd0 <filewrite+0xfa>

0000000080004d0a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d0a:	7179                	addi	sp,sp,-48
    80004d0c:	f406                	sd	ra,40(sp)
    80004d0e:	f022                	sd	s0,32(sp)
    80004d10:	ec26                	sd	s1,24(sp)
    80004d12:	e84a                	sd	s2,16(sp)
    80004d14:	e44e                	sd	s3,8(sp)
    80004d16:	e052                	sd	s4,0(sp)
    80004d18:	1800                	addi	s0,sp,48
    80004d1a:	84aa                	mv	s1,a0
    80004d1c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d1e:	0005b023          	sd	zero,0(a1)
    80004d22:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d26:	00000097          	auipc	ra,0x0
    80004d2a:	bf8080e7          	jalr	-1032(ra) # 8000491e <filealloc>
    80004d2e:	e088                	sd	a0,0(s1)
    80004d30:	c551                	beqz	a0,80004dbc <pipealloc+0xb2>
    80004d32:	00000097          	auipc	ra,0x0
    80004d36:	bec080e7          	jalr	-1044(ra) # 8000491e <filealloc>
    80004d3a:	00aa3023          	sd	a0,0(s4)
    80004d3e:	c92d                	beqz	a0,80004db0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	da0080e7          	jalr	-608(ra) # 80000ae0 <kalloc>
    80004d48:	892a                	mv	s2,a0
    80004d4a:	c125                	beqz	a0,80004daa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d4c:	4985                	li	s3,1
    80004d4e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d52:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d56:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d5a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d5e:	00003597          	auipc	a1,0x3
    80004d62:	72258593          	addi	a1,a1,1826 # 80008480 <states.0+0x1b8>
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	dda080e7          	jalr	-550(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004d6e:	609c                	ld	a5,0(s1)
    80004d70:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d74:	609c                	ld	a5,0(s1)
    80004d76:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d7a:	609c                	ld	a5,0(s1)
    80004d7c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d80:	609c                	ld	a5,0(s1)
    80004d82:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d86:	000a3783          	ld	a5,0(s4)
    80004d8a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d8e:	000a3783          	ld	a5,0(s4)
    80004d92:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d96:	000a3783          	ld	a5,0(s4)
    80004d9a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d9e:	000a3783          	ld	a5,0(s4)
    80004da2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004da6:	4501                	li	a0,0
    80004da8:	a025                	j	80004dd0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004daa:	6088                	ld	a0,0(s1)
    80004dac:	e501                	bnez	a0,80004db4 <pipealloc+0xaa>
    80004dae:	a039                	j	80004dbc <pipealloc+0xb2>
    80004db0:	6088                	ld	a0,0(s1)
    80004db2:	c51d                	beqz	a0,80004de0 <pipealloc+0xd6>
    fileclose(*f0);
    80004db4:	00000097          	auipc	ra,0x0
    80004db8:	c26080e7          	jalr	-986(ra) # 800049da <fileclose>
  if(*f1)
    80004dbc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dc0:	557d                	li	a0,-1
  if(*f1)
    80004dc2:	c799                	beqz	a5,80004dd0 <pipealloc+0xc6>
    fileclose(*f1);
    80004dc4:	853e                	mv	a0,a5
    80004dc6:	00000097          	auipc	ra,0x0
    80004dca:	c14080e7          	jalr	-1004(ra) # 800049da <fileclose>
  return -1;
    80004dce:	557d                	li	a0,-1
}
    80004dd0:	70a2                	ld	ra,40(sp)
    80004dd2:	7402                	ld	s0,32(sp)
    80004dd4:	64e2                	ld	s1,24(sp)
    80004dd6:	6942                	ld	s2,16(sp)
    80004dd8:	69a2                	ld	s3,8(sp)
    80004dda:	6a02                	ld	s4,0(sp)
    80004ddc:	6145                	addi	sp,sp,48
    80004dde:	8082                	ret
  return -1;
    80004de0:	557d                	li	a0,-1
    80004de2:	b7fd                	j	80004dd0 <pipealloc+0xc6>

0000000080004de4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004de4:	1101                	addi	sp,sp,-32
    80004de6:	ec06                	sd	ra,24(sp)
    80004de8:	e822                	sd	s0,16(sp)
    80004dea:	e426                	sd	s1,8(sp)
    80004dec:	e04a                	sd	s2,0(sp)
    80004dee:	1000                	addi	s0,sp,32
    80004df0:	84aa                	mv	s1,a0
    80004df2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	ddc080e7          	jalr	-548(ra) # 80000bd0 <acquire>
  if(writable){
    80004dfc:	02090d63          	beqz	s2,80004e36 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e00:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e04:	21848513          	addi	a0,s1,536
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	742080e7          	jalr	1858(ra) # 8000254a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e10:	2204b783          	ld	a5,544(s1)
    80004e14:	eb95                	bnez	a5,80004e48 <pipeclose+0x64>
    release(&pi->lock);
    80004e16:	8526                	mv	a0,s1
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	e6c080e7          	jalr	-404(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004e20:	8526                	mv	a0,s1
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	bc0080e7          	jalr	-1088(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004e2a:	60e2                	ld	ra,24(sp)
    80004e2c:	6442                	ld	s0,16(sp)
    80004e2e:	64a2                	ld	s1,8(sp)
    80004e30:	6902                	ld	s2,0(sp)
    80004e32:	6105                	addi	sp,sp,32
    80004e34:	8082                	ret
    pi->readopen = 0;
    80004e36:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e3a:	21c48513          	addi	a0,s1,540
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	70c080e7          	jalr	1804(ra) # 8000254a <wakeup>
    80004e46:	b7e9                	j	80004e10 <pipeclose+0x2c>
    release(&pi->lock);
    80004e48:	8526                	mv	a0,s1
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	e3a080e7          	jalr	-454(ra) # 80000c84 <release>
}
    80004e52:	bfe1                	j	80004e2a <pipeclose+0x46>

0000000080004e54 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e54:	711d                	addi	sp,sp,-96
    80004e56:	ec86                	sd	ra,88(sp)
    80004e58:	e8a2                	sd	s0,80(sp)
    80004e5a:	e4a6                	sd	s1,72(sp)
    80004e5c:	e0ca                	sd	s2,64(sp)
    80004e5e:	fc4e                	sd	s3,56(sp)
    80004e60:	f852                	sd	s4,48(sp)
    80004e62:	f456                	sd	s5,40(sp)
    80004e64:	f05a                	sd	s6,32(sp)
    80004e66:	ec5e                	sd	s7,24(sp)
    80004e68:	e862                	sd	s8,16(sp)
    80004e6a:	1080                	addi	s0,sp,96
    80004e6c:	84aa                	mv	s1,a0
    80004e6e:	8aae                	mv	s5,a1
    80004e70:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	b24080e7          	jalr	-1244(ra) # 80001996 <myproc>
    80004e7a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	d52080e7          	jalr	-686(ra) # 80000bd0 <acquire>
  while(i < n){
    80004e86:	0b405363          	blez	s4,80004f2c <pipewrite+0xd8>
  int i = 0;
    80004e8a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e8c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e8e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e92:	21c48b93          	addi	s7,s1,540
    80004e96:	a089                	j	80004ed8 <pipewrite+0x84>
      release(&pi->lock);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	dea080e7          	jalr	-534(ra) # 80000c84 <release>
      return -1;
    80004ea2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ea4:	854a                	mv	a0,s2
    80004ea6:	60e6                	ld	ra,88(sp)
    80004ea8:	6446                	ld	s0,80(sp)
    80004eaa:	64a6                	ld	s1,72(sp)
    80004eac:	6906                	ld	s2,64(sp)
    80004eae:	79e2                	ld	s3,56(sp)
    80004eb0:	7a42                	ld	s4,48(sp)
    80004eb2:	7aa2                	ld	s5,40(sp)
    80004eb4:	7b02                	ld	s6,32(sp)
    80004eb6:	6be2                	ld	s7,24(sp)
    80004eb8:	6c42                	ld	s8,16(sp)
    80004eba:	6125                	addi	sp,sp,96
    80004ebc:	8082                	ret
      wakeup(&pi->nread);
    80004ebe:	8562                	mv	a0,s8
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	68a080e7          	jalr	1674(ra) # 8000254a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ec8:	85a6                	mv	a1,s1
    80004eca:	855e                	mv	a0,s7
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	39a080e7          	jalr	922(ra) # 80002266 <sleep>
  while(i < n){
    80004ed4:	05495d63          	bge	s2,s4,80004f2e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ed8:	2204a783          	lw	a5,544(s1)
    80004edc:	dfd5                	beqz	a5,80004e98 <pipewrite+0x44>
    80004ede:	0289a783          	lw	a5,40(s3)
    80004ee2:	fbdd                	bnez	a5,80004e98 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ee4:	2184a783          	lw	a5,536(s1)
    80004ee8:	21c4a703          	lw	a4,540(s1)
    80004eec:	2007879b          	addiw	a5,a5,512
    80004ef0:	fcf707e3          	beq	a4,a5,80004ebe <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef4:	4685                	li	a3,1
    80004ef6:	01590633          	add	a2,s2,s5
    80004efa:	faf40593          	addi	a1,s0,-81
    80004efe:	0509b503          	ld	a0,80(s3)
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	7e4080e7          	jalr	2020(ra) # 800016e6 <copyin>
    80004f0a:	03650263          	beq	a0,s6,80004f2e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f0e:	21c4a783          	lw	a5,540(s1)
    80004f12:	0017871b          	addiw	a4,a5,1
    80004f16:	20e4ae23          	sw	a4,540(s1)
    80004f1a:	1ff7f793          	andi	a5,a5,511
    80004f1e:	97a6                	add	a5,a5,s1
    80004f20:	faf44703          	lbu	a4,-81(s0)
    80004f24:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f28:	2905                	addiw	s2,s2,1
    80004f2a:	b76d                	j	80004ed4 <pipewrite+0x80>
  int i = 0;
    80004f2c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f2e:	21848513          	addi	a0,s1,536
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	618080e7          	jalr	1560(ra) # 8000254a <wakeup>
  release(&pi->lock);
    80004f3a:	8526                	mv	a0,s1
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	d48080e7          	jalr	-696(ra) # 80000c84 <release>
  return i;
    80004f44:	b785                	j	80004ea4 <pipewrite+0x50>

0000000080004f46 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f46:	715d                	addi	sp,sp,-80
    80004f48:	e486                	sd	ra,72(sp)
    80004f4a:	e0a2                	sd	s0,64(sp)
    80004f4c:	fc26                	sd	s1,56(sp)
    80004f4e:	f84a                	sd	s2,48(sp)
    80004f50:	f44e                	sd	s3,40(sp)
    80004f52:	f052                	sd	s4,32(sp)
    80004f54:	ec56                	sd	s5,24(sp)
    80004f56:	e85a                	sd	s6,16(sp)
    80004f58:	0880                	addi	s0,sp,80
    80004f5a:	84aa                	mv	s1,a0
    80004f5c:	892e                	mv	s2,a1
    80004f5e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	a36080e7          	jalr	-1482(ra) # 80001996 <myproc>
    80004f68:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f6a:	8526                	mv	a0,s1
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	c64080e7          	jalr	-924(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f74:	2184a703          	lw	a4,536(s1)
    80004f78:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f7c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f80:	02f71463          	bne	a4,a5,80004fa8 <piperead+0x62>
    80004f84:	2244a783          	lw	a5,548(s1)
    80004f88:	c385                	beqz	a5,80004fa8 <piperead+0x62>
    if(pr->killed){
    80004f8a:	028a2783          	lw	a5,40(s4)
    80004f8e:	ebc9                	bnez	a5,80005020 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f90:	85a6                	mv	a1,s1
    80004f92:	854e                	mv	a0,s3
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	2d2080e7          	jalr	722(ra) # 80002266 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f9c:	2184a703          	lw	a4,536(s1)
    80004fa0:	21c4a783          	lw	a5,540(s1)
    80004fa4:	fef700e3          	beq	a4,a5,80004f84 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fa8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004faa:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fac:	05505463          	blez	s5,80004ff4 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004fb0:	2184a783          	lw	a5,536(s1)
    80004fb4:	21c4a703          	lw	a4,540(s1)
    80004fb8:	02f70e63          	beq	a4,a5,80004ff4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fbc:	0017871b          	addiw	a4,a5,1
    80004fc0:	20e4ac23          	sw	a4,536(s1)
    80004fc4:	1ff7f793          	andi	a5,a5,511
    80004fc8:	97a6                	add	a5,a5,s1
    80004fca:	0187c783          	lbu	a5,24(a5)
    80004fce:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fd2:	4685                	li	a3,1
    80004fd4:	fbf40613          	addi	a2,s0,-65
    80004fd8:	85ca                	mv	a1,s2
    80004fda:	050a3503          	ld	a0,80(s4)
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	67c080e7          	jalr	1660(ra) # 8000165a <copyout>
    80004fe6:	01650763          	beq	a0,s6,80004ff4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fea:	2985                	addiw	s3,s3,1
    80004fec:	0905                	addi	s2,s2,1
    80004fee:	fd3a91e3          	bne	s5,s3,80004fb0 <piperead+0x6a>
    80004ff2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ff4:	21c48513          	addi	a0,s1,540
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	552080e7          	jalr	1362(ra) # 8000254a <wakeup>
  release(&pi->lock);
    80005000:	8526                	mv	a0,s1
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c82080e7          	jalr	-894(ra) # 80000c84 <release>
  return i;
}
    8000500a:	854e                	mv	a0,s3
    8000500c:	60a6                	ld	ra,72(sp)
    8000500e:	6406                	ld	s0,64(sp)
    80005010:	74e2                	ld	s1,56(sp)
    80005012:	7942                	ld	s2,48(sp)
    80005014:	79a2                	ld	s3,40(sp)
    80005016:	7a02                	ld	s4,32(sp)
    80005018:	6ae2                	ld	s5,24(sp)
    8000501a:	6b42                	ld	s6,16(sp)
    8000501c:	6161                	addi	sp,sp,80
    8000501e:	8082                	ret
      release(&pi->lock);
    80005020:	8526                	mv	a0,s1
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	c62080e7          	jalr	-926(ra) # 80000c84 <release>
      return -1;
    8000502a:	59fd                	li	s3,-1
    8000502c:	bff9                	j	8000500a <piperead+0xc4>

000000008000502e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000502e:	de010113          	addi	sp,sp,-544
    80005032:	20113c23          	sd	ra,536(sp)
    80005036:	20813823          	sd	s0,528(sp)
    8000503a:	20913423          	sd	s1,520(sp)
    8000503e:	21213023          	sd	s2,512(sp)
    80005042:	ffce                	sd	s3,504(sp)
    80005044:	fbd2                	sd	s4,496(sp)
    80005046:	f7d6                	sd	s5,488(sp)
    80005048:	f3da                	sd	s6,480(sp)
    8000504a:	efde                	sd	s7,472(sp)
    8000504c:	ebe2                	sd	s8,464(sp)
    8000504e:	e7e6                	sd	s9,456(sp)
    80005050:	e3ea                	sd	s10,448(sp)
    80005052:	ff6e                	sd	s11,440(sp)
    80005054:	1400                	addi	s0,sp,544
    80005056:	892a                	mv	s2,a0
    80005058:	dea43423          	sd	a0,-536(s0)
    8000505c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	936080e7          	jalr	-1738(ra) # 80001996 <myproc>
    80005068:	84aa                	mv	s1,a0

  begin_op();
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	4a8080e7          	jalr	1192(ra) # 80004512 <begin_op>

  if((ip = namei(path)) == 0){
    80005072:	854a                	mv	a0,s2
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	27e080e7          	jalr	638(ra) # 800042f2 <namei>
    8000507c:	c93d                	beqz	a0,800050f2 <exec+0xc4>
    8000507e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	ab6080e7          	jalr	-1354(ra) # 80003b36 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005088:	04000713          	li	a4,64
    8000508c:	4681                	li	a3,0
    8000508e:	e5040613          	addi	a2,s0,-432
    80005092:	4581                	li	a1,0
    80005094:	8556                	mv	a0,s5
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	d54080e7          	jalr	-684(ra) # 80003dea <readi>
    8000509e:	04000793          	li	a5,64
    800050a2:	00f51a63          	bne	a0,a5,800050b6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050a6:	e5042703          	lw	a4,-432(s0)
    800050aa:	464c47b7          	lui	a5,0x464c4
    800050ae:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050b2:	04f70663          	beq	a4,a5,800050fe <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050b6:	8556                	mv	a0,s5
    800050b8:	fffff097          	auipc	ra,0xfffff
    800050bc:	ce0080e7          	jalr	-800(ra) # 80003d98 <iunlockput>
    end_op();
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	4d0080e7          	jalr	1232(ra) # 80004590 <end_op>
  }
  return -1;
    800050c8:	557d                	li	a0,-1
}
    800050ca:	21813083          	ld	ra,536(sp)
    800050ce:	21013403          	ld	s0,528(sp)
    800050d2:	20813483          	ld	s1,520(sp)
    800050d6:	20013903          	ld	s2,512(sp)
    800050da:	79fe                	ld	s3,504(sp)
    800050dc:	7a5e                	ld	s4,496(sp)
    800050de:	7abe                	ld	s5,488(sp)
    800050e0:	7b1e                	ld	s6,480(sp)
    800050e2:	6bfe                	ld	s7,472(sp)
    800050e4:	6c5e                	ld	s8,464(sp)
    800050e6:	6cbe                	ld	s9,456(sp)
    800050e8:	6d1e                	ld	s10,448(sp)
    800050ea:	7dfa                	ld	s11,440(sp)
    800050ec:	22010113          	addi	sp,sp,544
    800050f0:	8082                	ret
    end_op();
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	49e080e7          	jalr	1182(ra) # 80004590 <end_op>
    return -1;
    800050fa:	557d                	li	a0,-1
    800050fc:	b7f9                	j	800050ca <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050fe:	8526                	mv	a0,s1
    80005100:	ffffd097          	auipc	ra,0xffffd
    80005104:	95a080e7          	jalr	-1702(ra) # 80001a5a <proc_pagetable>
    80005108:	8b2a                	mv	s6,a0
    8000510a:	d555                	beqz	a0,800050b6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000510c:	e7042783          	lw	a5,-400(s0)
    80005110:	e8845703          	lhu	a4,-376(s0)
    80005114:	c735                	beqz	a4,80005180 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005116:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005118:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    8000511c:	6a05                	lui	s4,0x1
    8000511e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005122:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005126:	6d85                	lui	s11,0x1
    80005128:	7d7d                	lui	s10,0xfffff
    8000512a:	ac1d                	j	80005360 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000512c:	00003517          	auipc	a0,0x3
    80005130:	7d450513          	addi	a0,a0,2004 # 80008900 <syscallargs+0x230>
    80005134:	ffffb097          	auipc	ra,0xffffb
    80005138:	406080e7          	jalr	1030(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000513c:	874a                	mv	a4,s2
    8000513e:	009c86bb          	addw	a3,s9,s1
    80005142:	4581                	li	a1,0
    80005144:	8556                	mv	a0,s5
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	ca4080e7          	jalr	-860(ra) # 80003dea <readi>
    8000514e:	2501                	sext.w	a0,a0
    80005150:	1aa91863          	bne	s2,a0,80005300 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005154:	009d84bb          	addw	s1,s11,s1
    80005158:	013d09bb          	addw	s3,s10,s3
    8000515c:	1f74f263          	bgeu	s1,s7,80005340 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005160:	02049593          	slli	a1,s1,0x20
    80005164:	9181                	srli	a1,a1,0x20
    80005166:	95e2                	add	a1,a1,s8
    80005168:	855a                	mv	a0,s6
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	ee8080e7          	jalr	-280(ra) # 80001052 <walkaddr>
    80005172:	862a                	mv	a2,a0
    if(pa == 0)
    80005174:	dd45                	beqz	a0,8000512c <exec+0xfe>
      n = PGSIZE;
    80005176:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005178:	fd49f2e3          	bgeu	s3,s4,8000513c <exec+0x10e>
      n = sz - i;
    8000517c:	894e                	mv	s2,s3
    8000517e:	bf7d                	j	8000513c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005180:	4481                	li	s1,0
  iunlockput(ip);
    80005182:	8556                	mv	a0,s5
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	c14080e7          	jalr	-1004(ra) # 80003d98 <iunlockput>
  end_op();
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	404080e7          	jalr	1028(ra) # 80004590 <end_op>
  p = myproc();
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	802080e7          	jalr	-2046(ra) # 80001996 <myproc>
    8000519c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000519e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051a2:	6785                	lui	a5,0x1
    800051a4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800051a6:	97a6                	add	a5,a5,s1
    800051a8:	777d                	lui	a4,0xfffff
    800051aa:	8ff9                	and	a5,a5,a4
    800051ac:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051b0:	6609                	lui	a2,0x2
    800051b2:	963e                	add	a2,a2,a5
    800051b4:	85be                	mv	a1,a5
    800051b6:	855a                	mv	a0,s6
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	24e080e7          	jalr	590(ra) # 80001406 <uvmalloc>
    800051c0:	8c2a                	mv	s8,a0
  ip = 0;
    800051c2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051c4:	12050e63          	beqz	a0,80005300 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051c8:	75f9                	lui	a1,0xffffe
    800051ca:	95aa                	add	a1,a1,a0
    800051cc:	855a                	mv	a0,s6
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	45a080e7          	jalr	1114(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    800051d6:	7afd                	lui	s5,0xfffff
    800051d8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051da:	df043783          	ld	a5,-528(s0)
    800051de:	6388                	ld	a0,0(a5)
    800051e0:	c925                	beqz	a0,80005250 <exec+0x222>
    800051e2:	e9040993          	addi	s3,s0,-368
    800051e6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051ea:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ec:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	c5a080e7          	jalr	-934(ra) # 80000e48 <strlen>
    800051f6:	0015079b          	addiw	a5,a0,1
    800051fa:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051fe:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005202:	13596363          	bltu	s2,s5,80005328 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005206:	df043d83          	ld	s11,-528(s0)
    8000520a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000520e:	8552                	mv	a0,s4
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	c38080e7          	jalr	-968(ra) # 80000e48 <strlen>
    80005218:	0015069b          	addiw	a3,a0,1
    8000521c:	8652                	mv	a2,s4
    8000521e:	85ca                	mv	a1,s2
    80005220:	855a                	mv	a0,s6
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	438080e7          	jalr	1080(ra) # 8000165a <copyout>
    8000522a:	10054363          	bltz	a0,80005330 <exec+0x302>
    ustack[argc] = sp;
    8000522e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005232:	0485                	addi	s1,s1,1
    80005234:	008d8793          	addi	a5,s11,8
    80005238:	def43823          	sd	a5,-528(s0)
    8000523c:	008db503          	ld	a0,8(s11)
    80005240:	c911                	beqz	a0,80005254 <exec+0x226>
    if(argc >= MAXARG)
    80005242:	09a1                	addi	s3,s3,8
    80005244:	fb3c95e3          	bne	s9,s3,800051ee <exec+0x1c0>
  sz = sz1;
    80005248:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000524c:	4a81                	li	s5,0
    8000524e:	a84d                	j	80005300 <exec+0x2d2>
  sp = sz;
    80005250:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005252:	4481                	li	s1,0
  ustack[argc] = 0;
    80005254:	00349793          	slli	a5,s1,0x3
    80005258:	f9078793          	addi	a5,a5,-112
    8000525c:	97a2                	add	a5,a5,s0
    8000525e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005262:	00148693          	addi	a3,s1,1
    80005266:	068e                	slli	a3,a3,0x3
    80005268:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000526c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005270:	01597663          	bgeu	s2,s5,8000527c <exec+0x24e>
  sz = sz1;
    80005274:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005278:	4a81                	li	s5,0
    8000527a:	a059                	j	80005300 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000527c:	e9040613          	addi	a2,s0,-368
    80005280:	85ca                	mv	a1,s2
    80005282:	855a                	mv	a0,s6
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	3d6080e7          	jalr	982(ra) # 8000165a <copyout>
    8000528c:	0a054663          	bltz	a0,80005338 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005290:	058bb783          	ld	a5,88(s7)
    80005294:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005298:	de843783          	ld	a5,-536(s0)
    8000529c:	0007c703          	lbu	a4,0(a5)
    800052a0:	cf11                	beqz	a4,800052bc <exec+0x28e>
    800052a2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052a4:	02f00693          	li	a3,47
    800052a8:	a039                	j	800052b6 <exec+0x288>
      last = s+1;
    800052aa:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052ae:	0785                	addi	a5,a5,1
    800052b0:	fff7c703          	lbu	a4,-1(a5)
    800052b4:	c701                	beqz	a4,800052bc <exec+0x28e>
    if(*s == '/')
    800052b6:	fed71ce3          	bne	a4,a3,800052ae <exec+0x280>
    800052ba:	bfc5                	j	800052aa <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800052bc:	4641                	li	a2,16
    800052be:	de843583          	ld	a1,-536(s0)
    800052c2:	158b8513          	addi	a0,s7,344
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	b50080e7          	jalr	-1200(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800052ce:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800052d2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800052d6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052da:	058bb783          	ld	a5,88(s7)
    800052de:	e6843703          	ld	a4,-408(s0)
    800052e2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052e4:	058bb783          	ld	a5,88(s7)
    800052e8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052ec:	85ea                	mv	a1,s10
    800052ee:	ffffd097          	auipc	ra,0xffffd
    800052f2:	808080e7          	jalr	-2040(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052f6:	0004851b          	sext.w	a0,s1
    800052fa:	bbc1                	j	800050ca <exec+0x9c>
    800052fc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005300:	df843583          	ld	a1,-520(s0)
    80005304:	855a                	mv	a0,s6
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	7f0080e7          	jalr	2032(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    8000530e:	da0a94e3          	bnez	s5,800050b6 <exec+0x88>
  return -1;
    80005312:	557d                	li	a0,-1
    80005314:	bb5d                	j	800050ca <exec+0x9c>
    80005316:	de943c23          	sd	s1,-520(s0)
    8000531a:	b7dd                	j	80005300 <exec+0x2d2>
    8000531c:	de943c23          	sd	s1,-520(s0)
    80005320:	b7c5                	j	80005300 <exec+0x2d2>
    80005322:	de943c23          	sd	s1,-520(s0)
    80005326:	bfe9                	j	80005300 <exec+0x2d2>
  sz = sz1;
    80005328:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000532c:	4a81                	li	s5,0
    8000532e:	bfc9                	j	80005300 <exec+0x2d2>
  sz = sz1;
    80005330:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005334:	4a81                	li	s5,0
    80005336:	b7e9                	j	80005300 <exec+0x2d2>
  sz = sz1;
    80005338:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000533c:	4a81                	li	s5,0
    8000533e:	b7c9                	j	80005300 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005340:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005344:	e0843783          	ld	a5,-504(s0)
    80005348:	0017869b          	addiw	a3,a5,1
    8000534c:	e0d43423          	sd	a3,-504(s0)
    80005350:	e0043783          	ld	a5,-512(s0)
    80005354:	0387879b          	addiw	a5,a5,56
    80005358:	e8845703          	lhu	a4,-376(s0)
    8000535c:	e2e6d3e3          	bge	a3,a4,80005182 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005360:	2781                	sext.w	a5,a5
    80005362:	e0f43023          	sd	a5,-512(s0)
    80005366:	03800713          	li	a4,56
    8000536a:	86be                	mv	a3,a5
    8000536c:	e1840613          	addi	a2,s0,-488
    80005370:	4581                	li	a1,0
    80005372:	8556                	mv	a0,s5
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	a76080e7          	jalr	-1418(ra) # 80003dea <readi>
    8000537c:	03800793          	li	a5,56
    80005380:	f6f51ee3          	bne	a0,a5,800052fc <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005384:	e1842783          	lw	a5,-488(s0)
    80005388:	4705                	li	a4,1
    8000538a:	fae79de3          	bne	a5,a4,80005344 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000538e:	e4043603          	ld	a2,-448(s0)
    80005392:	e3843783          	ld	a5,-456(s0)
    80005396:	f8f660e3          	bltu	a2,a5,80005316 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000539a:	e2843783          	ld	a5,-472(s0)
    8000539e:	963e                	add	a2,a2,a5
    800053a0:	f6f66ee3          	bltu	a2,a5,8000531c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053a4:	85a6                	mv	a1,s1
    800053a6:	855a                	mv	a0,s6
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	05e080e7          	jalr	94(ra) # 80001406 <uvmalloc>
    800053b0:	dea43c23          	sd	a0,-520(s0)
    800053b4:	d53d                	beqz	a0,80005322 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800053b6:	e2843c03          	ld	s8,-472(s0)
    800053ba:	de043783          	ld	a5,-544(s0)
    800053be:	00fc77b3          	and	a5,s8,a5
    800053c2:	ff9d                	bnez	a5,80005300 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053c4:	e2042c83          	lw	s9,-480(s0)
    800053c8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053cc:	f60b8ae3          	beqz	s7,80005340 <exec+0x312>
    800053d0:	89de                	mv	s3,s7
    800053d2:	4481                	li	s1,0
    800053d4:	b371                	j	80005160 <exec+0x132>

00000000800053d6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053d6:	7179                	addi	sp,sp,-48
    800053d8:	f406                	sd	ra,40(sp)
    800053da:	f022                	sd	s0,32(sp)
    800053dc:	ec26                	sd	s1,24(sp)
    800053de:	e84a                	sd	s2,16(sp)
    800053e0:	1800                	addi	s0,sp,48
    800053e2:	892e                	mv	s2,a1
    800053e4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053e6:	fdc40593          	addi	a1,s0,-36
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	9ee080e7          	jalr	-1554(ra) # 80002dd8 <argint>
    800053f2:	04054063          	bltz	a0,80005432 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053f6:	fdc42703          	lw	a4,-36(s0)
    800053fa:	47bd                	li	a5,15
    800053fc:	02e7ed63          	bltu	a5,a4,80005436 <argfd+0x60>
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	596080e7          	jalr	1430(ra) # 80001996 <myproc>
    80005408:	fdc42703          	lw	a4,-36(s0)
    8000540c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd701a>
    80005410:	078e                	slli	a5,a5,0x3
    80005412:	953e                	add	a0,a0,a5
    80005414:	611c                	ld	a5,0(a0)
    80005416:	c395                	beqz	a5,8000543a <argfd+0x64>
    return -1;
  if(pfd)
    80005418:	00090463          	beqz	s2,80005420 <argfd+0x4a>
    *pfd = fd;
    8000541c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005420:	4501                	li	a0,0
  if(pf)
    80005422:	c091                	beqz	s1,80005426 <argfd+0x50>
    *pf = f;
    80005424:	e09c                	sd	a5,0(s1)
}
    80005426:	70a2                	ld	ra,40(sp)
    80005428:	7402                	ld	s0,32(sp)
    8000542a:	64e2                	ld	s1,24(sp)
    8000542c:	6942                	ld	s2,16(sp)
    8000542e:	6145                	addi	sp,sp,48
    80005430:	8082                	ret
    return -1;
    80005432:	557d                	li	a0,-1
    80005434:	bfcd                	j	80005426 <argfd+0x50>
    return -1;
    80005436:	557d                	li	a0,-1
    80005438:	b7fd                	j	80005426 <argfd+0x50>
    8000543a:	557d                	li	a0,-1
    8000543c:	b7ed                	j	80005426 <argfd+0x50>

000000008000543e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000543e:	1101                	addi	sp,sp,-32
    80005440:	ec06                	sd	ra,24(sp)
    80005442:	e822                	sd	s0,16(sp)
    80005444:	e426                	sd	s1,8(sp)
    80005446:	1000                	addi	s0,sp,32
    80005448:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	54c080e7          	jalr	1356(ra) # 80001996 <myproc>
    80005452:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005454:	0d050793          	addi	a5,a0,208
    80005458:	4501                	li	a0,0
    8000545a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000545c:	6398                	ld	a4,0(a5)
    8000545e:	cb19                	beqz	a4,80005474 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005460:	2505                	addiw	a0,a0,1
    80005462:	07a1                	addi	a5,a5,8
    80005464:	fed51ce3          	bne	a0,a3,8000545c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005468:	557d                	li	a0,-1
}
    8000546a:	60e2                	ld	ra,24(sp)
    8000546c:	6442                	ld	s0,16(sp)
    8000546e:	64a2                	ld	s1,8(sp)
    80005470:	6105                	addi	sp,sp,32
    80005472:	8082                	ret
      p->ofile[fd] = f;
    80005474:	01a50793          	addi	a5,a0,26
    80005478:	078e                	slli	a5,a5,0x3
    8000547a:	963e                	add	a2,a2,a5
    8000547c:	e204                	sd	s1,0(a2)
      return fd;
    8000547e:	b7f5                	j	8000546a <fdalloc+0x2c>

0000000080005480 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005480:	715d                	addi	sp,sp,-80
    80005482:	e486                	sd	ra,72(sp)
    80005484:	e0a2                	sd	s0,64(sp)
    80005486:	fc26                	sd	s1,56(sp)
    80005488:	f84a                	sd	s2,48(sp)
    8000548a:	f44e                	sd	s3,40(sp)
    8000548c:	f052                	sd	s4,32(sp)
    8000548e:	ec56                	sd	s5,24(sp)
    80005490:	0880                	addi	s0,sp,80
    80005492:	89ae                	mv	s3,a1
    80005494:	8ab2                	mv	s5,a2
    80005496:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005498:	fb040593          	addi	a1,s0,-80
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	e74080e7          	jalr	-396(ra) # 80004310 <nameiparent>
    800054a4:	892a                	mv	s2,a0
    800054a6:	12050e63          	beqz	a0,800055e2 <create+0x162>
    return 0;

  ilock(dp);
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	68c080e7          	jalr	1676(ra) # 80003b36 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054b2:	4601                	li	a2,0
    800054b4:	fb040593          	addi	a1,s0,-80
    800054b8:	854a                	mv	a0,s2
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	b60080e7          	jalr	-1184(ra) # 8000401a <dirlookup>
    800054c2:	84aa                	mv	s1,a0
    800054c4:	c921                	beqz	a0,80005514 <create+0x94>
    iunlockput(dp);
    800054c6:	854a                	mv	a0,s2
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	8d0080e7          	jalr	-1840(ra) # 80003d98 <iunlockput>
    ilock(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	664080e7          	jalr	1636(ra) # 80003b36 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054da:	2981                	sext.w	s3,s3
    800054dc:	4789                	li	a5,2
    800054de:	02f99463          	bne	s3,a5,80005506 <create+0x86>
    800054e2:	0444d783          	lhu	a5,68(s1)
    800054e6:	37f9                	addiw	a5,a5,-2
    800054e8:	17c2                	slli	a5,a5,0x30
    800054ea:	93c1                	srli	a5,a5,0x30
    800054ec:	4705                	li	a4,1
    800054ee:	00f76c63          	bltu	a4,a5,80005506 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054f2:	8526                	mv	a0,s1
    800054f4:	60a6                	ld	ra,72(sp)
    800054f6:	6406                	ld	s0,64(sp)
    800054f8:	74e2                	ld	s1,56(sp)
    800054fa:	7942                	ld	s2,48(sp)
    800054fc:	79a2                	ld	s3,40(sp)
    800054fe:	7a02                	ld	s4,32(sp)
    80005500:	6ae2                	ld	s5,24(sp)
    80005502:	6161                	addi	sp,sp,80
    80005504:	8082                	ret
    iunlockput(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	890080e7          	jalr	-1904(ra) # 80003d98 <iunlockput>
    return 0;
    80005510:	4481                	li	s1,0
    80005512:	b7c5                	j	800054f2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005514:	85ce                	mv	a1,s3
    80005516:	00092503          	lw	a0,0(s2)
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	482080e7          	jalr	1154(ra) # 8000399c <ialloc>
    80005522:	84aa                	mv	s1,a0
    80005524:	c521                	beqz	a0,8000556c <create+0xec>
  ilock(ip);
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	610080e7          	jalr	1552(ra) # 80003b36 <ilock>
  ip->major = major;
    8000552e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005532:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005536:	4a05                	li	s4,1
    80005538:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	52c080e7          	jalr	1324(ra) # 80003a6a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005546:	2981                	sext.w	s3,s3
    80005548:	03498a63          	beq	s3,s4,8000557c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000554c:	40d0                	lw	a2,4(s1)
    8000554e:	fb040593          	addi	a1,s0,-80
    80005552:	854a                	mv	a0,s2
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	cdc080e7          	jalr	-804(ra) # 80004230 <dirlink>
    8000555c:	06054b63          	bltz	a0,800055d2 <create+0x152>
  iunlockput(dp);
    80005560:	854a                	mv	a0,s2
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	836080e7          	jalr	-1994(ra) # 80003d98 <iunlockput>
  return ip;
    8000556a:	b761                	j	800054f2 <create+0x72>
    panic("create: ialloc");
    8000556c:	00003517          	auipc	a0,0x3
    80005570:	3b450513          	addi	a0,a0,948 # 80008920 <syscallargs+0x250>
    80005574:	ffffb097          	auipc	ra,0xffffb
    80005578:	fc6080e7          	jalr	-58(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000557c:	04a95783          	lhu	a5,74(s2)
    80005580:	2785                	addiw	a5,a5,1
    80005582:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005586:	854a                	mv	a0,s2
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	4e2080e7          	jalr	1250(ra) # 80003a6a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005590:	40d0                	lw	a2,4(s1)
    80005592:	00003597          	auipc	a1,0x3
    80005596:	39e58593          	addi	a1,a1,926 # 80008930 <syscallargs+0x260>
    8000559a:	8526                	mv	a0,s1
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	c94080e7          	jalr	-876(ra) # 80004230 <dirlink>
    800055a4:	00054f63          	bltz	a0,800055c2 <create+0x142>
    800055a8:	00492603          	lw	a2,4(s2)
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	38c58593          	addi	a1,a1,908 # 80008938 <syscallargs+0x268>
    800055b4:	8526                	mv	a0,s1
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	c7a080e7          	jalr	-902(ra) # 80004230 <dirlink>
    800055be:	f80557e3          	bgez	a0,8000554c <create+0xcc>
      panic("create dots");
    800055c2:	00003517          	auipc	a0,0x3
    800055c6:	37e50513          	addi	a0,a0,894 # 80008940 <syscallargs+0x270>
    800055ca:	ffffb097          	auipc	ra,0xffffb
    800055ce:	f70080e7          	jalr	-144(ra) # 8000053a <panic>
    panic("create: dirlink");
    800055d2:	00003517          	auipc	a0,0x3
    800055d6:	37e50513          	addi	a0,a0,894 # 80008950 <syscallargs+0x280>
    800055da:	ffffb097          	auipc	ra,0xffffb
    800055de:	f60080e7          	jalr	-160(ra) # 8000053a <panic>
    return 0;
    800055e2:	84aa                	mv	s1,a0
    800055e4:	b739                	j	800054f2 <create+0x72>

00000000800055e6 <sys_dup>:
{
    800055e6:	7179                	addi	sp,sp,-48
    800055e8:	f406                	sd	ra,40(sp)
    800055ea:	f022                	sd	s0,32(sp)
    800055ec:	ec26                	sd	s1,24(sp)
    800055ee:	e84a                	sd	s2,16(sp)
    800055f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055f2:	fd840613          	addi	a2,s0,-40
    800055f6:	4581                	li	a1,0
    800055f8:	4501                	li	a0,0
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	ddc080e7          	jalr	-548(ra) # 800053d6 <argfd>
    return -1;
    80005602:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005604:	02054363          	bltz	a0,8000562a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005608:	fd843903          	ld	s2,-40(s0)
    8000560c:	854a                	mv	a0,s2
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	e30080e7          	jalr	-464(ra) # 8000543e <fdalloc>
    80005616:	84aa                	mv	s1,a0
    return -1;
    80005618:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000561a:	00054863          	bltz	a0,8000562a <sys_dup+0x44>
  filedup(f);
    8000561e:	854a                	mv	a0,s2
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	368080e7          	jalr	872(ra) # 80004988 <filedup>
  return fd;
    80005628:	87a6                	mv	a5,s1
}
    8000562a:	853e                	mv	a0,a5
    8000562c:	70a2                	ld	ra,40(sp)
    8000562e:	7402                	ld	s0,32(sp)
    80005630:	64e2                	ld	s1,24(sp)
    80005632:	6942                	ld	s2,16(sp)
    80005634:	6145                	addi	sp,sp,48
    80005636:	8082                	ret

0000000080005638 <sys_read>:
{
    80005638:	7179                	addi	sp,sp,-48
    8000563a:	f406                	sd	ra,40(sp)
    8000563c:	f022                	sd	s0,32(sp)
    8000563e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005640:	fe840613          	addi	a2,s0,-24
    80005644:	4581                	li	a1,0
    80005646:	4501                	li	a0,0
    80005648:	00000097          	auipc	ra,0x0
    8000564c:	d8e080e7          	jalr	-626(ra) # 800053d6 <argfd>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005652:	04054163          	bltz	a0,80005694 <sys_read+0x5c>
    80005656:	fe440593          	addi	a1,s0,-28
    8000565a:	4509                	li	a0,2
    8000565c:	ffffd097          	auipc	ra,0xffffd
    80005660:	77c080e7          	jalr	1916(ra) # 80002dd8 <argint>
    return -1;
    80005664:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005666:	02054763          	bltz	a0,80005694 <sys_read+0x5c>
    8000566a:	fd840593          	addi	a1,s0,-40
    8000566e:	4505                	li	a0,1
    80005670:	ffffd097          	auipc	ra,0xffffd
    80005674:	78a080e7          	jalr	1930(ra) # 80002dfa <argaddr>
    return -1;
    80005678:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567a:	00054d63          	bltz	a0,80005694 <sys_read+0x5c>
  return fileread(f, p, n);
    8000567e:	fe442603          	lw	a2,-28(s0)
    80005682:	fd843583          	ld	a1,-40(s0)
    80005686:	fe843503          	ld	a0,-24(s0)
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	48a080e7          	jalr	1162(ra) # 80004b14 <fileread>
    80005692:	87aa                	mv	a5,a0
}
    80005694:	853e                	mv	a0,a5
    80005696:	70a2                	ld	ra,40(sp)
    80005698:	7402                	ld	s0,32(sp)
    8000569a:	6145                	addi	sp,sp,48
    8000569c:	8082                	ret

000000008000569e <sys_write>:
{
    8000569e:	7179                	addi	sp,sp,-48
    800056a0:	f406                	sd	ra,40(sp)
    800056a2:	f022                	sd	s0,32(sp)
    800056a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a6:	fe840613          	addi	a2,s0,-24
    800056aa:	4581                	li	a1,0
    800056ac:	4501                	li	a0,0
    800056ae:	00000097          	auipc	ra,0x0
    800056b2:	d28080e7          	jalr	-728(ra) # 800053d6 <argfd>
    return -1;
    800056b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b8:	04054163          	bltz	a0,800056fa <sys_write+0x5c>
    800056bc:	fe440593          	addi	a1,s0,-28
    800056c0:	4509                	li	a0,2
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	716080e7          	jalr	1814(ra) # 80002dd8 <argint>
    return -1;
    800056ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056cc:	02054763          	bltz	a0,800056fa <sys_write+0x5c>
    800056d0:	fd840593          	addi	a1,s0,-40
    800056d4:	4505                	li	a0,1
    800056d6:	ffffd097          	auipc	ra,0xffffd
    800056da:	724080e7          	jalr	1828(ra) # 80002dfa <argaddr>
    return -1;
    800056de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e0:	00054d63          	bltz	a0,800056fa <sys_write+0x5c>
  return filewrite(f, p, n);
    800056e4:	fe442603          	lw	a2,-28(s0)
    800056e8:	fd843583          	ld	a1,-40(s0)
    800056ec:	fe843503          	ld	a0,-24(s0)
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	4e6080e7          	jalr	1254(ra) # 80004bd6 <filewrite>
    800056f8:	87aa                	mv	a5,a0
}
    800056fa:	853e                	mv	a0,a5
    800056fc:	70a2                	ld	ra,40(sp)
    800056fe:	7402                	ld	s0,32(sp)
    80005700:	6145                	addi	sp,sp,48
    80005702:	8082                	ret

0000000080005704 <sys_close>:
{
    80005704:	1101                	addi	sp,sp,-32
    80005706:	ec06                	sd	ra,24(sp)
    80005708:	e822                	sd	s0,16(sp)
    8000570a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000570c:	fe040613          	addi	a2,s0,-32
    80005710:	fec40593          	addi	a1,s0,-20
    80005714:	4501                	li	a0,0
    80005716:	00000097          	auipc	ra,0x0
    8000571a:	cc0080e7          	jalr	-832(ra) # 800053d6 <argfd>
    return -1;
    8000571e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005720:	02054463          	bltz	a0,80005748 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005724:	ffffc097          	auipc	ra,0xffffc
    80005728:	272080e7          	jalr	626(ra) # 80001996 <myproc>
    8000572c:	fec42783          	lw	a5,-20(s0)
    80005730:	07e9                	addi	a5,a5,26
    80005732:	078e                	slli	a5,a5,0x3
    80005734:	953e                	add	a0,a0,a5
    80005736:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000573a:	fe043503          	ld	a0,-32(s0)
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	29c080e7          	jalr	668(ra) # 800049da <fileclose>
  return 0;
    80005746:	4781                	li	a5,0
}
    80005748:	853e                	mv	a0,a5
    8000574a:	60e2                	ld	ra,24(sp)
    8000574c:	6442                	ld	s0,16(sp)
    8000574e:	6105                	addi	sp,sp,32
    80005750:	8082                	ret

0000000080005752 <sys_fstat>:
{
    80005752:	1101                	addi	sp,sp,-32
    80005754:	ec06                	sd	ra,24(sp)
    80005756:	e822                	sd	s0,16(sp)
    80005758:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000575a:	fe840613          	addi	a2,s0,-24
    8000575e:	4581                	li	a1,0
    80005760:	4501                	li	a0,0
    80005762:	00000097          	auipc	ra,0x0
    80005766:	c74080e7          	jalr	-908(ra) # 800053d6 <argfd>
    return -1;
    8000576a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000576c:	02054563          	bltz	a0,80005796 <sys_fstat+0x44>
    80005770:	fe040593          	addi	a1,s0,-32
    80005774:	4505                	li	a0,1
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	684080e7          	jalr	1668(ra) # 80002dfa <argaddr>
    return -1;
    8000577e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005780:	00054b63          	bltz	a0,80005796 <sys_fstat+0x44>
  return filestat(f, st);
    80005784:	fe043583          	ld	a1,-32(s0)
    80005788:	fe843503          	ld	a0,-24(s0)
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	316080e7          	jalr	790(ra) # 80004aa2 <filestat>
    80005794:	87aa                	mv	a5,a0
}
    80005796:	853e                	mv	a0,a5
    80005798:	60e2                	ld	ra,24(sp)
    8000579a:	6442                	ld	s0,16(sp)
    8000579c:	6105                	addi	sp,sp,32
    8000579e:	8082                	ret

00000000800057a0 <sys_link>:
{
    800057a0:	7169                	addi	sp,sp,-304
    800057a2:	f606                	sd	ra,296(sp)
    800057a4:	f222                	sd	s0,288(sp)
    800057a6:	ee26                	sd	s1,280(sp)
    800057a8:	ea4a                	sd	s2,272(sp)
    800057aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ac:	08000613          	li	a2,128
    800057b0:	ed040593          	addi	a1,s0,-304
    800057b4:	4501                	li	a0,0
    800057b6:	ffffd097          	auipc	ra,0xffffd
    800057ba:	666080e7          	jalr	1638(ra) # 80002e1c <argstr>
    return -1;
    800057be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c0:	10054e63          	bltz	a0,800058dc <sys_link+0x13c>
    800057c4:	08000613          	li	a2,128
    800057c8:	f5040593          	addi	a1,s0,-176
    800057cc:	4505                	li	a0,1
    800057ce:	ffffd097          	auipc	ra,0xffffd
    800057d2:	64e080e7          	jalr	1614(ra) # 80002e1c <argstr>
    return -1;
    800057d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d8:	10054263          	bltz	a0,800058dc <sys_link+0x13c>
  begin_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	d36080e7          	jalr	-714(ra) # 80004512 <begin_op>
  if((ip = namei(old)) == 0){
    800057e4:	ed040513          	addi	a0,s0,-304
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	b0a080e7          	jalr	-1270(ra) # 800042f2 <namei>
    800057f0:	84aa                	mv	s1,a0
    800057f2:	c551                	beqz	a0,8000587e <sys_link+0xde>
  ilock(ip);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	342080e7          	jalr	834(ra) # 80003b36 <ilock>
  if(ip->type == T_DIR){
    800057fc:	04449703          	lh	a4,68(s1)
    80005800:	4785                	li	a5,1
    80005802:	08f70463          	beq	a4,a5,8000588a <sys_link+0xea>
  ip->nlink++;
    80005806:	04a4d783          	lhu	a5,74(s1)
    8000580a:	2785                	addiw	a5,a5,1
    8000580c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	258080e7          	jalr	600(ra) # 80003a6a <iupdate>
  iunlock(ip);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	3dc080e7          	jalr	988(ra) # 80003bf8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005824:	fd040593          	addi	a1,s0,-48
    80005828:	f5040513          	addi	a0,s0,-176
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	ae4080e7          	jalr	-1308(ra) # 80004310 <nameiparent>
    80005834:	892a                	mv	s2,a0
    80005836:	c935                	beqz	a0,800058aa <sys_link+0x10a>
  ilock(dp);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	2fe080e7          	jalr	766(ra) # 80003b36 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005840:	00092703          	lw	a4,0(s2)
    80005844:	409c                	lw	a5,0(s1)
    80005846:	04f71d63          	bne	a4,a5,800058a0 <sys_link+0x100>
    8000584a:	40d0                	lw	a2,4(s1)
    8000584c:	fd040593          	addi	a1,s0,-48
    80005850:	854a                	mv	a0,s2
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	9de080e7          	jalr	-1570(ra) # 80004230 <dirlink>
    8000585a:	04054363          	bltz	a0,800058a0 <sys_link+0x100>
  iunlockput(dp);
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	538080e7          	jalr	1336(ra) # 80003d98 <iunlockput>
  iput(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	486080e7          	jalr	1158(ra) # 80003cf0 <iput>
  end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	d1e080e7          	jalr	-738(ra) # 80004590 <end_op>
  return 0;
    8000587a:	4781                	li	a5,0
    8000587c:	a085                	j	800058dc <sys_link+0x13c>
    end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	d12080e7          	jalr	-750(ra) # 80004590 <end_op>
    return -1;
    80005886:	57fd                	li	a5,-1
    80005888:	a891                	j	800058dc <sys_link+0x13c>
    iunlockput(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	50c080e7          	jalr	1292(ra) # 80003d98 <iunlockput>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	cfc080e7          	jalr	-772(ra) # 80004590 <end_op>
    return -1;
    8000589c:	57fd                	li	a5,-1
    8000589e:	a83d                	j	800058dc <sys_link+0x13c>
    iunlockput(dp);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	4f6080e7          	jalr	1270(ra) # 80003d98 <iunlockput>
  ilock(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	28a080e7          	jalr	650(ra) # 80003b36 <ilock>
  ip->nlink--;
    800058b4:	04a4d783          	lhu	a5,74(s1)
    800058b8:	37fd                	addiw	a5,a5,-1
    800058ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	1aa080e7          	jalr	426(ra) # 80003a6a <iupdate>
  iunlockput(ip);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	4ce080e7          	jalr	1230(ra) # 80003d98 <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	cbe080e7          	jalr	-834(ra) # 80004590 <end_op>
  return -1;
    800058da:	57fd                	li	a5,-1
}
    800058dc:	853e                	mv	a0,a5
    800058de:	70b2                	ld	ra,296(sp)
    800058e0:	7412                	ld	s0,288(sp)
    800058e2:	64f2                	ld	s1,280(sp)
    800058e4:	6952                	ld	s2,272(sp)
    800058e6:	6155                	addi	sp,sp,304
    800058e8:	8082                	ret

00000000800058ea <sys_unlink>:
{
    800058ea:	7151                	addi	sp,sp,-240
    800058ec:	f586                	sd	ra,232(sp)
    800058ee:	f1a2                	sd	s0,224(sp)
    800058f0:	eda6                	sd	s1,216(sp)
    800058f2:	e9ca                	sd	s2,208(sp)
    800058f4:	e5ce                	sd	s3,200(sp)
    800058f6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058f8:	08000613          	li	a2,128
    800058fc:	f3040593          	addi	a1,s0,-208
    80005900:	4501                	li	a0,0
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	51a080e7          	jalr	1306(ra) # 80002e1c <argstr>
    8000590a:	18054163          	bltz	a0,80005a8c <sys_unlink+0x1a2>
  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	c04080e7          	jalr	-1020(ra) # 80004512 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005916:	fb040593          	addi	a1,s0,-80
    8000591a:	f3040513          	addi	a0,s0,-208
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	9f2080e7          	jalr	-1550(ra) # 80004310 <nameiparent>
    80005926:	84aa                	mv	s1,a0
    80005928:	c979                	beqz	a0,800059fe <sys_unlink+0x114>
  ilock(dp);
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	20c080e7          	jalr	524(ra) # 80003b36 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005932:	00003597          	auipc	a1,0x3
    80005936:	ffe58593          	addi	a1,a1,-2 # 80008930 <syscallargs+0x260>
    8000593a:	fb040513          	addi	a0,s0,-80
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	6c2080e7          	jalr	1730(ra) # 80004000 <namecmp>
    80005946:	14050a63          	beqz	a0,80005a9a <sys_unlink+0x1b0>
    8000594a:	00003597          	auipc	a1,0x3
    8000594e:	fee58593          	addi	a1,a1,-18 # 80008938 <syscallargs+0x268>
    80005952:	fb040513          	addi	a0,s0,-80
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	6aa080e7          	jalr	1706(ra) # 80004000 <namecmp>
    8000595e:	12050e63          	beqz	a0,80005a9a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005962:	f2c40613          	addi	a2,s0,-212
    80005966:	fb040593          	addi	a1,s0,-80
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	6ae080e7          	jalr	1710(ra) # 8000401a <dirlookup>
    80005974:	892a                	mv	s2,a0
    80005976:	12050263          	beqz	a0,80005a9a <sys_unlink+0x1b0>
  ilock(ip);
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	1bc080e7          	jalr	444(ra) # 80003b36 <ilock>
  if(ip->nlink < 1)
    80005982:	04a91783          	lh	a5,74(s2)
    80005986:	08f05263          	blez	a5,80005a0a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000598a:	04491703          	lh	a4,68(s2)
    8000598e:	4785                	li	a5,1
    80005990:	08f70563          	beq	a4,a5,80005a1a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005994:	4641                	li	a2,16
    80005996:	4581                	li	a1,0
    80005998:	fc040513          	addi	a0,s0,-64
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	330080e7          	jalr	816(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059a4:	4741                	li	a4,16
    800059a6:	f2c42683          	lw	a3,-212(s0)
    800059aa:	fc040613          	addi	a2,s0,-64
    800059ae:	4581                	li	a1,0
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	530080e7          	jalr	1328(ra) # 80003ee2 <writei>
    800059ba:	47c1                	li	a5,16
    800059bc:	0af51563          	bne	a0,a5,80005a66 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059c0:	04491703          	lh	a4,68(s2)
    800059c4:	4785                	li	a5,1
    800059c6:	0af70863          	beq	a4,a5,80005a76 <sys_unlink+0x18c>
  iunlockput(dp);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	3cc080e7          	jalr	972(ra) # 80003d98 <iunlockput>
  ip->nlink--;
    800059d4:	04a95783          	lhu	a5,74(s2)
    800059d8:	37fd                	addiw	a5,a5,-1
    800059da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	08a080e7          	jalr	138(ra) # 80003a6a <iupdate>
  iunlockput(ip);
    800059e8:	854a                	mv	a0,s2
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	3ae080e7          	jalr	942(ra) # 80003d98 <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	b9e080e7          	jalr	-1122(ra) # 80004590 <end_op>
  return 0;
    800059fa:	4501                	li	a0,0
    800059fc:	a84d                	j	80005aae <sys_unlink+0x1c4>
    end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	b92080e7          	jalr	-1134(ra) # 80004590 <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	a05d                	j	80005aae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a0a:	00003517          	auipc	a0,0x3
    80005a0e:	f5650513          	addi	a0,a0,-170 # 80008960 <syscallargs+0x290>
    80005a12:	ffffb097          	auipc	ra,0xffffb
    80005a16:	b28080e7          	jalr	-1240(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a1a:	04c92703          	lw	a4,76(s2)
    80005a1e:	02000793          	li	a5,32
    80005a22:	f6e7f9e3          	bgeu	a5,a4,80005994 <sys_unlink+0xaa>
    80005a26:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a2a:	4741                	li	a4,16
    80005a2c:	86ce                	mv	a3,s3
    80005a2e:	f1840613          	addi	a2,s0,-232
    80005a32:	4581                	li	a1,0
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	3b4080e7          	jalr	948(ra) # 80003dea <readi>
    80005a3e:	47c1                	li	a5,16
    80005a40:	00f51b63          	bne	a0,a5,80005a56 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a44:	f1845783          	lhu	a5,-232(s0)
    80005a48:	e7a1                	bnez	a5,80005a90 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4a:	29c1                	addiw	s3,s3,16
    80005a4c:	04c92783          	lw	a5,76(s2)
    80005a50:	fcf9ede3          	bltu	s3,a5,80005a2a <sys_unlink+0x140>
    80005a54:	b781                	j	80005994 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a56:	00003517          	auipc	a0,0x3
    80005a5a:	f2250513          	addi	a0,a0,-222 # 80008978 <syscallargs+0x2a8>
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	adc080e7          	jalr	-1316(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005a66:	00003517          	auipc	a0,0x3
    80005a6a:	f2a50513          	addi	a0,a0,-214 # 80008990 <syscallargs+0x2c0>
    80005a6e:	ffffb097          	auipc	ra,0xffffb
    80005a72:	acc080e7          	jalr	-1332(ra) # 8000053a <panic>
    dp->nlink--;
    80005a76:	04a4d783          	lhu	a5,74(s1)
    80005a7a:	37fd                	addiw	a5,a5,-1
    80005a7c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	fe8080e7          	jalr	-24(ra) # 80003a6a <iupdate>
    80005a8a:	b781                	j	800059ca <sys_unlink+0xe0>
    return -1;
    80005a8c:	557d                	li	a0,-1
    80005a8e:	a005                	j	80005aae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a90:	854a                	mv	a0,s2
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	306080e7          	jalr	774(ra) # 80003d98 <iunlockput>
  iunlockput(dp);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	2fc080e7          	jalr	764(ra) # 80003d98 <iunlockput>
  end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	aec080e7          	jalr	-1300(ra) # 80004590 <end_op>
  return -1;
    80005aac:	557d                	li	a0,-1
}
    80005aae:	70ae                	ld	ra,232(sp)
    80005ab0:	740e                	ld	s0,224(sp)
    80005ab2:	64ee                	ld	s1,216(sp)
    80005ab4:	694e                	ld	s2,208(sp)
    80005ab6:	69ae                	ld	s3,200(sp)
    80005ab8:	616d                	addi	sp,sp,240
    80005aba:	8082                	ret

0000000080005abc <sys_open>:

uint64
sys_open(void)
{
    80005abc:	7131                	addi	sp,sp,-192
    80005abe:	fd06                	sd	ra,184(sp)
    80005ac0:	f922                	sd	s0,176(sp)
    80005ac2:	f526                	sd	s1,168(sp)
    80005ac4:	f14a                	sd	s2,160(sp)
    80005ac6:	ed4e                	sd	s3,152(sp)
    80005ac8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aca:	08000613          	li	a2,128
    80005ace:	f5040593          	addi	a1,s0,-176
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	348080e7          	jalr	840(ra) # 80002e1c <argstr>
    return -1;
    80005adc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ade:	0c054163          	bltz	a0,80005ba0 <sys_open+0xe4>
    80005ae2:	f4c40593          	addi	a1,s0,-180
    80005ae6:	4505                	li	a0,1
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	2f0080e7          	jalr	752(ra) # 80002dd8 <argint>
    80005af0:	0a054863          	bltz	a0,80005ba0 <sys_open+0xe4>

  begin_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	a1e080e7          	jalr	-1506(ra) # 80004512 <begin_op>

  if(omode & O_CREATE){
    80005afc:	f4c42783          	lw	a5,-180(s0)
    80005b00:	2007f793          	andi	a5,a5,512
    80005b04:	cbdd                	beqz	a5,80005bba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b06:	4681                	li	a3,0
    80005b08:	4601                	li	a2,0
    80005b0a:	4589                	li	a1,2
    80005b0c:	f5040513          	addi	a0,s0,-176
    80005b10:	00000097          	auipc	ra,0x0
    80005b14:	970080e7          	jalr	-1680(ra) # 80005480 <create>
    80005b18:	892a                	mv	s2,a0
    if(ip == 0){
    80005b1a:	c959                	beqz	a0,80005bb0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b1c:	04491703          	lh	a4,68(s2)
    80005b20:	478d                	li	a5,3
    80005b22:	00f71763          	bne	a4,a5,80005b30 <sys_open+0x74>
    80005b26:	04695703          	lhu	a4,70(s2)
    80005b2a:	47a5                	li	a5,9
    80005b2c:	0ce7ec63          	bltu	a5,a4,80005c04 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	dee080e7          	jalr	-530(ra) # 8000491e <filealloc>
    80005b38:	89aa                	mv	s3,a0
    80005b3a:	10050263          	beqz	a0,80005c3e <sys_open+0x182>
    80005b3e:	00000097          	auipc	ra,0x0
    80005b42:	900080e7          	jalr	-1792(ra) # 8000543e <fdalloc>
    80005b46:	84aa                	mv	s1,a0
    80005b48:	0e054663          	bltz	a0,80005c34 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b4c:	04491703          	lh	a4,68(s2)
    80005b50:	478d                	li	a5,3
    80005b52:	0cf70463          	beq	a4,a5,80005c1a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b56:	4789                	li	a5,2
    80005b58:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b5c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b60:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b64:	f4c42783          	lw	a5,-180(s0)
    80005b68:	0017c713          	xori	a4,a5,1
    80005b6c:	8b05                	andi	a4,a4,1
    80005b6e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b72:	0037f713          	andi	a4,a5,3
    80005b76:	00e03733          	snez	a4,a4
    80005b7a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b7e:	4007f793          	andi	a5,a5,1024
    80005b82:	c791                	beqz	a5,80005b8e <sys_open+0xd2>
    80005b84:	04491703          	lh	a4,68(s2)
    80005b88:	4789                	li	a5,2
    80005b8a:	08f70f63          	beq	a4,a5,80005c28 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b8e:	854a                	mv	a0,s2
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	068080e7          	jalr	104(ra) # 80003bf8 <iunlock>
  end_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	9f8080e7          	jalr	-1544(ra) # 80004590 <end_op>

  return fd;
}
    80005ba0:	8526                	mv	a0,s1
    80005ba2:	70ea                	ld	ra,184(sp)
    80005ba4:	744a                	ld	s0,176(sp)
    80005ba6:	74aa                	ld	s1,168(sp)
    80005ba8:	790a                	ld	s2,160(sp)
    80005baa:	69ea                	ld	s3,152(sp)
    80005bac:	6129                	addi	sp,sp,192
    80005bae:	8082                	ret
      end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	9e0080e7          	jalr	-1568(ra) # 80004590 <end_op>
      return -1;
    80005bb8:	b7e5                	j	80005ba0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bba:	f5040513          	addi	a0,s0,-176
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	734080e7          	jalr	1844(ra) # 800042f2 <namei>
    80005bc6:	892a                	mv	s2,a0
    80005bc8:	c905                	beqz	a0,80005bf8 <sys_open+0x13c>
    ilock(ip);
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	f6c080e7          	jalr	-148(ra) # 80003b36 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bd2:	04491703          	lh	a4,68(s2)
    80005bd6:	4785                	li	a5,1
    80005bd8:	f4f712e3          	bne	a4,a5,80005b1c <sys_open+0x60>
    80005bdc:	f4c42783          	lw	a5,-180(s0)
    80005be0:	dba1                	beqz	a5,80005b30 <sys_open+0x74>
      iunlockput(ip);
    80005be2:	854a                	mv	a0,s2
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	1b4080e7          	jalr	436(ra) # 80003d98 <iunlockput>
      end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	9a4080e7          	jalr	-1628(ra) # 80004590 <end_op>
      return -1;
    80005bf4:	54fd                	li	s1,-1
    80005bf6:	b76d                	j	80005ba0 <sys_open+0xe4>
      end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	998080e7          	jalr	-1640(ra) # 80004590 <end_op>
      return -1;
    80005c00:	54fd                	li	s1,-1
    80005c02:	bf79                	j	80005ba0 <sys_open+0xe4>
    iunlockput(ip);
    80005c04:	854a                	mv	a0,s2
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	192080e7          	jalr	402(ra) # 80003d98 <iunlockput>
    end_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	982080e7          	jalr	-1662(ra) # 80004590 <end_op>
    return -1;
    80005c16:	54fd                	li	s1,-1
    80005c18:	b761                	j	80005ba0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c1a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c1e:	04691783          	lh	a5,70(s2)
    80005c22:	02f99223          	sh	a5,36(s3)
    80005c26:	bf2d                	j	80005b60 <sys_open+0xa4>
    itrunc(ip);
    80005c28:	854a                	mv	a0,s2
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	01a080e7          	jalr	26(ra) # 80003c44 <itrunc>
    80005c32:	bfb1                	j	80005b8e <sys_open+0xd2>
      fileclose(f);
    80005c34:	854e                	mv	a0,s3
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	da4080e7          	jalr	-604(ra) # 800049da <fileclose>
    iunlockput(ip);
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	158080e7          	jalr	344(ra) # 80003d98 <iunlockput>
    end_op();
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	948080e7          	jalr	-1720(ra) # 80004590 <end_op>
    return -1;
    80005c50:	54fd                	li	s1,-1
    80005c52:	b7b9                	j	80005ba0 <sys_open+0xe4>

0000000080005c54 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c54:	7175                	addi	sp,sp,-144
    80005c56:	e506                	sd	ra,136(sp)
    80005c58:	e122                	sd	s0,128(sp)
    80005c5a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	8b6080e7          	jalr	-1866(ra) # 80004512 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c64:	08000613          	li	a2,128
    80005c68:	f7040593          	addi	a1,s0,-144
    80005c6c:	4501                	li	a0,0
    80005c6e:	ffffd097          	auipc	ra,0xffffd
    80005c72:	1ae080e7          	jalr	430(ra) # 80002e1c <argstr>
    80005c76:	02054963          	bltz	a0,80005ca8 <sys_mkdir+0x54>
    80005c7a:	4681                	li	a3,0
    80005c7c:	4601                	li	a2,0
    80005c7e:	4585                	li	a1,1
    80005c80:	f7040513          	addi	a0,s0,-144
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	7fc080e7          	jalr	2044(ra) # 80005480 <create>
    80005c8c:	cd11                	beqz	a0,80005ca8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	10a080e7          	jalr	266(ra) # 80003d98 <iunlockput>
  end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	8fa080e7          	jalr	-1798(ra) # 80004590 <end_op>
  return 0;
    80005c9e:	4501                	li	a0,0
}
    80005ca0:	60aa                	ld	ra,136(sp)
    80005ca2:	640a                	ld	s0,128(sp)
    80005ca4:	6149                	addi	sp,sp,144
    80005ca6:	8082                	ret
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	8e8080e7          	jalr	-1816(ra) # 80004590 <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	b7fd                	j	80005ca0 <sys_mkdir+0x4c>

0000000080005cb4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cb4:	7135                	addi	sp,sp,-160
    80005cb6:	ed06                	sd	ra,152(sp)
    80005cb8:	e922                	sd	s0,144(sp)
    80005cba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	856080e7          	jalr	-1962(ra) # 80004512 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cc4:	08000613          	li	a2,128
    80005cc8:	f7040593          	addi	a1,s0,-144
    80005ccc:	4501                	li	a0,0
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	14e080e7          	jalr	334(ra) # 80002e1c <argstr>
    80005cd6:	04054a63          	bltz	a0,80005d2a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cda:	f6c40593          	addi	a1,s0,-148
    80005cde:	4505                	li	a0,1
    80005ce0:	ffffd097          	auipc	ra,0xffffd
    80005ce4:	0f8080e7          	jalr	248(ra) # 80002dd8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ce8:	04054163          	bltz	a0,80005d2a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005cec:	f6840593          	addi	a1,s0,-152
    80005cf0:	4509                	li	a0,2
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	0e6080e7          	jalr	230(ra) # 80002dd8 <argint>
     argint(1, &major) < 0 ||
    80005cfa:	02054863          	bltz	a0,80005d2a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cfe:	f6841683          	lh	a3,-152(s0)
    80005d02:	f6c41603          	lh	a2,-148(s0)
    80005d06:	458d                	li	a1,3
    80005d08:	f7040513          	addi	a0,s0,-144
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	774080e7          	jalr	1908(ra) # 80005480 <create>
     argint(2, &minor) < 0 ||
    80005d14:	c919                	beqz	a0,80005d2a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	082080e7          	jalr	130(ra) # 80003d98 <iunlockput>
  end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	872080e7          	jalr	-1934(ra) # 80004590 <end_op>
  return 0;
    80005d26:	4501                	li	a0,0
    80005d28:	a031                	j	80005d34 <sys_mknod+0x80>
    end_op();
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	866080e7          	jalr	-1946(ra) # 80004590 <end_op>
    return -1;
    80005d32:	557d                	li	a0,-1
}
    80005d34:	60ea                	ld	ra,152(sp)
    80005d36:	644a                	ld	s0,144(sp)
    80005d38:	610d                	addi	sp,sp,160
    80005d3a:	8082                	ret

0000000080005d3c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d3c:	7135                	addi	sp,sp,-160
    80005d3e:	ed06                	sd	ra,152(sp)
    80005d40:	e922                	sd	s0,144(sp)
    80005d42:	e526                	sd	s1,136(sp)
    80005d44:	e14a                	sd	s2,128(sp)
    80005d46:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c4e080e7          	jalr	-946(ra) # 80001996 <myproc>
    80005d50:	892a                	mv	s2,a0
  
  begin_op();
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	7c0080e7          	jalr	1984(ra) # 80004512 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d5a:	08000613          	li	a2,128
    80005d5e:	f6040593          	addi	a1,s0,-160
    80005d62:	4501                	li	a0,0
    80005d64:	ffffd097          	auipc	ra,0xffffd
    80005d68:	0b8080e7          	jalr	184(ra) # 80002e1c <argstr>
    80005d6c:	04054b63          	bltz	a0,80005dc2 <sys_chdir+0x86>
    80005d70:	f6040513          	addi	a0,s0,-160
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	57e080e7          	jalr	1406(ra) # 800042f2 <namei>
    80005d7c:	84aa                	mv	s1,a0
    80005d7e:	c131                	beqz	a0,80005dc2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	db6080e7          	jalr	-586(ra) # 80003b36 <ilock>
  if(ip->type != T_DIR){
    80005d88:	04449703          	lh	a4,68(s1)
    80005d8c:	4785                	li	a5,1
    80005d8e:	04f71063          	bne	a4,a5,80005dce <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	e64080e7          	jalr	-412(ra) # 80003bf8 <iunlock>
  iput(p->cwd);
    80005d9c:	15093503          	ld	a0,336(s2)
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	f50080e7          	jalr	-176(ra) # 80003cf0 <iput>
  end_op();
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	7e8080e7          	jalr	2024(ra) # 80004590 <end_op>
  p->cwd = ip;
    80005db0:	14993823          	sd	s1,336(s2)
  return 0;
    80005db4:	4501                	li	a0,0
}
    80005db6:	60ea                	ld	ra,152(sp)
    80005db8:	644a                	ld	s0,144(sp)
    80005dba:	64aa                	ld	s1,136(sp)
    80005dbc:	690a                	ld	s2,128(sp)
    80005dbe:	610d                	addi	sp,sp,160
    80005dc0:	8082                	ret
    end_op();
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	7ce080e7          	jalr	1998(ra) # 80004590 <end_op>
    return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	b7ed                	j	80005db6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dce:	8526                	mv	a0,s1
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	fc8080e7          	jalr	-56(ra) # 80003d98 <iunlockput>
    end_op();
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	7b8080e7          	jalr	1976(ra) # 80004590 <end_op>
    return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	bfd1                	j	80005db6 <sys_chdir+0x7a>

0000000080005de4 <sys_exec>:

uint64
sys_exec(void)
{
    80005de4:	7145                	addi	sp,sp,-464
    80005de6:	e786                	sd	ra,456(sp)
    80005de8:	e3a2                	sd	s0,448(sp)
    80005dea:	ff26                	sd	s1,440(sp)
    80005dec:	fb4a                	sd	s2,432(sp)
    80005dee:	f74e                	sd	s3,424(sp)
    80005df0:	f352                	sd	s4,416(sp)
    80005df2:	ef56                	sd	s5,408(sp)
    80005df4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005df6:	08000613          	li	a2,128
    80005dfa:	f4040593          	addi	a1,s0,-192
    80005dfe:	4501                	li	a0,0
    80005e00:	ffffd097          	auipc	ra,0xffffd
    80005e04:	01c080e7          	jalr	28(ra) # 80002e1c <argstr>
    return -1;
    80005e08:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e0a:	0c054b63          	bltz	a0,80005ee0 <sys_exec+0xfc>
    80005e0e:	e3840593          	addi	a1,s0,-456
    80005e12:	4505                	li	a0,1
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	fe6080e7          	jalr	-26(ra) # 80002dfa <argaddr>
    80005e1c:	0c054263          	bltz	a0,80005ee0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e20:	10000613          	li	a2,256
    80005e24:	4581                	li	a1,0
    80005e26:	e4040513          	addi	a0,s0,-448
    80005e2a:	ffffb097          	auipc	ra,0xffffb
    80005e2e:	ea2080e7          	jalr	-350(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e32:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e36:	89a6                	mv	s3,s1
    80005e38:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e3a:	02000a13          	li	s4,32
    80005e3e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e42:	00391513          	slli	a0,s2,0x3
    80005e46:	e3040593          	addi	a1,s0,-464
    80005e4a:	e3843783          	ld	a5,-456(s0)
    80005e4e:	953e                	add	a0,a0,a5
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	eee080e7          	jalr	-274(ra) # 80002d3e <fetchaddr>
    80005e58:	02054a63          	bltz	a0,80005e8c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e5c:	e3043783          	ld	a5,-464(s0)
    80005e60:	c3b9                	beqz	a5,80005ea6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	c7e080e7          	jalr	-898(ra) # 80000ae0 <kalloc>
    80005e6a:	85aa                	mv	a1,a0
    80005e6c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e70:	cd11                	beqz	a0,80005e8c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e72:	6605                	lui	a2,0x1
    80005e74:	e3043503          	ld	a0,-464(s0)
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	f18080e7          	jalr	-232(ra) # 80002d90 <fetchstr>
    80005e80:	00054663          	bltz	a0,80005e8c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e84:	0905                	addi	s2,s2,1
    80005e86:	09a1                	addi	s3,s3,8
    80005e88:	fb491be3          	bne	s2,s4,80005e3e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e8c:	f4040913          	addi	s2,s0,-192
    80005e90:	6088                	ld	a0,0(s1)
    80005e92:	c531                	beqz	a0,80005ede <sys_exec+0xfa>
    kfree(argv[i]);
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	b4e080e7          	jalr	-1202(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e9c:	04a1                	addi	s1,s1,8
    80005e9e:	ff2499e3          	bne	s1,s2,80005e90 <sys_exec+0xac>
  return -1;
    80005ea2:	597d                	li	s2,-1
    80005ea4:	a835                	j	80005ee0 <sys_exec+0xfc>
      argv[i] = 0;
    80005ea6:	0a8e                	slli	s5,s5,0x3
    80005ea8:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd6fc0>
    80005eac:	00878ab3          	add	s5,a5,s0
    80005eb0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005eb4:	e4040593          	addi	a1,s0,-448
    80005eb8:	f4040513          	addi	a0,s0,-192
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	172080e7          	jalr	370(ra) # 8000502e <exec>
    80005ec4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec6:	f4040993          	addi	s3,s0,-192
    80005eca:	6088                	ld	a0,0(s1)
    80005ecc:	c911                	beqz	a0,80005ee0 <sys_exec+0xfc>
    kfree(argv[i]);
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	b14080e7          	jalr	-1260(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed6:	04a1                	addi	s1,s1,8
    80005ed8:	ff3499e3          	bne	s1,s3,80005eca <sys_exec+0xe6>
    80005edc:	a011                	j	80005ee0 <sys_exec+0xfc>
  return -1;
    80005ede:	597d                	li	s2,-1
}
    80005ee0:	854a                	mv	a0,s2
    80005ee2:	60be                	ld	ra,456(sp)
    80005ee4:	641e                	ld	s0,448(sp)
    80005ee6:	74fa                	ld	s1,440(sp)
    80005ee8:	795a                	ld	s2,432(sp)
    80005eea:	79ba                	ld	s3,424(sp)
    80005eec:	7a1a                	ld	s4,416(sp)
    80005eee:	6afa                	ld	s5,408(sp)
    80005ef0:	6179                	addi	sp,sp,464
    80005ef2:	8082                	ret

0000000080005ef4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ef4:	7139                	addi	sp,sp,-64
    80005ef6:	fc06                	sd	ra,56(sp)
    80005ef8:	f822                	sd	s0,48(sp)
    80005efa:	f426                	sd	s1,40(sp)
    80005efc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005efe:	ffffc097          	auipc	ra,0xffffc
    80005f02:	a98080e7          	jalr	-1384(ra) # 80001996 <myproc>
    80005f06:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f08:	fd840593          	addi	a1,s0,-40
    80005f0c:	4501                	li	a0,0
    80005f0e:	ffffd097          	auipc	ra,0xffffd
    80005f12:	eec080e7          	jalr	-276(ra) # 80002dfa <argaddr>
    return -1;
    80005f16:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f18:	0e054063          	bltz	a0,80005ff8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f1c:	fc840593          	addi	a1,s0,-56
    80005f20:	fd040513          	addi	a0,s0,-48
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	de6080e7          	jalr	-538(ra) # 80004d0a <pipealloc>
    return -1;
    80005f2c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f2e:	0c054563          	bltz	a0,80005ff8 <sys_pipe+0x104>
  fd0 = -1;
    80005f32:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f36:	fd043503          	ld	a0,-48(s0)
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	504080e7          	jalr	1284(ra) # 8000543e <fdalloc>
    80005f42:	fca42223          	sw	a0,-60(s0)
    80005f46:	08054c63          	bltz	a0,80005fde <sys_pipe+0xea>
    80005f4a:	fc843503          	ld	a0,-56(s0)
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	4f0080e7          	jalr	1264(ra) # 8000543e <fdalloc>
    80005f56:	fca42023          	sw	a0,-64(s0)
    80005f5a:	06054963          	bltz	a0,80005fcc <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f5e:	4691                	li	a3,4
    80005f60:	fc440613          	addi	a2,s0,-60
    80005f64:	fd843583          	ld	a1,-40(s0)
    80005f68:	68a8                	ld	a0,80(s1)
    80005f6a:	ffffb097          	auipc	ra,0xffffb
    80005f6e:	6f0080e7          	jalr	1776(ra) # 8000165a <copyout>
    80005f72:	02054063          	bltz	a0,80005f92 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f76:	4691                	li	a3,4
    80005f78:	fc040613          	addi	a2,s0,-64
    80005f7c:	fd843583          	ld	a1,-40(s0)
    80005f80:	0591                	addi	a1,a1,4
    80005f82:	68a8                	ld	a0,80(s1)
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	6d6080e7          	jalr	1750(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f8c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f8e:	06055563          	bgez	a0,80005ff8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f92:	fc442783          	lw	a5,-60(s0)
    80005f96:	07e9                	addi	a5,a5,26
    80005f98:	078e                	slli	a5,a5,0x3
    80005f9a:	97a6                	add	a5,a5,s1
    80005f9c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fa0:	fc042783          	lw	a5,-64(s0)
    80005fa4:	07e9                	addi	a5,a5,26
    80005fa6:	078e                	slli	a5,a5,0x3
    80005fa8:	00f48533          	add	a0,s1,a5
    80005fac:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fb0:	fd043503          	ld	a0,-48(s0)
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	a26080e7          	jalr	-1498(ra) # 800049da <fileclose>
    fileclose(wf);
    80005fbc:	fc843503          	ld	a0,-56(s0)
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	a1a080e7          	jalr	-1510(ra) # 800049da <fileclose>
    return -1;
    80005fc8:	57fd                	li	a5,-1
    80005fca:	a03d                	j	80005ff8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fcc:	fc442783          	lw	a5,-60(s0)
    80005fd0:	0007c763          	bltz	a5,80005fde <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005fd4:	07e9                	addi	a5,a5,26
    80005fd6:	078e                	slli	a5,a5,0x3
    80005fd8:	97a6                	add	a5,a5,s1
    80005fda:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005fde:	fd043503          	ld	a0,-48(s0)
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	9f8080e7          	jalr	-1544(ra) # 800049da <fileclose>
    fileclose(wf);
    80005fea:	fc843503          	ld	a0,-56(s0)
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	9ec080e7          	jalr	-1556(ra) # 800049da <fileclose>
    return -1;
    80005ff6:	57fd                	li	a5,-1
}
    80005ff8:	853e                	mv	a0,a5
    80005ffa:	70e2                	ld	ra,56(sp)
    80005ffc:	7442                	ld	s0,48(sp)
    80005ffe:	74a2                	ld	s1,40(sp)
    80006000:	6121                	addi	sp,sp,64
    80006002:	8082                	ret
	...

0000000080006010 <kernelvec>:
    80006010:	7111                	addi	sp,sp,-256
    80006012:	e006                	sd	ra,0(sp)
    80006014:	e40a                	sd	sp,8(sp)
    80006016:	e80e                	sd	gp,16(sp)
    80006018:	ec12                	sd	tp,24(sp)
    8000601a:	f016                	sd	t0,32(sp)
    8000601c:	f41a                	sd	t1,40(sp)
    8000601e:	f81e                	sd	t2,48(sp)
    80006020:	fc22                	sd	s0,56(sp)
    80006022:	e0a6                	sd	s1,64(sp)
    80006024:	e4aa                	sd	a0,72(sp)
    80006026:	e8ae                	sd	a1,80(sp)
    80006028:	ecb2                	sd	a2,88(sp)
    8000602a:	f0b6                	sd	a3,96(sp)
    8000602c:	f4ba                	sd	a4,104(sp)
    8000602e:	f8be                	sd	a5,112(sp)
    80006030:	fcc2                	sd	a6,120(sp)
    80006032:	e146                	sd	a7,128(sp)
    80006034:	e54a                	sd	s2,136(sp)
    80006036:	e94e                	sd	s3,144(sp)
    80006038:	ed52                	sd	s4,152(sp)
    8000603a:	f156                	sd	s5,160(sp)
    8000603c:	f55a                	sd	s6,168(sp)
    8000603e:	f95e                	sd	s7,176(sp)
    80006040:	fd62                	sd	s8,184(sp)
    80006042:	e1e6                	sd	s9,192(sp)
    80006044:	e5ea                	sd	s10,200(sp)
    80006046:	e9ee                	sd	s11,208(sp)
    80006048:	edf2                	sd	t3,216(sp)
    8000604a:	f1f6                	sd	t4,224(sp)
    8000604c:	f5fa                	sd	t5,232(sp)
    8000604e:	f9fe                	sd	t6,240(sp)
    80006050:	bbbfc0ef          	jal	ra,80002c0a <kerneltrap>
    80006054:	6082                	ld	ra,0(sp)
    80006056:	6122                	ld	sp,8(sp)
    80006058:	61c2                	ld	gp,16(sp)
    8000605a:	7282                	ld	t0,32(sp)
    8000605c:	7322                	ld	t1,40(sp)
    8000605e:	73c2                	ld	t2,48(sp)
    80006060:	7462                	ld	s0,56(sp)
    80006062:	6486                	ld	s1,64(sp)
    80006064:	6526                	ld	a0,72(sp)
    80006066:	65c6                	ld	a1,80(sp)
    80006068:	6666                	ld	a2,88(sp)
    8000606a:	7686                	ld	a3,96(sp)
    8000606c:	7726                	ld	a4,104(sp)
    8000606e:	77c6                	ld	a5,112(sp)
    80006070:	7866                	ld	a6,120(sp)
    80006072:	688a                	ld	a7,128(sp)
    80006074:	692a                	ld	s2,136(sp)
    80006076:	69ca                	ld	s3,144(sp)
    80006078:	6a6a                	ld	s4,152(sp)
    8000607a:	7a8a                	ld	s5,160(sp)
    8000607c:	7b2a                	ld	s6,168(sp)
    8000607e:	7bca                	ld	s7,176(sp)
    80006080:	7c6a                	ld	s8,184(sp)
    80006082:	6c8e                	ld	s9,192(sp)
    80006084:	6d2e                	ld	s10,200(sp)
    80006086:	6dce                	ld	s11,208(sp)
    80006088:	6e6e                	ld	t3,216(sp)
    8000608a:	7e8e                	ld	t4,224(sp)
    8000608c:	7f2e                	ld	t5,232(sp)
    8000608e:	7fce                	ld	t6,240(sp)
    80006090:	6111                	addi	sp,sp,256
    80006092:	10200073          	sret
    80006096:	00000013          	nop
    8000609a:	00000013          	nop
    8000609e:	0001                	nop

00000000800060a0 <timervec>:
    800060a0:	34051573          	csrrw	a0,mscratch,a0
    800060a4:	e10c                	sd	a1,0(a0)
    800060a6:	e510                	sd	a2,8(a0)
    800060a8:	e914                	sd	a3,16(a0)
    800060aa:	6d0c                	ld	a1,24(a0)
    800060ac:	7110                	ld	a2,32(a0)
    800060ae:	6194                	ld	a3,0(a1)
    800060b0:	96b2                	add	a3,a3,a2
    800060b2:	e194                	sd	a3,0(a1)
    800060b4:	4589                	li	a1,2
    800060b6:	14459073          	csrw	sip,a1
    800060ba:	6914                	ld	a3,16(a0)
    800060bc:	6510                	ld	a2,8(a0)
    800060be:	610c                	ld	a1,0(a0)
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	30200073          	mret
	...

00000000800060ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ca:	1141                	addi	sp,sp,-16
    800060cc:	e422                	sd	s0,8(sp)
    800060ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060d0:	0c0007b7          	lui	a5,0xc000
    800060d4:	4705                	li	a4,1
    800060d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060d8:	c3d8                	sw	a4,4(a5)
}
    800060da:	6422                	ld	s0,8(sp)
    800060dc:	0141                	addi	sp,sp,16
    800060de:	8082                	ret

00000000800060e0 <plicinithart>:

void
plicinithart(void)
{
    800060e0:	1141                	addi	sp,sp,-16
    800060e2:	e406                	sd	ra,8(sp)
    800060e4:	e022                	sd	s0,0(sp)
    800060e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	882080e7          	jalr	-1918(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060f0:	0085171b          	slliw	a4,a0,0x8
    800060f4:	0c0027b7          	lui	a5,0xc002
    800060f8:	97ba                	add	a5,a5,a4
    800060fa:	40200713          	li	a4,1026
    800060fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006102:	00d5151b          	slliw	a0,a0,0xd
    80006106:	0c2017b7          	lui	a5,0xc201
    8000610a:	97aa                	add	a5,a5,a0
    8000610c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006110:	60a2                	ld	ra,8(sp)
    80006112:	6402                	ld	s0,0(sp)
    80006114:	0141                	addi	sp,sp,16
    80006116:	8082                	ret

0000000080006118 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006118:	1141                	addi	sp,sp,-16
    8000611a:	e406                	sd	ra,8(sp)
    8000611c:	e022                	sd	s0,0(sp)
    8000611e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006120:	ffffc097          	auipc	ra,0xffffc
    80006124:	84a080e7          	jalr	-1974(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006128:	00d5151b          	slliw	a0,a0,0xd
    8000612c:	0c2017b7          	lui	a5,0xc201
    80006130:	97aa                	add	a5,a5,a0
  return irq;
}
    80006132:	43c8                	lw	a0,4(a5)
    80006134:	60a2                	ld	ra,8(sp)
    80006136:	6402                	ld	s0,0(sp)
    80006138:	0141                	addi	sp,sp,16
    8000613a:	8082                	ret

000000008000613c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000613c:	1101                	addi	sp,sp,-32
    8000613e:	ec06                	sd	ra,24(sp)
    80006140:	e822                	sd	s0,16(sp)
    80006142:	e426                	sd	s1,8(sp)
    80006144:	1000                	addi	s0,sp,32
    80006146:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	822080e7          	jalr	-2014(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006150:	00d5151b          	slliw	a0,a0,0xd
    80006154:	0c2017b7          	lui	a5,0xc201
    80006158:	97aa                	add	a5,a5,a0
    8000615a:	c3c4                	sw	s1,4(a5)
}
    8000615c:	60e2                	ld	ra,24(sp)
    8000615e:	6442                	ld	s0,16(sp)
    80006160:	64a2                	ld	s1,8(sp)
    80006162:	6105                	addi	sp,sp,32
    80006164:	8082                	ret

0000000080006166 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006166:	1141                	addi	sp,sp,-16
    80006168:	e406                	sd	ra,8(sp)
    8000616a:	e022                	sd	s0,0(sp)
    8000616c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000616e:	479d                	li	a5,7
    80006170:	06a7c863          	blt	a5,a0,800061e0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006174:	0001f717          	auipc	a4,0x1f
    80006178:	e8c70713          	addi	a4,a4,-372 # 80025000 <disk>
    8000617c:	972a                	add	a4,a4,a0
    8000617e:	6789                	lui	a5,0x2
    80006180:	97ba                	add	a5,a5,a4
    80006182:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006186:	e7ad                	bnez	a5,800061f0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006188:	00451793          	slli	a5,a0,0x4
    8000618c:	00021717          	auipc	a4,0x21
    80006190:	e7470713          	addi	a4,a4,-396 # 80027000 <disk+0x2000>
    80006194:	6314                	ld	a3,0(a4)
    80006196:	96be                	add	a3,a3,a5
    80006198:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000619c:	6314                	ld	a3,0(a4)
    8000619e:	96be                	add	a3,a3,a5
    800061a0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061a4:	6314                	ld	a3,0(a4)
    800061a6:	96be                	add	a3,a3,a5
    800061a8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ac:	6318                	ld	a4,0(a4)
    800061ae:	97ba                	add	a5,a5,a4
    800061b0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061b4:	0001f717          	auipc	a4,0x1f
    800061b8:	e4c70713          	addi	a4,a4,-436 # 80025000 <disk>
    800061bc:	972a                	add	a4,a4,a0
    800061be:	6789                	lui	a5,0x2
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	4705                	li	a4,1
    800061c4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061c8:	00021517          	auipc	a0,0x21
    800061cc:	e5050513          	addi	a0,a0,-432 # 80027018 <disk+0x2018>
    800061d0:	ffffc097          	auipc	ra,0xffffc
    800061d4:	37a080e7          	jalr	890(ra) # 8000254a <wakeup>
}
    800061d8:	60a2                	ld	ra,8(sp)
    800061da:	6402                	ld	s0,0(sp)
    800061dc:	0141                	addi	sp,sp,16
    800061de:	8082                	ret
    panic("free_desc 1");
    800061e0:	00002517          	auipc	a0,0x2
    800061e4:	7c050513          	addi	a0,a0,1984 # 800089a0 <syscallargs+0x2d0>
    800061e8:	ffffa097          	auipc	ra,0xffffa
    800061ec:	352080e7          	jalr	850(ra) # 8000053a <panic>
    panic("free_desc 2");
    800061f0:	00002517          	auipc	a0,0x2
    800061f4:	7c050513          	addi	a0,a0,1984 # 800089b0 <syscallargs+0x2e0>
    800061f8:	ffffa097          	auipc	ra,0xffffa
    800061fc:	342080e7          	jalr	834(ra) # 8000053a <panic>

0000000080006200 <virtio_disk_init>:
{
    80006200:	1101                	addi	sp,sp,-32
    80006202:	ec06                	sd	ra,24(sp)
    80006204:	e822                	sd	s0,16(sp)
    80006206:	e426                	sd	s1,8(sp)
    80006208:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000620a:	00002597          	auipc	a1,0x2
    8000620e:	7b658593          	addi	a1,a1,1974 # 800089c0 <syscallargs+0x2f0>
    80006212:	00021517          	auipc	a0,0x21
    80006216:	f1650513          	addi	a0,a0,-234 # 80027128 <disk+0x2128>
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	926080e7          	jalr	-1754(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006222:	100017b7          	lui	a5,0x10001
    80006226:	4398                	lw	a4,0(a5)
    80006228:	2701                	sext.w	a4,a4
    8000622a:	747277b7          	lui	a5,0x74727
    8000622e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006232:	0ef71063          	bne	a4,a5,80006312 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006236:	100017b7          	lui	a5,0x10001
    8000623a:	43dc                	lw	a5,4(a5)
    8000623c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000623e:	4705                	li	a4,1
    80006240:	0ce79963          	bne	a5,a4,80006312 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006244:	100017b7          	lui	a5,0x10001
    80006248:	479c                	lw	a5,8(a5)
    8000624a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000624c:	4709                	li	a4,2
    8000624e:	0ce79263          	bne	a5,a4,80006312 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006252:	100017b7          	lui	a5,0x10001
    80006256:	47d8                	lw	a4,12(a5)
    80006258:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000625a:	554d47b7          	lui	a5,0x554d4
    8000625e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006262:	0af71863          	bne	a4,a5,80006312 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006266:	100017b7          	lui	a5,0x10001
    8000626a:	4705                	li	a4,1
    8000626c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000626e:	470d                	li	a4,3
    80006270:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006272:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006274:	c7ffe6b7          	lui	a3,0xc7ffe
    80006278:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    8000627c:	8f75                	and	a4,a4,a3
    8000627e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006280:	472d                	li	a4,11
    80006282:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006284:	473d                	li	a4,15
    80006286:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006288:	6705                	lui	a4,0x1
    8000628a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000628c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006290:	5bdc                	lw	a5,52(a5)
    80006292:	2781                	sext.w	a5,a5
  if(max == 0)
    80006294:	c7d9                	beqz	a5,80006322 <virtio_disk_init+0x122>
  if(max < NUM)
    80006296:	471d                	li	a4,7
    80006298:	08f77d63          	bgeu	a4,a5,80006332 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000629c:	100014b7          	lui	s1,0x10001
    800062a0:	47a1                	li	a5,8
    800062a2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062a4:	6609                	lui	a2,0x2
    800062a6:	4581                	li	a1,0
    800062a8:	0001f517          	auipc	a0,0x1f
    800062ac:	d5850513          	addi	a0,a0,-680 # 80025000 <disk>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a1c080e7          	jalr	-1508(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062b8:	0001f717          	auipc	a4,0x1f
    800062bc:	d4870713          	addi	a4,a4,-696 # 80025000 <disk>
    800062c0:	00c75793          	srli	a5,a4,0xc
    800062c4:	2781                	sext.w	a5,a5
    800062c6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062c8:	00021797          	auipc	a5,0x21
    800062cc:	d3878793          	addi	a5,a5,-712 # 80027000 <disk+0x2000>
    800062d0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062d2:	0001f717          	auipc	a4,0x1f
    800062d6:	dae70713          	addi	a4,a4,-594 # 80025080 <disk+0x80>
    800062da:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062dc:	00020717          	auipc	a4,0x20
    800062e0:	d2470713          	addi	a4,a4,-732 # 80026000 <disk+0x1000>
    800062e4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062e6:	4705                	li	a4,1
    800062e8:	00e78c23          	sb	a4,24(a5)
    800062ec:	00e78ca3          	sb	a4,25(a5)
    800062f0:	00e78d23          	sb	a4,26(a5)
    800062f4:	00e78da3          	sb	a4,27(a5)
    800062f8:	00e78e23          	sb	a4,28(a5)
    800062fc:	00e78ea3          	sb	a4,29(a5)
    80006300:	00e78f23          	sb	a4,30(a5)
    80006304:	00e78fa3          	sb	a4,31(a5)
}
    80006308:	60e2                	ld	ra,24(sp)
    8000630a:	6442                	ld	s0,16(sp)
    8000630c:	64a2                	ld	s1,8(sp)
    8000630e:	6105                	addi	sp,sp,32
    80006310:	8082                	ret
    panic("could not find virtio disk");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	6be50513          	addi	a0,a0,1726 # 800089d0 <syscallargs+0x300>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	220080e7          	jalr	544(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	6ce50513          	addi	a0,a0,1742 # 800089f0 <syscallargs+0x320>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	210080e7          	jalr	528(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	6de50513          	addi	a0,a0,1758 # 80008a10 <syscallargs+0x340>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	200080e7          	jalr	512(ra) # 8000053a <panic>

0000000080006342 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006342:	7119                	addi	sp,sp,-128
    80006344:	fc86                	sd	ra,120(sp)
    80006346:	f8a2                	sd	s0,112(sp)
    80006348:	f4a6                	sd	s1,104(sp)
    8000634a:	f0ca                	sd	s2,96(sp)
    8000634c:	ecce                	sd	s3,88(sp)
    8000634e:	e8d2                	sd	s4,80(sp)
    80006350:	e4d6                	sd	s5,72(sp)
    80006352:	e0da                	sd	s6,64(sp)
    80006354:	fc5e                	sd	s7,56(sp)
    80006356:	f862                	sd	s8,48(sp)
    80006358:	f466                	sd	s9,40(sp)
    8000635a:	f06a                	sd	s10,32(sp)
    8000635c:	ec6e                	sd	s11,24(sp)
    8000635e:	0100                	addi	s0,sp,128
    80006360:	8aaa                	mv	s5,a0
    80006362:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006364:	00c52c83          	lw	s9,12(a0)
    80006368:	001c9c9b          	slliw	s9,s9,0x1
    8000636c:	1c82                	slli	s9,s9,0x20
    8000636e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006372:	00021517          	auipc	a0,0x21
    80006376:	db650513          	addi	a0,a0,-586 # 80027128 <disk+0x2128>
    8000637a:	ffffb097          	auipc	ra,0xffffb
    8000637e:	856080e7          	jalr	-1962(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006382:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006384:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006386:	0001fc17          	auipc	s8,0x1f
    8000638a:	c7ac0c13          	addi	s8,s8,-902 # 80025000 <disk>
    8000638e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006390:	4b0d                	li	s6,3
    80006392:	a0ad                	j	800063fc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006394:	00fc0733          	add	a4,s8,a5
    80006398:	975e                	add	a4,a4,s7
    8000639a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000639e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063a0:	0207c563          	bltz	a5,800063ca <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063a4:	2905                	addiw	s2,s2,1
    800063a6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800063a8:	19690c63          	beq	s2,s6,80006540 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800063ac:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063ae:	00021717          	auipc	a4,0x21
    800063b2:	c6a70713          	addi	a4,a4,-918 # 80027018 <disk+0x2018>
    800063b6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063b8:	00074683          	lbu	a3,0(a4)
    800063bc:	fee1                	bnez	a3,80006394 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063be:	2785                	addiw	a5,a5,1
    800063c0:	0705                	addi	a4,a4,1
    800063c2:	fe979be3          	bne	a5,s1,800063b8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063c6:	57fd                	li	a5,-1
    800063c8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063ca:	01205d63          	blez	s2,800063e4 <virtio_disk_rw+0xa2>
    800063ce:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063d0:	000a2503          	lw	a0,0(s4)
    800063d4:	00000097          	auipc	ra,0x0
    800063d8:	d92080e7          	jalr	-622(ra) # 80006166 <free_desc>
      for(int j = 0; j < i; j++)
    800063dc:	2d85                	addiw	s11,s11,1
    800063de:	0a11                	addi	s4,s4,4
    800063e0:	ff2d98e3          	bne	s11,s2,800063d0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063e4:	00021597          	auipc	a1,0x21
    800063e8:	d4458593          	addi	a1,a1,-700 # 80027128 <disk+0x2128>
    800063ec:	00021517          	auipc	a0,0x21
    800063f0:	c2c50513          	addi	a0,a0,-980 # 80027018 <disk+0x2018>
    800063f4:	ffffc097          	auipc	ra,0xffffc
    800063f8:	e72080e7          	jalr	-398(ra) # 80002266 <sleep>
  for(int i = 0; i < 3; i++){
    800063fc:	f8040a13          	addi	s4,s0,-128
{
    80006400:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006402:	894e                	mv	s2,s3
    80006404:	b765                	j	800063ac <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006406:	00021697          	auipc	a3,0x21
    8000640a:	bfa6b683          	ld	a3,-1030(a3) # 80027000 <disk+0x2000>
    8000640e:	96ba                	add	a3,a3,a4
    80006410:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006414:	0001f817          	auipc	a6,0x1f
    80006418:	bec80813          	addi	a6,a6,-1044 # 80025000 <disk>
    8000641c:	00021697          	auipc	a3,0x21
    80006420:	be468693          	addi	a3,a3,-1052 # 80027000 <disk+0x2000>
    80006424:	6290                	ld	a2,0(a3)
    80006426:	963a                	add	a2,a2,a4
    80006428:	00c65583          	lhu	a1,12(a2)
    8000642c:	0015e593          	ori	a1,a1,1
    80006430:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006434:	f8842603          	lw	a2,-120(s0)
    80006438:	628c                	ld	a1,0(a3)
    8000643a:	972e                	add	a4,a4,a1
    8000643c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006440:	20050593          	addi	a1,a0,512
    80006444:	0592                	slli	a1,a1,0x4
    80006446:	95c2                	add	a1,a1,a6
    80006448:	577d                	li	a4,-1
    8000644a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000644e:	00461713          	slli	a4,a2,0x4
    80006452:	6290                	ld	a2,0(a3)
    80006454:	963a                	add	a2,a2,a4
    80006456:	03078793          	addi	a5,a5,48
    8000645a:	97c2                	add	a5,a5,a6
    8000645c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000645e:	629c                	ld	a5,0(a3)
    80006460:	97ba                	add	a5,a5,a4
    80006462:	4605                	li	a2,1
    80006464:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006466:	629c                	ld	a5,0(a3)
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	4809                	li	a6,2
    8000646c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006470:	629c                	ld	a5,0(a3)
    80006472:	97ba                	add	a5,a5,a4
    80006474:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006478:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000647c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006480:	6698                	ld	a4,8(a3)
    80006482:	00275783          	lhu	a5,2(a4)
    80006486:	8b9d                	andi	a5,a5,7
    80006488:	0786                	slli	a5,a5,0x1
    8000648a:	973e                	add	a4,a4,a5
    8000648c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006490:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006494:	6698                	ld	a4,8(a3)
    80006496:	00275783          	lhu	a5,2(a4)
    8000649a:	2785                	addiw	a5,a5,1
    8000649c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064a0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064a4:	100017b7          	lui	a5,0x10001
    800064a8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064ac:	004aa783          	lw	a5,4(s5)
    800064b0:	02c79163          	bne	a5,a2,800064d2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800064b4:	00021917          	auipc	s2,0x21
    800064b8:	c7490913          	addi	s2,s2,-908 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800064bc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064be:	85ca                	mv	a1,s2
    800064c0:	8556                	mv	a0,s5
    800064c2:	ffffc097          	auipc	ra,0xffffc
    800064c6:	da4080e7          	jalr	-604(ra) # 80002266 <sleep>
  while(b->disk == 1) {
    800064ca:	004aa783          	lw	a5,4(s5)
    800064ce:	fe9788e3          	beq	a5,s1,800064be <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800064d2:	f8042903          	lw	s2,-128(s0)
    800064d6:	20090713          	addi	a4,s2,512
    800064da:	0712                	slli	a4,a4,0x4
    800064dc:	0001f797          	auipc	a5,0x1f
    800064e0:	b2478793          	addi	a5,a5,-1244 # 80025000 <disk>
    800064e4:	97ba                	add	a5,a5,a4
    800064e6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064ea:	00021997          	auipc	s3,0x21
    800064ee:	b1698993          	addi	s3,s3,-1258 # 80027000 <disk+0x2000>
    800064f2:	00491713          	slli	a4,s2,0x4
    800064f6:	0009b783          	ld	a5,0(s3)
    800064fa:	97ba                	add	a5,a5,a4
    800064fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006500:	854a                	mv	a0,s2
    80006502:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006506:	00000097          	auipc	ra,0x0
    8000650a:	c60080e7          	jalr	-928(ra) # 80006166 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000650e:	8885                	andi	s1,s1,1
    80006510:	f0ed                	bnez	s1,800064f2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006512:	00021517          	auipc	a0,0x21
    80006516:	c1650513          	addi	a0,a0,-1002 # 80027128 <disk+0x2128>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	76a080e7          	jalr	1898(ra) # 80000c84 <release>
}
    80006522:	70e6                	ld	ra,120(sp)
    80006524:	7446                	ld	s0,112(sp)
    80006526:	74a6                	ld	s1,104(sp)
    80006528:	7906                	ld	s2,96(sp)
    8000652a:	69e6                	ld	s3,88(sp)
    8000652c:	6a46                	ld	s4,80(sp)
    8000652e:	6aa6                	ld	s5,72(sp)
    80006530:	6b06                	ld	s6,64(sp)
    80006532:	7be2                	ld	s7,56(sp)
    80006534:	7c42                	ld	s8,48(sp)
    80006536:	7ca2                	ld	s9,40(sp)
    80006538:	7d02                	ld	s10,32(sp)
    8000653a:	6de2                	ld	s11,24(sp)
    8000653c:	6109                	addi	sp,sp,128
    8000653e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006540:	f8042503          	lw	a0,-128(s0)
    80006544:	20050793          	addi	a5,a0,512
    80006548:	0792                	slli	a5,a5,0x4
  if(write)
    8000654a:	0001f817          	auipc	a6,0x1f
    8000654e:	ab680813          	addi	a6,a6,-1354 # 80025000 <disk>
    80006552:	00f80733          	add	a4,a6,a5
    80006556:	01a036b3          	snez	a3,s10
    8000655a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000655e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006562:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006566:	7679                	lui	a2,0xffffe
    80006568:	963e                	add	a2,a2,a5
    8000656a:	00021697          	auipc	a3,0x21
    8000656e:	a9668693          	addi	a3,a3,-1386 # 80027000 <disk+0x2000>
    80006572:	6298                	ld	a4,0(a3)
    80006574:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006576:	0a878593          	addi	a1,a5,168
    8000657a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000657c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000657e:	6298                	ld	a4,0(a3)
    80006580:	9732                	add	a4,a4,a2
    80006582:	45c1                	li	a1,16
    80006584:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006586:	6298                	ld	a4,0(a3)
    80006588:	9732                	add	a4,a4,a2
    8000658a:	4585                	li	a1,1
    8000658c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006590:	f8442703          	lw	a4,-124(s0)
    80006594:	628c                	ld	a1,0(a3)
    80006596:	962e                	add	a2,a2,a1
    80006598:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000659c:	0712                	slli	a4,a4,0x4
    8000659e:	6290                	ld	a2,0(a3)
    800065a0:	963a                	add	a2,a2,a4
    800065a2:	058a8593          	addi	a1,s5,88
    800065a6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065a8:	6294                	ld	a3,0(a3)
    800065aa:	96ba                	add	a3,a3,a4
    800065ac:	40000613          	li	a2,1024
    800065b0:	c690                	sw	a2,8(a3)
  if(write)
    800065b2:	e40d1ae3          	bnez	s10,80006406 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065b6:	00021697          	auipc	a3,0x21
    800065ba:	a4a6b683          	ld	a3,-1462(a3) # 80027000 <disk+0x2000>
    800065be:	96ba                	add	a3,a3,a4
    800065c0:	4609                	li	a2,2
    800065c2:	00c69623          	sh	a2,12(a3)
    800065c6:	b5b9                	j	80006414 <virtio_disk_rw+0xd2>

00000000800065c8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065c8:	1101                	addi	sp,sp,-32
    800065ca:	ec06                	sd	ra,24(sp)
    800065cc:	e822                	sd	s0,16(sp)
    800065ce:	e426                	sd	s1,8(sp)
    800065d0:	e04a                	sd	s2,0(sp)
    800065d2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065d4:	00021517          	auipc	a0,0x21
    800065d8:	b5450513          	addi	a0,a0,-1196 # 80027128 <disk+0x2128>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	5f4080e7          	jalr	1524(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065e4:	10001737          	lui	a4,0x10001
    800065e8:	533c                	lw	a5,96(a4)
    800065ea:	8b8d                	andi	a5,a5,3
    800065ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065f2:	00021797          	auipc	a5,0x21
    800065f6:	a0e78793          	addi	a5,a5,-1522 # 80027000 <disk+0x2000>
    800065fa:	6b94                	ld	a3,16(a5)
    800065fc:	0207d703          	lhu	a4,32(a5)
    80006600:	0026d783          	lhu	a5,2(a3)
    80006604:	06f70163          	beq	a4,a5,80006666 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006608:	0001f917          	auipc	s2,0x1f
    8000660c:	9f890913          	addi	s2,s2,-1544 # 80025000 <disk>
    80006610:	00021497          	auipc	s1,0x21
    80006614:	9f048493          	addi	s1,s1,-1552 # 80027000 <disk+0x2000>
    __sync_synchronize();
    80006618:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000661c:	6898                	ld	a4,16(s1)
    8000661e:	0204d783          	lhu	a5,32(s1)
    80006622:	8b9d                	andi	a5,a5,7
    80006624:	078e                	slli	a5,a5,0x3
    80006626:	97ba                	add	a5,a5,a4
    80006628:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000662a:	20078713          	addi	a4,a5,512
    8000662e:	0712                	slli	a4,a4,0x4
    80006630:	974a                	add	a4,a4,s2
    80006632:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006636:	e731                	bnez	a4,80006682 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006638:	20078793          	addi	a5,a5,512
    8000663c:	0792                	slli	a5,a5,0x4
    8000663e:	97ca                	add	a5,a5,s2
    80006640:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006642:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006646:	ffffc097          	auipc	ra,0xffffc
    8000664a:	f04080e7          	jalr	-252(ra) # 8000254a <wakeup>

    disk.used_idx += 1;
    8000664e:	0204d783          	lhu	a5,32(s1)
    80006652:	2785                	addiw	a5,a5,1
    80006654:	17c2                	slli	a5,a5,0x30
    80006656:	93c1                	srli	a5,a5,0x30
    80006658:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000665c:	6898                	ld	a4,16(s1)
    8000665e:	00275703          	lhu	a4,2(a4)
    80006662:	faf71be3          	bne	a4,a5,80006618 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006666:	00021517          	auipc	a0,0x21
    8000666a:	ac250513          	addi	a0,a0,-1342 # 80027128 <disk+0x2128>
    8000666e:	ffffa097          	auipc	ra,0xffffa
    80006672:	616080e7          	jalr	1558(ra) # 80000c84 <release>
}
    80006676:	60e2                	ld	ra,24(sp)
    80006678:	6442                	ld	s0,16(sp)
    8000667a:	64a2                	ld	s1,8(sp)
    8000667c:	6902                	ld	s2,0(sp)
    8000667e:	6105                	addi	sp,sp,32
    80006680:	8082                	ret
      panic("virtio_disk_intr status");
    80006682:	00002517          	auipc	a0,0x2
    80006686:	3ae50513          	addi	a0,a0,942 # 80008a30 <syscallargs+0x360>
    8000668a:	ffffa097          	auipc	ra,0xffffa
    8000668e:	eb0080e7          	jalr	-336(ra) # 8000053a <panic>
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
