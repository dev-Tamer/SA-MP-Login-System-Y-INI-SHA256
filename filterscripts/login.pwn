#pragma warning disable 239 //Para el nuevo compilador...

#include <a_samp>
#include <YSI_Storage\y_ini>

#define USER_PATH_ACCOUNT "cuentas/%s.ini"

// limites
#define MAX_CELLS_HASH 65
#define MAX_PASSWORD_ATTEMS 3

// macros
#define function%0(%1) forward%0(%1); public%0(%1)

// valores defaults

#define DEFAULT_PLAYER_POS_X 0.0
#define DEFAULT_PLAYER_POS_Y 0.0
#define DEFAULT_PLAYER_POS_Z 0.0
#define DEFAULT_PLAYER_POS_ANGLE 0.0
#define DEFAULT_PLAYER_SKIN 2

enum
{
	DIALOG_REGISTRO,
	DIALOG_LOGIN
};
enum p_info
{
	PLAYER_PASSWORD[MAX_CELLS_HASH],
	PLAYER_NAME[MAX_PLAYER_NAME],
	PLAYER_SALT[17],
	bool:PLAYER_LOGEADO,
	Float:PLAYER_POS[4],
	PLAYER_PASSWORD_ATTEMPS,
	PLAYER_SKIN
};

//array's
new PLAYER_INFO[MAX_PLAYERS][p_info];

// eventos

#if defined FILTERSCRIPT

