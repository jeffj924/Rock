//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by the T4\Model.tt template.
//
//     Changes to this file will be lost when the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------
//
// THIS WORK IS LICENSED UNDER A CREATIVE COMMONS ATTRIBUTION-NONCOMMERCIAL-
// SHAREALIKE 3.0 UNPORTED LICENSE:
// http://creativecommons.org/licenses/by-nc-sa/3.0/
//
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.Entity.ModelConfiguration;
using System.Linq;
using System.Text;

using Rock.Models;

namespace Rock.Models.Groups
{
    [Table( "groupsMember" )]
    public partial class Member : ModelWithAttributes, IAuditable
    {
		public Guid Guid { get; set; }
		
		public bool System { get; set; }
		
		public int GroupId { get; set; }
		
		public int PersonId { get; set; }
		
		public int GroupRoleId { get; set; }
		
		public DateTime? CreatedDateTime { get; set; }
		
		public DateTime? ModifiedDateTime { get; set; }
		
		public int? CreatedByPersonId { get; set; }
		
		public int? ModifiedByPersonId { get; set; }
		
		[NotMapped]
		public override string AuthEntity { get { return "Groups.Member"; } }

		public virtual Crm.Person Person { get; set; }

		public virtual Crm.Person CreatedByPerson { get; set; }

		public virtual Crm.Person ModifiedByPerson { get; set; }

		public virtual Group Group { get; set; }

		public virtual GroupRole GroupRole { get; set; }
    }

    public partial class MemberConfiguration : EntityTypeConfiguration<Member>
    {
        public MemberConfiguration()
        {
			this.HasRequired( p => p.Person ).WithMany( p => p.Members ).HasForeignKey( p => p.PersonId );
			this.HasOptional( p => p.CreatedByPerson ).WithMany().HasForeignKey( p => p.CreatedByPersonId );
			this.HasOptional( p => p.ModifiedByPerson ).WithMany().HasForeignKey( p => p.ModifiedByPersonId );
			this.HasRequired( p => p.Group ).WithMany( p => p.Members ).HasForeignKey( p => p.GroupId );
			this.HasRequired( p => p.GroupRole ).WithMany( p => p.Members ).HasForeignKey( p => p.GroupRoleId );
		}
    }
}
