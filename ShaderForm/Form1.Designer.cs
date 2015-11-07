namespace ShaderForm
{
    partial class FormMain
    {
        /// <summary>
        /// Erforderliche Designervariable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Verwendete Ressourcen bereinigen.
        /// </summary>
        /// <param name="disposing">True, wenn verwaltete Ressourcen gelöscht werden sollen; andernfalls False.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Vom Windows Form-Designer generierter Code

        /// <summary>
        /// Erforderliche Methode für die Designerunterstützung.
        /// Der Inhalt der Methode darf nicht mit dem Code-Editor geändert werden.
        /// </summary>
        private void InitializeComponent()
        {
			this.glControl = new OpenTK.GLControl();
			this.fileSystemWatcher = new System.IO.FileSystemWatcher();
			this.errorLog = new System.Windows.Forms.TextBox();
			this.menuStrip = new System.Windows.Forms.MenuStrip();
			this.reload = new System.Windows.Forms.ToolStripMenuItem();
			this.play = new System.Windows.Forms.ToolStripMenuItem();
			this.fps = new System.Windows.Forms.ToolStripMenuItem();
			this.elapsedTime = new System.Windows.Forms.ToolStripMenuItem();
			this.granularity = new System.Windows.Forms.ToolStripComboBox();
			((System.ComponentModel.ISupportInitialize)(this.fileSystemWatcher)).BeginInit();
			this.menuStrip.SuspendLayout();
			this.SuspendLayout();
			// 
			// glControl
			// 
			this.glControl.AllowDrop = true;
			this.glControl.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.glControl.BackColor = System.Drawing.Color.Black;
			this.glControl.Location = new System.Drawing.Point(0, 0);
			this.glControl.Margin = new System.Windows.Forms.Padding(4, 4, 4, 4);
			this.glControl.Name = "glControl";
			this.glControl.Size = new System.Drawing.Size(353, 297);
			this.glControl.TabIndex = 0;
			this.glControl.VSync = true;
			this.glControl.Load += new System.EventHandler(this.glControl_Load);
			this.glControl.DragDrop += new System.Windows.Forms.DragEventHandler(this.glControl_DragDrop);
			this.glControl.DragEnter += new System.Windows.Forms.DragEventHandler(this.glControl_DragEnter);
			this.glControl.Paint += new System.Windows.Forms.PaintEventHandler(this.glControl_Paint);
			this.glControl.MouseDown += new System.Windows.Forms.MouseEventHandler(this.glControl_MouseDown);
			this.glControl.MouseMove += new System.Windows.Forms.MouseEventHandler(this.glControl_MouseMove);
			this.glControl.MouseUp += new System.Windows.Forms.MouseEventHandler(this.glControl_MouseUp);
			// 
			// fileSystemWatcher
			// 
			this.fileSystemWatcher.EnableRaisingEvents = true;
			this.fileSystemWatcher.SynchronizingObject = this;
			this.fileSystemWatcher.Changed += new System.IO.FileSystemEventHandler(this.fileSystemWatcher_Changed);
			// 
			// errorLog
			// 
			this.errorLog.AllowDrop = true;
			this.errorLog.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.errorLog.Location = new System.Drawing.Point(0, 0);
			this.errorLog.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
			this.errorLog.Multiline = true;
			this.errorLog.Name = "errorLog";
			this.errorLog.ReadOnly = true;
			this.errorLog.ScrollBars = System.Windows.Forms.ScrollBars.Both;
			this.errorLog.Size = new System.Drawing.Size(353, 297);
			this.errorLog.TabIndex = 1;
			this.errorLog.Visible = false;
			this.errorLog.DragDrop += new System.Windows.Forms.DragEventHandler(this.glControl_DragDrop);
			this.errorLog.DragEnter += new System.Windows.Forms.DragEventHandler(this.glControl_DragEnter);
			// 
			// menuStrip
			// 
			this.menuStrip.Dock = System.Windows.Forms.DockStyle.Bottom;
			this.menuStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.reload,
            this.play,
            this.fps,
            this.elapsedTime,
            this.granularity});
			this.menuStrip.Location = new System.Drawing.Point(0, 294);
			this.menuStrip.Name = "menuStrip";
			this.menuStrip.Size = new System.Drawing.Size(353, 27);
			this.menuStrip.TabIndex = 2;
			this.menuStrip.Text = "menuStrip1";
			// 
			// reload
			// 
			this.reload.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.reload.Image = global::ShaderForm.Properties.Resources.Edit_Redo;
			this.reload.ImageTransparentColor = System.Drawing.Color.Fuchsia;
			this.reload.Name = "reload";
			this.reload.ShortcutKeys = ((System.Windows.Forms.Keys)((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.R)));
			this.reload.Size = new System.Drawing.Size(28, 23);
			this.reload.ToolTipText = "reload shader";
			this.reload.Click += new System.EventHandler(this.reload_Click);
			// 
			// play
			// 
			this.play.CheckOnClick = true;
			this.play.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.play.Image = global::ShaderForm.Properties.Resources.Play;
			this.play.ImageTransparentColor = System.Drawing.Color.Fuchsia;
			this.play.Name = "play";
			this.play.ShortcutKeys = ((System.Windows.Forms.Keys)((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.P)));
			this.play.Size = new System.Drawing.Size(28, 23);
			this.play.CheckStateChanged += new System.EventHandler(this.play_CheckStateChanged);
			// 
			// fps
			// 
			this.fps.Alignment = System.Windows.Forms.ToolStripItemAlignment.Right;
			this.fps.Name = "fps";
			this.fps.Size = new System.Drawing.Size(38, 23);
			this.fps.Text = "FPS";
			// 
			// elapsedTime
			// 
			this.elapsedTime.Alignment = System.Windows.Forms.ToolStripItemAlignment.Right;
			this.elapsedTime.Name = "elapsedTime";
			this.elapsedTime.Size = new System.Drawing.Size(86, 23);
			this.elapsedTime.Text = "elapsed time";
			// 
			// granularity
			// 
			this.granularity.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.granularity.Items.AddRange(new object[] {
            "1",
            "2",
            "4"});
			this.granularity.Name = "granularity";
			this.granularity.Size = new System.Drawing.Size(75, 23);
			this.granularity.SelectedIndexChanged += new System.EventHandler(this.granularity_SelectedIndexChanged);
			// 
			// FormMain
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(353, 321);
			this.Controls.Add(this.errorLog);
			this.Controls.Add(this.glControl);
			this.Controls.Add(this.menuStrip);
			this.DoubleBuffered = true;
			this.KeyPreview = true;
			this.MainMenuStrip = this.menuStrip;
			this.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
			this.Name = "FormMain";
			this.Text = "ShaderForm";
			this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.FormMain_FormClosing);
			this.Load += new System.EventHandler(this.FormMain_Load);
			this.KeyDown += new System.Windows.Forms.KeyEventHandler(this.FormMain_KeyDown);
			((System.ComponentModel.ISupportInitialize)(this.fileSystemWatcher)).EndInit();
			this.menuStrip.ResumeLayout(false);
			this.menuStrip.PerformLayout();
			this.ResumeLayout(false);
			this.PerformLayout();

        }

        #endregion

        private OpenTK.GLControl glControl;
        private System.IO.FileSystemWatcher fileSystemWatcher;
		private System.Windows.Forms.TextBox errorLog;
		private System.Windows.Forms.MenuStrip menuStrip;
		private System.Windows.Forms.ToolStripMenuItem play;
		private System.Windows.Forms.ToolStripMenuItem reload;
		private System.Windows.Forms.ToolStripMenuItem elapsedTime;
		private System.Windows.Forms.ToolStripMenuItem fps;
		private System.Windows.Forms.ToolStripComboBox granularity;
    }
}

