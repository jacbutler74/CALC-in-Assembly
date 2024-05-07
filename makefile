z.exe: z.o
	ld z.o -o z.exe

z.o: calc.asm
	sudo nasm -f elf64 calc.asm -o z.o

run:
	./z.exe

clean:
	rm -f z.exe
	rm -f z.o