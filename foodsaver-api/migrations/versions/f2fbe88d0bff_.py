"""empty message

Revision ID: f2fbe88d0bff
Revises: 4e9e0270f495
Create Date: 2025-01-22 12:17:18.856662

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = 'f2fbe88d0bff'
down_revision = '4e9e0270f495'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('product', schema=None) as batch_op:
        batch_op.add_column(sa.Column('name_en', sa.String(length=255), nullable=False))
        batch_op.add_column(sa.Column('name_fr', sa.String(length=255), nullable=False))
        batch_op.add_column(sa.Column('barcode', sa.String(length=255), nullable=False))
        batch_op.drop_column('name')

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('product', schema=None) as batch_op:
        batch_op.add_column(sa.Column('name', mysql.VARCHAR(length=255), nullable=False))
        batch_op.drop_column('barcode')
        batch_op.drop_column('name_fr')
        batch_op.drop_column('name_en')

    # ### end Alembic commands ###