public OnFilterScriptInit()
{
	print(">>\n");
	print("Sistema de guardado y cargado de cuentas (SHA-256) - Manuel_Hernandezz");
	print("\n>>");
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

#else

main()
{

}

public OnGameModeInit()
{
	print(">>\n");
	print("Sistema de guardado y cargado de cuentas (SHA-256) - Manuel_Hernandezz");
	print("\n>>");
	return 1;
}
public OnGameModeExit()
{
	return 1;
}

#endif

public OnPlayerConnect(playerid)
{
	ResetPvar(playerid); // Va primero que todo para despues asignarle nuevos valores...

	GetPlayerName(playerid, PLAYER_INFO[playerid][PLAYER_NAME], MAX_PLAYER_NAME);

	if(fexist(USER_PATH(playerid)))
	{
		INI_ParseFile(USER_PATH(playerid), "LoadPlayerPassword_data", .bExtra = true, .extra = playerid);
		SHOW_DIALOG(playerid,DIALOG_LOGIN);
	}
	else
	{
		SHOW_DIALOG(playerid,DIALOG_REGISTRO);
	}
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	if(PLAYER_INFO[playerid][PLAYER_LOGEADO] == true)
	{
		SavePlayerAccount_data(playerid);
	}
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_REGISTRO:
		{
			if(!response) return Kick(playerid);
			if(isnull(inputtext)) return SHOW_DIALOG(playerid,DIALOG_REGISTRO);
			if(strlen(inputtext) < 4 || strlen(inputtext) > 32)
			{
				SendClientMessage(playerid,-1,"La contraseña no puede ser menor a 4 digitos ni mayor a 32 digitos");
				SHOW_DIALOG(playerid,DIALOG_REGISTRO);
				return 1;
			}
			for (new i = 0; i < 16; i++) PLAYER_INFO[playerid][PLAYER_SALT][i] = random(94) + 33;
			SHA256_PassHash(inputtext, PLAYER_INFO[playerid][PLAYER_SALT], PLAYER_INFO[playerid][PLAYER_PASSWORD], 65);
		
			new INI:file = INI_Open(USER_PATH(playerid));

			INI_WriteString(file, "password", PLAYER_INFO[playerid][PLAYER_PASSWORD]);
			INI_WriteString(file, "salt", PLAYER_INFO[playerid][PLAYER_SALT]);

			INI_WriteFloat(file, "pos_x", DEFAULT_PLAYER_POS_X);
			INI_WriteFloat(file, "pos_y", DEFAULT_PLAYER_POS_Y);
			INI_WriteFloat(file, "pos_z", DEFAULT_PLAYER_POS_Z);
			INI_WriteFloat(file, "pos_angle", DEFAULT_PLAYER_POS_ANGLE);

			INI_WriteInt(file, "skin", DEFAULT_PLAYER_SKIN);

			INI_Close(file);

			PLAYER_INFO[playerid][PLAYER_POS][0] = DEFAULT_PLAYER_POS_X;
			PLAYER_INFO[playerid][PLAYER_POS][1] = DEFAULT_PLAYER_POS_Y;
			PLAYER_INFO[playerid][PLAYER_POS][2] = DEFAULT_PLAYER_POS_Z;
			PLAYER_INFO[playerid][PLAYER_POS][3] = DEFAULT_PLAYER_POS_ANGLE;
			
			PLAYER_INFO[playerid][PLAYER_SKIN] = DEFAULT_PLAYER_SKIN;
			SetSpawnInfo(playerid, NO_TEAM, PLAYER_INFO[playerid][PLAYER_SKIN],
			PLAYER_INFO[playerid][PLAYER_POS][0],PLAYER_INFO[playerid][PLAYER_POS][2],
			PLAYER_INFO[playerid][PLAYER_POS][1],PLAYER_INFO[playerid][PLAYER_POS][3], 0, 0, 0, 0, 0, 0);

			SpawnPlayer(playerid);

			new str[128]; format(str,sizeof(str),"%s tu cuenta fue creada exitosamente.",PLAYER_INFO[playerid][PLAYER_NAME]);
			SendClientMessage(playerid,-1,str);
		}
		case DIALOG_LOGIN:
		{
			if(!response) return Kick(playerid);
			if(isnull(inputtext)) return SHOW_DIALOG(playerid,DIALOG_LOGIN);
			
			new sha_pass[MAX_CELLS_HASH];
			SHA256_PassHash(inputtext, PLAYER_INFO[playerid][PLAYER_SALT], sha_pass, MAX_CELLS_HASH);

			if(strcmp(sha_pass, PLAYER_INFO[playerid][PLAYER_PASSWORD]) == 0)
			{
				// Contraseña correcta...
				PLAYER_INFO[playerid][PLAYER_LOGEADO] = true;
				
				INI_ParseFile(USER_PATH(playerid), "LoadPlayerAccount_data", .bExtra = true, .extra = playerid);

				SetSpawnInfo(playerid, NO_TEAM, PLAYER_INFO[playerid][PLAYER_SKIN],
				PLAYER_INFO[playerid][PLAYER_POS][0],PLAYER_INFO[playerid][PLAYER_POS][2],
				PLAYER_INFO[playerid][PLAYER_POS][1],PLAYER_INFO[playerid][PLAYER_POS][3], 0, 0, 0, 0, 0, 0);

				SpawnPlayer(playerid);

				new str[128]; format(str,sizeof(str),"Bienvenido de nuevo %s.",PLAYER_INFO[playerid][PLAYER_NAME]);
				SendClientMessage(playerid,-1,str);
			}
			else
			{
				// Contraseña incorrecta...
				if(PLAYER_INFO[playerid][PLAYER_PASSWORD_ATTEMPS] < MAX_PASSWORD_ATTEMS)
				{
					PLAYER_INFO[playerid][PLAYER_PASSWORD_ATTEMPS] ++;
					new str[128]; format(str,sizeof(str),"Contraseña incorrecta %d/"#MAX_PASSWORD_ATTEMS"",PLAYER_INFO[playerid][PLAYER_PASSWORD_ATTEMPS]);
					SendClientMessage(playerid, 0xFF0000FF, str);
					SHOW_DIALOG(playerid,DIALOG_LOGIN);

					return 1;
				}
				else return Kick(playerid); // Kick por pasar el limite de MAX_PASSWORD_ATTEMS - 3 default
			}
		}
	}
	return 1;
}
public OnPlayerSpawn(playerid)
{
	if(PLAYER_INFO[playerid][PLAYER_LOGEADO] == true)
	{
		SetPlayerPos(playerid,PLAYER_INFO[playerid][PLAYER_POS][0],PLAYER_INFO[playerid][PLAYER_POS][1],PLAYER_INFO[playerid][PLAYER_POS][2]);
		SetPlayerFacingAngle(playerid, PLAYER_INFO[playerid][PLAYER_POS][3]);
		SetPlayerSkin(playerid, PLAYER_INFO[playerid][PLAYER_SKIN]);
	}
	return 1;
}
function LoadPlayerPassword_data(playerid, name[], value[])
{
	INI_String("password", PLAYER_INFO[playerid][PLAYER_PASSWORD]);
	INI_String("salt", PLAYER_INFO[playerid][PLAYER_SALT]);

	return 1;
}
function LoadPlayerAccount_data(playerid, name[], value[])
{
	INI_Float("pos_x",PLAYER_INFO[playerid][PLAYER_POS][0]);
	INI_Float("pos_y",PLAYER_INFO[playerid][PLAYER_POS][1]);
	INI_Float("pos_z",PLAYER_INFO[playerid][PLAYER_POS][2]);
	INI_Float("pos_angle",PLAYER_INFO[playerid][PLAYER_POS][3]);

	INI_Int("skin",PLAYER_INFO[playerid][PLAYER_SKIN]);

	return 1;
}
SavePlayerAccount_data(playerid)
{

	GetPlayerPos(playerid, PLAYER_INFO[playerid][PLAYER_POS][0],PLAYER_INFO[playerid][PLAYER_POS][1],PLAYER_INFO[playerid][PLAYER_POS][2]);
	GetPlayerFacingAngle(playerid, PLAYER_INFO[playerid][PLAYER_POS][3]);

	new INI:file = INI_Open(USER_PATH(playerid));

	INI_WriteFloat(file, "pos_x", PLAYER_INFO[playerid][PLAYER_POS][0]);
	INI_WriteFloat(file, "pos_y", PLAYER_INFO[playerid][PLAYER_POS][1]);
	INI_WriteFloat(file, "pos_z", PLAYER_INFO[playerid][PLAYER_POS][2]);
	INI_WriteFloat(file, "pos_angle", PLAYER_INFO[playerid][PLAYER_POS][3]);

	INI_Close(file);
}
stock USER_PATH(playerid)
{
	new name[MAX_PLAYER_NAME],str[128];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	format(str,sizeof(str),USER_PATH_ACCOUNT,name);
	return str;
}
stock ResetPvar(playerid)
{
	new empty_player[p_info]; PLAYER_INFO[playerid] = empty_player;
}

stock SHOW_DIALOG(playerid,dialogid)
{
	switch(dialogid)
	{
		case DIALOG_REGISTRO:
		{
			new str[131+MAX_PLAYER_NAME];
			format(str, sizeof(str), "{FFFFFF}Bienvenido {3BFFFC}%s{FFFFFF} esta cuenta esta registrada\n\
			Escribe una contraseña para registrarte", PLAYER_INFO[playerid][PLAYER_NAME]);
			ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, "Registro", str, "Registrarse", "Salir");
		}
		case DIALOG_LOGIN:
		{
			new str[126+MAX_PLAYER_NAME];
			format(str, sizeof(str), "{FFFFFF}Bienvenido {3BFFFC}%s{FFFFFF} esta cuenta esta registrada\n\
			Escribe la contraseña de la cuenta para ingresar.", PLAYER_INFO[playerid][PLAYER_NAME]);
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", str, "Ingresar", "Salir");
		}
	}
	return 1;
}