/*
 *  Firebird ADO.NET Data provider for .NET and Mono 
 * 
 *     The contents of this file are subject to the Initial 
 *     Developer's Public License Version 1.0 (the "License"); 
 *     you may not use this file except in compliance with the 
 *     License. You may obtain a copy of the License at 
 *     http://www.firebirdsql.org/index.php?op=doc&id=idpl
 *
 *     Software distributed under the License is distributed on 
 *     an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either 
 *     express or implied.  See the License for the specific 
 *     language governing rights and limitations under the License.
 * 
 *  Copyright (c) 2014 Jiri Cincura (jiri@cincura.net)
 *  All Rights Reserved.
 */

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FirebirdSql.Data.FirebirdClient;
using NUnit.Framework;

namespace FirebirdSql.Data.UnitTests
{
	[TestFixture]
	class FbParallelTransactionsTests : TestsBase
	{
		public FbParallelTransactionsTests()
			: base(false)
		{ }

		[Test]
		public void DifferentTransactionsHandled()
		{
			using (FbTransaction tx1 = Connection.BeginTransaction(), 
				tx2 = Connection.BeginTransaction())
			{
				var cmd1 = new FbCommand("select current_transaction from rdb$database", Connection, tx1);
				var cmd2 = new FbCommand("select current_transaction from rdb$database", Connection, tx2);

				Assert.AreNotEqual((int)cmd1.ExecuteScalar(), (int)cmd2.ExecuteScalar());

				cmd2.Dispose();
				cmd1.Dispose();
			}
		}
	}
}
