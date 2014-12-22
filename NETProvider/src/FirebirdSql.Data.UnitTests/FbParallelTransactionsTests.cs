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
using System.Data;
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

		[Test]
		public void DifferentIL()
		{
			using (FbTransaction tx1 = Connection.BeginTransaction(IsolationLevel.ReadCommitted),
				tx2 = Connection.BeginTransaction(IsolationLevel.Serializable))
			{
				var cmd1 = new FbCommand("select mon$isolation_mode from mon$transactions where mon$transaction_id = current_transaction", Connection, tx1);
				var cmd2 = new FbCommand("select mon$isolation_mode from mon$transactions where mon$transaction_id = current_transaction", Connection, tx2);

				Assert.AreEqual(2, (short)cmd1.ExecuteScalar());
				Assert.AreEqual(0, (short)cmd2.ExecuteScalar());

				cmd2.Dispose();
				cmd1.Dispose();
			}
		}

		[Test]
		public void NoDanglingTransactionsAfterPooledConnectionCloseTransactionsLeft()
		{
			var before = GetTransactionsCount(Connection);
			Console.WriteLine("Before: {0}", before);

			var builder = BuildConnectionStringBuilder();
			builder.Pooling = true;
			using (var conn = new FbConnection(builder.ToString()))
			{
				conn.Open();
				var tx1 = conn.BeginTransaction();
				var tx2 = conn.BeginTransaction();

				var current = GetTransactionsCount(Connection);
				Console.WriteLine("Current: {0}", current);
				Assert.AreEqual(before + 2, current);
			}

			var after = GetTransactionsCount(Connection);
			Console.WriteLine("After: {0}", after);

			FbConnection.ClearAllPools();

			Assert.AreEqual(before, after);
		}

		static int GetTransactionsCount(FbConnection connection)
		{
			using (var cmd = connection.CreateCommand())
			{
				cmd.CommandText = "select count(*) from mon$transactions where mon$transaction_id <> current_transaction";
				return (int)cmd.ExecuteScalar();
			}
		}
	}
}
