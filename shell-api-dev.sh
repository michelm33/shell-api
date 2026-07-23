#!/bin/bash
###############################################################################
# HUMAN-READABLE "BSA BASH SHELL API" and genapp bash app generator
# 
# Copyright (c) 2024-2026 Michel Mehl.
# All rights reserved. 
# Tous droits réservés (France).
# 
# License terms written down in file LICENSE.txt
# Les termes de la licence sont détaillés dans le fichier LICENSE.txt
# 
# Release file path: shell-api-dev.sh
# Release file date: 2026-07-23 13:37
# App version: 1.1.0
# App source revision: 97
# App source signature: e20eb96b3d4e6835befb66ce8f066b37209f14602974b26a9ca3fd01599ac513
# Source file last modification: 2026-05-05 02:58:12.821290966 +0200
#
# This header was generated. Do not modify.
#
# -----------------------------------------------------------------------------
#
# A shell API for manipulating system devices.
#
# -----------------------------------------------------------------------------
# 
# Report bugs and suggestions: 
#     assistance@slashetc.fr
# 
# Specific or corporate requirements or extensions: 
#     info@slashetc.fr
# 
# The author is overall not required to provide maintenance or support 
# outside specific commercial terms agreed.
# 
###############################################################################

__SHELL_API_DEV_DIR__=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

source "${__SHELL_API_DEV_DIR__}/shell-api-core.sh"

if _loaded "${BASH_SOURCE[0]}"  ; then
	return 0
fi
declare -A Dev__fstype2PartUUID
declare -A Dev__PartitionTypes

Dev__mapperdir="/dev/mapper"

Dev__fstypes="ext4
ext3
ext2
exfat
vfat
ntfs
vera
luks
zfs
xfs
btrfs
ubifs
VMFS
squashfs
squashfs3
bfs
befs
nilfs2
f2fs
apfs
exfs
reiserfs
jfs
hfsplus
hfs
ufs
hpfs
sysv
xenix
minix
cramfs
romfs"

Dev_getPartUUID()
{	
	local __partTypeName="$1"
	local -n __out_uuid="$2"

	Str__toLower __partTypeName
	local __key
	for __key in "${!Dev__PartitionTypes[@]}" ; do
		local searchPartTypeName="${Dev__PartitionTypes["$__key"]}"
		Str__toLower searchPartTypeName		
		if [  "${searchPartTypeName}" = "${__partTypeName}" ] ; then
			__out_uuid="$__key"
			return 0
		fi
	done
	__out_uuid=""
	return 1
}

Dev_getPartNames()
{
	local -n __out_partNameList=$1
	local val
	for val in "${Dev__PartitionTypes[@]}" ; do
		if [ -z "${__out_partNameList}" ] ; then
		__out_partNameList="'$val'"
		else
		__out_partNameList="${__out_partNameList}
'$val'"
		fi
	done
}

Dev_getPartNamesReduced()
{
	local -n __out_partNameList=$1
	local val
	local newLine=""
	for val in "${Dev__PartitionTypes[@]}" ; do
		if [[ ! $val =~ ^"Linux root" ]] && 
			[[ ! $val =~ ^"Linux user" ]] && 
			[[ ! $val =~ ^"Verity root" ]] && 
			[[ ! $val =~ ^"Verity user" ]] &&
			[[ ! $val =~ .*"reserved".* ]] &&
			[[ ! $val =~ .*"Reserved".* ]] ; then
			if [ -z "${__out_partNameList}" ] ; then
				__out_partNameList="'$val'"
			else
				__out_partNameList="${__out_partNameList}
'$val'"
			fi
		fi
	done
}


