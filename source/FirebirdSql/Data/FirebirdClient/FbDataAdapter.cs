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
 *  Copyright (c) 2002, 2007 Carlos Guzman Alvarez
 *  All Rights Reserved.
 * 
 *  Contributors:
 *   Jiri Cincura (jiri@cincura.net)
 */

using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Data.Common;
using System.Collections.Generic;

namespace FirebirdSql.Data.FirebirdClient
{
#if (!NET_CF)
	[DefaultEvent("RowUpdated")]
#endif
	public sealed class FbDataAdapter : DbDataAdapter, ICloneable
	{
		#region � Static Fields �

		private static readonly object EventRowUpdated = new object();
		private static readonly object EventRowUpdating = new object();

		#endregion

		#region � Events �

		public event FbRowUpdatedEventHandler RowUpdated
		{
			add
			{
				base.Events.AddHandler(EventRowUpdated, value);
			}

			remove
			{
				base.Events.RemoveHandler(EventRowUpdated, value);
			}
		}

		public event FbRowUpdatingEventHandler RowUpdating
		{
			add
			{
				base.Events.AddHandler(EventRowUpdating, value);
			}

			remove
			{
				base.Events.RemoveHandler(EventRowUpdating, value);
			}
		}

		#endregion

		#region � Fields �

		private bool disposed;
		private bool shouldDisposeSelectCommand;

		#endregion

		#region � Properties �

#if (!NET_CF)
		[Category("Fill")]
		[DefaultValue(null)]
#endif
		public new FbCommand SelectCommand
		{
			get { return (FbCommand)base.SelectCommand; }
			set { base.SelectCommand = value; }
		}

#if (!NET_CF)
		[Category("Update")]
		[DefaultValue(null)]
#endif
		public new FbCommand InsertCommand
		{
			get { return (FbCommand)base.InsertCommand; }
			set { base.InsertCommand = value; }
		}

#if (!NET_CF)
		[Category("Update")]
		[DefaultValue(null)]
#endif
		public new FbCommand UpdateCommand
		{
			get { return (FbCommand)base.UpdateCommand; }
			set { base.UpdateCommand = value; }
		}

#if (!NET_CF)
		[Category("Update")]
		[DefaultValue(null)]
#endif
		public new FbCommand DeleteCommand
		{
			get { return (FbCommand)base.DeleteCommand; }
			set { base.DeleteCommand = value; }
		}

		#endregion

		#region � Constructors �

		public FbDataAdapter()
			: base()
		{
		}

		public FbDataAdapter(FbCommand selectCommand)
			: base()
		{
			this.SelectCommand = selectCommand;
		}

		public FbDataAdapter(string selectCommandText, string selectConnectionString)
			: this(selectCommandText, new FbConnection(selectConnectionString))
		{
		}

		public FbDataAdapter(string selectCommandText, FbConnection selectConnection)
			: base()
		{
			this.SelectCommand = new FbCommand(selectCommandText, selectConnection);
			this.shouldDisposeSelectCommand = true;
		}

		#endregion

		#region IDisposable	Methods

		protected override void Dispose(bool disposing)
		{
			lock (this)
			{
				if (!this.disposed)
				{
					try
					{
						// Release any managed resources
						if (disposing)
						{
							if (this.shouldDisposeSelectCommand)
							{
								if (this.SelectCommand != null)
								{
									this.SelectCommand.Dispose();
									this.SelectCommand = null;
								}
							}
						}

						// release any unmanaged resources

						this.disposed = true;
					}
					finally
					{
						base.Dispose(disposing);
					}
				}
			}
		}

		#endregion

		#region � Protected Methods �

		protected override RowUpdatingEventArgs CreateRowUpdatingEvent(
			DataRow dataRow,
			IDbCommand command,
			StatementType statementType,
			DataTableMapping tableMapping)
		{
			return new FbRowUpdatingEventArgs(dataRow, command, statementType, tableMapping);
		}

		protected override RowUpdatedEventArgs CreateRowUpdatedEvent(
			DataRow dataRow,
			IDbCommand command,
			StatementType statementType,
			DataTableMapping tableMapping)
		{
			return new FbRowUpdatedEventArgs(dataRow, command, statementType, tableMapping);
		}

		protected override void OnRowUpdating(RowUpdatingEventArgs value)
		{
			FbRowUpdatingEventHandler handler = null;

			handler = (FbRowUpdatingEventHandler)base.Events[EventRowUpdating];

			if ((null != handler) &&
				(value is FbRowUpdatingEventArgs) &&
				(value != null))
			{
				handler(this, (FbRowUpdatingEventArgs)value);
			}
		}

		protected override void OnRowUpdated(RowUpdatedEventArgs value)
		{
			FbRowUpdatedEventHandler handler = null;

			handler = (FbRowUpdatedEventHandler)base.Events[EventRowUpdated];

			if ((handler != null) &&
				(value is FbRowUpdatedEventArgs) &&
				(value != null))
			{
				handler(this, (FbRowUpdatedEventArgs)value);
			}
		}

