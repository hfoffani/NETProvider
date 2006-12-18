/*
 *  Firebird ADO.NET Data provider for .NET and Mono 
 * 
 *     The contents of this file are subject to the Initial 
 *     Developer's Public License Version 1.0 (the "License"); 
 *     you may not use this file except in compliance with the 
 *     License. You may obtain a copy of the License at 
 *     http://www.ibphoenix.com/main.nfs?a=ibphoenix&l=;PAGES;NAME='ibpidpl'
 *
 *     Software distributed under the License is distributed on 
 *     an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either 
 *     express or implied.  See the License for the specific 
 *     language governing rights and limitations under the License.
 * 
 *  Copyright (c) 2002, 2004 Carlos Guzman Alvarez
 *  All Rights Reserved.
 */

using System;
using System.Data;
using System.Collections;
using FirebirdSql.Data.Firebird;
using FirebirdSql.Data.Firebird.Isql;
using NUnit.Framework;

namespace FirebirdSql.Data.Firebird.Tests
{
    [TestFixture]
    public class FbDatabaseSchemaTest : BaseTest
    {
        public FbDatabaseSchemaTest() : base(false)
        {
        }

        [Test]
        public void CharacterSets()
        {
            DataTable characterSets = Connection.GetSchema("CharacterSets");
        }

        [Test]
        public void CheckConstraints()
        {
            DataTable checkConstraints = Connection.GetSchema("CheckConstraints");
        }

        [Test]
        public void CheckConstraintsByTable()
        {
            DataTable checkConstraintsByTable = Connection.GetSchema("CheckConstraintsByTable");
        }

        [Test]
        public void Collations()
        {
            DataTable collations = Connection.GetSchema("Collations");
        }

        [Test]
        public void Columns()
        {
            DataTable columns = Connection.GetSchema("Columns");

            columns = Connection.GetSchema(
                            "Columns",
                            new string[] { null, null, "TEST", "INT_FIELD" });

            Assert.AreEqual(1, columns.Rows.Count);
        }

        [Test]
        public void ColumnPrivileges()
        {
            DataTable columnPrivileges = Connection.GetSchema("ColumnPrivileges");
        }

        [Test]
        public void Domains()
        {
            DataTable domains = Connection.GetSchema("Domains");
        }

        [Test]
        public void ForeignKeys()
        {
            DataTable foreignKeys = Connection.GetSchema("ForeignKeys");
        }

        [Test]
        public void Functions()
        {
            DataTable functions = Connection.GetSchema("Functions");
        }

        [Test]
        public void Generators()
        {
            DataTable generators = Connection.GetSchema("Generators");
        }

        [Test]
        public void Indexes()
        {
            DataTable indexes = Connection.GetSchema("Indexes");
        }

        [Test]
        public void PrimaryKeys()
        {
            DataTable primaryKeys = Connection.GetSchema("PrimaryKeys");

            primaryKeys = Connection.GetSchema(
                "PrimaryKeys",
                new string[] { null, null, "TEST" });

            Assert.AreEqual(1, primaryKeys.Rows.Count);
        }

        [Test]
        public void ProcedureParameters()
        {
            DataTable procedureParameters = Connection.GetSchema("ProcedureParameters");

            procedureParameters = Connection.GetSchema(
                "ProcedureParameters",
                new string[] { null, null, "SELECT_DATA" });

            Assert.AreEqual(3, procedureParameters.Rows.Count);
        }

        [Test]
        public void ProcedurePrivileges()
        {
            DataTable procedurePrivileges = Connection.GetSchema("ProcedurePrivileges");
        }

        [Test]
        public void Procedures()
        {
            DataTable procedures = Connection.GetSchema("Procedures");

            procedures = Connection.GetSchema(
                "Procedures",
                new string[] { null, null, "SELECT_DATA" });

            Assert.AreEqual(1, procedures.Rows.Count);
        }

        [Test]
        public void DataTypes()
        {
            DataTable providerTypes = Connection.GetSchema("DataTypes");
        }

        [Test]
        public void Roles()
        {
            DataTable roles = Connection.GetSchema("Roles");
        }

        [Test]
        public void Tables()
        {
            DataTable tables = Connection.GetSchema("Tables");

            tables = Connection.GetSchema(
                "Tables",
                new string[] { null, null, "TEST" });

            Assert.AreEqual(tables.Rows.Count, 1);

            tables = Connection.GetSchema(
                "Tables",
                new string[] { null, null, null, "TABLE" });

            Assert.AreEqual(tables.Rows.Count, 1);
        }

        [Test]
        public void TableConstraints()
        {
            DataTable tableConstraint = Connection.GetSchema("TableConstraints");
        }

        [Test]
        public void TablePrivileges()
        {
            DataTable tablePrivileges = Connection.GetSchema("TablePrivileges");
        }

        [Test]
        public void Triggers()
        {
            DataTable triggers = Connection.GetSchema("Triggers");
        }

        [Test]
        public void UniqueKeys()
        {
            DataTable primaryKeys = Connection.GetSchema("UniqueKeys");
        }

        [Test]
        public void ViewColumnUsage()
        {
            DataTable viewColumnUsage = Connection.GetSchema("ViewColumnUsage");
        }

        [Test]
        public void Views()
        {
            DataTable views = Connection.GetSchema("Views");
        }

        [Test]
        public void ViewPrivileges()
        {
            DataTable viewPrivileges = Connection.GetSchema("ViewPrivileges");
        }
    }
}