Dev__initPartTypes()
{
	Dev__PartitionTypes["024DEE41-33E7-11D3-9D69-0008C781F39F"]="MBR"
	Dev__PartitionTypes["C12A7328-F81F-11D2-BA4B-00A0C93EC93B"]="EFI"
	Dev__PartitionTypes["21686148-6449-6E6F-744E-656564454649"]="BIOS boot"
	Dev__PartitionTypes["D3BFE2DE-3DAF-11DF-BA40-E3A556D89593"]="iFFS" # Intel Fast Flash  (for Intel Rapid Start technology)
	Dev__PartitionTypes["F4019732-066E-4E12-8273-346C5641494F"]="Sony boot"
	Dev__PartitionTypes["BFBFAFE7-A34F-448A-9A5B-6213EB736C22"]="Lenovo boot"
	# Windows
	Dev__PartitionTypes["E3C9E316-0B5C-4DB8-817D-F92DF00215AE"]="Microsoft Reserved" #  MSR
	Dev__PartitionTypes["EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"]="Microsoft Basic data"
	Dev__PartitionTypes["5808C8AA-7E8F-42E0-85D2-E1E90434CFB3"]="LDM metadata" # Logical Disk Manager 
	Dev__PartitionTypes["AF9B60A0-1431-4F62-BC68-3311714A69AD"]="LDM data"
	Dev__PartitionTypes["DE94BBA4-06D1-4D40-A16A-BFD50179D6AC"]="Microsoft Recovery"
	Dev__PartitionTypes["37AFFC90-EF7D-4E96-91C3-2D7AE055B174"]="GPFS" #IBM General Parallel File System
	Dev__PartitionTypes["E75CAF8F-F680-4CEE-AFA3-B001E56EFC2D"]="MS Storage Spaces"
	Dev__PartitionTypes["558D43C5-A1AC-43C0-AAC8-D1472B2923D1"]="MS Storage Replica"
	Dev__PartitionTypes["75894C1E-3AEB-11D3-B7C1-7B03A0000000"]="HP-UX Data"
	Dev__PartitionTypes["E2A1E728-32E3-11D6-A682-7B03A0000000"]="HP-UX Service"
	Dev__PartitionTypes["0FC63DAF-8483-4772-8E79-3D69D8477DE4"]="Linux"
	Dev__PartitionTypes["A19D880F-05FC-4D3B-A006-743F0F84911E"]="Linux RAID"
	Dev__PartitionTypes["6523F8AE-3EB1-4E2A-A05A-18B695AE656F"]="Linux root Alpha"
	Dev__PartitionTypes["D27F46ED-2919-4CB8-BD25-9531F3C16534"]="Linux root ARC"
	Dev__PartitionTypes["69DAD710-2CE4-4E3C-B16C-21A1D49ABED3"]="Linux root ARM 32‐bit"
	Dev__PartitionTypes["B921B045-1DF0-41C3-AF44-4C6F280D3FAE"]="Linux root AArch64"
	Dev__PartitionTypes["993D8D3D-F80E-4225-855A-9DAF8ED7EA97"]="Linux root IA-64"
	Dev__PartitionTypes["77055800-792C-4F94-B39A-98C91B762BB6"]="Linux root LoongArch 64‐bit"
	Dev__PartitionTypes["E9434544-6E2C-47CC-BAE2-12D6DEAFB44C"]="Linux root mips: 32‐bit MIPS BE" # BE big-endian
	Dev__PartitionTypes["D113AF76-80EF-41B4-BDB6-0CFF4D3D4A25"]="Linux root mips64: 64‐bit MIPS BE"
	Dev__PartitionTypes["37C58C8A-D913-4156-A25F-48B1B64E07F0"]="Linux root mipsel: 32‐bit MIPS LE" # LE Little-endian
	Dev__PartitionTypes["700BDA43-7A34-4507-B179-EEB93D7A7CA3"]="Linux root mips64el: 64‐bit MIPS LE"
	Dev__PartitionTypes["1AACDB3B-5444-4138-BD9E-E5C2239B2346"]="Linux root PA-RISC"
	Dev__PartitionTypes["1DE3F1EF-FA98-47B5-8DCD-4A860A654D78"]="Linux root 32‐bit PowerPC"
	Dev__PartitionTypes["912ADE1D-A839-4913-8964-A10EEE08FBD2"]="Linux root 64‐bit PowerPC BE"
	Dev__PartitionTypes["C31C45E6-3F39-412E-80FB-4809C4980599"]="Linux root 64‐bit PowerPC LE"
	Dev__PartitionTypes["60D5A7FE-8E7D-435C-B714-3DD8162144E1"]="Linux root RISC-V 32‐bit"
	Dev__PartitionTypes["72EC70A6-CF74-40E6-BD49-4BDA08E8F224"]="Linux root RISC-V 64‐bit"
	Dev__PartitionTypes["08A7ACEA-624C-4A20-91E8-6E0FA67D23F9"]="Linux root s390"
	Dev__PartitionTypes["5EEAD9A9-FE09-4A1E-A1D7-520D00531306"]="Linux root s390x"
	Dev__PartitionTypes["C50CDD70-3862-4CC3-90E1-809A8C93EE2C"]="Linux root TILE-Gx"
	Dev__PartitionTypes["44479540-F297-41B2-9AF7-D131D5F0458A"]="Linux root x86"
	Dev__PartitionTypes["4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709"]="Linux root x86-64"
	Dev__PartitionTypes["E18CF08C-33EC-4C0D-8246-C6C6FB3DA024"]="Linux user Alpha"
	Dev__PartitionTypes["7978A683-6316-4922-BBEE-38BFF5A2FECC"]="Linux user ARC"
	Dev__PartitionTypes["7D0359A3-02B3-4F0A-865C-654403E70625"]="Linux user ARM 32‐bit"
	Dev__PartitionTypes["B0E01050-EE5F-4390-949A-9101B17104E9"]="Linux user AArch64"
	Dev__PartitionTypes["4301D2A6-4E3B-4B2A-BB94-9E0B2C4225EA"]="Linux user IA-64"
	Dev__PartitionTypes["E611C702-575C-4CBE-9A46-434FA0BF7E3F"]="Linux user LoongArch 64‐bit"
	Dev__PartitionTypes["773B2ABC-2A99-4398-8BF5-03BAAC40D02B"]="Linux user mips: 32‐bit MIPS BE"
	Dev__PartitionTypes["57E13958-7331-4365-8E6E-35EEEE17C61B"]="Linux user mips64: 64‐bit MIPS BE"
	Dev__PartitionTypes["0F4868E9-9952-4706-979F-3ED3A473E947"]="Linux user mipsel: 32‐bit MIPS LE"
	Dev__PartitionTypes["C97C1F32-BA06-40B4-9F22-236061B08AA8"]="Linux user mips64el: 64‐bit MIPS LE"
	Dev__PartitionTypes["DC4A4480-6917-4262-A4EC-DB9384949F25"]="Linux user PA-RISC"
	Dev__PartitionTypes["7D14FEC5-CC71-415D-9D6C-06BF0B3C3EAF"]="Linux user 32‐bit PowerPC"
	Dev__PartitionTypes["2C9739E2-F068-46B3-9FD0-01C5A9AFBCCA"]="Linux user 64‐bit PowerPC BE"
	Dev__PartitionTypes["15BB03AF-77E7-4D4A-B12B-C0D084F7491C"]="Linux user 64‐bit PowerPC LE"
	Dev__PartitionTypes["B933FB22-5C3F-4F91-AF90-E2BB0FA50702"]="Linux user RISC-V 32‐bit"
	Dev__PartitionTypes["BEAEC34B-8442-439B-A40B-984381ED097D"]="Linux user RISC-V 64‐bit"
	Dev__PartitionTypes["CD0F869B-D0FB-4CA0-B141-9EA87CC78D66"]="Linux user s390"
	Dev__PartitionTypes["8A4F5770-50AA-4ED3-874A-99B710DB6FEA"]="Linux user s390x"
	Dev__PartitionTypes["55497029-C7C1-44CC-AA39-815ED1558630"]="Linux user TILE-Gx"
	Dev__PartitionTypes["75250D76-8CC6-458E-BD66-BD47CC81A812"]="Linux user x86"
	Dev__PartitionTypes["8484680C-9521-48C6-9C11-B0720656F69E"]="Linux user x86-64"
	Dev__PartitionTypes["FC56D9E9-E6E5-4C06-BE32-E74407CE09A5"]="Verity root Alpha"
	Dev__PartitionTypes["24B2D975-0F97-4521-AFA1-CD531E421B8D"]="Verity root ARC"
	Dev__PartitionTypes["7386CDF2-203C-47A9-A498-F2ECCE45A2D6"]="Verity root ARM 32‐bit"
	Dev__PartitionTypes["DF3300CE-D69F-4C92-978C-9BFB0F38D820"]="Verity root AArch64"
	Dev__PartitionTypes["86ED10D5-B607-45BB-8957-D350F23D0571"]="Verity root IA-64"
	Dev__PartitionTypes["F3393B22-E9AF-4613-A948-9D3BFBD0C535"]="Verity root LoongArch 64‐bit"
	Dev__PartitionTypes["7A430799-F711-4C7E-8E5B-1D685BD48607"]="Verity root mips: 32‐bit MIPS BE"
	Dev__PartitionTypes["579536F8-6A33-4055-A95A-DF2D5E2C42A8"]="Verity root mips64: 64‐bit MIPS BE"
	Dev__PartitionTypes["D7D150D2-2A04-4A33-8F12-16651205FF7B"]="Verity root mipsel: 32‐bit MIPS LE"
	Dev__PartitionTypes["16B417F8-3E06-4F57-8DD2-9B5232F41AA6"]="Verity root mips64el: 64‐bit MIPS LE"
	Dev__PartitionTypes["D212A430-FBC5-49F9-A983-A7FEEF2B8D0E"]="Verity root PA-RISC"
	Dev__PartitionTypes["906BD944-4589-4AAE-A4E4-DD983917446A"]="Verity root 64‐bit PowerPC LE"
	Dev__PartitionTypes["9225A9A3-3C19-4D89-B4F6-EEFF88F17631"]="Verity root 64‐bit PowerPC BE"
	Dev__PartitionTypes["98CFE649-1588-46DC-B2F0-ADD147424925"]="Verity root 32‐bit PowerPC"
	Dev__PartitionTypes["AE0253BE-1167-4007-AC68-43926C14C5DE"]="Verity root RISC-V 32‐bit"
	Dev__PartitionTypes["B6ED5582-440B-4209-B8DA-5FF7C419EA3D"]="Verity root RISC-V 64‐bit"
	Dev__PartitionTypes["7AC63B47-B25C-463B-8DF8-B4A94E6C90E1"]="Verity root s390"
	Dev__PartitionTypes["B325BFBE-C7BE-4AB8-8357-139E652D2F6B"]="Verity root s390x"
	Dev__PartitionTypes["966061EC-28E4-4B2E-B4A5-1F0A825A1D84"]="Verity root TILE-Gx"
	Dev__PartitionTypes["2C7357ED-EBD2-46D9-AEC1-23D437EC2BF5"]="Verity root x86-64"
	Dev__PartitionTypes["D13C5D3B-B5D1-422A-B29F-9454FDC89D76"]="Verity root x86"
	Dev__PartitionTypes["8CCE0D25-C0D0-4A44-BD87-46331BF1DF67"]="Verity user Alpha"
	Dev__PartitionTypes["FCA0598C-D880-4591-8C16-4EDA05C7347C"]="Verity user ARC"
	Dev__PartitionTypes["C215D751-7BCD-4649-BE90-6627490A4C05"]="Verity user ARM 32‐bit"
	Dev__PartitionTypes["6E11A4E7-FBCA-4DED-B9E9-E1A512BB664E"]="Verity user AArch64"
	Dev__PartitionTypes["6A491E03-3BE7-4545-8E38-83320E0EA880"]="Verity user IA-64"
	Dev__PartitionTypes["F46B2C26-59AE-48F0-9106-C50ED47F673D"]="Verity user LoongArch 64‐bit"
	Dev__PartitionTypes["6E5A1BC8-D223-49B7-BCA8-37A5FCCEB996"]="Verity user mips: 32‐bit MIPS BE"
	Dev__PartitionTypes["81CF9D90-7458-4DF4-8DCF-C8A3A404F09B"]="Verity user mips64: 64‐bit MIPS BE"
	Dev__PartitionTypes["46B98D8D-B55C-4E8F-AAB3-37FCA7F80752"]="Verity user mipsel: 32‐bit MIPS LE"
	Dev__PartitionTypes["3C3D61FE-B5F3-414D-BB71-8739A694A4EF"]="Verity user mips64el: 64‐bit MIPS LE"
	Dev__PartitionTypes["5843D618-EC37-48D7-9F12-CEA8E08768B2"]="Verity user PA-RISC"
	Dev__PartitionTypes["EE2B9983-21E8-4153-86D9-B6901A54D1CE"]="Verity user 64‐bit PowerPC LE"
	Dev__PartitionTypes["BDB528A5-A259-475F-A87D-DA53FA736A07"]="Verity user 64‐bit PowerPC BE"
	Dev__PartitionTypes["DF765D00-270E-49E5-BC75-F47BB2118B09"]="Verity user 32‐bit PowerPC"
	Dev__PartitionTypes["CB1EE4E3-8CD0-4136-A0A4-AA61A32E8730"]="Verity user RISC-V 32‐bit"
	Dev__PartitionTypes["8F1056BE-9B05-47C4-81D6-BE53128E5B54"]="Verity user RISC-V 64‐bit"
	Dev__PartitionTypes["B663C618-E7BC-4D6D-90AA-11B756BB1797"]="Verity user s390"
	Dev__PartitionTypes["31741CC4-1A2A-4111-A581-E00B447D2D06"]="Verity user s390x"
	Dev__PartitionTypes["2FB4BF56-07FA-42DA-8132-6B139F2026AE"]="Verity user TILE-Gx"
	Dev__PartitionTypes["77FF5F63-E7B6-4633-ACF4-1565B864C0E6"]="Verity user x86-64"
	Dev__PartitionTypes["8F461B0D-14EE-4E81-9AA9-049B6FB97ABD"]="Verity user x86"
	Dev__PartitionTypes["D46495B7-A053-414F-80F7-700C99921EF8"]="Verity root signature Alpha"
	Dev__PartitionTypes["143A70BA-CBD3-4F06-919F-6C05683A78BC"]="Verity root signature ARC"
	Dev__PartitionTypes["42B0455F-EB11-491D-98D3-56145BA9D037"]="Verity root signature ARM 32‐bit"
	Dev__PartitionTypes["6DB69DE6-29F4-4758-A7A5-962190F00CE3"]="Verity root signature AArch64"
	Dev__PartitionTypes["E98B36EE-32BA-4882-9B12-0CE14655F46A"]="Verity root signature IA-64"
	Dev__PartitionTypes["5AFB67EB-ECC8-4F85-AE8E-AC1E7C50E7D0"]="Verity root signature LoongArch 64‐bit"
	Dev__PartitionTypes["BBA210A2-9C5D-45EE-9E87-FF2CCBD002D0"]="Verity root signature mips: 32‐bit MIPS BE"
	Dev__PartitionTypes["43CE94D4-0F3D-4999-8250-B9DEAFD98E6E"]="Verity root signature mips64: 64‐bit MIPS BE"
	Dev__PartitionTypes["C919CC1F-4456-4EFF-918C-F75E94525CA5"]="Verity root signature mipsel: 32‐bit MIPS LE"
	Dev__PartitionTypes["904E58EF-5C65-4A31-9C57-6AF5FC7C5DE7"]="Verity root signature mips64el: 64‐bit MIPS LE"
	Dev__PartitionTypes["15DE6170-65D3-431C-916E-B0DCD8393F25"]="Verity root signature PA-RISC"
	Dev__PartitionTypes["D4A236E7-E873-4C07-BF1D-BF6CF7F1C3C6"]="Verity root signature 64‐bit PowerPC LE"
	Dev__PartitionTypes["F5E2C20C-45B2-4FFA-BCE9-2A60737E1AAF"]="Verity root signature 64‐bit PowerPC BE"
	Dev__PartitionTypes["1B31B5AA-ADD9-463A-B2ED-BD467FC857E7"]="Verity root signature 32‐bit PowerPC"
	Dev__PartitionTypes["3A112A75-8729-4380-B4CF-764D79934448"]="Verity root signature RISC-V 32‐bit"
	Dev__PartitionTypes["EFE0F087-EA8D-4469-821A-4C2A96A8386A"]="Verity root signature RISC-V 64‐bit"
	Dev__PartitionTypes["3482388E-4254-435A-A241-766A065F9960"]="Verity root signature s390"
	Dev__PartitionTypes["C80187A5-73A3-491A-901A-017C3FA953E9"]="Verity root signature s390x"
	Dev__PartitionTypes["B3671439-97B0-4A53-90F7-2D5A8F3AD47B"]="Verity root signature TILE-Gx"
	Dev__PartitionTypes["41092B05-9FC8-4523-994F-2DEF0408B176"]="Verity root signature x86-64"
	Dev__PartitionTypes["5996FC05-109C-48DE-808B-23FA0830B676"]="Verity root signature x86"
	Dev__PartitionTypes["5C6E1C76-076A-457A-A0FE-F3B4CD21CE6E"]="Verity user signature Alpha"
	Dev__PartitionTypes["94F9A9A1-9971-427A-A400-50CB297F0F35"]="Verity user signature ARC"
	Dev__PartitionTypes["D7FF812F-37D1-4902-A810-D76BA57B975A"]="Verity user signature ARM 32‐bit"
	Dev__PartitionTypes["C23CE4FF-44BD-4B00-B2D4-B41B3419E02A"]="Verity user signature AArch64"
	Dev__PartitionTypes["8DE58BC2-2A43-460D-B14E-A76E4A17B47F"]="Verity user signature IA-64"
	Dev__PartitionTypes["B024F315-D330-444C-8461-44BBDE524E99"]="Verity user signature LoongArch 64‐bit"
	Dev__PartitionTypes["97AE158D-F216-497B-8057-F7F905770F54"]="Verity user signature mips: 32‐bit MIPS BE"
	Dev__PartitionTypes["05816CE2-DD40-4AC6-A61D-37D32DC1BA7D"]="Verity user signature mips64: 64‐bit MIPS BE"
	Dev__PartitionTypes["3E23CA0B-A4BC-4B4E-8087-5AB6A26AA8A9"]="Verity user signature mipsel: 32‐bit MIPS LE"
	Dev__PartitionTypes["F2C2C7EE-ADCC-4351-B5C6-EE9816B66E16"]="Verity user signature mips64el: 64‐bit MIPS LE"
	Dev__PartitionTypes["450DD7D1-3224-45EC-9CF2-A43A346D71EE"]="Verity user signature PA-RISC"
	Dev__PartitionTypes["C8BFBD1E-268E-4521-8BBA-BF314C399557"]="Verity user signature 64‐bit PowerPC LE"
	Dev__PartitionTypes["0B888863-D7F8-4D9E-9766-239FCE4D58AF"]="Verity user signature 64‐bit PowerPC BE"
	Dev__PartitionTypes["7007891D-D371-4A80-86A4-5CB875B9302E"]="Verity user signature 32‐bit PowerPC"
	Dev__PartitionTypes["C3836A13-3137-45BA-B583-B16C50FE5EB4"]="Verity user signature RISC-V 32‐bit"
	Dev__PartitionTypes["D2F9000A-7A18-453F-B5CD-4D32F77A7B32"]="Verity user signature RISC-V 64‐bit"
	Dev__PartitionTypes["17440E4F-A8D0-467F-A46E-3912AE6EF2C5"]="Verity user signature s390"
	Dev__PartitionTypes["3F324816-667B-46AE-86EE-9B0C0C6C11B4"]="Verity user signature s390x"
	Dev__PartitionTypes["4EDE75E2-6CCC-4CC8-B9C7-70334B087510"]="Verity user signature TILE-Gx"
	Dev__PartitionTypes["E7BB33FB-06CF-4E81-8273-E543B413E2E2"]="Verity user signature x86-64"
	Dev__PartitionTypes["974A71C0-DE41-43C3-BE5D-5C5CCD1AD2C0"]="Verity user signature x86"
	Dev__PartitionTypes["BC13C2FF-59E6-4262-A352-B275FD6F7172"]="XBOOTLDR" # Extended Boot Loader (XBOOTLDR) partition
	Dev__PartitionTypes["0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"]="Linux Swap"
	Dev__PartitionTypes["E6D6D379-F507-44C2-A23C-238F2A3DF928"]="LVM" # Logical Volume Manager
	Dev__PartitionTypes["933AC7E1-2EB4-4F13-B844-0E14E2AEF915"]="/home part"
	Dev__PartitionTypes["3B8F8425-20E0-4F3B-907F-1A25A76F98E8"]="/srv part" #  (server data)
	Dev__PartitionTypes["773F91EF-66D4-49B5-BD83-D683BF40AD16"]="Per‐user home"
	Dev__PartitionTypes["7FFEC5C9-2D00-49B7-8941-3EA10A5586B7"]="Plain dm-crypt"
	Dev__PartitionTypes["CA7D7CCB-63ED-4C53-861C-1742536059CC"]="LUKS"
	Dev__PartitionTypes["8DA63339-0007-60C0-C436-083AC8230908"]="Reserved"
	Dev__PartitionTypes["0FC63DAF-8483-4772-8E79-3D69D8477DE4"]="Linux" # GNU/Hurd filesystem data"
	Dev__PartitionTypes["0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"]="Linux Swap" # "GNU/Hurd Swap"
	Dev__PartitionTypes["83BD6B9D-7F41-11DC-BE0B-001560B84F0F"]="FreeBSD Boot"
	Dev__PartitionTypes["516E7CB4-6ECF-11D6-8FF8-00022D09712B"]="FreeBSD BSD disklabel"
	Dev__PartitionTypes["516E7CB5-6ECF-11D6-8FF8-00022D09712B"]="FreeBSD Swap"
	Dev__PartitionTypes["516E7CB6-6ECF-11D6-8FF8-00022D09712B"]="FreeBSD UFS" # Unix File System
	Dev__PartitionTypes["516E7CB8-6ECF-11D6-8FF8-00022D09712B"]="FreeBSD Vinum" # Vinum volume manager partition
	Dev__PartitionTypes["516E7CBA-6ECF-11D6-8FF8-00022D09712B"]="FreeBSD ZFS"
	Dev__PartitionTypes["74BA7DD9-A689-11E1-BD04-00E081286ACF"]="FreeBSD nandfs"
	Dev__PartitionTypes["48465300-0000-11AA-AA11-00306543ECAC"]="HFS+" # "Hierarchical File System Plus (HFS+) partition"
	Dev__PartitionTypes["7C3457EF-0000-11AA-AA11-00306543ECAC"]="APFS" # Apple APFS container, APFS FileVault volume container 
	Dev__PartitionTypes["55465300-0000-11AA-AA11-00306543ECAC"]="Apple UFS container"
	Dev__PartitionTypes["6A898CC3-1DD2-11B2-99A6-080020736631"]="ZFS"
	Dev__PartitionTypes["52414944-0000-11AA-AA11-00306543ECAC"]="Apple RAID"
	Dev__PartitionTypes["52414944-5F4F-11AA-AA11-00306543ECAC"]="Apple RAID, offline"
	Dev__PartitionTypes["426F6F74-0000-11AA-AA11-00306543ECAC"]="Apple Boot (Recovery HD)"
	Dev__PartitionTypes["4C616265-6C00-11AA-AA11-00306543ECAC"]="Apple Label"
	Dev__PartitionTypes["5265636F-7665-11AA-AA11-00306543ECAC"]="Apple TV Recovery" 
	Dev__PartitionTypes["53746F72-6167-11AA-AA11-00306543ECAC"]="CoreStorage"   # Apple Core Storage ContainerHFS+ FileVault volume container 
	Dev__PartitionTypes["69646961-6700-11AA-AA11-00306543ECAC"]="Apple APFS Preboot"
	Dev__PartitionTypes["52637672-7900-11AA-AA11-00306543ECAC"]="Apple APFS Recovery"
	Dev__PartitionTypes["6A82CB45-1DD2-11B2-99A6-080020736631"]="Solaris Boot"
	Dev__PartitionTypes["6A85CF4D-1DD2-11B2-99A6-080020736631"]="Solaris Root"
	Dev__PartitionTypes["6A87C46F-1DD2-11B2-99A6-080020736631"]="Solaris Swap"
	Dev__PartitionTypes["6A8B642B-1DD2-11B2-99A6-080020736631"]="Solaris Backup"
	Dev__PartitionTypes["6A898CC3-1DD2-11B2-99A6-080020736631"]="Solaris /usr"
	Dev__PartitionTypes["6A8EF2E9-1DD2-11B2-99A6-080020736631"]="Solaris /var"
	Dev__PartitionTypes["6A90BA39-1DD2-11B2-99A6-080020736631"]="Solaris /home"
	Dev__PartitionTypes["6A9283A5-1DD2-11B2-99A6-080020736631"]="Solaris Alternate sector"
	Dev__PartitionTypes["6A945A3B-1DD2-11B2-99A6-080020736631"]="Solaris Reserved"
	Dev__PartitionTypes["6A9630D1-1DD2-11B2-99A6-080020736631"]="Solaris Reserved"
	Dev__PartitionTypes["6A980767-1DD2-11B2-99A6-080020736631"]="Solaris Reserved"
	Dev__PartitionTypes["6A96237F-1DD2-11B2-99A6-080020736631"]="Solaris Reserved"
	Dev__PartitionTypes["6A8D2AC7-1DD2-11B2-99A6-080020736631"]="Solaris Reserved"
	Dev__PartitionTypes["49F48D32-B10E-11DC-B99B-0019D1879648"]="NetBSD Swap"
	Dev__PartitionTypes["49F48D5A-B10E-11DC-B99B-0019D1879648"]="NetBSD FFS"
	Dev__PartitionTypes["49F48D82-B10E-11DC-B99B-0019D1879648"]="NetBSD LFS"
	Dev__PartitionTypes["49F48DAA-B10E-11DC-B99B-0019D1879648"]="NetBSD RAID"
	Dev__PartitionTypes["2DB519C4-B10F-11DC-B99B-0019D1879648"]="NetBSD Concatenated"
	Dev__PartitionTypes["2DB519EC-B10F-11DC-B99B-0019D1879648"]="NetBSD Encrypted"
	Dev__PartitionTypes["FE3A2A5D-4F32-41A7-B725-ACCC3285A309"]="ChromeOS kernel"
	Dev__PartitionTypes["3CB8E202-3B7E-47DD-8A3C-7FF2A13CFCEC"]="ChromeOS rootfs"
	Dev__PartitionTypes["CAB6E88E-ABF3-4102-A07A-D4BB9BE3C1D3"]="ChromeOS firmware"
	Dev__PartitionTypes["2E0A753D-9E48-43B0-8337-B15192CB1B5E"]="ChromeOS future use"
	Dev__PartitionTypes["09845860-705F-4BB5-B16C-8A8A099CAF52"]="ChromeOS miniOS"
	Dev__PartitionTypes["5DFBF5F4-2848-4BAC-AA5E-0D9A20B745A6"]="coreos-usr"
	Dev__PartitionTypes["3884DD41-8582-4404-B9A8-E9B84F2DF50E"]="coreos-resize-rootfs"
	Dev__PartitionTypes["C95DC21A-DF0E-4340-8D7B-26CBFA9A03E0"]="coreos-reserved"
	Dev__PartitionTypes["BE9067B9-EA49-4F15-B4F6-F36F8C9E1818"]="coreos-root-raid"
	Dev__PartitionTypes["42465331-3BA3-10F1-802A-4861696B7521"]="Haiku BFS"
	Dev__PartitionTypes["85D5E45E-237C-11E1-B4B3-E89A8F7FC3A7"]="MidnightBSD Boot"
	Dev__PartitionTypes["85D5E45A-237C-11E1-B4B3-E89A8F7FC3A7"]="MidnightBSD Data"
	Dev__PartitionTypes["85D5E45B-237C-11E1-B4B3-E89A8F7FC3A7"]="MidnightBSD Swap"
	Dev__PartitionTypes["0394EF8B-237E-11E1-B4B3-E89A8F7FC3A7"]="MidnightBSD Unix File System (UFS)"
	Dev__PartitionTypes["85D5E45C-237C-11E1-B4B3-E89A8F7FC3A7"]="MidnightBSD Vinum volume manager"
	Dev__PartitionTypes["85D5E45D-237C-11E1-B4B3-E89A8F7FC3A7"]="MidnightBSD ZFS"
	Dev__PartitionTypes["45B0969E-9B03-4F30-B4C6-B4B80CEFF106"]="Journal"
	Dev__PartitionTypes["45B0969E-9B03-4F30-B4C6-5EC00CEFF106"]="dm-crypt journal"
	Dev__PartitionTypes["4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D"]="OSD"
	Dev__PartitionTypes["4FBD7E29-9D25-41B8-AFD0-5EC00CEFF05D"]="dm-crypt OSD"
	Dev__PartitionTypes["89C57F98-2FE5-4DC0-89C1-F3AD0CEFF2BE"]="Disk in creation"
	Dev__PartitionTypes["89C57F98-2FE5-4DC0-89C1-5EC00CEFF2BE"]="dm-crypt disk in creation"
	Dev__PartitionTypes["CAFECAFE-9B03-4F30-B4C6-B4B80CEFF106"]="Block"
	Dev__PartitionTypes["30CD0809-C2B2-499C-8879-2D6B78529876"]="Block DB"
	Dev__PartitionTypes["5CE17FCE-4087-4169-B7FF-056CC58473F9"]="Block write-ahead log"
	Dev__PartitionTypes["FB3AABF9-D25F-47CC-BF5E-721D1816496B"]="Lockbox for dm-crypt keys"
	Dev__PartitionTypes["4FBD7E29-8AE0-4982-BF9D-5A8D867AF560"]="Multipath OSD"
	Dev__PartitionTypes["45B0969E-8AE0-4982-BF9D-5A8D867AF560"]="Multipath journal"
	Dev__PartitionTypes["CAFECAFE-8AE0-4982-BF9D-5A8D867AF560"]="Multipath block"
	Dev__PartitionTypes["7F4A666A-16F3-47A2-8445-152EF4D03F6C"]="Multipath block"
	Dev__PartitionTypes["EC6D6385-E346-45DC-BE91-DA2A7C8B3261"]="Multipath block DB"
	Dev__PartitionTypes["01B41E1B-002A-453C-9F17-88793989FF8F"]="Multipath block write-ahead log"
	Dev__PartitionTypes["CAFECAFE-9B03-4F30-B4C6-5EC00CEFF106"]="dm-crypt block"
	Dev__PartitionTypes["93B0052D-02D9-4D8A-A43B-33A3EE4DFBC3"]="dm-crypt block DB"
	Dev__PartitionTypes["306E8683-4FE2-4330-B7C0-00A917C16966"]="dm-crypt block write-ahead log"
	Dev__PartitionTypes["45B0969E-9B03-4F30-B4C6-35865CEFF106"]="dm-crypt LUKS journal"
	Dev__PartitionTypes["CAFECAFE-9B03-4F30-B4C6-35865CEFF106"]="dm-crypt LUKS block"
	Dev__PartitionTypes["166418DA-C469-4022-ADF4-B30AFD37F176"]="dm-crypt LUKS block DB"
	Dev__PartitionTypes["86A32090-3647-40B9-BBBD-38D8C573AA86"]="dm-crypt LUKS block write-ahead log"
	Dev__PartitionTypes["4FBD7E29-9D25-41B8-AFD0-35865CEFF05D"]="dm-crypt LUKS OSD"
	Dev__PartitionTypes["824CC7A0-36A8-11E3-890A-952519AD3F61"]="OpenBSD Data"
	Dev__PartitionTypes["CEF5A9AD-73BC-4601-89F3-CDEEEEE321A1"]="Power-safe (QNX6)"
	Dev__PartitionTypes["C91818F9-8025-47AF-89D2-F030D7000C2C"]="Plan 9"
	Dev__PartitionTypes["9D275380-40AD-11DB-BF97-000C2911D1B8"]="vmkcore" # (coredump partition)
	Dev__PartitionTypes["AA31E02A-400F-11DB-9590-000C2911D1B8"]="VMFS"  # VMFS filesystem partition
	Dev__PartitionTypes["9198EFFC-31C0-11DB-8F78-000C2911D1B8"]="VMware Reserved"
	Dev__PartitionTypes["2568845D-2332-4675-BC39-8FA5A4748D15"]="Android Bootloader"
	Dev__PartitionTypes["114EAFFE-1552-4022-B26E-9B053604CF84"]="Android Bootloader2"
	Dev__PartitionTypes["49A4D17F-93A3-45C1-A0DE-F50B2EBE2599"]="Android Boot"
	Dev__PartitionTypes["4177C722-9E92-4AAB-8644-43502BFD5506"]="Android Recovery"
	Dev__PartitionTypes["EF32A33B-A409-486C-9141-9FFB711F6266"]="Android Misc"
	Dev__PartitionTypes["20AC26BE-20B7-11E3-84C5-6CFDB94711E9"]="Android Metadata"
	Dev__PartitionTypes["38F428E6-D326-425D-9140-6E0EA133647C"]="Android System"
	Dev__PartitionTypes["A893EF21-E428-470A-9E55-0668FD91A2D9"]="Android Cache"
	Dev__PartitionTypes["DC76DDA9-5AC1-491C-AF42-A82591580C0D"]="Android Data"
	Dev__PartitionTypes["EBC597D0-2053-4B15-8B64-E0AAC75F4DB1"]="Android Persistent"
	Dev__PartitionTypes["C5A0AEEC-13EA-11E5-A1B1-001E67CA0C3C"]="Android Vendor"
	Dev__PartitionTypes["BD59408B-4514-490D-BF12-9878D963F378"]="Android Config"
	Dev__PartitionTypes["8F68CC74-C5E5-48DA-BE91-A0C8C15E9C80"]="Android Factory"
	Dev__PartitionTypes["9FDAA6EF-4B3F-40D2-BA8D-BFF16BFB887B"]="Android Factory (alt)"
	Dev__PartitionTypes["767941D0-2085-11E3-AD3B-6CFDB94711E9"]="Android Fastboot / Tertiary"
	Dev__PartitionTypes["AC6D7924-EB71-4DF8-B48D-E267B27148FF"]="Android OEM"
	Dev__PartitionTypes["19A710A2-B3CA-11E4-B026-10604B889DCF"]="Android6.0+ARM Meta"
	Dev__PartitionTypes["193D1EA4-B3CA-11E4-B075-10604B889DCF"]="Android6.0+ARM EXT"
	Dev__PartitionTypes["7412F7D5-A156-4B13-81DC-867174929325"]="ONIE Boot"
	Dev__PartitionTypes["D4E6E2CD-4469-46F3-B5CB-1BFF57AFC149"]="ONIE Config"
	Dev__PartitionTypes["9E1A2D38-C612-4316-AA26-8B49521E5A8B"]="PowerPC PReP boot"
	Dev__PartitionTypes["BC13C2FF-59E6-4262-A352-B275FD6F7172"]="freedesktop.org shared bootloader cfg" # "freedesktop.org OSes (Linux, etc.) 	Shared boot loader configuration"
	Dev__PartitionTypes["734E5AFE-F61A-11E6-BC64-92361F002671"]="Atari TOS Basic data" #  (GEM, BGM, F32)
	Dev__PartitionTypes["35540011-B055-499F-842D-C69AECA357B7"]="Atari TOS Raw data/XHDI" # (RAW), XHDI
	Dev__PartitionTypes["8C8F8EFF-AC95-4770-814A-21994F2DBC8F"]="VeraCrypt"
	Dev__PartitionTypes["90B6FF38-B98F-4358-A21F-48F35B4A8AD3"]="OS/2 	ArcaOS Type 1"
	Dev__PartitionTypes["7C5222BD-8F5D-4087-9C00-BF9843C7B58C"]="SPDK block device"
	Dev__PartitionTypes["4778ED65-BF42-45FA-9C5B-287A1DC4AAB1"]="barebox-state"
	Dev__PartitionTypes["3DE21764-95BD-54BD-A5C3-4ABE786F38A8"]="U-Boot"
	Dev__PartitionTypes["B6FA30DA-92D2-4A9A-96F1-871EC6486200"]="SoftRAID_Status"
	Dev__PartitionTypes["2E313465-19B9-463F-8126-8A7993773801"]="SoftRAID_Scratch"
	Dev__PartitionTypes["FA709C7E-65B1-4593-BFD5-E71D61DE9B02"]="SoftRAID_Volume"
	Dev__PartitionTypes["BBBA6DF5-F46F-4A89-8F59-8765B2727503"]="SoftRAID_Cache"
	Dev__PartitionTypes["FE8A2634-5E2E-46BA-99E3-3A192091A350"]="Fuchsia Bootloader (slot A/B/R)"
	Dev__PartitionTypes["D9FD4535-106C-4CEC-8D37-DFC020CA87CB"]="Fuchsia Durable mutable encrypted"
	Dev__PartitionTypes["A409E16B-78AA-4ACC-995C-302352621A41"]="Fuchsia Durable mutable bootloader data (including A/B/R metadata)"
	Dev__PartitionTypes["F95D940E-CABA-4578-9B93-BB6C90F29D3E"]="Fuchsia Factory System " # ro: read-only , Factory-provisioned read-only system data 
	Dev__PartitionTypes["10B8DBAA-D2BF-42A9-98C6-A7C5DB3701E7"]="Fuchsia Factory Bootloader" # Factory-provisioned read-only bootloader data 
	Dev__PartitionTypes["49FD7CB8-DF15-4E73-B9D9-992070127F0F"]="Fuchsia Volume Manager"
	Dev__PartitionTypes["421A8BFC-85D9-4D85-ACDA-B64EEC0133E9"]="Fuchsia Verified boot metadata (slot A/B/R)"
	Dev__PartitionTypes["9B37FFF6-2E58-466A-983A-F7926D0B04E0"]="Zircon boot image (slot A/B/R)"
	# SAME AS EFI !?!
	#Dev__PartitionTypes["C12A7328-F81F-11D2-BA4B-00A0C93EC93B"]="fuchsia-esp"
	Dev__PartitionTypes["606B000B-B7C7-4653-A7D5-B737332C899D"]="fuchsia-system"
	Dev__PartitionTypes["08185F0C-892D-428A-A789-DBEEC8F55E6A"]="fuchsia-data"
	Dev__PartitionTypes["48435546-4953-2041-494E-5354414C4C52"]="fuchsia-install"
	Dev__PartitionTypes["2967380E-134C-4CBB-B6DA-17E7CE1CA45D"]="fuchsia-blob"
	Dev__PartitionTypes["41D0E340-57E3-954E-8C1E-17ECAC44CFF5"]="fuchsia-fvm"
	Dev__PartitionTypes["DE30CC86-1F4A-4A31-93C4-66F147D33E05"]="Zircon boot image (slot A)"
	Dev__PartitionTypes["23CC04DF-C278-4CE7-8471-897D1A4BCDF7"]="Zircon boot image (slot B)"
	Dev__PartitionTypes["A0E5CF57-2DEF-46BE-A80C-A2067C37CD49"]="Zircon boot image (slot R)"
	Dev__PartitionTypes["4E5E989E-4C86-11E8-A15B-480FCF35F8E6"]="Fuchsia sys-config"
	Dev__PartitionTypes["5A3A90BE-4C86-11E8-A15B-480FCF35F8E6"]="Fuchsia factory-config"
	Dev__PartitionTypes["5ECE94FE-4C86-11E8-A15B-480FCF35F8E6"]="Fuchsia bootloader"
	Dev__PartitionTypes["8B94D043-30BE-4871-9DFA-D69556E8C1F3"]="Fuchsia guid-test"
	Dev__PartitionTypes["A13B4D9A-EC5F-11E8-97D8-6C3BE52705BF"]="Fuchsia Verified boot metadata (slot A)"
	Dev__PartitionTypes["A288ABF2-EC5F-11E8-97D8-6C3BE52705BF"]="Fuchsia Verified boot metadata (slot B)"
	Dev__PartitionTypes["6A2460C3-CD11-4E8B-80A8-12CCE268ED0A"]="Fuchsia Verified boot metadata (slot R)"
	Dev__PartitionTypes["1D75395D-F2C6-476B-A8B7-45CC1C97B476"]="Fuchsia misc"
	Dev__PartitionTypes["900B0FC5-90CD-4D4F-84F9-9F8ED579DB88"]="Fuchsia emmc-boot1"
	Dev__PartitionTypes["B2B2E8D1-7C10-4EBC-A2D0-4614568260AD"]="Fuchsia emmc-boot2"
	Dev__PartitionTypes["481B2A38-0561-420B-B72A-F1C4988EFC16"]="Minix"
	Dev__PartitionTypes["3F82EEBC-87C9-4097-8165-89D6540557C0"]="Emu68/AmigaOS"

}

