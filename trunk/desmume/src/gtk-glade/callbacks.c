/* callbacks.c - this file is part of DeSmuME
 *
 * Copyright (C) 2007 Damien Nozay (damdoum)
 * Copyright (C) 2007 Pascal Giard (evilynux)
 * Author: damdoum at users.sourceforge.net
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include "callbacks.h"

/* globals */
int Frameskip = 0;
gboolean ScreenRight=FALSE;
gboolean ScreenGap=FALSE;
gboolean ScreenInvert=FALSE;

/* inline & protos */

inline void SET_SENSITIVE(gchar *w, gboolean b) {
	gtk_widget_set_sensitive(
		glade_xml_get_widget(xml, w), TRUE);
}

void enable_rom_features() {
	scan_savestates();
	update_savestates_menu();
	SET_SENSITIVE("menu_exec", TRUE);
	SET_SENSITIVE("menu_pause", TRUE);
	SET_SENSITIVE("menu_reset", TRUE);
	SET_SENSITIVE("wgt_Exec", TRUE);
	SET_SENSITIVE("wgt_Reset", TRUE);
}

void MAINWINDOW_RESIZE() {
	GtkWidget * spacer1 = glade_xml_get_widget(xml, "misc_sep3");
	GtkWidget * spacer2 = glade_xml_get_widget(xml, "misc_sep4");
	int dim = 66 * ScreenCoeff_Size[0];
	BOOL rotate = (ScreenRotate==90.0 || ScreenRotate==270.0 );

	/* sees whether we want a gap */
	if (!ScreenGap) dim = -1;
	if (ScreenRight && rotate) {
		gtk_widget_set_usize(spacer1, dim, -1);
	} else if (!ScreenRight && !rotate) {
		gtk_widget_set_usize(spacer2, -1, dim);
	} else {
		gtk_widget_set_usize(spacer1, -1, -1);	
		gtk_widget_set_usize(spacer2, -1, -1);	
	}

	gtk_window_resize ((GtkWindow*)pWindow,1,1);
}

/* MENU FILE ***** ***** ***** ***** */
void inline ADD_FILTER(GtkWidget * filech, const char * pattern, const char * name) {
	GtkFileFilter *pFilter;
	pFilter = gtk_file_filter_new();
	gtk_file_filter_add_pattern(pFilter, pattern);
	gtk_file_filter_set_name(pFilter, name);
	gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(filech), pFilter);
}

void file_open() {
	desmume_pause();
	
	GtkWidget *pFileSelection;
	GtkWidget *pParent;
	gchar *sChemin;

	pParent = GTK_WIDGET(pWindow);
	
	/* Creating the selection window */
	pFileSelection = gtk_file_chooser_dialog_new("Open...",
			GTK_WINDOW(pParent),
			GTK_FILE_CHOOSER_ACTION_OPEN,
			GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
			GTK_STOCK_OPEN, GTK_RESPONSE_OK,
			NULL);
	/* On limite les actions a cette fenetre */
	gtk_window_set_modal(GTK_WINDOW(pFileSelection), TRUE);

	ADD_FILTER(pFileSelection, "*.nds", "Nds binary (.nds)");
	ADD_FILTER(pFileSelection, "*.ds.gba", "Nds binary with loader (.ds.gba)");
	ADD_FILTER(pFileSelection, "*", "All files");
	//ADD_FILTER(pFileSelection, "*.zip", "Nds zipped binary");
	
	/* Affichage fenetre*/
	switch(gtk_dialog_run(GTK_DIALOG(pFileSelection)))
	{
		case GTK_RESPONSE_OK:
			/* Recuperation du chemin */
			sChemin = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(pFileSelection));
			if(desmume_open((const char*)sChemin) < 0)
			{
				GtkWidget *pDialog = gtk_message_dialog_new(GTK_WINDOW(pFileSelection),
						GTK_DIALOG_MODAL,
						GTK_MESSAGE_ERROR,
						GTK_BUTTONS_OK,
						"Unable to load :\n%s", sChemin);
				gtk_dialog_run(GTK_DIALOG(pDialog));
				gtk_widget_destroy(pDialog);
			} else {
				desmume_resume();
				enable_rom_features();
			}

			g_free(sChemin);
			break;
		default:
			break;
	}
	gtk_widget_destroy(pFileSelection);
}
 
void  on_menu_ouvrir_activate  (GtkMenuItem *menuitem, gpointer user_data) { file_open();}
void  on_menu_pscreen_activate (GtkMenuItem *menuitem, gpointer user_data) {  WriteBMP("./test.bmp",GPU_screen); }
void  on_menu_quit_activate    (GtkMenuItem *menuitem, gpointer user_data) { gtk_main_quit(); }


