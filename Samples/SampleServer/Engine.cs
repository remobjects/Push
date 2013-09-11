using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Text;

namespace SampleServer
{
    public partial class Engine : Component
    {
        public Engine()
        {
            InitializeComponent();
        }

        public Engine(IContainer container)
        {
            container.Add(this);

            InitializeComponent();
        }
    }
}
