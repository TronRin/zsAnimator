version "4.12"

#include "zsanimator.zs"
#include "ssgfire.zs"
#include "shotgunfire.zs"

class ZSASSG : SuperShotgun replaces SuperShotgun
{
	Default
	{
		Weapon.sLotNumber 3;
	}
	
	states
	{
		Fire:
			SHTG A 0 {
				A_FireBullets(11.2, 7.1, 20, 5, "BulletPuff");
				A_StartSound("weapons/sshotf", CHAN_WEAPON);
				A_Overlay(PSP_FLASH, "Flash");
				A_OverlayFlags(PSP_FLASH, PSPF_ADDWEAPON, true);
			}
			SHTG A 0 {
				ZSAnimator animator = ZSanimator(New("ZSAnimator"));
				animator.StartAnimation(player, "ZSAnimationSSGFire");
			}
			SHT2 A 25;
			SHT2 B 3;
			SHT2 C 12;
			SHT2 B 2;
			SHT2 K 3;
			SHT2 K 0 A_Overlay(ZSAnimator.PSP_HANDS, "HandsReload");
			SHT2 K 20;
			SHT2 B 4;
			SHT2 C 11;
			SHT2 A 16;
			goto Ready;
		Flash:
			SHT2 IJ 2 bright;
			stop;
		HandsReload:
			SHT2 L 20;
			stop;
	}
}

class ZSAShotgun : Shotgun replaces Shotgun
{
	action void A_ZSAWeaponReady(int flags = 0)
	{
		if (!player) return;
														DoReadyWeaponToSwitch(player, !(flags & WRF_NoSwitch));
		if ((flags & WRF_NoFire) != WRF_NoFire)			DoReadyWeaponToFire(player.mo, !(flags & WRF_NoPrimary), !(flags & WRF_NoSecondary));
		//if (!(flags & WRF_NoBob))						DoReadyWeaponToBob(player);

		player.WeaponState |= GetButtonStateFlags(flags);														
		DoReadyWeaponDisableSwitch(player, flags & WRF_DisableSwitch);
	}
	
	Default
	{
		Weapon.SlotNumber 3;
	}
	
	action void A_Test()
	{
		ZSAnimator animator = ZSanimator(New("ZSAnimator"));
		animator.StartAnimation(player, "ZSAnimationShotgunFire");
		A_Overlay(PSP_FLASH, "Flash");
		A_OverlayFlags(PSP_FLASH, PSPF_ADDWEAPON, false);
	}
	
	States
	{
		Ready:
			SHTG A 1 A_ZSAWeaponReady();
			loop;
		Fire:
			SHTG A 0 A_FireShotgun();
			SHTG A 0 A_Test();
			SHTG A 9;
			SHTG B 5;
			SHTG C 4;
			SHTG D 3;
			SHTG C 6;
			SHTG B 4;
			SHTG A 6;
			goto Ready;	
		Flash:
			SHTF AB 1 bright;
			stop;
	}
}