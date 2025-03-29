#include <utils.h>
#include <elf.h>

#ifdef CONFIG_FTRACE
typedef Elf32_Ehdr Elf_Ehdr;	
typedef Elf32_Shdr Elf_Shdr;	
typedef Elf32_Sym Elf_Sym;	

Elf_Ehdr Ehdr;
Elf_Shdr *Shdrs;
Elf_Sym *Symtab;
char* Strtab;
int32_t SymtabCnt;
char* SpaceCnt;
#endif

char* ftrace(word_t);

static int ftrace_table_sta = 0;
void FTrace_init(char* fileStr){
	if(fileStr == NULL)
		return;
#ifdef CONFIG_FTRACE
	SpaceCnt = malloc(sizeof(char) * 1024);
	SpaceCnt[0] = '\0';

	FILE *fp = fopen(fileStr, "rb");
	Assert(fp, "Error Opening Elf file.");

	size_t ret = fread(&Ehdr, sizeof(Ehdr), 1, fp);
	Assert(ret == 1, "Elf header table read Error.");


	//printf("%#04x %c %c %c\n", Ehdr.e_ident[0],Ehdr.e_ident[1],Ehdr.e_ident[2],Ehdr.e_ident[3]);
	//printf("soff : 0x%4x\n", Ehdr.e_shoff);
	//printf("shentsize : 0x%4x\n", Ehdr.e_shentsize);

	rewind(fp);
	char* trash = malloc(Ehdr.e_shoff + 5);
	ret =	fread(trash, sizeof(char), Ehdr.e_shoff, fp);
	Assert(ret == Ehdr.e_shoff, "Moving fp to shoff Error.");

	Shdrs = calloc(Ehdr.e_shnum, Ehdr.e_shentsize);
	ret = fread(Shdrs, Ehdr.e_shentsize, Ehdr.e_shnum, fp);
	Assert(ret == Ehdr.e_shnum, "Section Headers table entry num Reading Error");


	for(uint32_t i = 0; i < Ehdr.e_shnum; i++) {
		if(Shdrs[i].sh_type == SHT_SYMTAB){
			Symtab = malloc(Shdrs[i].sh_size);
			SymtabCnt = Shdrs[i].sh_size / sizeof(Elf_Sym);
			rewind(fp);
			ret = fread(trash, sizeof(char), Shdrs[i].sh_offset, fp);
			Assert(ret == Shdrs[i].sh_offset, "Moving fp to sh_offset Error");

			ret = fread(Symtab, Shdrs[i].sh_size, 1, fp);
			Assert(ret == 1, "Reading whole symtab error.")	;
		}
		if(Shdrs[i].sh_type == SHT_STRTAB && i != Ehdr.e_shstrndx){
			 Strtab = malloc(Shdrs[i].sh_size);
			 rewind(fp);
			 ret = fread(trash, sizeof(char), Shdrs[i].sh_offset, fp);
			 Assert(ret == Shdrs[i].sh_offset, "Moving fp to sh_offset Error");

			 ret = fread(Strtab, Shdrs[i].sh_size, 1, fp);
			Assert(ret == 1, "Reading whole strtab error.")	;
		}
	}
	Log("Symbol table entry count : %u\n", SymtabCnt);
	for(int i = 0; i < SymtabCnt; i++){
		//printf("name: %u\n", Symtab[i].st_name);
		if(ELF32_ST_TYPE(Symtab[i].st_info) == STT_FUNC ){
			Log("Function Deteced : %s\n", Strtab + Symtab[i].st_name);
			//char* tests = "test";
			//Log("Log test %s\n", tests)	;
		}
	}

	free(trash);
	fclose(fp);
  ftrace_table_sta = 1;
#endif
}

static int level;
void ftrace_judge(word_t pc, int rs1, int rd, char* type, word_t dnpc){
  level = 0;
  if(ftrace_table_sta){
#ifdef CONFIG_FTRACE
    SpaceCnt[0] = '\0';

    char* funcstr;
    // JAL/JALR	 rd == ra --> call
    if(rd == 0x1){
      funcstr = ftrace(dnpc);
      for(int i = 0; i < level; i++) strcat(SpaceCnt, "\t");
      Log("%scall: %s @ 0x%08x\n", SpaceCnt, funcstr, dnpc);
      level++;
      return;
    }

    // JALR  rd == 0 rs == ra -->ret
    if(strcmp(type, "R") == 0 && rs1 == 0x1 && rd ==0){
      funcstr = ftrace(pc);
      level--;
      for(int i = 0; i < level; i++) strcat(SpaceCnt, "\t");
      Log("%sret : %s @ 0x%08x\n", SpaceCnt, funcstr, dnpc);
      return;
    }
    funcstr = ftrace(dnpc);
    Log("Normal Jump to : %s @ 0x%08x\n", funcstr, dnpc);
    return;	
#endif
  }
}

char* ftrace(word_t pos){
  if(ftrace_table_sta) {
  #ifdef CONFIG_FTRACE
    for(int i = 0; i < SymtabCnt; i++) {
      if(ELF32_ST_TYPE(Symtab[i].st_info) == STT_FUNC && pos >= Symtab[i].st_value && pos < Symtab[i].st_value + Symtab[i].st_size){
      return Strtab + Symtab[i].st_name;
      }
    }
    Log("Not found Func at 0x%08x\n", pos);
  #endif
  }
	return NULL;
}

void Ftrace_close(){
  #ifdef CONFIG_FTRACE
  if(ftrace_table_sta) {
    free(Strtab);
    free(Shdrs);
    free(Symtab);
    free(SpaceCnt);
  }
  #endif /* ifdef CONFIG_FTRACE */
}