/* MENU SAVES ***** ***** ***** ***** */
void on_loadstateXX_activate (GtkMenuItem *m, gpointer d) {
	int slot = dyn_CAST(int,d);
	loadstate_slot(slot);
}
void on_savestateXX_activate (GtkMenuItem *m, gpointer d) {
	int slot = dyn_CAST(int,d);
	update_savestate(slot);
}
void on_savetypeXX_activate (GtkMenuItem *m, gpointer d) {
	int type = dyn_CAST(int,d);
	desmume_savetype(type);
}


/* MENU EMULATION ***** ***** ***** ***** */
void  on_menu_exec_activate   (GtkMenuItem *menuitem, gpointer user_data) { desmume_resume(); }
void  on_menu_pause_activate  (GtkMenuItem *menuitem, gpointer user_data) { desmume_pause(); }
void  on_menu_reset_activate  (GtkMenuItem *menuitem, gpointer user_data) { desmume_reset(); }
void  on_menu_layers_activate (GtkMenuItem *menuitem, gpointer user_data) {
	/* we want to hide or show the checkbox for the layers */
	GtkWidget * w1 = glade_xml_get_widget(xml, "wvb_1_Main");
	GtkWidget * w2 = glade_xml_get_widget(xml, "wvb_2_Sub");
	if (gtk_check_menu_item_get_active((GtkCheckMenuItem*)menuitem)==TRUE) {
		gtk_widget_show(w1);
		gtk_widget_show(w2);
	} else {
		gtk_widget_hide(w1);
		gtk_widget_hide(w2);
	}
	/* pack the window */
	MAINWINDOW_RESIZE();
}

/* SUBMENU FRAMESKIP ***** ***** ***** ***** */
void  on_fsXX_activate  (GtkMenuItem *menuitem,gpointer user_data) {
	Frameskip = dyn_CAST(int,user_data);
//	printf ("setting FS %d %d\n", Frameskip, user_data);
}


/* SUBMENU SIZE ***** ***** ***** ***** */
void rightscreen(BOOL apply) {
	GtkBox * sbox = (GtkBox*)glade_xml_get_widget(xml, "whb_Sub");
	GtkWidget * mbox = glade_xml_get_widget(xml, "whb_Main");
	GtkWidget * vbox = glade_xml_get_widget(xml, "wvb_Layout");
	GtkWidget * w    = glade_xml_get_widget(xml, "wvb_2_Sub");

	/* we want to change the layout, lower screen goes right */
	if (apply) {
		gtk_box_reorder_child(sbox,w,-1);
		gtk_widget_reparent((GtkWidget*)sbox,mbox);
	} else if (!ScreenRight) {
	/* we want to change the layout, lower screen goes down */
		gtk_box_reorder_child(sbox,w,0);
		gtk_widget_reparent((GtkWidget*)sbox,vbox);
	}
	/* pack the window */
	MAINWINDOW_RESIZE();
}
int H=192, W=256;
void resize (float Size1, float Size2) {
	// not ready yet to handle different zoom factors
	Size2 = Size1;
	/* we want to scale drawing areas by a factor (1x,2x or 3x) */
	gtk_widget_set_size_request (pDrawingArea, W * Size1, H * Size1);	
	gtk_widget_set_size_request (pDrawingArea2, W * Size2, H * Size2);	
	ScreenCoeff_Size[0] = Size1;
	ScreenCoeff_Size[1] = Size2;
	/* remove artifacts */
	black_screen();
	/* pack the window */
	MAINWINDOW_RESIZE();
}
void rotate(float angle) {
	BOOL rotated;
	if (angle >= 360.0) angle -= 360.0;
	ScreenRotate = angle;
	rotated = (ScreenRotate==90.0 || ScreenRotate==270.0);
	ScreenInvert = (ScreenRotate >= 180.0);
	if (rotated) {
		H=256; W=192;
	} else {
		W=256; H=192;
	}
	rightscreen(rotated);
	resize(ScreenCoeff_Size[0],ScreenCoeff_Size[1]);
}

void  on_sizeXX_activate (GtkMenuItem *menuitem, gpointer user_data) {
	float f = dyn_CAST(float,user_data);
//	printf("setting ZOOM %f\n",f);
	resize(f,f);
}



/* MENU CONFIG ***** ***** ***** ***** */
u16 Keypad_Temp[NB_KEYS];

void  on_menu_controls_activate     (GtkMenuItem *menuitem, gpointer user_data) {
	edit_controls();
}

/* Show joystick controls configuration dialog
   FIXME: sdl doesn't detect unplugged joysticks!! */
