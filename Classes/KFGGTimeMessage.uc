class KFGGTimeMessage extends CriticalEventPlus
	abstract;

//#exec AUDIO IMPORT FILE="..\Sounds\UT2K3Fanfare01.WAV" NAME="UT2K3Fanfare01" GROUP="Game"

var(Message) localized string TimeMessages[7],OvertimeMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{

	if( Switch<0 )
		return Default.OvertimeMessage;
	if( Switch<=10 )
		return Switch$"...";
	switch( Switch )
	{
	case 600:
		return Default.TimeMessages[6];
	case 300:
		return Default.TimeMessages[5];
	case 180:
		return Default.TimeMessages[4];
	case 120:
		return Default.TimeMessages[3];
	case 60:
		return Default.TimeMessages[2];
	case 30:
		return Default.TimeMessages[1];
	case 20:
		return Default.TimeMessages[0];
	}
}
static simulated function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
//	if( Switch<0 )
//		P.ClientPlaySound(Sound'UT2K3Fanfare01',true,2.f,SLOT_Talk); // Overtime sound.
	Super.ClientReceive(P,Switch);
}

defaultproperties
{
     TimeMessages(0)="20 seconds..."
     TimeMessages(1)="30 seconds left..."
     TimeMessages(2)="1 minute remains..."
     TimeMessages(3)="2 minutes..."
     TimeMessages(4)="3 minutes..."
     TimeMessages(5)="5 minutes left in the game!"
     TimeMessages(6)="10 minutes left in the game!"
     OvertimeMessage="Overtime!"
     DrawColor=(B=180,G=40,R=255)
     PosY=0.200000
     FontSize=2
}
