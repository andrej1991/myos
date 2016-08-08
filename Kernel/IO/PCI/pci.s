.code32
.text

.equ	CONFIG_ADDRESS, 0xCF8
.equ	CONFIG_DATA, 0xCFC

.macro calculate_pci_address bus=28, device=24, function=20, register=16
	movl	$0x80000000,%eax
	movl	\bus(%ebp),%ebx
	shll	$16,%ebx
	orl		%ebx,%eax
	movl	\device(%ebp),%ebx
	shll	$11,%ebx
	orl		%ebx,%eax
	movl	\function(%ebp),%ebx
	andb	$0x7,%bl
	shll	$8,%ebx
	orl		%ebx,%eax
	movl	\register(%ebp),%ebx
	andl	$0x3F,%ebx
	shll	$2,%ebx
	orl		%ebx,%eax
	.endm


#the parameters are: 
#					bus, 
#					device,
#					function,
#					register
.global read_pci
.type read_pci, @function
read_pci:
	pushl	%ebx
	pushl	%ebp
	pushl	%edx
	movl	%esp,%ebp
	calculate_pci_address
	mov		$CONFIG_ADDRESS,%dx
	out		%eax,%dx
	mov		$CONFIG_DATA,%dx
	in		%dx,%eax
	movl	%ebp,%esp
	popl	%edx
	popl	%ebp
	popl	%ebx
	ret

#the parameters are: 
#					bus, 
#					device,
#					function,
#					register
.global write_pci
.type write_pci, @function
write_pci:
	pushl	%ebx
	pushl	%ebp
	pushl	%edx
	movl	%esp,%ebp
	calculate_pci_address
	mov		$CONFIG_ADDRESS,%dx
	out		%eax,%dx
	mov		$CONFIG_DATA,%dx
	out		%eax,%dx
	movl	%ebp,%esp
	popl	%edx
	popl	%ebp
	popl	%ebx
	ret

.equ register, 0x2
.equ function, 0
.global begining_of_pci_dev_list
.equ begining_of_pci_dev_list, 0

#creates a dinamic array form the "begining_of_pci_dev_list" index of the data segments
#the array contains a structure with members bus and device number of existing pci devices
#returns the size of the array
.global enum_pci
.type enum_pci, @function
enum_pci:
	push	%ebx
	push	%ecx
	push	%edx
	push	%ebp
	movl	%esp,%ebp
	movl	$begining_of_pci_dev_list,%ebx
	movl	$256,%ecx
	enum_pci_outer:
		decl	%ecx
		movl	$32,%edx
		enum_pci_inner:
			decl	%edx
			pushl	%ecx
			pushl	%edx
			pushl	$function
			pushl	$register
			call	read_pci
			cmpl	$0xffffffff,%eax
			jz		end_of_enum_pci_inner
				movl	%ecx,%ds:0(%ebx)
				movl	%edx,%ds:4(%ebx)
				addl	$8,%ebx
			end_of_enum_pci_inner:
			cmpl	$0,%edx
			jnz		enum_pci_inner
		cmpl	$0,%ecx
		jnz		enum_pci_outer
	movl	%ebx,%eax
	shrl	$3,%eax
	movl	%ebp,%esp
	pop		%ebp
	pop		%edx
	pop		%ecx
	pop		%ebx
	ret