Dev__initfstype2PartUUIDTable()
{
	if [ ${#Dev__fstype2PartUUID[@]} -eq 0 ] ; then
Dev__fstype2PartUUID["luks"]="CA7D7CCB-63ED-4C53-861C-1742536059CC" 
Dev__fstype2PartUUID["vera"]="8C8F8EFF-AC95-4770-814A-21994F2DBC8F" 
Dev__fstype2PartUUID["ext4"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux or 9300 for sgdik
Dev__fstype2PartUUID["ext3"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux or 9300 for sgdik
Dev__fstype2PartUUID["ext2"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux or 9300 for sgdik
Dev__fstype2PartUUID["exfat"]="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" # Microsoft basic data partition
Dev__fstype2PartUUID["vfat"]="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" # Microsoft basic data partition
Dev__fstype2PartUUID["ntfs"]="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" # Microsoft basic data partition
Dev__fstype2PartUUID["zfs"]="6A898CC3-1DD2-11B2-99A6-080020736631"
Dev__fstype2PartUUID["xfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # SiliconValley Linux => IRIX systems
Dev__fstype2PartUUID["btrfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux or 9300 for sgdik. Correct?
# UBIFS is a flash file system for unmanaged flash memory devices.
Dev__fstype2PartUUID["ubifs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Deemed to be Linux, but NOT 100% SURE
Dev__fstype2PartUUID["VMFS"]="AA31E02A-400F-11DB-9590-000C2911D1B8" # or "FB00" 
Dev__fstype2PartUUID["squashfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
Dev__fstype2PartUUID["squashfs3"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
Dev__fstype2PartUUID["bfs"]="EB00"
Dev__fstype2PartUUID["befs"]="EB00"
Dev__fstype2PartUUID["nilfs2"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Deemed to be Linux, but NOT 100% SURE
# f2fs intended for flash storage SSDs, eMMC, and UFS, NAND flash memory-based storage devices
Dev__fstype2PartUUID["f2fs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # deemed to be Linux based, for Android
Dev__fstype2PartUUID["apfs"]="7C3457EF-0000-11AA-AA11-00306543ECAC"
Dev__fstype2PartUUID["exfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # UNSURE
Dev__fstype2PartUUID["reiserfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # ReiserFS est le nom d'un système de fichiers conçu et développé par Hans Reiser. Il est principalement utilisé par GNU/Linux.
# jfs not sure if it should be 45B0969E-9B03-4F30-B4C6-B4B80CEFF106 for "journal" or linux
Dev__fstype2PartUUID["jfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" #  Journaled File System), by IBM for AIX=> Linux
Dev__fstype2PartUUID["hfsplus"]="48465300-0000-11AA-AA11-00306543ECAC"
Dev__fstype2PartUUID["hfs"]="48465300-0000-11AA-AA11-00306543ECAC"
Dev__fstype2PartUUID["ufs"]="A800" # "55465300-0000-11AA-AA11-00306543ECAC" # Apple UFS container
Dev__fstype2PartUUID["hpfs"]="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" # hpfs precursor of ntfs Microsoft basic data partition
Dev__fstype2PartUUID["sysv"]="6300"  # "0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
Dev__fstype2PartUUID["xenix"]="0200" #"0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
Dev__fstype2PartUUID["minix"]="8000" # "0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
Dev__fstype2PartUUID["cramfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
Dev__fstype2PartUUID["romfs"]="0FC63DAF-8483-4772-8E79-3D69D8477DE4" # Linux
	fi
}

Dev__initfstype2PartUUIDTable
Dev__initPartTypes

Dev__isBlockDevice() {
	local __ftype=""
	Dev__getFileType "$1" __ftype
	Str__startsWith "$__ftype" "block"
}

Dev__isRegularFile() {
	local __ftype=""
	Dev__getFileType "$1" __ftype
	Str__startsWith "$__ftype" "regular"
}

Dev__getFileType() {
	local file="$1"
	local -n ftype=$2
	read ftype < <(stat -c "%F" "$file" 2>/dev/null)
    Str__toLower ${!ftype}
}

:<<'EOF'
Retrieves the block device size
@param [1] device path
@return 0 
@output echoes the size on stdout
EOF

Dev__getBlockDeviceParent() {
	local dev="$1"
	local parentDev="$(Str__tail "$(lsblk -n --paths -o name,pkname "$dev"|head -n1 2>>"${__LOG_ERR_FILE__}")" ' ')"  # for parent, it also displays the childs
	Str__trim "$parentDev" parentDev
	if [ "$dev" == "$parentDev" ] ; then
		echo ""
	else
		echo "$parentDev"
	fi
	return 0
}

:<<'EOF'
Retrieves the block device size
@param [1] device path
@return 0 
@output echoes the size on stdout
EOF

Dev__blockDeviceSize() {
	local res
	Str__trim "$(lsblk -n -o SIZE "$1"|head -n1)" res 
	echo "$res"
	return 0
}

:<<'EOF'
Retrieves the block device label
@param [1] device path
@param [2] out ref to var where to store label.
@return return value of lsblk command executed
EOF

Dev__getBlockDeviceLabel() {
	local devpath="$1"
	local -n out_res=$2
	local lsblk
	local ret
	lsblk="$(lsblk -n -o LABEL "$devpath")"
	ret=$?
	Str__trim "$lsblk" out_res
	return $ret
}

:<<EOF
Retrieves the source and mount point from an argument which is either the source
or the mount point. This function relies on 'mount' command which prevents it
from blocking in case of broken connections.

@param [1] mountpoint
@param [2] out source found
@param [2] out mount point found
EOF
Dev__findMount() {
	local inputRef="$1"
	local -n out_foundSource=$2
	local -n out_foundMountpoint=$3
	local mountRes=($(mount | \
		awk -i "${__SHELL_API_DEV_DIR__}/../awk-api/awk-api-core.awk" \
		-v ref="$inputRef" -F' ' '{
				LOG_DEBUG=1
                nbMountingItemInfos=split($0,mountedItemInfos," ")
                mountedDevpath=mountedItemInfos[1]
                mountedFolder=mountedItemInfos[3]
                if (nbMountingItemInfos>=4)
                {
					j=4
					# This is to handle the case where he mount folder path contains spaces
					# to concatenate the remaining path parts which were separated by the spaces.
					# Indeed, in that case, splitting with a space is not enough and correct.
					while (mountedItemInfos[j]!="type")
					{
							mountedFolder=mountedFolder" "mountedItemInfos[j]
							j=j+1 
					}
					# log_dbg($1 " ---- " escapeSpaces(mountedFolder,"\\\ "))
					if (($1==ref) || (mountedFolder==ref)) { print $1,escapeSpaces(mountedFolder,"§§") ; exit 0 }
				}
               }'
		))
#_log_dbg "CHECK ref='$inputRef' '$mountRes' ${#mountRes[@]}"
	if [ ! -z "$mountRes" ] && [ ${#mountRes[@]} -eq 2 ] ; then
		out_foundSource=${mountRes[0]}
		out_foundMountpoint=${mountRes[1]//§§/ }
		return 0
	fi
	return 1
}

:<<EOF
Retrieves the source of a mounted folder.
If a network connection is broken, the findmnt command may block.
As alternative, use findMount above.

@param [1] mountpoint
@param [2] output variable holding the found source
EOF
Dev__findMountSource() {
	local mountpoint="$1"
	local -n out_src=$2
	out_src="$(findmnt -n --mountpoint "${mountpoint}" -o SOURCE 2>>"${__LOG_ERR_FILE__}")"
	return $?
}

:<<EOF
Retrieves the mounted folder from a source device

@param [1] device path
@param [2] output variable
EOF

Dev__findMountPoint() {
	local blkDevice="$1"
	local -n out_mountpoint=$2
	out_mountpoint="$(findmnt -n --source "${blkDevice}" -o TARGET 2>>"${__LOG_ERR_FILE__}")"
	return $?
}

:<<EOF
Retrieves the options from a source device

@param [1] device path
@param [2] output variable
EOF

Dev__findMountPointOptions()
{
	local blkDevice="$1"
	local -n out_mountoptions=$2
	
	out_mountoptions="$(findmnt -n --source "${blkDevice}" -o options 2>>"${__LOG_ERR_FILE__}")"
	return $?
}        

:<<EOF
Retrieves a device specific info with udevadm tool 
@param [1] block device
@param [2] the type of data requested
@return 0 if the requested data was found, 1 otherwise and the output data is set to "-"
EOF

Dev__getDeviceInfo() {
	local blkDevice="$1"
	local device_info="$2"
	local -n out_deviceinfo=$3
	local allDeviceInfos="$(udevadm info "${blkDevice}" 2>>"${__LOG_ERR_FILE__}")"
	local lines=()
	local line
	local i=0

	while IFS= read -r line
	do 	
		Str__trimEnd "$line" line
			local fields=()
			readarray -t -d'=' fields <<< "$line"
			local f1=${fields[0]}
			local f2=${fields[1]}
			Str__trimEnd "$f1" f1
			Str__trimEnd "$f2" f2
			if [ "${f1}" == "$device_info" ] ; then
					out_deviceinfo="${f2}"
					return 0
			fi
		i=$(( $i + 1))
	done <<< "$allDeviceInfos"
	out_deviceinfo="-"
	return 1
}

:<<EOF
Tells whether the device bound with the passed block device path is 
bootable. 
For that purpose, the output of 'parted' is analysed for
search for the first partition id '1:' and the 'boot' keyward
Requires root priviledges.
@param [1] block device path
@returns true (0) when device is bootable, false (1) when not, <0 on usage error.
EOF

Dev__isBootable()
{
    if ! Args__checkCount "${FUNCNAME[0]}" 1 "$#" ; then return -1 ; fi

	local devpath="$1"
	local gPartedOutput="$(${__SUDO__}parted "$devpath" print 2>>"${__LOG_ERR_FILE__}")"
	local dflagseen=1
	local partline=""

	while IFS= read -r partline
	do 
		Str__squeeze "$partline" partline
		Str__trim "$partline" partline
		local fields=()
		local field
		local i=0
		readarray -t -d' ' fields <<< "$partline"
		local f1=${fields[0]}
		local f2=${fields[1]}
		Str__trimEnd "$f1" f1
		Str__trimEnd "$f2" f2

		if [ $dflagseen -eq 0 ] ;then			
			if [ "$f1" == "1" ]  ; then
				if Str__contains "${fields[*]}" "boot" ; then
					return 0
				else
					return 1
				fi
			fi
		elif [ "$f1" == "Disk" ]  && [ "$f2" == "Flags:" ] ; then
			dflagseen=0
		fi
	done <<< "$gPartedOutput"

	return 1
}

:<<EOF
This function uses gdisk to determine the type of the boot record of the device (if any)
among GPT, MDR, APM and BSD, and request 'parted' to determine whether the device is actually
bootable
@param [1] system device path
EOF

Sytem__getBootType()
{
	local devpath="$1"
	local -n out_boottype=$2
	local gdiskOutput=""
#echo "$gdiskOutput"
	local isBootable=1
	local i=0
	local isGPT=0
	local isMBR=0
	local isAPM=0
	local isBSD=0
	local boottypes=(GPT MDR APM BSD)
	local boottypesFlags=(isGPT isMBR isAPM isBSD)
	local nbBoot=0

	gdiskOutput="$(${__SUDO__}gdisk -l "$devpath")"
	boottype=""
	if Dev__isBootable "$devpath" ; then	
		isBootable=0
	fi
	local line=""
	while IFS= read -r line
	do 
		Str__trim "$line" line
		#echo $line
		i=0
		while [ $i -lt "${#boottypes[@]}" ]
		do
			#echo "START '${boottypes[$i]}: not present'"
			local checkStart="${boottypes[$i]}: not present"
	#echo "checking '$line' against '$checkStart'"
			if Str__startsWith "$line" "$checkStart"; then 
				eval ${boottypesFlags[$i]}=1
			fi
			i=$(( $i + 1 ))
		done
	done <<< "${gdiskOutput}"

	i=0
	while [ $i -lt "${#boottypes[@]}" ]
	do
		if [ "${!boottypesFlags[$i]}" -eq 0 ] ; then
			if [ $isBootable -eq 0 ] ; then 
				if [ $nbBoot -gt 0 ] ; then out_boottype="$out_boottype,"; fi
				out_boottype="${out_boottype}${boottypes[$i]}"
				nbBoot=$((nbBoot+1))
				if [ "${boottypes[$i]}" == "GPT" ] ; then
					break;
				fi
			fi
		fi
		i=$(( $i + 1 ))
	done

	if [ $nbBoot -eq 0 ] ; then
		out_boottype="-"
		return 1
	else
		return 0
	fi
}

:<<'EOF'
Erases any trace of a file system on the specified block device using wipefs
@param [1] output block device path
EOF
Dev__wipeDisk()
{
	if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "Usage: <block device path>"; then return 1; fi
	local output="$1"
	local creationcmd="${__SUDO__}wipefs -a --force '${output}'"
	_logf "DISK WIPING: $creationcmd"
	eval "$creationcmd" &>>"${__LOG_ERR_FILE__}"
}

:<<'EOF'
Erases any trace of a file systems on the specified block device by zeroing the first 1M of the device.
ATTENTION: this operation is destructive, use with care!
ATTENITION: this may not work with GPT because there may be backup sectors, use wipefs -a --force
@param [1] output block device path
EOF
Dev__resetDiskDevice()
{
	if ! Args__checkCount ${FUNCNAME[0]} 1 "$#" "Usage: <block device path>"; then return 1; fi
	local output="$1"
	local creationcmd="${__SUDO__}dd if=/dev/zero of='${output}' bs=1M count=1 && sync"
	_logf "DISK CREATION COMMAND: $creationcmd"
	eval "$creationcmd" &>>"${__LOG_ERR_FILE__}"
}

Dev__getDeviceFSType()
{
	local device="$1"
	local -n __out_fstype=$2
	__out_fstype="$(lsblk -n -o FSTYPE "$device"|tail -n1)"
}

:<<'EOF'
Generic low-level wrapper for creating a basic raw disk image filled with 0. 
This operation is time-consuming and may only be useful when handling disks in regular files.

@param [1] output disk image file path or block device path
@param [2] output disk size in bytes
@param [2] block size (e.g. 512 or 1024)
@returns the value of 'dd' commands
EOF

Dev__createRawDiskImage()
{
	if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <file or block device path> <total size> <block size>"; then return 1; fi

	local output="$1"
	local size="$2"
	local blockSize="$3"

	local creationcmd="dd if=/dev/zero of='${output}' iflag=fullblock bs=${blockSize} count=$(( ${size} / ${blockSize} )) && sync"
	_logf "DISK CREATION COMMAND: $creationcmd"
	eval "$creationcmd" &>>"${__LOG_ERR_FILE__}"
}

:<<'EOF'
Generic low-level wrapper for creating a partition given a file system type.
The type of partitition is deduced from the file system type, but not file system is created.
Take care, this function can have destructive effect.
@param [1] disk image file path or block device path
@param [2] expected file system to be host to deduce the partition type to create
@param [3] boolean telling whether root priviledges are required (0=true, false otherwise)

EOF

Dev__createSinglePartition()
{	
        if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <disk file path or block device path> <filesystem type> <O|1>"; then return 1; fi
        _log_dbg "${FUNCNAME[0]} $1 $2"
		local fstype="$2"
		local rootNeeded=$3

		#echo "ALL TYPES: ${Dev__fstype2PartUUID[@]}"

		local parttypeUUID="${Dev__fstype2PartUUID["$fstype"]}"
		if [ -z "${parttypeUUID}" ] ; then
			_log_err "Could not deduce hosting partition type for file system '$fstype'. Possibly invalid file system type."
			return 1
			#_log_warn "Could not deduce hosting partition type for file system '$fstype'. Using Linux by default."
			#parttypeUUID="8300"
		fi

        #_log "Creating single partition on disk"
		# -o: clear partition table
		# -g: convert MDR to GPT
        local cmd="/sbin/sgdisk -o -g -n 1:0:0 -t 1:${parttypeUUID} \"$1\""
        if [ $rootNeeded -eq 0 ] ; then
                cmd="${__SUDO__}$cmd"
        fi
        _logf "CREATE PARTITION: $cmd"
        eval "$cmd" &>>"${__LOG_ERR_FILE__}"
        if [ $? -ne 0 ] ; then
                _log_err "failed to create partition on disk"
                return 1
        else 
                return 0
        fi
}

:<<'EOF'
Generic low-level wrapper for creating directly a basic  partition by script without 
having to specify a file system type in advance like Dev__createSinglePartition() function.
Take care, this function can have destructive effect.
@param [1] disk image file path or block device path
@param [2] expected file system to be host to deduce the partition type to create
@param [3] boolean telling whether root priviledges are required (0=true, false otherwise)

EOF

Dev__createSinglePartitionDirect()
{	
        if ! Args__checkCount ${FUNCNAME[0]} 3 "$#" "Usage: <disk file path or block device path> <filesystem type> <O|1>"; then return 1; fi
        _log_dbg "${FUNCNAME[0]} $1 $2"
		local __dev="$1"
		local __uuid="$2"
		local rootNeeded=$3

		#echo "ALL TYPES: ${Dev__fstype2PartUUID[@]}"

        if [ -z "${Dev__PartitionTypes["${__uuid}"]}" ] ; then
			_log_err "Partition type UUID '${__uuid}' is not recognized.."
			return 1
		fi

        #_log "Creating single partition on disk"
		# -o: clear partition table
		# -g: convert MDR to GPT
        local cmd="/sbin/sgdisk -o -g -n 1:0:0 -t 1:${__uuid} \"${__dev}\""
        if [ $rootNeeded -eq 0 ] ; then
                cmd="${__SUDO__}$cmd"
        fi
        _logf "CREATE PARTITION: $cmd"
        eval "$cmd" &>>"${__LOG_ERR_FILE__}"
        if [ $? -ne 0 ] ; then
                _log_err "failed to create partition on disk"
                return 1
        else 
				# Call partprobe to force partition to become visible
				local __partitions
				Dev__getPartitionDevices "${__dev}" __partitions
                return 0
        fi
}

:<<EOF
Returns the device mapper name for a block device. If none exists, the original input block device path
is returned.

This function may be systematically called whatever the source is, 
which may result in message like "Device sdb1 not found\nCommand failed." on stderr
This is however harmless and shall be hidden, otherwise this misleads the log reader in thinking 
there's an error.

@param [1] Block device path
@param [2] Prefix to add to the found device mapper
@param [3] Ref to variable where to store device mapper name
EOF

Dev__getDeviceMapper()
{
	local logicalVolumePath="$1"
	local -n logicalVolumePath_deviceMapper=$3

	# Find the actual device mapper
	read logicalVolumePath_deviceMapper < <(${__SUDO__}dmsetup info --noheadings "$logicalVolumePath"  2>> /dev/null) #"${__LOG_ERR_FILE__}"
	# Here, logicalVolumePath_deviceMapper is e.g. Name:              debian--amd64--vg-home
	# Let extract the data:
	if [ $? -eq 0 ] ; then
		logicalVolumePath_deviceMapper=${logicalVolumePath_deviceMapper#*:}
		Str__trim "${logicalVolumePath_deviceMapper}" logicalVolumePath_deviceMapper
		logicalVolumePath_deviceMapper="${2}${logicalVolumePath_deviceMapper}"
	else
		logicalVolumePath_deviceMapper="$logicalVolumePath"
	fi
	_log_dbg "logicalVolumePath: '$logicalVolumePath'"
	_log_dbg "logicalVolumePath_deviceMapper: '$logicalVolumePath_deviceMapper'"
}

:<<EOF
@param [1] the top LVM group device for which to get the underlying system devices mapping actual partitions
EOF

Dev__getLVMPartitionDevices()
{
        local device="$1"
        local -n out_lvDeviceList=$2
        local pvLine
        local pvLineDataFound=1
        while IFS= read -r pvLine 
        do
                pvLineDataFound=0
                local pvLineAsArray=($pvLine)
                local volumeGroup=${pvLineAsArray[1]}
                #log_dbg "Found VG '$volumeGroup' for '$pdev'"
                out_lvDeviceList="${out_lvDeviceList}VG:${volumeGroup} "
                local lvLine
                while IFS= read -r lvLine 
                do
                        local lvLineAsArray=($lvLine)
                        local logicalVolume=${lvLineAsArray[0]}
						local logicalVolumePath="/dev/${volumeGroup}/${logicalVolume}"

                        #log_dbg "Found logical volume '$logicalVolume' for '$volumeGroup'"                                                                
                        out_lvDeviceList="${out_lvDeviceList}${logicalVolumePath} "
                done < <(${__SUDO__}lvs --noheadings -q "$volumeGroup" 2>>"${__LOG_ERR_FILE__}")
        done < <(${__SUDO__}pvs --noheadings -q "$pdev" 2>>"${__LOG_ERR_FILE__}")
        if [ $pvLineDataFound -ne 0 ] ; then
                _log_err "Failed to find volume groups for PV $pdev"
        fi
}

:<<EOF
Get the devices which are mapping partitions for the specified system device, which is assumed to be
a top disk device.

Uses sfdisk, partprobe, 

@param [1] the disk device for which to get the underlying system devices mapping partitions
@param [2] out a list of space-separated device paths
EOF

Dev__getPartitionDevices()
{
        local rootDevice="$1"
        local -n out_deviceList=$2
        local lcount=0
        local partLine
		local cmd="${__SUDO__}partprobe \"$rootDevice\""
		_logf "COMMAND: $cmd"
        if eval "$cmd" 2>>"${__LOG_ERR_FILE__}" ; then
                while IFS= read -r partLine
                do 
                        lcount=$(($lcount+1))
                        if [ $lcount -gt 1 ] ; then # ignore first line header

                                local lineAsArray=($partLine)
                                local pdev=${lineAsArray[0]}
                                local ptype=${lineAsArray[@]:1}

                                #echo "Found partition device '$partLine', $pdev,$ptype"

                                if [[ "$ptype" =~ "LVM" ]] ; then
                                        local LVMdevs
                                        Dev__getLVMPartitionDevices "$pdev" LVMdevs                           
                                        out_deviceList="${out_deviceList}${LVMdevs}"
                                else
                                        out_deviceList="${out_deviceList}$pdev "
                                fi
                        fi
                done < <(${__SUDO__}sfdisk -q -l "$rootDevice" -o device,type 2>>"${__LOG_ERR_FILE__}") # <(${__SUDO__}parted  "$rootDevice" print)                        
        fi

		local retGetPartitionDevices=$?
		Str__trimEnd "${out_deviceList}" out_deviceList # Returns the number of trimmed chars. 
		return $retGetPartitionDevices
}

:<<EOF
Provided a disk block device, this function deactivates all volume groups inside that disk.
It is assumed that partitions inside the volume group(s) have been unmounted.

This uses 'vgchange -a n' command. Other commands, see 'Dev__getPartitionDevices'

@param [1] the disk device for which to get the underlying system devices mapping partitions
@param [2] out a list of space-separated device paths
@returns 0 if at least the partition of the devices could be resolved and VG could be deactivate, 1 otheriwse.
EOF

Dev__deactivateAllVolumeGroupsForDisk()
{
	local diskBlockDev="$1"
	local allDiskPartDevices
	if Dev__getPartitionDevices "$diskBlockDev" allDiskPartDevices ; then
		local currentDevice
		local allDeviceList=(${allDiskPartDevices})
		for currentDevice in ${allDeviceList[@]} 
		do
			if Str__startsWith "$currentDevice" "VG:" ; then
					Str__toTail currentDevice "VG:" last
					if ! ${__SUDO__}vgchange -a n "$currentDevice" ; then
							_log_warn "Failed to deactivate LVM Volume Group '$currentDevice'."
							return 1
					fi
			fi
		done
		return 0
	fi
	return 1
}

:<<'EOF'
Allocates a loop device for the file specified as first argument.
@param [1] disk file name
@param [2] disk type
@param [3] out loop block device
@return 0 only on sucess
EOF

Dev__loop_open()
{
        local diskFileName="$1"
        local diskType="$2" # Not use at the moment
        local -n out_diskBlockDevice=$3

        ${__SUDO__}modprobe loop # First we will enable loopback if it wasn't already enabled:

        # Now we can request a new (free) loopback device:
        out_diskBlockDevice=$(${__SUDO__}/sbin/losetup -f)
        if [ $? -eq 0 ] ; then
                # Next we create a device for the image
                local cmd="${__SUDO__}/sbin/losetup \"${out_diskBlockDevice}\" \"${diskFileName}\"" 
                _logf "losetup COMMAND: $cmd"
                eval "$cmd" 2>>"${__LOG_ERR_FILE__}"
                res=$?
                _log_dbg "My device is ${out_diskBlockDevice}"
                return $res
        else
                return 1
        fi
}



:<<EOF
Retrieves the mounted folder for a Vera volume (file name)
given as first argument.

@param [1] absolute path of Vera encrypted file
@param [2] output variable where the mount point will be stored
EOF

Vera__findMountPointFromVolume() {
	local fullpath="${1// /§§}"
	local -n out_folderpath=$2
#	_log_dbg "Vera__findMountPointFromVolume for $fullpath\
#$(Vera_getEscapedList|awk -F' ' -i "${__SHELL_API_DEV_DIR__}/../awk-api/awk-api-core.awk" -v param="${fullpath}" '{ print "dbg processing" $0  " ! field 2=" $2 " ! field 4=" $4|"cat 1>&2" }')"
# printf("'%s' vs '%s'", $2, param) |"cat 1>&2" ; 
	out_folderpath=$(Vera_getEscapedList|\
awk -F' ' -i "${__SHELL_API_DEV_DIR__}/../awk-api/awk-api-core.awk" -v param="${fullpath}" '{ if ($2==param) { print $4; exit 0 } }' 2>>"${__LOG_ERR_FILE__}")
}

:<<EOF
Retrieves the mounted folder for a Vera slot number given as first argument.

@param [1] Slot number
@param [2] output variable where the mount point will be stored
EOF

Vera__findMountPointFromSlot() {
	local slotNbr="$1"
	local -n out_folderpath=$2
	out_folderpath=$(Vera_getEscapedList --slot "$slotNbr"|awk -F' ' -v param="${slotNbr}:" '{if ($1==param) print $4}' 2>>"${__LOG_ERR_FILE__}")
	[ ! -z "${out_folderpath}" ]
}

:<<EOF
Retrieves the slot number from a VERA mountpoint.

@param [1] Mount point path
@param [2] output variable where the slot number will be stored
EOF
Vera__findLabelFromMountPoint() {
	local mntp="$1"
	local -n out_label=$2
	out_label=$(Vera_getEscapedList|awk -F' ' -v param="${mntp}" '{if ($4==param) print $1}' 2>>"${__LOG_ERR_FILE__}")
}

:<<EOF
This routine enables to get the vera list where all spaces within simple quites are espaced with '§§' chars,
so that it can be safely processed by awk.
It also redirects the standard error to /dev/null.
EOF

Vera_getEscapedList()
{
	local additionalOption=""
	if [ $# -gt 0 ] ; then additionalOption="$@" ; fi

	veracrypt -l ${additionalOption} 2>>"${__LOG_ERR_FILE__}"| awk "{ 
   head = \"\" ;
   while ( match(\$0,\"'[^']*'\") ) {
      head = head substr(\$0,1,RSTART-1) gensub(/ /,\"§§\",\"g\",substr(\$0,RSTART,RLENGTH)) ;
      \$0 = substr(\$0,RSTART+RLENGTH) 
   } ; 
   print head \$0 
   }" 
}




Adb__getVersion()
{
	local -n __out_androidVersion=$1
    read -r __out_androidVersion< <(adb shell getprop ro.build.version.release 2>/dev/null)
}


Adb__getSDKVersion()
{
	local -n __out_androidSDKVersion=$1
    read -r __out_androidSDKVersion< <(adb shell getprop ro.build.version.sdk 2>/dev/null)
}

Adb__getDeviceName()
{
	local -n __out_androidDeviceName=$1
	__out_androidDeviceName=""
	local adbResLine=""
	while IFS= read -r adbResLine
	do
		Str__trim "${adbResLine}" adbResLine
		local adbResFieldValues=()
		local adbReslineNorm="${adbResLine//[[:space:]]/ }"
		readarray -t -d' ' adbResFieldValues <<< "$adbReslineNorm"
#_log_vars adbResLine adbReslineNorm
#_log "${#adbResFieldValues[@]}"
		if [ ${#adbResFieldValues[@]} -ge 2 ] ; then
			local adbResDeviceName="${adbResFieldValues[0]}"
			local adbResDeviceStatus="${adbResFieldValues[1]}"
#_log_vars adbResDeviceName adbResDeviceStatus

			local adbResDeviceNameLower="${adbResDeviceName}"
			local adbResDeviceStatusLower="${adbResDeviceStatus}"
			Str__toLower adbResDeviceNameLower
			Str__toLower adbResDeviceStatusLower
			if ! Str__startsWith "${adbResDeviceNameLower}" "list" ; then
					if Str__startsWith "${adbResDeviceStatusLower}" "device" ; then
							Str__trim "${adbResDeviceName}" adbResDeviceName
							__out_androidDeviceName="${adbResDeviceName}"
							return 0
					fi
			fi
		fi

	done< <(adb devices 2>/dev/null)
	return 1
}


Adb__listDevices()
{
	local -n __out_androidDeviceList=$1
	local -n __out_androidDeviceUnauthList=$2
	local -n __out_androidDeviceUnauthStatusList=$3
	__out_androidDeviceList=()
	local adbResLine=""
	while IFS= read -r adbResLine
	do
		Str__trim "${adbResLine}" adbResLine
		local adbResFieldValues=()
		local adbReslineNorm="${adbResLine//[[:space:]]/ }"
		readarray -t -d' ' adbResFieldValues <<< "$adbReslineNorm"
#_log_vars adbResLine adbReslineNorm
#_log "${#adbResFieldValues[@]}"
		if [ ${#adbResFieldValues[@]} -ge 2 ] ; then
			local adbResDeviceName="${adbResFieldValues[0]}"
			local adbResDeviceStatus="${adbResFieldValues[1]}"
#_log_vars adbResDeviceName adbResDeviceStatus

			local adbResDeviceNameLower="${adbResDeviceName}"
			local adbResDeviceStatusLower="${adbResDeviceStatus}"
			Str__trim "${adbResDeviceName}" adbResDeviceName
			Str__toLower adbResDeviceNameLower
			Str__trim "${adbResDeviceStatusLower}" adbResDeviceStatusLower
			Str__toLower adbResDeviceStatusLower
			if ! Str__startsWith "${adbResDeviceNameLower}" "list" ; then
					if Str__startsWith "${adbResDeviceStatusLower}" "device" ; then
							__out_androidDeviceList+=("${adbResDeviceName}")
					else #if Str__startsWith "${adbResDeviceStatusLower}" "unauthorized" ; then
							__out_androidDeviceUnauthList+=("${adbResDeviceName}") # Put all other there in __out_androidDeviceUnauthList
							__out_androidDeviceUnauthStatusList+=("${adbResDeviceStatusLower}") # Put all other there in __out_androidDeviceUnauthList
					fi
			fi
		fi

	done< <(adb devices 2>/dev/null)
	return 0
}




