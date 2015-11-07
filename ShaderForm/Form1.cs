using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace ShaderForm
{
	public partial class FormMain : Form
	{
		private Stopwatch sw = new Stopwatch(); // available to all event handlers
		private Visual visual;
		private string shaderFileName;
		private long lastTime = 0;
		private int frames = 0;
		private bool mouseDown = false;
		private Point mousePos;

		public FormMain()
		{
			InitializeComponent();
		}

		private void glControl_DragEnter(object sender, DragEventArgs e)
		{
			if (e.Data.GetDataPresent(DataFormats.FileDrop)) e.Effect = DragDropEffects.Link;
		}

		private void glControl_DragDrop(object sender, DragEventArgs e)
		{
			string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
			foreach (string file in files)
			{
				loadShader(file);
				return;
			}
		}

		private void fileSystemWatcher_Changed(object sender, FileSystemEventArgs e)
		{
			loadShader(e.FullPath);
		}

		private void loadShader(string fileName)
		{
			errorLog.Visible = false;
			//try load new
			try
			{
				shaderFileName = fileName;
				Text = shaderFileName;
				fileSystemWatcher.Filter = Path.GetFileName(fileName);
				fileSystemWatcher.Path = Path.GetDirectoryName(fileName);
				fileSystemWatcher.EnableRaisingEvents = true;
				visual.loadShader(fileName);
			}
			catch (Exception e)
			{
				errorLog.Text = e.Message;
				errorLog.Visible = true;
				//load default shader
				visual.loadShader("");
			}
			sw.Reset();
			frames = 0;
			lastTime = 0;
			sw.Start();
			Application_Idle(null, null);
			glControl.Invalidate();
		}

		private void glControl_Paint(object sender, PaintEventArgs e)
		{
			int width = glControl.Width;
			int height = glControl.Height;
			try 
			{
				int g = int.Parse(granularity.Text);
				width = glControl.Width / g;
				height = glControl.Height / g;
			}
			catch(Exception) { };
			visual.update(sw.ElapsedMilliseconds / 1000.0f, mousePos.X, mousePos.Y, mouseDown, width, height);
			visual.draw(glControl.Width, glControl.Height);
			glControl.SwapBuffers();
		}

		private void glControl_Load(object sender, EventArgs e)
		{
			visual = new Visual();
		}

		void Application_Idle(object sender, EventArgs e)
		{
			++frames;
			long newTime = sw.ElapsedMilliseconds;
			elapsedTime.Text = String.Format("{0:0.00}", newTime / 1000.0f);
			long diff = newTime - lastTime;
			if (diff > 500)
			{
				fps.Text = String.Format("{0:0.00}FPS", (1000.0f * frames) / diff);
				lastTime = newTime;
				frames = 0;
			}
			glControl.Invalidate();
		}

		private void FormMain_Load(object sender, EventArgs e)
		{
			try
			{
				Microsoft.Win32.RegistryKey keyApp = Application.UserAppDataRegistry;
				if (null == keyApp)
				{
					return;
				}
				WindowState = (FormWindowState)Convert.ToInt32(keyApp.GetValue("windowState", (int)WindowState));
				Width = Convert.ToInt32(keyApp.GetValue("width", Width));
				Height = Convert.ToInt32(keyApp.GetValue("height", Height));
				Top = Convert.ToInt32(keyApp.GetValue("top", Top));
				Left = Convert.ToInt32(keyApp.GetValue("left", Left));
				shaderFileName = Convert.ToString(keyApp.GetValue("shaderFileName", ""));
				play.Checked = Convert.ToBoolean(keyApp.GetValue("play", false));
				string granularity = Convert.ToString(keyApp.GetValue("granularity", this.granularity.Text));
				this.granularity.SelectedIndex = this.granularity.FindString(granularity); 
				String[] arguments = Environment.GetCommandLineArgs();
				if (arguments.Length > 1)
				{
					shaderFileName = arguments[1];
				}
				loadShader(shaderFileName);
			}
			catch (Exception ex)
			{
				MessageBox.Show(ex.Message);
			}
		}

		private void FormMain_FormClosing(object sender, FormClosingEventArgs e)
		{
			try
			{
				Microsoft.Win32.RegistryKey keyApp = Application.UserAppDataRegistry;
				if (null == keyApp)
				{
					return;
				}
				keyApp.SetValue("windowState", (int)WindowState);
				keyApp.SetValue("width", Width);
				keyApp.SetValue("height", Height);
				keyApp.SetValue("top", Top);
				keyApp.SetValue("left", Left);
				keyApp.SetValue("shaderFileName", shaderFileName);
				keyApp.SetValue("play", play.Checked);
				keyApp.SetValue("granularity", this.granularity.Text);
			}
			catch (Exception ex)
			{
				MessageBox.Show(ex.Message);
			}
		}

		private void reload_Click(object sender, EventArgs e)
		{
			loadShader(shaderFileName);
		}

		private void play_CheckStateChanged(object sender, EventArgs e)
		{
			if (play.Checked)
			{
				sw.Start();
				Application.Idle += Application_Idle;
				play.Image = global::ShaderForm.Properties.Resources.Pause;
			}
			else
			{
				sw.Stop();
				play.Image = global::ShaderForm.Properties.Resources.Play;
				Application.Idle -= Application_Idle;

			}
		}

		private void glControl_MouseDown(object sender, MouseEventArgs e)
		{
			if (System.Windows.Forms.MouseButtons.Left == e.Button)
			{
				mouseDown = true;
			}
		}

		private void glControl_MouseMove(object sender, MouseEventArgs e)
		{
			mousePos = e.Location;
		}

		private void glControl_MouseUp(object sender, MouseEventArgs e)
		{
			if (System.Windows.Forms.MouseButtons.Left == e.Button)
			{
				mouseDown = false;
			}
		}

		private void FormMain_KeyDown(object sender, KeyEventArgs e)
		{
			if (e.KeyCode == Keys.Escape)
			{
				Close();
			}
		}

		private void granularity_SelectedIndexChanged(object sender, EventArgs e)
		{
			glControl.Invalidate();
		}
	}
}
