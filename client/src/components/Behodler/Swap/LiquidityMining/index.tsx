import * as React from 'react'
import mining from '../../../../images/behodler/liquidityMiningPlaceholder.png'
import { Container, createStyles, Grid, makeStyles } from '@material-ui/core'

const useStyles = makeStyles(theme => createStyles({
    column: {
        width: 500
    }
}))

export default function LiquidityMining() {
    const classes = useStyles()
    return (
        <Container>
            <Grid
                container
                direction="column"
                justify="center"
                alignItems="center"
            >
                <Grid item className={classes.column}>
                    <Container> <img src={mining} width={400} /></Container>
                </Grid>
                <Grid item>
                    <a href="https://medium.com/weidaithriftcoin/roadmap-2021-9ee191fa8231" target="_blank">Road map</a>
                </Grid>
            </Grid>
        </Container>
    )

}