void  on_menu_joy_controls_activate     (GtkMenuItem *menuitem, gpointer
user_data)
{
  GtkDialog * dlg;
  GtkDialog * msgbox;
  char * text;
  
  /* At least one joystick connected?
   Can't configure joystick if SDL Event loop is already running. */
  if( (nbr_joy < 1) || desmume_running() )
    {
      if( nbr_joy < 1 )
        text = "You don't have any joystick!";
      else
        text = "Can't configure joystick while the game is running!";

      dlg = (GtkDialog*)glade_xml_get_widget(xml, "wMainW");
      msgbox =
        gtk_message_dialog_new(dlg, 
                               GTK_DIALOG_MODAL|GTK_DIALOG_DESTROY_WITH_PARENT,
                               GTK_MESSAGE_INFO,
                               GTK_BUTTONS_CLOSE,
                               text
                               );
      g_signal_connect(G_OBJECT(msgbox), "response", G_CALLBACK(gtk_widget_destroy), NULL);

      gtk_dialog_run( msgbox );
    }
  else
    {
      dlg = (GtkDialog*)glade_xml_get_widget(xml, "wJoyConfDlg");
      init_joy_labels();
      gtk_dialog_run(dlg);
    }
}

void  on_menu_audio_on_activate  (GtkMenuItem *menuitem, gpointer user_data) {
	/* we want set audio emulation ON or OFF */
	if (gtk_check_menu_item_get_active((GtkCheckMenuItem*)menuitem)) {
		SPU_Pause(0);
	} else {
		SPU_Pause(1);
	}
}

void  on_menu_gapscreen_activate  (GtkMenuItem *menuitem, gpointer user_data) {
	/* we want to add a gap between screens */
	ScreenGap = gtk_check_menu_item_get_active((GtkCheckMenuItem*)menuitem);

	/* pack the window */
	MAINWINDOW_RESIZE();
}

void  on_menu_rightscreen_activate  (GtkMenuItem *menuitem, gpointer user_data) {
	ScreenRight=gtk_check_menu_item_get_active((GtkCheckMenuItem*)menuitem);
	rightscreen(ScreenRight);
}

void  on_menu_rotatescreen_activate  (GtkMenuItem *menuitem, gpointer user_data) {
	/* we want to rotate the screen */
	float angle = dyn_CAST(float,user_data);
	rotate(angle);
}

/* MENU TOOLS ***** ***** ***** ***** */
void  on_menu_IO_regs_activate      (GtkMenuItem *menuitem, gpointer user_data) {
	GtkWidget * dlg = glade_xml_get_widget(xml_tools, "wtools_1_IOregs");
	gtk_widget_show(dlg);
}

void  on_menu_memview_activate      (GtkMenuItem *menuitem, gpointer user_data) {
	GtkWidget * dlg = glade_xml_get_widget(xml_tools, "wtools_2_MemView");
	gtk_widget_show(dlg);
}

void  on_menu_palview_activate      (GtkMenuItem *menuitem, gpointer user_data) {
	GtkWidget * dlg = glade_xml_get_widget(xml_tools, "wtools_3_PalView");
	gtk_widget_show(dlg);
}





/* MENU ? ***** ***** ***** ***** */
void  on_menu_apropos_activate      (GtkMenuItem *menuitem, gpointer user_data) {
	GtkAboutDialog * wAbout = (GtkAboutDialog*)glade_xml_get_widget(xml, "wAboutDlg");
	gtk_about_dialog_set_version(wAbout, VERSION);
	gtk_widget_show((GtkWidget*)wAbout);
}






/* TOOLBAR ***** ***** ***** ***** */
void  on_wgt_Open_clicked  (GtkToolButton *toolbutton, gpointer user_data) { file_open(); }
void  on_wgt_Reset_clicked (GtkToolButton *toolbutton, gpointer user_data) { desmume_reset(); }
void  on_wgt_Quit_clicked  (GtkToolButton *toolbutton, gpointer user_data) { gtk_main_quit(); }
void  on_wgt_Exec_toggled  (GtkToggleToolButton *toggletoolbutton, gpointer user_data) {
	if (gtk_toggle_tool_button_get_active(toggletoolbutton)==TRUE)
		desmume_resume();
	else 
		desmume_pause();
}



/* LAYERS ***** ***** ***** ***** */
void change_bgx_layer(int layer, gboolean state, NDS_Screen scr) {
	//if(!desmume_running()) return;
	if(state==TRUE) { 
		if (!scr.gpu->dispBG[layer]) GPU_addBack(scr.gpu, layer);
	} else {
		if (scr.gpu->dispBG[layer])  GPU_remove(scr.gpu, layer); 
	}
	//fprintf(stderr,"Changed Layer %s to %d\n",layer,state);
}
void  on_wc_1_BGXX_toggled  (GtkToggleButton *togglebutton, gpointer user_data) {
	int layer = dyn_CAST(int,user_data);
	change_bgx_layer(layer, gtk_toggle_button_get_active(togglebutton), MainScreen);
}
void  on_wc_2_BGXX_toggled  (GtkToggleButton *togglebutton, gpointer user_data) {
	int layer = dyn_CAST(int,user_data);
	change_bgx_layer(layer, gtk_toggle_button_get_active(togglebutton), SubScreen);
}
