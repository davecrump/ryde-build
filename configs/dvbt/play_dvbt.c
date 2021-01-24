/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Written by Dave, G8GKQ
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <pthread.h>
#include <fftw3.h>
#include <getopt.h>
#include <linux/input.h>
#include <fcntl.h>
#include <dirent.h>
#include <ctype.h>
#include <math.h>
#include <wiringPi.h>
#include <sys/stat.h> 
#include <sys/types.h> 
#include <time.h>

#define PATH_DVBTCONFIG "/home/pi/dvbt/dvb-t_config.txt"

//GLOBAL PARAMETERS

int debug_level = 1;
int FinishedButton = 1;
char LinuxCommand[255];

char ConfigFreq[63];
char ConfigBW[63];
char ConfigChan[63];
char ConfigAudio[63];


/***************************************************************************//**
 * @brief Looks up the value of a Param in PathConfigFile and sets value
 *        Used to look up the configuration from portsdown_config.txt
 *
 * @param PatchConfigFile (str) the name of the configuration text file
 * @param Param the string labeling the parameter
 * @param Value the looked-up value of the parameter
 *
 * @return void
*******************************************************************************/

void GetConfigParam(char *PathConfigFile, char *Param, char *Value)
{
  char * line = NULL;
  size_t len = 0;
  int read;
  char ParamWithEquals[255];
  strcpy(ParamWithEquals, Param);
  strcat(ParamWithEquals, "=");

  //printf("Get Config reads %s for %s ", PathConfigFile , Param);

  FILE *fp=fopen(PathConfigFile, "r");
  if(fp != 0)
  {
    while ((read = getline(&line, &len, fp)) != -1)
    {
      if(strncmp (line, ParamWithEquals, strlen(Param) + 1) == 0)
      {
        strcpy(Value, line+strlen(Param)+1);
        char *p;
        if((p=strchr(Value,'\n')) !=0 ) *p=0; //Remove \n
        break;
      }
    }
    if (debug_level == 2)
    {
      printf("Get Config reads %s for %s and returns %s\n", PathConfigFile, Param, Value);
    }
  }
  else
  {
    printf("Config file not found \n");
  }
  fclose(fp);
}

/***************************************************************************//**
 * @brief safely copies n characters of instring to outstring without overflow
 *
 * @param *outstring
 * @param *instring
 * @param n int number of characters to copy.  Max value is the outstring array size -1
 *
 * @return void
*******************************************************************************/
void strcpyn(char *outstring, char *instring, int n)
{
  //printf("\ninstring= -%s-, instring length = %d, desired length = %d\n", instring, strlen(instring), strnlen(instring, n));
  
  n = strnlen(instring, n);
  int i;
  for (i = 0; i < n; i = i + 1)
  {
    //printf("i = %d input character = %c\n", i, instring[i]);
    outstring[i] = instring[i];
  }
  outstring[n] = '\0'; // Terminate the outstring
}

/***************************************************************************//**
 * @Reads the Configuration from the Config file
 *
 * @param None
 *
 * @return void
*******************************************************************************/
void ReadConfig()
{
  // Read the current vision source and encoding
  GetConfigParam(PATH_DVBTCONFIG, "freq",  ConfigFreq);
  GetConfigParam(PATH_DVBTCONFIG, "bw",    ConfigBW);
  GetConfigParam(PATH_DVBTCONFIG, "chan",  ConfigChan);
  GetConfigParam(PATH_DVBTCONFIG, "audio", ConfigAudio);
}

/***************************************************************************//**
 * @brief Displays a blank screen with parameter details
 *
 * @param char ScreenMessage
 *
 * @return void
*******************************************************************************/