		#endregion

		#region � Update DataRow Collection �

		/// <summary>
		/// Review .NET	Framework documentation.
		/// </summary>
		protected override int Update(DataRow[] dataRows, DataTableMapping tableMapping)
		{
			int updated = 0;
			IDbCommand command = null;
			StatementType statementType = StatementType.Insert;
			ICollection<IDbConnection> connections = new List<IDbConnection>();
			RowUpdatingEventArgs updatingArgs = null;
			Exception updateException = null;

			foreach (DataRow row in dataRows)
			{
				updateException = null;

				if (row.RowState == DataRowState.Detached ||
					row.RowState == DataRowState.Unchanged)
				{
					continue;
				}

				switch (row.RowState)
				{
					case DataRowState.Unchanged:
					case DataRowState.Detached:
						continue;

					case DataRowState.Added:
						command = this.InsertCommand;
						statementType = StatementType.Insert;
						break;

					case DataRowState.Modified:
						command = this.UpdateCommand;
						statementType = StatementType.Update;
						break;

					case DataRowState.Deleted:
						command = this.DeleteCommand;
						statementType = StatementType.Delete;
						break;
				}

				/* The order of	execution can be reviewed in the .NET 1.1 documentation
				 *
				 * 1. The values in	the	DataRow	are	moved to the parameter values. 
				 * 2. The OnRowUpdating	event is raised. 
				 * 3. The command executes.	
				 * 4. If the command is	set	to FirstReturnedRecord,	then the first returned	result is placed in	the	DataRow. 
				 * 5. If there are output parameters, they are placed in the DataRow. 
				 * 6. The OnRowUpdated event is	raised.	
				 * 7 AcceptChanges is called. 
				 */

				try
				{
					updatingArgs = this.CreateRowUpdatingEvent(row, command, statementType, tableMapping);

					/* 1. Update Parameter values (It's	very similar to	what we	
					 * are doing in	the	FbCommandBuilder class).
					 *
					 * Only	input parameters should	be updated.
					 */
					if (command != null && command.Parameters.Count > 0)
					{
						try
						{
							this.UpdateParameterValues(command, statementType, row, tableMapping);
						}
						catch (Exception ex)
						{
							updatingArgs.Errors = ex;
							updatingArgs.Status = UpdateStatus.ErrorsOccurred;
						}
					}

					// 2. Raise	RowUpdating	event
					this.OnRowUpdating(updatingArgs);

					if (updatingArgs.Status == UpdateStatus.SkipAllRemainingRows)
					{
						break;
					}
					else if (updatingArgs.Status == UpdateStatus.ErrorsOccurred)
					{
						if (updatingArgs.Errors == null)
						{
							throw new InvalidOperationException("RowUpdatingEvent: Errors occurred; no additional information is available.");
						}
						throw updatingArgs.Errors;
					}
					else if (updatingArgs.Status == UpdateStatus.SkipCurrentRow)
					{
						updated++;
						continue;
					}
					else if (updatingArgs.Status == UpdateStatus.Continue)
					{
						if (command != updatingArgs.Command)
						{
							command = updatingArgs.Command;
						}
						if (command == null)
						{
							/* Samples of exceptions thrown	by DbDataAdapter class
							 *
							 *	Update requires	a valid	InsertCommand when passed DataRow collection with new rows
							 *	Update requires	a valid	UpdateCommand when passed DataRow collection with modified rows.
							 *	Update requires	a valid	DeleteCommand when passed DataRow collection with deleted rows.
							 */
							throw new InvalidOperationException(this.CreateExceptionMessage(statementType));
						}

						// 3. Execute the command
						if (command.Connection.State == ConnectionState.Closed)
						{
							command.Connection.Open();
							// Track command connection
							connections.Add(command.Connection);
						}

						int rowsAffected = command.ExecuteNonQuery();
						if (rowsAffected == 0)
						{
							throw new DBConcurrencyException(new DBConcurrencyException().Message, null, new DataRow[] { row });
						}

						updated++;

						// http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=933212&SiteID=1
						if (statementType == StatementType.Insert)
						{
							row.AcceptChanges();
						}

						/* 4. If the command is	set	to FirstReturnedRecord,	then the 
						 * first returned result is	placed in the DataRow. 
						 * 
						 * We have nothing to do in	this case as there are no 
						 * support for batch commands.
						 */

						/* 5. Check	if we have output parameters and they should 
						 * be updated.
						 *
						 * Only	output parameters should be	updated
						 */
						if (command.UpdatedRowSource == UpdateRowSource.OutputParameters ||
							command.UpdatedRowSource == UpdateRowSource.Both)
						{
							// Process output parameters
							foreach (IDataParameter parameter in command.Parameters)
							{
								if ((parameter.Direction == ParameterDirection.Output ||
									parameter.Direction == ParameterDirection.ReturnValue ||
									parameter.Direction == ParameterDirection.InputOutput) &&
									!String.IsNullOrEmpty(parameter.SourceColumn))
								{
									DataColumn column = null;

									DataColumnMapping columnMapping = tableMapping.GetColumnMappingBySchemaAction(
										parameter.SourceColumn,
										this.MissingMappingAction);

									if (columnMapping != null)
									{
										column = columnMapping.GetDataColumnBySchemaAction(
											row.Table,
											null,
											this.MissingSchemaAction);

										if (column != null)
										{
											row[column] = parameter.Value;
										}
									}
								}
							}
						}
					}
				}
				catch (Exception ex)
				{
					row.RowError = ex.Message;
					updateException = ex;
				}

				if (updatingArgs != null && updatingArgs.Status == UpdateStatus.Continue)
				{
					// 6. Raise	RowUpdated event
					RowUpdatedEventArgs updatedArgs = this.CreateRowUpdatedEvent(row, command, statementType, tableMapping);
					this.OnRowUpdated(updatedArgs);

					if (updatedArgs.Status == UpdateStatus.SkipAllRemainingRows)
					{
						break;
					}
					else if (updatedArgs.Status == UpdateStatus.ErrorsOccurred)
					{
						if (updatingArgs.Errors == null)
						{
							throw new InvalidOperationException("RowUpdatedEvent: Errors occurred; no additional information available.");
						}
						throw updatedArgs.Errors;
					}
					else if (updatedArgs.Status == UpdateStatus.SkipCurrentRow)
					{
					}
					else if (updatingArgs.Status == UpdateStatus.Continue)
					{
						// If the update result is an exception throw it
						if (!this.ContinueUpdateOnError && updateException != null)
						{
							this.CloseConnections(connections);
							throw updateException;
						}

						// 7. Call AcceptChanges
						if (this.AcceptChangesDuringUpdate && !row.HasErrors)
						{
							row.AcceptChanges();
						}
					}
				}
				else
				{
					// If the update result is an exception throw it
					if (!this.ContinueUpdateOnError && updateException != null)
					{
						this.CloseConnections(connections);
						throw updateException;
					}
				}
			}

			this.CloseConnections(connections);

			return updated;
		}

