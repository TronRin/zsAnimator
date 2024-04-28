version "4.12"

#include "shotgunfire.zs"
#include "ssgfire.zs"

class ZSAnimationFrame
{
	int pspId;
	int frameNum;
	Vector3 cameraAngles;
	Vector2 pspOffsets;
	Vector2 pspScale;
	double pspAngle;
	bool interpolate;
	
	static ZSAnimationFrame Create(int pspId, int frameNum, Vector3 cameraAngles, Vector2 pspOffsets, Vector2 pspScale, double pspAngle, bool interpolate)
	{
		let frame = ZSAnimationFrame(New("ZSAnimationFrame"));
		frame.frameNum = frameNum;
		frame.pspId = pspId;
		frame.cameraAngles = cameraAngles;
		frame.pspOffsets = pspOffsets;
		frame.pspScale = pspScale;
		frame.pspAngle = pspAngle;
		frame.interpolate = interpolate;
		return frame;
	}
}

class ZSAnimationFrameNode
{
	ZSAnimationFrameNode next;
	Array<ZSAnimationFrame> frames;
	
	static ZSAnimationFrameNode Create()
	{
		let node = ZSAnimationFrameNode(New("ZSAnimationFrameNode"));
		return node;
	}
}

Class ZSAnimation
{
	enum AnimFlags
	{
		ZSA_INTERPOLATE = 1 << 0
	}
	
	int frameCount;
	bool running;
	//ZSAnimationFrame previousFrame;
	//Weapon currentWeapon;
	Array<ZSAnimationFrame> frames;
	ZSAnimationFrameNode currentNode;
	
	virtual void MakeFrameList() { }
	virtual void Initialize() { }
	void LinkList()
	{
		//console.printf("linking list, %d frames", frameCount);
		currentNode = ZSAnimationFrameNode.Create();
		ZSAnimationFrameNode last = currentNode;
		//console.printf("base node %p", currentNode);
		for (int f = 0; f <= frameCount; f++)
		{
			ZSAnimationFrameNode n = ZSAnimationFrameNode.Create();
			for (int i = 0; i < frames.Size(); i++)
			{
				ZSAnimationFrame frame = frames[i];
				if (frame.frameNum == f)
				{
					last.frames.push(frame);
					//console.printf("pushed frame %d cur. size %d", f, n.frames.size());
				}
			}
			
			last.next = n;
			last = n;
		}
	}
}

Class ZSAnimator : Thinker
{
	enum SpecialAnimNums
	{
		PlayerView = -5000,
		PSP_HANDS = 1001,
	}
	
	ZSAnimation currentAnimation;
	int currentTicks;
	PlayerInfo ply;
	
	void StartAnimation(PlayerInfo ply, Class<ZSAnimation> animationClass, int frame = 0)
	{
		if (currentAnimation == NULL || currentAnimation.GetClass() != animationClass)
		{
			self.ply = ply;
			currentAnimation = ZSAnimation(New(animationClass));
			console.printf("starting animation %s", currentAnimation.GetClassName());
			currentAnimation.Initialize();
			currentAnimation.MakeFrameList();
			currentAnimation.LinkList();
			currentAnimation.running = true;
		}
	}
	
	override void Tick()
	{
		super.Tick();
		if (currentAnimation)
		{
			if (currentTicks > currentAnimation.frameCount)
			{
				currentTicks = 0;
				currentAnimation.Destroy();
				currentAnimation = null;
				return;
			}
			else
			{
				let n = currentAnimation.currentNode;
				if (n)
				{
					console.printf("i %d", currentTicks);
					for (int i = 0; i < n.frames.size(); i++)
					{
						let f = n.frames[i];
						if (f.pspId != ZSAnimator.PlayerView)
						{
							console.printf("frame %d subframe %d", f.frameNum, i);
							/*if (f.pspId == PSP_WEAPON)
							{
								ply.mo.A_WeaponOffset(f.pspOffsets.x*-1, f.pspOffsets.y*-1 + WEAPONTOP, WOF_INTERPOLATE);
							}
							else
							{
								ply.mo.A_OverlayFlags(f.pspId, PSPF_ADDWEAPON, false);
								//ply.mo.A_OverlayFlags(f.pspId, PSPF_PIVOTPERCENT, true);
								ply.mo.A_OverlayOffset(f.pspId, f.pspOffsets.x*-1, f.pspOffsets.y*-1, WOF_INTERPOLATE);
							}*/
							//ply.mo.A_OverlayPivot(f.pspId, 0.5, 0.5);
							//ply.mo.A_OverlayRotate(f.pspId, f.pspAngle);
							
							let psp = ply.findpsprite(f.pspId);
							if (psp)
							{
								let xOffs = f.pspOffsets.x*-1;
								let yOffs = f.pspOffsets.y*-1;
								if (f.pspId == PSP_WEAPON)
								{
									yOffs += WEAPONTOP;
								}
								psp.bInterpolate = false;//f.interpolate;
								
								psp.x = xOffs;
								psp.y = yOffs;
								if (!f.interpolate)
								{
									psp.oldx = psp.x;
									psp.oldy = psp.y;
								}
								psp.pivot = (0.5,0.5);
								psp.scale = f.pspScale;
								psp.rotation = f.pspAngle;
								console.printf("x y %.2f %.2f", psp.x, psp.y);
								console.printf("scale %.2f %.2f", psp.scale.x, psp.scale.y);
								console.printf("rot %.4f", psp.rotation);
							}
						}
						else
						{
							float viewScale = CVar.FindCVar('zsa_viewscale').GetFloat();
							ply.mo.A_SetViewRoll(f.cameraAngles.x * viewScale, SPF_INTERPOLATE);
							ply.mo.A_SetViewAngle(f.cameraAngles.y * viewScale, SPF_INTERPOLATE);
							ply.mo.A_SetViewPitch(f.cameraAngles.z * viewScale, SPF_INTERPOLATE);
						}
					}
					currentAnimation.currentNode = n.next;
				}
			}
			currentTicks += 1;
		}
	}
}

class ZSAShotgun : Shotgun replaces Shotgun
{
	Default
	{
		Weapon.SlotNumber 3;
	}
	
	action void A_Test()
	{
		ZSAnimator animator = ZSanimator(New("ZSAnimator"));
		animator.StartAnimation(player, "ZSAnimationShotgunFire");
	}
	
	States
	{
		Fire:
			SHTG A 0 A_FireShotgun();
			SHTG A 0 A_Test();
			SHTG A 20;
			SHTG B 3;
			SHTG C 8;
			SHTG D 5;
			SHTG C 3;
			SHTG B 4;
			SHTG A 7;
			goto Ready;	
		Flash:
			SHTF AB 1 bright;
			stop;
	}
}	

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