void DisplayMsg(char* ScreenMessage)
{
  // Delete any old image
  system("sudo rm /home/pi/tmp/message.jpg >/dev/null 2>/dev/null");

  // Build and run the convert command for the image
  strcpy(LinuxCommand, "sudo convert -size 1280x720 xc:black -stroke white ");
  strcat(LinuxCommand, "-gravity NorthWest -pointsize 40 -annotate 0 ");
  strcat(LinuxCommand, "\"Ryde Interim DVB-T Receiver\n\n");
  strcat(LinuxCommand, ScreenMessage);
  strcat(LinuxCommand, "\" /home/pi/tmp/message.jpg");

  //printf("\n\n%s\n\n", LinuxCommand);
  system(LinuxCommand);
  usleep(1000);

  // Display the image on the desktop
  system("sudo fbi -T 1 -noverbose -a /home/pi/tmp/message.jpg >/dev/null 2>/dev/null");

  // Kill fbi
  system("(sleep 0.1; sudo killall -9 fbi >/dev/null 2>/dev/null) &");
}


void DVBTRX()
{
  int num;
  int fd_status_fifo;
  char status_message_char[14];
  char stat_string[255];
  char vlctext[255];
  int Parameters_currently_displayed = 1;  // 1 for displayed, 0 for blank
  int FirstLock = 0;  // set to 1 on first lock, and 2 after parameter fade

  // DVB-T parameters

  char composite[255] = "";

  char line3[31] = "";
  char line4[31] = "";
  char line5[127] = "";
  char line6[31] = "";
  char line7[31] = "";
  char line8[31] = "";
  char line9[31] = "";
  char line10[31] = "";
  char line11[31] = "";
  char line12[31] = "";
  char line13[31] = "";
  char line14[31] = "";
  char linex[127] = "";
  int TunerPollCount = 0;
  bool TunerFound = FALSE;
  bool UpdateDisplay = TRUE;

  // Set globals
  FinishedButton = 1;

    printf("STARTING VLC with FFMPEG DVB-T RX\n");

    // Create DVB-T Receiver thread
    system("/home/pi/dvbt/dvb-t_start.sh");

    // Open status FIFO for read only
    fd_status_fifo = open("/home/pi/knucker_status_fifo", O_RDONLY); 

    // Set the status fifo to be non-blocking on empty reads
    fcntl(fd_status_fifo, F_SETFL, O_NONBLOCK);

    if (fd_status_fifo < 0)  // failed to open
    {
      printf("Failed to open knucker status fifo\n");
    }

    // Flush status message string
    stat_string[0]='\0';

    while ((FinishedButton == 1) || (FinishedButton == 2)) // 1 is captions on, 2 is off
    {
      // Read the next character from the fifo
      num = read(fd_status_fifo, status_message_char, 1);

      if (num < 0)  // no character to read
      {
        usleep(500);
        if (TunerFound == FALSE)
        {
          TunerPollCount = TunerPollCount + 1;
          if (TunerPollCount > 30)
          {
            strcpy(line5, "Knucker Tuner Not Responding");
            TunerPollCount = 0;
          }
        }
      }
      else // there was a character to read
      {
        status_message_char[num]='\0';  // Make sure that it is a single character (when num=1)
        //printf("%s\n", status_message_char);

        if (strcmp(status_message_char, "\n") == 0)  // If end of line, process info
        {
          printf("%s\n", stat_string);  // for test

          if (TunerFound == FALSE)
          {
            if (strcmp(stat_string, "[GetChipId] chip id:AVL6862") == 0)
            {
              strcpy(line5, "Found Knucker Tuner");
              TunerFound = TRUE;
            }
            else  // Fault conditions
            {
              if (strcmp(stat_string, "Tuner not found") == 0)
              {
                strcpy(line5, "Please connect a Knucker Tuner");
              }
              strcpyn(linex, stat_string, 7);  // for destructive test
              if (strcmp(linex, "USB Cmd") == 0)
              {
                strcpy(line5, "USB Error.  Change Cable");
              }
            }
          UpdateDisplay = TRUE;
          }
          
          if (strcmp(stat_string, "[GetFamilyId] Family ID:0x4955") == 0)
          {
            strcpy(line5, "Initialising Tuner, Please Wait");
            UpdateDisplay = TRUE;
          }

          if (strcmp(stat_string, "[AVL_Init] AVL_Initialize Failed!") == 0)
          {
            strcpy(line5, "Failed to Initialise Tuner.  Change USB Cable");
            UpdateDisplay = TRUE;
          }

          if (strcmp(stat_string, "[AVL_Init] ok") == 0)
          {
            strcpy(line5, "Tuner Initialised");
            UpdateDisplay = TRUE;
          }

          if ((stat_string[0] == '=') && (stat_string[5] == 'F'))  // Frequency
          {
            line3[0] = stat_string[13];
            line3[1] = stat_string[14];
            line3[2] = stat_string[15];
            line3[3] = stat_string[16];
            line3[4] = stat_string[17];
            line3[5] = stat_string[18];
            line3[6] = stat_string[19];
            line3[7] = '\0';
            strcat(line3, " MHz");
          }

          if ((stat_string[0] == '=') && (stat_string[5] == 'B'))  // Bandwidth
          {
            if (stat_string[18] != '0')
            {
              line4[0] = stat_string[18];
              line4[1] = stat_string[20];
              line4[2] = stat_string[21];
              line4[3] = stat_string[22];
              line4[4] = '\0';
            }
            else
            {
              line4[0] = stat_string[20];
              line4[1] = stat_string[21];
              line4[2] = stat_string[22];
              line4[3] = '\0';
            }
            strcat(line4, " kHz");
            UpdateDisplay = TRUE;
          }

          // Now detect start of signal search
          strcpyn(linex, stat_string, 25);  // for destructive test
          if (strcmp(linex, "[AVL_ChannelScan_Tx] Freq") == 0)
          {
            strcpy(line5, "Searching for signal");
            UpdateDisplay = TRUE;
          }

          // And detect failed search
          if (strcmp(stat_string, "[DVBTx_Channel_ScanLock_Example] DVBTx channel scan is fail,Err.") == 0)
          {
            strcpy(line5, "Search failed, resetting for another search");
            UpdateDisplay = TRUE;
          }

          // Notify signal detection (linex is already the first 25 chars of stat_string)
          if (strcmp(linex, "[AVL_LockChannel_T] Freq ") == 0)
          {
            strcpy(line5, "Signal detected, attempting to lock");
            UpdateDisplay = TRUE;
          }

          // Notify lock
          if (strcmp(stat_string, "locked") == 0)
          {
            strcpy(line5, "Signal locked");
            UpdateDisplay = TRUE;
          }

          // Notify unlocked
          if (strcmp(stat_string, "Unlocked") == 0)
          {
            strcpy(line5, "Tuner Unlocked");
            strcpy(line10, "|");
            strcpy(line11, "|");
            strcpy(line12, "|");
            strcpy(line13, "|");
            strcpy(line14, "|");
            FinishedButton = 1;
            if(FirstLock == 0)
            {
              FirstLock = 1;
            }
            UpdateDisplay = TRUE;
          }

          // Display reported modulation
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "MOD  :") == 0)
          {
            strcpy(line6, stat_string);
          }

          // Display reported FFT
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "FFT  :") == 0)
          {
            strcpy(line7, stat_string);
          }

          // Display reported constellation
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "Const:") == 0)
          {
            strcpy(line8, stat_string);
          }

          // Display reported FEC
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "FEC  :") == 0)
          {
            strcpy(line9, stat_string);
          }
          
          // Display reported Guard
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "Guard:") == 0)
          {
            strcpy(line10, stat_string);
            UpdateDisplay = TRUE;
          }

          // Display reported SSI
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "SSI is") == 0)
          {
            strcpy(line11, stat_string);
          }

          // Display reported SQI
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "SQI is") == 0)
          {
            strcpy(line12, stat_string);
          }

          // Display reported SNR
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "SNR is") == 0)
          {
            strcpy(line13, stat_string);
          }

          // Display reported PER
          strcpyn(linex, stat_string, 6);  // for destructive test
          if (strcmp(linex, "PER is") == 0)
          {
            strcpy(line14, stat_string);
            strcpy(line5, "|");            // Clear any old text from line 5
            UpdateDisplay = TRUE;
          }

          stat_string[0] = '\0';   // Finished processing this info, so clear the stat_string

          if (FinishedButton == 1)  // Parameters requested to be displayed
          {

            Parameters_currently_displayed = 1;
            strcpy(composite, line5);
            strcat(composite, "\n");
            strcat(composite, line3);
            strcat(composite, "   ");
            strcat(composite, line4);
            strcat(composite, "\n");
            strcat(composite, line6);
            strcat(composite, "   ");
            strcat(composite, line7);
            strcat(composite, "\n");
            strcat(composite, line8);
            strcat(composite, "\n");
            strcat(composite, line9);
            strcat(composite, "\n");
            strcat(composite, line10);
            strcat(composite, "\n");
            strcat(composite, line11);
            strcat(composite, "\n");
            strcat(composite, line12);
            strcat(composite, "\n");
            strcat(composite, line13);

            // Only build the display image if needed (takes too long to display every update)
            if (UpdateDisplay)
            {    
              DisplayMsg(composite);
              UpdateDisplay = FALSE;
            }

            // Build string for VLC
            strcpy(vlctext, line5);
            strcat(vlctext, "%n");
            strcat(vlctext, line3);
            strcat(vlctext, ",  ");
            strcat(vlctext, line4);
            strcat(vlctext, "%n");
            strcat(vlctext, line6);
            strcat(vlctext, ",  ");
            strcat(vlctext, line7);
            strcat(vlctext, "%n");
            strcat(vlctext, line8);
            strcat(vlctext, ",  ");
            strcat(vlctext, line9);
            strcat(vlctext, "%n");
            strcat(vlctext, line10);
            strcat(vlctext, "%n");
            strcat(vlctext, line11);
            strcat(vlctext, "%n");
            strcat(vlctext, line12);
            strcat(vlctext, "%n");
            strcat(vlctext, line13);
            strcat(vlctext, "%n");
            strcat(vlctext, line14);

            FILE *fw=fopen("/home/pi/tmp/vlc_temp_overlay.txt","w+");
            if(fw!=0)
            {
              fprintf(fw, "%s\n", vlctext);
            }
            fclose(fw);

            // Copy temp file to file to be read by VLC to prevent file collisions
            system("cp /home/pi/tmp/vlc_temp_overlay.txt /home/pi/tmp/vlc_overlay.txt");
          }
          else
          {
            if (Parameters_currently_displayed == 1)
            {
              Parameters_currently_displayed = 0;

              FILE *fw=fopen("/home/pi/tmp/vlc_overlay.txt","w+");
              if(fw!=0)
              {
                fprintf(fw, " ");
              }
              fclose(fw);
            }
          }
        }
        else
        {
          strcat(stat_string, status_message_char);  // Not end of line, so append the character to the stat string
        }
      }
  }
  close(fd_status_fifo); 
  usleep(1000);
  printf("Stopped receive process\n");
}


static void
terminate(int dummy)
{
  system("/home/pi/dvbt/dvb-t_stop.sh &");
  usleep(1000000);
  system("sudo killall vlc >/dev/null 2>/dev/null");
  system("sudo killall /home/pi/dvbt/CombiTunerExpress >/dev/null 2>/dev/null");
  printf("Terminate\n");
  DisplayMsg("Ryde Interim DVB-T Receiver Stopped");

  exit(1);
}

// main initializes the system and starts Menu 1 

int main(int argc, char **argv)
{
  int i;
  // Catch sigaction and call terminate
  for (i = 0; i < 16; i++)
  {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = terminate;
    sigaction(i, &sa, NULL);
  }

  // Read in the Config file
  ReadConfig();

  // Run the receiver
  DVBTRX();
  return 0;
}