		#endregion

		#region � Private Methods �

		private string CreateExceptionMessage(StatementType statementType)
		{
			System.Text.StringBuilder sb = new System.Text.StringBuilder();

			sb.Append("Update requires a valid ");
			sb.Append(statementType.ToString());
			sb.Append("Command when passed DataRow collection with ");

			switch (statementType)
			{
				case StatementType.Insert:
					sb.Append("new");
					break;

				case StatementType.Update:
					sb.Append("modified");
					break;

				case StatementType.Delete:
					sb.Append("deleted");
					break;
			}

			sb.Append(" rows.");

			return sb.ToString();
		}

		private void UpdateParameterValues(
			IDbCommand command,
			StatementType statementType,
			DataRow row,
			DataTableMapping tableMapping)
		{
			foreach (DbParameter parameter in command.Parameters)
			{
				// Process only input parameters
				if ((parameter.Direction == ParameterDirection.Input || parameter.Direction == ParameterDirection.InputOutput) &&
					!String.IsNullOrEmpty(parameter.SourceColumn))
				{
					DataColumn column = null;

					/* Get the DataColumnMapping that matches the given
					 * column name
					 */
					DataColumnMapping columnMapping = tableMapping.GetColumnMappingBySchemaAction(
						parameter.SourceColumn,
						this.MissingMappingAction);

					if (columnMapping != null)
					{
						column = columnMapping.GetDataColumnBySchemaAction(row.Table, null, this.MissingSchemaAction);

						if (column != null)
						{
							DataRowVersion dataRowVersion = DataRowVersion.Default;

							if (statementType == StatementType.Insert)
							{
								dataRowVersion = DataRowVersion.Current;
							}
							else if (statementType == StatementType.Update)
							{
								dataRowVersion = parameter.SourceVersion;
							}
							else if (statementType == StatementType.Delete)
							{
								dataRowVersion = DataRowVersion.Original;
							}

							if (parameter.SourceColumnNullMapping)
							{
								parameter.Value = this.IsNull(row[column, dataRowVersion]) ? 1 : 0;
							}
							else
							{
								parameter.Value = row[column, dataRowVersion];
							}
						}
					}
				}
			}
		}

		private void CloseConnections(ICollection<IDbConnection> connections)
		{
			foreach (IDbConnection c in connections)
			{
				c.Close();
			}
			connections.Clear();
		}

		private bool IsNull(object value)
		{
			return FirebirdSql.Data.Common.TypeHelper.IsDBNull(value);
		}

		#endregion
	}
}
