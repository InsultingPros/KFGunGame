class KFGGWinMessage extends CriticalEventPlus
	abstract;

//#exec AUDIO IMPORT FILE="..\Sounds\BlueInc.WAV" NAME="BlueInc" GROUP="Team"
//#exec AUDIO IMPORT FILE="..\Sounds\BlueLead.WAV" NAME="BlueLead" GROUP="Team"
//#exec AUDIO IMPORT FILE="..\Sounds\BlueWinRound.WAV" NAME="BlueWinRound" GROUP="Team"
//#exec AUDIO IMPORT FILE="..\Sounds\RedInc.WAV" NAME="RedInc" GROUP="Team"
//#exec AUDIO IMPORT FILE="..\Sounds\RedLead.WAV" NAME="RedLead" GROUP="Team"
//#exec AUDIO IMPORT FILE="..\Sounds\RedWinRound.WAV" NAME="RedWinRound" GROUP="Team"

var(Message) localized string RedWin,BlueWin,Draw;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{

	if( Switch==-1 )
		return Default.Draw;
	else if( Switch<=2 )
		return Default.RedWin;
	else return Default.BlueWin;
}
static simulated function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
//	switch( Switch )
//	{
//	case 0:
//		P.ClientPlaySound(Sound'RedWinRound',true,2.f,SLOT_Talk);
//		break;
//	case 1:
//		P.ClientPlaySound(Sound'RedLead',true,2.f,SLOT_Talk);
//		break;
//	case 2:
//		P.ClientPlaySound(Sound'RedInc',true,2.f,SLOT_Talk);
//		break;
//	case 3:
//		P.ClientPlaySound(Sound'BlueWinRound',true,2.f,SLOT_Talk);
//		break;
//	case 4:
//		P.ClientPlaySound(Sound'BlueLead',true,2.f,SLOT_Talk);
//		break;
//	case 5:
//		P.ClientPlaySound(Sound'BlueInc',true,2.f,SLOT_Talk);
//		break;
//	}
	Super.ClientReceive(P,Switch);
}
static function color GetColor(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2 )
{
	if( Switch==-1 )
		return Default.DrawColor;
	if( Switch<=2 )
		return Class'Hud'.Default.RedColor;
	return Class'Hud'.Default.BlueColor;
}

defaultproperties
{
     RedWin="Red wins!"
     BlueWin="Blue wins!"
     Draw="Round draw!"
     DrawColor=(G=255,R=255)
     PosY=0.300000
     FontSize=2
}
